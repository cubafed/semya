/**
 * Dev-only: create invite code in Firestore emulator (no app UI).
 * Requires: auth + firestore emulators running.
 *
 * Usage: node scripts/generate_invite_dev.mjs
 */
import { createRequire } from 'node:module';

const require = createRequire(
  new URL('../functions/package.json', import.meta.url),
);
const admin = require('firebase-admin');
const { randomBytes } = require('node:crypto');

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';

const projectId = 'demo-semya';

admin.initializeApp({ projectId });

const db = admin.firestore();

function generateCode(length = 8) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const bytes = randomBytes(length);
  let out = '';
  for (let i = 0; i < length; i++) {
    out += alphabet[bytes[i] % alphabet.length];
  }
  return out;
}

async function ensureSpaceAndOwner() {
  const spaces = await db.collection('spaces').limit(1).get();
  if (!spaces.empty) {
    const doc = spaces.docs[0];
    const data = doc.data();
    return { spaceId: doc.id, ownerId: data.ownerId };
  }

  const { uid } = await admin.auth().createUser({});
  const spaceRef = db.collection('spaces').doc();
  const now = admin.firestore.FieldValue.serverTimestamp();

  await db.runTransaction(async (tx) => {
    tx.set(spaceRef, {
      name: 'Наша семья',
      ownerId: uid,
      createdAt: now,
    });
    tx.set(db.collection('users').doc(uid), {
      spaceId: spaceRef.id,
      displayName: 'Владелец',
      role: 'owner',
      fcmTokens: [],
      createdAt: now,
    });
  });

  return { spaceId: spaceRef.id, ownerId: uid };
}

async function main() {
  const { spaceId, ownerId } = await ensureSpaceAndOwner();
  const code = generateCode(8);
  const expiresAt = new Date(Date.now() + 72 * 3600 * 1000);

  await db
    .collection('spaces')
    .doc(spaceId)
    .collection('invites')
    .doc(code)
    .set({
      code,
      createdBy: ownerId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      singleUse: true,
      usedBy: null,
      revoked: false,
    });

  console.log('');
  console.log('Код приглашения (введите на экране «Вход по коду»):');
  console.log('');
  console.log(`  ${code}`);
  console.log('');
  console.log(`Действует до: ${expiresAt.toLocaleString('ru-RU')}`);
  console.log(`spaceId: ${spaceId}`);
  console.log('');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
