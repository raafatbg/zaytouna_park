class Order {
  final int id;
  final String orderNumber;
  final int? customerId;
  final int orderTypeId;
  final int? facilityId;
  final double totalAmount;
  final double finalAmount;
  final String? status;
  final String paymentStatus;
  final int? createdById;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.orderNumber,
    this.customerId,
    required this.orderTypeId,
    this.facilityId,
    required this.totalAmount,
    required this.finalAmount,
    this.status,
    required this.paymentStatus,
    this.createdById,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      customerId: json['customer_id'],
      orderTypeId: json['order_type_id'],
      facilityId: json['facility_id'],
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      finalAmount: (json['final_amount'] ?? 0).toDouble(),
      status: json['status'],
      paymentStatus: json['payment_status'] ?? 'pending',
      createdById: json['created_by_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'order_type_id': orderTypeId,
      'facility_id': facilityId,
      'total_amount': totalAmount,
      'final_amount': finalAmount,
      'status': status,
      'payment_status': paymentStatus,
      'created_by_id': createdById,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
