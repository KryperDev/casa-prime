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

      // ============================================================
      //  NOVO: Verifica o limite de membros do plano
      // ============================================================
      final familyRef = _db.collection('families').doc(familyId);
      final familySnap = await tx.get(familyRef);
      final familyData = familySnap.data() ?? {};
      final family = FamilyModel.fromMap(familyData);

      final memberCount = (familyData['memberIds'] as List?)?.length ?? 0;
      if (memberCount >= family.maxMembers) {
        throw Exception(
          'Esta família já atingiu o limite de ${family.maxMembers} membros '
          'do plano ${family.planType.label}. '
          'O administrador precisa fazer upgrade para adicionar mais membros.',
        );
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
      tx.update(familyRef, {
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
    } catch (_) {}

    return familyId;
  }