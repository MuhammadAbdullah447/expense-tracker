import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class EditExpenseScreen extends StatefulWidget {
  final ExpenseModel expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;

  // ─── Same colors as add screen ───
  static const primary = Color(0xFF10B981);
  static const primaryDark = Color(0xFF059669);
  static const bgColor = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecond = Color(0xFF64748B);
  static const borderColor = Color(0xFFE2E8F0);
  static const errorColor = Color(0xFFEF4444);
  static const cardColor = Colors.white;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.restaurant_outlined, 'color': Color(0xFFFF9800)},
    {'name': 'Transport', 'icon': Icons.directions_car_outlined, 'color': Color(0xFF2196F3)},
    {'name': 'Bills', 'icon': Icons.receipt_outlined, 'color': Color(0xFFF59E0B)},
    {'name': 'Health', 'icon': Icons.health_and_safety_outlined, 'color': Color(0xFFE91E63)},
    {'name': 'Entertainment', 'icon': Icons.movie_outlined, 'color': Color(0xFF8B5CF6)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined, 'color': Color(0xFF00BCD4)},
    {'name': 'Education', 'icon': Icons.school_outlined, 'color': Color(0xFF10B981)},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Color(0xFF607D8B)},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(text: widget.expense.amount.toStringAsFixed(0));
    _noteController = TextEditingController(text: widget.expense.note);
    _selectedCategory = widget.expense.category;
    _selectedDate = widget.expense.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
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

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selected == today) return 'Today';
    if (selected == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';
  }

  Future<void> _updateExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final updatedExpense = ExpenseModel(
        id: widget.expense.id,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        category: _selectedCategory,
        date: _selectedDate,
        note: _noteController.text.trim(),
      );

      await context.read<ExpenseProvider>().updateExpense(updatedExpense);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('✅ Expense updated successfully!',
                    style: GoogleFonts.poppins(color: Colors.white)),
              ],
            ),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountSection(),
                      const SizedBox(height: 20),
                      _buildTitleField(),
                      const SizedBox(height: 20),
                      _buildCategorySection(),
                      const SizedBox(height: 20),
                      _buildDatePicker(),
                      const SizedBox(height: 20),
                      _buildNoteField(),
                      const SizedBox(height: 30),
                      _buildUpdateButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        28,
      ),
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
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Expense',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Update your expense details',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _categories.firstWhere(
                              (c) => c['name'] == _selectedCategory,
                        )['icon'],
                        color: Colors.white,
                        size: 16,
                      ),

                      const SizedBox(width: 6),

                      Flexible(
                        child: Text(
                          _selectedCategory,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('💰 Amount', required: true),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                  border: Border(right: BorderSide(color: borderColor)),
                ),
                child: Text('Rs.',
                    style: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade300),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Amount is required';
                    final RegExp amountRegex = RegExp(r'^\d+(\.\d{1,2})?$');
                    if (!amountRegex.hasMatch(value.trim())) return 'Enter valid amount (e.g. 500 or 500.50)';
                    final double amount = double.parse(value.trim());
                    if (amount <= 0) return 'Amount must be greater than 0';
                    if (amount > 10000000) return 'Amount seems too large. Please check.';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('📝 What did you buy?', required: true),
        const SizedBox(height: 10),
        TextFormField(
          controller: _titleController,
          maxLength: 50,
          style: GoogleFonts.poppins(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Grocery shopping, Coffee, Movie ticket...',
            hintStyle: GoogleFonts.poppins(color: textSecond.withOpacity(0.5), fontSize: 13),
            prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF94A3B8), size: 20),
            filled: true,
            fillColor: cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: borderColor, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: errorColor, width: 1.5)),
            errorStyle: GoogleFonts.poppins(fontSize: 11, color: errorColor),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Please enter expense title';
            if (value.trim().length < 2) return 'Title too short';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('🏷️ Category', required: true),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = _selectedCategory == cat['name'];
            final color = cat['color'] as Color;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat['name']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? color : color.withOpacity(0.2), width: isSelected ? 2 : 1),
                  boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))] : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(cat['icon'] as IconData, color: isSelected ? Colors.white : color, size: 24),
                    const SizedBox(height: 6),
                    Text(cat['name'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : textPrimary,
                        )),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('📅 Date', required: true),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.calendar_today_outlined, color: primary, size: 18),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_dateLabel,
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
                    if (_dateLabel != 'Today' && _dateLabel != 'Yesterday')
                      const SizedBox()
                    else
                      Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: GoogleFonts.poppins(fontSize: 11, color: textSecond)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('Change',
                      style: GoogleFonts.poppins(fontSize: 11, color: primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('💬 Note', required: false),
        const SizedBox(height: 10),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          minLines: 2,
          maxLength: 100,
          style: GoogleFonts.poppins(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Add a note (optional)...',
            hintStyle: GoogleFonts.poppins(color: textSecond.withOpacity(0.5), fontSize: 13),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.edit_note_outlined, color: Color(0xFF94A3B8), size: 20),
            ),
            filled: true,
            fillColor: cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: borderColor, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _updateExpense,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _isLoading ? null : const LinearGradient(
            colors: [primary, primaryDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: _isLoading ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isLoading ? [] : [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.save_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Update Expense',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, {bool required = false}) {
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
          const Text('*', style: TextStyle(color: errorColor, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }
}