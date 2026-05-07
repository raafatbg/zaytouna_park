class Facility {
  final int id;
  final int typeId;
  final String name;
  final int? capacity;
  final double? pricePerHour;
  final bool isAvailable;
  final DateTime createdAt;

  Facility({
    required this.id,
    required this.typeId,
    required this.name,
    this.capacity,
    this.pricePerHour,
    required this.isAvailable,
    required this.createdAt,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'],
      typeId: json['type_id'],
      name: json['name'],
      capacity: json['capacity'],
      pricePerHour: json['price_per_hour']?.toDouble(),
      isAvailable: json['is_available'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type_id': typeId,
      'name': name,
      'capacity': capacity,
      'price_per_hour': pricePerHour,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
