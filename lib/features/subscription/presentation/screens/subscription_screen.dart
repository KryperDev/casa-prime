import 'package:flutter/material.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';

class SubscriptionScreen extends StatelessWidget {
  final FamilyModel family;

  const SubscriptionScreen({super.key, required this.family});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Escolha o plano ideal para a sua família',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Plano atual
          Card(
            color: Colors.blue.withValues(alpha: 0.08),
            child: ListTile(
              leading: const Icon(Icons.check_circle,
                  color: Colors.blue, size: 28),
              title: const Text('Seu plano atual'),
              subtitle: Text(
                family.planType.label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Plano GRÁTIS
          _PlanCard(
            title: 'Grátis',
            price: 'R\$ 0',
            period: 'para sempre',
            features: const [
              '✓ Até 2 membros',
              '✓ Lançamentos ilimitados',
              '✓ Relatórios em PDF',
              '✓ Categorias padrão (não editáveis)',
              '✗ Modo casal',
              '✗ Relatório por e-mail',
            ],
            isCurrent: family.planType == PlanType.free,
            isPopular: false,
            onSubscribe: family.planType == PlanType.free
                ? null
                : () => _changePlan(context, PlanType.free),
          ),
          const SizedBox(height: 12),

          // Plano FAMÍLIA (AGORA R$ 9,90)
          _PlanCard(
            title: 'Família',
            price: 'R\$ 9,90',
            period: 'por mês',
            features: const [
              '✓ Até 5 membros',
              '✓ Tudo do Grátis',
              '✓ Categorias personalizáveis',
              '✓ Parcelamento até 24x',
              '✗ Modo casal',
              '✗ Relatório por e-mail',
            ],
            isCurrent: family.planType == PlanType.family,
            isPopular: true,
            onSubscribe: family.planType == PlanType.family
                ? null
                : () => _changePlan(context, PlanType.family),
          ),
          const SizedBox(height: 12),

          // Plano PLUS (AGORA R$ 19,90)
          _PlanCard(
            title: 'Família Plus',
            price: 'R\$ 19,90',
            period: 'por mês',
            features: const [
              '✓ Até 10 membros',
              '✓ Tudo do Família',
              '✓ Modo Casal (split de contas)',
              '✓ Relatório mensal por e-mail',
              '✓ Backup completo em JSON',
              '✓ Suporte prioritário',
            ],
            isCurrent: family.planType == PlanType.plus,
            isPopular: false,
            onSubscribe: family.planType == PlanType.plus
                ? null
                : () => _changePlan(context, PlanType.plus),
          ),
          const SizedBox(height: 24),

          // Aviso
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pagamento será habilitado em breve. '
                    'No momento, os upgrades são cortesia para os primeiros usuários.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePlan(BuildContext context, PlanType newPlan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mudar de plano'),
        content: Text(
          'Deseja mudar para o plano ${newPlan.label}?\n\n'
          'Em produção, esta ação abrirá o checkout do Mercado Pago.',
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
      await FamilyService()
          .upgradePlan(familyId: family.id, newPlan: newPlan);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plano alterado para ${newPlan.label}!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isCurrent;
  final bool isPopular;
  final VoidCallback? onSubscribe;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.isCurrent,
    required this.isPopular,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? primary : Colors.grey.withValues(alpha: 0.2),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPopular)
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MAIS POPULAR',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
              ),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primary),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(period,
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    f,
                    style: TextStyle(
                        fontSize: 13,
                        color: f.startsWith('✗') ? Colors.grey : null),
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      child: const Text('Plano atual'),
                    )
                  : FilledButton(
                      onPressed: onSubscribe,
                      child: Text('Mudar para $title'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}