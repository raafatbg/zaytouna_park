// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum OrderStatus { pending, completed, cancelled }

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({required this.name, required this.quantity, required this.price});
}

class OrderModel {
  final String id;
  final String tableNumber;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime timestamp;
  final String customerName;

  OrderModel({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.status,
    required this.timestamp,
    required this.customerName,
  });

  double get total =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));
}

// ─────────────────────────────────────────────────────────────────────────────
//  DUMMY DATA
// ─────────────────────────────────────────────────────────────────────────────

final List<OrderModel> _dummyOrders = [
  OrderModel(
    id: "ORD-7721",
    tableNumber: "Table 04",
    customerName: "John Doe",
    status: OrderStatus.pending,
    timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    items: [
      OrderItem(name: "Grilled Chicken", quantity: 2, price: 12.50),
      OrderItem(name: "Hummus Large", quantity: 1, price: 6.00),
      OrderItem(name: "Fresh Orange Juice", quantity: 2, price: 4.50),
    ],
  ),
  OrderModel(
    id: "ORD-7722",
    tableNumber: "Takeaway",
    customerName: "Alice Smith",
    status: OrderStatus.completed,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    items: [
      OrderItem(name: "Beef Burger", quantity: 1, price: 10.00),
      OrderItem(name: "French Fries", quantity: 1, price: 3.50),
    ],
  ),
  OrderModel(
    id: "ORD-7723",
    tableNumber: "Table 12",
    customerName: "Bob Johnson",
    status: OrderStatus.pending,
    timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    items: [
      OrderItem(name: "Fish & Chips", quantity: 1, price: 15.00),
      OrderItem(name: "Coleslaw", quantity: 1, price: 3.00),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  ORDERS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderModel? _selectedOrder;
  String _filter = 'All';

  final Color bg = const Color(0xFFF8FAFC);
  final Color red = const Color(0xFFFF3B3B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 900;

          return Column(
            children: [
              _buildHeader(isWide),
              Expanded(
                child: Row(
                  children: [
                    Expanded(flex: 3, child: _buildOrderList()),
                    if (isWide && _selectedOrder != null)
                      Expanded(
                        flex: 2,
                        child: _OrderDetailPanel(
                          order: _selectedOrder!,
                          onClose: () => setState(() => _selectedOrder = null),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Text(
            "Orders",
            style: GoogleFonts.syne(
              fontSize: isWide ? 22.sp : 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          _filterChip("All"),
          SizedBox(width: 8.w),
          _filterChip("Active"),
          SizedBox(width: 8.w),
          _filterChip("Completed"),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final bool isSelected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? red : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    // Filter orders based on selected filter
    final filteredOrders = _dummyOrders.where((order) {
      if (_filter == 'All') return true;
      if (_filter == 'Active') {
        return order.status != OrderStatus.completed &&
            order.status != OrderStatus.cancelled;
      }
      if (_filter == 'Completed') return order.status == OrderStatus.completed;
      return true;
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Text(
          'No orders found',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final bool isSelected = _selectedOrder?.id == order.id;

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? red : const Color(0xFFE2E8F0),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _selectedOrder = order);
                if (MediaQuery.of(context).size.width < 900) {
                  _showMobileReceipt(order);
                }
              },
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    // Left content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                order.tableNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              _statusBadge(order.status),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "${order.items.length} items • ${order.id}",
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Right content - fixed width to prevent overflow
                    SizedBox(
                      width: 100.w,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "\$${order.total.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: red,
                              fontSize: 13.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${DateTime.now().difference(order.timestamp).inMinutes}m ago",
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusBadge(OrderStatus status) {
    Color color = Colors.orange;
    if (status == OrderStatus.completed) color = Colors.green;
    if (status == OrderStatus.cancelled) color = Colors.red;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showMobileReceipt(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (_, controller) => _OrderDetailPanel(
          order: order,
          onClose: () => Navigator.pop(context),
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
  final VoidCallback onClose;

  const _OrderDetailPanel({required this.order, required this.onClose});

  @override
  State<_OrderDetailPanel> createState() => _OrderDetailPanelState();
}

class _OrderDetailPanelState extends State<_OrderDetailPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          _buildReceiptHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "ZAYTOUNA PARK",
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w900,
                            fontSize: 18.sp,
                          ),
                        ),
                        const Text(
                          "Order Receipt",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  const Divider(thickness: 1, color: Colors.black12),
                  ...widget.order.items.map(
                    (item) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Row(
                        children: [
                          Text(
                            "${item.quantity}x",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            "\$${(item.price * item.quantity).toStringAsFixed(2)}",
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(thickness: 1, color: Colors.black12),
                  SizedBox(height: 10.h),
                  _rowTotal(
                    "Subtotal",
                    "\$${widget.order.total.toStringAsFixed(2)}",
                  ),
                  _rowTotal("Tax (0%)", "\$0.00"),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TOTAL",
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w900,
                          fontSize: 16.sp,
                        ),
                      ),
                      Text(
                        "\$${widget.order.total.toStringAsFixed(2)}",
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w900,
                          fontSize: 16.sp,
                          color: const Color(0xFFFF3B3B),
                        ),
                      ),
                    ],
                  ),
                ],
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
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Order Details",
            style: GoogleFonts.syne(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _rowTotal(String label, String value) => Padding(
    padding: EdgeInsets.symmetric(vertical: 4.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B3B),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Receipt sent to printer!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.print, color: Colors.white),
              label: const Text(
                "Print Receipt",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          if (widget.order.status == OrderStatus.pending)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order marked as completed!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  "Complete Order",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (widget.order.status != OrderStatus.cancelled)
            Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: const BorderSide(color: Color(0xFFFF3B3B)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order cancelled!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text(
                    "Cancel Order",
                    style: TextStyle(
                      color: Color(0xFFFF3B3B),
                      fontWeight: FontWeight.bold,
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
