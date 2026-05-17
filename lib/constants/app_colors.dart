import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════
// App Colors — Sab colors ek jagah
// ═══════════════════════════════════════════════
class AppColors {

  // ─── Primary ───
  static const Color primary     = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFFD1FAE5);

  // ─── Background ───
  static const Color bgColor   = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;

  // ─── Text ───
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecond  = Color(0xFF64748B);

  // ─── Border ───
  static const Color borderColor = Color(0xFFE2E8F0);

  // ─── Status ───
  static const Color errorColor   = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);

  // ─── Inactive ───
  static const Color inactive = Color(0xFF94A3B8);

  // ─── Gradient ───
  static const List<Color> primaryGradient = [
    Color(0xFF064E3B),
    Color(0xFF065F46),
    Color(0xFF047857),
  ];

  static const List<Color> buttonGradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  // ─── Category Colors ───
  static const Color food          = Color(0xFFFF9800);
  static const Color transport     = Color(0xFF2196F3);
  static const Color bills         = Color(0xFFF59E0B);
  static const Color health        = Color(0xFFE91E63);
  static const Color entertainment = Color(0xFF8B5CF6);
  static const Color shopping      = Color(0xFF00BCD4);
  static const Color education     = Color(0xFF3B82F6);
  static const Color other         = Color(0xFF607D8B);

  // ─── Category color map ───
  static const Map<String, Color> categoryColors = {
    'Food':          food,
    'Transport':     transport,
    'Bills':         bills,
    'Health':        health,
    'Entertainment': entertainment,
    'Shopping':      shopping,
    'Education':     education,
    'Other':         other,
  };
}