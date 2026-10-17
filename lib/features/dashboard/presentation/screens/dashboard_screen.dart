import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/data/auth_service.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../transactions/data/transaction_service.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/screens/transaction_details_screen.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/app_snackbar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyService = FamilyService();
    final txService = TransactionService();
    final auth = AuthService();

    return StreamBuilder<FamilyModel?>(
      stream: familyService.watchMyFamily(),
      builder: (context, famSnap) {
        if (!famSnap.hasData) {
          return const Scaffold(
            body: DashboardSkeleton(),
          );
        }
        final family = famSnap.data!;
        final isAdmin = family.adminId == auth.currentUser?.uid;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Casa Prime'),
            actions: const [
              NotificationBell(),
            ],
          ),
          body: StreamBuilder<List<TransactionModel>>(
            stream: txService.watchTransactions(family.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const DashboardSkeleton();
              }
              final list = snap.data ?? [];
              final stats = _DashboardStats.from(list);

              return RefreshIndicator(
                onRefresh: () async =>
                    await Future.delayed(const Duration(milliseconds: 300)),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    _BalanceCard(stats: stats),
                    const SizedBox(height: 12),
                    _MonthlySummaryRow(stats: stats),
                    const SizedBox(height: 12),
                    _HighlightCard(stats: stats),
                    const SizedBox(height: 20),
                    const _SectionTitle('Entradas x Saídas (6 meses)'),
                    _IncomeExpenseChart(stats: stats),
                    const SizedBox(height: 20),
                    const _SectionTitle('Gastos por categoria'),
                    _CategoryPieChart(stats: stats),
                    const SizedBox(height: 20),
                    const _SectionTitle('Últimos lançamentos'),
                    if (list.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Nenhum lançamento ainda.',
                            style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ...list.take(5).map((t) => _MiniTile(
                            tx: t,
                            familyId: family.id,
                            isAdmin: isAdmin,
                          )),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DashboardStats {
  final double totalIncome;
  final double totalExpense;
  final double monthIncome;
  final double monthExpense;
  final double biggestExpense;
  final Map<String, double> expensesByCategory;
  final Map<int, double> incomeByMonth;
  final Map<int, double> expenseByMonth;

  _DashboardStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.monthIncome,
    required this.monthExpense,
    required this.biggestExpense,
    required this.expensesByCategory,
    required this.incomeByMonth,
    required this.expenseByMonth,
  });

  double get balance => totalIncome - totalExpense;
  double get monthBalance => monthIncome - monthExpense;

  String get topCategory {
    if (expensesByCategory.isEmpty) return '—';
    final sorted = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  factory _DashboardStats.from(List<TransactionModel> list) {
    final now = DateTime.now();
    double ti = 0, te = 0, mi = 0, me = 0, big = 0;
    final byCat = <String, double>{};
    final incM = <int, double>{};
    final expM = <int, double>{};

    for (final t in list) {
      if (t.isIncome) {
        ti += t.amount;
        incM[t.date.month] = (incM[t.date.month] ?? 0) + t.amount;
        if (t.date.year == now.year && t.date.month == now.month) {
          mi += t.amount;
        }
      } else {
        te += t.amount;
        expM[t.date.month] = (expM[t.date.month] ?? 0) + t.amount;
        if (t.date.year == now.year && t.date.month == now.month) {
          me += t.amount;
          if (t.amount > big) big = t.amount;
          byCat[t.categoryName] =
              (byCat[t.categoryName] ?? 0) + t.amount;
        }
      }
    }

    return _DashboardStats(
      totalIncome: ti,
      totalExpense: te,
      monthIncome: mi,
      monthExpense: me,
      biggestExpense: big,
      expensesByCategory: byCat,
      incomeByMonth: incM,
      expenseByMonth: expM,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final _DashboardStats stats;
  const _BalanceCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final positive = stats.balance >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: positive
              ? [const Color(0xFF1565C0), const Color(0xFF1E88E5)]
              : [const Color(0xFFC62828), const Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saldo atual',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(Formatters.money(stats.balance),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Resultado do mês: ${Formatters.money(stats.monthBalance)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MonthlySummaryRow extends StatelessWidget {
  final _DashboardStats stats;
  const _MonthlySummaryRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Entradas do mês',
            value: Formatters.money(stats.monthIncome),
            icon: Icons.arrow_downward,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Saídas do mês',
            value: Formatters.money(stats.monthExpense),
            icon: Icons.arrow_upward,
            color: const Color(0xFFC62828),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          ],
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final _DashboardStats stats;
  const _HighlightCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Destaques do mês',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _kv('Maior despesa', Formatters.money(stats.biggestExpense)),
            _kv('Categoria que mais gastou', stats.topCategory),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            Text(v,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
}

class _IncomeExpenseChart extends StatelessWidget {
  final _DashboardStats stats;
  const _IncomeExpenseChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - 5 + i, 1),
    );

    final maxY = months
            .expand((m) => [
                  stats.incomeByMonth[m.month] ?? 0,
                  stats.expenseByMonth[m.month] ?? 0,
                ])
            .fold<double>(0, (a, b) => a > b ? a : b) *
        1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
        child: SizedBox(
          height: 220,
          child: maxY == 0
              ? const Center(
                  child: Text('Sem dados ainda',
                      style: TextStyle(color: Colors.grey)),
                )
              : BarChart(
                  BarChartData(
                    maxY: maxY,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= months.length) {
                              return const SizedBox.shrink();
                            }
                            final m = months[i];
                            const labels = [
                              'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
                              'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
                            ];
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(labels[m.month - 1],
                                  style: const TextStyle(fontSize: 11)),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(months.length, (i) {
                      final m = months[i];
                      final inc = stats.incomeByMonth[m.month] ?? 0;
                      final exp = stats.expenseByMonth[m.month] ?? 0;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: inc,
                            color: const Color(0xFF2E7D32),
                            width: 8,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          BarChartRodData(
                            toY: exp,
                            color: const Color(0xFFC62828),
                            width: 8,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final _DashboardStats stats;
  const _CategoryPieChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = stats.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();

    if (top.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text('Sem despesas no mês.',
                style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    final total = top.fold<double>(0, (a, e) => a + e.value);
    const colors = [
      Color(0xFFE53935),
      Color(0xFFFB8C00),
      Color(0xFFFDD835),
      Color(0xFF43A047),
      Color(0xFF1E88E5),
      Color(0xFF8E24AA),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: List.generate(top.length, (i) {
                    final pct = (top[i].value / total) * 100;
                    return PieChartSectionData(
                      value: top[i].value,
                      color: colors[i % colors.length],
                      radius: 40,
                      title: '${pct.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(top.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[i % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            top[i].key,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          Formatters.money(top[i].value),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class _MiniTile extends StatelessWidget {
  final TransactionModel tx;
  final String familyId;
  final bool isAdmin;
  const _MiniTile({
    required this.tx,
    required this.familyId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;
    final color = isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final sign = isIncome ? '+' : '-';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 18,
          ),
        ),
        title: Text(tx.description,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(tx.categoryName,
            style: const TextStyle(fontSize: 12)),
        trailing: Text(
          '$sign ${Formatters.money(tx.amount)}',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13),
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


