class Delivery {
  final int id;
  final int orderId;
  final int addressId;
  final int? driverId;
  final String? status;
  final double? deliveryFee;
  final DateTime createdAt;

  Delivery({
    required this.id,
    required this.orderId,
    required this.addressId,
    this.driverId,
    this.status,
    this.deliveryFee,
    required this.createdAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'],
      orderId: json['order_id'],
      addressId: json['address_id'],
      driverId: json['driver_id'],
      status: json['status'],
      deliveryFee: json['delivery_fee']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'address_id': addressId,
      'driver_id': driverId,
      'status': status,
      'delivery_fee': deliveryFee,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
