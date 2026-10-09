import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../../transactions/data/transaction_service.dart';
import '../../../transactions/domain/transaction_model.dart';
import 'export_sheet.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyService = FamilyService();
    final txService = TransactionService();

    return StreamBuilder<FamilyModel?>(
      stream: familyService.watchMyFamily(),
      builder: (context, famSnap) {
        if (!famSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final family = famSnap.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Relatórios'),
            actions: [
              StreamBuilder<List<TransactionModel>>(
                stream: txService.watchTransactions(family.id),
                builder: (context, txSnap) {
                  final list = txSnap.data ?? [];
                  return IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Exportar (PDF / CSV)',
                    onPressed: list.isEmpty
                        ? null
                        : () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (_) => ExportSheet(
                                family: family,
                                transactions: list,
                              ),
                            ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: 'Mensal', icon: Icon(Icons.calendar_month)),
                Tab(text: 'Anual', icon: Icon(Icons.calendar_today)),
              ],
            ),
          ),
          body: StreamBuilder<List<TransactionModel>>(
            stream: txService.watchTransactions(family.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data ?? [];

              return TabBarView(
                controller: _tab,
                children: [
                  _MonthlyReport(list: list),
                  _YearlyReport(list: list),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _MonthlyReport extends StatefulWidget {
  final List<TransactionModel> list;
  const _MonthlyReport({required this.list});

  @override
  State<_MonthlyReport> createState() => _MonthlyReportState();
}

class _MonthlyReportState extends State<_MonthlyReport> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  Future<void> _pickMonthYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, _month, 1),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Escolha o mês de referência',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _year = picked.year;
        _month = picked.month;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthly = widget.list.where((t) {
      return t.date.year == _year && t.date.month == _month;
    }).toList();

    final prevMonth = _month == 1 ? 12 : _month - 1;
    final prevYear = _month == 1 ? _year - 1 : _year;
    final previous = widget.list.where((t) {
      return t.date.year == prevYear && t.date.month == prevMonth;
    }).toList();

    double income = 0, expense = 0;
    double bigIncome = 0, bigExpense = 0;
    final byCat = <String, double>{};
    final byMember = <String, double>{};

    for (final t in monthly) {
      if (t.isIncome) {
        income += t.amount;
        if (t.amount > bigIncome) bigIncome = t.amount;
      } else {
        expense += t.amount;
        if (t.amount > bigExpense) bigExpense = t.amount;
        byCat[t.categoryName] = (byCat[t.categoryName] ?? 0) + t.amount;
        byMember[t.createdByName] =
            (byMember[t.createdByName] ?? 0) + t.amount;
      }
    }

    double prevIncome = 0, prevExpense = 0;
    for (final t in previous) {
      if (t.isIncome) {
        prevIncome += t.amount;
      } else {
        prevExpense += t.amount;
      }
    }

    final balance = income - expense;
    final prevBalance = prevIncome - prevExpense;
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final avgDaily = expense / daysInMonth;

    final catEntries = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCat = catEntries.isNotEmpty ? catEntries.first : null;
    final lowCat = catEntries.isNotEmpty ? catEntries.last : null;

    final memberEntries = byMember.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMember = memberEntries.isNotEmpty ? memberEntries.first : null;

    const monthNames = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text('${monthNames[_month - 1]} $_year',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.edit),
            onTap: _pickMonthYear,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: balance >= 0
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
              const Text('Saldo do mês',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text(Formatters.money(balance),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Comparado ao mês anterior: '
                '${_deltaLabel(balance, prevBalance)}',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SmallStat(
                label: 'Entradas',
                value: Formatters.money(income),
                color: const Color(0xFF2E7D32),
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SmallStat(
                label: 'Saídas',
                value: Formatters.money(expense),
                color: const Color(0xFFC62828),
                icon: Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumo',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _kv('Quantidade de lançamentos', '${monthly.length}'),
                _kv('Maior entrada', Formatters.money(bigIncome)),
                _kv('Maior saída', Formatters.money(bigExpense)),
                _kv('Média diária de gastos', Formatters.money(avgDaily)),
                _kv('Categoria que mais gastou',
                    topCat != null ? topCat.key : '—'),
                _kv('Categoria que menos gastou',
                    lowCat != null ? lowCat.key : '—'),
                _kv('Membro que mais gastou',
                    topMember != null ? topMember.key : '—'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (catEntries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Sem despesas neste mês.',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
          )
        else ...[
          const Text('Gastos por categoria',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _PieByCategory(entries: catEntries),
        ],
      ],
    );
  }

  String _deltaLabel(double cur, double prev) {
    if (prev == 0) return '—';
    final diff = cur - prev;
    final pct = (diff / prev.abs()) * 100;
    final sign = diff >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }
}

class _YearlyReport extends StatefulWidget {
  final List<TransactionModel> list;
  const _YearlyReport({required this.list});

  @override
  State<_YearlyReport> createState() => _YearlyReportState();
}

class _YearlyReportState extends State<_YearlyReport> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  Future<void> _pickYear() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, 1, 1),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Escolha o ano',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _year = picked.year);
    }
  }

  @override
  Widget build(BuildContext context) {
    final yearly =
        widget.list.where((t) => t.date.year == _year).toList();

    double totalIncome = 0, totalExpense = 0;
    final incomeByMonth = List<double>.filled(12, 0);
    final expenseByMonth = List<double>.filled(12, 0);
    final byCat = <String, double>{};

    for (final t in yearly) {
      if (t.isIncome) {
        totalIncome += t.amount;
        incomeByMonth[t.date.month - 1] += t.amount;
      } else {
        totalExpense += t.amount;
        expenseByMonth[t.date.month - 1] += t.amount;
        byCat[t.categoryName] = (byCat[t.categoryName] ?? 0) + t.amount;
      }
    }

    final balance = totalIncome - totalExpense;
    final avgMonthlyIncome = totalIncome / 12;
    final avgMonthlyExpense = totalExpense / 12;

    int topExpMonthIdx = -1;
    double topExpValue = 0;
    for (var i = 0; i < 12; i++) {
      if (expenseByMonth[i] > topExpValue) {
        topExpValue = expenseByMonth[i];
        topExpMonthIdx = i;
      }
    }

    int lowExpMonthIdx = -1;
    double lowExpValue = double.infinity;
    for (var i = 0; i < 12; i++) {
      if (expenseByMonth[i] > 0 && expenseByMonth[i] < lowExpValue) {
        lowExpValue = expenseByMonth[i];
        lowExpMonthIdx = i;
      }
    }

    final catEntries = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCat = catEntries.isNotEmpty ? catEntries.first : null;
    final lowCat = catEntries.isNotEmpty ? catEntries.last : null;

    const monthNames = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text('Ano $_year',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.edit),
            onTap: _pickYear,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: balance >= 0
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
              const Text('Saldo do ano',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text(Formatters.money(balance),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SmallStat(
                label: 'Entradas do ano',
                value: Formatters.money(totalIncome),
                color: const Color(0xFF2E7D32),
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SmallStat(
                label: 'Saídas do ano',
                value: Formatters.money(totalExpense),
                color: const Color(0xFFC62828),
                icon: Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumo do ano',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _kv('Média mensal de entradas',
                    Formatters.money(avgMonthlyIncome)),
                _kv('Média mensal de saídas',
                    Formatters.money(avgMonthlyExpense)),
                _kv(
                  'Mês com maior gasto',
                  topExpMonthIdx >= 0
                      ? '${monthNames[topExpMonthIdx]} — '
                          '${Formatters.money(topExpValue)}'
                      : '—',
                ),
                _kv(
                  'Mês com menor gasto',
                  lowExpMonthIdx >= 0
                      ? '${monthNames[lowExpMonthIdx]} — '
                          '${Formatters.money(lowExpValue)}'
                      : '—',
                ),
                _kv('Categoria que mais gastou',
                    topCat != null ? topCat.key : '—'),
                _kv('Categoria que menos gastou',
                    lowCat != null ? lowCat.key : '—'),
                _kv('Lançamentos no ano', '${yearly.length}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Evolução mensal',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _YearlyBarChart(
          incomeByMonth: incomeByMonth,
          expenseByMonth: expenseByMonth,
        ),
      ],
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _SmallStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
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
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

Widget _kv(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(k,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            flex: 4,
            child: Text(v,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );

class _PieByCategory extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  const _PieByCategory({required this.entries});

  static const _colors = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFF00897B),
    Color(0xFF6D4C41),
  ];

  @override
  Widget build(BuildContext context) {
    final top = entries.take(8).toList();
    final total = top.fold<double>(0, (a, e) => a + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: List.generate(top.length, (i) {
                    final pct = (top[i].value / total) * 100;
                    return PieChartSectionData(
                      value: top[i].value,
                      color: _colors[i % _colors.length],
                      radius: 50,
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
            const SizedBox(height: 16),
            Column(
              children: List.generate(top.length, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _colors[i % _colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          top[i].key,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Formatters.money(top[i].value),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearlyBarChart extends StatelessWidget {
  final List<double> incomeByMonth;
  final List<double> expenseByMonth;
  const _YearlyBarChart({
    required this.incomeByMonth,
    required this.expenseByMonth,
  });

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];

    final maxY = [...incomeByMonth, ...expenseByMonth]
            .fold<double>(0, (a, b) => a > b ? a : b) *
        1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
        child: SizedBox(
          height: 240,
          child: maxY == 0
              ? const Center(
                  child: Text('Sem dados para este ano',
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
                            if (i < 0 || i >= 12) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(labels[i],
                                  style: const TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(12, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: incomeByMonth[i],
                            color: const Color(0xFF2E7D32),
                            width: 6,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          BarChartRodData(
                            toY: expenseByMonth[i],
                            color: const Color(0xFFC62828),
                            width: 6,
                            borderRadius: BorderRadius.circular(2),
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
