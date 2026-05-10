import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {

  // ─── Selected month filter ───
  int _selectedMonth = DateTime.now().month;
  int _selectedYear  = DateTime.now().year;

  // ─── Category colors map ───
  final Map<String, Color> categoryColors = {
    'Food':          const Color(0xFF4CAF50),
    'Transport':     const Color(0xFF2196F3),
    'Bills':         const Color(0xFFFF9800),
    'Health':        const Color(0xFFE91E63),
    'Entertainment': const Color(0xFF9C27B0),
    'Shopping':      const Color(0xFF00BCD4),
    'Education':     const Color(0xFF795548),
    'Other':         const Color(0xFF607D8B),
  };

  // ─── Category icons map ───
  final Map<String, IconData> categoryIcons = {
    'Food':          Icons.fastfood,
    'Transport':     Icons.directions_car,
    'Bills':         Icons.receipt_long,
    'Health':        Icons.favorite,
    'Entertainment': Icons.sports_esports,
    'Shopping':      Icons.shopping_bag,
    'Education':     Icons.school,
    'Other':         Icons.more_horiz,
  };

  // ─── Month names list ───
  final List<String> monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  // ─── Selected month ki expenses filter karo ───
  List<ExpenseModel> _getFilteredExpenses(List<ExpenseModel> expenses) {
    return expenses.where((e) =>
    e.date.month == _selectedMonth &&
        e.date.year  == _selectedYear
    ).toList();
  }

  // ─── Category wise totals calculate karo ───
  Map<String, double> _getCategoryTotals(List<ExpenseModel> expenses) {
    final Map<String, double> totals = {};
    for (var expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  // ─── Total calculate karo ───
  double _getTotal(List<ExpenseModel> expenses) {
    double total = 0;
    for (var e in expenses) {
      total += e.amount;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<ExpenseProvider>();
    final filtered  = _getFilteredExpenses(provider.expenses);
    final catTotals = _getCategoryTotals(filtered);
    final total     = _getTotal(filtered);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── Header ───
            _buildHeader(),

            // ─── Month Selector ───
            _buildMonthSelector(),

            const SizedBox(height: 16),

            // ─── Total Summary Card ───
            _buildTotalCard(total, provider.budget, filtered.length),

            const SizedBox(height: 16),

            // ─── Pie Chart ───
            if (filtered.isEmpty)
              _buildEmptyState()
            else ...[
              // ─── Pie Chart ───
              _buildPieChart(catTotals, total),
              const SizedBox(height: 16),

              // ─── Bar Chart ───
              _buildBarChart(provider.expenses),
              const SizedBox(height: 16),

              // ─── Category Breakdown ───
              _buildCategoryBreakdown(catTotals, total),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Empty state — jab koi expense nahi ───
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              // ─── Icon ───
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.bar_chart_outlined,
                  size: 50,
                  color: Color(0xFF1E3A5F),
                ),
              ),

              const SizedBox(height: 20),

              // ─── Title ───
              Text(
                'No Data for ${monthNames[_selectedMonth - 1]} $_selectedYear',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),

              const SizedBox(height: 10),

              // ─── Subtitle ───
              Text(
                'Add some expenses to see\nyour spending analysis here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // ─── Tip ───
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Tap + to add your first expense',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A5F),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reports',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Your spending analysis',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  // ─── Month Selector ───
  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 12,
          itemBuilder: (context, index) {
            final month     = index + 1;
            final isSelected = month == _selectedMonth;
            return GestureDetector(
              onTap: () => setState(() => _selectedMonth = month),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E3A5F)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Text(
                  monthNames[index],
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Total summary card ───
  Widget _buildTotalCard(
      double total, double budget, int count) {
    final double percentage =
    budget > 0 ? (total / budget * 100) : 0;
    final bool isOver = total > budget;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthNames[_selectedMonth - 1] +
                            ' $_selectedYear',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOver
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}% of budget',
                      style: TextStyle(
                        color: isOver ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOver ? Colors.red : const Color(0xFF1E3A5F),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Bottom row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$count expenses recorded',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                  Text(
                    'Budget: Rs. ${budget.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Pie Chart ───
  Widget _buildPieChart(
      Map<String, double> catTotals, double total) {
    final entries = catTotals.entries.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Spending by Category',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F))),
              const SizedBox(height: 20),

              // Pie chart
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: entries.map((entry) {
                      final percentage =
                      (entry.value / total * 100);
                      final color =
                          categoryColors[entry.key] ?? Colors.grey;
                      return PieChartSectionData(
                        value: entry.value,
                        color: color,
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 80,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Legend
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: entries.map((entry) {
                  final color =
                      categoryColors[entry.key] ?? Colors.grey;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(entry.key,
                          style: const TextStyle(fontSize: 12)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bar Chart — Last 6 months ───
  Widget _buildBarChart(List<ExpenseModel> allExpenses) {
    // Last 6 months ka data prepare karo
    final List<Map<String, dynamic>> monthlyData = [];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(
          _selectedYear, _selectedMonth - i, 1);
      final monthExpenses = allExpenses.where((e) =>
      e.date.month == date.month &&
          e.date.year == date.year).toList();

      double total = 0;
      for (var e in monthExpenses) {
        total += e.amount;
      }

      monthlyData.add({
        'month': monthNames[date.month - 1],
        'total': total,
      });
    }

    final double maxY = monthlyData
        .map((e) => e['total'] as double)
        .reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Last 6 Months',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F))),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    maxY: maxY > 0 ? maxY * 1.2 : 1000,
                    barGroups: monthlyData
                        .asMap()
                        .entries
                        .map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value['total'] as double,
                            color: const Color(0xFF1E3A5F),
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft:  Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                monthlyData[value.toInt()]['month'],
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value >= 1000
                                  ? '${(value / 1000).toStringAsFixed(0)}k'
                                  : value.toStringAsFixed(0),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Category breakdown list ───
  Widget _buildCategoryBreakdown(
      Map<String, double> catTotals, double total) {
    // Amount ke hisaab se sort karo — descending
    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Category Breakdown',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F))),
              const SizedBox(height: 16),

              ...sorted.map((entry) {
                final color =
                    categoryColors[entry.key] ?? Colors.grey;
                final icon =
                    categoryIcons[entry.key] ?? Icons.more_horiz;
                final percentage = total > 0
                    ? (entry.value / total * 100)
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child:
                            Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 12),

                          // Name + percentage
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key,
                                        style: const TextStyle(
                                            fontWeight:
                                            FontWeight.w600,
                                            fontSize: 14)),
                                    Text(
                                      'Rs. ${entry.value.toStringAsFixed(0)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Progress bar
                                ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    minHeight: 6,
                                    backgroundColor:
                                    Colors.grey.shade200,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        color),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${percentage.toStringAsFixed(1)}% of total',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}