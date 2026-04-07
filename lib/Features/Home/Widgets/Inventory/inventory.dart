// lib/Features/Inventory/inventory_screen.dart
// Zaytouna POS - Inventory Screen (Light Theme Only)

// ignore_for_file: deprecated_member_use, file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LIGHT THEME PALETTE
// ─────────────────────────────────────────────────────────────────────────────

class InventoryColors {
  InventoryColors._();

  // Base Colors
  static const bg = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0F2F5);
  static const surface3 = Color(0xFFE8EBF0);
  static const border = Color(0xFFE2E5EA);
  static const borderLight = Color(0xFFEDF0F4);

  // Text Colors
  static const text = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const textDim = Color(0xFFCBD5E1);

  // Accent Colors
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
  final String id, name, category, sku, supplier, unit;
  int stock;
  final int minStock, maxStock;
  final double costPrice, sellPrice;
  final Color color;
  final IconData icon;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.supplier,
    required this.unit,
    required this.stock,
    required this.minStock,
    required this.maxStock,
    required this.costPrice,
    required this.sellPrice,
    required this.color,
    required this.icon,
  });

  StockStatus get status {
    if (stock == 0) return StockStatus.outOfStock;
    if (stock <= minStock ~/ 2) return StockStatus.critical;
    if (stock <= minStock) return StockStatus.low;
    return StockStatus.ok;
  }

  double get margin => ((sellPrice - costPrice) / sellPrice) * 100;
  double get stockValue => stock * costPrice;
}

// ─────────────────────────────────────────────────────────────────────────────
//  COLUMN WIDTHS
// ─────────────────────────────────────────────────────────────────────────────

