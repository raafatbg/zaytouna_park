// ignore_for_file: deprecated_member_use, use_build_context_synchronously, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── CONSTANTS ────────────────────────────────────────────────────────
const double EXCHANGE_RATE = 90000.0;
const Color ZAYTOUNA_GREEN = Color(0xFF22C55E);
const Color ZAYTOUNA_BLUE = Color(0xFF1E40AF);
const Color BG_COLOR = Color(0xFFF1F5F9);

// ─── UNIFIED MODELS ───────────────────────────────────────────────────

class PosCategory {
  final int id;
  final String name;
  final bool isInventoryCategory; // Differentiates Menu vs Inventory categories

  PosCategory({
    required this.id,
    required this.name,
    required this.isInventoryCategory,
  });
}

class PosProduct {
  final int id;
  final int categoryId;
  final String name;
  final double price;
  final bool requiresPrep;
  final bool
  isInventoryItem; // Differentiates Kitchen food vs Retail goods (Pepsi)

  PosProduct({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.requiresPrep,
    required this.isInventoryItem,
  });
}

class CartItem {
  final PosProduct product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get total => product.price * quantity;
}

// Relational Models
class PosCustomer {
  final int id;
  final String name;
  PosCustomer({required this.id, required this.name});
}

class PosOrderType {
  final int id;
  final String name;
  PosOrderType({required this.id, required this.name});
}

class PosFacility {
  final int id;
  final String name;
  PosFacility({required this.id, required this.name});
}

// ─── MAIN POS SCREEN ──────────────────────────────────────────────────

class UpgradedPOS extends StatefulWidget {
  const UpgradedPOS({super.key});

  @override
  State<UpgradedPOS> createState() => _UpgradedPOSState();
}

