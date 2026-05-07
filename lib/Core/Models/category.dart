class Category {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final int? sortOrder;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.sortOrder,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
