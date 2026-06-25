import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  // ─── Add a notification ───
  void addNotification({
    required String           title,
    required String           message,
    required NotificationType type,
  }) {
    final notification = NotificationModel(
      id:      DateTime.now().millisecondsSinceEpoch.toString(),
      title:   title,
      message: message,
      type:    type,
      time:    DateTime.now(),
    );

    // Avoid duplicate alerts of same title within 1 minute
    final isDuplicate = _notifications.any((n) =>
    n.title == title &&
        DateTime.now().difference(n.time).inMinutes < 1);

    if (!isDuplicate) {
      _notifications.insert(0, notification);
      notifyListeners();
    }
  }

  // ─── Check budget and auto-generate alerts ───
  void checkBudgetAlerts({
    required double spent,
    required double budget,
  }) {
    if (budget <= 0) return;
    final percentage = spent / budget;

    if (percentage >= 1.0) {
      addNotification(
        title:   '🚨 Over Budget!',
        message: 'You have exceeded your monthly budget of Rs. ${_fmt(budget)}. Spent: Rs. ${_fmt(spent)}.',
        type:    NotificationType.overBudget,
      );
    } else if (percentage >= 0.9) {
      addNotification(
        title:   '⚠️ 90% Budget Used',
        message: 'You\'ve used 90% of your Rs. ${_fmt(budget)} budget. Only Rs. ${_fmt(budget - spent)} left.',
        type:    NotificationType.warning,
      );
    } else if (percentage >= 0.8) {
      addNotification(
        title:   '⚠️ 80% Budget Used',
        message: 'You\'ve used 80% of your Rs. ${_fmt(budget)} budget. Remaining: Rs. ${_fmt(budget - spent)}.',
        type:    NotificationType.warning,
      );
    }
  }

  // ─── Expense added notification ───
  void onExpenseAdded(String title, double amount) {
    addNotification(
      title:   '✅ Expense Added',
      message: '"$title" of Rs. ${_fmt(amount)} was added successfully.',
      type:    NotificationType.success,
    );
  }

  // ─── Expense deleted notification ───
  void onExpenseDeleted(String title) {
    addNotification(
      title:   '🗑️ Expense Deleted',
      message: '"$title" has been removed from your expenses.',
      type:    NotificationType.info,
    );
  }

  // ─── Budget updated notification ───
  void onBudgetUpdated(double newBudget) {
    addNotification(
      title:   '💰 Budget Updated',
      message: 'Your monthly budget has been set to Rs. ${_fmt(newBudget)}.',
      type:    NotificationType.info,
    );
  }

  // ─── Mark single as read ───
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  // ─── Mark all as read ───
  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  // ─── Clear all ───
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  String _fmt(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}