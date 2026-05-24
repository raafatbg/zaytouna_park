// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zaytouna_park/Features/cashier/Utils/receipt_printer.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Orders/orders.dart';

// ─── DESIGN SYSTEM ────────────────────────────────────────────────────
// Unified with cashier dashboard (gold theme).
class TC {
  static const primary   = Color(0xFFB8860B); // gold
  static const primaryD  = Color(0xFF8B6914); // dark gold
  static const primaryL  = Color(0xFFFFF7DB); // gold tint
  static const ink       = Color(0xFF0F172A); // slate-900
  static const ink2      = Color(0xFF334155); // slate-700
  static const muted     = Color(0xFF64748B); // slate-500
  static const line      = Color(0xFFE2E8F0); // slate-200
  static const surface   = Colors.white;
  static const bg        = Color(0xFFF8FAFC); // slate-50
  static const success   = Color(0xFF10B981);
  static const successL  = Color(0xFFD1FAE5);
  static const warn      = Color(0xFFF59E0B);
  static const warnL     = Color(0xFFFEF3C7);
  static const danger    = Color(0xFFEF4444);
  static const dangerL   = Color(0xFFFEE2E2);
  static const info      = Color(0xFF6366F1);
  static const infoL     = Color(0xFFE0E7FF);
}

TextStyle _ui(double size, {FontWeight w = FontWeight.w600, Color? c}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: w, color: c ?? TC.ink);

TextStyle _mono(double size, {FontWeight w = FontWeight.w700, Color? c}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: w, color: c ?? TC.ink);

int roundToNearest5000(num amount) => (amount / 5000).round() * 5000;

// ─── MODELS ───────────────────────────────────────────────────────────
enum PosView { menu, inventory, facility }

class PosCategory {
  final int id;
  final String name;
  final bool isInventoryCategory;
  PosCategory({required this.id, required this.name, required this.isInventoryCategory});
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

class PosCustomer  { final int id; final String name; PosCustomer({required this.id, required this.name}); }
class PosOrderType { final int id; final String name; PosOrderType({required this.id, required this.name}); }
class PosFacility {
  final int id; final String name; final String typeName; final double pricePerHour;
  PosFacility({required this.id, required this.name, required this.typeName, required this.pricePerHour});
}
class PosTable     { final int id; final String name; PosTable({required this.id, required this.name}); }

// ─── MAIN POS SCREEN ──────────────────────────────────────────────────
class UpgradedPOS extends StatefulWidget {
  final int? editOrderId;
  const UpgradedPOS({super.key, this.editOrderId});

  @override
  State<UpgradedPOS> createState() => _UpgradedPOSState();
}

class _UpgradedPOSState extends State<UpgradedPOS> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isCheckoutMode = false;

  List<PosCategory> _allCategories = [];
  List<PosProduct>  _allProducts   = [];
  List<PosCustomer>  _customers   = [];
  List<PosOrderType> _orderTypes  = [];
  List<PosFacility>  _facilities  = [];
  List<PosTable>     _tables      = [];

  final List<CartItem> _cart = [];
  PosCategory?  _selectedCategory;
  PosCustomer?  _selectedCustomer;
  PosOrderType? _selectedOrderType;
  PosFacility?  _selectedFacility;
  PosTable?     _selectedTable;

  PosView _currentView = PosView.menu;

  double _exchangeRate   = 90000.0;
  double _discountAmount = 0.0;
  double _taxPercent     = 0.0;

  late TabController _tabCtrl;

  double get _subtotalUSD   => _cart.fold(0, (s, i) => s + i.total);
  double get _taxAmountUSD  => (_subtotalUSD - _discountAmount) * (_taxPercent / 100);
  double get _finalTotalUSD {
    final t = _subtotalUSD - _discountAmount + _taxAmountUSD;
    return t < 0 ? 0 : t;
  }

  List<PosCategory> get _currentCategories {
    if (_currentView == PosView.menu)      return _allCategories.where((c) => !c.isInventoryCategory).toList();
    if (_currentView == PosView.inventory) return _allCategories.where((c) =>  c.isInventoryCategory).toList();
    final types = _facilities.map((f) => f.typeName).toSet().toList();
    return types.map((t) => PosCategory(id: t.hashCode, name: t, isInventoryCategory: false)).toList();
  }

