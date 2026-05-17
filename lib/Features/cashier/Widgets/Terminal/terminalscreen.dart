// ignore_for_file: deprecated_member_use, use_build_context_synchronously, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Ensure these imports match your actual file structure
import 'package:zaytouna_park/Features/cashier/Utils/receipt_printer.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Orders/orders.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';

// ─── CONSTANTS & HELPERS ──────────────────────────────────────────────
const Color ZAYTOUNA_GREEN = Color(0xFF22C55E);
const Color ZAYTOUNA_BLUE = Color(0xFF1E40AF);
const Color BG_COLOR = Color(0xFFF1F5F9);

int roundToNearest5000(num amount) {
  return ((amount / 5000).round() * 5000);
}

// ─── UNIFIED MODELS ───────────────────────────────────────────────────
enum PosView { menu, inventory, facility }

class PosCategory {
  final int id;
  final String name;
  final bool isInventoryCategory;

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
  final bool isInventoryItem;
  final bool isFacility;
  final String? imageUrl;

  PosProduct({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.requiresPrep,
    required this.isInventoryItem,
    this.isFacility = false,
    this.imageUrl,
  });
}

class CartItem {
  final PosProduct product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get total => product.price * quantity;
}

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
  final String typeName;
  final double pricePerHour;

  PosFacility({
    required this.id,
    required this.name,
    required this.typeName,
    required this.pricePerHour,
  });
}

class PosTable {
  final int id;
  final String name;

  PosTable({required this.id, required this.name});
}

// ─── MAIN POS SCREEN ──────────────────────────────────────────────────
class UpgradedPOS extends StatefulWidget {
  final int? editOrderId;

  const UpgradedPOS({super.key, this.editOrderId});

  @override
  State<UpgradedPOS> createState() => _UpgradedPOSState();
}

