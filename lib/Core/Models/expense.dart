class Expense {
  final int id;
  final int categoryId;
  final double amount;
  final String description;
  final String? recordedById;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.recordedById,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      categoryId: json['category_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description']?.toString() ?? '',
      recordedById: json['recorded_by_id']?.toString(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'recorded_by_id': recordedById,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
