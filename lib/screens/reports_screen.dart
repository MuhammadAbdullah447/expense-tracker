import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {

  int _selectedMonth = DateTime.now().month;
  int _selectedYear  = DateTime.now().year;
  int _touchedIndex  = -1;

  // ─── Animation Controllers ───
  late AnimationController _fadeController;
  late AnimationController _chartController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _chartAnimation;

  // ─── Colors ───
  static const primary     = Color(0xFF10B981);
  static const primaryDark = Color(0xFF059669);
  static const bgColor     = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecond  = Color(0xFF64748B);
  static const borderColor = Color(0xFFE2E8F0);
  static const errorColor  = Color(0xFFEF4444);
  static const cardColor   = Colors.white;

  final Map<String, Color> categoryColors = {
    'Food':          const Color(0xFF10B981),
    'Transport':     const Color(0xFF2196F3),
    'Bills':         const Color(0xFFF59E0B),
    'Health':        const Color(0xFFE91E63),
    'Entertainment': const Color(0xFF8B5CF6),
    'Shopping':      const Color(0xFF00BCD4),
    'Education':     const Color(0xFF3B82F6),
    'Other':         const Color(0xFF607D8B),
  };

  final Map<String, IconData> categoryIcons = {
    'Food':          Icons.restaurant_outlined,
    'Transport':     Icons.directions_car_outlined,
    'Bills':         Icons.receipt_outlined,
    'Health':        Icons.health_and_safety_outlined,
    'Entertainment': Icons.movie_outlined,
    'Shopping':      Icons.shopping_bag_outlined,
    'Education':     Icons.school_outlined,
    'Other':         Icons.more_horiz,
  };

  final List<String> monthNames = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
        parent: _fadeController, curve: Curves.easeIn));

    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
        parent: _chartController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  List<ExpenseModel> _getFiltered(List<ExpenseModel> expenses) =>
      expenses.where((e) =>
      e.date.month == _selectedMonth &&
          e.date.year == _selectedYear).toList();

  Map<String, double> _getCategoryTotals(
      List<ExpenseModel> expenses) {
    final Map<String, double> totals = {};
    for (var e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  double _getTotal(List<ExpenseModel> expenses) =>
      expenses.fold(0, (sum, e) => sum + e.amount);

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<ExpenseProvider>();
    final filtered  = _getFiltered(provider.expenses);
    final catTotals = _getCategoryTotals(filtered);
    final total     = _getTotal(filtered);
    final sorted    = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: bgColor,
      body: provider.isLoading
          ? _buildReportsLoading()
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ─── Header ───
              _buildHeader(total, provider.budget, filtered.length),
              const SizedBox(height: 20),

              // ─── Month Selector ───
              _buildMonthSelector(),
              const SizedBox(height: 20),

              // ─── Key Metrics ───
              _buildKeyMetrics(total, provider.budget, filtered.length),
              const SizedBox(height: 20),

              // ─── Budget Progress ───
              _buildBudgetProgress(total, provider.budget),
              const SizedBox(height: 20),

              if (filtered.isEmpty) ...[
                _buildEmptyState(),
              ] else ...[
                // ─── Pie Chart ───
                _buildPieChart(catTotals, total, sorted),
                const SizedBox(height: 20),

                // ─── Bar Chart ───
                _buildBarChart(provider.expenses),
                const SizedBox(height: 20),

                // ─── Category Breakdown ───
                _buildCategoryBreakdown(sorted, total),
                const SizedBox(height: 20),

                // ─── Insights ───
                _buildInsights(sorted, total, provider.budget),
                const SizedBox(height: 20),

                // ─── Top Expenses ───
                _buildTopExpenses(filtered),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(double total, double budget, int count) {
    final pct = budget > 0 ? (total / budget * 100) : 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E3B),
            Color(0xFF065F46),
            Color(0xFF047857),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      )),
                  Text(
                    '${monthNames[_selectedMonth - 1]} $_selectedYear',
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              // ─── Budget % badge ───
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}% used',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ─── Quick stats in header ───
          Row(
            children: [
              _buildHeaderChip('💰',
                  'Rs. ${_formatAmount(total)}', 'Spent'),
              const SizedBox(width: 10),
              _buildHeaderChip('🏦',
                  'Rs. ${_formatAmount(budget)}', 'Budget'),
              const SizedBox(width: 10),
              _buildHeaderChip(
                  '📊', '$count', 'Expenses'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(
      String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji,
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                )),
            Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.white60, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ─── Month Selector ───
  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Month',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecond,
              )),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 12,
              itemBuilder: (context, index) {
                final month      = index + 1;
                final isSelected = month == _selectedMonth;
                final isCurrent  = month == DateTime.now().month &&
                    _selectedYear == DateTime.now().year;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedMonth = month;
                      _touchedIndex  = -1;
                    });
                    // ─── Animate charts on month change ───
                    _fadeController.reset();
                    _chartController.reset();
                    Future.delayed(
                      const Duration(milliseconds: 100),
                          () {
                        if (mounted) {
                          _fadeController.forward();
                          _chartController.forward();
                        }
                      },
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                          colors: [primary, primaryDark])
                          : null,
                      color: isSelected ? null : cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? primary
                            : isCurrent
                            ? primary.withOpacity(0.3)
                            : borderColor,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          monthNames[index],
                          style: GoogleFonts.poppins(
                            color: isSelected
                                ? Colors.white
                                : textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        if (isCurrent && !isSelected) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Key Metrics Row ───
  Widget _buildKeyMetrics(
      double total, double budget, int count) {
    final remaining = budget - total;
    final isOver    = remaining < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // ─── Total Spent ───
          Expanded(
            child: _buildMetricCard(
              icon:      Icons.arrow_upward,
              iconColor: errorColor,
              iconBg:    Colors.red.shade50,
              label:     'Total Spent',
              value:     'Rs. ${_formatAmount(total)}',
              sub:       '$count expenses',
            ),
          ),
          const SizedBox(width: 10),

          // ─── Remaining ───
          Expanded(
            child: _buildMetricCard(
              icon:      isOver
                  ? Icons.warning_amber
                  : Icons.savings_outlined,
              iconColor: isOver ? errorColor : primary,
              iconBg:    isOver
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              label:     isOver ? 'Over Budget' : 'Remaining',
              value:     'Rs. ${_formatAmount(remaining.abs())}',
              sub:       isOver ? '⚠️ Exceeded' : '✅ Safe',
            ),
          ),
          const SizedBox(width: 10),

          // ─── Budget ───
          Expanded(
            child: _buildMetricCard(
              icon:      Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF6366F1),
              iconBg:    const Color(0xFFEEF2FF),
              label:     'Budget',
              value:     'Rs. ${_formatAmount(budget)}',
              sub:       'Monthly limit',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 9, color: textSecond)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(sub,
              style: GoogleFonts.poppins(
                  fontSize: 9, color: textSecond)),
        ],
      ),
    );
  }

  // ─── Budget Progress Card ───
  Widget _buildBudgetProgress(double total, double budget) {
    final pct    = budget > 0 ? (total / budget).clamp(0.0, 1.0) : 0.0;
    final isOver = total > budget;
    final isClose = pct >= 0.8 && !isOver;
    final color  = isOver
        ? errorColor
        : isClose
        ? Colors.orange
        : primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    )),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(pct * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ─── Animated Progress Bar ───
            AnimatedBuilder(
              animation: _chartAnimation,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pct * _chartAnimation.value,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade100,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                _buildProgressStat(
                    'Spent', total, errorColor),
                _buildProgressStat(
                    'Budget', budget, textSecond),
                _buildProgressStat(
                    isOver ? 'Exceeded' : 'Remaining',
                    (budget - total).abs(),
                    isOver ? errorColor : primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(
      String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: textSecond)),
        Text(
          'Rs. ${_formatAmount(amount)}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── Pie Chart ───
  Widget _buildPieChart(Map<String, double> catTotals,
      double total, List<MapEntry<String, double>> sorted) {
    final entries = catTotals.entries.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Text('Spending by Category',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    )),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Donut',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: primary,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ─── Donut Chart ───
            AnimatedBuilder(
              animation: _chartAnimation,
              builder: (_, __) {
                return SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                if (!event
                                    .isInterestedForInteractions ||
                                    response == null ||
                                    response.touchedSection ==
                                        null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = response
                                    .touchedSection!
                                    .touchedSectionIndex;
                              });
                            },
                          ),
                          sections: entries
                              .asMap()
                              .entries
                              .map((entry) {
                            final i       = entry.key;
                            final e       = entry.value;
                            final isTouched =
                                i == _touchedIndex;
                            final pct =
                            total > 0 ? e.value / total : 0.0;
                            final color =
                                categoryColors[e.key] ??
                                    Colors.grey;
                            final radius =
                            isTouched ? 75.0 : 60.0;

                            return PieChartSectionData(
                              value: e.value *
                                  _chartAnimation.value,
                              color: color,
                              title: isTouched
                                  ? '${(pct * 100).toStringAsFixed(1)}%'
                                  : (pct * 100) > 5
                                  ? '${(pct * 100).toStringAsFixed(0)}%'
                                  : '',
                              radius: radius,
                              titleStyle: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isTouched ? 13 : 11,
                                fontWeight: FontWeight.w700,
                              ),
                              badgeWidget: isTouched
                                  ? null
                                  : null,
                            );
                          }).toList(),
                          sectionsSpace:    3,
                          centerSpaceRadius: 50,
                        ),
                      ),

                      // ─── Center text ───
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Total',
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: textSecond)),
                          Text(
                            'Rs.${_formatAmount(total)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // ─── Legend ───
            ...sorted.map((entry) {
              final color =
                  categoryColors[entry.key] ?? Colors.grey;
              final icon =
                  categoryIcons[entry.key] ?? Icons.more_horiz;
              final pct = total > 0
                  ? (entry.value / total * 100)
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(entry.key,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          )),
                    ),
                    Text(
                      'Rs. ${_formatAmount(entry.value)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── Bar Chart ───
  Widget _buildBarChart(List<ExpenseModel> allExpenses) {
    // ─── Last 6 months data ───
    final List<Map<String, dynamic>> monthlyData = [];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(_selectedYear, _selectedMonth - i, 1);
      final monthExpenses = allExpenses.where((e) =>
      e.date.month == date.month &&
          e.date.year == date.year).toList();
      final total =
      monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
      monthlyData.add({
        'month': monthNames[date.month - 1],
        'total': total,
      });
    }

    final maxY = monthlyData
        .map((e) => e['total'] as double)
        .fold(0.0, (a, b) => a > b ? a : b);

    final avg = monthlyData
        .map((e) => e['total'] as double)
        .fold(0.0, (a, b) => a + b) /
        6;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Text('Monthly Trend',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    )),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('6 Months',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: primary,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ─── Avg line ───
            Text(
              'Avg: Rs. ${_formatAmount(avg)}',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: textSecond),
            ),

            const SizedBox(height: 20),

            AnimatedBuilder(
              animation: _chartAnimation,
              builder: (_, __) {
                return SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY > 0 ? maxY * 1.25 : 10000,
                      barGroups: monthlyData
                          .asMap()
                          .entries
                          .map((entry) {
                        final isCurrentMonth =
                            entry.key == 5;
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: (entry.value['total']
                              as double) *
                                  _chartAnimation.value,
                              gradient: LinearGradient(
                                colors: isCurrentMonth
                                    ? [primary, primaryDark]
                                    : [
                                  primary.withOpacity(0.4),
                                  primary.withOpacity(0.6),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 28,
                              borderRadius:
                              const BorderRadius.only(
                                topLeft:
                                Radius.circular(8),
                                topRight:
                                Radius.circular(8),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      // ─── Average line ───
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: avg,
                            color: Colors.orange
                                .withOpacity(0.6),
                            strokeWidth: 1.5,
                            dashArray: [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              style: GoogleFonts.poppins(
                                color: Colors.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                              labelResolver: (_) => 'Avg',
                            ),
                          ),
                        ],
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) =>
                                Padding(
                                  padding:
                                  const EdgeInsets.only(top: 6),
                                  child: Text(
                                    monthlyData[value.toInt()]
                                    ['month'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: value.toInt() == 5
                                          ? primary
                                          : textSecond,
                                      fontWeight:
                                      value.toInt() == 5
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, _) => Text(
                              value >= 1000
                                  ? '${(value / 1000).toStringAsFixed(0)}k'
                                  : value.toStringAsFixed(0),
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: textSecond),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles:
                            SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles:
                            SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.grey.shade100,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, _, rod, __) =>
                              BarTooltipItem(
                                'Rs. ${_formatAmount(rod.toY / _chartAnimation.value)}',
                                GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Category Breakdown ───
  Widget _buildCategoryBreakdown(
      List<MapEntry<String, double>> sorted, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category Breakdown',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                )),
            const SizedBox(height: 16),
            ...sorted.asMap().entries.map((entry) {
              final i     = entry.key;
              final e     = entry.value;
              final color =
                  categoryColors[e.key] ?? Colors.grey;
              final icon =
                  categoryIcons[e.key] ?? Icons.more_horiz;
              final pct =
              total > 0 ? e.value / total : 0.0;

              return AnimatedBuilder(
                animation: _chartAnimation,
                builder: (_, __) {
                  final delay =
                  (i * 0.1).clamp(0.0, 0.5);
                  final progress =
                  ((_chartAnimation.value - delay) /
                      (1 - delay))
                      .clamp(0.0, 1.0);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                        children: [
                    Row(
                    children: [
                    Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color:
                      color.withOpacity(0.12),
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: Icon(icon,
                        color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                  child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                  Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                  Text(e.key,
                  style:
                  GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w600,
                  color: textPrimary,
                  )),
                  Text(
                  'Rs. ${_formatAmount(e.value)}',
                  style:
                  GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w700,
                  color: color,
                  ),
                  ),
                  ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                  borderRadius:
                  BorderRadius.circular(10),
                  child:
                  LinearProgressIndicator(
                    value: pct * progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                  '${(pct * 100).toStringAsFixed(1)}% of total',
                  style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: textSecond),
                  ),
                  ],
                  ),
                  ),
                  ],
                  ),
                  ],
                  ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── Insights ───
  Widget _buildInsights(List<MapEntry<String, double>> sorted,
      double total, double budget) {
    if (sorted.isEmpty) return const SizedBox();

    final top     = sorted.first;
    final topPct  = total > 0 ? top.value / total * 100 : 0.0;
    final isOver  = total > budget;
    final pct     = budget > 0 ? total / budget * 100 : 0.0;

    final List<Map<String, dynamic>> insights = [
      {
        'icon':  Icons.insights,
        'color': const Color(0xFF6366F1),
        'text':
        '${top.key} is your largest expense (${topPct.toStringAsFixed(1)}% of total)',
      },
      {
        'icon':  isOver ? Icons.warning_amber : Icons.check_circle,
        'color': isOver ? errorColor : primary,
        'text':  isOver
            ? 'You have exceeded your monthly budget by Rs. ${_formatAmount(total - budget)}'
            : 'Great! You have used ${pct.toStringAsFixed(1)}% of your budget',
      },
      if (sorted.length > 1) ...[
        {
          'icon':  Icons.trending_down,
          'color': primary,
          'text':
          '${sorted.last.key} has the lowest spending (Rs. ${_formatAmount(sorted.last.value)})',
        },
      ],
      {
        'icon':  Icons.lightbulb_outline,
        'color': Colors.amber.shade700,
        'text':
        'You recorded ${_getFiltered([]).length} expenses this month',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF064E3B).withOpacity(0.05),
              const Color(0xFF10B981).withOpacity(0.05),
            ],
          ),
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: primary.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: primary, size: 16),
                ),
                const SizedBox(width: 10),
                Text('Smart Insights',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (insight['color'] as Color)
                          .withOpacity(0.1),
                      borderRadius:
                      BorderRadius.circular(8),
                    ),
                    child: Icon(
                      insight['icon'] as IconData,
                      color: insight['color'] as Color,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight['text'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // ─── Top Expenses ───
  Widget _buildTopExpenses(List<ExpenseModel> filtered) {
    if (filtered.isEmpty) return const SizedBox();

    final sorted = List<ExpenseModel>.from(filtered)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top = sorted.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Expenses',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                )),
            const SizedBox(height: 16),
            ...top.asMap().entries.map((entry) {
              final i       = entry.key;
              final expense = entry.value;
              final color   =
                  categoryColors[expense.category] ??
                      Colors.grey;
              final icon    =
                  categoryIcons[expense.category] ??
                      Icons.more_horiz;

              final medals = ['🥇', '🥈', '🥉'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(medals[i],
                        style:
                        const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: Icon(icon,
                          color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          Text(expense.category,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: textSecond)),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${_formatAmount(expense.amount)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── Reports Loading Shimmer ───
  Widget _buildReportsLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // ─── Header shimmer ───
          Container(
            width: double.infinity,
            height: 180,
            decoration: const BoxDecoration(
              color: Color(0xFF065F46),
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [

                // ─── Metrics shimmer ───
                Row(
                  children: List.generate(3, (i) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )),
                ),

                const SizedBox(height: 16),

                // ─── Budget card shimmer ───
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Chart shimmer ───
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF10B981),
                      strokeWidth: 2.5,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Bar chart shimmer ───
                Container(
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ───
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart_outlined,
                  size: 48, color: primary),
            ),
            const SizedBox(height: 16),
            Text(
              'No Data for ${monthNames[_selectedMonth - 1]} $_selectedYear',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some expenses to see\nyour spending analytics here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: textSecond,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}