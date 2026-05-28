// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zaytouna_park/Core/Routers/routes.dart';
import 'package:zaytouna_park/Features/cashier/Utils/receipt_printer.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Terminal/terminalscreen.dart';

// ─── DESIGN TOKENS (matches terminal/dashboard) ───────────────────────
class _T {
  static const primary = Color(0xFFB8860B);
  static const primaryD = Color(0xFF8B6914);
  static const primaryL = Color(0xFFFFF7DB);
  static const bg = Color(0xFFFAFAF7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F5F0);
  static const ink = Color(0xFF0A0F0D);
  static const ink2 = Color(0xFF2D3438);
  static const muted = Color(0xFF64748B);
  static const muted2 = Color(0xFF94A3B8);
  static const line = Color(0xFFE5E7EB);
  static const lineSoft = Color(0xFFF1F2F4);
  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFD1FAE5);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEE2E2);
  static const warn = Color(0xFFD97706);
  static const warnBg = Color(0xFFFEF3C7);
  static const info = Color(0xFF2563EB);
}

TextStyle _ui(
  double s, {
  FontWeight w = FontWeight.w600,
  Color? c,
  double? ls,
}) => GoogleFonts.inter(
  fontSize: s,
  fontWeight: w,
  color: c ?? _T.ink,
  letterSpacing: ls,
);

TextStyle _num(double s, {FontWeight w = FontWeight.w700, Color? c}) =>
    GoogleFonts.inter(
      fontSize: s,
      fontWeight: w,
      color: c ?? _T.ink,
      letterSpacing: -0.2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

TextStyle _eyebrow(double s, {Color? c}) => GoogleFonts.inter(
  fontSize: s,
  fontWeight: FontWeight.w800,
  color: c ?? _T.muted,
  letterSpacing: 1.4,
);

// ─── MODELS (signatures unchanged — terminal depends on these) ────────
enum OrderStatus { active, completed, cancelled, deleted }

class OrderItem {
  final int id;
  final String name;
  final int quantity;
  final double price;
  final double total;
  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
  });
}

class OrderModel {
  final int id;
  final String tableNumber;
  final List<OrderItem> items;
  final OrderStatus status;
  final String paymentStatus;
  final DateTime timestamp;
  final String customerName;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  OrderModel({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.status,
    required this.paymentStatus,
    required this.timestamp,
    required this.customerName,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
  });
  String get displayId => "ORD-${id.toString().padLeft(4, '0')}";
}

