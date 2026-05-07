class Expense {
  final int id;
  final int categoryId;
  final double amount;
  final DateTime expenseDate;
  final int recordedById;
  final String? notes;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.expenseDate,
    required this.recordedById,
    this.notes,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      categoryId: json['category_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      expenseDate: DateTime.parse(json['expense_date']),
      recordedById: json['recorded_by_id'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().split('T')[0], // Date only
      'recorded_by_id': recordedById,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
