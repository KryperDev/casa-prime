import 'package:cloud_firestore/cloud_firestore.dart';
import '../../transactions/domain/account_model.dart';

class AccountWithBalance {
  final AccountModel account;
  final double income;
  final double expense;

  const AccountWithBalance({
    required this.account,
    required this.income,
    required this.expense,
  });

  double get balance => income - expense;
}

class AccountService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  //  STREAMS
  // ============================================================
  Stream<List<AccountModel>> watchAccounts(String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('accounts')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AccountModel.fromMap(d.data()))
          .toList();
      list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  // ============================================================
  //  CREATE
  // ============================================================
  Future<String> createAccount({
    required String familyId,
    required String name,
    required String type,
  }) async {
    final col = _db
        .collection('families')
        .doc(familyId)
        .collection('accounts');
    final ref = col.doc();
    await ref.set({
      'id': ref.id,
      'name': name.trim(),
      'type': type,
    });
    return ref.id;
  }

  // ============================================================
  //  UPDATE
  // ============================================================
  Future<void> updateAccount({
    required String familyId,
    required AccountModel account,
    required String newName,
    required String newType,
  }) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('accounts')
        .doc(account.id)
        .update({
      'name': newName.trim(),
      'type': newType,
    });
  }

  // ============================================================
  //  DELETE com validação
  // ============================================================
  Future<int> countTransactionsUsingAccount({
    required String familyId,
    required String accountId,
  }) async {
    final snap = await _db
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .where('accountId', isEqualTo: accountId)
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs.length;
  }

  Future<void> deleteAccount({
    required String familyId,
    required String accountId,
  }) async {
    final count = await countTransactionsUsingAccount(
      familyId: familyId,
      accountId: accountId,
    );
    if (count > 0) {
      throw Exception(
        'Existem $count lançamento(s) usando esta conta. '
        'Não é possível excluí-la.',
      );
    }
    await _db
        .collection('families')
        .doc(familyId)
        .collection('accounts')
        .doc(accountId)
        .delete();
  }

  // ============================================================
  //  CÁLCULO DE SALDO
  //  Recebe a lista de transações da família (já vem do stream
  //  existente na tela) e agrega por accountId.
  // ============================================================
  static List<AccountWithBalance> computeBalances({
    required List<AccountModel> accounts,
    required List<dynamic> transactions,
  }) {
    final incomeMap = <String, double>{};
    final expenseMap = <String, double>{};

    for (final t in transactions) {
      final accountId = t.accountId as String?;
      if (accountId == null || accountId.isEmpty) continue;
      final amount = (t.amount as num).toDouble();
      final type = t.type.name as String;
      if (type == 'income') {
        incomeMap[accountId] = (incomeMap[accountId] ?? 0) + amount;
      } else {
        expenseMap[accountId] = (expenseMap[accountId] ?? 0) + amount;
      }
    }

    return accounts.map((a) {
      return AccountWithBalance(
        account: a,
        income: incomeMap[a.id] ?? 0,
        expense: expenseMap[a.id] ?? 0,
      );
    }).toList();
  }
}
