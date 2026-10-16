import 'package:flutter/material.dart';
import '../../../family/presentation/screens/my_family_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../transactions/presentation/screens/transactions_list_screen.dart';
import '../../../goals/presentation/screens/goals_screen.dart';
import '../../../recurring/presentation/screens/recurrings_screen.dart';
import '../../../installments/presentation/screens/installments_screen.dart';
import 'dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    TransactionsListScreen(),
    RecurringsScreen(),
    InstallmentsScreen(),
    GoalsScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Lançar',
          ),
          NavigationDestination(
            icon: Icon(Icons.repeat_outlined),
            selectedIcon: Icon(Icons.repeat),
            label: 'Recorr.',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Parcel.',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Metas',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Relat.',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
