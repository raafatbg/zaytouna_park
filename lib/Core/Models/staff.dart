class Staff {
  final String id; // UUID
  final String name;
  final String? email;
  final String? phone;
  final int roleId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Staff({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.roleId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      roleId: json['role_id'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role_id': roleId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
