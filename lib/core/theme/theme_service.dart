import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../features/auth/data/auth_service.dart';
import 'theme_controller.dart';

/// Sincroniza o tema do usuário com o Firestore.
/// Campo: `users/{uid}.themeMode` = 'system' | 'light' | 'dark'
class ThemeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  /// Aplica no controller o tema salvo no Firestore do usuário logado.
  /// Chame isto depois de login / ao abrir o app autenticado.
  Future<void> syncFromFirestore(ThemeController controller) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      final saved = doc.data()?['themeMode'] as String?;
      if (saved == null) return;

      final mode = _decode(saved);
      // Atualiza sem persistir localmente (veio do servidor)
      await controller.setMode(mode, persist: false);
    } catch (_) {
      // silencioso — se falhar, mantém o valor local
    }
  }

  /// Salva no Firestore o tema atual do usuário.
  Future<void> saveToFirestore(ThemeMode mode) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).update({
        'themeMode': _encode(mode),
      });
    } catch (_) {
      // silencioso — não bloqueia a troca de tema
    }
  }

  String _encode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _decode(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
