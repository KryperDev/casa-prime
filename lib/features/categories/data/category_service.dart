import 'package:cloud_firestore/cloud_firestore.dart';
import '../../transactions/domain/category_model.dart';

class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  //  STREAMS
  // ============================================================
  Stream<List<CategoryModel>> watchCategories(String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('categories')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => CategoryModel.fromMap(d.data()))
          .toList();
      // Ordena: primeiro tipo (entrada antes de saída), depois nome
      list.sort((a, b) {
        if (a.type != b.type) return a.type.compareTo(b.type);
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return list;
    });
  }

  // ============================================================
  //  CREATE
  // ============================================================
  Future<String> createCategory({
    required String familyId,
    required String name,
    required String type, // 'income' | 'expense'
    required String icon,
  }) async {
    final col = _db
        .collection('families')
        .doc(familyId)
        .collection('categories');
    final ref = col.doc();
    await ref.set({
      'id': ref.id,
      'name': name.trim(),
      'type': type,
      'icon': icon,
      'subcategories': <Map<String, dynamic>>[],
    });
    return ref.id;
  }

  // ============================================================
  //  UPDATE (nome, ícone e subcategorias)
  // ============================================================
  Future<void> updateCategory({
    required String familyId,
    required CategoryModel category,
    required String newName,
    required String newIcon,
    required List<SubcategoryModel> newSubcategories,
  }) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('categories')
        .doc(category.id)
        .update({
      'name': newName.trim(),
      'icon': newIcon,
      'subcategories':
          newSubcategories.map((s) => s.toMap()).toList(),
      // 'type' não é editável — mantém o existente
    });
  }

  // ============================================================
  //  DELETE (com validação: bloqueia se houver lançamentos)
  // ============================================================
  /// Retorna o número de lançamentos ativos que usam esta categoria.
  Future<int> countTransactionsUsingCategory({
    required String familyId,
    required String categoryId,
  }) async {
    final snap = await _db
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .where('categoryId', isEqualTo: categoryId)
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs.length;
  }

  Future<void> deleteCategory({
    required String familyId,
    required String categoryId,
  }) async {
    // Segurança extra: só apaga se não houver lançamentos ativos
    final count = await countTransactionsUsingCategory(
      familyId: familyId,
      categoryId: categoryId,
    );
    if (count > 0) {
      throw Exception(
        'Existem $count lançamento(s) usando esta categoria. '
        'Não é possível excluí-la.',
      );
    }
    await _db
        .collection('families')
        .doc(familyId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }
}
