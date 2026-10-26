import 'package:cloud_firestore/cloud_firestore.dart';
import '../../split/domain/split_model.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String familyId;
  final TransactionType type;
  final double amount;
  final String description;
  final String categoryId;
  final String categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final DateTime date;
  final DateTime competenceDate;
  final String? paymentMethod;
  final String? accountId;
  final String? accountName;
  final String? note;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final String? goalId;
  final String? purchaseId;      // compra parcelada
  final int? installmentNumber;  // 1, 2, 3...
  final int? totalInstallments;
  final List<SplitShare>? splitShares;  // 12, 24...

  TransactionModel({
    required this.id,
    required this.familyId,
    required this.type,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    required this.date,
    required this.competenceDate,
    this.paymentMethod,
    this.accountId,
    this.accountName,
    this.note,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
    this.goalId,
    this.purchaseId,
    this.installmentNumber,
    this.totalInstallments,
    this.splitShares,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isInstallment => purchaseId != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'familyId': familyId,
        'type': type.name,
        'amount': amount,
        'description': description,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'subcategoryId': subcategoryId,
        'subcategoryName': subcategoryName,
        'date': Timestamp.fromDate(date),
        'competenceDate': Timestamp.fromDate(competenceDate),
        'paymentMethod': paymentMethod,
        'accountId': accountId,
        'accountName': accountName,
        'note': note,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'status': status,
        'goalId': goalId,
        'purchaseId': purchaseId,
        'installmentNumber': installmentNumber,
        'totalInstallments': totalInstallments,
        'splitShares': splitShares?.map((s) => s.toMap()).toList(),
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
        id: map['id'] ?? '',
        familyId: map['familyId'] ?? '',
        type: (map['type'] == 'income')
            ? TransactionType.income
            : TransactionType.expense,
        amount: (map['amount'] ?? 0).toDouble(),
        description: map['description'] ?? '',
        categoryId: map['categoryId'] ?? '',
        categoryName: map['categoryName'] ?? '',
        subcategoryId: map['subcategoryId'],
        subcategoryName: map['subcategoryName'],
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        competenceDate:
            (map['competenceDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        paymentMethod: map['paymentMethod'],
        accountId: map['accountId'],
        accountName: map['accountName'],
        note: map['note'],
        createdBy: map['createdBy'] ?? '',
        createdByName: map['createdByName'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: map['status'] ?? 'active',
        goalId: map['goalId'],
        purchaseId: map['purchaseId'],
        installmentNumber: map['installmentNumber'],
        totalInstallments: map['totalInstallments'],
        splitShares: (map['splitShares'] as List?)
            ?.map((s) => SplitShare.fromMap(Map<String, dynamic>.from(s)))
            .toList(),
      );
}

