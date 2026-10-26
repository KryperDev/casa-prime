import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../../transactions/data/transaction_service.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../data/split_service.dart';
import '../../domain/split_model.dart';

class SplitScreen extends StatelessWidget {
  const SplitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyService = FamilyService();
    final txService = TransactionService();
    final splitService = SplitService();

    return StreamBuilder<FamilyModel?>(
      stream: familyService.watchMyFamily(),
      builder: (context, famSnap) {
        if (!famSnap.hasData) {
          return const Scaffold(body: ListSkeleton());
        }
        final family = famSnap.data!;

        if (!family.canUseCoupleMode) {
          return Scaffold(
            appBar: AppBar(title: const Text('Acerto de contas')),
            body: EmptyState(
              icon: Icons.lock_outline,
              title: 'Recurso exclusivo do Plus',
              subtitle:
                  'O Modo Casal está disponível apenas no plano Família Plus. '
                  'Faça upgrade para dividir despesas automaticamente entre os membros.',
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Acerto de contas')),
          body: StreamBuilder<List<TransactionModel>>(
            stream: txService.watchTransactions(family.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }
              final txs = snap.data ?? [];
              final balances = splitService.calculateBalances(txs);

              if (balances.isEmpty) {
                return const EmptyState(
                  icon: Icons.handshake_outlined,
                  title: 'Tudo em ordem!',
                  subtitle:
                      'Ninguém está devendo ninguém. As despesas divididas '
                      'aparecerão aqui quando forem criadas.',
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Colors.blue.withValues(alpha: 0.08),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Saldo calculado a partir das despesas divididas. '
                              'Marque como "pago" para zerar.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...balances.map((b) => _BalanceCard(
                        balance: b,
                        familyId: family.id,
                      )),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Balance balance;
  final String familyId;

  const _BalanceCard({required this.balance, required this.familyId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFE0E0),
                  child: Icon(Icons.arrow_forward, color: Color(0xFFC62828)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: balance.fromUserName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' deve '),
                        TextSpan(
                          text: Formatters.money(balance.amount),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC62828)),
                        ),
                        const TextSpan(text: ' a '),
                        TextSpan(
                          text: balance.toUserName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Marcar como pago'),
                onPressed: () => _markAsPaid(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsPaid(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar pagamento'),
        content: Text(
          'Confirmar que ${balance.fromUserName} pagou '
          '${Formatters.money(balance.amount)} a ${balance.toUserName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Cria uma entrada para quem recebeu (compensação)
      await TransactionService().addTransaction(
        familyId: familyId,
        type: TransactionType.income,
        amount: balance.amount,
        description: 'Acerto entre membros',
        categoryId: 'transfer',
        categoryName: 'Transferência entre membros',
        date: DateTime.now(),
        competenceDate: DateTime.now(),
        note: '${balance.fromUserName} pagou ${balance.toUserName}',
        notify: false,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acerto registrado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
