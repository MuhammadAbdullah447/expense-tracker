// ═══════════════════════════════════════════════
// Expense Model — OOP Class
// Har expense ka data yahan store hoga
// ═══════════════════════════════════════════════
class ExpenseModel {

  // Private instance variables — Encapsulation
  String _id;        // ← Naya — Firestore document ID
  String _title;
  double _amount;
  String _category;
  DateTime _date;
  String _note;

  // Constructor — required fields se object banao
  ExpenseModel({
    String id = '',  // ← Naya
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    String note = '',
  })  : _id = id,
        _title = title,
        _amount = amount,
        _category = category,
        _date = date,
        _note = note;

  // Getters — private variables ko bahar access dena
  String get id => _id;          // ← Naya
  String get title => _title;
  double get amount => _amount;
  String get category => _category;
  DateTime get date => _date;
  String get note => _note;

  // Setters — private variables ko update karna
  set id(String value) => _id = value;
  set title(String value) => _title = value;
  set amount(double value) => _amount = value;
  set category(String value) => _category = value;
  set date(DateTime value) => _date = value;
  set note(String value) => _note = value;

  // Category ke hisaab se emoji return karta hai
  String get categoryIcon {
    final Map<String, String> icons = {
      'Food':          '🍔',
      'Transport':     '🚗',
      'Bills':         '📄',
      'Health':        '💊',
      'Entertainment': '🎮',
      'Shopping':      '🛍️',
      'Education':     '📚',
      'Other':         '💰',
    };
    return icons[_category] ?? '💰';
  }

  // Date ko readable format mein return karta hai
  String get formattedDate {
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[_date.month - 1]} ${_date.day}, ${_date.year}';
  }
}