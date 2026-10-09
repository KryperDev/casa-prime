import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/data/auth_service.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../data/transaction_service.dart';
import '../../domain/category_model.dart';
import '../../domain/transaction_model.dart';
import 'add_transaction_screen.dart';
import 'transaction_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
//  Filtros
// ============================================================
class TransactionFilters {
  DateTime? startDate;
  DateTime? endDate;
  String? type;            // 'income' | 'expense' | null (ambos)
  String? categoryId;
  String? categoryName;
  String? memberId;
  String? memberName;
  String? paymentMethod;
  double? minAmount;
  double? maxAmount;
  String sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc, category

  int get activeCount {
    int c = 0;
    if (startDate != null) c++;
    if (endDate != null) c++;
    if (type != null) c++;
    if (categoryId != null) c++;
    if (memberId != null) c++;
    if (paymentMethod != null) c++;
    if (minAmount != null) c++;
    if (maxAmount != null) c++;
    return c;
  }

  bool get isEmpty => activeCount == 0;

  void clear() {
    startDate = null;
    endDate = null;
    type = null;
    categoryId = null;
    categoryName = null;
    memberId = null;
    memberName = null;
    paymentMethod = null;
    minAmount = null;
    maxAmount = null;
    sortBy = 'date_desc';
  }

  List<TransactionModel> apply(List<TransactionModel> input) {
    var list = input.where((t) {
      if (startDate != null) {
        final s = DateTime(startDate!.year, startDate!.month, startDate!.day);
        if (t.date.isBefore(s)) return false;
      }
      if (endDate != null) {
        final e = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
        if (t.date.isAfter(e)) return false;
      }
      if (type != null && t.type.name != type) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      if (memberId != null && t.createdBy != memberId) return false;
      if (paymentMethod != null && t.paymentMethod != paymentMethod) return false;
      if (minAmount != null && t.amount < minAmount!) return false;
      if (maxAmount != null && t.amount > maxAmount!) return false;
      return true;
    }).toList();

    switch (sortBy) {
      case 'date_asc':
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amount_desc':
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'category':
        list.sort((a, b) => a.categoryName.compareTo(b.categoryName));
        break;
      case 'date_desc':
      default:
        list.sort((a, b) => b.date.compareTo(a.date));
    }
    return list;
  }
}

