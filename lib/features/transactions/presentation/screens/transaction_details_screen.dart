import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/transaction_service.dart';
import '../../domain/transaction_model.dart';
import 'add_transaction_screen.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final TransactionModel tx;
  final String familyId;
  /// Se `true`, o usuário atual é administrador da família
  /// e pode editar/excluir qualquer lançamento.
  final bool isAdmin;

  const TransactionDetailsScreen({
    super.key,
    required this.tx,
    required this.familyId,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;
    final color = isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final auth = AuthService();
    final service = TransactionService();
    final isMine = tx.createdBy == auth.currentUser?.uid;
    final canEdit = isMine || isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTransactionScreen(
                        type: tx.type,
                        familyId: familyId,
                        existing: tx,
                      ),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                } else if (v == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Excluir lançamento'),
                      content: const Text(
                          'Tem certeza que deseja excluir este lançamento?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Excluir'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await service.deleteTransaction(
                      familyId: familyId,
                      tx: tx,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Lançamento excluído.')),
                      );
                      Navigator.pop(context);
                    }
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Editar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Excluir',
                        style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: color,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${isIncome ? '+' : '-'} ${Formatters.money(tx.amount)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(tx.description,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _row('Tipo', isIncome ? 'Entrada' : 'Saída'),
          _row('Categoria', tx.categoryName),
          if (tx.subcategoryName != null)
            _row('Subcategoria', tx.subcategoryName!),
          _row('Data', Formatters.date(tx.date)),
          _row('Hora', Formatters.time(tx.createdAt)),
          _row('Competência', Formatters.date(tx.competenceDate)),
          if (tx.paymentMethod != null)
            _row('Forma de pagamento', tx.paymentMethod!),
          if (tx.accountName != null) _row('Conta', tx.accountName!),
          if (tx.note != null && tx.note!.isNotEmpty)
            _row('Observação', tx.note!),

          const Divider(height: 32),

          _row('Adicionado por', tx.createdByName),
          _row('Em', Formatters.dateTime(tx.createdAt)),
          if (tx.updatedAt.difference(tx.createdAt).inSeconds.abs() > 1)
            _row('Última alteração', Formatters.dateTime(tx.updatedAt)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}