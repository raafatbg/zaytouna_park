class OrderItem {
  final int id;
  final int orderId;
  final int menuItemId;
  final int? variantId;
  final int quantity;
  final double unitPrice;
  final double itemTotal;
  final String? specialInstructions;
  final DateTime createdAt;
  final String itemStatus;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.itemTotal,
    this.specialInstructions,
    required this.createdAt,
    required this.itemStatus,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      menuItemId: json['menu_item_id'],
      variantId: json['variant_id'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      itemTotal: (json['item_total'] ?? 0).toDouble(),
      specialInstructions: json['special_instructions'],
      createdAt: DateTime.parse(json['created_at']),
      itemStatus: json['item_status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'variant_id': variantId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'item_total': itemTotal,
      'special_instructions': specialInstructions,
      'created_at': createdAt.toIso8601String(),
      'item_status': itemStatus,
    };
  }
}
