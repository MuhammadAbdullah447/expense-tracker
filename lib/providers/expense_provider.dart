import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';

class ExpenseProvider extends ChangeNotifier {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth      _auth      = FirebaseAuth.instance;

  List<ExpenseModel> _expenses  = [];
  double             _budget    = 50000;
  bool               _isLoading = true;  // ← default true, taake MainScreen shuru se hi spinner dikhaye

  // ─── Notification callbacks ───
  void Function(String title, double amount)?  onExpenseAdded;
  void Function(String title)?                 onExpenseDeleted;
  void Function(double budget)?                onBudgetUpdated;
  void Function(double spent, double budget)?  onCheckBudget;

  List<ExpenseModel> get expenses  => _expenses;
  double             get budget    => _budget;
  bool               get isLoading => _isLoading;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return user.uid;
  }

  double get totalSpent {
    double total = 0;
    for (var expense in _expenses) {
      total += expense.amount;
    }
    return total;
  }

  double get remaining => _budget - totalSpent;

  Map<String, double> get categoryTotals {
    final Map<String, double> totals = {};
    for (var expense in _expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  List<ExpenseModel> searchExpenses(String query) {
    if (query.trim().isEmpty) return _expenses;
    return _expenses.where((e) =>
    e.title.toLowerCase().contains(query.toLowerCase()) ||
        e.category.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      // ─── Auth state settle hone ka wait karo ───
      final user = _auth.currentUser ??
          await _auth.authStateChanges().first;

      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .orderBy('date', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));

      _expenses = snapshot.docs.map((doc) {
        final data = doc.data();
        return ExpenseModel(
          id:       doc.id,
          title:    data['title']    ?? 'Unknown',
          amount:   (data['amount']  ?? 0).toDouble(),
          category: data['category'] ?? 'Other',
          date:     data['date'] != null
              ? (data['date'] as Timestamp).toDate()
              : DateTime.now(),
          note:     data['note'] ?? '',
        );
      }).toList();

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (userDoc.exists &&
          userDoc.data()!.containsKey('budget')) {
        _budget = userDoc.data()!['budget'].toDouble();
      }

      onCheckBudget?.call(totalSpent, _budget);

    } catch (e) {
      print('Error loading expenses: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .add({
        'title':    expense.title,
        'amount':   expense.amount,
        'category': expense.category,
        'date':     Timestamp.fromDate(expense.date),
        'note':     expense.note,
      });

      final newExpense = ExpenseModel(
        id:       docRef.id,
        title:    expense.title,
        amount:   expense.amount,
        category: expense.category,
        date:     expense.date,
        note:     expense.note,
      );

      _expenses.insert(0, newExpense);
      notifyListeners();

      // ─── Fire notifications ───
      onExpenseAdded?.call(expense.title, expense.amount);
      onCheckBudget?.call(totalSpent, _budget);

    } catch (e) {
      print('Error adding expense: $e');
    }
  }

  Future<void> deleteExpense(ExpenseModel expense) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .doc(expense.id)
          .delete();

      _expenses.removeWhere((e) => e.id == expense.id);
      notifyListeners();

      // ─── Fire notification ───
      onExpenseDeleted?.call(expense.title);

    } catch (e) {
      print('Error deleting expense: $e');
    }
  }

  Future<void> updateExpense(ExpenseModel updated) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .doc(updated.id)
          .update({
        'title':    updated.title,
        'amount':   updated.amount,
        'category': updated.category,
        'date':     Timestamp.fromDate(updated.date),
        'note':     updated.note,
      });

      final index = _expenses.indexWhere((e) => e.id == updated.id);
      if (index != -1) {
        _expenses[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating expense: $e');
    }
  }

  Future<void> updateBudget(double newBudget) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .set({'budget': newBudget}, SetOptions(merge: true));

      _budget = newBudget;
      notifyListeners();

      // ─── Fire notifications ───
      onBudgetUpdated?.call(newBudget);
      onCheckBudget?.call(totalSpent, newBudget);

    } catch (e) {
      print('Error updating budget: $e');
    }
  }

  Future<void> restoreExpense(ExpenseModel expense) async {
    await addExpense(expense);
  }

  void clearData() {
    _expenses  = [];
    _budget    = 50000;
    _isLoading = true;  // ← agla login/signup pe phir loading state se shuru ho
    notifyListeners();
  }
}