class ColumnWidths {
  final double icon,
      name,
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
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // Color shortcuts
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
  late List<InventoryItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _mockItems();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Restaurant inventory mock data
  List<InventoryItem> _mockItems() => [
    InventoryItem(
      id: '1',
      name: 'Olive Oil Extra Virgin',
      category: 'Oils',
      sku: 'ING-OIL-001',
      supplier: 'Mediterranean Foods',
      unit: 'Liter',
      stock: 24,
      minStock: 15,
      maxStock: 100,
      costPrice: 8.50,
      sellPrice: 15.00,
      color: InventoryColors.green,
      icon: Icons.water_drop_rounded,
    ),
    InventoryItem(
      id: '2',
      name: 'Fresh Salmon Fillet',
      category: 'Seafood',
      sku: 'SEA-SAL-500',
      supplier: 'Ocean Fresh Ltd',
      unit: 'Kg',
      stock: 5,
      minStock: 10,
      maxStock: 50,
      costPrice: 18.00,
      sellPrice: 32.00,
      color: InventoryColors.blue,
      icon: Icons.set_meal_rounded,
    ),
    InventoryItem(
      id: '3',
      name: 'Pita Bread (Pack 10)',
      category: 'Bread',
      sku: 'BRD-PIT-010',
      supplier: 'Bakery Express',
      unit: 'Pack',
      stock: 0,
      minStock: 20,
      maxStock: 100,
      costPrice: 2.50,
      sellPrice: 5.00,
      color: InventoryColors.yellow,
      icon: Icons.bakery_dining_rounded,
    ),
    InventoryItem(
      id: '4',
      name: 'Hummus Premium',
      category: 'Dips',
      sku: 'DIP-HUM-250',
      supplier: 'Mediterranean Foods',
      unit: 'Kg',
      stock: 12,
      minStock: 8,
      maxStock: 40,
      costPrice: 4.00,
      sellPrice: 8.50,
      color: InventoryColors.orange,
      icon: Icons.soup_kitchen_rounded,
    ),
    InventoryItem(
      id: '5',
      name: 'Fresh Lemons',
      category: 'Fruits',
      sku: 'FRT-LEM-001',
      supplier: 'Farm Fresh Co',
      unit: 'Kg',
      stock: 18,
      minStock: 10,
      maxStock: 60,
      costPrice: 1.80,
      sellPrice: 3.50,
      color: InventoryColors.yellow,
      icon: Icons.eco_rounded,
    ),
    InventoryItem(
      id: '6',
      name: 'Lamb Meat (Ground)',
      category: 'Meat',
      sku: 'MET-LAM-500',
      supplier: 'Premium Meats',
      unit: 'Kg',
      stock: 3,
      minStock: 8,
      maxStock: 40,
      costPrice: 12.00,
      sellPrice: 22.00,
      color: InventoryColors.red,
      icon: Icons.restaurant_rounded,
    ),
    InventoryItem(
      id: '7',
      name: 'Tabouleh Mix',
      category: 'Salads',
      sku: 'SAL-TAB-200',
      supplier: 'Garden Fresh',
      unit: 'Kg',
      stock: 8,
      minStock: 10,
      maxStock: 50,
      costPrice: 3.50,
      sellPrice: 7.00,
      color: InventoryColors.green,
      icon: Icons.grass_rounded,
    ),
    InventoryItem(
      id: '8',
      name: 'Cola (Crate 24)',
      category: 'Beverages',
      sku: 'BEV-COL-024',
      supplier: 'Beverage Distributors',
      unit: 'Crate',
      stock: 15,
      minStock: 10,
      maxStock: 80,
      costPrice: 9.60,
      sellPrice: 18.00,
      color: InventoryColors.purple,
      icon: Icons.local_drink_rounded,
    ),
    InventoryItem(
      id: '9',
      name: 'Fresh Mint Leaves',
      category: 'Herbs',
      sku: 'HRB-MIN-100',
      supplier: 'Garden Fresh',
      unit: 'Bunch',
      stock: 1,
      minStock: 5,
      maxStock: 30,
      costPrice: 1.00,
      sellPrice: 2.50,
      color: InventoryColors.green,
      icon: Icons.grass_rounded,
    ),
    InventoryItem(
      id: '10',
      name: 'Arak (1 Liter)',
      category: 'Spirits',
      sku: 'SPI-ARK-1L',
      supplier: 'Premium Spirits Co',
      unit: 'Bottle',
      stock: 22,
      minStock: 12,
      maxStock: 60,
      costPrice: 15.00,
      sellPrice: 28.00,
      color: InventoryColors.cyan,
      icon: Icons.wine_bar_rounded,
    ),
    InventoryItem(
      id: '11',
      name: 'Feta Cheese (Block)',
      category: 'Dairy',
      sku: 'DRY-FET-500',
      supplier: 'Dairy Farm',
      unit: 'Kg',
      stock: 6,
      minStock: 8,
      maxStock: 40,
      costPrice: 8.00,
      sellPrice: 15.00,
      color: InventoryColors.orange,
      icon: Icons.egg_alt_rounded,
    ),
    InventoryItem(
      id: '12',
      name: 'Tissue Box (Pack 50)',
      category: 'Supplies',
      sku: 'SUP-TIS-050',
      supplier: 'Office Supplies Inc',
      unit: 'Pack',
      stock: 45,
      minStock: 20,
      maxStock: 100,
      costPrice: 3.00,
      sellPrice: 6.00,
      color: InventoryColors.pink,
      icon: Icons.inventory_2_rounded,
    ),
  ];

