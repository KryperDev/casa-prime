import 'package:flutter/material.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/error_translator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/formatters.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../../transactions/domain/category_model.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../data/recurring_service.dart';
import '../../domain/recurring_model.dart';

class EditRecurringScreen extends StatefulWidget {
  final RecurringModel? existing;
  const EditRecurringScreen({super.key, this.existing});

  @override
  State<EditRecurringScreen> createState() => _EditRecurringScreenState();
}

class _EditRecurringScreenState extends State<EditRecurringScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _service = RecurringService();
  final _familyService = FamilyService();

  TransactionType _type = TransactionType.expense;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  String? _categoryId;
  String? _subcategoryId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _active = true;

  FamilyModel? _family;
  bool _loading = true;
  bool _saving = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _descCtrl.text = e.description;
      _amountCtrl.text = e.amount.toStringAsFixed(2).replaceAll('.', ',');
      _noteCtrl.text = e.note ?? '';
      _type = e.type;
      _frequency = e.frequency;
      _categoryId = e.categoryId;
      _subcategoryId = e.subcategoryId;
      _startDate = e.startDate;
      _endDate = e.endDate;
      _active = e.active;
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
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_family == null || _categoryId == null) return;

    setState(() => _saving = true);
    try {
      final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));

      // Busca nome da categoria
      final catSnap = await FirebaseFirestore.instance
          .collection('families')
          .doc(_family!.id)
          .collection('categories')
          .doc(_categoryId)
          .get();
      final catName = catSnap.data()?['name'] ?? 'Categoria';

      String? subName;
      if (_subcategoryId != null && catSnap.data() != null) {
        final subs = (catSnap.data()!['subcategories'] ?? []) as List;
        for (final s in subs) {
          final m = Map<String, dynamic>.from(s);
          if (m['id'] == _subcategoryId) {
            subName = m['name'];
            break;
          }
        }
      }

      if (isEditing) {
        final e = widget.existing!;
        final updated = RecurringModel(
          id: e.id,
          familyId: e.familyId,
          description: _descCtrl.text.trim(),
          type: _type,
          amount: amount,
          categoryId: _categoryId!,
          categoryName: catName,
          subcategoryId: _subcategoryId,
          subcategoryName: subName,
          paymentMethod: e.paymentMethod,
          accountId: e.accountId,
          accountName: e.accountName,
          note: _noteCtrl.text.trim().isEmpty
              ? null
              : _noteCtrl.text.trim(),
          frequency: _frequency,
          startDate: _startDate,
          nextDate: e.nextDate,
          endDate: _endDate,
          active: _active,
          createdBy: e.createdBy,
          createdByName: e.createdByName,
          createdAt: e.createdAt,
        );
        await _service.updateRecurring(
            familyId: _family!.id, recurring: updated);
      } else {
        await _service.createRecurring(
          familyId: _family!.id,
          description: _descCtrl.text,
          type: _type,
          amount: amount,
          categoryId: _categoryId!,
          categoryName: catName,
          subcategoryId: _subcategoryId,
          subcategoryName: subName,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          frequency: _frequency,
          startDate: _startDate,
          endDate: _endDate,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isEditing
                ? 'Recorrência atualizada.'
                : 'Recorrência criada!')),
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

  Future<void> _confirmDelete() async {
    if (!isEditing || _family == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir recorrência'),
        content: const Text(
            'Os lançamentos já criados NÃO serão apagados. '
            'Somente a recorrência será removida.'),
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
      await _service.deleteRecurring(
        familyId: _family!.id,
        recurringId: widget.existing!.id,
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

    final isIncome = _type == TransactionType.income;
    final color =
        isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar recorrência' : 'Nova recorrência'),
        backgroundColor: color,
        foregroundColor: Colors.white,
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
                // Tipo
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Saída'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Entrada'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() {
                    _type = s.first;
                    _categoryId = null;
                    _subcategoryId = null;
                  }),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex: Salário, Aluguel, Netflix',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (v) => (v != null && v.trim().isNotEmpty)
                      ? null
                      : 'Informe a descrição',
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor (R\$)',
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

                // Categoria
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('families')
                      .doc(_family!.id)
                      .collection('categories')
                      .where('type', isEqualTo: _type.name)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final cats = snapshot.data!.docs
                        .map((d) => CategoryModel.fromMap(
                            d.data() as Map<String, dynamic>))
                        .toList();

                    return DropdownButtonFormField<String>(
                      value: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: cats
                          .map((c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _categoryId = v;
                        _subcategoryId = null;
                      }),
                      validator: (v) =>
                          v == null ? 'Selecione a categoria' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Frequência
                DropdownButtonFormField<RecurrenceFrequency>(
                  value: _frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequência',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: RecurrenceFrequency.values
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.label),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _frequency = v ?? _frequency),
                ),
                const SizedBox(height: 16),

                // Data início
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.play_arrow),
                    title: const Text('Início'),
                    subtitle: Text(Formatters.date(_startDate)),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),

                // Data fim (opcional)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.stop),
                    title: Text(_endDate == null
                        ? 'Sem data final (contínuo)'
                        : 'Encerra em ${Formatters.date(_endDate!)}'),
                    trailing: _endDate == null
                        ? const Icon(Icons.add)
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _endDate = null),
                          ),
                    onTap:
                        _endDate == null ? () => _pickDate(isStart: false) : null,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 16),

                if (isEditing)
                  SwitchListTile(
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                    title: const Text('Recorrência ativa'),
                    subtitle: const Text(
                        'Desative para pausar sem apagar o histórico'),
                  ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: color),
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: Text(isEditing
                        ? 'Salvar alterações'
                        : 'Criar recorrência'),
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

