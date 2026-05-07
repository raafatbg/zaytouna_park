class InventoryItem {
  final int id;
  final int categoryId;
  final String categoryName; // Added to show "Meat", "Beverages", etc.
  final String name;
  final String? unit;
  final double currentQuantity;
  final double reorderLevel;
  final double reorderQuantity;
  final double costPerUnit;
  final String supplierName; // Added for UI
  final DateTime lastUpdated;
  final DateTime createdAt;

  InventoryItem({
    required this.id,
    required this.categoryId,
    this.categoryName = 'General',
    required this.name,
    this.unit,
    required this.currentQuantity,
    this.reorderLevel = 0,
    this.reorderQuantity = 0,
    this.costPerUnit = 0,
    this.supplierName = 'N/A',
    required this.lastUpdated,
    required this.createdAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    // Handle the nested join data from Supabase select
    final categoryData = json['inventory_categories'] as Map<String, dynamic>?;
    final supplierData = json['suppliers'] as Map<String, dynamic>?;

    return InventoryItem(
      id: json['id'],
      categoryId: json['category_id'],
      categoryName: categoryData?['name'] ?? 'Uncategorized',
      name: json['name'] ?? 'Unknown Item',
      unit: json['unit'],
      currentQuantity: (json['current_quantity'] ?? 0).toDouble(),
      reorderLevel: (json['reorder_level'] ?? 0).toDouble(),
      reorderQuantity: (json['reorder_quantity'] ?? 0).toDouble(),
      costPerUnit: (json['cost_per_unit'] ?? 0).toDouble(),
      supplierName: supplierData?['name'] ?? 'No Supplier',
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
