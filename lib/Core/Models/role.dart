class Role {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  Role({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
