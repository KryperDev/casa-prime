import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/installment_service.dart';
import '../../domain/installment_model.dart';
import '../../../transactions/domain/transaction_model.dart';

class InstallmentDetailsScreen extends StatelessWidget {
  final InstallmentModel installment;
  final String familyId;

  const InstallmentDetailsScreen({
    super.key,
    required this.installment,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context) {
    final service = InstallmentService();
    final color = const Color(0xFFC62828);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compra parcelada'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir compra',
            onPressed: () => _confirmDelete(context, service),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabeçalho
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    installment.description,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${installment.categoryName}'
                    '${installment.subcategoryName != null ? ' • ${installment.subcategoryName}' : ''}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _row('Valor total', Formatters.money(installment.totalAmount)),
                  _row(
                    'Parcelas',
                    '${installment.totalInstallments}x de '
                        '${Formatters.money(installment.installmentAmount)}',
                  ),
                  _row('Início', Formatters.date(installment.startDate)),
                  if (installment.paymentMethod != null)
                    _row('Pagamento', installment.paymentMethod!),
                  if (installment.accountName != null)
                    _row('Conta', installment.accountName!),
                  if (installment.note != null &&
                      installment.note!.isNotEmpty)
                    _row('Observação', installment.note!),
                  const Divider(height: 24),
                  _row('Criada por', installment.createdByName),
                  _row('Em', Formatters.dateTime(installment.createdAt)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'PARCELAS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
          ),
          StreamBuilder<List<TransactionModel>>(
            stream: service.watchPurchaseTransactions(
              familyId: familyId,
              purchaseId: installment.id,
            ),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator()));
              }
              final txs = snap.data!;
              final pagas = txs
                  .where((t) => t.date.isBefore(DateTime.now()))
                  .length;

              return Column(
                children: [
                  // Progresso
                  Card(
                    color: Colors.green.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$pagas de ${installment.totalInstallments} '
                              'parcelas já venceram',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...txs.map((t) => _ParcelaTile(tx: t)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(k,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            Expanded(
              child: Text(v,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14)),
            ),
          ],
        ),
      );

  Future<void> _confirmDelete(
      BuildContext context, InstallmentService service) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir compra parcelada'),
        content: Text(
          'Isso vai remover TODAS as '
          '${installment.totalInstallments} parcelas do histórico. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir tudo'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await service.deletePurchase(
      familyId: familyId,
      purchaseId: installment.id,
    );
    if (context.mounted) Navigator.pop(context);
  }
}

class _ParcelaTile extends StatelessWidget {
  final TransactionModel tx;
  const _ParcelaTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final vencida = tx.date.isBefore(DateTime.now());
    final color =
        vencida ? const Color(0xFFC62828) : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            '${tx.installmentNumber}/${tx.totalInstallments}',
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          'Parcela ${tx.installmentNumber}/${tx.totalInstallments}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Vence em ${Formatters.date(tx.date)}'
          '${vencida ? ' • vencida' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          Formatters.money(tx.amount),
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
