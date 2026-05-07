// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── MODELS ─────────────────────────────────────────────────────────────

class PosCategory {
  final int id;
  final String name;

  PosCategory({required this.id, required this.name});

  factory PosCategory.fromJson(Map<String, dynamic> json) {
    return PosCategory(id: json['id'] as int, name: json['name'] as String);
  }
}

class PosMenuItem {
  final int id;
  final int categoryId;
  final String name;
  final double price;
  final bool requiresPreparation;

  PosMenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.requiresPreparation,
  });

  factory PosMenuItem.fromJson(Map<String, dynamic> json) {
    return PosMenuItem(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      requiresPreparation: json['requires_preparation'] as bool? ?? false,
    );
  }
}

class CartItem {
  final PosMenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  double get total => menuItem.price * quantity;
}

// ─── POS SCREEN ─────────────────────────────────────────────────────────

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isCheckingOut = false;

  List<PosCategory> _categories = [];
  List<PosMenuItem> _menuItems = [];
  final List<CartItem> _cart = [];

  PosCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch Categories
      final catsRes = await _supabase
          .from('categories')
          .select('id, name')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      // Fetch Menu Items
      final itemsRes = await _supabase
          .from('menu_items')
          .select('id, category_id, name, price, requires_preparation')
          .eq('is_available', true);

      if (mounted) {
        setState(() {
          _categories = (catsRes as List)
              .map((c) => PosCategory.fromJson(c))
              .toList();
          _menuItems = (itemsRes as List)
              .map((i) => PosMenuItem.fromJson(i))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching POS data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading menu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── CART LOGIC ───

  void _addToCart(PosMenuItem item) {
    setState(() {
      final existingIndex = _cart.indexWhere((c) => c.menuItem.id == item.id);
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(menuItem: item));
      }
    });
  }

  void _incrementQty(int index) {
    setState(() => _cart[index].quantity++);
  }

  void _decrementQty(int index) {
    setState(() {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _selectedCategory = null;
    });
  }

  double get _cartTotal => _cart.fold(0, (sum, item) => sum + item.total);

  // ─── CHECKOUT LOGIC ───

  Future<void> _processCheckout() async {
    if (_cart.isEmpty) return;
    setState(() => _isCheckingOut = true);

    try {
      // 1. Create the Order
      final orderRes = await _supabase
          .from('orders')
          .insert({
            'total_amount': _cartTotal,
            'order_status': 'active',
            // Optional: 'created_by_id': userId (if mapped to staff properly)
          })
          .select('id')
          .single();

      final orderId = orderRes['id'] as int;

      // 2. Create Order Items with correct status
      final orderItemsData = _cart.map((cartItem) {
        return {
          'order_id': orderId,
          'menu_item_id': cartItem.menuItem.id,
          'quantity': cartItem.quantity,
          'unit_price': cartItem.menuItem.price,
          'item_total': cartItem.total,
          // CRITICAL LOGIC: Retail = completed, Kitchen = pending_kitchen
          'item_status': cartItem.menuItem.requiresPreparation
              ? 'pending_kitchen'
              : 'completed',
        };
      }).toList();

      await _supabase.from('order_items').insert(orderItemsData);

      // 3. Success
      if (mounted) {
        _clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Color(0xFF28A745),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Checkout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  // ─── BUILD ───

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── LEFT PANEL (Cart & Checkout) ───
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildTopToolbar(),
                            _buildSearchBar(),
                            _buildCartTableHeaders(),
                            _cart.isEmpty
                                ? _buildEmptyCartArea()
                                : _buildCartItems(),
                            _buildSummarySection(),
                            _buildCheckoutButton(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ─── RIGHT PANEL (Categories / Items) ───
                    Expanded(
                      flex: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRightPanelHeader(),
                            Expanded(
                              child: _selectedCategory == null
                                  ? _buildCategoryGrid()
                                  : _buildItemsGrid(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── LEFT PANEL WIDGETS ─────────────────────────────────────────────

  Widget _buildTopToolbar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _ActionButton(
            icon: Icons.dashboard,
            label: "Dashboard",
            bgColor: const Color(0xFF28A745),
            textColor: Colors.white,
            iconColor: Colors.white,
            onTap: () => Navigator.pop(context),
          ),
          _ActionButton(
            icon: Icons.restore,
            label: "Reset",
            bgColor: const Color(0xFFDC3545),
            textColor: Colors.white,
            iconColor: Colors.white,
            onTap: _clearCart,
          ),
          _ActionButton(
            icon: Icons.person_outline,
            label: "Customer",
            bgColor: Colors.white,
            textColor: Colors.grey.shade700,
            iconColor: Colors.grey.shade600,
          ),
          _ActionButton(
            icon: Icons.table_restaurant_outlined,
            label: "Choose Table",
            bgColor: Colors.white,
            textColor: Colors.grey.shade700,
            iconColor: Colors.grey.shade600,
            showDropdown: true,
          ),
          _ActionButton(
            label: "Eat In",
            bgColor: Colors.white,
            textColor: Colors.grey.shade700,
            showDropdown: true,
          ),
          _ActionButton(
            icon: Icons.meeting_room_outlined,
            label: "Choose Room",
            bgColor: Colors.white,
            textColor: Colors.grey.shade700,
            iconColor: Colors.grey.shade600,
            showDropdown: true,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              "\$ UNPAID ˅",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.qr_code_scanner,
                color: Colors.grey.shade500,
                size: 20,
              ),
            ),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Scan barcode, search by name or SKU",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartTableHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerText("Product")),
          Expanded(flex: 1, child: _headerText("Quantity", center: true)),
          Expanded(flex: 1, child: _headerText("Total", alignRight: true)),
          const SizedBox(width: 24), // For delete icon spacing
        ],
      ),
    );
  }

  Widget _headerText(
    String text, {
    bool center = false,
    bool alignRight = false,
  }) {
    return Text(
      text,
      textAlign: center
          ? TextAlign.center
          : (alignRight ? TextAlign.right : TextAlign.left),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildEmptyCartArea() {
    return Expanded(
      child: Center(
        child: Text(
          "No Products added...",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildCartItems() {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _cart.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final cartItem = _cart[index];
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    cartItem.menuItem.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => _decrementQty(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.remove, size: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '${cartItem.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      InkWell(
                        onTap: () => _incrementQty(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '\$${cartItem.total.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() => _cart.removeAt(index));
                  },
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      children: [
        Divider(height: 1, color: Colors.grey.shade300),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryText("Customer: N/A"),
                  _summaryText(
                    "Subtotal",
                    value: "\$ ${_cartTotal.toStringAsFixed(2)}",
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [_summaryText("Table : N/A")],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryText("Delivery Charge: \$\n0.00"),
                  _summaryText(
                    "Discount",
                    value: "\$ 0.00",
                    valueColor: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          color: const Color(0xFFE0F7FA),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryText(
                    "TAX AMOUNT: \$ 0.00",
                    isBold: true,
                    color: Colors.blueGrey.shade700,
                  ),
                  const Text(
                    "Total",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryText(
                    "TVA 0%: \$ 0.00",
                    isBold: true,
                    color: Colors.blueGrey.shade700,
                  ),
                  Text(
                    "\$ ${_cartTotal.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryText(
    String label, {
    String? value,
    Color? valueColor,
    bool isBold = false,
    Color? color,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value != null ? "$label: " : label,
            style: TextStyle(
              color: color ?? Colors.grey.shade600,
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (value != null)
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor ?? Colors.grey.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _cart.isEmpty || _isCheckingOut ? null : _processCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF28A745),
          disabledBackgroundColor: Colors.grey.shade400,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
        ),
        child: _isCheckingOut
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "CHECKOUT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  // ─── RIGHT PANEL WIDGETS ────────────────────────────────────────────

  Widget _buildRightPanelHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (_selectedCategory != null) ...[
            InkWell(
              onTap: () => setState(() => _selectedCategory = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            _selectedCategory == null ? "Categories" : _selectedCategory!.name,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    if (_categories.isEmpty) {
      return Center(
        child: Text(
          "No categories found.",
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        return InkWell(
          onTap: () => setState(() => _selectedCategory = cat),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                cat.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsGrid() {
    final catItems = _menuItems
        .where((i) => i.categoryId == _selectedCategory!.id)
        .toList();

    if (catItems.isEmpty) {
      return Center(
        child: Text(
          "No items in this category.",
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: catItems.length,
      itemBuilder: (context, index) {
        final item = catItems[index];
        return InkWell(
          onTap: () => _addToCart(item),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF28A745),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── CUSTOM ACTION BUTTON ─────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color? iconColor;
  final bool showDropdown;
  final VoidCallback? onTap;

  const _ActionButton({
    this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.iconColor,
    this.showDropdown = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: bgColor == Colors.white ? Colors.grey.shade300 : bgColor,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showDropdown) ...[
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: textColor, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
