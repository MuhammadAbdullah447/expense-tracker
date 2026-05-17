import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import 'edit_expense_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {

  // ─── Filter state ───
  String _selectedFilter = 'All Time';
  String _selectedCategory = 'All';

  // ─── Animation ───
  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;

  // ─── Colors ───
  static const primary     = Color(0xFF10B981);
  static const primaryDark = Color(0xFF059669);
  static const bgColor     = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecond  = Color(0xFF64748B);
  static const borderColor = Color(0xFFE2E8F0);
  static const errorColor  = Color(0xFFEF4444);
  static const cardColor   = Colors.white;

  // ─── Time filters ───
  final List<String> _timeFilters = [
    'All Time',
    'This Month',
    'Last Month',
    'Last 3 Months',
    'This Year',
  ];

  // ─── Categories ───
  final List<String> _categories = [
    'All', 'Food', 'Transport', 'Bills',
    'Health', 'Entertainment', 'Shopping',
    'Education', 'Other',
  ];

  final Map<String, Color> categoryColors = {
    'Food':          const Color(0xFFFF9800),
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

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
        parent: _fadeController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ─── Filter expenses by time ───
  List<ExpenseModel> _getFilteredExpenses(
      List<ExpenseModel> all) {
    final now   = DateTime.now();
    List<ExpenseModel> filtered = [];

    switch (_selectedFilter) {
      case 'This Month':
        filtered = all.where((e) =>
        e.date.month == now.month &&
            e.date.year == now.year).toList();
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1);
        filtered = all.where((e) =>
        e.date.month == lastMonth.month &&
            e.date.year == lastMonth.year).toList();
        break;
      case 'Last 3 Months':
        final threeMonthsAgo =
        DateTime(now.year, now.month - 3, now.day);
        filtered = all
            .where((e) => e.date.isAfter(threeMonthsAgo))
            .toList();
        break;
      case 'This Year':
        filtered = all
            .where((e) => e.date.year == now.year)
            .toList();
        break;
      default:
        filtered = all;
    }

    // ─── Category filter ───
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((e) => e.category == _selectedCategory)
          .toList();
    }

    // ─── Sort by date descending ───
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  // ─── Group by date ───
  Map<String, List<ExpenseModel>> _groupByDate(
      List<ExpenseModel> expenses) {
    final Map<String, List<ExpenseModel>> grouped = {};
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday =
    today.subtract(const Duration(days: 1));

    for (var expense in expenses) {
      final expDate = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day);

      String label;
      if (expDate == today) {
        label = 'Today';
      } else if (expDate == yesterday) {
        label = 'Yesterday';
      } else {
        final months = [
          'Jan','Feb','Mar','Apr','May','Jun',
          'Jul','Aug','Sep','Oct','Nov','Dec'
        ];
        label =
        '${months[expense.date.month - 1]} ${expense.date.day}, ${expense.date.year}';
      }

      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(expense);
    }
    return grouped;
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<ExpenseProvider>();
    final filtered  = _getFilteredExpenses(provider.expenses);
    final grouped   = _groupByDate(filtered);
    final total     =
    filtered.fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [

            // ─── Header ───
            _buildHeader(filtered.length, total),

            // ─── Time Filter ───
            _buildTimeFilter(),

            // ─── Category Filter ───
            _buildCategoryFilter(),

            // ─── Content ───
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : _buildGroupedList(grouped, provider),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(int count, double total) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 24),
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
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Back + Title ───
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'History',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ─── Stats Row ───
          Row(
            children: [
              _buildHeaderStat(
                  '📋', '$count', 'Expenses'),
              const SizedBox(width: 10),
              _buildHeaderStat(
                  '💰',
                  'Rs. ${_formatAmount(total)}',
                  'Total Spent'),
              const SizedBox(width: 10),
              _buildHeaderStat(
                  '📅',
                  _selectedFilter,
                  'Period'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.white60, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // ─── Time Filter ───
  Widget _buildTimeFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Time Period',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textSecond,
              )),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _timeFilters.length,
              itemBuilder: (context, index) {
                final filter   = _timeFilters[index];
                final isActive = filter == _selectedFilter;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(
                            () => _selectedFilter = filter);
                  },
                  child: AnimatedContainer(
                    duration:
                    const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(colors: [
                        primary,
                        primaryDark
                      ])
                          : null,
                      color: isActive
                          ? null
                          : Colors.grey.shade100,
                      borderRadius:
                      BorderRadius.circular(20),
                      boxShadow: isActive
                          ? [
                        BoxShadow(
                          color: primary
                              .withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                          : [],
                    ),
                    child: Text(
                      filter,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : textSecond,
                      ),
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

  // ─── Category Filter ───
  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textSecond,
              )),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat      = _categories[index];
                final isActive = cat == _selectedCategory;
                final color    = cat == 'All'
                    ? primary
                    : categoryColors[cat] ?? primary;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(
                            () => _selectedCategory = cat);
                  },
                  child: AnimatedContainer(
                    duration:
                    const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? color
                          : color.withOpacity(0.08),
                      borderRadius:
                      BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? color
                            : color.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : color,
                      ),
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

  // ─── Grouped List ───
  Widget _buildGroupedList(
      Map<String, List<ExpenseModel>> grouped,
      ExpenseProvider provider) {
    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final dateLabel = keys[index];
        final expenses  = grouped[dateLabel]!;
        final dayTotal  =
        expenses.fold(0.0, (s, e) => s + e.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ─── Date Header ───
            Padding(
              padding: const EdgeInsets.only(
                  top: 8, bottom: 8),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.1),
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Rs. ${_formatAmount(dayTotal)}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Expenses for this date ───
            ...expenses.map((expense) =>
                _buildExpenseCard(expense, provider)),

            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ─── Expense Card ───
  Widget _buildExpenseCard(
      ExpenseModel expense, ExpenseProvider provider) {
    final color =
        categoryColors[expense.category] ?? Colors.grey;
    final icon =
        categoryIcons[expense.category] ?? Icons.more_horiz;

    return Dismissible(
      key: Key('history_${expense.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Expense',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700)),
          content: Text('Delete "${expense.title}"?',
              style: GoogleFonts.poppins(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color: textSecond)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child:
              Text('Delete', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
      onDismissed: (_) async {
        await provider.deleteExpense(expense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🗑️ "${expense.title}" deleted!',
                style: GoogleFonts.poppins(
                    color: Colors.white),
              ),
              backgroundColor: errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Colors.white,
                onPressed: () =>
                    provider.restoreExpense(expense),
              ),
            ),
          );
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: errorColor,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 22),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EditExpenseScreen(expense: expense),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ─── Icon ───
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 18),
              ),

              const SizedBox(width: 12),

              // ─── Details ───
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
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          expense.category,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: textSecond,
                          ),
                        ),
                      ],
                    ),
                    if (expense.note.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '📝 ${expense.note}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: textSecond,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // ─── Amount ───
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${_formatAmount(expense.amount)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: errorColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'tap to edit',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Empty State ───
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                  Icons.history_rounded,
                  size: 48,
                  color: primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No History Found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No expenses found for\nthe selected filters.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: textSecond,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedFilter   = 'All Time';
                  _selectedCategory = 'All';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [primary, primaryDark]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Clear Filters',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}