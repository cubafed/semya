import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/firebase/firebase_app_holder.dart';

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository(familyFirestore);
});

enum CallStatus { ringing, active, ended, missed }

class CallSession {
  CallSession({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.status,
    this.offer,
    this.answer,
  });

  final String id;
  final String callerId;
  final String calleeId;
  final CallStatus status;
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? answer;

  factory CallSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return CallSession(
      id: doc.id,
      callerId: data['callerId'] as String? ?? '',
      calleeId: data['calleeId'] as String? ?? '',
      status: _parseStatus(data['status'] as String?),
      offer: data['offer'] as Map<String, dynamic>?,
      answer: data['answer'] as Map<String, dynamic>?,
    );
  }

  static CallStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'active':
        return CallStatus.active;
      case 'ended':
        return CallStatus.ended;
      case 'missed':
        return CallStatus.missed;
      default:
        return CallStatus.ringing;
    }
  }
}

class CallRepository {
  CallRepository(this._firestore);

  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> get _calls =>
      _firestore.collection('calls');

  Stream<CallSession?> watchCall(String callId) {
    return _calls.doc(callId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CallSession.fromFirestore(doc);
    });
  }

  Stream<List<Map<String, dynamic>>> watchIceCandidates(String callId) {
    return _calls
        .doc(callId)
        .collection('candidates')
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<String> createOutgoingCall({
    required String callerId,
    required String calleeId,
  }) async {
    final id = _uuid.v4();
    await _calls.doc(id).set({
      'callerId': callerId,
      'calleeId': calleeId,
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  Future<void> setOffer(String callId, Map<String, dynamic> offer) async {
    await _calls.doc(callId).update({'offer': offer});
  }

  Future<void> setAnswer(String callId, Map<String, dynamic> answer) async {
    await _calls.doc(callId).update({
      'answer': answer,
      'status': 'active',
    });
  }

  Future<void> addIceCandidate(
    String callId,
    Map<String, dynamic> candidate,
  ) async {
    await _calls.doc(callId).collection('candidates').add(candidate);
  }

  Future<void> endCall(String callId, {String status = 'ended'}) async {
    await _calls.doc(callId).update({'status': status});
  }
}
