import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController  = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController   = TextEditingController();

  String _selectedCategory = 'Food';
  DateTime _selectedDate   = DateTime.now();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food',          'icon': Icons.fastfood,       'color': Color(0xFF4CAF50)},
    {'name': 'Transport',     'icon': Icons.directions_car, 'color': Color(0xFF2196F3)},
    {'name': 'Bills',         'icon': Icons.receipt_long,   'color': Color(0xFFFF9800)},
    {'name': 'Health',        'icon': Icons.favorite,       'color': Color(0xFFE91E63)},
    {'name': 'Entertainment', 'icon': Icons.sports_esports, 'color': Color(0xFF9C27B0)},
    {'name': 'Shopping',      'icon': Icons.shopping_bag,   'color': Color(0xFF00BCD4)},
    {'name': 'Education',     'icon': Icons.school,         'color': Color(0xFF795548)},
    {'name': 'Other',         'icon': Icons.more_horiz,     'color': Color(0xFF607D8B)},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ─── Date picker ───
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A5F)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ─── Expense save karo — Provider ke zariye Firestore mein ───
  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final newExpense = ExpenseModel(
        title:    _titleController.text.trim(),
        amount:   double.parse(_amountController.text.trim()),
        category: _selectedCategory,
        date:     _selectedDate,
        note:     _noteController.text.trim(),
      );

      // Provider ke zariye save karo
      await context.read<ExpenseProvider>().addExpense(newExpense);

      if (mounted) {
        setState(() => _isLoading = false);  // ← Loading stop

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Expense saved successfully!'),
            backgroundColor: Color(0xFF1E3A5F),
            duration: Duration(seconds: 2),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Expense Title'),
                    _buildTitleField(),
                    const SizedBox(height: 16),

                    _buildLabel('Amount (Rs.)'),
                    _buildAmountField(),
                    const SizedBox(height: 16),

                    _buildLabel('Category'),
                    _buildCategorySelector(),
                    const SizedBox(height: 16),

                    _buildLabel('Date'),
                    _buildDatePicker(),
                    const SizedBox(height: 16),

                    _buildLabel('Note (Optional)'),
                    _buildNoteField(),
                    const SizedBox(height: 30),

                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
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
          Text('Add Expense',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Record your daily spending',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  // ─── Field label ───
  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1E3A5F))),
  );

  // ─── Title field ───
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration:
      _inputDecoration('e.g. Grocery Shopping', Icons.edit_outlined),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter expense title';
        }
        final RegExp titleRegex = RegExp(r'^[a-zA-Z0-9\s]+$');
        if (!titleRegex.hasMatch(value.trim())) {
          return 'Only letters and numbers allowed';
        }
        if (value.trim().length < 3) {
          return 'Title must be at least 3 characters';
        }
        return null;
      },
    );
  }

  // ─── Amount field — Rs. hamesha visible ───
  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                  right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: const Text('Rs.',
                style: TextStyle(
                    color: Color(0xFF1E3A5F),
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
          Expanded(
            child: TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: const InputDecoration(
                hintText: 'e.g. 500',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter amount';
                }
                final RegExp amountRegex =
                RegExp(r'^\d+(\.\d{1,2})?$');
                if (!amountRegex.hasMatch(value.trim())) {
                  return 'Enter valid amount (e.g. 500 or 500.50)';
                }
                if (double.parse(value.trim()) <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category chips ───
  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final bool isSelected = _selectedCategory == cat['name'];
        return GestureDetector(
          onTap: () =>
              setState(() => _selectedCategory = cat['name']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (cat['color'] as Color)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: cat['color'] as Color, width: 1.5),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: (cat['color'] as Color)
                      .withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat['icon'] as IconData,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : cat['color'] as Color),
                const SizedBox(width: 6),
                Text(cat['name'] as String,
                    style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Date picker button ───
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: Color(0xFF1E3A5F), size: 20),
            const SizedBox(width: 12),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(fontSize: 15),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ─── Note field ───
  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Add a note...',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Color(0xFF1E3A5F), width: 2),
        ),
      ),
    );
  }

  // ─── Save button ───
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A5F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 3,
        ),
        // ─── Loading hone par spinner dikhao ───
        icon: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        )
            : const Icon(Icons.save_outlined),
        label: Text(
          _isLoading ? 'Saving...' : 'Save Expense',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
        // ─── Loading hone par button disable karo ───
        onPressed: _isLoading ? null : _saveExpense,
      ),
    );
  }

  // ─── Reusable input decoration ───
  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: const Color(0xFF1E3A5F))
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: Color(0xFF1E3A5F), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}