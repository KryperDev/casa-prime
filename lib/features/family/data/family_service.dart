import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/auth_service.dart';
import '../../notifications/data/notification_service.dart';
import '../../transactions/data/default_categories.dart';
import '../domain/family_model.dart';
import '../domain/invite_model.dart';

class FamilyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();
  final NotificationService _notif = NotificationService();

  // ============================================================
  //  CRIAR FAMÍLIA
  // ============================================================
  Future<String> createFamily({required String name}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');

    final familyId = await _db.runTransaction<String>((tx) async {
      final userRef = _db.collection('users').doc(user.uid);
      final userSnap = await tx.get(userRef);
      final userData = userSnap.data() ?? {};
      if (userData['familyId'] != null) {
        throw Exception('Você já pertence a uma família.');
      }

      final familyRef = _db.collection('families').doc();
      final family = FamilyModel(
        id: familyRef.id,
        name: name.trim(),
        adminId: user.uid,
        memberIds: [user.uid],
        createdAt: DateTime.now(),
      );

      tx.set(familyRef, family.toMap());
      tx.update(userRef, {
        'familyId': familyRef.id,
        'role': 'admin',
      });

      return familyRef.id;
    });

    await seedDefaultCategories(familyId);
    return familyId;
  }

  // ============================================================
  //  OBSERVAR FAMÍLIA
  // ============================================================
  Stream<FamilyModel?> watchMyFamily() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield null;
      return;
    }
    await for (final userSnap
        in _db.collection('users').doc(user.uid).snapshots()) {
      final familyId = userSnap.data()?['familyId'] as String?;
      if (familyId == null) {
        yield null;
      } else {
        final familyDoc = await _db.collection('families').doc(familyId).get();
        yield familyDoc.exists
            ? FamilyModel.fromMap(familyDoc.data()!)
            : null;
      }
    }
  }

  Future<FamilyModel?> fetchMyFamily() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final familyId = userDoc.data()?['familyId'] as String?;
    if (familyId == null) return null;
    final familyDoc = await _db.collection('families').doc(familyId).get();
    if (!familyDoc.exists) return null;
    return FamilyModel.fromMap(familyDoc.data()!);
  }

  Future<List<Map<String, dynamic>>> fetchMembers(
      List<String> memberIds) async {
    if (memberIds.isEmpty) return [];
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < memberIds.length; i += 10) {
      final chunk = memberIds.sublist(
        i,
        i + 10 > memberIds.length ? memberIds.length : i + 10,
      );
      final snap = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        result.add({'uid': d.id, ...d.data()});
      }
    }
    return result;
  }

  // ============================================================
  //  CONVITES
  // ============================================================
  Future<InviteModel> createInvite({
    required String familyId,
    Duration validFor = const Duration(days: 7),
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');

    final token = _generateToken(8);
    final inviteRef =
        _db.collection('families').doc(familyId).collection('invites').doc();

    final invite = InviteModel(
      id: inviteRef.id,
      token: token,
      familyId: familyId,
      createdBy: user.uid,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(validFor),
    );

    await inviteRef.set(invite.toMap());

    await _db.collection('invite_tokens').doc(token).set({
      'familyId': familyId,
      'inviteId': inviteRef.id,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return invite;
  }

  Future<void> revokeInvite(InviteModel invite) async {
    await _db
        .collection('families')
        .doc(invite.familyId)
        .collection('invites')
        .doc(invite.id)
        .update({'revoked': true});
    await _db.collection('invite_tokens').doc(invite.token).update({
      'active': false,
    });
  }

  Stream<List<InviteModel>> watchInvites(String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('invites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => InviteModel.fromMap(d.id, d.data()))
            .toList());
  }

  // ============================================================
  //  ENTRAR COM CONVITE  ← dispara notificação ao admin
  // ============================================================
  Future<String> joinWithToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');

    final cleanToken = token.trim().toUpperCase();
    final tokenRef = _db.collection('invite_tokens').doc(cleanToken);
    final tokenSnap = await tokenRef.get();
    if (!tokenSnap.exists || tokenSnap.data()?['active'] != true) {
      throw Exception('Convite inválido ou expirado.');
    }

    final familyId = tokenSnap.data()!['familyId'] as String;
    final inviteId = tokenSnap.data()!['inviteId'] as String;

    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(user.uid);
      final userSnap = await tx.get(userRef);
      if (userSnap.data()?['familyId'] != null) {
        throw Exception('Você já pertence a uma família.');
      }

      final inviteRef = _db
          .collection('families')
          .doc(familyId)
          .collection('invites')
          .doc(inviteId);
      final inviteSnap = await tx.get(inviteRef);
      final inviteData = inviteSnap.data() ?? {};

      final revoked = inviteData['revoked'] == true;
      final expiresAt = (inviteData['expiresAt'] as Timestamp?)?.toDate();
      if (revoked || (expiresAt != null && DateTime.now().isAfter(expiresAt))) {
        throw Exception('Convite expirado ou cancelado.');
      }

      tx.update(userRef, {'familyId': familyId, 'role': 'member'});
      tx.update(_db.collection('families').doc(familyId), {
        'memberIds': FieldValue.arrayUnion([user.uid]),
      });
      tx.update(inviteRef, {'usageCount': FieldValue.increment(1)});
    });

    await tokenRef.update({'active': false});

    // Notifica o admin
    try {
      final adminId = await _notif.familyAdminId(familyId);
      final myData = await _auth.fetchCurrentUser();
      final myName = myData?.displayName ?? 'Um novo membro';
      if (adminId != null) {
        await _notif.notifyUsers(
          userIds: [adminId],
          type: 'invite_accepted',
          title: 'Convite aceito',
          body: '$myName entrou na sua família.',
          data: {'familyId': familyId, 'userId': user.uid},
          excludeUserId: user.uid,
        );
      }
    } catch (_) {
      // não bloqueia o fluxo principal
    }

    return familyId;
  }

  // ============================================================
  //  ADMIN: parentesco, remoção, renomear
  // ============================================================
  Future<void> updateMemberRelationship({
    required String memberId,
    required String relationship,
    String? customRelationship,
  }) async {
    await _db.collection('users').doc(memberId).update({
      'relationship': relationship,
      'customRelationship': customRelationship,
    });
  }

  Future<void> removeMember({
    required String familyId,
    required String memberId,
  }) async {
    await _db.runTransaction((tx) async {
      tx.update(_db.collection('users').doc(memberId), {
        'familyId': null,
        'role': 'member',
      });
      tx.update(_db.collection('families').doc(familyId), {
        'memberIds': FieldValue.arrayRemove([memberId]),
      });
    });
  }

  Future<void> renameFamily(String familyId, String newName) async {
    await _db.collection('families').doc(familyId).update({
      'name': newName.trim(),
    });
  }

  String _generateToken(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)])
        .join();
  }
}
