import 'package:flutter/material.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../../transactions/domain/account_model.dart';
import '../../data/account_service.dart';
import '../../data/account_types.dart';

class EditAccountScreen extends StatefulWidget {
  final AccountModel? existing;
  const EditAccountScreen({super.key, this.existing});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _service = AccountService();
  final _familyService = FamilyService();

  late String _type;
  FamilyModel? _family;
  bool _loading = true;
  bool _saving = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.existing?.name ?? '';
    _type = widget.existing?.type ?? 'dinheiro';
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    final f = await _familyService.fetchMyFamily();
    if (!mounted) return;
    setState(() {
      _family = f;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_family == null) return;

    setState(() => _saving = true);
    try {
      if (isEditing) {
        await _service.updateAccount(
          familyId: _family!.id,
          account: widget.existing!,
          newName: _nameCtrl.text,
          newType: _type,
        );
      } else {
        await _service.createAccount(
          familyId: _family!.id,
          name: _nameCtrl.text,
          type: _type,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                isEditing ? 'Conta atualizada.' : 'Conta criada.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final s = e.toString();
      final msg = s.contains(']') ? s.split(']').last.trim() : s;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $msg')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (!isEditing || _family == null) return;
    setState(() => _saving = true);
    try {
      final count = await _service.countTransactionsUsingAccount(
        familyId: _family!.id,
        accountId: widget.existing!.id,
      );
      if (!mounted) return;

      if (count > 0) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Não é possível excluir'),
            content: Text(
              'Existem $count lançamento(s) usando esta conta.\n\n'
              'Para excluí-la, primeiro edite os lançamentos para '
              'outra conta (ou remova a associação).',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Excluir conta'),
          content: Text(
              'Tem certeza que deseja excluir "${widget.existing!.name}"?'),
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

      await _service.deleteAccount(
        familyId: _family!.id,
        accountId: widget.existing!.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta excluída.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final s = e.toString();
      final msg = s.contains(']') ? s.split(']').last.trim() : s;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $msg')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar conta' : 'Nova conta'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir',
              onPressed: _saving ? null : _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome da conta',
                    hintText: 'Ex: Nubank, Carteira, Bradesco...',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (v) =>
                      (v != null && v.trim().length >= 2)
                          ? null
                          : 'Mínimo 2 caracteres',
                ),
                const SizedBox(height: 20),
                const Text('Tipo de conta',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                Column(
                  children: AccountTypes.all.map((t) {
                    final selected = t.key == _type;
                    return RadioListTile<String>(
                      value: t.key,
                      groupValue: _type,
                      onChanged: (v) => setState(() => _type = v!),
                      title: Row(
                        children: [
                          Icon(t.icon,
                              size: 20,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey),
                          const SizedBox(width: 12),
                          Text(t.label),
                        ],
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isEditing ? 'Salvar alterações' : 'Criar conta'),
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
