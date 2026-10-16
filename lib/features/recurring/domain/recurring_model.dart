import 'package:cloud_firestore/cloud_firestore.dart';
import '../../transactions/domain/transaction_model.dart';

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

extension RecurrenceFrequencyX on RecurrenceFrequency {
  String get label {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Diária';
      case RecurrenceFrequency.weekly:
        return 'Semanal';
      case RecurrenceFrequency.monthly:
        return 'Mensal';
      case RecurrenceFrequency.yearly:
        return 'Anual';
    }
  }

  String get key {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'daily';
      case RecurrenceFrequency.weekly:
        return 'weekly';
      case RecurrenceFrequency.monthly:
        return 'monthly';
      case RecurrenceFrequency.yearly:
        return 'yearly';
    }
  }

  static RecurrenceFrequency fromKey(String key) {
    switch (key) {
      case 'daily':
        return RecurrenceFrequency.daily;
      case 'weekly':
        return RecurrenceFrequency.weekly;
      case 'yearly':
        return RecurrenceFrequency.yearly;
      case 'monthly':
      default:
        return RecurrenceFrequency.monthly;
    }
  }
}

class RecurringModel {
  final String id;
  final String familyId;
  final String description;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final String? paymentMethod;
  final String? accountId;
  final String? accountName;
  final String? note;
  final RecurrenceFrequency frequency;
  final DateTime startDate;      // quando começa
  final DateTime nextDate;       // próxima ocorrência
  final DateTime? endDate;       // quando termina (opcional)
  final bool active;             // pausar/retomar
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;

  RecurringModel({
    required this.id,
    required this.familyId,
    required this.description,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.paymentMethod,
    this.accountId,
    this.accountName,
    this.note,
    required this.frequency,
    required this.startDate,
    required this.nextDate,
    this.endDate,
    this.active = true,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
  });

  bool get isIncome => type == TransactionType.income;

  /// Calcula a próxima data a partir de uma data base.
  DateTime computeNext(DateTime from) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        final m = from.month + 1;
        final y = m > 12 ? from.year + 1 : from.year;
        final mm = m > 12 ? 1 : m;
        // Cuidado com meses com menos dias (ex: 31 jan → 28 fev)
        final lastDay = DateTime(y, mm + 1, 0).day;
        final day = from.day > lastDay ? lastDay : from.day;
        return DateTime(y, mm, day, from.hour, from.minute);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day,
            from.hour, from.minute);
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'familyId': familyId,
        'description': description,
        'type': type.name,
        'amount': amount,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'subcategoryId': subcategoryId,
        'subcategoryName': subcategoryName,
        'paymentMethod': paymentMethod,
        'accountId': accountId,
        'accountName': accountName,
        'note': note,
        'frequency': frequency.key,
        'startDate': Timestamp.fromDate(startDate),
        'nextDate': Timestamp.fromDate(nextDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'active': active,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory RecurringModel.fromMap(Map<String, dynamic> m) => RecurringModel(
        id: m['id'] ?? '',
        familyId: m['familyId'] ?? '',
        description: m['description'] ?? '',
        type: (m['type'] == 'income')
            ? TransactionType.income
            : TransactionType.expense,
        amount: (m['amount'] ?? 0).toDouble(),
        categoryId: m['categoryId'] ?? '',
        categoryName: m['categoryName'] ?? '',
        subcategoryId: m['subcategoryId'],
        subcategoryName: m['subcategoryName'],
        paymentMethod: m['paymentMethod'],
        accountId: m['accountId'],
        accountName: m['accountName'],
        note: m['note'],
        frequency: RecurrenceFrequencyX.fromKey(m['frequency'] ?? 'monthly'),
        startDate:
            (m['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        nextDate: (m['nextDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endDate: (m['endDate'] as Timestamp?)?.toDate(),
        active: m['active'] ?? true,
        createdBy: m['createdBy'] ?? '',
        createdByName: m['createdByName'] ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
