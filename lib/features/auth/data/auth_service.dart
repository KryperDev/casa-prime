import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================================
  //  Cadastro / Login / Logout
  // ============================================================
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = UserModel(
      uid: cred.user!.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      username: username.trim(),
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> logout() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<UserModel?> fetchCurrentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    final doc = await _db.collection('users').doc(u.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // ============================================================
  //  Editar perfil (nome de exibição e foto)
  // ============================================================
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final uid = _auth.currentUser!.uid;
    final data = <String, dynamic>{};
    if (displayName != null && displayName.trim().isNotEmpty) {
      data['displayName'] = displayName.trim();
    }
    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }
    if (data.isEmpty) return;
    await _db.collection('users').doc(uid).update(data);
    if (displayName != null) {
      await _auth.currentUser!.updateDisplayName(displayName.trim());
    }
    if (photoUrl != null) {
      await _auth.currentUser!.updatePhotoURL(photoUrl);
    }
  }

  // ============================================================
  //  Reautenticação (obrigatória antes de trocar e-mail/senha)
  // ============================================================
  Future<void> reauthenticate(String currentPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Sessão expirada. Faça login novamente.');
    final email = user.email;
    if (email == null) throw Exception('E-mail não encontrado.');

    final cred = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
  }

  // ============================================================
  //  Alterar e-mail
  // ============================================================
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    await reauthenticate(currentPassword);
    final user = _auth.currentUser!;
    await user.verifyBeforeUpdateEmail(newEmail.trim());
    // Atualiza também no Firestore (será confirmado quando o usuário clicar no link)
    await _db.collection('users').doc(user.uid).update({
      'email': newEmail.trim(),
    });
  }

  // ============================================================
  //  Alterar senha
  // ============================================================
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await reauthenticate(currentPassword);
    await _auth.currentUser!.updatePassword(newPassword);
  }

  // ============================================================
  //  Excluir conta
  //  Estratégia: preservar lançamentos no histórico (opção A)
  //  -> só desvincula do usuário, marca como removido,
  //     e apaga o documento users/{uid}.
  // ============================================================
  Future<void> deleteAccount({
    required String currentPassword,
    bool removeFromFamily = true,
  }) async {
    await reauthenticate(currentPassword);
    final user = _auth.currentUser!;
    final uid = user.uid;

    // Busca dados antes de apagar
    final userDoc = await _db.collection('users').doc(uid).get();
    final data = userDoc.data() ?? {};
    final familyId = data['familyId'] as String?;

    // 1) Remove do array de membros da família (preserva os lançamentos)
    if (familyId != null && removeFromFamily) {
      try {
        await _db.collection('families').doc(familyId).update({
          'memberIds': FieldValue.arrayRemove([uid]),
        });
      } catch (_) {
        // ignora se família já não existe
      }
    }

    // 2) Apaga o documento do usuário
    await _db.collection('users').doc(uid).delete();

    // 3) Apaga a conta do Firebase Auth
    await user.delete();
  }
}
