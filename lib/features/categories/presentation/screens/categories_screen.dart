import 'package:flutter/material.dart';
import '../../../../core/utils/icon_helper.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../../transactions/domain/category_model.dart';
import '../../data/category_service.dart';
import 'edit_category_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyService = FamilyService();
    final categoryService = CategoryService();

    return StreamBuilder<FamilyModel?>(
      stream: familyService.watchMyFamily(),
      builder: (context, famSnap) {
        if (!famSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final family = famSnap.data!;

        return Scaffold(
          appBar: AppBar(title: const Text('Categorias')),
          body: StreamBuilder<List<CategoryModel>>(
            stream: categoryService.watchCategories(family.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data ?? [];
              if (all.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Nenhuma categoria criada.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              final incomes =
                  all.where((c) => c.type == 'income').toList();
              final expenses =
                  all.where((c) => c.type == 'expense').toList();

              return ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  if (incomes.isNotEmpty) ...[
                    const _SectionHeader(
                      title: 'Entradas',
                      icon: Icons.arrow_downward,
                      color: Color(0xFF2E7D32),
                    ),
                    ...incomes.map((c) => _CategoryTile(
                          category: c,
                          familyId: family.id,
                        )),
                  ],
                  if (expenses.isNotEmpty) ...[
                    const _SectionHeader(
                      title: 'Saídas',
                      icon: Icons.arrow_upward,
                      color: Color(0xFFC62828),
                    ),
                    ...expenses.map((c) => _CategoryTile(
                          category: c,
                          familyId: family.id,
                        )),
                  ],
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Nova categoria'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EditCategoryScreen(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final String familyId;

  const _CategoryTile({
    required this.category,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = category.type == 'income';
    final color = isIncome
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(IconHelper.getIcon(category.icon), color: color),
        ),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          category.subcategories.isEmpty
              ? 'Sem subcategorias'
              : '${category.subcategories.length} subcategoria(s)',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditCategoryScreen(existing: category),
          ),
        ),
      ),
    );
  }
}
