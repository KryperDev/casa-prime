import 'package:flutter/material.dart';
import '../../../goals/presentation/screens/goals_screen.dart';
import '../../../installments/presentation/screens/installments_screen.dart';
import '../../../recurring/presentation/screens/recurrings_screen.dart';
import '../../../split/presentation/screens/split_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mais opções')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Mais ferramentas para organizar sua vida financeira',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          _tile(
            context,
            icon: Icons.handshake,
            color: const Color(0xFFFF7043),
            title: 'Acerto de contas',
            subtitle: 'Quem deve quanto a quem (Plus)',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SplitScreen(),
              ),
            ),
          ),
          _tile(
            context,
            icon: Icons.repeat,
            color: const Color(0xFF1E88E5),
            title: 'Lançamentos recorrentes',
            subtitle: 'Salário, aluguel, Netflix e outros que se repetem',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RecurringsScreen(),
              ),
            ),
          ),
          _tile(
            context,
            icon: Icons.credit_card,
            color: const Color(0xFFC62828),
            title: 'Compras parceladas',
            subtitle: 'Acompanhe parcelas de cartão de crédito',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InstallmentsScreen(),
              ),
            ),
          ),
          _tile(
            context,
            icon: Icons.savings,
            color: const Color(0xFF43A047),
            title: 'Metas financeiras',
            subtitle: 'Economize com a família para objetivos',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GoalsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