class _UpgradedPOSState extends State<UpgradedPOS> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  // Unified Data Lists
  List<PosCategory> _allCategories = [];
  List<PosProduct> _allProducts = [];

  // Relational Lists
  List<PosCustomer> _customers = [];
  List<PosOrderType> _orderTypes = [];
  List<PosFacility> _facilities = [];

  // State
  final List<CartItem> _cart = [];
  PosCategory? _selectedCategory;
  PosCustomer? _selectedCustomer;
  PosOrderType? _selectedOrderType;
  PosFacility? _selectedFacility;

  double get _cartTotalUSD => _cart.fold(0, (sum, item) => sum + item.total);

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch EVERYTHING in parallel
      final results = await Future.wait([
        _supabase.from('categories').select('id, name').eq('is_active', true),
        _supabase.from('inventory_categories').select('id, name'),
        _supabase
            .from('menu_items')
            .select('id, category_id, name, price, requires_preparation')
            .eq('is_available', true),
        _supabase
            .from('inventory_items')
            .select('id, category_id, name, selling_price'),
        _supabase.from('customers').select('id, name').order('name'),
        _supabase.from('order_types').select('id, name'),
        _supabase
            .from('facilities')
            .select('id, name')
            .eq('is_available', true),
      ]);

      List<PosCategory> combinedCategories = [];
      List<PosProduct> combinedProducts = [];

      // 2. Map Menu Categories & Items
      for (var c in results[0] as List) {
        combinedCategories.add(
          PosCategory(id: c['id'], name: c['name'], isInventoryCategory: false),
        );
      }
      for (var i in results[2] as List) {
        combinedProducts.add(
          PosProduct(
            id: i['id'],
            categoryId: i['category_id'],
            name: i['name'],
            price: (i['price'] as num).toDouble(),
            requiresPrep: i['requires_preparation'] ?? false,
            isInventoryItem: false,
          ),
        );
      }

      // 3. Map Inventory Categories & Items (Retail Goods)
      for (var c in results[1] as List) {
        combinedCategories.add(
          PosCategory(id: c['id'], name: c['name'], isInventoryCategory: true),
        );
      }
      for (var i in results[3] as List) {
        combinedProducts.add(
          PosProduct(
            id: i['id'],
            categoryId: i['category_id'],
            name: i['name'],
            price: (i['selling_price'] as num?)?.toDouble() ?? 0.0,
            requiresPrep: false,
            isInventoryItem: true,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _allCategories = combinedCategories;
          _allProducts = combinedProducts;
          _customers = (results[4] as List)
              .map((c) => PosCustomer(id: c['id'], name: c['name']))
              .toList();
          _orderTypes = (results[5] as List)
              .map((o) => PosOrderType(id: o['id'], name: o['name']))
              .toList();
          _facilities = (results[6] as List)
              .map((f) => PosFacility(id: f['id'], name: f['name']))
              .toList();

          if (_orderTypes.isNotEmpty) {
            _selectedOrderType = _orderTypes.firstWhere(
              (type) => type.name.toLowerCase().contains('takeaway'),
              orElse: () => _orderTypes.first,
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching POS data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast(
          'Data Error: Please ensure inventory_items has a "selling_price" column.',
          Colors.red,
        );
      }
    }
  }

  // ─── CART LOGIC ───
  void _addToCart(PosProduct item) {
    setState(() {
      final existingIndex = _cart.indexWhere(
        (c) =>
            c.product.id == item.id &&
            c.product.isInventoryItem == item.isInventoryItem,
      );
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(product: item));
      }
    });
  }

  void _updateQty(int index, int delta) {
    setState(() {
      _cart[index].quantity += delta;
      if (_cart[index].quantity <= 0) _cart.removeAt(index);
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _selectedCategory = null;
      _selectedFacility = null;
    });
  }

  // ─── DB CHECKOUT ROUTING ───
  Future<void> _processCheckout(String paymentMethod) async {
    if (_cart.isEmpty) return;
    if (_selectedOrderType == null) {
      _showToast('Please select an Order Type first!', Colors.orange);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: ZAYTOUNA_GREEN)),
    );

    try {
      // 1. Create Main Order
      final orderRes = await _supabase
          .from('orders')
          .insert({
            'customer_id': _selectedCustomer?.id,
            'order_type_id': _selectedOrderType?.id,
            'facility_id': _selectedFacility?.id,
            'subtotal': _cartTotalUSD,
            'total_amount': _cartTotalUSD,
            'exchange_rate': EXCHANGE_RATE,
            'order_status': 'completed',
            'payment_status': 'paid',
            'payment_method': paymentMethod.toLowerCase(),
          })
          .select('id')
          .single();

      final orderId = orderRes['id'] as int;

      // 2. Prepare ALL items for a single batch insert (Much faster and safer)
      final List<Map<String, dynamic>> orderItemsToInsert = [];

      for (var cartItem in _cart) {
        orderItemsToInsert.add({
          'order_id': orderId,
          // Route to the correct DB column based on item type
          'menu_item_id': cartItem.product.isInventoryItem
              ? null
              : cartItem.product.id,
          'inventory_item_id': cartItem.product.isInventoryItem
              ? cartItem.product.id
              : null,
          'quantity': cartItem.quantity,
          'unit_price': cartItem.product.price,
          'item_total': cartItem.total,
          'item_status': cartItem.product.requiresPrep
              ? 'pending_kitchen'
              : 'completed',
        });
      }

      // Insert the entire cart into order_items in one single database call
      await _supabase.from('order_items').insert(orderItemsToInsert);

      // 3. IF INVENTORY ITEM: Deduct from stock!
      for (var cartItem in _cart) {
        if (cartItem.product.isInventoryItem) {
          // Fetch current stock
          final stockRes = await _supabase
              .from('inventory_items')
              .select('current_quantity')
              .eq('id', cartItem.product.id)
              .single();

          final currentQty =
              (stockRes['current_quantity'] as num?)?.toDouble() ?? 0.0;

          // Update stock
          await _supabase
              .from('inventory_items')
              .update({'current_quantity': currentQty - cartItem.quantity})
              .eq('id', cartItem.product.id);
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _clearCart();
        _showToast('Order #$orderId processed successfully!', ZAYTOUNA_GREEN);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showToast('Error saving order: $e', Colors.red);
      }
    }
  }

  void _showToast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── UI BUILD ───
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BG_COLOR,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ZAYTOUNA_GREEN),
              )
            : Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTopActionToolbar(),
                          _buildCartHeader(),
                          Expanded(child: _buildCartList()),
                          _buildBillingSummary(),
                          _buildPayButton(),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMenuHeader(),
                        _buildCategoryTabs(),
                        Expanded(child: _buildItemsGrid()),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── LEFT PANEL WIDGETS ───
  Widget _buildTopActionToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Settings",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SelectorButton(
                  title: "Customer",
                  value: _selectedCustomer?.name ?? "Walk-in",
                  icon: Icons.person_outline,
                  color: ZAYTOUNA_BLUE,
                  onTap: () => _showSelectionDialog(
                    "Select Customer",
                    _customers,
                    (item) => setState(() => _selectedCustomer = item),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SelectorButton(
                  title: "Type",
                  value: _selectedOrderType?.name ?? "Select Type",
                  icon: Icons.shopping_bag_outlined,
                  color: Colors.orange.shade700,
                  onTap: () => _showSelectionDialog(
                    "Select Order Type",
                    _orderTypes,
                    (item) => setState(() => _selectedOrderType = item),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SelectorButton(
                  title: "Facility",
                  value: _selectedFacility?.name ?? "No Table",
                  icon: Icons.table_restaurant_outlined,
                  color: ZAYTOUNA_GREEN,
                  onTap: () => _showSelectionDialog(
                    "Select Facility",
                    _facilities,
                    (item) => setState(() => _selectedFacility = item),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Current Order",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          IconButton(
            onPressed: _clearCart,
            icon: const Icon(
              Icons.delete_sweep,
              color: Colors.redAccent,
              size: 28,
            ),
            tooltip: 'Clear Cart',
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    if (_cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "Cart is empty",
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _cart.length,
      separatorBuilder: (_, _) =>
          Divider(height: 16, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final item = _cart[index];
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '\$${item.product.price.toStringAsFixed(2)} each',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  _qtyBtn(Icons.remove, () => _updateQty(index, -1)),
                  Container(
                    width: 36,
                    alignment: Alignment.center,
                    child: Text(
                      '${item.quantity}',
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _qtyBtn(Icons.add, () => _updateQty(index, 1)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '\$${item.total.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: ZAYTOUNA_BLUE,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }

  Widget _buildBillingSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 2)),
      ),
      child: Column(
        children: [
          _summaryRow("Subtotal", "\$${_cartTotalUSD.toStringAsFixed(2)}"),
          _summaryRow("Tax (0%)", "\$0.00"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _summaryRow(
            "Total (USD)",
            "\$${_cartTotalUSD.toStringAsFixed(2)}",
            isTotal: true,
          ),
          _summaryRow(
            "Total (LBP)",
            "${(_cartTotalUSD * EXCHANGE_RATE).toInt()} LBP",
            isTotal: true,
            color: ZAYTOUNA_BLUE,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String val, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: isTotal ? Colors.black87 : Colors.grey.shade600,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            val,
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 14,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ZAYTOUNA_GREEN,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: _cart.isEmpty ? 0 : 4,
          ),
          onPressed: _cart.isEmpty
              ? null
              : () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _CheckoutPanel(
                      totalUSD: _cartTotalUSD,
                      onConfirm: (method) {
                        Navigator.pop(context);
                        _processCheckout(method);
                      },
                    ),
                  );
                },
          child: Text(
            "PROCEED TO CHECKOUT",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // ─── RIGHT PANEL WIDGETS (MENU) ───
  Widget _buildMenuHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(
        "POS Terminal",
        style: GoogleFonts.dmSerifDisplay(fontSize: 32, color: ZAYTOUNA_BLUE),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    if (_allCategories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _allCategories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CategoryTab(
              title: "All",
              isSelected: _selectedCategory == null,
              onTap: () => setState(() => _selectedCategory = null),
            );
          }
          final cat = _allCategories[index - 1];
          return _CategoryTab(
            title: cat.name,
            isSelected:
                _selectedCategory?.id == cat.id &&
                _selectedCategory?.isInventoryCategory ==
                    cat.isInventoryCategory,
            onTap: () => setState(() => _selectedCategory = cat),
          );
        },
      ),
    );
  }

  Widget _buildItemsGrid() {
    final displayedItems = _selectedCategory == null
        ? _allProducts
        : _allProducts
              .where(
                (i) =>
                    i.categoryId == _selectedCategory!.id &&
                    i.isInventoryItem == _selectedCategory!.isInventoryCategory,
              )
              .toList();

    if (displayedItems.isEmpty) {
      return Center(
        child: Text(
          "No items found.",
          style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 18),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: displayedItems.length,
      itemBuilder: (context, index) {
        final item = displayedItems[index];
        return InkWell(
          onTap: () => _addToCart(item),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: item.isInventoryItem
                          ? Colors.orange.withOpacity(0.1)
                          : ZAYTOUNA_GREEN.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        item.isInventoryItem
                            ? Icons.shopping_basket_rounded
                            : Icons.fastfood_rounded,
                        size: 48,
                        color: item.isInventoryItem
                            ? Colors.orange.withOpacity(0.5)
                            : ZAYTOUNA_GREEN.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: GoogleFonts.jetBrainsMono(
                            color: ZAYTOUNA_GREEN,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSelectionDialog<T>(
    String title,
    List<T> items,
    Function(T) onSelect,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: ZAYTOUNA_BLUE),
        ),
        content: SizedBox(
          width: 400,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final item = items[index];
              String name = '';
              if (item is PosCustomer) name = item.name;
              if (item is PosOrderType) name = item.name;
              if (item is PosFacility) name = item.name;

              return ListTile(
                title: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  onSelect(item);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CUSTOM WIDGETS ───
class _CategoryTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? ZAYTOUNA_BLUE : Colors.white,
          border: Border.all(
            color: isSelected ? ZAYTOUNA_BLUE : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _SelectorButton extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SelectorButton({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

// ─── CHECKOUT PANEL ───
class _CheckoutPanel extends StatefulWidget {
  final double totalUSD;
  final Function(String) onConfirm;

  const _CheckoutPanel({required this.totalUSD, required this.onConfirm});

  @override
  State<_CheckoutPanel> createState() => _CheckoutPanelState();
}

class _CheckoutPanelState extends State<_CheckoutPanel> {
  double tenderedUSD = 0;
  int tenderedLBP = 0;

  double get totalReceivedInUSD => tenderedUSD + (tenderedLBP / EXCHANGE_RATE);
  double get changeDueUSD => totalReceivedInUSD - widget.totalUSD;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Complete Checkout",
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 32,
              color: ZAYTOUNA_BLUE,
            ),
          ),
          const SizedBox(height: 32),
          _paymentInput(
            "Tender USD Amount",
            (v) => setState(() => tenderedUSD = double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 20),
          _paymentInput(
            "Tender LBP Amount",
            (v) => setState(() => tenderedLBP = int.tryParse(v) ?? 0),
            isLbp: true,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BG_COLOR,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _changeRow(
                  "Return USD",
                  "\$${changeDueUSD.toStringAsFixed(2)}",
                  changeDueUSD < 0 ? Colors.red : ZAYTOUNA_GREEN,
                ),
                const SizedBox(height: 8),
                _changeRow(
                  "Return LBP",
                  "${(changeDueUSD * EXCHANGE_RATE).toInt()} LBP",
                  changeDueUSD < 0 ? Colors.red : ZAYTOUNA_BLUE,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _methodButton("CARD", Icons.credit_card, Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _methodButton(
                  "CASH",
                  Icons.payments,
                  ZAYTOUNA_GREEN,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentInput(
    String label,
    Function(String) onChange, {
    bool isLbp = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            prefixText: isLbp ? "LBP " : "\$ ",
            prefixStyle: GoogleFonts.jetBrainsMono(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
          ),
          onChanged: onChange,
        ),
      ],
    );
  }

  Widget _changeRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          val,
          style: GoogleFonts.jetBrainsMono(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _methodButton(
    String label,
    IconData icon,
    Color color, {
    bool isPrimary = false,
  }) {
    bool isUnderpaid = changeDueUSD < 0 && isPrimary;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : Colors.white,
        foregroundColor: isPrimary ? Colors.white : color,
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      onPressed: isUnderpaid ? null : () => widget.onConfirm(label),
      icon: Icon(icon, size: 28),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
