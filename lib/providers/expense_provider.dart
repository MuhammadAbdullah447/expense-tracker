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
  bool               _isLoading = false;

  List<ExpenseModel> get expenses  => _expenses;
  double             get budget    => _budget;
  bool               get isLoading => _isLoading;

  String get _userId => _auth.currentUser!.uid;

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

  // ─── Firestore se expenses load karo ───
  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();

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
          .doc(_userId)
          .get();

      if (userDoc.exists &&
          userDoc.data()!.containsKey('budget')) {
        _budget = userDoc.data()!['budget'].toDouble();
      }

    } catch (e) {
      print('Error loading expenses: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Naya expense add karo ───
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
    } catch (e) {
      print('Error adding expense: $e');
    }
  }

  // ─── Expense delete karo ───
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
    } catch (e) {
      print('Error deleting expense: $e');
    }
  }

  // ─── Expense update karo ───
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

      final index =
      _expenses.indexWhere((e) => e.id == updated.id);
      if (index != -1) {
        _expenses[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating expense: $e');
    }
  }

  // ─── Budget update karo ───
  Future<void> updateBudget(double newBudget) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .set({'budget': newBudget}, SetOptions(merge: true));

      _budget = newBudget;
      notifyListeners();
    } catch (e) {
      print('Error updating budget: $e');
    }
  }

  // ─── Restore expense ───
  Future<void> restoreExpense(ExpenseModel expense) async {
    await addExpense(expense);
  }

  // ─── Logout par data clear karo ───
  void clearData() {
    _expenses  = [];
    _budget    = 50000;
    notifyListeners();
  }
}