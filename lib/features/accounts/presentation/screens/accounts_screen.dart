import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../../transactions/domain/account_model.dart';
import '../../../transactions/data/transaction_service.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../data/account_service.dart';
import '../../data/account_types.dart';
import 'edit_account_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyService = FamilyService();
    final accountService = AccountService();
    final txService = TransactionService();

    return StreamBuilder<FamilyModel?>(
      stream: familyService.watchMyFamily(),
      builder: (context, famSnap) {
        if (!famSnap.hasData) {
          return const Scaffold(body: ListSkeleton());
        }
        final family = famSnap.data!;

        return Scaffold(
          appBar: AppBar(title: const Text('Contas')),
          body: StreamBuilder<List<AccountModel>>(
            stream: accountService.watchAccounts(family.id),
            builder: (context, accSnap) {
              if (accSnap.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }
              final accounts = accSnap.data ?? [];

              return StreamBuilder<List<TransactionModel>>(
                stream: txService.watchTransactions(family.id),
                builder: (context, txSnap) {
                  final txs = txSnap.data ?? [];
                  final withBalances = AccountService.computeBalances(
                    accounts: accounts,
                    transactions: txs,
                  );

                  if (accounts.isEmpty) {
                    return EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Nenhuma conta cadastrada',
                      subtitle:
                          'Cadastre suas contas para acompanhar o saldo de cada uma: dinheiro, conta corrente, poupança, cartão...',
                      actionLabel: 'Adicionar conta',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditAccountScreen(),
                        ),
                      ),
                    );
                  }

                  final total = withBalances.fold<double>(
                      0, (a, b) => a + b.balance);

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: total >= 0
                                ? [
                                    const Color(0xFF1565C0),
                                    const Color(0xFF1E88E5)
                                  ]
                                : [
                                    const Color(0xFFC62828),
                                    const Color(0xFFE53935)
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Saldo total das contas',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(
                              Formatters.money(total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${accounts.length} conta(s)',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ...withBalances.map((a) => _AccountTile(item: a)),
                    ],
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Nova conta'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EditAccountScreen(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccountTile extends StatelessWidget {
  final AccountWithBalance item;
  const _AccountTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final info = AccountTypes.byKey(item.account.type);
    final color = item.balance >= 0
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(info.icon, color: color),
        ),
        title: Text(item.account.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${info.label}\n'
          'Entradas: ${Formatters.money(item.income)}  •  '
          'Saídas: ${Formatters.money(item.expense)}',
          style: const TextStyle(fontSize: 11, height: 1.4),
        ),
        isThreeLine: true,
        trailing: Text(
          Formatters.money(item.balance),
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditAccountScreen(existing: item.account),
          ),
        ),
      ),
    );
  }
}

