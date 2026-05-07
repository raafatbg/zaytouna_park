// lib/Features/Inventory/inventory_screen.dart
// Zaytouna POS - Inventory Screen (Connected to Supabase)

// ignore_for_file: deprecated_member_use, file_names, non_constant_identifier_names, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LIGHT THEME PALETTE
// ─────────────────────────────────────────────────────────────────────────────

class InventoryColors {
  InventoryColors._();

  static const bg = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0F2F5);
  static const surface3 = Color(0xFFE8EBF0);
  static const border = Color(0xFFE2E5EA);
  static const borderLight = Color(0xFFEDF0F4);

  static const text = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const textDim = Color(0xFFCBD5E1);

  static const green = Color(0xFF22C55E);
  static const greenLight = Color(0xFFDCFCE7);
  static const greenDim = Color(0x1A22C55E);

  static const red = Color(0xFFEF4444);
  static const redLight = Color(0xFFFEE2E2);
  static const redDim = Color(0x1FEF4444);

  static const blue = Color(0xFF3B82F6);
  static const blueLight = Color(0xFFDBEAFE);
  static const blueDim = Color(0x1A3B82F6);

  static const orange = Color(0xFFF97316);
  static const orangeLight = Color(0xFFFFEDD5);
  static const orangeDim = Color(0x1AF97316);

  static const yellow = Color(0xFFEAB308);
  static const yellowLight = Color(0xFFFEF9C3);
  static const yellowDim = Color(0x1AEAB308);

  static const purple = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFFEDE9FE);
  static const purpleDim = Color(0x1A8B5CF6);

  static const cyan = Color(0xFF06B6D4);
  static const cyanLight = Color(0xFFCFFAFE);
  static const cyanDim = Color(0x1A06B6D4);

  static const pink = Color(0xFFEC4899);
  static const pinkLight = Color(0xFFFCE7F3);
  static const pinkDim = Color(0x1FEC4899);
}

// ─────────────────────────────────────────────────────────────────────────────
//  FONTS
// ─────────────────────────────────────────────────────────────────────────────

class InventoryFonts {
  InventoryFonts._();

  static TextStyle display(
    double size, {
    FontWeight w = FontWeight.w700,
    Color? color,
  }) => GoogleFonts.dmSerifDisplay(
    fontSize: size,
    fontWeight: w,
    color: color ?? InventoryColors.text,
  );

  static TextStyle sans(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color ?? InventoryColors.text,
  );

  static TextStyle mono(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: w,
    color: color ?? InventoryColors.text,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum StockStatus { ok, low, critical, outOfStock }

class InventoryItem {
  final int id;
  final String name;
  final int categoryId;
  final String category;
  final String sku;
  final String? barcode;
  final int supplierId;
  final String supplier;
  final String unit;
  double stock;
  final double minStock;
  final double reorderQty;
  final double maxStock;
  final double costPrice;
  final double sellPrice;
  final Color color;
  final IconData icon;

  InventoryItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.category,
    required this.sku,
    this.barcode,
    required this.supplierId,
    required this.supplier,
    required this.unit,
    required this.stock,
    required this.minStock,
    required this.reorderQty,
    required this.maxStock,
    required this.costPrice,
    required this.sellPrice,
    required this.color,
    required this.icon,
  });

  StockStatus get status {
    if (stock <= 0) return StockStatus.outOfStock;
    if (stock <= minStock / 2) return StockStatus.critical;
    if (stock <= minStock) return StockStatus.low;
    return StockStatus.ok;
  }

  double get margin =>
      sellPrice > 0 ? ((sellPrice - costPrice) / sellPrice) * 100 : 0.0;
  double get stockValue => stock * costPrice;

  // Helper to neatly format numbers (e.g., 10 instead of 10.0 for whole numbers)
  String get formattedStock => stock == stock.truncateToDouble()
      ? stock.toInt().toString()
      : stock.toStringAsFixed(2);

