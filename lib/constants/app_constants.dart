import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════
// App Constants — Icons, Categories, Strings
// ═══════════════════════════════════════════════
class AppConstants {

  // ─── Category Icons ───
  static const Map<String, IconData> categoryIcons = {
    'Food':          Icons.restaurant_outlined,
    'Transport':     Icons.directions_car_outlined,
    'Bills':         Icons.receipt_outlined,
    'Health':        Icons.health_and_safety_outlined,
    'Entertainment': Icons.movie_outlined,
    'Shopping':      Icons.shopping_bag_outlined,
    'Education':     Icons.school_outlined,
    'Other':         Icons.more_horiz,
  };

  // ─── Category List ───
  static const List<String> categories = [
    'Food',
    'Transport',
    'Bills',
    'Health',
    'Entertainment',
    'Shopping',
    'Education',
    'Other',
  ];

  // ─── Categories with All ───
  static const List<String> categoriesWithAll = [
    'All',
    'Food',
    'Transport',
    'Bills',
    'Health',
    'Entertainment',
    'Shopping',
    'Education',
    'Other',
  ];

  // ─── Month Names ───
  static const List<String> monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // ─── App Info ───
  static const String appName      = 'Expense Tracker';
  static const String appVersion   = 'v1.0.0';
  static const String developerName = 'Muhammad Abdullah';
  static const String developerEmail =
      'muhammadabdullah495969@gmail.com';

  // ─── Default Budget ───
  static const double defaultBudget = 50000;

  // ─── Quick Amounts ───
  static const List<int> quickAmounts = [
    100, 500, 1000, 2000, 5000
  ];

  // ─── Format amount helper ───
  static String formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}