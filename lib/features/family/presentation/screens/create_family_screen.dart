import 'package:flutter/material.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/family_service.dart';

class CreateFamilyScreen extends StatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _familyService = FamilyService();
  final _auth = AuthService();

  String _relationship = 'pai';
  String _customRelationship = '';
  bool _loading = false;

  static const _relationships = [
    'pai', 'mãe', 'filho', 'filha', 'esposo', 'esposa',
    'irmão', 'irmã', 'avô', 'avó', 'neto', 'neta',
    'tio', 'tia', 'primo', 'prima', 'outro',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _familyService.createFamily(name: _nameCtrl.text);

      final uid = _auth.currentUser!.uid;
      await _familyService.updateMemberRelationship(
        memberId: uid,
        relationship: _relationship,
        customRelationship:
            _relationship == 'outro' ? _customRelationship : null,
      );

      if (!mounted) return;
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
      appBar: AppBar(title: const Text('Criar família')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome da família',
                    hintText: 'Ex: Família Silva',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  validator: (v) => (v != null && v.trim().length >= 3)
                      ? null
                      : 'Mínimo 3 caracteres',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _relationship,
                  decoration: const InputDecoration(
                    labelText: 'Seu parentesco',
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                  items: _relationships
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r[0].toUpperCase() + r.substring(1)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _relationship = v!),
                ),
                if (_relationship == 'outro') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Especifique o parentesco',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    onChanged: (v) => _customRelationship = v,
                    validator: (v) => (v != null && v.trim().isNotEmpty)
                        ? null
                        : 'Informe o parentesco',
                  ),
                ],
                const SizedBox(height: 32),
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
                        : const Text('Criar família'),
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

