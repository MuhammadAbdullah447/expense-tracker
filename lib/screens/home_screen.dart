import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import 'edit_expense_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ─── Provider se data lो ───
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: provider.isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1E3A5F),
        ),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(provider),
            _buildSummaryCards(context, provider),
            if (provider.categoryTotals.isNotEmpty)
              _buildCategorySection(provider),
            _buildRecentExpenses(context, provider),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Top header ───
  Widget _buildHeader(ExpenseProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A5F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good Morning! 👋',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('Muhammad Abdullah',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border:
              Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text('Total Spent This Month',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  'Rs. ${provider.totalSpent.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  '${provider.expenses.length} expense${provider.expenses.length == 1 ? '' : 's'} recorded',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Budget, Spent aur Remaining cards ───
  Widget _buildSummaryCards(
      BuildContext context, ExpenseProvider provider) {
    final bool isOverBudget = provider.remaining < 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              // ─── Budget card — tap to edit ───
              Expanded(
                child: GestureDetector(
                  onTap: () => _showBudgetDialog(context, provider),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit,
                                color: Colors.green, size: 20),
                          ),
                          const SizedBox(height: 10),
                          const Text('Budget (tap to edit)',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            'Rs. ${provider.budget.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ─── Spent card ───
              Expanded(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_upward,
                              color: Colors.red, size: 20),
                        ),
                        const SizedBox(height: 10),
                        const Text('Spent',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${provider.totalSpent.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ─── Remaining card ───
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: isOverBudget
                ? const Color(0xFFFFEBEE)
                : const Color(0xFFE8F5E9),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isOverBudget
                            ? Icons.warning_amber
                            : Icons.savings,
                        color: isOverBudget
                            ? Colors.red
                            : Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isOverBudget
                            ? 'Over Budget!'
                            : 'Remaining Budget',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isOverBudget
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Rs. ${provider.remaining.abs().toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isOverBudget
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category wise spending ───
  Widget _buildCategorySection(ExpenseProvider provider) {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Spending by Category',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: provider.categoryTotals.entries.map((entry) {
              final color =
                  categoryColors[entry.key] ?? Colors.grey;
              final icon =
                  categoryIcons[entry.key] ?? Icons.more_horiz;
              return Container(
                width: 90,
                padding:
                const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 26),
                    const SizedBox(height: 4),
                    Text(entry.key,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      'Rs.${entry.value.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Recent expenses list ───
  Widget _buildRecentExpenses(
      BuildContext context, ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Expenses',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F))),
              TextButton(
                  onPressed: () {},
                  child: const Text('See All')),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.expenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('No expenses yet!',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('Tap + to add your first expense',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.expenses.length,
              itemBuilder: (context, index) {
                return _buildExpenseCard(
                    context, provider.expenses[index], provider);
              },
            ),
        ],
      ),
    );
  }

  // ─── Single expense card — swipe to delete ───
  Widget _buildExpenseCard(BuildContext context,
      ExpenseModel expense, ExpenseProvider provider) {
    final Map<String, Color> colors = {
      'Food':          const Color(0xFF4CAF50),
      'Transport':     const Color(0xFF2196F3),
      'Bills':         const Color(0xFFFF9800),
      'Health':        const Color(0xFFE91E63),
      'Entertainment': const Color(0xFF9C27B0),
      'Shopping':      const Color(0xFF00BCD4),
      'Education':     const Color(0xFF795548),
      'Other':         const Color(0xFF607D8B),
    };

    final Map<String, IconData> icons = {
      'Food':          Icons.fastfood,
      'Transport':     Icons.directions_car,
      'Bills':         Icons.receipt_long,
      'Health':        Icons.favorite,
      'Entertainment': Icons.sports_esports,
      'Shopping':      Icons.shopping_bag,
      'Education':     Icons.school,
      'Other':         Icons.more_horiz,
    };

    final color = colors[expense.category] ?? Colors.grey;
    final icon = icons[expense.category] ?? Icons.more_horiz;

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Expense'),
            content: Text(
                'Are you sure you want to delete "${expense.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await provider.deleteExpense(expense);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🗑️ "${expense.title}" deleted!'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Colors.white,
                onPressed: () => provider.restoreExpense(expense),
              ),
            ),
          );
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(expense.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${expense.category}  •  ${expense.formattedDate}',
                style:
                const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (expense.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '📝 ${expense.note}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E3A5F),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${expense.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFFE53935)),
              ),
              const SizedBox(height: 4),
              // ─── Edit button ───
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditExpenseScreen(expense: expense),
                  ),
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1E3A5F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Budget dialog ───
  void _showBudgetDialog(
      BuildContext context, ExpenseProvider provider) {
    final TextEditingController budgetController =
    TextEditingController(
        text: provider.budget.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: Container(
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
                      right:
                      BorderSide(color: Colors.grey.shade300)),
                ),
                child: const Text(
                  'Rs.',
                  style: TextStyle(
                    color: Color(0xFF1E3A5F),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: budgetController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 50000',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final value = double.tryParse(
                  budgetController.text.trim());
              if (value != null && value > 0) {
                provider.updateBudget(value);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}