class _UpgradedPOSState extends State<UpgradedPOS> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isCheckoutMode = false;

  // Unified Data Lists
  List<PosCategory> _allCategories = [];
  List<PosProduct> _allProducts = [];
  List<PosCustomer> _customers = [];
  List<PosOrderType> _orderTypes = [];
  List<PosFacility> _facilities = [];
  List<PosTable> _tables = [];

  // State
  final List<CartItem> _cart = [];
  PosCategory? _selectedCategory;
  PosCustomer? _selectedCustomer;
  PosOrderType? _selectedOrderType;
  PosFacility?
  _selectedFacility; // Used if a facility is booked, but hidden from the top bar
  PosTable? _selectedTable;

  PosView _currentView = PosView.menu;

  // Financial State
  double _exchangeRate = 90000.0;
  double _discountAmount = 0.0;
  double _taxPercent = 0.0;

  // Financial Getters
  double get _subtotalUSD => _cart.fold(0, (sum, item) => sum + item.total);
  double get _taxAmountUSD =>
      (_subtotalUSD - _discountAmount) * (_taxPercent / 100);
  double get _finalTotalUSD {
    double total = _subtotalUSD - _discountAmount + _taxAmountUSD;
    return total < 0 ? 0 : total;
  }

  // ─── DYNAMIC DATA GETTERS ───
  List<PosCategory> get _currentCategories {
    if (_currentView == PosView.menu) {
      return _allCategories.where((c) => !c.isInventoryCategory).toList();
    }
    if (_currentView == PosView.inventory) {
      return _allCategories.where((c) => c.isInventoryCategory).toList();
    }
    final types = _facilities.map((f) => f.typeName).toSet().toList();
    return types
        .map(
          (t) =>
              PosCategory(id: t.hashCode, name: t, isInventoryCategory: false),
        )
        .toList();
  }

  List<PosProduct> get _currentDisplayItems {
    List<PosProduct> list;

    if (_currentView == PosView.facility) {
      list = _facilities
          .map(
            (f) => PosProduct(
              id: f.id,
              categoryId: f.typeName.hashCode,
              name: '${f.name} (Booking)',
              price: f.pricePerHour,
              requiresPrep: false,
              isInventoryItem: false,
              isFacility: true,
            ),
          )
          .toList();
    } else {
      list = _allProducts
          .where(
            (p) => p.isInventoryItem == (_currentView == PosView.inventory),
          )
          .toList();
    }

    if (_selectedCategory != null) {
      list = list.where((p) => p.categoryId == _selectedCategory!.id).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _supabase.from('categories').select('id, name').eq('is_active', true),
        _supabase.from('inventory_categories').select('id, name'),
        _supabase
            .from('menu_items')
            .select(
              'id, category_id, name, price, requires_preparation, image_url',
            )
            .eq('is_available', true),
        _supabase
            .from('inventory_items')
            .select('id, category_id, name, selling_price'),
        _supabase.from('customers').select('id, name').order('name'),
        _supabase.from('order_types').select('id, name'),
        _supabase
            .from('facilities')
            .select('id, name, price_per_hour, facility_types(name)')
            .eq('is_available', true),
        _supabase
            .from('restaurant_tables')
            .select('id, name')
            .eq('is_available', true),
      ]);

      List<PosCategory> combinedCategories = [];
      List<PosProduct> combinedProducts = [];

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
            imageUrl: i['image_url'],
          ),
        );
      }

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
            imageUrl: null,
          ),
        );
      }

      _allCategories = combinedCategories;
      _allProducts = combinedProducts;

      _customers = (results[4] as List)
          .map((c) => PosCustomer(id: c['id'], name: c['name']))
          .toList();
      _orderTypes = (results[5] as List)
          .map((o) => PosOrderType(id: o['id'], name: o['name']))
          .toList();

      _facilities = (results[6] as List)
          .map(
            (f) => PosFacility(
              id: f['id'],
              name: f['name'],
              typeName: f['facility_types']?['name'] ?? 'General',
              pricePerHour: (f['price_per_hour'] as num?)?.toDouble() ?? 0.0,
            ),
          )
          .toList();

      _tables = (results[7] as List)
          .map((t) => PosTable(id: t['id'], name: t['name']))
          .toList();

      if (_orderTypes.isNotEmpty) {
        _selectedOrderType = _orderTypes.firstWhere(
          (type) => type.name.toLowerCase().contains('takeaway'),
          orElse: () => _orderTypes.first,
        );
      }

      if (widget.editOrderId != null) {
        final orderData = await _supabase
            .from('orders')
            .select()
            .eq('id', widget.editOrderId!)
            .single();
        final itemsData = await _supabase
            .from('order_items')
            .select()
            .eq('order_id', widget.editOrderId!);

        if (orderData['customer_id'] != null) {
          _selectedCustomer = _customers
              .where((c) => c.id == orderData['customer_id'])
              .firstOrNull;
        }
        if (orderData['order_type_id'] != null) {
          _selectedOrderType = _orderTypes
              .where((t) => t.id == orderData['order_type_id'])
              .firstOrNull;
        }
        if (orderData['facility_id'] != null) {
          _selectedFacility = _facilities
              .where((f) => f.id == orderData['facility_id'])
              .firstOrNull;
        }
        if (orderData['table_id'] != null) {
          _selectedTable = _tables
              .where((t) => t.id == orderData['table_id'])
              .firstOrNull;
        }

        _exchangeRate =
            (orderData['exchange_rate'] as num?)?.toDouble() ?? 90000.0;
        _discountAmount =
            (orderData['discount_amount'] as num?)?.toDouble() ?? 0.0;

        double st = (orderData['subtotal'] as num?)?.toDouble() ?? 0.0;
        double ta = (orderData['tax_amount'] as num?)?.toDouble() ?? 0.0;
        if ((st - _discountAmount) > 0) {
          _taxPercent = (ta / (st - _discountAmount)) * 100;
        }

        _cart.clear();
        for (var item in itemsData as List) {
          PosProduct? product;
          if (item['menu_item_id'] != null) {
            product = _allProducts
                .where(
                  (p) =>
                      p.id == item['menu_item_id'] &&
                      !p.isInventoryItem &&
                      !p.isFacility,
                )
                .firstOrNull;
          } else if (item['inventory_item_id'] != null) {
            product = _allProducts
                .where(
                  (p) => p.id == item['inventory_item_id'] && p.isInventoryItem,
                )
                .firstOrNull;
          } else if (item['facility_id'] != null) {
            final f = _facilities
                .where((fac) => fac.id == item['facility_id'])
                .firstOrNull;
            if (f != null) {
              product = PosProduct(
                id: f.id,
                categoryId: f.typeName.hashCode,
                name: '${f.name} (Booking)',
                price:
                    (item['unit_price'] as num?)?.toDouble() ?? f.pricePerHour,
                requiresPrep: false,
                isInventoryItem: false,
                isFacility: true,
              );
            }
          }

          if (product != null) {
            _cart.add(CartItem(product: product, quantity: item['quantity']));
          }
        }
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching POS data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast('Data Error: Failed to load POS data.', Colors.red);
      }
    }
  }

  void _addToCart(PosProduct item) {
    if (_isCheckoutMode) return;
    setState(() {
      final existingIndex = _cart.indexWhere(
        (c) =>
            c.product.id == item.id &&
            c.product.isInventoryItem == item.isInventoryItem &&
            c.product.isFacility == item.isFacility,
      );
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(product: item));
      }
    });
  }

  void _updateQty(int index, int delta) {
    if (_isCheckoutMode) return;
    setState(() {
      _cart[index].quantity += delta;
      if (_cart[index].quantity <= 0) {
        _cart.removeAt(index);
        if (_cart.isEmpty) _isCheckoutMode = false;
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _selectedCategory = null;
      _selectedFacility = null;
      _selectedTable = null;
      _selectedCustomer = null;
      _discountAmount = 0.0;
      _taxPercent = 0.0;
      _isCheckoutMode = false;
    });
  }

  Future<void> _processCheckout(
    String paymentMethod, {
    bool shouldPrint = false,
    bool isPaid = true,
  }) async {
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
      int orderId;

      final orderData = {
        'customer_id': _selectedCustomer?.id,
        'order_type_id': _selectedOrderType?.id,
        'facility_id': _selectedFacility?.id,
        'table_id': _selectedTable?.id,
        'subtotal': _subtotalUSD,
        'discount_amount': _discountAmount,
        'tax_amount': _taxAmountUSD,
        'total_amount': _finalTotalUSD,
        'exchange_rate': _exchangeRate,
        'order_status': isPaid ? 'completed' : 'active',
        'payment_status': isPaid ? 'paid' : 'unpaid',
        'payment_method': paymentMethod.toLowerCase(),
      };

      if (widget.editOrderId != null) {
        orderId = widget.editOrderId!;
        final oldItems = await _supabase
            .from('order_items')
            .select('inventory_item_id, quantity')
            .eq('order_id', orderId);

        for (var oldItem in oldItems as List) {
          if (oldItem['inventory_item_id'] != null) {
            final stockRes = await _supabase
                .from('inventory_items')
                .select('current_quantity')
                .eq('id', oldItem['inventory_item_id'])
                .single();
            final currentQty =
                (stockRes['current_quantity'] as num?)?.toDouble() ?? 0.0;
            await _supabase
                .from('inventory_items')
                .update({'current_quantity': currentQty + oldItem['quantity']})
                .eq('id', oldItem['inventory_item_id']);
          }
        }

        await _supabase.from('order_items').delete().eq('order_id', orderId);
        await _supabase.from('orders').update(orderData).eq('id', orderId);
      } else {
        final orderRes = await _supabase
            .from('orders')
            .insert(orderData)
            .select('id')
            .single();
        orderId = orderRes['id'] as int;
      }

      final List<Map<String, dynamic>> orderItemsToInsert = [];

      for (var cartItem in _cart) {
        orderItemsToInsert.add({
          'order_id': orderId,
          'menu_item_id':
              cartItem.product.isFacility || cartItem.product.isInventoryItem
              ? null
              : cartItem.product.id,
          'inventory_item_id': cartItem.product.isInventoryItem
              ? cartItem.product.id
              : null,
          'facility_id': cartItem.product.isFacility
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

      await _supabase.from('order_items').insert(orderItemsToInsert);

      for (var cartItem in _cart) {
        if (cartItem.product.isInventoryItem) {
          final stockRes = await _supabase
              .from('inventory_items')
              .select('current_quantity')
              .eq('id', cartItem.product.id)
              .single();
          final currentQty =
              (stockRes['current_quantity'] as num?)?.toDouble() ?? 0.0;
          await _supabase
              .from('inventory_items')
              .update({'current_quantity': currentQty - cartItem.quantity})
              .eq('id', cartItem.product.id);
        }
      }

      if (shouldPrint) {
        final printModel = OrderModel(
          id: orderId,
          tableNumber:
              _selectedTable?.name ?? _selectedOrderType?.name ?? 'Takeaway',
          customerName: _selectedCustomer?.name ?? 'Walk-in Guest',
          items: _cart
              .map(
                (c) => OrderItem(
                  id: 0,
                  name: c.product.name,
                  quantity: c.quantity,
                  price: c.product.price,
                  total: c.total,
                ),
              )
              .toList(),
          status: isPaid ? OrderStatus.completed : OrderStatus.active,
          timestamp: DateTime.now(),
          subtotal: _subtotalUSD,
          discountAmount: _discountAmount,
          taxAmount: _taxAmountUSD,
          totalAmount: _finalTotalUSD,
          paymentStatus: isPaid ? 'paid' : 'unpaid',
        );

        try {
          await ReceiptPrinter.printReceipt(printModel);
        } catch (e) {
          _showToast('Print failed: $e', Colors.red);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        if (widget.editOrderId != null) {
          Navigator.pop(context, true);
        } else {
          _clearCart();
          _showToast('Order #$orderId saved successfully!', ZAYTOUNA_GREEN);
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BG_COLOR,
      resizeToAvoidBottomInset: false,
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
                          if (widget.editOrderId != null)
                            Container(
                              width: double.infinity,
                              color: Colors.orange.shade100,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_note,
                                    color: Colors.orange.shade800,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "EDITING ORDER #${widget.editOrderId}",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800,
                                      letterSpacing: 1.2,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                    child: _isCheckoutMode
                        ? _EmbeddedCheckoutPanel(
                            totalUSD: _finalTotalUSD,
                            exchangeRate: _exchangeRate,
                            onExchangeRateChanged: (newRate) =>
                                setState(() => _exchangeRate = newRate),
                            onBack: () =>
                                setState(() => _isCheckoutMode = false),
                            onConfirm: (method, shouldPrint, isPaid) =>
                                _processCheckout(
                                  method,
                                  shouldPrint: shouldPrint,
                                  isPaid: isPaid,
                                ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMenuHeader(),
                              _buildViewToggle(),
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

  // ─── UPDATED: ONLY SHOWS TABLE SELECTOR ───
  Widget _buildTopActionToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.cashierDashboard,
                  (r) => false,
                ),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Text(
                "Order Settings",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
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
                  onTap: () => _showSelectionDialog<PosCustomer>(
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
                  onTap: () => _showSelectionDialog<PosOrderType>(
                    "Select Order Type",
                    _orderTypes,
                    (item) {
                      setState(() {
                        _selectedOrderType = item;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // PERMANENT TABLE SELECTOR (Facility is removed from this row)
              Expanded(
                child: _SelectorButton(
                  title: "Table",
                  value: _selectedTable?.name ?? "Select Table",
                  icon: Icons.table_restaurant_outlined,
                  color: ZAYTOUNA_GREEN,
                  onTap: () => _showSelectionDialog<PosTable>(
                    "Select Table",
                    _tables,
                    (item) => setState(() {
                      _selectedTable = item;
                    }),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Current Order",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          if (widget.editOrderId == null)
            IconButton(
              onPressed: _clearCart,
              icon: const Icon(
                Icons.delete_sweep,
                color: Colors.redAccent,
                size: 24,
              ),
              tooltip: 'Clear Cart',
            )
          else
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 18),
              label: const Text(
                "Cancel Edit",
                style: TextStyle(color: Colors.redAccent),
              ),
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
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "Cart is empty",
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 14,
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
          Divider(height: 12, color: Colors.grey.shade200),
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
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '\$${item.product.price.toStringAsFixed(2)} ${item.product.isFacility ? '/hr' : 'ea'}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
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
                    width: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '${item.quantity}',
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
                  fontSize: 15,
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
        padding: const EdgeInsets.all(6.0),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildBillingSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 2)),
      ),
      child: Column(
        children: [
          _summaryRow("Subtotal", "\$${_subtotalUSD.toStringAsFixed(2)}"),
          _interactiveSummaryRow(
            "Discount (\$)",
            "-\$${_discountAmount.toStringAsFixed(2)}",
            Colors.redAccent,
            () {
              if (!_isCheckoutMode) {
                _showNumberInputDialog(
                  "Apply Discount",
                  "Enter flat discount amount in USD",
                  _discountAmount,
                  false,
                  (val) => setState(() => _discountAmount = val),
                );
              }
            },
          ),
          _interactiveSummaryRow(
            "Tax (${_taxPercent.toStringAsFixed(1)}%)",
            "+\$${_taxAmountUSD.toStringAsFixed(2)}",
            Colors.grey.shade700,
            () {
              if (!_isCheckoutMode) {
                _showNumberInputDialog(
                  "Apply Tax",
                  "Enter tax percentage",
                  _taxPercent,
                  true,
                  (val) => setState(() => _taxPercent = val),
                );
              }
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _summaryRow(
            "Total (USD)",
            "\$${_finalTotalUSD.toStringAsFixed(2)}",
            isTotal: true,
          ),
          _summaryRow(
            "Total (LBP)",
            "${roundToNearest5000(_finalTotalUSD * _exchangeRate)} LBP",
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: isTotal ? Colors.black87 : Colors.grey.shade600,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              fontSize: isTotal ? 15 : 13,
            ),
          ),
          Text(
            val,
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 13,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _interactiveSummaryRow(
    String label,
    String val,
    Color valColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: _isCheckoutMode ? Colors.grey : Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                if (!_isCheckoutMode)
                  Icon(Icons.edit, size: 12, color: Colors.blue.shade700),
              ],
            ),
            Text(
              val,
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: valColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNumberInputDialog(
    String title,
    String hint,
    double currentValue,
    bool isPercent,
    Function(double) onSave,
  ) {
    final TextEditingController ctrl = TextEditingController(
      text: currentValue > 0 ? currentValue.toString() : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: isPercent ? null : '\$ ',
            suffixText: isPercent ? ' %' : null,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ZAYTOUNA_BLUE),
            onPressed: () {
              final val = double.tryParse(ctrl.text) ?? 0.0;
              onSave(val);
              Navigator.pop(ctx);
            },
            child: Text("Apply", style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isCheckoutMode
                ? Colors.blueGrey
                : (widget.editOrderId != null
                      ? Colors.orange.shade600
                      : ZAYTOUNA_GREEN),
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: _cart.isEmpty ? 0 : 4,
          ),
          onPressed: _cart.isEmpty
              ? null
              : () => setState(() => _isCheckoutMode = !_isCheckoutMode),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isCheckoutMode)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
              Text(
                _isCheckoutMode
                    ? "BACK TO MENU"
                    : (widget.editOrderId != null
                          ? "UPDATE ORDER"
                          : "PROCEED TO CHECKOUT"),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 15,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectionDialog<T>(
    String title,
    List<T> items,
    Function(T?) onSelect,
  ) {
    if (_isCheckoutMode) return;
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
              if (item is PosTable) name = item.name;

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
            onPressed: () {
              onSelect(null);
              Navigator.pop(context);
            },
            child: Text(
              "Clear",
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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

  Widget _buildMenuHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        "POS Terminal",
        style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: ZAYTOUNA_BLUE),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _currentView = PosView.menu;
                  _selectedCategory = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _currentView == PosView.menu
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _currentView == PosView.menu
                        ? [
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 18,
                        color: _currentView == PosView.menu
                            ? ZAYTOUNA_BLUE
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Kitchen",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _currentView == PosView.menu
                              ? ZAYTOUNA_BLUE
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _currentView = PosView.inventory;
                  _selectedCategory = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _currentView == PosView.inventory
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _currentView == PosView.inventory
                        ? [
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_basket_outlined,
                        size: 18,
                        color: _currentView == PosView.inventory
                            ? Colors.orange.shade700
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Retail",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _currentView == PosView.inventory
                              ? Colors.orange.shade700
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _currentView = PosView.facility;
                  _selectedCategory = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _currentView == PosView.facility
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _currentView == PosView.facility
                        ? [
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: _currentView == PosView.facility
                            ? Colors.purple
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Bookings",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _currentView == PosView.facility
                              ? Colors.purple
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final displayCategories = _currentCategories;
    if (displayCategories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: displayCategories.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            Color activeCol = ZAYTOUNA_BLUE;
            if (_currentView == PosView.inventory) {
              activeCol = Colors.orange.shade700;
            }
            if (_currentView == PosView.facility) activeCol = Colors.purple;
            if (index == 0) {
              return _CategoryTab(
                title: "All",
                isSelected: _selectedCategory == null,
                activeColor: activeCol,
                onTap: () => setState(() => _selectedCategory = null),
              );
            }
            final cat = displayCategories[index - 1];
            return _CategoryTab(
              title: cat.name,
              isSelected: _selectedCategory?.id == cat.id,
              activeColor: activeCol,
              onTap: () => setState(() => _selectedCategory = cat),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemsGrid() {
    final displayedItems = _currentDisplayItems;
    if (displayedItems.isEmpty) {
      return Center(
        child: Text(
          "No items found in this section.",
          style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 16),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.80,
      ),
      itemCount: displayedItems.length,
      itemBuilder: (context, index) {
        final item = displayedItems[index];
        return InkWell(
          onTap: () => _addToCart(item),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: item.isFacility
                          ? Colors.purple.withOpacity(0.1)
                          : (item.isInventoryItem
                                ? Colors.orange.withOpacity(0.1)
                                : ZAYTOUNA_GREEN.withOpacity(0.1)),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  _buildFallbackIcon(item),
                            ),
                          )
                        : _buildFallbackIcon(item),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: GoogleFonts.jetBrainsMono(
                            color: item.isFacility
                                ? Colors.purple
                                : (item.isInventoryItem
                                      ? Colors.orange.shade700
                                      : ZAYTOUNA_GREEN),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
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

  Widget _buildFallbackIcon(PosProduct item) {
    IconData icon = Icons.fastfood_rounded;
    Color color = ZAYTOUNA_GREEN;
    if (item.isFacility) {
      icon = Icons.calendar_month_rounded;
      color = Colors.purple;
    } else if (item.isInventoryItem) {
      icon = Icons.shopping_basket_rounded;
      color = Colors.orange;
    }
    return Center(child: Icon(icon, size: 36, color: color.withOpacity(0.5)));
  }
}

class _CategoryTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _CategoryTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 13,
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade500, size: 16),
          ],
        ),
      ),
    );
  }
}

class _EmbeddedCheckoutPanel extends StatefulWidget {
  final double totalUSD;
  final double exchangeRate;
  final VoidCallback onBack;
  final Function(double) onExchangeRateChanged;
  final Function(String, bool, bool) onConfirm;

  const _EmbeddedCheckoutPanel({
    required this.totalUSD,
    required this.exchangeRate,
    required this.onBack,
    required this.onExchangeRateChanged,
    required this.onConfirm,
  });

  @override
  State<_EmbeddedCheckoutPanel> createState() => _EmbeddedCheckoutPanelState();
}

class _EmbeddedCheckoutPanelState extends State<_EmbeddedCheckoutPanel> {
  double tenderedUSD = 0;
  int tenderedLBP = 0;
  late double currentExchangeRate;
  late TextEditingController _rateCtrl;

  @override
  void initState() {
    super.initState();
    currentExchangeRate = widget.exchangeRate;
    _rateCtrl = TextEditingController(
      text: currentExchangeRate.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  double get totalReceivedInUSD =>
      tenderedUSD + (tenderedLBP / currentExchangeRate);
  double get changeDueUSD => totalReceivedInUSD - widget.totalUSD;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 24),
                  color: ZAYTOUNA_BLUE,
                ),
                Text(
                  "Complete Checkout",
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 32,
                    color: ZAYTOUNA_BLUE,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                "Amount Due: \$${widget.totalUSD.toStringAsFixed(2)}  •  ${roundToNearest5000(widget.totalUSD * currentExchangeRate)} LBP",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: ZAYTOUNA_BLUE,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _paymentInput(
                    "Tender USD",
                    (v) =>
                        setState(() => tenderedUSD = double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _paymentInput(
                    "Tender LBP",
                    (v) => setState(() => tenderedLBP = int.tryParse(v) ?? 0),
                    prefixText: "LBP ",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _paymentInput(
                    "Exchange Rate (LBP/\$)",
                    (v) {
                      final rate = double.tryParse(v) ?? 90000.0;
                      setState(
                        () => currentExchangeRate = rate > 0 ? rate : 90000.0,
                      );
                      widget.onExchangeRateChanged(currentExchangeRate);
                    },
                    prefixText: "LBP ",
                    controller: _rateCtrl,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: BG_COLOR,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _changeRow(
                          "Return USD",
                          "\$${changeDueUSD.toStringAsFixed(2)}",
                          changeDueUSD < 0 ? Colors.red : ZAYTOUNA_GREEN,
                        ),
                        const SizedBox(height: 4),
                        _changeRow(
                          "Return LBP",
                          "${roundToNearest5000(changeDueUSD * currentExchangeRate)} LBP",
                          changeDueUSD < 0 ? Colors.red : ZAYTOUNA_BLUE,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _methodButton(
                    "SAVE UNPAID",
                    Icons.receipt_long,
                    Colors.orange.shade700,
                    onTap: () => widget.onConfirm("pending", true, false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _methodButton(
                    "CARD",
                    Icons.credit_card,
                    Colors.blue,
                    onTap: () => widget.onConfirm("card", false, true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _methodButton(
                    "CASH",
                    Icons.payments,
                    ZAYTOUNA_GREEN,
                    onTap: () => widget.onConfirm("cash", false, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _methodButton(
                    "PRINT & PAY",
                    Icons.print,
                    ZAYTOUNA_GREEN,
                    isPrimary: true,
                    onTap: () => widget.onConfirm("cash", true, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentInput(
    String label,
    Function(String) onChange, {
    String prefixText = "\$ ",
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            prefixText: prefixText,
            prefixStyle: GoogleFonts.jetBrainsMono(
              fontSize: 20,
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
              horizontal: 16,
              vertical: 16,
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
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          val,
          style: GoogleFonts.jetBrainsMono(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 16,
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
    required VoidCallback onTap,
  }) {
    bool isUnderpaid = changeDueUSD < 0 && isPrimary;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : Colors.white,
        foregroundColor: isPrimary ? Colors.white : color,
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: isUnderpaid ? null : onTap,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
