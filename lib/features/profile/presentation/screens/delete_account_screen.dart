import 'package:flutter/material.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../auth/data/auth_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _confirmAndDelete() async {
    if (_passCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe sua senha atual.')),
      );
      return;
    }

    // Confirmação dupla
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Esta ação é permanente. Seus dados de login serão removidos.\n\n'
          'Seus lançamentos continuarão no histórico da família, '
          'marcados com seu nome.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await _auth.deleteAccount(currentPassword: _passCtrl.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } catch (e) {
      if (!mounted) return;
      final s = e.toString();
      final msg = s.contains(']') ? s.split(']').last.trim() : s;
      AppSnackBar.erro(context, ErrorTranslator.translate(msg));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excluir conta'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 72, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Atenção',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ao excluir sua conta:\n\n'
                '• Seus dados de login são apagados permanentemente.\n'
                '• Você será removido da família.\n'
                '• Seus lançamentos continuam visíveis no histórico da família.\n'
                '• Esta ação não pode ser desfeita.',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              const Text('Para confirmar, digite sua senha atual:'),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Senha atual',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red),
                  icon: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.delete_forever),
                  label: const Text('Excluir minha conta'),
                  onPressed: _loading ? null : _confirmAndDelete,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

