import 'package:flutter/material.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/error_translator.dart';
import '../../data/family_service.dart';

class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _codeCtrl = TextEditingController();
  final _service = FamilyService();
  bool _loading = false;

  Future<void> _submit() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _service.joinWithToken(_codeCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você entrou na família!')),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      final s = e.toString();
      final msg = s.contains(']') ? s.split(']').last.trim() : s;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $msg')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar com convite')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.vpn_key_outlined,
                  size: 64, color: Color(0xFF1E88E5)),
              const SizedBox(height: 16),
              const Text(
                'Cole o código de convite enviado pelo administrador da família.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'XXXXXXXX',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar na família'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

