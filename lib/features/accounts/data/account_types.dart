import 'package:flutter/material.dart';

class AccountTypeInfo {
  final String key;
  final String label;
  final IconData icon;

  const AccountTypeInfo({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class AccountTypes {
  static const List<AccountTypeInfo> all = [
    AccountTypeInfo(
        key: 'dinheiro', label: 'Dinheiro', icon: Icons.payments),
    AccountTypeInfo(
        key: 'corrente', label: 'Conta Corrente', icon: Icons.account_balance),
    AccountTypeInfo(
        key: 'poupanca', label: 'Poupança', icon: Icons.savings),
    AccountTypeInfo(
        key: 'carteira', label: 'Carteira Digital', icon: Icons.wallet),
    AccountTypeInfo(
        key: 'credito', label: 'Cartão de Crédito', icon: Icons.credit_card),
    AccountTypeInfo(
        key: 'digital', label: 'Conta Digital', icon: Icons.smartphone),
    AccountTypeInfo(
        key: 'investimento', label: 'Investimento', icon: Icons.trending_up),
    AccountTypeInfo(
        key: 'outro', label: 'Outro', icon: Icons.account_balance_wallet),
  ];

  static AccountTypeInfo byKey(String key) {
    return all.firstWhere(
      (t) => t.key == key,
      orElse: () => all.last,
    );
  }

  static IconData iconOf(String key) => byKey(key).icon;
  static String labelOf(String key) => byKey(key).label;
}
