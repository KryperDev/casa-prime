import 'package:flutter/material.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../auth/data/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.updatePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada com sucesso.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${_clean(e)}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _clean(Object e) {
    final s = e.toString();
    return s.contains(']') ? s.split(']').last.trim() : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alterar senha')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _currentCtrl,
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
                  validator: (v) =>
                      (v != null && v.length >= 6) ? null : 'Informe sua senha',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nova senha',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  validator: (v) =>
                      (v != null && v.length >= 6) ? null : 'Mínimo 6 caracteres',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nova senha',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  validator: (v) =>
                      v == _newCtrl.text ? null : 'As senhas não coincidem',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Alterar senha'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

