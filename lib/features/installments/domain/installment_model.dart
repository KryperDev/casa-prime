import 'package:cloud_firestore/cloud_firestore.dart';
import '../../transactions/domain/transaction_model.dart';

class InstallmentModel {
  final String id;           // purchaseId
  final String familyId;
  final String description;
  final double totalAmount;  // valor total da compra
  final double installmentAmount; // valor de cada parcela
  final int totalInstallments;
  final String categoryId;
  final String categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final String? paymentMethod;
  final String? accountId;
  final String? accountName;
  final String? note;
  final DateTime startDate;  // data da 1ª parcela
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;

  InstallmentModel({
    required this.id,
    required this.familyId,
    required this.description,
    required this.totalAmount,
    required this.installmentAmount,
    required this.totalInstallments,
    required this.categoryId,
    required this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.paymentMethod,
    this.accountId,
    this.accountName,
    this.note,
    required this.startDate,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'familyId': familyId,
        'description': description,
        'totalAmount': totalAmount,
        'installmentAmount': installmentAmount,
        'totalInstallments': totalInstallments,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'subcategoryId': subcategoryId,
        'subcategoryName': subcategoryName,
        'paymentMethod': paymentMethod,
        'accountId': accountId,
        'accountName': accountName,
        'note': note,
        'startDate': Timestamp.fromDate(startDate),
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory InstallmentModel.fromMap(Map<String, dynamic> m) => InstallmentModel(
        id: m['id'] ?? '',
        familyId: m['familyId'] ?? '',
        description: m['description'] ?? '',
        totalAmount: (m['totalAmount'] ?? 0).toDouble(),
        installmentAmount: (m['installmentAmount'] ?? 0).toDouble(),
        totalInstallments: (m['totalInstallments'] ?? 1).toInt(),
        categoryId: m['categoryId'] ?? '',
        categoryName: m['categoryName'] ?? '',
        subcategoryId: m['subcategoryId'],
        subcategoryName: m['subcategoryName'],
        paymentMethod: m['paymentMethod'],
        accountId: m['accountId'],
        accountName: m['accountName'],
        note: m['note'],
        startDate:
            (m['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdBy: m['createdBy'] ?? '',
        createdByName: m['createdByName'] ?? '',
        createdAt:
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  // === Helpers para UI ===
  static String typeName(TransactionType t) => t.name;
}