  List<PosProduct> get _currentDisplayItems {
    List<PosProduct> list;
    if (_currentView == PosView.facility) {
      list = _facilities.map((f) => PosProduct(
        id: f.id, categoryId: f.typeName.hashCode,
        name: '${f.name} (Booking)',
        price: f.pricePerHour, requiresPrep: false,
        isInventoryItem: false, isFacility: true,
      )).toList();
    } else {
      list = _allProducts.where((p) => p.isInventoryItem == (_currentView == PosView.inventory)).toList();
    }
    if (_selectedCategory != null) {
      list = list.where((p) => p.categoryId == _selectedCategory!.id).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─── DATA ───────────────────────────────────────────────────────────
  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _supabase.from('categories').select('id, name').eq('is_active', true),
        _supabase.from('inventory_categories').select('id, name'),
        _supabase.from('menu_items').select('id, category_id, name, price, requires_preparation, image_url').eq('is_available', true),
        _supabase.from('inventory_items').select('id, category_id, name, selling_price'),
        _supabase.from('customers').select('id, name').order('name'),
        _supabase.from('order_types').select('id, name'),
        _supabase.from('facilities').select('id, name, price_per_hour, facility_types(name)').eq('is_available', true),
        _supabase.from('restaurant_tables').select('id, name').eq('is_available', true),
      ]);

      final cats = <PosCategory>[];
      final prods = <PosProduct>[];

      for (final c in results[0] as List) {
        cats.add(PosCategory(id: c['id'], name: c['name'], isInventoryCategory: false));
      }
      for (final i in results[2] as List) {
        prods.add(PosProduct(
          id: i['id'], categoryId: i['category_id'], name: i['name'],
          price: (i['price'] as num).toDouble(),
          requiresPrep: i['requires_preparation'] ?? false,
          isInventoryItem: false, imageUrl: i['image_url'],
        ));
      }
      for (final c in results[1] as List) {
        cats.add(PosCategory(id: c['id'], name: c['name'], isInventoryCategory: true));
      }
      for (final i in results[3] as List) {
        prods.add(PosProduct(
          id: i['id'], categoryId: i['category_id'], name: i['name'],
          price: (i['selling_price'] as num?)?.toDouble() ?? 0.0,
          requiresPrep: false, isInventoryItem: true, imageUrl: null,
        ));
      }

      _allCategories = cats;
      _allProducts   = prods;
      _customers   = (results[4] as List).map((c) => PosCustomer(id: c['id'], name: c['name'])).toList();
      _orderTypes  = (results[5] as List).map((o) => PosOrderType(id: o['id'], name: o['name'])).toList();
      _facilities  = (results[6] as List).map((f) => PosFacility(
        id: f['id'], name: f['name'],
        typeName: f['facility_types']?['name'] ?? 'General',
        pricePerHour: (f['price_per_hour'] as num?)?.toDouble() ?? 0.0,
      )).toList();
      _tables      = (results[7] as List).map((t) => PosTable(id: t['id'], name: t['name'])).toList();

      if (_orderTypes.isNotEmpty) {
        _selectedOrderType = _orderTypes.firstWhere(
          (t) => t.name.toLowerCase().contains('takeaway'),
          orElse: () => _orderTypes.first,
        );
      }