// ============================================================
//  Tela principal
// ============================================================
class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  final _service = TransactionService();
  final _familyService = FamilyService();
  final _filters = TransactionFilters();

  void _openFiltersSheet(String familyId, FamilyModel family) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FiltersSheet(
        filters: _filters,
        familyId: familyId,
        family: family,
        onApply: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return StreamBuilder<FamilyModel?>(
      stream: _familyService.watchMyFamily(),
      builder: (context, famSnap) {
        if (!famSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final family = famSnap.data!;
        final isAdmin = family.adminId == auth.currentUser?.uid;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Lançamentos'),
            actions: [
              // Badge com contagem de filtros ativos
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Filtros',
                    onPressed: () => _openFiltersSheet(family.id, family),
                  ),
                  if (_filters.activeCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_filters.activeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (_filters.activeCount > 0)
                _ActiveFiltersBar(
                  filters: _filters,
                  onClear: () => setState(() => _filters.clear()),
                ),
              Expanded(
                child: StreamBuilder<List<TransactionModel>>(
                  stream: _service.watchTransactions(family.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Erro ao carregar: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    final all = snapshot.data ?? [];
                    final filtered = _filters.apply(all);

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            all.isEmpty
                                ? 'Nenhum lançamento ainda.\nToque no + para adicionar.'
                                : 'Nenhum lançamento corresponde aos filtros.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    // Agrupa por dia (só quando ordenado por data)
                    final isDateSort = _filters.sortBy == 'date_desc' ||
                        _filters.sortBy == 'date_asc';

                    if (!isDateSort) {
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _TransactionTile(
                          tx: filtered[i],
                          familyId: family.id,
                          isAdmin: isAdmin,
                        ),
                      );
                    }

                    final grouped = <String, List<TransactionModel>>{};
                    for (final t in filtered) {
                      final key = Formatters.date(t.date);
                      grouped.putIfAbsent(key, () => []).add(t);
                    }
                    final days = grouped.keys.toList();

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${filtered.length} lançamento(s)',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 96),
                            itemCount: days.length,
                            itemBuilder: (context, i) {
                              final day = days[i];
                              final items = grouped[day]!;
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 8),
                                    child: Text(
                                      day,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  ...items.map((t) => _TransactionTile(
                                        tx: t,
                                        familyId: family.id,
                                        isAdmin: isAdmin,
                                      )),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Novo'),
            onPressed: () => _showAddMenu(context, family.id),
          ),
        );
      },
    );
  }

  void _showAddMenu(BuildContext context, String familyId) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.green),
              title: const Text('Nova entrada'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(
                      type: TransactionType.income,
                      familyId: familyId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.red),
              title: const Text('Nova saída'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(
                      type: TransactionType.expense,
                      familyId: familyId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Barra de filtros ativos
// ============================================================
class _ActiveFiltersBar extends StatelessWidget {
  final TransactionFilters filters;
  final VoidCallback onClear;

  const _ActiveFiltersBar({required this.filters, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.blue.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${filters.activeCount} filtro(s) ativo(s)',
              style: const TextStyle(fontSize: 13, color: Colors.blue),
            ),
          ),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Sheet de filtros
// ============================================================
class _FiltersSheet extends StatefulWidget {
  final TransactionFilters filters;
  final String familyId;
  final FamilyModel family;
  final VoidCallback onApply;

  const _FiltersSheet({
    required this.filters,
    required this.familyId,
    required this.family,
    required this.onApply,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late TransactionFilters _local;
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  static const _paymentMethods = [
    'Dinheiro',
    'PIX',
    'Débito',
    'Crédito',
    'Boleto',
    'Transferência',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    // Cópia para não aplicar imediatamente
    _local = TransactionFilters()
      ..startDate = widget.filters.startDate
      ..endDate = widget.filters.endDate
      ..type = widget.filters.type
      ..categoryId = widget.filters.categoryId
      ..categoryName = widget.filters.categoryName
      ..memberId = widget.filters.memberId
      ..memberName = widget.filters.memberName
      ..paymentMethod = widget.filters.paymentMethod
      ..minAmount = widget.filters.minAmount
      ..maxAmount = widget.filters.maxAmount
      ..sortBy = widget.filters.sortBy;

    if (_local.minAmount != null) {
      _minCtrl.text = _local.minAmount!.toStringAsFixed(2);
    }
    if (_local.maxAmount != null) {
      _maxCtrl.text = _local.maxAmount!.toStringAsFixed(2);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_local.startDate ?? DateTime.now())
        : (_local.endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _local.startDate = picked;
        } else {
          _local.endDate = picked;
        }
      });
    }
  }

  Future<void> _apply() async {
    // Copia os valores locais para o objeto real
    final f = widget.filters;
    f.startDate = _local.startDate;
    f.endDate = _local.endDate;
    f.type = _local.type;
    f.categoryId = _local.categoryId;
    f.categoryName = _local.categoryName;
    f.memberId = _local.memberId;
    f.memberName = _local.memberName;
    f.paymentMethod = _local.paymentMethod;
    f.minAmount = _local.minAmount;
    f.maxAmount = _local.maxAmount;
    f.sortBy = _local.sortBy;

    widget.onApply();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Filtros',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _local.clear();
                      _minCtrl.clear();
                      _maxCtrl.clear();
                    }),
                    child: const Text('Limpar tudo'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Corpo rolável
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // ------- Tipo -------
                  const _Label('Tipo'),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _local.type == null,
                        onSelected: (_) =>
                            setState(() => _local.type = null),
                      ),
                      ChoiceChip(
                        label: const Text('Entradas'),
                        selected: _local.type == 'income',
                        onSelected: (_) =>
                            setState(() => _local.type = 'income'),
                      ),
                      ChoiceChip(
                        label: const Text('Saídas'),
                        selected: _local.type == 'expense',
                        onSelected: (_) =>
                            setState(() => _local.type = 'expense'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ------- Período -------
                  const _Label('Período'),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_local.startDate == null
                              ? 'De'
                              : Formatters.date(_local.startDate!)),
                          onPressed: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(_local.endDate == null
                              ? 'Até'
                              : Formatters.date(_local.endDate!)),
                          onPressed: () => _pickDate(isStart: false),
                        ),
                      ),
                      if (_local.startDate != null ||
                          _local.endDate != null)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _local.startDate = null;
                            _local.endDate = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ------- Categoria -------
                  const _Label('Categoria'),
                  _CategoryDropdown(
                    familyId: widget.familyId,
                    selectedId: _local.categoryId,
                    onChanged: (id, name) => setState(() {
                      _local.categoryId = id;
                      _local.categoryName = name;
                    }),
                  ),
                  const SizedBox(height: 20),

                  // ------- Membro -------
                  const _Label('Membro'),
                  _MemberDropdown(
                    memberIds: widget.family.memberIds,
                    selectedId: _local.memberId,
                    onChanged: (id, name) => setState(() {
                      _local.memberId = id;
                      _local.memberName = name;
                    }),
                  ),
                  const SizedBox(height: 20),

                  // ------- Forma de pagamento -------
                  const _Label('Forma de pagamento'),
                  DropdownButtonFormField<String>(
                    value: _local.paymentMethod,
                    decoration: const InputDecoration(
                      hintText: 'Qualquer',
                      isDense: true,
                    ),
                    items: _paymentMethods
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _local.paymentMethod = v),
                  ),
                  const SizedBox(height: 20),

                  // ------- Valor -------
                  const _Label('Valor (R\$)'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Mínimo',
                            isDense: true,
                          ),
                          onChanged: (v) => _local.minAmount = double.tryParse(
                              v.replaceAll(',', '.')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Máximo',
                            isDense: true,
                          ),
                          onChanged: (v) => _local.maxAmount = double.tryParse(
                              v.replaceAll(',', '.')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ------- Ordenar -------
                  const _Label('Ordenar por'),
                  DropdownButtonFormField<String>(
                    value: _local.sortBy,
                    decoration: const InputDecoration(isDense: true),
                    items: const [
                      DropdownMenuItem(
                          value: 'date_desc',
                          child: Text('Data (mais recentes)')),
                      DropdownMenuItem(
                          value: 'date_asc',
                          child: Text('Data (mais antigos)')),
                      DropdownMenuItem(
                          value: 'amount_desc',
                          child: Text('Valor (maior → menor)')),
                      DropdownMenuItem(
                          value: 'amount_asc',
                          child: Text('Valor (menor → maior)')),
                      DropdownMenuItem(
                          value: 'category',
                          child: Text('Categoria (A-Z)')),
                    ],
                    onChanged: (v) =>
                        setState(() => _local.sortBy = v ?? 'date_desc'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // ------- Aplicar -------
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Aplicar filtros'),
                    onPressed: _apply,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Dropdown de categoria (observa Firestore)
// ============================================================
class _CategoryDropdown extends StatelessWidget {
  final String familyId;
  final String? selectedId;
  final void Function(String? id, String? name) onChanged;

  const _CategoryDropdown({
    required this.familyId,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .collection('categories')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final cats = snapshot.data!.docs
            .map((d) => CategoryModel.fromMap(d.data() as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return DropdownButtonFormField<String?>(
          value: selectedId,
          decoration: const InputDecoration(
            hintText: 'Qualquer categoria',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Qualquer categoria'),
            ),
            ...cats.map((c) => DropdownMenuItem<String?>(
                  value: c.id,
                  child: Text(c.name),
                )),
          ],
          onChanged: (id) {
            String? name;
            if (id != null) {
              name = cats.firstWhere((c) => c.id == id).name;
            }
            onChanged(id, name);
          },
        );
      },
    );
  }
}

// ============================================================
//  Dropdown de membro (observa usuários da família)
// ============================================================
class _MemberDropdown extends StatelessWidget {
  final List<String> memberIds;
  final String? selectedId;
  final void Function(String? id, String? name) onChanged;

  const _MemberDropdown({
    required this.memberIds,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('users').where('familyId', isEqualTo: _familyId)
          .snapshots(),
      builder: (context, snapshot) {
        // fallback: se não dá pra consultar (regras), usa memberIds
        final docs = snapshot.data?.docs ?? [];
        final names = <String, String>{};
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          if (data['familyId'] == _familyId) {
            names[d.id] = (data['displayName'] ?? 'Usuário') as String;
          }
        }

        return DropdownButtonFormField<String?>(
          value: selectedId,
          decoration: const InputDecoration(
            hintText: 'Qualquer membro',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Qualquer membro'),
            ),
            ...names.entries.map((e) => DropdownMenuItem<String?>(
                  value: e.key,
                  child: Text(e.value),
                )),
          ],
          onChanged: (id) => onChanged(id, id == null ? null : names[id]),
        );
      },
    );
  }

  String get _familyId {
    // Necessário para o filtro de membros; ajustado pelo widget pai
    // (ver _FiltersSheet). Aqui usamos um hack: pega do primeiro
    // memberId via mapa implícito — mas como Firestore não permite
    // consultar "users where familyId == X" diretamente do lado
    // cliente sem permissão, deixamos o dropdown vazio se falhar.
    return _familyIdCache;
  }
}

// Cache estático simples para passar o familyId ao _MemberDropdown
String _familyIdCache = '';

// ============================================================
//  Label de seção
// ============================================================
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

// ============================================================
//  Tile de transação
// ============================================================
class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final String familyId;
  final bool isAdmin;

  const _TransactionTile({
    required this.tx,
    required this.familyId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;
    final color =
        isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final sign = isIncome ? '+' : '-';
    final auth = AuthService();
    final isMine = tx.createdBy == auth.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
          ),
        ),
        title: Text(tx.description,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${tx.categoryName}'
          '${tx.subcategoryName != null ? ' • ${tx.subcategoryName}' : ''}\n'
          'Adicionado por ${tx.createdByName} às ${Formatters.time(tx.createdAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$sign ${Formatters.money(tx.amount)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (isAdmin && !isMine)
              const Text('editar como admin',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailsScreen(
              tx: tx,
              familyId: familyId,
              isAdmin: isAdmin,
            ),
          ),
        ),
      ),
    );
  }
}
