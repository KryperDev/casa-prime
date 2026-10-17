import 'package:flutter/material.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../data/goal_service.dart';
import '../../domain/goal_model.dart';

class EditGoalScreen extends StatefulWidget {
  final GoalModel? existing;
  const EditGoalScreen({super.key, this.existing});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _addValueCtrl = TextEditingController();
  final _service = GoalService();
  final _familyService = FamilyService();

  String _icon = 'savings';
  String _color = '#1E88E5';
  DateTime? _deadline;

  FamilyModel? _family;
  bool _loading = true;
  bool _saving = false;

  bool get isEditing => widget.existing != null;

  static const _icones = [
    'savings', 'flight', 'home', 'directions_car',
    'school', 'phone_android', 'favorite', 'beach_access', 'celebration',
  ];

  static const _cores = [
    '#1E88E5', '#43A047', '#8E24AA', '#F4511E',
    '#E53935', '#00ACC1', '#3949AB', '#FB8C00',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _descCtrl.text = e.description ?? '';
      _targetCtrl.text = e.targetAmount.toStringAsFixed(2).replaceAll('.', ',');
      _deadline = e.deadline;
      _icon = e.icon;
      _color = e.color;
    }
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
    _descCtrl.dispose();
    _targetCtrl.dispose();
    _addValueCtrl.dispose();
    super.dispose();
  }

  IconData _iconData(String key) {
    switch (key) {
      case 'flight':
        return Icons.flight;
      case 'home':
        return Icons.home;
      case 'directions_car':
        return Icons.directions_car;
      case 'school':
        return Icons.school;
      case 'phone_android':
        return Icons.phone_android;
      case 'favorite':
        return Icons.favorite;
      case 'beach_access':
        return Icons.beach_access;
      case 'celebration':
        return Icons.celebration;
      case 'savings':
      default:
        return Icons.savings;
    }
  }

  Color _colorFromHex(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF1E88E5);
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: 'Prazo para atingir a meta',
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_family == null) return;

    setState(() => _saving = true);
    try {
      final target = double.parse(_targetCtrl.text.replaceAll(',', '.'));

      if (isEditing) {
        final e = widget.existing!;
        final updated = GoalModel(
          id: e.id,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          targetAmount: target,
          currentAmount: e.currentAmount,
          deadline: _deadline,
          createdBy: e.createdBy,
          createdByName: e.createdByName,
          createdAt: e.createdAt,
          status: e.status,
          icon: _icon,
          color: _color,
        );
        await _service.updateGoal(familyId: _family!.id, goal: updated);
      } else {
        await _service.createGoal(
          familyId: _family!.id,
          name: _nameCtrl.text,
          description: _descCtrl.text,
          targetAmount: target,
          deadline: _deadline,
          icon: _icon,
          color: _color,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isEditing ? 'Meta atualizada.' : 'Meta criada!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ============================================================
  //  GUARDAR / RESGATAR valor da meta
  // ============================================================
  Future<void> _addValue(bool criarLancamento) async {
    if (_family == null || widget.existing == null) return;
    final txt = _addValueCtrl.text.replaceAll(',', '.').trim();
    if (txt.isEmpty) return;
    final value = double.tryParse(txt);
    if (value == null || value == 0) return;

    setState(() => _saving = true);
    try {
      await _service.addToGoal(
        familyId: _family!.id,
        goal: widget.existing!,
        amount: value,
        criarLancamento: criarLancamento,
      );
      if (!mounted) return;
      _addValueCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${value > 0 ? 'Guardado' : 'Resgatado'}: '
                  'R\$ ${value.abs().toStringAsFixed(2)}'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showAddValueSheet() {
    bool criarLancamento = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Guardar dinheiro',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Informe quanto quer adicionar (ou use valor negativo para resgatar).',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addValueCtrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Valor (R\$)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: criarLancamento,
                    onChanged: (v) =>
                        setModalState(() => criarLancamento = v ?? true),
                    title: const Text('Criar lançamento automático',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                      'Registra uma saída em "Metas e Objetivos"',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : () => _addValue(criarLancamento),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (!isEditing || _family == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir meta'),
        content:
        Text('Tem certeza que deseja excluir "${widget.existing!.name}"?'),
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
    try {
      await _service.deleteGoal(
        familyId: _family!.id,
        goalId: widget.existing!.id,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final cor = _colorFromHex(_color);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar meta' : 'Nova meta'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
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
                if (isEditing) ...[
                  _ProgressCard(
                    goal: widget.existing!,
                    color: cor,
                    onAdd: _showAddValueSheet,
                  ),
                  const SizedBox(height: 20),
                ],

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome da meta',
                    hintText: 'Ex: Viagem para a praia',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  validator: (v) => (v != null && v.trim().length >= 3)
                      ? null
                      : 'Mínimo 3 caracteres',
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _targetCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor alvo (R\$)',
                    hintText: 'Ex: 5000,00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o valor';
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Valor inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(_deadline == null
                        ? 'Sem prazo definido'
                        : 'Prazo: ${Formatters.date(_deadline!)}'),
                    trailing: _deadline == null
                        ? const Icon(Icons.add)
                        : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => _deadline = null),
                    ),
                    onTap: _deadline == null ? _pickDeadline : null,
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Ícone',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _icones.map((i) {
                    final selecionado = i == _icon;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _icon = i),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                            selecionado ? cor : Colors.grey.shade300,
                            width: selecionado ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: selecionado
                              ? cor.withValues(alpha: 0.1)
                              : null,
                        ),
                        child: Icon(_iconData(i),
                            color: selecionado ? cor : Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                const Text('Cor',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _cores.map((c) {
                    final selecionado = c == _color;
                    final cc = _colorFromHex(c);
                    return InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cc,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selecionado
                                ? Colors.black87
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: selecionado
                            ? const Icon(Icons.check,
                            color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: cor),
                    icon: _saving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.check),
                    label:
                    Text(isEditing ? 'Salvar alterações' : 'Criar meta'),
                    onPressed: _saving ? null : _save,
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

class _ProgressCard extends StatelessWidget {
  final GoalModel goal;
  final Color color;
  final VoidCallback onAdd;

  const _ProgressCard({
    required this.goal,
    required this.color,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progresso',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            Formatters.money(goal.currentAmount),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('de ${Formatters.money(goal.targetAmount)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('$pct%',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Guardar'),
                onPressed: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
