// lib/Features/Sales/sales_screen.dart
// Zaytouna POS - Sales Report Screen (Connected to Supabase)

// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LIGHT THEME PALETTE
// ─────────────────────────────────────────────────────────────────────────────

class SalesColors {
  SalesColors._();

  static const bg = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0F2F5);
  static const surface3 = Color(0xFFE8EBF0);
  static const border = Color(0xFFE2E5EA);

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

class SalesFonts {
  SalesFonts._();

  static TextStyle display(
    double size, {
    FontWeight w = FontWeight.w700,
    Color? color,
  }) => GoogleFonts.dmSerifDisplay(
    fontSize: size,
    fontWeight: w,
    color: color ?? SalesColors.text,
  );

  static TextStyle sans(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color ?? SalesColors.text,
  );

  static TextStyle mono(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: w,
    color: color ?? SalesColors.text,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum SaleStatus { completed, pending, voided, refunded, cancelled }

enum PaymentMethod { cash, card, transfer, split, digital }

class SaleItem {
  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  SaleItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class Sale {
  final String id;
  final String invoiceNumber;
  final DateTime date;
  final String customerName;
  final SaleStatus status;
  final PaymentMethod paymentMethod;
  final List<SaleItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String? server;
  final String? table;

  Sale({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.customerName,
    required this.status,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    this.server,
    this.table,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusLabel {
    switch (status) {
      case SaleStatus.completed:
        return 'Completed';
      case SaleStatus.pending:
        return 'Pending';
      case SaleStatus.voided:
        return 'Voided';
      case SaleStatus.refunded:
        return 'Refunded';
      case SaleStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (status) {
      case SaleStatus.completed:
        return SalesColors.green;
      case SaleStatus.pending:
        return SalesColors.orange;
      case SaleStatus.voided:
        return SalesColors.red;
      case SaleStatus.refunded:
        return SalesColors.purple;
      case SaleStatus.cancelled:
        return SalesColors.red;
    }
  }

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.transfer:
        return 'Transfer';
      case PaymentMethod.split:
        return 'Split';
      case PaymentMethod.digital:
        return 'Digital';
    }
  }

  IconData get paymentMethodIcon {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return Icons.money_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.transfer:
        return Icons.account_balance_rounded;
      case PaymentMethod.split:
        return Icons.call_split_rounded;
      case PaymentMethod.digital:
        return Icons.smartphone_rounded;
    }
  }
}

class DailySummary {
  final DateTime date;
  final int totalOrders;
  final double totalSales;
  final double averageOrder;
  final Map<PaymentMethod, double> paymentBreakdown;

  DailySummary({
    required this.date,
    required this.totalOrders,
    required this.totalSales,
    required this.averageOrder,
    required this.paymentBreakdown,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  SALES SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late final SupabaseClient _supabase;
  final _searchCtrl = TextEditingController();

  List<Sale> _allSales = [];
  List<Sale> _cachedFiltered = [];
  List<DailySummary> _dailySummaries = [];

  String _searchQuery = '';
  SaleStatus? _filterStatus;
  PaymentMethod? _filterPayment;
  Sale? _selectedSale;
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = true;

  // Color shortcuts
  Color get bg => SalesColors.bg;
  Color get surface => SalesColors.surface;
  Color get surface2 => SalesColors.surface2;
  Color get border => SalesColors.border;
  Color get textClr => SalesColors.text;
  Color get textMuted => SalesColors.textSecondary;
  Color get textDim => SalesColors.textMuted;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _loadSales();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      // Fetch orders and inner-join order_items & menu_items
      final data = await _supabase
          .from('orders')
          .select('''
            id, 
            total_amount, 
            created_at, 
            order_items (
              id,
              quantity, 
              unit_price, 
              item_total, 
              menu_items (name)
            )
          ''')
          .order('created_at', ascending: false);

      final sales = <Sale>[];

      for (var order in data) {
        // Parse Items properly
        final rawItems = order['order_items'] as List<dynamic>? ?? [];
        final saleItems = rawItems.map((item) {
          final menuItem = item['menu_items'] as Map<String, dynamic>?;
          return SaleItem(
            id: item['id'].toString(),
            name: menuItem?['name'] as String? ?? 'Unknown Item',
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
            unitPrice: (item['unit_price'] as num?)?.toDouble() ?? 0.0,
            totalPrice: (item['item_total'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        final total = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
        final subtotal =
            total / 1.1; // Assuming 10% tax reverse calculation for UI
        final tax = total - subtotal;

        sales.add(
          Sale(
            id: order['id'].toString(),
            invoiceNumber: 'INV-${order['id'].toString().padLeft(6, '0')}',
            date: DateTime.parse(order['created_at']).toLocal(),
            customerName: 'Walk-in Customer', // Mocked - Not in schema
            status: SaleStatus.completed, // Mocked - Not in schema
            paymentMethod: PaymentMethod.card, // Mocked - Not in schema
            items: saleItems,
            subtotal: subtotal,
            tax: tax,
            discount: 0.0,
            total: total,
            server: 'POS Terminal',
          ),
        );
      }

      // Calculate daily summaries for the chart
      final dailySummaries = <DailySummary>[];
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final daySales = sales
            .where(
              (s) =>
                  s.date.day == date.day &&
                  s.date.month == date.month &&
                  s.date.year == date.year,
            )
            .toList();

        final total = daySales.fold(0.0, (sum, s) => sum + s.total);
        final count = daySales.length;

        dailySummaries.add(
          DailySummary(
            date: date,
            totalOrders: count,
            totalSales: total,
            averageOrder: count > 0 ? total / count : 0,
            paymentBreakdown: {},
          ),
        );
      }

      if (mounted) {
        setState(() {
          _allSales = sales;
          _dailySummaries = dailySummaries;
          _isLoading = false;
          _recalculateFiltered();
        });
      }
    } catch (e) {
      print('Error loading sales: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    _updateFilters(search: _searchCtrl.text);
  }

  void _updateFilters({
    String? search,
    SaleStatus? status,
    PaymentMethod? payment,
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
    if (payment != _filterPayment) {
      _filterPayment = payment;
      changed = true;
    }

    if (changed) {
      setState(() => _recalculateFiltered());
    }
  }

  void _recalculateFiltered() {
    var list = List<Sale>.from(_allSales);

    if (_filterStatus != null) {
      list = list.where((s) => s.status == _filterStatus).toList();
    }
    if (_filterPayment != null) {
      list = list.where((s) => s.paymentMethod == _filterPayment).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (s) =>
                s.invoiceNumber.toLowerCase().contains(q) ||
                s.customerName.toLowerCase().contains(q) ||
                (s.server?.toLowerCase().contains(q) == true),
          )
          .toList();
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    _cachedFiltered = list;
  }

  // ✅ Computed properties
  double get _totalSales =>
      _cachedFiltered.fold(0.0, (sum, s) => sum + s.total);
  int get _totalOrders => _cachedFiltered.length;
  double get _averageOrder => _totalOrders > 0 ? _totalSales / _totalOrders : 0;
  int get _totalItems => _cachedFiltered.fold(0, (sum, s) => sum + s.itemCount);

  double get _todaySales {
    final today = DateTime.now();
    return _allSales
        .where(
          (s) =>
              s.date.year == today.year &&
              s.date.month == today.month &&
              s.date.day == today.day,
        )
        .fold(0.0, (sum, s) => sum + s.total);
  }

  void _showSaleDetails(Sale sale) {
    _selectedSale = sale;
    if (MediaQuery.of(context).size.width < 1000) {
      _showDetailSheet(sale);
    } else {
      setState(() {});
    }
  }

  void _showDetailSheet(Sale sale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SaleDetailSheet(sale: sale),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: SalesColors.cyan),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      backgroundColor: bg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: SalesColors.cyan),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    _TopBar(
                      searchCtrl: _searchCtrl,
                      onDateTap: _selectDate,
                      selectedDate: _selectedDate,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _WelcomeHeader(),
                            SizedBox(height: 24.h),
                            _KPICards(
                              todaySales: _todaySales,
                              totalOrders: _totalOrders,
                              averageOrder: _averageOrder,
                              totalItems: _totalItems,
                              constraints: constraints,
                            ),
                            SizedBox(height: 24.h),
                            _DailyTrendChart(summaries: _dailySummaries),
                            SizedBox(height: 24.h),
                            if (isWide && _selectedSale != null)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _SalesTable(
                                      sales: _cachedFiltered,
                                      selected: _selectedSale,
                                      filterStatus: _filterStatus,
                                      filterPayment: _filterPayment,
                                      onSelect: _showSaleDetails,
                                      onStatusFilter: (s) =>
                                          _updateFilters(status: s),
                                      onPaymentFilter: (p) =>
                                          _updateFilters(payment: p),
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: _SaleDetailPanel(
                                      sale: _selectedSale!,
                                      onClose: () =>
                                          setState(() => _selectedSale = null),
                                    ),
                                  ),
                                ],
                              )
                            else
                              _SalesTable(
                                sales: _cachedFiltered,
                                selected: _selectedSale,
                                filterStatus: _filterStatus,
                                filterPayment: _filterPayment,
                                onSelect: _showSaleDetails,
                                onStatusFilter: (s) =>
                                    _updateFilters(status: s),
                                onPaymentFilter: (p) =>
                                    _updateFilters(payment: p),
                              ),
                            SizedBox(height: 32.h),
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
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final VoidCallback onDateTap;
  final DateTime selectedDate;

  const _TopBar({
    required this.searchCtrl,
    required this.onDateTap,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: SalesColors.surface,
        border: Border(bottom: BorderSide(color: SalesColors.border)),
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
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: SalesColors.cyan,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              size: 20.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SALES',
                style: SalesFonts.sans(
                  8.sp,
                  w: FontWeight.w700,
                  color: SalesColors.cyan,
                ),
              ),
              Text(
                'Transaction History',
                style: SalesFonts.display(16.sp, w: FontWeight.w700),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: SalesColors.surface2,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: SalesColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14.sp,
                    color: SalesColors.textSecondary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    style: SalesFonts.mono(
                      11.sp,
                      color: SalesColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 16.sp,
                    color: SalesColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 240.w,
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: SalesColors.surface2,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: SalesColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18.sp,
                  color: SalesColors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    style: SalesFonts.sans(12.sp),
                    decoration: InputDecoration(
                      hintText: 'Search sales...',
                      hintStyle: SalesFonts.sans(
                        11.sp,
                        color: SalesColors.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    cursorColor: SalesColors.cyan,
                  ),
                ),
                if (searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () => searchCtrl.clear(),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16.sp,
                      color: SalesColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: SalesColors.cyan,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Icon(Icons.download_rounded, size: 14.sp, color: Colors.white),
                SizedBox(width: 6.w),
                Text(
                  'Export',
                  style: SalesFonts.sans(
                    11.sp,
                    w: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          CircleAvatar(
            radius: 18.r,
            backgroundColor: SalesColors.cyanLight,
            child: Text(
              'S',
              style: TextStyle(
                color: SalesColors.cyan,
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

// ─────────────────────────────────────────────────────────────────────────────
//  WELCOME HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: SalesColors.cyanLight,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5.w,
                height: 5.w,
                decoration: const BoxDecoration(
                  color: SalesColors.cyan,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'TRANSACTION HISTORY',
                style: SalesFonts.sans(
                  8.sp,
                  w: FontWeight.w700,
                  color: SalesColors.cyan,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text('Sales Records', style: SalesFonts.display(36.sp)),
        SizedBox(height: 6.h),
        Text(
          'View and manage all sales transactions, filter by status, and export reports.',
          style: SalesFonts.sans(12.sp, color: SalesColors.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  KPI CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _KPICards extends StatelessWidget {
  final double todaySales;
  final int totalOrders;
  final double averageOrder;
  final int totalItems;
  final BoxConstraints constraints;

  const _KPICards({
    required this.todaySales,
    required this.totalOrders,
    required this.averageOrder,
    required this.totalItems,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KPI(
        label: 'Today\'s Sales',
        value: '\$${todaySales.toStringAsFixed(2)}',
        subtitle: DateTime.now().toString().split(' ')[0],
        icon: Icons.today_rounded,
        color: SalesColors.cyan,
        lightColor: SalesColors.cyanLight,
      ),
      _KPI(
        label: 'Total Orders',
        value: totalOrders.toString(),
        subtitle: 'Filtered view',
        icon: Icons.receipt_long_rounded,
        color: SalesColors.blue,
        lightColor: SalesColors.blueLight,
      ),
      _KPI(
        label: 'Average Order',
        value: '\$${averageOrder.toStringAsFixed(2)}',
        subtitle: 'Per transaction',
        icon: Icons.analytics_rounded,
        color: SalesColors.purple,
        lightColor: SalesColors.purpleLight,
      ),
      _KPI(
        label: 'Items Sold',
        value: totalItems.toString(),
        subtitle: 'Total quantity',
        icon: Icons.shopping_bag_rounded,
        color: SalesColors.orange,
        lightColor: SalesColors.orangeLight,
      ),
    ];

    if (constraints.maxWidth >= 900) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(width: 16.w),
            Expanded(child: _KPICard(data: cards[i])),
          ],
        ],
      );
    } else if (constraints.maxWidth >= 600) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _KPICard(data: cards[0])),
              SizedBox(width: 12.w),
              Expanded(child: _KPICard(data: cards[1])),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: _KPICard(data: cards[2])),
              SizedBox(width: 12.w),
              Expanded(child: _KPICard(data: cards[3])),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            _KPICard(data: cards[i]),
            if (i < 3) SizedBox(height: 10.h),
          ],
        ],
      );
    }
  }
}

class _KPI {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color lightColor;

  _KPI({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.lightColor,
  });
}

class _KPICard extends StatelessWidget {
  final _KPI data;

  const _KPICard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: SalesColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: SalesColors.border),
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
                  color: data.lightColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(data.icon, size: 20.sp, color: data.color),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 12.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: SalesFonts.display(22.sp, w: FontWeight.w800),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            data.label,
            style: SalesFonts.sans(11.sp, color: SalesColors.textSecondary),
          ),
          SizedBox(height: 2.h),
          Text(
            data.subtitle,
            style: SalesFonts.sans(9.sp, color: SalesColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DAILY TREND CHART
// ─────────────────────────────────────────────────────────────────────────────

class _DailyTrendChart extends StatelessWidget {
  final List<DailySummary> summaries;

  const _DailyTrendChart({required this.summaries});

  String _formatDate(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    // Safely calculate maxSales to prevent Division By Zero crash
    final maxSalesRaw = summaries.isEmpty
        ? 0.0
        : summaries.map((s) => s.totalSales).reduce(math.max);
    final safeMaxSales = maxSalesRaw <= 0 ? 1.0 : maxSalesRaw;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: SalesColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: SalesColors.border),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last 7 Days Performance',
                style: SalesFonts.sans(14.sp, w: FontWeight.w700),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: SalesColors.cyanLight,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Daily Trend',
                  style: SalesFonts.sans(
                    10.sp,
                    color: SalesColors.cyan,
                    w: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 180.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: summaries.asMap().entries.map((entry) {
                final summary = entry.value;
                final barHeight = (summary.totalSales / safeMaxSales) * 140.h;
                final isToday =
                    summary.date.day == DateTime.now().day &&
                    summary.date.month == DateTime.now().month;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '\$${summary.totalSales.toStringAsFixed(0)}',
                          style: SalesFonts.mono(
                            9.sp,
                            color: SalesColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutQuart,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: isToday
                                ? SalesColors.cyan
                                : SalesColors.cyan.withOpacity(0.6),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(6.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _formatDate(summary.date),
                          style: SalesFonts.mono(
                            10.sp,
                            w: isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isToday
                                ? SalesColors.cyan
                                : SalesColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${summary.totalOrders}',
                          style: SalesFonts.mono(
                            9.sp,
                            color: SalesColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SALES TABLE
// ─────────────────────────────────────────────────────────────────────────────

class _SalesTable extends StatelessWidget {
  final List<Sale> sales;
  final Sale? selected;
  final SaleStatus? filterStatus;
  final PaymentMethod? filterPayment;
  final Function(Sale) onSelect;
  final Function(SaleStatus?) onStatusFilter;
  final Function(PaymentMethod?) onPaymentFilter;

  const _SalesTable({
    required this.sales,
    required this.selected,
    required this.filterStatus,
    required this.filterPayment,
    required this.onSelect,
    required this.onStatusFilter,
    required this.onPaymentFilter,
  });

  static const _headers = [
    'Invoice',
    'Date',
    'Customer',
    'Items',
    'Payment',
    'Status',
    'Total',
  ];
  static const _widths = [130.0, 120.0, 150.0, 70.0, 100.0, 100.0, 100.0];
  double get _tableWidth => _widths.fold(0.0, (a, b) => a + b) + 32;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SalesColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: SalesColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: SalesColors.border)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'Status:',
                    style: SalesFonts.sans(
                      11.sp,
                      color: SalesColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _FilterChip(
                    label: 'All',
                    isSelected: filterStatus == null,
                    onTap: () => onStatusFilter(null),
                  ),
                  SizedBox(width: 6.w),
                  _FilterChip(
                    label: 'Completed',
                    color: SalesColors.green,
                    isSelected: filterStatus == SaleStatus.completed,
                    onTap: () => onStatusFilter(SaleStatus.completed),
                  ),
                  SizedBox(width: 6.w),
                  _FilterChip(
                    label: 'Pending',
                    color: SalesColors.orange,
                    isSelected: filterStatus == SaleStatus.pending,
                    onTap: () => onStatusFilter(SaleStatus.pending),
                  ),
                  SizedBox(width: 6.w),
                  _FilterChip(
                    label: 'Voided',
                    color: SalesColors.red,
                    isSelected: filterStatus == SaleStatus.voided,
                    onTap: () => onStatusFilter(SaleStatus.voided),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    'Payment:',
                    style: SalesFonts.sans(
                      11.sp,
                      color: SalesColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _FilterChip(
                    label: 'All',
                    isSelected: filterPayment == null,
                    onTap: () => onPaymentFilter(null),
                  ),
                  SizedBox(width: 6.w),
                  _FilterChip(
                    label: 'Cash',
                    isSelected: filterPayment == PaymentMethod.cash,
                    onTap: () => onPaymentFilter(PaymentMethod.cash),
                  ),
                  SizedBox(width: 6.w),
                  _FilterChip(
                    label: 'Card',
                    isSelected: filterPayment == PaymentMethod.card,
                    onTap: () => onPaymentFilter(PaymentMethod.card),
                  ),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: _tableWidth,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: SalesColors.surface2,
                border: Border(bottom: BorderSide(color: SalesColors.border)),
              ),
              child: Row(
                children: List.generate(
                  _headers.length,
                  (i) => SizedBox(
                    width: _widths[i],
                    child: Text(
                      _headers[i],
                      style: SalesFonts.sans(
                        9.sp,
                        w: FontWeight.w600,
                        color: SalesColors.textDim,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (sales.isEmpty)
            Padding(
              padding: EdgeInsets.all(48.w),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 48.sp,
                      color: SalesColors.textDim,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No sales found',
                      style: SalesFonts.sans(
                        14.sp,
                        color: SalesColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...sales.map(
              (s) => _SaleRow(
                sale: s,
                isSelected: selected?.id == s.id,
                colWidths: _widths,
                totalWidth: _tableWidth,
                onTap: () => onSelect(s),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? SalesColors.cyan;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withOpacity(0.12)
              : SalesColors.surface2,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: isSelected ? chipColor : SalesColors.border,
          ),
        ),
        child: Text(
          label,
          style: SalesFonts.sans(
            10.sp,
            w: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? chipColor : SalesColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  final Sale sale;
  final bool isSelected;
  final List<double> colWidths;
  final double totalWidth;
  final VoidCallback onTap;

  const _SaleRow({
    required this.sale,
    required this.isSelected,
    required this.colWidths,
    required this.totalWidth,
    required this.onTap,
  });

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today ${_formatTime(date)}';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday ${_formatTime(date)}';
    }
    return '${date.day}/${date.month} ${_formatTime(date)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: totalWidth,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? SalesColors.cyan.withOpacity(0.04)
                : SalesColors.surface,
            border: Border(
              bottom: BorderSide(color: SalesColors.border),
              left: BorderSide(
                color: isSelected ? SalesColors.cyan : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: colWidths[0],
                child: Text(
                  sale.invoiceNumber,
                  style: SalesFonts.mono(
                    11.sp,
                    w: FontWeight.w600,
                    color: SalesColors.cyan,
                  ),
                ),
              ),
              SizedBox(
                width: colWidths[1],
                child: Text(
                  _formatDate(sale.date),
                  style: SalesFonts.sans(
                    11.sp,
                    color: SalesColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: colWidths[2],
                child: Text(
                  sale.customerName,
                  style: SalesFonts.sans(11.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: colWidths[3],
                child: Text(
                  '${sale.itemCount} items',
                  style: SalesFonts.mono(
                    11.sp,
                    color: SalesColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: colWidths[4],
                child: Row(
                  children: [
                    Icon(
                      sale.paymentMethodIcon,
                      size: 14.sp,
                      color: SalesColors.textSecondary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      sale.paymentMethodLabel,
                      style: SalesFonts.sans(
                        11.sp,
                        color: SalesColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: colWidths[5],
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: sale.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    sale.statusLabel,
                    style: SalesFonts.sans(
                      10.sp,
                      w: FontWeight.w600,
                      color: sale.statusColor,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: colWidths[6],
                child: Text(
                  '\$${sale.total.toStringAsFixed(2)}',
                  style: SalesFonts.mono(
                    12.sp,
                    w: FontWeight.w700,
                    color: SalesColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SALE DETAIL PANELS
// ─────────────────────────────────────────────────────────────────────────────

class _SaleDetailPanel extends StatelessWidget {
  final Sale sale;
  final VoidCallback onClose;

  const _SaleDetailPanel({required this.sale, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SalesColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: SalesColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Text(
                  'Sale Details',
                  style: SalesFonts.sans(13.sp, w: FontWeight.w700),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18.sp,
                    color: SalesColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: SalesColors.border),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sale.invoiceNumber,
                      style: SalesFonts.mono(
                        16.sp,
                        w: FontWeight.w700,
                        color: SalesColors.cyan,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: sale.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        sale.statusLabel,
                        style: SalesFonts.sans(
                          11.sp,
                          w: FontWeight.w600,
                          color: sale.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _DetailRow(
                  label: 'Date',
                  value:
                      '${sale.date.day}/${sale.date.month}/${sale.date.year} ${sale.date.hour}:${sale.date.minute.toString().padLeft(2, '0')}',
                ),
                _DetailRow(label: 'Customer', value: sale.customerName),
                if (sale.server != null)
                  _DetailRow(label: 'Server', value: sale.server!),
                if (sale.table != null)
                  _DetailRow(label: 'Table', value: sale.table!),
                _DetailRow(label: 'Payment', value: sale.paymentMethodLabel),
                SizedBox(height: 16.h),
                Divider(color: SalesColors.border),
                SizedBox(height: 8.h),
                Text(
                  'Items',
                  style: SalesFonts.sans(12.sp, w: FontWeight.w600),
                ),
                SizedBox(height: 8.h),
                ...sale.items.map(
                  (item) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(item.name, style: SalesFonts.sans(11.sp)),
                        ),
                        Text(
                          '${item.quantity} × ',
                          style: SalesFonts.sans(
                            11.sp,
                            color: SalesColors.textSecondary,
                          ),
                        ),
                        Text(
                          '\$${item.unitPrice.toStringAsFixed(2)}',
                          style: SalesFonts.mono(
                            11.sp,
                            color: SalesColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        SizedBox(
                          width: 60.w,
                          child: Text(
                            '\$${item.totalPrice.toStringAsFixed(2)}',
                            style: SalesFonts.mono(11.sp, w: FontWeight.w600),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(color: SalesColors.border),
                _SummaryRow(
                  label: 'Subtotal',
                  value: '\$${sale.subtotal.toStringAsFixed(2)}',
                ),
                _SummaryRow(
                  label: 'Tax (10%)',
                  value: '\$${sale.tax.toStringAsFixed(2)}',
                ),
                if (sale.discount > 0)
                  _SummaryRow(
                    label: 'Discount',
                    value: '-\$${sale.discount.toStringAsFixed(2)}',
                    color: SalesColors.red,
                  ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: SalesFonts.sans(14.sp, w: FontWeight.w700),
                    ),
                    Text(
                      '\$${sale.total.toStringAsFixed(2)}',
                      style: SalesFonts.mono(
                        16.sp,
                        w: FontWeight.w800,
                        color: SalesColors.cyan,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.print_rounded, size: 16.sp),
                        label: const Text('Print Receipt'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SalesColors.textSecondary,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.refresh_rounded, size: 16.sp),
                        label: const Text('Refund'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SalesColors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleDetailSheet extends StatelessWidget {
  final Sale sale;

  const _SaleDetailSheet({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: SalesColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: SalesColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sale.invoiceNumber,
                style: SalesFonts.mono(
                  16.sp,
                  w: FontWeight.w700,
                  color: SalesColors.cyan,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: sale.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  sale.statusLabel,
                  style: SalesFonts.sans(
                    11.sp,
                    w: FontWeight.w600,
                    color: sale.statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _DetailRow(
            label: 'Date',
            value: '${sale.date.day}/${sale.date.month}/${sale.date.year}',
          ),
          _DetailRow(label: 'Customer', value: sale.customerName),
          _DetailRow(
            label: 'Total',
            value: '\$${sale.total.toStringAsFixed(2)}',
          ),
          SizedBox(height: 16.h),
          Text(
            '${sale.itemCount} items',
            style: SalesFonts.sans(12.sp, w: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          ...sale.items
              .take(3)
              .map(
                (item) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}× ${item.name}',
                          style: SalesFonts.sans(11.sp),
                        ),
                      ),
                      Text(
                        '\$${item.totalPrice.toStringAsFixed(2)}',
                        style: SalesFonts.mono(11.sp),
                      ),
                    ],
                  ),
                ),
              ),
          if (sale.items.length > 3)
            Text(
              '+${sale.items.length - 3} more items',
              style: SalesFonts.sans(11.sp, color: SalesColors.textSecondary),
            ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SalesColors.cyan,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Print'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: SalesFonts.sans(11.sp, color: SalesColors.textSecondary),
          ),
          Text(value, style: SalesFonts.sans(12.sp)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SummaryRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: SalesFonts.sans(11.sp, color: SalesColors.textSecondary),
          ),
          Text(
            value,
            style: SalesFonts.mono(11.sp, color: color ?? SalesColors.text),
          ),
        ],
      ),
    );
  }
}
