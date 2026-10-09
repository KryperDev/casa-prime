class SubcategoryModel {
  final String id;
  final String name;
  const SubcategoryModel({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory SubcategoryModel.fromMap(Map<String, dynamic> m) =>
      SubcategoryModel(id: m['id'] ?? '', name: m['name'] ?? '');
}

class CategoryModel {
  final String id;
  final String name;
  final String type; // 'income' | 'expense'
  final String icon; // nome do ícone (guarda como string)
  final List<SubcategoryModel> subcategories;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.icon = 'category',
    this.subcategories = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'icon': icon,
        'subcategories': subcategories.map((s) => s.toMap()).toList(),
      };

  factory CategoryModel.fromMap(Map<String, dynamic> m) => CategoryModel(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        type: m['type'] ?? 'expense',
        icon: m['icon'] ?? 'category',
        subcategories: ((m['subcategories'] ?? []) as List)
            .map((e) => SubcategoryModel.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );
}