  factory InventoryItem.fromSupabaseRow({
    required Map<String, dynamic> row,
    required String categoryName,
    required String supplierName,
  }) {
    final stockVal = (row['current_quantity'] as num?)?.toDouble() ?? 0.0;
    final minStockVal = (row['reorder_level'] as num?)?.toDouble() ?? 5.0;
    final reorderQtyVal = (row['reorder_quantity'] as num?)?.toDouble() ?? 20.0;
    final maxStockVal = stockVal > reorderQtyVal
        ? stockVal + 10.0
        : reorderQtyVal;

    final costPriceVal = (row['cost_per_unit'] as num?)?.toDouble() ?? 0.0;
    final sellPriceVal = (row['selling_price'] as num?)?.toDouble() ?? 0.0;

    final categoryColors = {
      'Oils': InventoryColors.blue,
      'Seafood': InventoryColors.cyan,
      'Bread': InventoryColors.yellow,
      'Dips': InventoryColors.orange,
      'Fruits': InventoryColors.green,
      'Meat': InventoryColors.red,
      'Salads': InventoryColors.green,
      'Beverages': InventoryColors.purple,
      'Herbs': InventoryColors.green,
      'Spirits': InventoryColors.cyan,
      'Dairy': InventoryColors.orange,
      'Supplies': InventoryColors.pink,
    };

    final categoryIcons = {
      'Oils': Icons.water_drop_rounded,
      'Seafood': Icons.set_meal_rounded,
      'Bread': Icons.bakery_dining_rounded,
      'Dips': Icons.soup_kitchen_rounded,
      'Fruits': Icons.eco_rounded,
      'Meat': Icons.restaurant_rounded,
      'Salads': Icons.grass_rounded,
      'Beverages': Icons.local_drink_rounded,
      'Herbs': Icons.grass_rounded,
      'Spirits': Icons.wine_bar_rounded,
      'Dairy': Icons.egg_alt_rounded,
      'Supplies': Icons.inventory_2_rounded,
    };

    return InventoryItem(
      id: int.tryParse(row['id']?.toString() ?? '') ?? 0,
      name: row['name'] ?? 'Unknown',
      categoryId: int.tryParse(row['category_id']?.toString() ?? '') ?? 0,
      category: categoryName,
      sku: 'INV-${row['id'] ?? 'N/A'}',
      barcode: row['barcode']?.toString(),
      supplierId: int.tryParse(row['supplier_id']?.toString() ?? '') ?? 0,
      supplier: supplierName,
      unit: row['unit'] ?? 'pcs',
      stock: stockVal,
      minStock: minStockVal,
      reorderQty: reorderQtyVal,
      maxStock: maxStockVal,
      costPrice: costPriceVal,
      sellPrice: sellPriceVal,
      color: categoryColors[categoryName] ?? InventoryColors.blue,
      icon: categoryIcons[categoryName] ?? Icons.inventory_2_rounded,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  COLUMN WIDTHS
// ─────────────────────────────────────────────────────────────────────────────

class ColumnWidths {
  final double icon,
      name,
      sku,
      category,
      supplier,
      stock,
      price,
      margin,
      status,
      actions,
      padH;

  const ColumnWidths({
    required this.icon,
    required this.name,
    required this.sku,
    required this.category,
    required this.supplier,
    required this.stock,
    required this.price,
    required this.margin,
    required this.status,
    required this.actions,
    required this.padH,
  });

  factory ColumnWidths.fromWidth(double screenWidth) {
    if (screenWidth < 600) {
      return const ColumnWidths(
        icon: 44,
        name: 130,
        sku: 85,
        category: 90,
        supplier: 90,
        stock: 85,
        price: 95,
        margin: 65,
        status: 100,
        actions: 75,
        padH: 14,
      );
    } else if (screenWidth < 900) {
      return const ColumnWidths(
        icon: 48,
        name: 150,
        sku: 90,
        category: 100,
        supplier: 110,
        stock: 90,
        price: 100,
        margin: 70,
        status: 105,
        actions: 80,
        padH: 16,
      );
    } else {
      return const ColumnWidths(
        icon: 52,
        name: 180,
        sku: 100,
        category: 110,
        supplier: 130,
        stock: 100,
        price: 110,
        margin: 75,
        status: 110,
        actions: 85,
        padH: 18,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final SupabaseClient _supabase;

  Color get bg => InventoryColors.bg;
  Color get surface => InventoryColors.surface;
  Color get surface2 => InventoryColors.surface2;
  Color get surface3 => InventoryColors.surface3;
  Color get border => InventoryColors.border;
  Color get textClr => InventoryColors.text;
  Color get textMuted => InventoryColors.textSecondary;
  Color get textDim => InventoryColors.textMuted;

  String _searchQuery = '';
  StockStatus? _filterStatus;
  String _sortBy = 'name';
  bool _sortAsc = true;
  final _searchCtrl = TextEditingController();

  List<InventoryItem> _items = [];
  List<InventoryItem> _cachedFiltered = [];

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _suppliers = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _loadInventory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final categoriesData = await _supabase
          .from('inventory_categories')
          .select('id, name');
      final suppliersData = await _supabase
          .from('suppliers')
          .select('id, name');

      // Updated query to match new schema
      final inventoryRows = await _supabase
          .from('inventory_items')
          .select(
            'id, name, unit, current_quantity, reorder_level, reorder_quantity, cost_per_unit, selling_price, barcode, category_id, supplier_id',
          );

      _categories = List<Map<String, dynamic>>.from(categoriesData);
      _suppliers = List<Map<String, dynamic>>.from(suppliersData);

      final categoryNames = <int, String>{};
      for (var cat in categoriesData) {
        final id = int.tryParse(cat['id']?.toString() ?? '') ?? 0;
        categoryNames[id] = cat['name'] ?? 'Uncategorized';
      }

      final supplierNames = <int, String>{};
      for (var sup in suppliersData) {
        final id = int.tryParse(sup['id']?.toString() ?? '') ?? 0;
        supplierNames[id] = sup['name'] ?? 'Unknown';
      }

      final items = <InventoryItem>[];
      for (var row in inventoryRows) {
        items.add(
          InventoryItem.fromSupabaseRow(
            row: row,
            categoryName:
                categoryNames[int.tryParse(
                      row['category_id']?.toString() ?? '',
                    ) ??
                    0] ??
                'Uncategorized',
            supplierName:
                supplierNames[int.tryParse(
                      row['supplier_id']?.toString() ?? '',
                    ) ??
                    0] ??
                'Unknown',
          ),
        );
      }

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
          _recalculateFiltered();
        });
      }
    } catch (e) {
      print('Error loading inventory: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load inventory: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _recalculateFiltered() {
    var list = List<InventoryItem>.from(_items);

    if (_filterStatus != null) {
      list = list.where((i) => i.status == _filterStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (i) =>
                i.name.toLowerCase().contains(q) ||
                i.sku.toLowerCase().contains(q) ||
                i.category.toLowerCase().contains(q) ||
                (i.barcode != null && i.barcode!.toLowerCase().contains(q)),
          )
          .toList();
    }

    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'stock':
          cmp = a.stock.compareTo(b.stock);
          break;
        case 'value':
          cmp = a.stockValue.compareTo(b.stockValue);
          break;
        case 'margin':
          cmp = a.margin.compareTo(b.margin);
          break;
        default:
          cmp = a.name.compareTo(b.name);
      }
      return _sortAsc ? cmp : -cmp;
    });

    _cachedFiltered = list;
  }