      if (widget.editOrderId != null) await _hydrateExistingOrder();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching POS data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast('Failed to load POS data: $e', TC.danger);
      }
    }
  }

  Future<void> _hydrateExistingOrder() async {
    final order = await _supabase.from('orders').select().eq('id', widget.editOrderId!).single();
    final items = await _supabase.from('order_items').select().eq('order_id', widget.editOrderId!);

    if (order['customer_id']   != null) _selectedCustomer  = _customers .where((c) => c.id == order['customer_id']).firstOrNull;
    if (order['order_type_id'] != null) _selectedOrderType = _orderTypes.where((t) => t.id == order['order_type_id']).firstOrNull;
    if (order['facility_id']   != null) _selectedFacility  = _facilities.where((f) => f.id == order['facility_id']).firstOrNull;
    if (order['table_id']      != null) _selectedTable     = _tables    .where((t) => t.id == order['table_id']).firstOrNull;

    _exchangeRate   = (order['exchange_rate']   as num?)?.toDouble() ?? 90000.0;
    _discountAmount = (order['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final st = (order['subtotal']   as num?)?.toDouble() ?? 0.0;
    final ta = (order['tax_amount'] as num?)?.toDouble() ?? 0.0;
    if ((st - _discountAmount) > 0) _taxPercent = (ta / (st - _discountAmount)) * 100;

    _cart.clear();
    for (final i in items as List) {
      PosProduct? p;
      if (i['menu_item_id'] != null) {
        p = _allProducts.where((x) => x.id == i['menu_item_id'] && !x.isInventoryItem && !x.isFacility).firstOrNull;
      } else if (i['inventory_item_id'] != null) {
        p = _allProducts.where((x) => x.id == i['inventory_item_id'] && x.isInventoryItem).firstOrNull;
      } else if (i['facility_id'] != null) {
        final f = _facilities.where((x) => x.id == i['facility_id']).firstOrNull;
        if (f != null) {
          p = PosProduct(
            id: f.id, categoryId: f.typeName.hashCode,
            name: '${f.name} (Booking)',
            price: (i['unit_price'] as num?)?.toDouble() ?? f.pricePerHour,
            requiresPrep: false, isInventoryItem: false, isFacility: true,
          );
        }
      }
      if (p != null) _cart.add(CartItem(product: p, quantity: i['quantity']));
    }
  }

  // ─── CART ───────────────────────────────────────────────────────────
  void _addToCart(PosProduct item) {
    if (_isCheckoutMode) return;
    setState(() {
      final i = _cart.indexWhere((c) =>
        c.product.id == item.id &&
        c.product.isInventoryItem == item.isInventoryItem &&
        c.product.isFacility == item.isFacility);
      if (i >= 0) _cart[i].quantity++;
      else _cart.add(CartItem(product: item));
    });
  }

  void _updateQty(int i, int d) {
    if (_isCheckoutMode) return;
    setState(() {
      _cart[i].quantity += d;
      if (_cart[i].quantity <= 0) {
        _cart.removeAt(i);
        if (_cart.isEmpty) _isCheckoutMode = false;
      }
    });
  }

  void _clearCart() => setState(() {
    _cart.clear();
    _selectedCategory = null;
    _selectedFacility = null;
    _selectedTable = null;
    _selectedCustomer = null;
    _discountAmount = 0.0;
    _taxPercent = 0.0;
    _isCheckoutMode = false;
  });

  // ─── CHECKOUT ───────────────────────────────────────────────────────
  Future<void> _processCheckout(String paymentMethod, {bool shouldPrint = false, bool isPaid = true}) async {
    if (_cart.isEmpty) return;
    if (_selectedOrderType == null) {
      _showToast('Please select an Order Type first', TC.warn);
      return;
    }

    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: TC.primary)),
    );

    int? createdOrderId;
    final isEdit = widget.editOrderId != null;

    try {
      // ── 1. Pre-flight stock check for inventory items
      for (final c in _cart) {
        if (!c.product.isInventoryItem) continue;
        final res = await _supabase
          .from('inventory_items')
          .select('current_quantity, name')
          .eq('id', c.product.id)
          .single();
        final qty = (res['current_quantity'] as num?)?.toDouble() ?? 0.0;
        if (qty < c.quantity) {
          if (mounted) Navigator.pop(context);
          _showToast('Insufficient stock for ${res['name']} (have $qty, need ${c.quantity})', TC.danger);
          return;
        }
      }

      // ── 2. Restore old stock if editing
      if (isEdit) {
        final oldItems = await _supabase
          .from('order_items').select('inventory_item_id, quantity').eq('order_id', widget.editOrderId!);
        for (final oi in oldItems as List) {
          if (oi['inventory_item_id'] != null) {
            await _supabase.rpc('increment_inventory', params: {
              'p_item_id': oi['inventory_item_id'],
              'p_quantity': oi['quantity'],
            });
          }
        }
        await _supabase.from('order_items').delete().eq('order_id', widget.editOrderId!);
      }

      // ── 3. Create or update the order row.
      //    NOTE: column name is `status`. If your schema uses `order_status`,
      //    do a global find-replace: 'status': → 'order_status':
      final orderData = <String, dynamic>{
        'customer_id':     _selectedCustomer?.id,
        'order_type_id':   _selectedOrderType?.id,
        'facility_id':     _selectedFacility?.id,
        'table_id':        _selectedTable?.id,
        'subtotal':        _subtotalUSD,
        'discount_amount': _discountAmount,
        'tax_amount':      _taxAmountUSD,
        'total_amount':    _finalTotalUSD,
        'exchange_rate':   _exchangeRate,
        'status':          isPaid ? 'completed' : 'active',
        'payment_status':  isPaid ? 'paid' : 'unpaid',
        'payment_method':  paymentMethod.toLowerCase(),
      };

      int orderId;
      if (isEdit) {
        orderId = widget.editOrderId!;
        await _supabase.from('orders').update(orderData).eq('id', orderId);
      } else {
        final res = await _supabase.from('orders').insert(orderData).select('id').single();
        orderId = res['id'] as int;
        createdOrderId = orderId;
      }

      // ── 4. Insert order items
      final rows = _cart.map((c) => {
        'order_id':          orderId,
        'menu_item_id':      (c.product.isFacility || c.product.isInventoryItem) ? null : c.product.id,
        'inventory_item_id': c.product.isInventoryItem ? c.product.id : null,
        'facility_id':       c.product.isFacility ? c.product.id : null,
        'quantity':          c.quantity,
        'unit_price':        c.product.price,
        'item_total':        c.total,
        'item_status':       c.product.requiresPrep ? 'pending_kitchen' : 'completed',
      }).toList();

      await _supabase.from('order_items').insert(rows);

      // ── 5. Atomic stock decrement via RPC (rejects negative)
      for (final c in _cart) {
        if (!c.product.isInventoryItem) continue;
        final ok = await _supabase.rpc('decrement_inventory', params: {
          'p_item_id':  c.product.id,
          'p_quantity': c.quantity,
        });
        if (ok != true) {
          throw 'Stock for "${c.product.name}" changed during checkout. Please retry.';
        }
      }

      // ── 6. Optional receipt print
      if (shouldPrint) {
        final printModel = OrderModel(
          id: orderId,
          tableNumber: _selectedTable?.name ?? _selectedOrderType?.name ?? 'Takeaway',
          customerName: _selectedCustomer?.name ?? 'Walk-in Guest',
          items: _cart.map((c) => OrderItem(
            id: 0, name: c.product.name, quantity: c.quantity,
            price: c.product.price, total: c.total,
          )).toList(),
          status: isPaid ? OrderStatus.completed : OrderStatus.active,
          timestamp: DateTime.now(),
          subtotal: _subtotalUSD,
          discountAmount: _discountAmount,
          taxAmount: _taxAmountUSD,
          totalAmount: _finalTotalUSD,
          paymentStatus: isPaid ? 'paid' : 'unpaid',
        );
        try { await ReceiptPrinter.printReceipt(printModel); }
        catch (e) { if (mounted) _showToast('Print failed: $e', TC.danger); }
      }

      if (mounted) {
        Navigator.pop(context); // dismiss loading
        if (isEdit) {
          Navigator.pop(context, true);
        } else {
          _clearCart();
          _showToast('Order #$orderId saved', TC.success);
        }
      }
    } catch (e) {
      // ── ROLLBACK: if we created an orphan order row, delete it
      if (createdOrderId != null) {
        try {
          await _supabase.from('order_items').delete().eq('order_id', createdOrderId);
          await _supabase.from('orders').delete().eq('id', createdOrderId);
        } catch (_) {/* best effort */}
      }
      if (mounted) {
        Navigator.pop(context);
        _showToast('Checkout failed: $e', TC.danger);
      }
    }
  }

  void _showToast(String msg, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─── BUILD ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isPhone = w < 720;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: TC.bg,
        body: Center(child: CircularProgressIndicator(color: TC.primary)),
      );
    }
    return isPhone ? _buildPhoneScaffold() : _buildTabletScaffold();
  }

  // Tablet/desktop: original 4:6 split
  Widget _buildTabletScaffold() {
    return Scaffold(
      backgroundColor: TC.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(flex: 4, child: _cartPanel()),
            Expanded(flex: 6, child: _menuOrCheckoutPanel()),
          ],
        ),
      ),
    );
  }

  // Phone: two tabs — Menu | Cart [badge]
  Widget _buildPhoneScaffold() {
    return Scaffold(
      backgroundColor: TC.bg,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: Container(
          color: TC.surface,
          padding: const EdgeInsets.only(top: 8),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        height: 32, width: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [TC.primary, TC.primaryD]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.point_of_sale, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text('POS Terminal', style: _ui(16, w: FontWeight.w800)),
                      const Spacer(),
                      if (widget.editOrderId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: TC.warnL, borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Edit #${widget.editOrderId}',
                            style: _ui(10, w: FontWeight.w800, c: TC.warn)),
                        ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabCtrl,
                  labelColor: TC.primary,
                  unselectedLabelColor: TC.muted,
                  indicatorColor: TC.primary,
                  indicatorWeight: 3,
                  labelStyle: _ui(13, w: FontWeight.w800),
                  unselectedLabelStyle: _ui(13, w: FontWeight.w600),
                  tabs: [
                    const Tab(text: 'Menu'),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Cart'),
                          if (_cart.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: TC.primary, borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${_cart.length}',
                                style: _ui(10, w: FontWeight.w900, c: Colors.white)),
                            ),
                          ],
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
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _menuOrCheckoutPanel(showHeader: false),
          _cartPanel(showHeader: false),
        ],
      ),
    );
  }

  // ─── CART PANEL (left side / phone tab 2) ────────────────────────────
  Widget _cartPanel({bool showHeader = true}) {
    return Container(
      color: TC.surface,
      child: Column(
        children: [
          if (showHeader && widget.editOrderId != null) _editBanner(),
          _buildTopActionToolbar(),
          _buildCartHeader(),
          Expanded(child: _buildCartList()),
          _buildBillingSummary(),
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _editBanner() => Container(
    width: double.infinity, color: TC.warnL,
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.edit_note, color: TC.warn, size: 18),
        const SizedBox(width: 8),
        Text('