  List<InventoryItem> get _filtered {
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
                i.supplier.toLowerCase().contains(q) ||
                i.category.toLowerCase().contains(q),
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
    return list;
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
    return Scaffold(
      backgroundColor: bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final widths = ColumnWidths.fromWidth(constraints.maxWidth);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(constraints),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summaryCards(constraints),
                      SizedBox(height: 20.h),
                      _tableCard(constraints, widths),
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

  // ── Top Bar ──────────────────────────────────────────────────────────────────

  Widget _topBar(BoxConstraints c) {
    final isNarrow = c.maxWidth < 700;
    return Container(
      height: 68.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo & Title
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: InventoryColors.green,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 22.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12.w),
          Column(
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
              ),
            ],
          ),
          const Spacer(),

          // Search Box
          if (!isNarrow) ...[_searchBox(), SizedBox(width: 12.w)],

          // Add Item Button
          _addButton(),
          SizedBox(width: 10.w),

          // Notification
          _iconButton(Icons.notifications_none_rounded),
          SizedBox(width: 8.w),

          // User Avatar
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: InventoryColors.blueLight,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Center(
              child: Text(
                'S',
                style: InventoryFonts.sans(
                  16.sp,
                  w: FontWeight.w700,
                  color: InventoryColors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() => Container(
    width: 220.w,
    height: 40.h,
    padding: EdgeInsets.symmetric(horizontal: 12.w),
    decoration: BoxDecoration(
      color: surface2,
      borderRadius: BorderRadius.circular(10.r),
      border: Border.all(color: border),
    ),
    child: Row(
      children: [
        Icon(Icons.search_rounded, size: 18.sp, color: textMuted),
        SizedBox(width: 8.w),
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            style: InventoryFonts.sans(12.sp),
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search items, SKU...',
              hintStyle: InventoryFonts.sans(11.sp, color: textDim),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10.h),
            ),
            cursorColor: InventoryColors.green,
          ),
        ),
        if (_searchQuery.isNotEmpty)
          GestureDetector(
            onTap: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
            },
            child: Icon(Icons.close_rounded, size: 16.sp, color: textMuted),
          ),
      ],
    ),
  );

  Widget _addButton() => GestureDetector(
    onTap: _showAddDialog,
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

  Widget _iconButton(IconData icon) => GestureDetector(
    child: Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: border),
      ),
      child: Icon(icon, size: 20.sp, color: textMuted),
    ),
  );

  // ── Summary Cards ─────────────────────────────────────────────────────────────

  Widget _summaryCards(BoxConstraints c) {
    final cards = [
      _SD(
        'Total Items',
        '$_totalItems',
        Icons.inventory_2_outlined,
        InventoryColors.blue,
        InventoryColors.blueLight,
        'In catalog',
      ),
      _SD(
        'Stock Value',
        '\$${_totalValue.toStringAsFixed(0)}',
        Icons.account_balance_wallet_outlined,
        InventoryColors.green,
        InventoryColors.greenLight,
        'At cost',
      ),
      _SD(
        'Low Stock',
        '$_lowCount items',
        Icons.warning_amber_rounded,
        InventoryColors.orange,
        InventoryColors.orangeLight,
        'Need restock',
      ),
      _SD(
        'Out of Stock',
        '$_outCount items',
        Icons.remove_shopping_cart_outlined,
        InventoryColors.red,
        InventoryColors.redLight,
        'Urgent',
      ),
    ];

    if (c.maxWidth >= 900) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(width: 16.w),
            Expanded(child: _summaryCard(cards[i])),
          ],
        ],
      );
    } else if (c.maxWidth >= 600) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _summaryCard(cards[0])),
              SizedBox(width: 12.w),
              Expanded(child: _summaryCard(cards[1])),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: _summaryCard(cards[2])),
              SizedBox(width: 12.w),
              Expanded(child: _summaryCard(cards[3])),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            _summaryCard(cards[i]),
            if (i < 3) SizedBox(height: 10.h),
          ],
        ],
      );
    }
  }

  Widget _summaryCard(_SD d) => Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: d.accentDim,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(d.icon, size: 20.sp, color: d.accent),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: d.accentDim,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                d.sub,
                style: InventoryFonts.mono(9.sp, color: d.accent),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            d.value,
            style: InventoryFonts.display(22.sp, w: FontWeight.w800),
          ),
        ),
        SizedBox(height: 2.h),
        Text(d.label, style: InventoryFonts.sans(11.sp, color: textMuted)),
      ],
    ),
  );

  // ── Table Card ────────────────────────────────────────────────────────────────

  Widget _tableCard(BoxConstraints c, ColumnWidths widths) => Container(
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tableToolbar(),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tableHeader(widths),
              ..._filtered.map((item) => _tableRow(item, widths)),
              if (_filtered.isEmpty) _emptyState(),
            ],
          ),
        ),
        _tableFooter(),
      ],
    ),
  );

  Widget _tableToolbar() => Container(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: border)),
    ),
    child: LayoutBuilder(
      builder: (_, tc) {
        if (tc.maxWidth >= 800) return _toolbarWide();
        if (tc.maxWidth >= 500) return _toolbarMedium();
        return _toolbarNarrow();
      },
    ),
  );

  Widget _toolbarWide() => Row(
    children: [
      Text('All Items', style: InventoryFonts.sans(13.sp, w: FontWeight.w700)),
      SizedBox(width: 10.w),
      _countChip(),
      const Spacer(),
      _filterChip('All', null, null),
      SizedBox(width: 8.w),
      _filterChip('In Stock', StockStatus.ok, InventoryColors.green),
      SizedBox(width: 8.w),
      _filterChip('Low', StockStatus.low, InventoryColors.orange),
      SizedBox(width: 8.w),
      _filterChip('Critical', StockStatus.critical, InventoryColors.red),
      SizedBox(width: 8.w),
      _filterChip('Out', StockStatus.outOfStock, InventoryColors.textMuted),
      SizedBox(width: 16.w),
      _sortDropdown(),
      SizedBox(width: 6.w),
      _sortDirectionButton(),
    ],
  );

  Widget _toolbarMedium() => Row(
    children: [
      Text('All Items', style: InventoryFonts.sans(12.sp, w: FontWeight.w700)),
      SizedBox(width: 8.w),
      _countChip(),
      const Spacer(),
      _sortDropdown(),
      SizedBox(width: 6.w),
      _sortDirectionButton(),
    ],
  );

  Widget _toolbarNarrow() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Text(
            'All Items',
            style: InventoryFonts.sans(12.sp, w: FontWeight.w700),
          ),
          SizedBox(width: 8.w),
          _countChip(),
          const Spacer(),
          _sortDropdown(),
          SizedBox(width: 6.w),
          _sortDirectionButton(),
        ],
      ),
      SizedBox(height: 10.h),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('All', null, null),
            SizedBox(width: 6.w),
            _filterChip('In', StockStatus.ok, InventoryColors.green),
            SizedBox(width: 6.w),
            _filterChip('Low', StockStatus.low, InventoryColors.orange),
            SizedBox(width: 6.w),
            _filterChip(
              'Out',
              StockStatus.outOfStock,
              InventoryColors.textMuted,
            ),
          ],
        ),
      ),
    ],
  );

  Widget _countChip() => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
    decoration: BoxDecoration(
      color: surface2,
      borderRadius: BorderRadius.circular(20.r),
    ),
    child: Text(
      '${_filtered.length} items',
      style: InventoryFonts.mono(10.sp, color: textMuted),
    ),
  );

  Widget _filterChip(String label, StockStatus? status, Color? color) {
    final active = _filterStatus == status;
    final chipColor = color ?? InventoryColors.green;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = active ? null : status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? chipColor.withOpacity(0.12) : surface2,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: active ? chipColor : border),
        ),
        child: Text(
          label,
          style: InventoryFonts.sans(
            10.sp,
            w: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? chipColor : textMuted,
          ),
        ),
      ),
    );
  }

  Widget _sortDropdown() => Container(
    height: 34.h,
    padding: EdgeInsets.symmetric(horizontal: 10.w),
    decoration: BoxDecoration(
      color: surface2,
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _sortBy,
        isDense: true,
        dropdownColor: surface,
        style: InventoryFonts.sans(11.sp, color: textMuted),
        icon: Icon(Icons.unfold_more_rounded, size: 18.sp, color: textDim),
        items: const [
          DropdownMenuItem(value: 'name', child: Text('Name')),
          DropdownMenuItem(value: 'stock', child: Text('Stock')),
          DropdownMenuItem(value: 'value', child: Text('Value')),
          DropdownMenuItem(value: 'margin', child: Text('Margin')),
        ],
        onChanged: (v) => setState(() {
          if (v == _sortBy) {
            _sortAsc = !_sortAsc;
          } else {
            _sortBy = v!;
            _sortAsc = true;
          }
        }),
      ),
    ),
  );

  Widget _sortDirectionButton() => GestureDetector(
    onTap: () => setState(() => _sortAsc = !_sortAsc),
    child: Container(
      width: 34.w,
      height: 34.w,
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: border),
      ),
      child: Icon(
        _sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
        size: 16.sp,
        color: textMuted,
      ),
    ),
  );

  // ── Table Header ─────────────────────────────────────────────────────────────

  Widget _tableHeader(ColumnWidths w) => Container(
    padding: EdgeInsets.symmetric(horizontal: w.padH.w, vertical: 10.h),
    decoration: BoxDecoration(
      color: surface2,
      border: Border(bottom: BorderSide(color: border)),
    ),
    child: Row(
      children: [
        SizedBox(width: w.icon.w),
        SizedBox(width: 12.w),
        _headerCell('ITEM / SKU', w.name),
        _headerCell('CATEGORY', w.category),
        _headerCell('SUPPLIER', w.supplier),
        _headerCell('STOCK', w.stock),
        _headerCell('COST / SELL', w.price),
        _headerCell('MARGIN', w.margin),
        _headerCell('STATUS', w.status),
        _headerCell('ACTIONS', w.actions),
      ],
    ),
  );

  Widget _headerCell(String text, double width) => SizedBox(
    width: width.w,
    child: Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: InventoryFonts.sans(9.sp, w: FontWeight.w600, color: textDim),
    ),
  );

  // ── Table Row ────────────────────────────────────────────────────────────────

  Widget _tableRow(InventoryItem item, ColumnWidths w) {
    final sc = _statusColor(item.status);
    final sb = _statusBg(item.status);
    final sl = _statusLabel(item.status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w.padH.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: w.icon.w,
            height: w.icon.w,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(item.icon, size: 20.sp, color: item.color),
          ),
          SizedBox(width: 12.w),
          SizedBox(
            width: w.name.w,
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
                  style: InventoryFonts.mono(9.sp, color: textDim),
                ),
              ],
            ),
          ),
          SizedBox(
            width: w.category.w,
            child: Container(
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
          ),
          SizedBox(
            width: w.supplier.w,
            child: Text(
              item.supplier,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: InventoryFonts.sans(11.sp, color: textMuted),
            ),
          ),
          SizedBox(
            width: w.stock.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.stock} ${item.unit}',
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
                    backgroundColor: surface3,
                    valueColor: AlwaysStoppedAnimation<Color>(sc),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: w.price.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${item.costPrice.toStringAsFixed(2)}',
                  style: InventoryFonts.mono(10.sp, color: textDim),
                ),
                Text(
                  '\$${item.sellPrice.toStringAsFixed(2)}',
                  style: InventoryFonts.mono(12.sp, w: FontWeight.w600),
                ),
              ],
            ),
          ),
          SizedBox(
            width: w.margin.w,
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
            width: w.status.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: sb,
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
          // Actions column with fixed width
          SizedBox(
            width: w.actions.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionButton(
                  Icons.edit_outlined,
                  textMuted,
                  () => _showEditDialog(item),
                ),
                SizedBox(width: 6.w),
                _actionButton(
                  Icons.add_box_outlined,
                  InventoryColors.blue,
                  () => _showRestockDialog(item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
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

  Widget _emptyState() => Padding(
    padding: EdgeInsets.all(48.w),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48.sp, color: textDim),
          SizedBox(height: 12.h),
          Text(
            'No items match your filters',
            style: InventoryFonts.sans(14.sp, color: textMuted),
          ),
        ],
      ),
    ),
  );

  Widget _tableFooter() {
    final val = _filtered.fold(0.0, (s, i) => s + i.stockValue);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14.r)),
      ),
      child: Row(
        children: [
          Text(
            '${_filtered.length} items shown',
            style: InventoryFonts.mono(10.sp, color: textDim),
          ),
          const Spacer(),
          Text(
            'Visible value: ',
            style: InventoryFonts.mono(10.sp, color: textDim),
          ),
          Text(
            '\$${val.toStringAsFixed(2)}',
            style: InventoryFonts.mono(
              12.sp,
              color: InventoryColors.green,
              w: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Helpers ─────────────────────────────────────────────────────────────

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

  Color _statusBg(StockStatus s) {
    switch (s) {
      case StockStatus.ok:
        return InventoryColors.greenDim;
      case StockStatus.low:
        return InventoryColors.orangeDim;
      case StockStatus.critical:
        return InventoryColors.redDim;
      case StockStatus.outOfStock:
        return const Color(0x1A6B7280);
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

  // ── Dialogs ──────────────────────────────────────────────────────────────────

  void _showRestockDialog(InventoryItem item) {
    int qty = 10;
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
                    '${item.stock} ${item.unit}',
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
                    '$qty',
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
              onPressed: () {
                setState(() => item.stock += qty);
                Navigator.pop(ctx);
                _showToast('Restocked +$qty', InventoryColors.green);
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

  void _showEditDialog(InventoryItem item) {
    final nc = TextEditingController(text: item.name);
    final sc = TextEditingController(text: item.sku);
    final cc = TextEditingController(text: item.costPrice.toStringAsFixed(2));
    final lc = TextEditingController(text: item.sellPrice.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Edit Item',
          style: InventoryFonts.display(16.sp, w: FontWeight.w800),
        ),
        content: SizedBox(
          width: 320.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField('Name', nc),
              SizedBox(height: 12.h),
              _dialogField('SKU', sc),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(child: _dialogField('Cost \$', cc)),
                  SizedBox(width: 12.w),
                  Expanded(child: _dialogField('Sell \$', lc)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: InventoryFonts.sans(12.sp, color: textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: InventoryColors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              _showToast('Item updated', InventoryColors.green);
            },
            child: Text(
              'Save',
              style: InventoryFonts.sans(
                12.sp,
                w: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Add New Item',
          style: InventoryFonts.display(16.sp, w: FontWeight.w800),
        ),
        content: SizedBox(
          width: 340.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField('Item Name', TextEditingController()),
              SizedBox(height: 12.h),
              _dialogField('SKU', TextEditingController()),
              SizedBox(height: 12.h),
              _dialogField('Supplier', TextEditingController()),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _dialogField('Cost \$', TextEditingController()),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _dialogField('Sell \$', TextEditingController()),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _dialogField('Stock', TextEditingController()),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _dialogField('Min Stock', TextEditingController()),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            onPressed: () {
              Navigator.pop(context);
              _showToast('Item added', InventoryColors.green);
            },
            child: Text(
              'Add Item',
              style: InventoryFonts.sans(
                12.sp,
                w: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: InventoryFonts.sans(9.sp, w: FontWeight.w600, color: textDim),
      ),
      SizedBox(height: 6.h),
      Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: surface2,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: border),
        ),
        child: TextField(
          controller: ctrl,
          style: InventoryFonts.sans(12.sp),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10.h),
          ),
          cursorColor: InventoryColors.green,
        ),
      ),
    ],
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
            Text(
              msg,
              style: InventoryFonts.sans(
                13.sp,
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

class _SD {
  final String label, value, sub;
  final IconData icon;
  final Color accent, accentDim;
  const _SD(
    this.label,
    this.value,
    this.icon,
    this.accent,
    this.accentDim,
    this.sub,
  );
}