// ─── ORDERS SCREEN ────────────────────────────────────────────────────
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _supabase = Supabase.instance.client;
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  OrderModel? _selectedOrder;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('orders')
          .select('''
          id, created_at, order_status, payment_status,
          subtotal, discount_amount, tax_amount, total_amount,
          customers(name), restaurant_tables(name), facilities(name),
          order_types(name),
          order_items(
            id, quantity, unit_price, item_total,
            menu_items(name), inventory_items(name)
          )
        ''')
          .order('created_at', ascending: false);

      final parsed = (res as List).map((o) {
        OrderStatus status = OrderStatus.active;
        switch (o['order_status']) {
          case 'completed':
            status = OrderStatus.completed;
            break;
          case 'cancelled':
            status = OrderStatus.cancelled;
            break;
          case 'deleted':
            status = OrderStatus.deleted;
            break;
        }

        final items = <OrderItem>[];
        if (o['order_items'] != null) {
          for (final i in o['order_items']) {
            final name =
                i['menu_items']?['name'] ??
                i['inventory_items']?['name'] ??
                'Unknown Item';
            items.add(
              OrderItem(
                id: i['id'],
                name: name,
                quantity: i['quantity'] ?? 1,
                price: (i['unit_price'] as num).toDouble(),
                total: (i['item_total'] as num).toDouble(),
              ),
            );
          }
        }

        final tableName = o['restaurant_tables']?['name'] as String?;
        final facilityName = o['facilities']?['name'] as String?;
        final orderType = o['order_types']?['name'] as String? ?? 'Takeaway';

        return OrderModel(
          id: o['id'],
          timestamp: DateTime.parse(o['created_at']).toLocal(),
          status: status,
          paymentStatus: o['payment_status'] ?? 'unpaid',
          customerName: o['customers']?['name'] ?? 'Walk-in Guest',
          tableNumber: tableName ?? facilityName ?? orderType,
          subtotal: (o['subtotal'] as num?)?.toDouble() ?? 0.0,
          discountAmount: (o['discount_amount'] as num?)?.toDouble() ?? 0.0,
          taxAmount: (o['tax_amount'] as num?)?.toDouble() ?? 0.0,
          totalAmount: (o['total_amount'] as num?)?.toDouble() ?? 0.0,
          items: items,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _orders = parsed;
          if (_selectedOrder != null) {
            _selectedOrder = _orders
                .where((x) => x.id == _selectedOrder!.id)
                .firstOrNull;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _toast('Database error: $e', _T.danger);
      }
    }
  }

  void _toast(String msg, Color c) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              c == _T.success
                  ? Icons.check_circle_rounded
                  : c == _T.danger
                  ? Icons.error_rounded
                  : Icons.info_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: _ui(13, w: FontWeight.w600, c: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isPhone = w < 720;
    return Scaffold(
      backgroundColor: _T.bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(isPhone),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _T.primary,
                        strokeWidth: 3,
                      ),
                    )
                  : RefreshIndicator(
                      color: _T.primary,
                      onRefresh: _fetchOrders,
                      child: _orderList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────
  Widget _header(bool isPhone) => Container(
    decoration: const BoxDecoration(
      color: _T.surface,
      border: Border(bottom: BorderSide(color: _T.line)),
    ),
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          child: Row(
            children: [
              _IconBtn(
                icon: Icons.arrow_back_rounded,
                color: _T.ink,
                onTap: () => context.go(Routes.cashierDashboard),
              ),
              SizedBox(width: 10.w),
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_T.primary, _T.primaryD],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _T.primary.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Order History',
                      style: _ui(
                        isPhone ? 16.sp : 20.sp,
                        w: FontWeight.w800,
                        ls: -0.3,
                      ),
                    ),
                    if (!isPhone)
                      Text(
                        '${_orders.length} order${_orders.length == 1 ? "" : "s"}',
                        style: _ui(11, w: FontWeight.w600, c: _T.muted),
                      ),
                  ],
                ),
              ),
              if (!isPhone) _filterRow(),
            ],
          ),
        ),
        if (isPhone)
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
            child: SizedBox(height: 32, child: _filterRow(scrollable: true)),
          ),
      ],
    ),
  );

  Widget _filterRow({bool scrollable = false}) {
    const filters = ['All', 'Active', 'Completed', 'Cancelled', 'Deleted'];
    final chips = filters
        .map(
          (f) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Chip(
              label: f,
              isSelected: _filter == f,
              onTap: () {
                setState(() {
                  _filter = f;
                  _selectedOrder = null;
                });
              },
            ),
          ),
        )
        .toList();

    if (scrollable) {
      return ListView(scrollDirection: Axis.horizontal, children: chips);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: chips);
  }

  // ─── ORDER LIST ─────────────────────────────────────────────────────
  Widget _orderList() {
    final filtered = _orders.where((o) {
      switch (_filter) {
        case 'All':
          return o.status != OrderStatus.deleted;
        case 'Active':
          return o.status == OrderStatus.active;
        case 'Completed':
          return o.status == OrderStatus.completed;
        case 'Cancelled':
          return o.status == OrderStatus.cancelled;
        case 'Deleted':
          return o.status == OrderStatus.deleted;
        default:
          return true;
      }
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: _T.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 36,
                color: _T.muted2,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'No orders found',
              style: _ui(14, w: FontWeight.w800, c: _T.ink2),
            ),
            SizedBox(height: 4.h),
            Text(
              'Pull down to refresh',
              style: _ui(12, w: FontWeight.w500, c: _T.muted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _orderCard(filtered[i]),
    );
  }

  Widget _orderCard(OrderModel order) {
    final isDeleted = order.status == OrderStatus.deleted;
    final isSelected = _selectedOrder?.id == order.id;

    final iconData = isDeleted
        ? Icons.delete_outline_rounded
        : (order.tableNumber.toLowerCase().contains('takeaway') ||
              order.tableNumber.toLowerCase().contains('delivery'))
        ? Icons.shopping_bag_outlined
        : Icons.table_restaurant_outlined;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isSelected ? _T.primaryL : _T.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? _T.primary : _T.lineSoft,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _selectedOrder = order);
            _showOrderDialog(order);
          },
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Opacity(
              opacity: isDeleted ? 0.6 : 1.0,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _T.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: _T.muted, size: 18),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order.displayId,
                              style:
                                  _ui(
                                    14,
                                    w: FontWeight.w800,
                                    c: isDeleted ? _T.muted : _T.ink,
                                  ).copyWith(
                                    decoration: isDeleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                            ),
                            SizedBox(width: 10.w),
                            _StatusBadge(status: order.status),
                            if (order.paymentStatus == 'unpaid' &&
                                !isDeleted) ...[
                              SizedBox(width: 6.w),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _T.dangerBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'UNPAID',
                                  style: _eyebrow(8.5, c: _T.danger),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${order.tableNumber} • ${order.customerName}',
                          style: _ui(12, w: FontWeight.w500, c: _T.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${order.totalAmount.toStringAsFixed(2)}',
                        style: _num(
                          15,
                          w: FontWeight.w800,
                          c: isDeleted ? _T.muted : _T.ink,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _timeAgo(order.timestamp),
                        style: _ui(11, w: FontWeight.w500, c: _T.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${(d.inDays / 7).floor()}w ago';
  }

  // ─── DETAIL DIALOG ──────────────────────────────────────────────────
  void _showOrderDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Container(
          width: 480,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _OrderDetailPanel(
              order: order,
              onRefresh: () {
                _fetchOrders();
                Navigator.pop(context);
                setState(() => _selectedOrder = null);
              },
              onClose: () {
                Navigator.pop(context);
                setState(() => _selectedOrder = null);
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── REUSABLE WIDGETS ─────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _T.primary : _T.surface,
          border: Border.all(color: isSelected ? _T.primary : _T.line),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _T.primary.withOpacity(0.22),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: _ui(
            12,
            w: FontWeight.w800,
            c: isSelected ? Colors.white : _T.muted,
          ),
        ),
      ),
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _IconBtn({required this.icon, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: onTap == null ? _T.muted2 : color),
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    late Color fg, bg;
    switch (status) {
      case OrderStatus.completed:
        fg = _T.success;
        bg = _T.successBg;
        break;
      case OrderStatus.cancelled:
        fg = _T.danger;
        bg = _T.dangerBg;
        break;
      case OrderStatus.deleted:
        fg = _T.muted;
        bg = _T.surfaceAlt;
        break;
      case OrderStatus.active:
        fg = _T.warn;
        bg = _T.warnBg;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.name.toUpperCase(), style: _eyebrow(9, c: fg)),
    );
  }
}

// ─── DETAIL / RECEIPT PANEL ───────────────────────────────────────────
class _OrderDetailPanel extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onRefresh, onClose;
  const _OrderDetailPanel({
    required this.order,
    required this.onRefresh,
    required this.onClose,
  });
  @override
  State<_OrderDetailPanel> createState() => _OrderDetailPanelState();
}

class _OrderDetailPanelState extends State<_OrderDetailPanel> {
  final _supabase = Supabase.instance.client;
  bool _isProcessing = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isProcessing = true);
    try {
      final update = <String, dynamic>{'order_status': status};
      if (status == 'completed') update['payment_status'] = 'paid';
      await _supabase.from('orders').update(update).eq('id', widget.order.id);
      widget.onRefresh();
      _toast('Order marked as $status', _T.success);
    } catch (e) {
      _toast('Error: $e', _T.danger);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _hardDelete() async {
    setState(() => _isProcessing = true);
    try {
      await _supabase
          .from('order_items')
          .delete()
          .eq('order_id', widget.order.id);
      await _supabase.from('orders').delete().eq('id', widget.order.id);
      widget.onRefresh();
      _toast('Order permanently deleted', _T.danger);
    } catch (e) {
      _toast('Delete error: $e', _T.danger);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _editOrder() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UpgradedPOS(editOrderId: widget.order.id),
      ),
    );
    if (updated == true) widget.onRefresh();
  }

  void _toast(String msg, Color c) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: _ui(13, w: FontWeight.w600, c: Colors.white),
        ),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return const Center(
        child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3),
      );
    }
    final order = widget.order;
    final isDeleted = order.status == OrderStatus.deleted;

    return Column(
      children: [
        _detailHeader(),
        Expanded(
          child: Container(
            color: _T.bg,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Opacity(
                opacity: isDeleted ? 0.5 : 1.0,
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: _T.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_T.primary, _T.primaryD],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'ZAYTOUNA PARK',
                              style: _eyebrow(13, c: _T.ink).copyWith(
                                decoration: isDeleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Receipt • ${order.displayId}',
                              style: _ui(11.5, w: FontWeight.w600, c: _T.muted),
                            ),
                            Text(
                              order.timestamp.toString().substring(0, 16),
                              style: _num(11, w: FontWeight.w600, c: _T.muted2),
                            ),
                            SizedBox(height: 10.h),
                            _PaymentBadge(status: order.paymentStatus),
                          ],
                        ),
                      ),
                      SizedBox(height: 18.h),
                      const _DashedDivider(),
                      SizedBox(height: 14.h),
                      ...order.items.map(
                        (i) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '${i.quantity}×',
                                  style: _num(
                                    13,
                                    w: FontWeight.w800,
                                    c: _T.muted,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  i.name,
                                  style: _ui(13, w: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '\$${i.total.toStringAsFixed(2)}',
                                style: _num(13, w: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      const _DashedDivider(),
                      SizedBox(height: 14.h),
                      _totalRow(
                        'Subtotal',
                        '\$${order.subtotal.toStringAsFixed(2)}',
                      ),
                      if (order.discountAmount > 0)
                        _totalRow(
                          'Discount',
                          '-\$${order.discountAmount.toStringAsFixed(2)}',
                          color: _T.danger,
                        ),
                      _totalRow(
                        'Tax',
                        '+\$${order.taxAmount.toStringAsFixed(2)}',
                      ),
                      SizedBox(height: 12.h),
                      const _DashedDivider(),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL', style: _eyebrow(11, c: _T.ink)),
                          Text(
                            '\$${order.totalAmount.toStringAsFixed(2)}',
                            style: _num(20, w: FontWeight.w900, c: _T.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _actions(),
      ],
    );
  }

  Widget _detailHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(
      color: _T.surface,
      border: Border(bottom: BorderSide(color: _T.line)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Order Details', style: _ui(16, w: FontWeight.w800)),
        _IconBtn(
          icon: Icons.close_rounded,
          color: _T.muted,
          onTap: widget.onClose,
        ),
      ],
    ),
  );

  Widget _totalRow(String label, String val, {Color? color}) => Padding(
    padding: EdgeInsets.symmetric(vertical: 3.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: _ui(12, w: FontWeight.w600, c: _T.muted),
        ),
        Text(
          val,
          style: _num(13, w: FontWeight.w800, c: color ?? _T.ink),
        ),
      ],
    ),
  );

  Widget _actions() {
    final order = widget.order;
    final actions = <Widget>[];

    if (order.status == OrderStatus.deleted) {
      actions.add(
        _actionBtn(
          'Restore Order',
          Icons.restore_page_rounded,
          _T.warn,
          () => _updateStatus('cancelled'),
          filled: false,
        ),
      );
    }
    if (order.status == OrderStatus.active ||
        order.status == OrderStatus.completed) {
      actions.add(
        _actionBtn(
          'Edit Order',
          Icons.edit_note_rounded,
          _T.info,
          _editOrder,
          filled: false,
        ),
      );
      actions.add(
        _actionBtn(
          order.status == OrderStatus.active ? 'Print Bill' : 'Print Receipt',
          Icons.print_rounded,
          _T.primary,
          () async {
            try {
              await ReceiptPrinter.printReceipt(order);
              _toast('Receipt sent to printer', _T.success);
            } catch (e) {
              _toast('Print failed: $e', _T.danger);
            }
          },
          filled: true,
        ),
      );
    }
    if (order.status == OrderStatus.active) {
      actions.add(
        _actionBtn(
          'Cancel Order',
          Icons.close_rounded,
          _T.ink2,
          () => _updateStatus('cancelled'),
          filled: false,
        ),
      );
    }
    if (order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.completed) {
      actions.add(
        _actionBtn(
          'Move to Trash',
          Icons.delete_outline_rounded,
          _T.danger,
          () => _updateStatus('deleted'),
          filled: false,
        ),
      );
    }
    if (order.status == OrderStatus.deleted) {
      actions.add(
        _actionBtn(
          'Delete Permanently',
          Icons.delete_forever_rounded,
          _T.danger,
          () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: _T.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: _T.danger),
                    SizedBox(width: 8.w),
                    Text(
                      'Permanently Delete?',
                      style: _ui(16, w: FontWeight.w800),
                    ),
                  ],
                ),
                content: Text(
                  'This will wipe the order and its items from the database forever. This cannot be undone.',
                  style: _ui(13, w: FontWeight.w500, c: _T.ink2),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Cancel',
                      style: _ui(13, w: FontWeight.w700, c: _T.muted),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.danger,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      'Destroy Record',
                      style: _ui(13, w: FontWeight.w800, c: Colors.white),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) _hardDelete();
          },
          filled: false,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        color: _T.surface,
        border: Border(top: BorderSide(color: _T.line)),
      ),
      child: Column(
        children: actions
            .map(
              (a) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: a,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    required bool filled,
  }) => SizedBox(
    width: double.infinity,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: filled
                ? LinearGradient(colors: [color, color.withOpacity(0.82)])
                : null,
            color: filled ? null : _T.surface,
            border: Border.all(
              color: filled ? color : color.withOpacity(0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: filled ? Colors.white : color),
              const SizedBox(width: 8),
              Text(
                label,
                style: _ui(
                  13,
                  w: FontWeight.w800,
                  c: filled ? Colors.white : color,
                  ls: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PaymentBadge extends StatelessWidget {
  final String status;
  const _PaymentBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final paid = status == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: paid ? _T.successBg : _T.dangerBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: paid ? _T.success : _T.danger),
      ),
      child: Text(
        status.toUpperCase(),
        style: _eyebrow(10, c: paid ? _T.success : _T.danger),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, c) {
      const dashW = 5.0;
      final count = (c.maxWidth / (dashW * 2)).floor();
      return Flex(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        direction: Axis.horizontal,
        children: List.generate(
          count,
          (_) => const SizedBox(
            width: dashW,
            height: 1,
            child: DecoratedBox(decoration: BoxDecoration(color: _T.line)),
          ),
        ),
      );
    },
  );
}
