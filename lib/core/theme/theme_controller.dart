import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla o ThemeMode do app em tempo real.
///
/// Persiste a preferência localmente (SharedPreferences) para
/// carregamento instantâneo ao abrir o app, e opcionalmente
/// sincroniza com o Firestore (feito pelo ThemeService).
class ThemeController extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool _loaded = false;
  bool get loaded => _loaded;

  ThemeController() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      _mode = _decode(saved);
    } catch (_) {
      _mode = ThemeMode.system;
    }
    _loaded = true;
    notifyListeners();
  }

  /// Define o modo. `persist` controla se grava em SharedPreferences
  /// (usado para não gravar quando o valor veio do Firestore).
  Future<void> setMode(ThemeMode mode, {bool persist = true}) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();

    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _encode(mode));
    }
  }

  // ---------- helpers ----------
  static String _encode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _decode(String? s) {
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
