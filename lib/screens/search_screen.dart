import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import 'edit_expense_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {

  // ─── Controllers ───
  final TextEditingController _searchController =
  TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ─── State ───
  String _query           = '';
  String _selectedCategory = 'All';
  String _sortBy          = 'Latest';
  bool   _isSearching     = false;

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

  // ─── Categories ───
  final List<String> _categories = [
    'All', 'Food', 'Transport', 'Bills',
    'Health', 'Entertainment', 'Shopping',
    'Education', 'Other',
  ];

  // ─── Sort options ───
  final List<String> _sortOptions = [
    'Latest', 'Oldest', 'Highest', 'Lowest', 'A-Z',
  ];

  // ─── Category colors ───
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
      duration: const Duration(milliseconds: 400),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
        parent: _fadeController, curve: Curves.easeIn));

    // ─── Auto focus ───
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _searchController.addListener(() {
      setState(() => _isSearching = true);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _query       = _searchController.text;
            _isSearching = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Search + Filter + Sort ───
  List<ExpenseModel> _getResults(List<ExpenseModel> all) {
    var results = all.where((e) {
      final q = _query.toLowerCase().trim();
      final matchQuery = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.note.toLowerCase().contains(q);
      final matchCat = _selectedCategory == 'All' ||
          e.category == _selectedCategory;
      return matchQuery && matchCat;
    }).toList();

    // ─── Sort ───
    switch (_sortBy) {
      case 'Latest':
        results.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Oldest':
        results.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Highest':
        results.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Lowest':
        results.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'A-Z':
        results.sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return results;
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final results  = _getResults(provider.expenses);
    final total    = results.fold(0.0, (s, e) => s + e.amount);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [

              // ─── Search Header ───
              _buildSearchHeader(),

              // ─── Filter Chips ───
              _buildFilterChips(),

              // ─── Results Summary ───
              if (_query.isNotEmpty || _selectedCategory != 'All')
                _buildResultsSummary(results.length, total),

              // ─── Body ───
              Expanded(
                child: _query.isEmpty && _selectedCategory == 'All'
                    ? _buildInitialState(provider.expenses)
                    : results.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsList(results, provider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Search Header ───
  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [

          // ─── Back Button ───
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: textPrimary, size: 20),
            ),
          ),

          const SizedBox(width: 12),

          // ─── Search Field ───
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? primary.withOpacity(0.4)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.search_rounded,
                        color: Color(0xFF94A3B8), size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode:  _focusNode,
                      textInputAction: TextInputAction.search,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search expenses...',
                        hintStyle: GoogleFonts.poppins(
                          color: const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 10),
                      ),
                    ),
                  ),
                  // ─── Clear button ───
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Sort Button ───
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showSortSheet,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: primary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.sort_rounded,
                  color: primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter Chips ───
  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        height: 36,
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
                setState(() => _selectedCategory = cat);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? color
                      : color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? color
                        : color.withOpacity(0.2),
                  ),
                  boxShadow: isActive
                      ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                      : [],
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
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
    );
  }

  // ─── Results Summary ───
  Widget _buildResultsSummary(int count, double total) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded,
                  color: primary, size: 16),
              const SizedBox(width: 8),
              Text(
                '$count result${count == 1 ? '' : 's'} found',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ],
          ),
          Text(
            'Total: Rs. ${_formatAmount(total)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Initial State ───
  Widget _buildInitialState(List<ExpenseModel> all) {
    final recent = all.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ─── Search tip ───
          Container(
            padding: const EdgeInsets.all(16),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tips_and_updates_outlined,
                      color: primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Search Tips',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          )),
                      Text(
                        'Search by title, category, or note content',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: textSecond),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── Category Quick Filter ───
          Text('Browse by Category',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              )),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:  4,
              childAspectRatio: 1.1,
              crossAxisSpacing: 10,
              mainAxisSpacing:  10,
            ),
            itemCount: _categories.length - 1, // skip 'All'
            itemBuilder: (context, index) {
              final cat   = _categories[index + 1];
              final color = categoryColors[cat] ?? primary;
              final icon  = categoryIcons[cat] ?? Icons.more_horiz;
              final count = all
                  .where((e) => e.category == cat)
                  .length;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCategory = cat);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(height: 4),
                      Text(cat,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          )),
                      if (count > 0)
                        Text('$count',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: color,
                              fontWeight: FontWeight.w700,
                            )),
                    ],
                  ),
                ),
              );
            },
          ),

          if (recent.isNotEmpty) ...[
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Expenses',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    )),
                Text('${all.length} total',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: textSecond)),
              ],
            ),

            const SizedBox(height: 12),

            ...recent.map((expense) =>
                _buildExpenseCard(expense, '', context
                    .read<ExpenseProvider>())),
          ],
        ],
      ),
    );
  }

  // ─── Results List ───
  // ─── Results List with loading ───
  Widget _buildResultsList(
      List<ExpenseModel> results, ExpenseProvider provider) {

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF10B981),
          strokeWidth: 2.5,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 200 + index * 60),
          curve: Curves.easeOut,
          builder: (_, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          ),
          child: _buildExpenseCard(
              results[index], _query, provider),
        );
      },
    );
  }

  // ─── Expense Card ───
  Widget _buildExpenseCard(ExpenseModel expense,
      String query, ExpenseProvider provider) {
    final color =
        categoryColors[expense.category] ?? Colors.grey;
    final icon =
        categoryIcons[expense.category] ?? Icons.more_horiz;

    return Dismissible(
      key: Key('search_${expense.id}_${expense.title}'),
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
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
      onDismissed: (_) async {
        await provider.deleteExpense(expense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🗑️ "${expense.title}" deleted!',
                  style: GoogleFonts.poppins(
                      color: Colors.white)),
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
            Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 24),
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
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      // ─── Highlighted Title ───
                      _buildHighlightedText(
                          expense.title, query),

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
                        const SizedBox(height: 4),
                        Text(
                          '📝 ${expense.note}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
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

                const SizedBox(width: 10),

                // ─── Amount + Action ───
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Tap to edit',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Highlighted Text ───
  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ));
    }

    final lowerText  = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index      = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ));
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, index),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primary,
              backgroundColor: primary.withOpacity(0.12),
            ),
          ),
          TextSpan(
            text: text.substring(index + query.length),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
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
              child: const Icon(Icons.search_off_rounded,
                  size: 48, color: primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No expenses found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _query.isNotEmpty
                  ? 'No results for "$_query"'
                  : 'No expenses in this category',
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
                _searchController.clear();
                setState(() {
                  _query           = '';
                  _selectedCategory = 'All';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primary, primaryDark],
                  ),
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

  // ─── Sort Bottom Sheet ───
  void _showSortSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft:  Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Sort By',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                )),
            const SizedBox(height: 16),
            ..._sortOptions.map((option) {
              final isActive = option == _sortBy;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _sortBy = option);
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? primary.withOpacity(0.08)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? primary.withOpacity(0.3)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(option,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isActive
                                ? primary
                                : textPrimary,
                          )),
                      if (isActive)
                        const Icon(Icons.check_circle_rounded,
                            color: primary, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}