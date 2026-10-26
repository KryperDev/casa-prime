import 'package:cloud_firestore/cloud_firestore.dart';
import '../../transactions/domain/transaction_model.dart';
import '../domain/split_model.dart';

class SplitService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  //  Calcula os saldos entre membros com base nas transações
  //  com split (que têm splitShares).
  // ============================================================
  List<Balance> calculateBalances(List<TransactionModel> transactions) {
    // mapa de "quem pagou" -> "quanto pagou do total"
    // e "quem deve" -> "quanto deve para quem"
    // Estrutura: debt[devedor][credor] = valor
    final Map<String, Map<String, double>> debt = {};
    final Map<String, String> names = {};

    for (final tx in transactions) {
      final shares = tx.splitShares;
      if (shares == null || shares.isEmpty) continue;

      names[tx.createdBy] = tx.createdByName;
      for (final s in shares) {
        names[s.userId] = s.userName;
      }

      // Quem pagou (createdBy) pagou amount. Cada share indica
      // o percentual que aquela pessoa deveria ter pago.
      // Se share.userId != createdBy, aquela pessoa deve parte.
      for (final share in shares) {
        if (share.userId == tx.createdBy) continue;
        final devido = tx.amount * (share.percent / 100);
        debt.putIfAbsent(share.userId, () => {});
        debt[share.userId]![tx.createdBy] =
            (debt[share.userId]![tx.createdBy] ?? 0) + devido;
      }
    }

    // Simplifica: se A deve X para B, e B deve Y para A, compensa.
    final balances = <Balance>[];
    final processed = <String>{};

    for (final devedor in debt.keys) {
      for (final credor in debt[devedor]!.keys) {
        final pair = '$devedor|$credor';
        final reverse = '$credor|$devedor';
        if (processed.contains(pair) || processed.contains(reverse)) continue;

        final deve = debt[devedor]![credor] ?? 0;
        final contra = debt[credor]?[devedor] ?? 0;

        final net = deve - contra;
        if (net.abs() < 0.01) {
          processed.add(pair);
          continue;
        }

        if (net > 0) {
          balances.add(Balance(
            fromUserId: devedor,
            fromUserName: names[devedor] ?? 'Usuário',
            toUserId: credor,
            toUserName: names[credor] ?? 'Usuário',
            amount: net,
          ));
        } else {
          balances.add(Balance(
            fromUserId: credor,
            fromUserName: names[credor] ?? 'Usuário',
            toUserId: devedor,
            toUserName: names[devedor] ?? 'Usuário',
            amount: -net,
          ));
        }

        processed.add(pair);
        processed.add(reverse);
      }
    }

    return balances;
  }
}
