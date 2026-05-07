class Customer {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final int loyaltyPoints;
  final double totalSpent;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.loyaltyPoints,
    required this.totalSpent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      loyaltyPoints: json['loyalty_points'] ?? 0,
      totalSpent: (json['total_spent'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'loyalty_points': loyaltyPoints,
      'total_spent': totalSpent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