  void _updateFilters({
    String? search,
    StockStatus? status,
    String? sortBy,
    bool? sortAsc,
  }) {
    bool changed = false;

    if (search != null && search != _searchQuery) {
      _searchQuery = search;
      changed = true;
    }
    if (status != _filterStatus) {
      _filterStatus = status;
      changed = true;
    }
    if (sortBy != null && sortBy != _sortBy) {
      _sortBy = sortBy;
      changed = true;
    }
    if (sortAsc != null && sortAsc != _sortAsc) {
      _sortAsc = sortAsc;
      changed = true;
    }

    if (changed) setState(() => _recalculateFiltered());
  }

  int get _totalItems => _items.length;
  int get _lowCount => _items
      .where(
        (i) => i.status == StockStatus.low || i.status == StockStatus.critical,
      )
      .length;
  int get _outCount =>
      _items.where((i) => i.status == StockStatus.outOfStock).length;
  double get _totalValue => _items.fold(0, (s, i) => s + i.stockValue);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  InventoryColors.green,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Loading inventory...',
                style: InventoryFonts.sans(14.sp, color: textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48.sp,
                color: InventoryColors.red,
              ),
              SizedBox(height: 16.h),
              Text(
                'Error',
                style: InventoryFonts.display(20.sp, w: FontWeight.w800),
              ),
              SizedBox(height: 8.h),
              Text(
                _errorMessage!,
                style: InventoryFonts.sans(13.sp, color: textMuted),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: _loadInventory,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: InventoryColors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final widths = ColumnWidths.fromWidth(constraints.maxWidth);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                searchCtrl: _searchCtrl,
                searchQuery: _searchQuery,
                onSearchChanged: (v) => _updateFilters(search: v),
                onAddPressed: _showAddDialog,
                onRefresh: _loadInventory,
                constraints: constraints,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryCards(
                        totalItems: _totalItems,
                        totalValue: _totalValue,
                        lowCount: _lowCount,
                        outCount: _outCount,
                        constraints: constraints,
                      ),
                      SizedBox(height: 20.h),
                      _TableCard(
                        items: _cachedFiltered,
                        filterStatus: _filterStatus,
                        sortBy: _sortBy,
                        sortAsc: _sortAsc,
                        onFilterChanged: (s) => _updateFilters(status: s),
                        onSortChanged: (by, asc) =>
                            _updateFilters(sortBy: by, sortAsc: asc),
                        onEditItem: _showEditDialog,
                        onRestockItem: _showRestockDialog,
                        constraints: constraints,
                        widths: widths,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── DIALOGS ──────────────────────────────────────────────────────────────────

  void _showAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddItemDialog(
        categories: _categories,
        suppliers: _suppliers,
        onSuccess: () {
          _showToast('Item added successfully!', InventoryColors.green);
          _loadInventory();
        },
        onError: (error) =>
            _showToast('Failed to add item: $error', InventoryColors.red),
      ),
    );
  }

