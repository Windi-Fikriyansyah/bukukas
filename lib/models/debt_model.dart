class DebtModel {
  final int? id;
  final String name;
  final double amount;
  final String type; // 'piutang' (pelanggan) or 'supplier' (utang kita)
  final String note;
  final DateTime date;
  final DateTime? dueDate;
  final bool isPaid;
  final DateTime? paidDate;
  final String? productName;
  final double? productModal;

  DebtModel({
    this.id,
    required this.name,
    required this.amount,
    required this.type,
    this.note = '',
    required this.date,
    this.dueDate,
    this.isPaid = false,
    this.paidDate,
    this.productName,
    this.productModal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'type': type,
      'note': note,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isPaid': isPaid ? 1 : 0,
      'paidDate': paidDate?.toIso8601String(),
      'productName': productName,
      'productModal': productModal,
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'],
      name: map['name'],
      amount: (map['amount'] as num).toDouble(),
      type: map['type'],
      note: map['note'] ?? '',
      date: DateTime.parse(map['date']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isPaid: map['isPaid'] == 1,
      paidDate: map['paidDate'] != null ? DateTime.parse(map['paidDate']) : null,
      productName: map['productName'],
      productModal: map['productModal'] != null ? (map['productModal'] as num).toDouble() : null,
    );
  }
}
