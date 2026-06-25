import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import 'edit_expense_screen.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {

  // ─── Animation Controllers ───
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  // ─── Colors ───
  static const primary     = Color(0xFF10B981);
  static const primaryDark = Color(0xFF059669);
  static const bgColor     = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecond  = Color(0xFF64748B);
  static const errorColor  = Color(0xFFEF4444);
  static const cardColor   = Colors.white;

  // ─── Category maps ───
  final Map<String, Color> categoryColors = {
    'Food':          const Color(0xFFFF9800),
    'Transport':     const Color(0xFF2196F3),
    'Bills':         const Color(0xFF3B82F6),
    'Health':        const Color(0xFFE91E63),
    'Entertainment': const Color(0xFF9C27B0),
    'Shopping':      const Color(0xFF00BCD4),
    'Education':     const Color(0xFF10B981),
    'Other':         const Color(0xFF607D8B),
  };

  final Map<String, IconData> categoryIcons = {
    'Food':          Icons.restaurant,
    'Transport':     Icons.directions_car,
    'Bills':         Icons.receipt_long,
    'Health':        Icons.favorite,
    'Entertainment': Icons.movie,
    'Shopping':      Icons.shopping_bag,
    'Education':     Icons.school,
    'Other':         Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideController, curve: Curves.easeOut));

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _progressController, curve: Curves.easeOut),
    );
  }

  // ─── Notification Panel Bottom Sheet ───
  void _showNotificationPanel(BuildContext context) {
    final notifProvider = context.read<NotificationProvider>();
    notifProvider.markAllAsRead();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: notifProvider,
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollController) =>
              _NotificationSheet(scrollController: scrollController),
        ),
      ),
    );
  }

  // ─── Time based greeting ───
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      backgroundColor: bgColor,
      body: provider.isLoading
          ? _buildShimmerLoading()
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Premium Header ───
                _buildHeader(provider),

                const SizedBox(height: 20),

                // ─── Quick Stats Row ───
                _buildQuickStats(provider),

                const SizedBox(height: 20),

                // ─── Donut Chart ───
                if (provider.categoryTotals.isNotEmpty)
                  _buildCategoryChart(provider),

                const SizedBox(height: 20),

                // ─── Category Breakdown ───
                if (provider.categoryTotals.isNotEmpty)
                  _buildCategoryBreakdown(provider),

                const SizedBox(height: 20),

                // ─── Recent Transactions ───
                _buildRecentTransactions(provider),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Error Banner ───
  Widget _buildErrorBanner(String message, ExpenseProvider provider) {
    final bool isNoInternet = message.contains('internet') ||
        message.contains('timed out');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isNoInternet
            ? Colors.orange.shade50
            : Colors.red.shade50,
        border: Border(
          bottom: BorderSide(
            color: isNoInternet
                ? Colors.orange.shade200
                : Colors.red.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isNoInternet
                ? Icons.wifi_off_rounded
                : Icons.error_outline_rounded,
            color: isNoInternet
                ? Colors.orange.shade700
                : Colors.red.shade700,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isNoInternet
                    ? Colors.orange.shade800
                    : Colors.red.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // ─── Retry button ───
          GestureDetector(
            onTap: () {
              provider.loadExpenses(); // reload
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isNoInternet
                    ? Colors.orange.shade100
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isNoInternet
                      ? Colors.orange.shade800
                      : Colors.red.shade800,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shimmer Loading ───
  Widget _buildShimmerLoading() {
    return Column(
      children: [
        Container(
          height: 280,
          color: const Color(0xFF064E3B),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(3, (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )),
          ),
        ),
      ],
    );
  }

  // ─── Premium Header ───
  Widget _buildHeader(ExpenseProvider provider) {
    final spent      = provider.totalSpent;
    final budget     = provider.budget;
    final percentage = budget > 0
        ? (spent / budget).clamp(0.0, 1.0)
        : 0.0;
    final isOver     = spent > budget;
    final isClose    = percentage >= 0.8 && !isOver;

    final progressColor = isOver
        ? errorColor
        : isClose
        ? Colors.orange
        : primary;

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

          // ─── Top Row — Greeting + Avatar ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_greeting 👋',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FirebaseAuth.instance.currentUser?.displayName ?? 'Welcome!',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Row(
                children: [
                  // ─── Notification bell with badge ───
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showNotificationPanel(context);
                    },
                    child: Stack(
                      children: [
                        _buildHeaderIcon(Icons.notifications_outlined),
                        Consumer<NotificationProvider>(
                          builder: (_, notifProvider, __) {
                            final count = notifProvider.unreadCount;
                            if (count == 0) return const SizedBox.shrink();
                            return Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
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
                  // const SizedBox(width: 10),
                  // // ─── Avatar ───
                  // Container(
                  //   width: 42,
                  //   height: 42,
                  //   decoration: BoxDecoration(
                  //     shape: BoxShape.circle,
                  //     color: Colors.white.withOpacity(0.2),
                  //     border: Border.all(
                  //         color: Colors.white.withOpacity(0.4), width: 2),
                  //   ),
                  //   child: const Icon(Icons.person, color: Colors.white, size: 22),
                  // ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Hero Balance Card ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Spent This Month',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),

                // ─── Amount ───
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: spent),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOut,
                  builder: (_, value, __) => Text(
                    'Rs. ${_formatAmount(value)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                Text(
                  'of Rs. ${_formatAmount(budget)} budget',
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Animated Progress Bar ───
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, _) {
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percentage *
                                _progressAnimation.value,
                            minHeight: 8,
                            backgroundColor:
                            Colors.white.withOpacity(0.2),
                            valueColor:
                            AlwaysStoppedAnimation<Color>(
                                progressColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(percentage * 100).toStringAsFixed(1)}% used',
                              style: GoogleFonts.poppins(
                                color: progressColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              isOver
                                  ? '⚠️ Over budget!'
                                  : '${provider.expenses.length} expenses',
                              style: GoogleFonts.poppins(
                                color: isOver
                                    ? errorColor
                                    : Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ─── Spent vs Remaining ───
                Row(
                  children: [
                    Expanded(
                      child: _buildHeaderStat(
                        'Spent',
                        'Rs. ${_formatAmount(spent)}',
                        errorColor,
                        Icons.arrow_upward,
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.white24),
                    Expanded(
                      child: _buildHeaderStat(
                        'Remaining',
                        'Rs. ${_formatAmount(provider.remaining.abs())}',
                        isOver ? errorColor : primary,
                        isOver
                            ? Icons.warning_amber
                            : Icons.savings,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header icon button ───
  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withOpacity(0.2)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  // ─── Header stat ───
  Widget _buildHeaderStat(
      String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      color: Colors.white60, fontSize: 10)),
              Text(value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Quick Stats Row ───
  Widget _buildQuickStats(ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // ─── Budget — tap to edit ───
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showBudgetDialog(provider);
              },
              child: _buildStatCard(
                icon:  Icons.edit_outlined,
                iconBg: Colors.blue.shade50,
                iconColor: Colors.blue,
                label: 'Budget',
                value: 'Rs. ${_formatAmount(provider.budget)}',
                subtitle: 'Tap to edit',
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ─── Spent ───
          Expanded(
            child: _buildStatCard(
              icon:  Icons.arrow_upward,
              iconBg: Colors.red.shade50,
              iconColor: errorColor,
              label: 'Spent',
              value: 'Rs. ${_formatAmount(provider.totalSpent)}',
              subtitle: 'This month',
            ),
          ),
          const SizedBox(width: 12),

          // ─── Remaining ───
          Expanded(
            child: _buildStatCard(
              icon:  provider.remaining < 0
                  ? Icons.warning_amber
                  : Icons.savings,
              iconBg: provider.remaining < 0
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              iconColor: provider.remaining < 0
                  ? errorColor
                  : primary,
              label: 'Left',
              value:
              'Rs. ${_formatAmount(provider.remaining.abs())}',
              subtitle: provider.remaining < 0
                  ? 'Over budget'
                  : 'Remaining',
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stat Card ───
  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  color: textSecond, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(subtitle,
              style: GoogleFonts.poppins(
                  color: textSecond, fontSize: 9)),
        ],
      ),
    );
  }

  // ─── Category Donut Chart ───
  Widget _buildCategoryChart(ExpenseProvider provider) {
    final totals  = provider.categoryTotals;
    final total   = provider.totalSpent;
    final entries = totals.entries.toList();

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spending by Category',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'This Month',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ─── Donut Chart ───
            Row(
              children: [
                // Chart
                SizedBox(
                  height: 160,
                  width: 160,
                  child: PieChart(
                    PieChartData(
                      sections: entries.map((entry) {
                        final pct =
                        total > 0 ? entry.value / total : 0.0;
                        final color = categoryColors[entry.key] ??
                            Colors.grey;
                        return PieChartSectionData(
                          value: entry.value,
                          color: color,
                          title:
                          '${(pct * 100).toStringAsFixed(0)}%',
                          radius: 55,
                          titleStyle: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                      centerSpaceColor: cardColor,
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // ─── Legend ───
                Expanded(
                  child: Column(
                    children: entries.map((entry) {
                      final color =
                          categoryColors[entry.key] ?? Colors.grey;
                      final pct = total > 0
                          ? (entry.value / total * 100)
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Category Breakdown ───
  Widget _buildCategoryBreakdown(ExpenseProvider provider) {
    final totals = provider.categoryTotals;
    final total  = provider.totalSpent;
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            Text(
              'Category Breakdown',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...sorted.map((entry) {
              final color =
                  categoryColors[entry.key] ?? Colors.grey;
              final icon =
                  categoryIcons[entry.key] ?? Icons.more_horiz;
              final pct =
              total > 0 ? entry.value / total : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    // ─── Icon ───
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                      Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
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
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  )),
                              Text(
                                'Rs. ${_formatAmount(entry.value)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 5,
                              backgroundColor:
                              Colors.grey.shade100,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(
                                  color),
                            ),
                          ),
                          const SizedBox(height: 3),
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
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── Recent Transactions ───
  Widget _buildRecentTransactions(ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // ─── Header ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'See All',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ─── Empty State ───
          if (provider.expenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.receipt_long_outlined,
                          size: 48, color: primary),
                    ),
                    const SizedBox(height: 16),
                    Text('No Expenses Yet!',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      'Start tracking your spending\nby tapping the + button below.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: textSecond,
                          height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded,
                              color: primary, size: 16),
                          const SizedBox(width: 6),
                          Text('Add First Expense',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: primary,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
          // ─── Show max 5 recent ───
            ...provider.expenses
                .take(5)
                .toList()
                .asMap()
                .entries
                .map((entry) {
              final index   = entry.key;
              final expense = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(
                    milliseconds: 300 + index * 80),
                curve: Curves.easeOut,
                builder: (_, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                ),
                child: _buildTransactionCard(
                    expense, provider),
              );
            }),


        ],
      ),
    );
  }

  // ─── Transaction Card ───
  Widget _buildTransactionCard(
      ExpenseModel expense, ExpenseProvider provider) {
    final color =
        categoryColors[expense.category] ?? Colors.grey;
    final icon =
        categoryIcons[expense.category] ?? Icons.more_horiz;

    return Dismissible(
      key: Key('home_${expense.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Delete Expense',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700)),
            content: Text(
              'Delete "${expense.title}"?',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
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
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: GoogleFonts.poppins()),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await provider.deleteExpense(expense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🗑️ "${expense.title}" deleted!',
                style: GoogleFonts.poppins(color: Colors.white),
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline,
                color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontSize: 11)),
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
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // ─── Category Icon ───
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(width: 14),

              // ─── Details ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${expense.category} · ${expense.formattedDate}',
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
                          fontSize: 11,
                          color: textSecond,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ─── Amount + Tap hint ───
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${_formatAmount(expense.amount)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: errorColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to edit',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
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

  // ─── Budget Dialog ───
  void _showBudgetDialog(ExpenseProvider provider) {
    final controller = TextEditingController(
        text: provider.budget.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Set Monthly Budget',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 16)),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(
                          color: Colors.grey.shade200)),
                ),
                child: Text('Rs.',
                    style: GoogleFonts.poppins(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    )),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
                  autofocus: true,
                  style: GoogleFonts.poppins(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 50000',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: textSecond)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final val =
              double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                provider.updateBudget(val);
                Navigator.pop(ctx);
              }
            },
            child: Text('Save',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Format amount — 1000 → 1k ───
  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}

// ─── Notification Sheet Widget ───
class _NotificationSheet extends StatelessWidget {
  final ScrollController scrollController;
  const _NotificationSheet({required this.scrollController});

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.overBudget: return const Color(0xFFEF4444);
      case NotificationType.warning:    return const Color(0xFFF97316);
      case NotificationType.success:    return const Color(0xFF10B981);
      case NotificationType.info:       return const Color(0xFF3B82F6);
    }
  }

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.overBudget: return Icons.warning_rounded;
      case NotificationType.warning:    return Icons.info_outline_rounded;
      case NotificationType.success:    return Icons.check_circle_outline;
      case NotificationType.info:       return Icons.notifications_outlined;
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ─── Handle ───
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // ─── Header ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (notifications.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      provider.clearAll();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ─── List or Empty ───
          Expanded(
            child: notifications.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 64,
                      color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No notifications yet',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade400,
                      )),
                  const SizedBox(height: 6),
                  Text('Budget alerts & activity\nwill appear here',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      )),
                ],
              ),
            )
                : ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final n = notifications[index];
                final color = _typeColor(n.type);
                final icon  = _typeIcon(n.type);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: color.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Icon ───
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: Icon(icon,
                            color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      // ─── Content ───
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(n.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                )),
                            const SizedBox(height: 3),
                            Text(n.message,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                  height: 1.4,
                                )),
                            const SizedBox(height: 6),
                            Text(_timeAgo(n.time),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}