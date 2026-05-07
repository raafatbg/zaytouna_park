class Staff {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final int roleId;
  final String? passwordHash;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Staff({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.roleId,
    this.passwordHash,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      roleId: json['role_id'],
      passwordHash: json['password_hash'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role_id': roleId,
      'password_hash': passwordHash,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
