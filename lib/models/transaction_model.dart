class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final double modal; // added
  final String type; // 'income' or 'expense'
  final String category; // added
  final DateTime date;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    this.modal = 0.0,
    required this.type,
    this.category = '',
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'modal': modal,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      modal: (map['modal'] as num).toDouble(),
      type: map['type'],
      category: map['category'] ?? '',
      date: DateTime.parse(map['date']),
    );
  }
}
