import * as admin from "firebase-admin";
import {
  FieldValue,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { randomBytes } from "crypto";

const projectId =
  process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT ?? "demo-semya";

// Admin must use emulators before initializeApp() — env vars set after import are ignored.
const useEmulators =
  process.env.FUNCTIONS_EMULATOR === "true" ||
  !!process.env.FIREBASE_EMULATOR_HUB ||
  projectId === "demo-semya";

if (useEmulators) {
  process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
  process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";
}

admin.initializeApp({ projectId });

const db = getFirestore();

const OWNER_SECRET = process.env.OWNER_SECRET ?? "change-me-before-release";

function requireAuth(context: { auth?: { uid: string } }): string {
  if (!context.auth?.uid) {
    throw new HttpsError("unauthenticated", "Нужен вход в приложение");
  }
  return context.auth.uid;
}

function generateCode(length = 8): string {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const bytes = randomBytes(length);
  let out = "";
  for (let i = 0; i < length; i++) {
    out += alphabet[bytes[i] % alphabet.length];
  }
  return out;
}

async function getUser(uid: string) {
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) return null;
  return { id: uid, ...snap.data() } as {
    id: string;
    spaceId?: string;
    role?: string;
    displayName?: string;
  };
}

export const createSpaceAsOwner = onCall(async (request) => {
  const uid = requireAuth(request);
  const { ownerSecret, spaceName, displayName } = request.data as {
    ownerSecret?: string;
    spaceName?: string;
    displayName?: string;
  };

  if (ownerSecret !== OWNER_SECRET) {
    throw new HttpsError("permission-denied", "Неверный секрет владельца");
  }
  if (!spaceName?.trim() || !displayName?.trim()) {
    throw new HttpsError("invalid-argument", "Укажите название и имя");
  }

  const existing = await getUser(uid);
  if (existing?.spaceId) {
    throw new HttpsError("already-exists", "Профиль уже создан");
  }

  const spaces = await db.collection("spaces").limit(1).get();
  if (!spaces.empty) {
    throw new HttpsError(
      "failed-precondition",
      "Семейное пространство уже существует. Используйте код приглашения.",
    );
  }

  const spaceRef = db.collection("spaces").doc();
  const now = FieldValue.serverTimestamp();

  await db.runTransaction(async (tx) => {
    tx.set(spaceRef, {
      name: spaceName.trim(),
      ownerId: uid,
      createdAt: now,
    });
    tx.set(db.collection("users").doc(uid), {
      spaceId: spaceRef.id,
      displayName: displayName.trim(),
      role: "owner",
      fcmTokens: [],
      createdAt: now,
    });
  });

  return { spaceId: spaceRef.id };
});

function inviteExpiresAt(
  raw: FirebaseFirestore.Timestamp | { toDate?: () => Date } | undefined,
): Date | undefined {
  if (!raw) return undefined;
  if (typeof raw.toDate === "function") return raw.toDate();
  if (typeof (raw as FirebaseFirestore.Timestamp).toMillis === "function") {
    return new Date((raw as FirebaseFirestore.Timestamp).toMillis());
  }
  return undefined;
}

export const redeemInvite = onCall(async (request) => {
  try {
    const uid = requireAuth(request);
    const { code, displayName } = request.data as {
      code?: string;
      displayName?: string;
    };

    const normalized = code?.trim().toUpperCase();
    if (!normalized || !displayName?.trim()) {
      throw new HttpsError("invalid-argument", "Код и имя обязательны");
    }

    const user = await getUser(uid);
    if (user?.spaceId) {
      throw new HttpsError("already-exists", "Вы уже в семье");
    }

    const invites = await db
      .collectionGroup("invites")
      .where("code", "==", normalized)
      .limit(1)
      .get();

    if (invites.empty) {
      throw new HttpsError("not-found", "Код не найден");
    }

    const inviteDoc = invites.docs[0];
    const invite = inviteDoc.data();
    const spaceId = inviteDoc.ref.parent.parent?.id;

    if (!spaceId) {
      throw new HttpsError("internal", "Некорректный invite");
    }
    if (invite.usedBy) {
      throw new HttpsError("failed-precondition", "Код уже использован");
    }
    if (invite.revoked) {
      throw new HttpsError("failed-precondition", "Код отозван");
    }

    const expiresAt = inviteExpiresAt(invite.expiresAt);
    if (expiresAt && expiresAt < new Date()) {
      throw new HttpsError("deadline-exceeded", "Срок кода истёк");
    }

    await db.runTransaction(async (tx) => {
      tx.update(inviteDoc.ref, {
        usedBy: uid,
        usedAt: FieldValue.serverTimestamp(),
      });
      tx.set(
        db.collection("users").doc(uid),
        {
          spaceId,
          displayName: displayName.trim(),
          role: "member",
          fcmTokens: [],
          createdAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    return { spaceId };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    console.error("redeemInvite failed", err);
    const message = err instanceof Error ? err.message : String(err);
    throw new HttpsError("internal", message);
  }
});

export const generateInvite = onCall(async (request) => {
  const uid = requireAuth(request);
  const ttlHours = (request.data?.ttlHours as number) ?? 72;

  const user = await getUser(uid);
  if (!user?.spaceId || user.role !== "owner") {
    throw new HttpsError("permission-denied", "Только владелец может создавать коды");
  }

  const code = generateCode(8);
  const expiresAt = new Date(Date.now() + ttlHours * 3600 * 1000);

  await db
    .collection("spaces")
    .doc(user.spaceId)
    .collection("invites")
    .doc(code)
    .set({
      code,
      createdBy: uid,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromDate(expiresAt),
      singleUse: true,
      usedBy: null,
      revoked: false,
    });

  return { code, expiresAt: expiresAt.toISOString() };
});

export const listInvites = onCall(async (request) => {
  const uid = requireAuth(request);
  const user = await getUser(uid);
  if (!user?.spaceId || user.role !== "owner") {
    throw new HttpsError("permission-denied", "Только владелец");
  }

  const snap = await db
    .collection("spaces")
    .doc(user.spaceId)
    .collection("invites")
    .orderBy("createdAt", "desc")
    .limit(50)
    .get();

  const invites = snap.docs.map((d) => {
    const data = d.data();
    return {
      code: data.code,
      usedBy: data.usedBy ?? null,
      revoked: data.revoked ?? false,
      expiresAt: data.expiresAt?.toDate?.()?.toISOString() ?? null,
      createdAt: data.createdAt?.toDate?.()?.toISOString() ?? null,
    };
  });

  return { invites };
});
