import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../family/domain/family_model.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../services/export_service.dart';

class ExportSheet extends StatefulWidget {
  final FamilyModel family;
  final List<TransactionModel> transactions;

  const ExportSheet({
    super.key,
    required this.family,
    required this.transactions,
  });

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  final _service = ExportService();

  String _format = 'pdf';     // pdf | csv
  String _scope = 'monthly';  // monthly | yearly
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  final Set<String> _types = {'income', 'expense'};
  final Set<String> _categoryNames = {};
  final Set<String> _memberNames = {};

  bool _loading = false;

  // Dados agregados para os filtros
  late final Set<String> _allCategories;
  late final Set<String> _allMembers;

  @override
  void initState() {
    super.initState();
    _allCategories = widget.transactions
        .map((t) => t.categoryName)
        .where((s) => s.isNotEmpty)
        .toSet();
    _allMembers = widget.transactions
        .map((t) => t.createdByName)
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  Future<void> _pickMonthYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, _month, 1),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Escolha o mês',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _year = picked.year;
        _month = picked.month;
      });
    }
  }

  Future<void> _pickYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, 1, 1),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Escolha o ano',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _year = picked.year);
    }
  }

  Future<void> _generate() async {
    if (_types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha ao menos um tipo.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final filters = ExportFilters(
        types: _types,
        categoryNames: _categoryNames,
        memberNames: _memberNames,
      );

      if (_format == 'pdf') {
        if (_scope == 'monthly') {
          await _service.exportPdfMonthly(
            familyName: widget.family.name,
            year: _year,
            month: _month,
            all: widget.transactions,
            filters: filters,
          );
        } else {
          await _service.exportPdfYearly(
            familyName: widget.family.name,
            year: _year,
            all: widget.transactions,
            filters: filters,
          );
        }
      } else {
        if (_scope == 'monthly') {
          await _service.exportCsvMonthly(
            year: _year,
            month: _month,
            all: widget.transactions,
            filters: filters,
          );
        } else {
          await _service.exportCsvYearly(
            year: _year,
            all: widget.transactions,
            filters: filters,
          );
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relatório gerado!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Exportar relatório',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Formato
                  const _Label('Formato'),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceCard(
                          icon: Icons.picture_as_pdf,
                          label: 'PDF',
                          subtitle: 'Bonito, para imprimir/arquivar',
                          selected: _format == 'pdf',
                          onTap: () => setState(() => _format = 'pdf'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ChoiceCard(
                          icon: Icons.table_chart,
                          label: 'CSV',
                          subtitle: 'Abre no Excel / Sheets',
                          selected: _format == 'csv',
                          onTap: () => setState(() => _format = 'csv'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Escopo
                  const _Label('Período'),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceCard(
                          icon: Icons.calendar_month,
                          label: 'Mensal',
                          subtitle: '1 mês',
                          selected: _scope == 'monthly',
                          onTap: () => setState(() => _scope = 'monthly'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ChoiceCard(
                          icon: Icons.calendar_today,
                          label: 'Anual',
                          subtitle: '12 meses',
                          selected: _scope == 'yearly',
                          onTap: () => setState(() => _scope = 'yearly'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Seletor de mês/ano
                  if (_scope == 'monthly')
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(
                            '${_monthName(_month)} de $_year',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.edit),
                        onTap: _pickMonthYear,
                      ),
                    )
                  else
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.event),
                        title: Text('Ano $_year',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.edit),
                        onTap: _pickYear,
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Tipos
                  const _Label('Tipos'),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Entradas'),
                        selected: _types.contains('income'),
                        onSelected: (on) => setState(() {
                          on
                              ? _types.add('income')
                              : _types.remove('income');
                        }),
                      ),
                      FilterChip(
                        label: const Text('Saídas'),
                        selected: _types.contains('expense'),
                        onSelected: (on) => setState(() {
                          on
                              ? _types.add('expense')
                              : _types.remove('expense');
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Categorias
                  if (_allCategories.isNotEmpty) ...[
                    const _Label('Categorias (opcional)'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _allCategories
                          .map((c) => FilterChip(
                                label: Text(c),
                                selected: _categoryNames.contains(c),
                                onSelected: (on) => setState(() {
                                  on
                                      ? _categoryNames.add(c)
                                      : _categoryNames.remove(c);
                                }),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Membros
                  if (_allMembers.isNotEmpty) ...[
                    const _Label('Membros (opcional)'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _allMembers
                          .map((m) => FilterChip(
                                label: Text(m),
                                selected: _memberNames.contains(m),
                                onSelected: (on) => setState(() {
                                  on
                                      ? _memberNames.add(m)
                                      : _memberNames.remove(m);
                                }),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    icon: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download),
                    label: const Text('Gerar e compartilhar'),
                    onPressed: _loading ? null : _generate,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    return names[m - 1];
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey)),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? Theme.of(context).colorScheme.primary : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
              color: color, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: selected ? color.withValues(alpha: 0.08) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