  void _showEditDialog(InventoryItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditItemDialog(
        item: item,
        categories: _categories,
        suppliers: _suppliers,
        onSuccess: () {
          _showToast('Item updated successfully!', InventoryColors.green);
          _loadInventory();
        },
        onError: (error) =>
            _showToast('Failed to update item: $error', InventoryColors.red),
      ),
    );
  }

  void _showRestockDialog(InventoryItem item) {
    double qty = 1.0;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Restock Item',
                style: InventoryFonts.display(16.sp, w: FontWeight.w800),
              ),
              SizedBox(height: 4.h),
              Text(
                item.name,
                style: InventoryFonts.sans(12.sp, color: textMuted),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Current stock: ',
                    style: InventoryFonts.sans(12.sp, color: textMuted),
                  ),
                  Text(
                    '${item.formattedStock} ${item.unit}',
                    style: InventoryFonts.mono(
                      13.sp,
                      color: _statusColor(item.status),
                      w: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Text(
                    'Add quantity:',
                    style: InventoryFonts.sans(12.sp, color: textMuted),
                  ),
                  const Spacer(),
                  _qtyButton(Icons.remove_rounded, () {
                    if (qty > 1) set(() => qty--);
                  }),
                  SizedBox(width: 16.w),
                  Text(
                    qty.toStringAsFixed(0),
                    style: InventoryFonts.display(
                      24.sp,
                      w: FontWeight.w800,
                      color: InventoryColors.green,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  _qtyButton(Icons.add_rounded, () => set(() => qty++)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: InventoryFonts.sans(12.sp, color: textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: InventoryColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _supabase
                      .from('inventory_items')
                      .update({'current_quantity': item.stock + qty})
                      .eq('id', item.id);
                  if (mounted) {
                    _showToast('Restocked +$qty', InventoryColors.green);
                    _loadInventory();
                  }
                } catch (e) {
                  if (mounted) {
                    _showToast('Failed to restock: $e', InventoryColors.red);
                  }
                }
              },
              child: Text(
                'Confirm',
                style: InventoryFonts.sans(
                  12.sp,
                  w: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: border),
      ),
      child: Icon(icon, size: 18.sp, color: textMuted),
    ),
  );

  void _showToast(String msg, Color color) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.w),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18.sp),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                msg,
                style: InventoryFonts.sans(
                  13.sp,
                  w: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(StockStatus s) {
    switch (s) {
      case StockStatus.ok:
        return InventoryColors.green;
      case StockStatus.low:
        return InventoryColors.orange;
      case StockStatus.critical:
        return InventoryColors.red;
      case StockStatus.outOfStock:
        return InventoryColors.textMuted;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback onAddPressed;
  final VoidCallback onRefresh;
  final BoxConstraints constraints;

  const _TopBar({
    required this.searchCtrl,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onAddPressed,
    required this.onRefresh,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = constraints.maxWidth < 800;
    final isVeryNarrow = constraints.maxWidth < 500;

    return Container(
      height: 68.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: InventoryColors.surface,
        border: Border(
          bottom: BorderSide(color: InventoryColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: InventoryColors.green,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 20.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12.w),
          if (!isVeryNarrow)
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INVENTORY',
                    style: InventoryFonts.sans(
                      8.sp,
                      w: FontWeight.w700,
                      color: InventoryColors.green,
                    ),
                  ),
                  Text(
                    'Stock Management',
                    style: InventoryFonts.display(16.sp, w: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          const Spacer(),
          if (!isNarrow) ...[
            _SearchBox(
              ctrl: searchCtrl,
              searchQuery: searchQuery,
              onChanged: onSearchChanged,
            ),
            SizedBox(width: 12.w),
          ],
          _AddButton(onPressed: onAddPressed),
          SizedBox(width: 10.w),
          _RefreshButton(onPressed: onRefresh),
          SizedBox(width: 10.w),
          CircleAvatar(
            radius: 18.r,
            backgroundColor: InventoryColors.blueLight,
            child: Text(
              'I',
              style: TextStyle(
                color: InventoryColors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _RefreshButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: InventoryColors.surface2,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: InventoryColors.border),
        ),
        child: Icon(
          Icons.refresh_rounded,
          size: 18.sp,
          color: InventoryColors.blue,
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController ctrl;
  final String searchQuery;
  final Function(String) onChanged;

  const _SearchBox({
    required this.ctrl,
    required this.searchQuery,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220.w,
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: InventoryColors.surface2,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: InventoryColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 18.sp,
            color: InventoryColors.textSecondary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: ctrl,
              style: InventoryFonts.sans(12.sp),
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search items, SKU...',
                hintStyle: InventoryFonts.sans(
                  11.sp,
                  color: InventoryColors.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              ),
              cursorColor: InventoryColors.green,
            ),
          ),
          if (searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                ctrl.clear();
                onChanged('');
              },
              child: Icon(
                Icons.close_rounded,
                size: 16.sp,
                color: InventoryColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: InventoryColors.green,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: InventoryColors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 18.sp, color: Colors.white),
            SizedBox(width: 6.w),
            Text(
              'Add Item',
              style: InventoryFonts.sans(
                12.sp,
                w: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final int totalItems;
  final double totalValue;
  final int lowCount;
  final int outCount;
  final BoxConstraints constraints;

  const _SummaryCards({
    required this.totalItems,
    required this.totalValue,
    required this.lowCount,
    required this.outCount,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total Items',
            value: '$totalItems',
            icon: Icons.inventory_2_outlined,
            color: InventoryColors.blue,
            colorLight: InventoryColors.blueLight,
            sub: 'In catalog',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _SummaryCard(
            label: 'Stock Value',
            value: '\$${totalValue.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet_outlined,
            color: InventoryColors.green,
            colorLight: InventoryColors.greenLight,
            sub: 'At cost',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _SummaryCard(
            label: 'Low Stock',
            value: '$lowCount items',
            icon: Icons.warning_amber_rounded,
            color: InventoryColors.orange,
            colorLight: InventoryColors.orangeLight,
            sub: 'Need restock',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _SummaryCard(
            label: 'Out of Stock',
            value: '$outCount items',
            icon: Icons.remove_shopping_cart_outlined,
            color: InventoryColors.red,
            colorLight: InventoryColors.redLight,
            sub: 'Urgent',
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color, colorLight;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.colorLight,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: InventoryColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: InventoryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: colorLight,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 20.sp, color: color),
          ),
          SizedBox(height: 12.h),
          Text(
            label,
            style: InventoryFonts.sans(
              12.sp,
              color: InventoryColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: InventoryFonts.display(22.sp, w: FontWeight.w800),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            sub,
            style: InventoryFonts.mono(
              11.sp,
              color: InventoryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final List<InventoryItem> items;
  final StockStatus? filterStatus;
  final String sortBy;
  final bool sortAsc;
  final Function(StockStatus?) onFilterChanged;
  final Function(String, bool) onSortChanged;
  final Function(InventoryItem) onEditItem;
  final Function(InventoryItem) onRestockItem;
  final BoxConstraints constraints;
  final ColumnWidths widths;

  const _TableCard({
    required this.items,
    required this.filterStatus,
    required this.sortBy,
    required this.sortAsc,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onEditItem,
    required this.onRestockItem,
    required this.constraints,
    required this.widths,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: EdgeInsets.all(48.w),
        decoration: BoxDecoration(
          color: InventoryColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: InventoryColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48.sp,
                color: InventoryColors.textMuted,
              ),
              SizedBox(height: 12.h),
              Text(
                'No items found',
                style: InventoryFonts.sans(
                  14.sp,
                  color: InventoryColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: InventoryColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: InventoryColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TableHeader(widths: widths),
            for (var item in items)
              _TableRow(
                item: item,
                widths: widths,
                onEdit: () => onEditItem(item),
                onRestock: () => onRestockItem(item),
              ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final ColumnWidths widths;
  const _TableHeader({required this.widths});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: InventoryColors.surface2,
        border: Border(bottom: BorderSide(color: InventoryColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(width: widths.icon.w),
          _HeaderCell(widths.name, 'Item'),
          _HeaderCell(widths.sku, 'SKU / Barcode'),
          _HeaderCell(widths.category, 'Category'),
          _HeaderCell(widths.supplier, 'Supplier'),
          _HeaderCell(widths.stock, 'Stock'),
          _HeaderCell(widths.status, 'Status'),
          _HeaderCell(widths.actions, 'Actions'),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final double width;
  final String title;
  const _HeaderCell(this.width, this.title);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.w,
      child: Text(
        title,
        style: InventoryFonts.sans(
          11.sp,
          color: InventoryColors.textMuted,
          w: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final InventoryItem item;
  final ColumnWidths widths;
  final VoidCallback onEdit;
  final VoidCallback onRestock;

  const _TableRow({
    required this.item,
    required this.widths,
    required this.onEdit,
    required this.onRestock,
  });

  Color _statusColor(StockStatus s) {
    switch (s) {
      case StockStatus.ok:
        return InventoryColors.green;
      case StockStatus.low:
        return InventoryColors.orange;
      case StockStatus.critical:
        return InventoryColors.red;
      case StockStatus.outOfStock:
        return InventoryColors.textMuted;
    }
  }

  String _statusLabel(StockStatus s) {
    switch (s) {
      case StockStatus.ok:
        return 'In Stock';
      case StockStatus.low:
        return 'Low Stock';
      case StockStatus.critical:
        return 'Critical';
      case StockStatus.outOfStock:
        return 'Out';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(item.status);
    final sl = _statusLabel(item.status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: widths.padH.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: InventoryColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: widths.icon.w,
            height: widths.icon.w,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(item.icon, size: 20.sp, color: item.color),
          ),
          SizedBox(width: 12.w),
          SizedBox(
            width: widths.name.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: InventoryFonts.sans(12.sp, w: FontWeight.w600),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.sku,
                  overflow: TextOverflow.ellipsis,
                  style: InventoryFonts.mono(
                    9.sp,
                    color: InventoryColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: widths.category.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    item.category,
                    overflow: TextOverflow.ellipsis,
                    style: InventoryFonts.mono(
                      9.5.sp,
                      color: item.color,
                      w: FontWeight.w500,
                    ),
                  ),
                ),
                if (item.barcode != null && item.barcode!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    item.barcode!,
                    style: InventoryFonts.mono(
                      8.sp,
                      color: InventoryColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: widths.supplier.w,
            child: Text(
              item.supplier,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: InventoryFonts.sans(
                11.sp,
                color: InventoryColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: widths.stock.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.formattedStock} ${item.unit}',
                  style: InventoryFonts.mono(
                    11.sp,
                    w: FontWeight.w600,
                    color: sc,
                  ),
                ),
                SizedBox(height: 4.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3.r),
                  child: LinearProgressIndicator(
                    value: (item.stock / item.maxStock).clamp(0.0, 1.0),
                    minHeight: 4.h,
                    backgroundColor: InventoryColors.surface3,
                    valueColor: AlwaysStoppedAnimation<Color>(sc),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: widths.price.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${item.costPrice.toStringAsFixed(2)}',
                  style: InventoryFonts.mono(
                    10.sp,
                    color: InventoryColors.textDim,
                  ),
                ),
                Text(
                  '\$${item.sellPrice.toStringAsFixed(2)}',
                  style: InventoryFonts.mono(12.sp, w: FontWeight.w600),
                ),
              ],
            ),
          ),
          SizedBox(
            width: widths.margin.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: InventoryColors.greenDim,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                '${item.margin.toStringAsFixed(1)}%',
                style: InventoryFonts.mono(
                  10.sp,
                  color: InventoryColors.green,
                  w: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(
            width: widths.status.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: sc.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: sc,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      sl,
                      overflow: TextOverflow.ellipsis,
                      style: InventoryFonts.mono(
                        10.sp,
                        color: sc,
                        w: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: widths.actions.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: Icons.edit_outlined,
                  color: InventoryColors.textSecondary,
                  onTap: onEdit,
                ),
                SizedBox(width: 6.w),
                _ActionButton(
                  icon: Icons.add_box_outlined,
                  color: InventoryColors.blue,
                  onTap: onRestock,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Icon(icon, size: 16.sp, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ADD ITEM FORM DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _AddItemDialog extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> suppliers;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const _AddItemDialog({
    required this.categories,
    required this.suppliers,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  bool _isSubmitting = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'pcs');
  final _stockCtrl = TextEditingController(text: '0');
  final _costCtrl = TextEditingController(text: '0.00');
  final _sellCtrl = TextEditingController(text: '0.00');
  final _reorderLevelCtrl = TextEditingController(text: '5');
  final _reorderQtyCtrl = TextEditingController(text: '20');

  // Dropdown states
  int? _selectedCategoryId;
  int? _selectedSupplierId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _unitCtrl.dispose();
    _stockCtrl.dispose();
    _costCtrl.dispose();
    _sellCtrl.dispose();
    _reorderLevelCtrl.dispose();
    _reorderQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      widget.onError('Please select a category');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final newItemData = {
        'name': _nameCtrl.text.trim(),
        'barcode': _barcodeCtrl.text.trim().isEmpty
            ? null
            : _barcodeCtrl.text.trim(),
        'category_id': _selectedCategoryId,
        'supplier_id': _selectedSupplierId,
        'unit': _unitCtrl.text.trim(),
        'current_quantity': double.parse(_stockCtrl.text),
        'cost_per_unit': double.parse(_costCtrl.text),
        'selling_price': double.parse(_sellCtrl.text),
        'reorder_level': double.parse(_reorderLevelCtrl.text),
        'reorder_quantity': double.parse(_reorderQtyCtrl.text),
      };

      await _supabase.from('inventory_items').insert(newItemData);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        widget.onSuccess();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      widget.onError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: InventoryColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        'Add New Item',
        style: InventoryFonts.display(18.sp, w: FontWeight.w800),
      ),
      content: SizedBox(
        width: 600.w, // Wide enough for tablet/desktop
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Item Name'),
                          _buildTextField(
                            ctrl: _nameCtrl,
                            hint: 'e.g., Premium Olive Oil',
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Barcode (Optional)'),
                          _buildTextField(
                            ctrl: _barcodeCtrl,
                            hint: 'Scan or type',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Category'),
                          _buildDropdown(
                            value: _selectedCategoryId,
                            items: widget.categories,
                            hint: 'Select Category',
                            onChanged: (val) => setState(
                              () => _selectedCategoryId = val as int?,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Supplier'),
                          _buildDropdown(
                            value: _selectedSupplierId,
                            items: widget.suppliers,
                            hint: 'Select Supplier',
                            onChanged: (val) => setState(
                              () => _selectedSupplierId = val as int?,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Unit (e.g., pcs, kg, L)'),
                          _buildTextField(ctrl: _unitCtrl, hint: 'pcs'),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Cost Price (\$)'),
                          _buildTextField(
                            ctrl: _costCtrl,
                            hint: '0.00',
                            isNumber: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Selling Price (\$)'),
                          _buildTextField(
                            ctrl: _sellCtrl,
                            hint: '0.00',
                            isNumber: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Initial Stock'),
                          _buildTextField(
                            ctrl: _stockCtrl,
                            hint: '0',
                            isNumber: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Low Alert At'),
                          _buildTextField(
                            ctrl: _reorderLevelCtrl,
                            hint: '5',
                            isNumber: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Restock Qty'),
                          _buildTextField(
                            ctrl: _reorderQtyCtrl,
                            hint: '20',
                            isNumber: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: InventoryFonts.sans(
              13.sp,
              color: InventoryColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: InventoryColors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            elevation: 0,
          ),
          onPressed: _isSubmitting ? null : _submitForm,
          child: _isSubmitting
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Add Item',
                  style: InventoryFonts.sans(
                    13.sp,
                    w: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, left: 2.w),
      child: Text(
        text,
        style: InventoryFonts.sans(
          11.sp,
          w: FontWeight.w600,
          color: InventoryColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController ctrl,
    required String hint,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : [],
      style: InventoryFonts.sans(13.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: InventoryFonts.sans(13.sp, color: InventoryColors.textDim),
        filled: true,
        fillColor: InventoryColors.surface2,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
        errorStyle: InventoryFonts.sans(10.sp, color: InventoryColors.red),
      ),
      validator:
          validator ?? (isNumber ? (v) => v!.isEmpty ? 'Req' : null : null),
    );
  }

  Widget _buildDropdown({
    required int? value,
    required List<Map<String, dynamic>> items,
    required String hint,
    required void Function(dynamic) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      dropdownColor: InventoryColors.surface,
      style: InventoryFonts.sans(13.sp, color: InventoryColors.text),
      decoration: InputDecoration(
        filled: true,
        fillColor: InventoryColors.surface2,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(
        hint,
        style: InventoryFonts.sans(13.sp, color: InventoryColors.textDim),
      ),
      items: items.map((item) {
        return DropdownMenuItem<int>(
          value: item['id'] as int,
          child: Text(item['name'].toString()),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EDIT ITEM FORM DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _EditItemDialog extends StatefulWidget {
  final InventoryItem item;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> suppliers;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const _EditItemDialog({
    required this.item,
    required this.categories,
    required this.suppliers,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  bool _isSubmitting = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _sellCtrl;
  late TextEditingController _reorderLevelCtrl;
  late TextEditingController _reorderQtyCtrl;

  int? _selectedCategoryId;
  int? _selectedSupplierId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _barcodeCtrl = TextEditingController(text: widget.item.barcode ?? '');
    _unitCtrl = TextEditingController(text: widget.item.unit);
    _stockCtrl = TextEditingController(text: widget.item.formattedStock);
    _costCtrl = TextEditingController(
      text: widget.item.costPrice.toStringAsFixed(2),
    );
    _sellCtrl = TextEditingController(
      text: widget.item.sellPrice.toStringAsFixed(2),
    );
    _reorderLevelCtrl = TextEditingController(
      text: widget.item.minStock.toStringAsFixed(0),
    );
    _reorderQtyCtrl = TextEditingController(
      text: widget.item.reorderQty.toStringAsFixed(0),
    );

    _selectedCategoryId = widget.item.categoryId != 0
        ? widget.item.categoryId
        : null;
    _selectedSupplierId = widget.item.supplierId != 0
        ? widget.item.supplierId
        : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _unitCtrl.dispose();
    _stockCtrl.dispose();
    _costCtrl.dispose();
    _sellCtrl.dispose();
    _reorderLevelCtrl.dispose();
    _reorderQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      widget.onError('Please select a category');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updatedItemData = {
        'name': _nameCtrl.text.trim(),
        'barcode': _barcodeCtrl.text.trim().isEmpty
            ? null
            : _barcodeCtrl.text.trim(),
        'category_id': _selectedCategoryId,
        'supplier_id': _selectedSupplierId,
        'unit': _unitCtrl.text.trim(),
        'current_quantity': double.parse(_stockCtrl.text),
        'cost_per_unit': double.parse(_costCtrl.text),
        'selling_price': double.parse(_sellCtrl.text),
        'reorder_level': double.parse(_reorderLevelCtrl.text),
        'reorder_quantity': double.parse(_reorderQtyCtrl.text),
      };

      await _supabase
          .from('inventory_items')
          .update(updatedItemData)
          .eq('id', widget.item.id);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        widget.onSuccess();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      widget.onError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: InventoryColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        'Edit Item',
        style: InventoryFonts.display(18.sp, w: FontWeight.w800),
      ),
      content: SizedBox(
        width: 600.w, // Wide enough for tablet/desktop
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Item Name'),
                          _buildTextField(
                            ctrl: _nameCtrl,
                            hint: 'e.g., Premium Olive Oil',
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Barcode (Optional)'),
                          _buildTextField(
                            ctrl: _barcodeCtrl,
                            hint: 'Scan or type',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Category'),
                          _buildDropdown(
                            value: _selectedCategoryId,
                            items: widget.categories,
                            hint: 'Select Category',
                            onChanged: (val) => setState(
                              () => _selectedCategoryId = val as int?,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Supplier'),
                          _buildDropdown(
                            value: _selectedSupplierId,
                            items: widget.suppliers,
                            hint: 'Select Supplier',
                            onChanged: (val) => setState(
                              () => _selectedSupplierId = val as int?,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Unit (e.g., pcs, kg, L)'),
                          _buildTextField(ctrl: _unitCtrl, hint: 'pcs'),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Cost Price (\$)'),
                          _buildTextField(
                            ctrl: _costCtrl,
                            hint: '0.00',
                            isNumber: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Selling Price (\$)'),
                          _buildTextField(
                            ctrl: _sellCtrl,
                            hint: '0.00',
                            isNumber: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Current Stock'),
                          _buildTextField(
                            ctrl: _stockCtrl,
                            hint: '0',
                            isNumber: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Low Alert At'),
                          _buildTextField(
                            ctrl: _reorderLevelCtrl,
                            hint: '5',
                            isNumber: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Restock Qty'),
                          _buildTextField(
                            ctrl: _reorderQtyCtrl,
                            hint: '20',
                            isNumber: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: InventoryFonts.sans(
              13.sp,
              color: InventoryColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: InventoryColors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            elevation: 0,
          ),
          onPressed: _isSubmitting ? null : _submitForm,
          child: _isSubmitting
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Save Changes',
                  style: InventoryFonts.sans(
                    13.sp,
                    w: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, left: 2.w),
      child: Text(
        text,
        style: InventoryFonts.sans(
          11.sp,
          w: FontWeight.w600,
          color: InventoryColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController ctrl,
    required String hint,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : [],
      style: InventoryFonts.sans(13.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: InventoryFonts.sans(13.sp, color: InventoryColors.textDim),
        filled: true,
        fillColor: InventoryColors.surface2,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
        errorStyle: InventoryFonts.sans(10.sp, color: InventoryColors.red),
      ),
      validator:
          validator ?? (isNumber ? (v) => v!.isEmpty ? 'Req' : null : null),
    );
  }

  Widget _buildDropdown({
    required int? value,
    required List<Map<String, dynamic>> items,
    required String hint,
    required void Function(dynamic) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      dropdownColor: InventoryColors.surface,
      style: InventoryFonts.sans(13.sp, color: InventoryColors.text),
      decoration: InputDecoration(
        filled: true,
        fillColor: InventoryColors.surface2,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(
        hint,
        style: InventoryFonts.sans(13.sp, color: InventoryColors.textDim),
      ),
      items: items.map((item) {
        return DropdownMenuItem<int>(
          value: item['id'] as int,
          child: Text(item['name'].toString()),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }
}
