import 'package:flutter/material.dart';
import '../../../../core/utils/icon_helper.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../../transactions/domain/category_model.dart';
import '../../data/category_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/error_translator.dart';

class EditCategoryScreen extends StatefulWidget {
  final CategoryModel? existing;

  const EditCategoryScreen({super.key, this.existing});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _subCtrl = TextEditingController();
  final _service = CategoryService();
  final _familyService = FamilyService();

  late String _type;
  late String _icon;
  late List<SubcategoryModel> _subcategories;

  FamilyModel? _family;
  bool _loading = true;
  bool _saving = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl.text = e?.name ?? '';
    _type = e?.type ?? 'expense';
    _icon = e?.icon ?? 'category';
    _subcategories = List.from(e?.subcategories ?? []);
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
    _subCtrl.dispose();
    super.dispose();
  }

  void _addSubcategory() {
    final name = _subCtrl.text.trim();
    if (name.isEmpty) return;
    final id = name
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    // Evita duplicidade por id
    if (_subcategories.any((s) => s.id == id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Essa subcategoria já existe.')),
      );
      return;
    }
    setState(() {
      _subcategories.add(SubcategoryModel(id: id, name: name));
      _subCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_family == null) return;

    setState(() => _saving = true);
    try {
      if (isEditing) {
        await _service.updateCategory(
          familyId: _family!.id,
          category: widget.existing!,
          newName: _nameCtrl.text,
          newIcon: _icon,
          newSubcategories: _subcategories,
        );
      } else {
        await _service.createCategory(
          familyId: _family!.id,
          name: _nameCtrl.text,
          type: _type,
          icon: _icon,
        );
      }
      if (!mounted) return;
      AppSnackBar.sucesso(context, isEditing ? 'Categoria atualizada.' : 'Categoria criada.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final s = e.toString();
      final msg = s.contains(']') ? s.split(']').last.trim() : s;
      AppSnackBar.erro(context, ErrorTranslator.translate($msg));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (!isEditing || _family == null) return;
    setState(() => _saving = true);
    try {
      final count = await _service.countTransactionsUsingCategory(
        familyId: _family!.id,
        categoryId: widget.existing!.id,
      );
      if (!mounted) return;
      if (count > 0) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Não é possível excluir'),
            content: Text(
              'Existem $count lançamento(s) usando esta categoria.\n\n'
              'Para excluí-la, primeiro edite os lançamentos para '
              'outra categoria.',
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
          title: const Text('Excluir categoria'),
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

      await _service.deleteCategory(
        familyId: _family!.id,
        categoryId: widget.existing!.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria excluída.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final s = e.toString();
      final msg = s.contains(']') ? s.split(']').last.trim() : s;
      AppSnackBar.erro(context, ErrorTranslator.translate($msg));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pickIcon() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Escolha um ícone'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: IconHelper.allNames.length,
            itemBuilder: (context, i) {
              final name = IconHelper.allNames[i];
              final icon = IconHelper.allIcons[i];
              final selected = name == _icon;
              return InkWell(
                onTap: () {
                  setState(() => _icon = name);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: selected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1)
                        : null,
                  ),
                  child: Icon(icon, size: 24),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final isIncome = _type == 'income';
    final color = isIncome
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar categoria' : 'Nova categoria'),
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
                // Nome
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome da categoria',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) =>
                      (v != null && v.trim().length >= 2)
                          ? null
                          : 'Mínimo 2 caracteres',
                ),
                const SizedBox(height: 16),

                // Tipo (só na criação)
                if (!isEditing)
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'income',
                        label: Text('Entrada'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: 'expense',
                        label: Text('Saída'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) =>
                        setState(() => _type = s.first),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isIncome
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isIncome ? 'Entrada' : 'Saída',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        const Text(
                          'Tipo não pode ser alterado',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Ícone
                const Text('Ícone',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickIcon,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(IconHelper.getIcon(_icon), size: 32),
                        const SizedBox(width: 12),
                        const Text('Toque para escolher'),
                        const Spacer(),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Subcategorias
                const Text('Subcategorias',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Nome da subcategoria',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addSubcategory(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: _addSubcategory,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_subcategories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nenhuma subcategoria.',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12)),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _subcategories
                        .map((s) => Chip(
                              label: Text(s.name),
                              onDeleted: () => setState(
                                  () => _subcategories.remove(s)),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 32),

                // Salvar
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: color),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isEditing
                            ? 'Salvar alterações'
                            : 'Criar categoria'),
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

