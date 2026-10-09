import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/data/auth_service.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../data/transaction_service.dart';
import '../../domain/transaction_model.dart';
import 'add_transaction_screen.dart';
import 'transaction_details_screen.dart';

class TransactionsListScreen extends StatelessWidget {
  const TransactionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = TransactionService();
    final familyService = FamilyService();
    final auth = AuthService();

    return StreamBuilder<FamilyModel?>(
      stream: familyService.watchMyFamily(),
      builder: (context, famSnap) {
        if (!famSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final family = famSnap.data!;
        final isAdmin = family.adminId == auth.currentUser?.uid;

        return Scaffold(
          appBar: AppBar(title: const Text('Lançamentos')),
          body: StreamBuilder<List<TransactionModel>>(
            stream: service.watchTransactions(family.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erro ao carregar: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhum lançamento ainda.\nToque no ➕ para adicionar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              final grouped = <String, List<TransactionModel>>{};
              for (final t in list) {
                final key = Formatters.date(t.date);
                grouped.putIfAbsent(key, () => []).add(t);
              }
              final days = grouped.keys.toList();

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: days.length,
                itemBuilder: (context, i) {
                  final day = days[i];
                  final items = grouped[day]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ...items.map((t) => _TransactionTile(
                        tx: t,
                        familyId: family.id,
                        isAdmin: isAdmin,
                      )),
                    ],
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Novo'),
            onPressed: () => _showAddMenu(context, family.id),
          ),
        );
      },
    );
  }

  void _showAddMenu(BuildContext context, String familyId) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.green),
              title: const Text('Nova entrada'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(
                      type: TransactionType.income,
                      familyId: familyId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.red),
              title: const Text('Nova saída'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(
                      type: TransactionType.expense,
                      familyId: familyId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final String familyId;
  final bool isAdmin;

  const _TransactionTile({
    required this.tx,
    required this.familyId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;
    final color = isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final sign = isIncome ? '+' : '-';
    final auth = AuthService();
    final isMine = tx.createdBy == auth.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
          ),
        ),
        title: Text(tx.description,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${tx.categoryName}'
              '${tx.subcategoryName != null ? ' • ${tx.subcategoryName}' : ''}\n'
              'Adicionado por ${tx.createdByName} às ${Formatters.time(tx.createdAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$sign ${Formatters.money(tx.amount)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (isAdmin && !isMine)
              const Text('editar como admin',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailsScreen(
              tx: tx,
              familyId: familyId,
              isAdmin: isAdmin,
            ),
          ),
        ),
      ),
    );
  }
}