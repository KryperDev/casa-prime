import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../data/installment_service.dart';
import '../../domain/installment_model.dart';
import 'installment_details_screen.dart';

class InstallmentsScreen extends StatelessWidget {
  const InstallmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyService = FamilyService();
    final service = InstallmentService();

    return StreamBuilder<FamilyModel?>(
      stream: familyService.watchMyFamily(),
      builder: (context, famSnap) {
        if (!famSnap.hasData) {
          return const Scaffold(body: ListSkeleton());
        }
        final family = famSnap.data!;

        return Scaffold(
          appBar: AppBar(title: const Text('Compras parceladas')),
          body: StreamBuilder<List<InstallmentModel>>(
            stream: service.watchInstallments(family.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }
              final list = snap.data ?? [];

              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.credit_card,
                  title: 'Nenhuma compra parcelada',
                  subtitle:
                      'Quando você cria uma saída, marque a opção "Compra parcelada no cartão" para dividir em N vezes.',
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: list
                    .map((i) => _InstallmentCard(
                          installment: i,
                          familyId: family.id,
                        ))
                    .toList(),
              );
            },
          ),
        );
      },
    );
  }
}

class _InstallmentCard extends StatelessWidget {
  final InstallmentModel installment;
  final String familyId;

  const _InstallmentCard({
    required this.installment,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFC62828);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InstallmentDetailsScreen(
              installment: installment,
              familyId: familyId,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(Icons.credit_card, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          installment.description,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${installment.categoryName} • '
                          '${installment.totalInstallments}x de '
                          '${Formatters.money(installment.installmentAmount)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${Formatters.money(installment.totalAmount)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Início: ${Formatters.date(installment.startDate)}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
