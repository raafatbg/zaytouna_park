// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Terminal/terminalscreen.dart';

// 👇 UNCOMMENTED AND FIXED IMPORT
import 'package:zaytouna_park/Features/cashier/Utils/receipt_printer.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
//  ORDERS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

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

  // Modern Color Palette
  final Color bg = const Color(0xFFF1F5F9);
  final Color primaryBlue = const Color(0xFF2563EB);
  final Color successGreen = const Color(0xFF10B981);
  final Color dangerRed = const Color(0xFFEF4444);
  final Color textDark = const Color(0xFF1E293B);
  final Color textMuted = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // ─── DATABASE FETCH ───
  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('orders')
          .select('''
        id, 
        created_at, 
        order_status, 
        payment_status, 
        subtotal, 
        discount_amount, 
        tax_amount, 
        total_amount,
        customers(name), 
        restaurant_tables(name), 
        facilities(name),
        order_types(name),
        order_items(
          id, quantity, unit_price, item_total,
          menu_items(name), 
          inventory_items(name)
        )
      ''')
          .order('created_at', ascending: false);

      final List<OrderModel> parsedOrders = (res as List).map((o) {
        OrderStatus status = OrderStatus.active;
        if (o['order_status'] == 'completed') status = OrderStatus.completed;
        if (o['order_status'] == 'cancelled') status = OrderStatus.cancelled;
        if (o['order_status'] == 'deleted') {
          status = OrderStatus.deleted;
        }

        List<OrderItem> items = [];
        if (o['order_items'] != null) {
          for (var item in o['order_items']) {
            String itemName =
                item['menu_items']?['name'] ??
                item['inventory_items']?['name'] ??
                'Unknown Item';

            items.add(
              OrderItem(
                id: item['id'],
                name: itemName,
                quantity: item['quantity'] ?? 1,
                price: (item['unit_price'] as num).toDouble(),
                total: (item['item_total'] as num).toDouble(),
              ),
            );
          }
        }

        // NEW: Smart Fallback Logic for new Tables Schema
        String? tableName = o['restaurant_tables']?['name'];
        String? facilityName = o['facilities']?['name'];
        String orderTypeName = o['order_types']?['name'] ?? 'Takeaway';

        String displayLocation = tableName ?? facilityName ?? orderTypeName;

        return OrderModel(
          id: o['id'],
          timestamp: DateTime.parse(o['created_at']).toLocal(),
          status: status,
          paymentStatus: o['payment_status'] ?? 'unpaid',
          customerName: o['customers']?['name'] ?? 'Walk-in Guest',
          tableNumber: displayLocation,
          subtotal: (o['subtotal'] as num?)?.toDouble() ?? 0.0,
          discountAmount: (o['discount_amount'] as num?)?.toDouble() ?? 0.0,
          taxAmount: (o['tax_amount'] as num?)?.toDouble() ?? 0.0,
          totalAmount: (o['total_amount'] as num?)?.toDouble() ?? 0.0,
          items: items,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _orders = parsedOrders;
          if (_selectedOrder != null) {
            // FIXED: Better selection matching for Dart 3
            _selectedOrder = _orders
                .where((o) => o.id == _selectedOrder!.id)
                .firstOrNull;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database Error: $e'),
            backgroundColor: dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _buildHeader(isWide),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryBlue))
                : RefreshIndicator(
                    color: primaryBlue,
                    onRefresh: _fetchOrders,
                    child: _buildOrderList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, color: primaryBlue, size: 28.sp),
          SizedBox(width: 12.w),
          Text(
            "Order History",
            style: GoogleFonts.inter(
              fontSize: isWide ? 22.sp : 18.sp,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const Spacer(),
          _filterChip("All"),
          SizedBox(width: 8.w),
          _filterChip("Active"),
          SizedBox(width: 8.w),
          _filterChip("Completed"),
          SizedBox(width: 8.w),
          _filterChip("Cancelled"),
          SizedBox(width: 8.w),
          _filterChip("Deleted"),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final bool isSelected = _filter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = label;
          _selectedOrder = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : textMuted,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    final filteredOrders = _orders.where((order) {
      if (_filter == 'All') {
        return order.status != OrderStatus.deleted;
      }
      if (_filter == 'Active') return order.status == OrderStatus.active;
      if (_filter == 'Completed') return order.status == OrderStatus.completed;
      if (_filter == 'Cancelled') return order.status == OrderStatus.cancelled;
      if (_filter == 'Deleted') {
        return order.status == OrderStatus.deleted;
      }
      return true;
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64.sp, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text(
              'No orders found',
              style: GoogleFonts.inter(
                color: textMuted,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(24.w),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final bool isSelected = _selectedOrder?.id == order.id;
        final bool isDeleted = order.status == OrderStatus.deleted;

        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? primaryBlue : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () {
                setState(() => _selectedOrder = order);
                _showOrderDialog(order);
              },
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Opacity(
                  opacity: isDeleted ? 0.6 : 1.0,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDeleted
                              ? Icons.delete_outline_rounded
                              : (order.tableNumber.toLowerCase().contains(
                                      'takeaway',
                                    ) ||
                                    order.tableNumber.toLowerCase().contains(
                                      'delivery',
                                    ))
                              ? Icons.shopping_bag_outlined
                              : Icons.table_restaurant_outlined,
                          color: textMuted,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  order.displayId,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.sp,
                                    color: isDeleted ? textMuted : textDark,
                                    decoration: isDeleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                _statusBadge(order.status),
                                SizedBox(width: 8.w),
                                if (order.paymentStatus == 'unpaid' &&
                                    order.status != OrderStatus.deleted)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: dangerRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      'UNPAID',
                                      style: GoogleFonts.inter(
                                        color: dangerRed,
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              "${order.tableNumber} • ${order.customerName}",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "\$${order.totalAmount.toStringAsFixed(2)}",
                            style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.w800,
                              color: isDeleted ? textMuted : textDark,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _getTimeAgo(order.timestamp),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: textMuted,
                            ),
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
      },
    );
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  Widget _statusBadge(OrderStatus status) {
    Color color;
    Color bgColor;

    switch (status) {
      case OrderStatus.completed:
        color = successGreen;
        bgColor = successGreen.withOpacity(0.1);
        break;
      case OrderStatus.cancelled:
        color = dangerRed;
        bgColor = dangerRed.withOpacity(0.1);
        break;
      case OrderStatus.deleted:
        color = Colors.grey.shade700;
        bgColor = Colors.grey.shade200;
        break;
      case OrderStatus.active:
        color = Colors.orange.shade700;
        bgColor = Colors.orange.withOpacity(0.1);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showOrderDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Container(
          width: 500, // Constrain width so it looks like a receipt panel
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
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

// ─────────────────────────────────────────────────────────────────────────────
//  ORDER DETAIL / RECEIPT PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _OrderDetailPanel extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

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

  final Color primaryBlue = const Color(0xFF2563EB);
  final Color successGreen = const Color(0xFF10B981);
  final Color dangerRed = const Color(0xFFEF4444);

  // ─── DB ACTIONS ───
  Future<void> _updateStatus(String status) async {
    setState(() => _isProcessing = true);
    try {
      final updateData = {'order_status': status};

      if (status == 'completed') {
        updateData['payment_status'] = 'paid';
      }

      await _supabase
          .from('orders')
          .update(updateData)
          .eq('id', widget.order.id);

      widget.onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order marked as $status!'),
          backgroundColor: successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: dangerRed),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _hardDeleteOrder() async {
    setState(() => _isProcessing = true);
    try {
      await _supabase
          .from('order_items')
          .delete()
          .eq('order_id', widget.order.id);
      await _supabase.from('orders').delete().eq('id', widget.order.id);

      widget.onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order permanently destroyed!'),
          backgroundColor: dangerRed,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete Error: $e'), backgroundColor: dangerRed),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _editOrder() async {
    final bool? wasUpdated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpgradedPOS(editOrderId: widget.order.id),
      ),
    );

    if (wasUpdated == true) {
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    final bool isDeleted = widget.order.status == OrderStatus.deleted;

    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          _buildReceiptHeader(),
          Expanded(
            child: Container(
              color: const Color(0xFFFAFAFA),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(32.w),
                child: Opacity(
                  opacity: isDeleted ? 0.5 : 1.0,
                  child: Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.storefront_rounded,
                                size: 40.sp,
                                color: Colors.black87,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "ZAYTOUNA PARK",
                                style: GoogleFonts.syne(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20.sp,
                                  letterSpacing: 1.5,
                                  decoration: isDeleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                "Order Receipt • ${widget.order.displayId}",
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade500,
                                  fontSize: 12.sp,
                                ),
                              ),
                              Text(
                                widget.order.timestamp.toString().substring(
                                  0,
                                  16,
                                ),
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade400,
                                  fontSize: 11.sp,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.order.paymentStatus == 'paid'
                                      ? successGreen.withOpacity(0.1)
                                      : dangerRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: widget.order.paymentStatus == 'paid'
                                        ? successGreen
                                        : dangerRed,
                                  ),
                                ),
                                child: Text(
                                  widget.order.paymentStatus.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: widget.order.paymentStatus == 'paid'
                                        ? successGreen
                                        : dangerRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),
                        _dashedDivider(),
                        SizedBox(height: 16.h),
                        ...widget.order.items.map(
                          (item) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${item.quantity}x",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Text(
                                  "\$${item.total.toStringAsFixed(2)}",
                                  style: GoogleFonts.jetBrainsMono(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _dashedDivider(),
                        SizedBox(height: 16.h),
                        _rowTotal(
                          "Subtotal",
                          "\$${widget.order.subtotal.toStringAsFixed(2)}",
                        ),
                        if (widget.order.discountAmount > 0)
                          _rowTotal(
                            "Discount",
                            "-\$${widget.order.discountAmount.toStringAsFixed(2)}",
                            color: dangerRed,
                          ),
                        _rowTotal(
                          "Tax",
                          "+\$${widget.order.taxAmount.toStringAsFixed(2)}",
                        ),
                        SizedBox(height: 16.h),
                        _dashedDivider(),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "TOTAL",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w900,
                                fontSize: 18.sp,
                              ),
                            ),
                            Text(
                              "\$${widget.order.totalAmount.toStringAsFixed(2)}",
                              style: GoogleFonts.jetBrainsMono(
                                fontWeight: FontWeight.w900,
                                fontSize: 20.sp,
                                color: primaryBlue,
                              ),
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
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Order Details",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 18.sp,
              color: Colors.black87,
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(Icons.close, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade300),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _rowTotal(String label, String value, {Color? color}) => Padding(
    padding: EdgeInsets.symmetric(vertical: 4.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    ),
  );

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          if (widget.order.status == OrderStatus.deleted)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50,
                    foregroundColor: Colors.orange.shade700,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () => _updateStatus('cancelled'),
                  icon: const Icon(Icons.restore_page_rounded),
                  label: Text(
                    "Restore Order",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
            ),

          if (widget.order.status == OrderStatus.active ||
              widget.order.status == OrderStatus.completed)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: primaryBlue,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: _editOrder,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(
                    "Edit Order",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
            ),

          if (widget.order.status == OrderStatus.completed ||
              widget.order.status == OrderStatus.active)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await ReceiptPrinter.printReceipt(widget.order);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Receipt sent to printer!'),
                          backgroundColor: successGreen,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to print: $e'),
                          backgroundColor: dangerRed,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.print_rounded, color: Colors.white),
                  label: Text(
                    widget.order.status == OrderStatus.active
                        ? "Print Bill"
                        : "Print Receipt",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
            ),

          if (widget.order.status == OrderStatus.active)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () => _updateStatus('cancelled'),
                  icon: const Icon(Icons.close_rounded, color: Colors.black87),
                  label: Text(
                    "Cancel Order",
                    style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
            ),

          if (widget.order.status == OrderStatus.cancelled ||
              widget.order.status == OrderStatus.completed)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dangerRed,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    side: BorderSide(color: dangerRed.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () => _updateStatus('deleted'),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    "Move to Trash",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
            ),

          if (widget.order.status == OrderStatus.deleted)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: dangerRed,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () async {
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        title: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: dangerRed),
                            SizedBox(width: 8.w),
                            const Text("Permanently Delete?"),
                          ],
                        ),
                        content: const Text(
                          "This will wipe the order and its items from the database forever. This cannot be undone.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(
                              "Cancel",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dangerRed,
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              "Destroy Record",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) _hardDeleteOrder();
                  },
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: Text(
                    "Delete Permanently",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
