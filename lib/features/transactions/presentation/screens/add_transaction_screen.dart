import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/formatters.dart';
import '../../../accounts/data/account_service.dart';
import '../../../accounts/data/account_types.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../../installments/data/installment_service.dart';
import '../../data/transaction_service.dart';
import '../../domain/account_model.dart';
import '../../domain/category_model.dart';
import '../../domain/transaction_model.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType type;
  final String familyId;
  final TransactionModel? existing;

  const AddTransactionScreen({
    super.key,
    required this.type,
    required this.familyId,
    this.existing,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _service = TransactionService();
  final _accountService = AccountService();
  final _installmentService = InstallmentService();

  String? _categoryId;
  String? _subcategoryId;
  String? _accountId;
  late DateTime _date;
  late DateTime _competence;
  String? _paymentMethod;
  bool _loading = false;
  bool _isInstallment = false;
  int _installmentCount = 2;
  FamilyModel? _family;

  bool get isEditing => widget.existing != null;

  static const _paymentMethods = [
    'Dinheiro', 'PIX', 'Débito', 'Crédito', 'Boleto',
    'Transferência', 'Outros',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amountCtrl.text = e.amount.toStringAsFixed(2).replaceAll('.', ',');
      _descCtrl.text = e.description;
      _noteCtrl.text = e.note ?? '';
      _categoryId = e.categoryId;
      _subcategoryId = e.subcategoryId;
      _accountId = e.accountId;
      _date = e.date;
      _competence = e.competenceDate;
      _paymentMethod = e.paymentMethod;
    } else {
      _date = DateTime.now();
      _competence = DateTime.now();
    }
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    final f = await FamilyService().fetchMyFamily();
    if (!mounted) return;
    setState(() => _family = f);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isCompetence}) async {
    final initial = isCompetence ? _competence : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isCompetence) {
          _competence = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  Future<void> _submit(
    List<CategoryModel> categories,
    List<AccountModel> accounts,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria.')),
      );
      return;
    }

    final category = categories.firstWhere((c) => c.id == _categoryId!);
    final subcategory = _subcategoryId == null
        ? null
        : category.subcategories.firstWhere((s) => s.id == _subcategoryId!);
    final account = _accountId == null
        ? null
        : accounts.firstWhere((a) => a.id == _accountId!);

    setState(() => _loading = true);
    try {
      final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));

      // Compra parcelada
      if (_isInstallment && !isEditing) {
        await _installmentService.createInstallmentPurchase(
          familyId: widget.familyId,
          description: _descCtrl.text.trim(),
          totalAmount: amount,
          totalInstallments: _installmentCount,
          categoryId: category.id,
          categoryName: category.name,
          subcategoryId: subcategory?.id,
          subcategoryName: subcategory?.name,
          paymentMethod: _paymentMethod,
          accountId: account?.id,
          accountName: account?.name,
          note: _noteCtrl.text.trim().isEmpty
              ? null
              : _noteCtrl.text.trim(),
          startDate: _date,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Compra parcelada em $_installmentCount vezes criada!',
            ),
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      // Fluxo normal
      if (isEditing) {
        final old = widget.existing!;
        final updated = TransactionModel(
          id: old.id,
          familyId: old.familyId,
          type: widget.type,
          amount: amount,
          description: _descCtrl.text.trim(),
          categoryId: category.id,
          categoryName: category.name,
          subcategoryId: subcategory?.id,
          subcategoryName: subcategory?.name,
          date: _date,
          competenceDate: _competence,
          paymentMethod: _paymentMethod,
          accountId: account?.id,
          accountName: account?.name,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          createdBy: old.createdBy,
          createdByName: old.createdByName,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
          status: old.status,
          goalId: old.goalId,
          purchaseId: old.purchaseId,
          installmentNumber: old.installmentNumber,
          totalInstallments: old.totalInstallments,
        );

        await _service.updateTransaction(
          familyId: widget.familyId,
          old: old,
          updated: updated,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lançamento atualizado.')),
        );
      } else {
        await _service.addTransaction(
          familyId: widget.familyId,
          type: widget.type,
          amount: amount,
          description: _descCtrl.text.trim(),
          categoryId: category.id,
          categoryName: category.name,
          subcategoryId: subcategory?.id,
          subcategoryName: subcategory?.name,
          date: _date,
          competenceDate: _competence,
          paymentMethod: _paymentMethod,
          accountId: account?.id,
          accountName: account?.name,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.type == TransactionType.income
                ? 'Entrada adicionada com sucesso.'
                : 'Despesa registrada com sucesso.'),
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == TransactionType.income;
    final color =
        isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final title = isEditing
        ? (isIncome ? 'Editar entrada' : 'Editar saída')
        : (isIncome ? 'Nova entrada' : 'Nova saída');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('families')
              .doc(widget.familyId)
              .collection('categories')
              .where('type', isEqualTo: widget.type.name)
              .snapshots(),
          builder: (context, catSnap) {
            if (catSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!catSnap.hasData || catSnap.data!.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nenhuma categoria encontrada.\n'
                    'Crie uma em Perfil → Categorias.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final categories = catSnap.data!.docs
                .map((d) => CategoryModel.fromMap(
                    d.data() as Map<String, dynamic>))
                .toList();

            if (_categoryId != null &&
                !categories.any((c) => c.id == _categoryId)) {
              _categoryId = null;
              _subcategoryId = null;
            }

            final selectedCategory = _categoryId == null
                ? null
                : categories.firstWhere((c) => c.id == _categoryId);

            return StreamBuilder<List<AccountModel>>(
              stream: _accountService.watchAccounts(widget.familyId),
              builder: (context, accSnap) {
                final accounts = accSnap.data ?? [];

                // Trava de parcelas baseada no plano
                final maxInstallments =
                    _family?.planType == PlanType.free ? 12 : 24;
                final opcoesParcelas = [
                  2, 3, 4, 5, 6, 7, 8, 10, 12, 18, 24
                ].where((n) => n <= maxInstallments).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _amountCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: InputDecoration(
                            labelText: _isInstallment
                                ? 'Valor total da compra (R\$)'
                                : 'Valor (R\$)',
                            prefixIcon: const Icon(Icons.attach_money),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe o valor';
                            }
                            final n = double.tryParse(
                                v.replaceAll(',', '.'));
                            if (n == null || n <= 0) {
                              return 'Valor inválido';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            prefixIcon:
                                Icon(Icons.description_outlined),
                          ),
                          validator: (v) =>
                              (v != null && v.trim().isNotEmpty)
                                  ? null
                                  : 'Informe a descrição',
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _categoryId,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: categories
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
                        ),
                        if (selectedCategory != null &&
                            selectedCategory.subcategories.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _subcategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Subcategoria (opcional)',
                              prefixIcon:
                                  Icon(Icons.subdirectory_arrow_right),
                            ),
                            items: selectedCategory.subcategories
                                .map((s) => DropdownMenuItem<String>(
                                      value: s.id,
                                      child: Text(s.name),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _subcategoryId = v),
                          ),
                        ],
                        const SizedBox(height: 16),

                        if (accounts.isNotEmpty)
                          DropdownButtonFormField<String>(
                            value: _accountId,
                            decoration: const InputDecoration(
                              labelText: 'Conta (opcional)',
                              prefixIcon: Icon(
                                  Icons.account_balance_wallet_outlined),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Sem conta'),
                              ),
                              ...accounts.map((a) {
                                final info = AccountTypes.byKey(a.type);
                                return DropdownMenuItem<String>(
                                  value: a.id,
                                  child: Row(
                                    children: [
                                      Icon(info.icon, size: 18),
                                      const SizedBox(width: 8),
                                      Text(a.name),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (v) =>
                                setState(() => _accountId = v),
                          ),
                        if (accounts.isNotEmpty)
                          const SizedBox(height: 16),

                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Data'),
                          subtitle: Text(Formatters.date(_date)),
                          trailing: const Icon(Icons.edit),
                          onTap: () => _pickDate(isCompetence: false),
                        ),

                        if (!_isInstallment)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.event_note),
                            title: const Text('Competência'),
                            subtitle: Text(Formatters.date(_competence)),
                            trailing: const Icon(Icons.edit),
                            onTap: () => _pickDate(isCompetence: true),
                          ),
                        const SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Forma de pagamento (opcional)',
                            prefixIcon: Icon(Icons.payment),
                          ),
                          items: _paymentMethods
                              .map((m) => DropdownMenuItem<String>(
                                    value: m,
                                    child: Text(m),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _paymentMethod = v),
                        ),
                        const SizedBox(height: 16),

                        if (!isIncome && !isEditing) ...[
                          Card(
                            color: _isInstallment
                                ? color.withValues(alpha: 0.08)
                                : null,
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  value: _isInstallment,
                                  onChanged: (v) => setState(() {
                                    _isInstallment = v ?? false;
                                    if (_isInstallment &&
                                        _paymentMethod == null) {
                                      _paymentMethod = 'Crédito';
                                    }
                                  }),
                                  title: const Text(
                                      'Compra parcelada no cartão'),
                                  subtitle: const Text(
                                    'Cria automaticamente N lançamentos mensais',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                                if (_isInstallment)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text('Número de parcelas',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey)),
                                            const Spacer(),
                                            if (_family?.planType ==
                                                PlanType.free)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                    'Máx. 12x (Grátis)',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.orange)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: opcoesParcelas
                                              .map((n) => ChoiceChip(
                                                    label: Text('${n}x'),
                                                    selected:
                                                        _installmentCount == n,
                                                    onSelected: (_) =>
                                                        setState(() =>
                                                            _installmentCount =
                                                                n),
                                                  ))
                                              .toList(),
                                        ),
                                        if (_amountCtrl.text.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Builder(
                                            builder: (_) {
                                              final total = double.tryParse(
                                                      _amountCtrl.text
                                                          .replaceAll(
                                                              ',', '.')) ??
                                                  0;
                                              final parcela = total /
                                                  _installmentCount;
                                              return Text(
                                                '$_installmentCount parcelas de '
                                                '${Formatters.money(parcela)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: color,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextFormField(
                          controller: _noteCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Observação (opcional)',
                            prefixIcon: Icon(Icons.notes),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: color),
                            onPressed: _loading
                                ? null
                                : () => _submit(categories, accounts),
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : Text(
                                    _isInstallment
                                        ? 'Criar compra parcelada'
                                        : isEditing
                                            ? 'Salvar alterações'
                                            : (isIncome
                                                ? 'Adicionar entrada'
                                                : 'Adicionar saída')),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}