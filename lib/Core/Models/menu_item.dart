class MenuItem {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final bool requiresPreparation;
  final int? preparationTimeMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.requiresPreparation,
    this.preparationTimeMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'],
      isAvailable: json['is_available'] ?? true,
      requiresPreparation: json['requires_preparation'] ?? false,
      preparationTimeMinutes: json['preparation_time_minutes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'requires_preparation': requiresPreparation,
      'preparation_time_minutes': preparationTimeMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
