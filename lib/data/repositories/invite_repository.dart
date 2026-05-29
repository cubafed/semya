import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_app_holder.dart';

final inviteRepositoryProvider = Provider<InviteRepository>((ref) {
  return InviteRepository(familyFunctions);
});

class InviteRepository {
  InviteRepository(this._functions);

  final FirebaseFunctions _functions;

  Future<String> createSpaceAsOwner({
    required String ownerSecret,
    required String spaceName,
    required String displayName,
  }) async {
    final result = await _functions.httpsCallable('createSpaceAsOwner').call({
      'ownerSecret': ownerSecret,
      'spaceName': spaceName,
      'displayName': displayName,
    });
    return result.data['spaceId'] as String;
  }

  Future<void> redeemInvite({
    required String code,
    required String displayName,
  }) async {
    await _functions.httpsCallable('redeemInvite').call({
      'code': code.trim().toUpperCase(),
      'displayName': displayName.trim(),
    });
  }

  Future<String> generateInvite({int ttlHours = 72}) async {
    final result = await _functions.httpsCallable('generateInvite').call({
      'ttlHours': ttlHours,
    });
    return result.data['code'] as String;
  }

  Future<List<Map<String, dynamic>>> listInvites() async {
    final result = await _functions.httpsCallable('listInvites').call();
    final list = result.data['invites'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}
