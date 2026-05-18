import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with TickerProviderStateMixin {

  // ─── Form & Controllers ───
  final _formKey                                 = GlobalKey<FormState>();
  final TextEditingController _titleController   = TextEditingController();
  final TextEditingController _amountController  = TextEditingController();
  final TextEditingController _noteController    = TextEditingController();

  // ─── Focus Nodes ───
  final FocusNode _titleFocus  = FocusNode();
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _noteFocus   = FocusNode();

  // ─── State ───
  String   _selectedCategory = 'Food';
  DateTime _selectedDate     = DateTime.now();
  bool     _isLoading        = false;
  int      _noteLength       = 0;
  int      _titleLength      = 0;

  // ─── Animation Controllers ───
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late List<Animation<double>> _fieldAnimations;

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
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food',          'icon': Icons.restaurant_outlined,      'color': Color(0xFFFF9800)},
    {'name': 'Transport',     'icon': Icons.directions_car_outlined,  'color': Color(0xFF2196F3)},
    {'name': 'Bills',         'icon': Icons.receipt_outlined,         'color': Color(0xFF3B82F6)},
    {'name': 'Health',        'icon': Icons.health_and_safety_outlined,'color': Color(0xFFE91E63)},
    {'name': 'Entertainment', 'icon': Icons.movie_outlined,           'color': Color(0xFF9C27B0)},
    {'name': 'Shopping',      'icon': Icons.shopping_bag_outlined,    'color': Color(0xFF00BCD4)},
    {'name': 'Education',     'icon': Icons.school_outlined,          'color': Color(0xFF10B981)},
    {'name': 'Other',         'icon': Icons.more_horiz_outlined,      'color': Color(0xFF607D8B)},
  ];

  // ─── Quick amounts ───
  final List<int> _quickAmounts = [100, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _addListeners();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fieldAnimations = List.generate(7, (index) {
      final start = index * 0.10;
      final end   = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
  }

  void _addListeners() {
    _titleController.addListener(() =>
        setState(() => _titleLength = _titleController.text.length));
    _noteController.addListener(() =>
        setState(() => _noteLength = _noteController.text.length));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _titleFocus.dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  // ─── Date picker ───
  Future<void> _pickDate() async {
    HapticFeedback.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: primary),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: primary),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ─── Relative date string ───
  String get _dateLabel {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selected == today) return 'Today';
    if (selected == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';
  }

  // ─── Save expense ───
  // ─── Save expense ───
  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);

      final expense = ExpenseModel(
        title:    _titleController.text.trim(),
        amount:   double.parse(_amountController.text.trim()),
        category: _selectedCategory,
        date:     _selectedDate,
        note:     _noteController.text.trim(),
      );

      await context.read<ExpenseProvider>().addExpense(expense);

      if (mounted) {
        setState(() => _isLoading = false);
        HapticFeedback.heavyImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('✅ Expense saved successfully!',
                    style: GoogleFonts.poppins(
                        color: Colors.white)),
              ],
            ),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        _titleController.clear();
        _amountController.clear();
        _noteController.clear();
        setState(() {
          _selectedCategory = 'Food';
          _selectedDate     = DateTime.now();
        });
      }
    }
  }

  // ─── Animated field wrapper ───
  Widget _animated(int index, Widget child) {
    return AnimatedBuilder(
      animation: _fieldAnimations[index.clamp(0, 6)],
      builder: (_, __) {
        final v = _fieldAnimations[index.clamp(0, 6)].value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - v)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: FadeTransition(
          opacity: _fadeController,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ─── Header ───
                _buildHeader(),

                // ─── Form ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ─── Amount Field — most important ───
                        _animated(0, _buildAmountSection()),
                        const SizedBox(height: 20),

                        // ─── Title Field ───
                        _animated(1, _buildTitleField()),
                        const SizedBox(height: 20),

                        // ─── Category ───
                        _animated(2, _buildCategorySection()),
                        const SizedBox(height: 20),

                        // ─── Date ───
                        _animated(3, _buildDatePicker()),
                        const SizedBox(height: 20),

                        // ─── Note ───
                        _animated(4, _buildNoteField()),
                        const SizedBox(height: 30),

                        // ─── Save Button ───
                        _animated(5, _buildSaveButton()),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader() {
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
          // ─── Top row ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Expense',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 4),
                  Text('What did you spend on?',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      )),
                ],
              ),
              // ─── Category indicator ───
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categories.firstWhere((c) =>
                      c['name'] == _selectedCategory)['icon'],
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedCategory,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Amount Section ───
  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('💰 Amount', required: true),
        const SizedBox(height: 10),

        // ─── Large Amount Input ───
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // ─── Input Row ───
              Row(
                children: [
                  // ─── Rs. prefix ───
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.08),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      border: Border(
                        right: BorderSide(color: borderColor),
                      ),
                    ),
                    child: Text('Rs.',
                        style: GoogleFonts.poppins(
                          color: primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        )),
                  ),

                  // ─── Number input ───
                  Expanded(
                    child: TextFormField(
                      controller:   _amountController,
                      focusNode:    _amountFocus,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).requestFocus(_titleFocus),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade300,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Amount is required';
                        }
                        final RegExp amountRegex = RegExp(r'^\d+(\.\d{1,2})?$');
                        if (!amountRegex.hasMatch(value.trim())) {
                          return 'Enter valid amount (e.g. 500 or 500.50)';
                        }
                        final double amount = double.parse(value.trim());
                        if (amount <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        if (amount > 10000000) {
                          return 'Amount seems too large. Please check.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ─── Quick Amount Chips ───
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickAmounts.map((amount) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final current = double.tryParse(
                      _amountController.text.trim()) ??
                      0;
                  _amountController.text =
                      (current + amount).toStringAsFixed(0);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    '+${amount >= 1000 ? '${amount ~/ 1000}k' : amount}',
                    style: GoogleFonts.poppins(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Title Field ───
  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('📝 What did you buy?',
                required: true),
            Text('$_titleLength/50',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: textSecond)),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller:      _titleController,
          focusNode:       _titleFocus,
          maxLength:       50,
          textInputAction: TextInputAction.next,
          onEditingComplete: () =>
              FocusScope.of(context).requestFocus(_noteFocus),
          style: GoogleFonts.poppins(
              color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            counterText: '',
            hintText:
            'Grocery shopping, Coffee, Movie ticket...',
            hintStyle: GoogleFonts.poppins(
                color: textSecond.withOpacity(0.5),
                fontSize: 13),
            prefixIcon: const Icon(
                Icons.shopping_bag_outlined,
                color: Color(0xFF94A3B8),
                size: 20),
            filled: true,
            fillColor: cardColor,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: errorColor, width: 1.5),
            ),
            errorStyle: GoogleFonts.poppins(
                fontSize: 11, color: errorColor),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter expense title';
            }
            if (value.trim().length < 2) {
              return 'Title too short';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─── Category Section ───
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('🏷️ Category', required: true),
        const SizedBox(height: 12),

        // ─── 4 column grid ───
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:  4,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing:  10,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat       = _categories[index];
            final isSelected =
                _selectedCategory == cat['name'];
            final color     = cat['color'] as Color;

            return GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _selectedCategory = cat['name']);
              },
              onTapDown: (_) => setState(() {}),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.elasticOut,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : color.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : color,
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat['name'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 9,           // ← 10 se 9 kar diya
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : textPrimary,
                      ),
                    ),

                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Date Picker ───
  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('📅 Date', required: true),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                      Icons.calendar_today_outlined,
                      color: primary,
                      size: 18),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    if (_dateLabel != 'Today' &&
                        _dateLabel != 'Yesterday')
                      const SizedBox()
                    else
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: textSecond),
                      ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Change',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: primary,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Note Field ───
  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('💬 Note', required: false),
            Text('$_noteLength/100',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: textSecond)),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller:  _noteController,
          focusNode:   _noteFocus,
          maxLines:    3,
          minLines:    2,
          maxLength:   100,
          style: GoogleFonts.poppins(
              color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            counterText: '',
            hintText:    'Add a note (optional)...',
            hintStyle:   GoogleFonts.poppins(
                color: textSecond.withOpacity(0.5),
                fontSize: 13),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.edit_note_outlined,
                  color: Color(0xFF94A3B8), size: 20),
            ),
            filled:    true,
            fillColor: cardColor,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Save Button ───
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _saveExpense,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width:  double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? null
              : const LinearGradient(
            colors: [primary, primaryDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: _isLoading ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isLoading
              ? []
              : [
            BoxShadow(
              color: primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Save Expense',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section Label ───
  Widget _buildSectionLabel(String text,
      {bool required = false}) {
    return Row(
      children: [
        Text(text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            )),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*',
              style: TextStyle(
                  color: errorColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }
}