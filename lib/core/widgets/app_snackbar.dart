import 'package:flutter/material.dart';

/// SnackBars padronizados para o Casa Prime.
/// Verde = sucesso, vermelho = erro, azul = info, laranja = aviso.
class AppSnackBar {
  static void sucesso(BuildContext context, String message) {
    _show(context, message, const Color(0xFF2E7D32), Icons.check_circle);
  }

  static void erro(BuildContext context, String message) {
    _show(context, message, const Color(0xFFC62828), Icons.error_outline);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, const Color(0xFF1E88E5), Icons.info_outline);
  }

  static void aviso(BuildContext context, String message) {
    _show(context, message, const Color(0xFFF57C00), Icons.warning_amber);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

