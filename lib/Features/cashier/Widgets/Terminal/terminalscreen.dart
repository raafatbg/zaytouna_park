// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zaytouna_park/Features/cashier/Utils/receipt_printer.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Orders/orders.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────
class T {
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
  static const infoBg = Color(0xFFDBEAFE);
}

TextStyle _ui(
  double s, {
  FontWeight w = FontWeight.w600,
  Color? c,
  double? ls,
}) => GoogleFonts.inter(
  fontSize: s,
  fontWeight: w,
  color: c ?? T.ink,
  letterSpacing: ls,
);

TextStyle _mono(double s, {FontWeight w = FontWeight.w700, Color? c}) =>
    GoogleFonts.inter(
      fontSize: s,
      fontWeight: w,
      color: c ?? T.ink,
      letterSpacing: -0.2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

TextStyle _eyebrow(double s, {Color? c}) => GoogleFonts.inter(
  fontSize: s,
  fontWeight: FontWeight.w800,
  color: c ?? T.muted,
  letterSpacing: 1.4,
);

int roundToNearest5000(num amount) => (amount / 5000).round() * 5000;

// ─── MODELS ───────────────────────────────────────────────────────────
enum PosView { menu, inventory }

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
  final String? imageUrl;
  PosProduct({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.requiresPrep,
    required this.isInventoryItem,
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

class _UpgradedPOSState extends State<UpgradedPOS>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isCheckoutMode = false;

  List<PosCategory> _allCategories = [];
  List<PosProduct> _allProducts = [];
  List<PosCustomer> _customers = [];
  List<PosOrderType> _orderTypes = [];
  List<PosTable> _tables = [];

  final List<CartItem> _cart = [];
  PosCategory? _selectedCategory;
  PosCustomer? _selectedCustomer;
  PosOrderType? _selectedOrderType;
  PosTable? _selectedTable;

  PosView _currentView = PosView.menu;

  Map<String, dynamic>? _pendingExtra;
  bool _extraConsumed = false;

  double _exchangeRate = 90000.0;
  double _discountAmount = 0.0;
  double _taxPercent = 0.0;

  late TabController _tabCtrl;

  double get _subtotalUSD => _cart.fold(0, (s, i) => s + i.total);
  double get _taxAmountUSD =>
      (_subtotalUSD - _discountAmount) * (_taxPercent / 100);
  double get _finalTotalUSD {
    final t = _subtotalUSD - _discountAmount + _taxAmountUSD;
    return t < 0 ? 0 : t;
  }

  bool get _isDineIn {
    final n =
        _selectedOrderType?.name.toLowerCase().replaceAll(
          RegExp(r'[-_\s]'),
          '',
        ) ??
        '';
    return n.contains('dinein');
  }

  List<PosCategory> get _currentCategories {
    if (_currentView == PosView.menu) {
      return _allCategories.where((c) => !c.isInventoryCategory).toList();
    }
    return _allCategories.where((c) => c.isInventoryCategory).toList();
  }

  List<PosProduct> get _currentDisplayItems {
    var list = _allProducts
        .where((p) => p.isInventoryItem == (_currentView == PosView.inventory))
        .toList();
    if (_selectedCategory != null) {
      list = list.where((p) => p.categoryId == _selectedCategory!.id).toList();
    }
    return list;
  }

  Color get _viewAccent =>
      _currentView == PosView.inventory ? T.warn : T.primary;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchAllData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_extraConsumed) return;
    try {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map) {
        _pendingExtra = Map<String, dynamic>.from(extra);
      }
    } catch (_) {}
    _extraConsumed = true;
    if (!_isLoading) _applyPreselection();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _applyPreselection() {
    final extra = _pendingExtra;
    if (extra == null) return;
    final raw = extra['preselectedTable'];
    if (raw == null) return;

    PosTable? table;
    if (raw is PosTable) {
      table = raw;
    } else if (raw is Map) {
      final id = raw['id'];
      table = _tables.where((t) => t.id == id).firstOrNull;
      if (table == null && id is int && raw['name'] != null) {
        table = PosTable(id: id, name: raw['name'].toString());
      }
    }
    if (table == null) return;

    final dineIn = _orderTypes.where((o) {
      final n = o.name.toLowerCase().replaceAll(RegExp(r'[-_\s]'), '');
      return n.contains('dinein');
    }).firstOrNull;

    setState(() {
      if (dineIn != null) _selectedOrderType = dineIn;
      _selectedTable = table;
    });
    _pendingExtra = null;

    final pickedName = table.name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _toast('Table "$pickedName" selected for Dine in', T.success);
    });
  }

  // ─── DATA ───────────────────────────────────────────────────────────
  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final r = await Future.wait([
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
            .from('restaurant_tables')
            .select('id, name')
            .eq('is_available', true),
      ]);

      final cats = <PosCategory>[];
      final prods = <PosProduct>[];

      for (final c in r[0] as List) {
        cats.add(
          PosCategory(id: c['id'], name: c['name'], isInventoryCategory: false),
        );
      }
      for (final i in r[2] as List) {
        prods.add(
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
      for (final c in r[1] as List) {
        cats.add(
          PosCategory(id: c['id'], name: c['name'], isInventoryCategory: true),
        );
      }
      for (final i in r[3] as List) {
        prods.add(
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

      _allCategories = cats;
      _allProducts = prods;
      _customers = (r[4] as List)
          .map((c) => PosCustomer(id: c['id'], name: c['name']))
          .toList();
      _orderTypes = (r[5] as List)
          .map((o) => PosOrderType(id: o['id'], name: o['name']))
          .toList();
      _tables = (r[6] as List)
          .map((t) => PosTable(id: t['id'], name: t['name']))
          .toList();

      if (_orderTypes.isNotEmpty) {
        _selectedOrderType = _orderTypes.firstWhere(
          (t) => t.name.toLowerCase().contains('takeaway'),
          orElse: () => _orderTypes.first,
        );
      }

      if (widget.editOrderId != null) await _hydrateExistingOrder();
      if (mounted) setState(() => _isLoading = false);
      _applyPreselection();
    } catch (e) {
      debugPrint('Error fetching POS data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _toast('Failed to load POS data: $e', T.danger);
      }
    }
  }

  Future<void> _hydrateExistingOrder() async {
    final order = await _supabase
        .from('orders')
        .select()
        .eq('id', widget.editOrderId!)
        .single();
    final items = await _supabase
        .from('order_items')
        .select()
        .eq('order_id', widget.editOrderId!);

    if (order['customer_id'] != null) {
      _selectedCustomer = _customers
          .where((c) => c.id == order['customer_id'])
          .firstOrNull;
    }
    if (order['order_type_id'] != null) {
      _selectedOrderType = _orderTypes
          .where((t) => t.id == order['order_type_id'])
          .firstOrNull;
    }
    if (order['table_id'] != null) {
      _selectedTable = _tables
          .where((t) => t.id == order['table_id'])
          .firstOrNull;
    }

    _exchangeRate = (order['exchange_rate'] as num?)?.toDouble() ?? 90000.0;
    _discountAmount = (order['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final st = (order['subtotal'] as num?)?.toDouble() ?? 0.0;
    final ta = (order['tax_amount'] as num?)?.toDouble() ?? 0.0;
    if ((st - _discountAmount) > 0) {
      _taxPercent = (ta / (st - _discountAmount)) * 100;
    }

    _cart.clear();
    for (final i in items as List) {
      PosProduct? p;
      if (i['menu_item_id'] != null) {
        p = _allProducts
            .where((x) => x.id == i['menu_item_id'] && !x.isInventoryItem)
            .firstOrNull;
      } else if (i['inventory_item_id'] != null) {
        p = _allProducts
            .where((x) => x.id == i['inventory_item_id'] && x.isInventoryItem)
            .firstOrNull;
      }
      if (p != null) _cart.add(CartItem(product: p, quantity: i['quantity']));
    }
  }

  // ─── CART ───────────────────────────────────────────────────────────
  void _addToCart(PosProduct item) {
    if (_isCheckoutMode) return;
    HapticFeedback.lightImpact();
    setState(() {
      final i = _cart.indexWhere(
        (c) =>
            c.product.id == item.id &&
            c.product.isInventoryItem == item.isInventoryItem,
      );
      if (i >= 0) {
        _cart[i].quantity++;
      } else {
        _cart.add(CartItem(product: item));
      }
    });
  }

  void _updateQty(int i, int d) {
    if (_isCheckoutMode) return;
    HapticFeedback.selectionClick();
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
    _selectedTable = null;
    _selectedCustomer = null;
    _discountAmount = 0.0;
    _taxPercent = 0.0;
    _isCheckoutMode = false;
  });

  // ─── CHECKOUT ───────────────────────────────────────────────────────
  Future<void> _processCheckout(
    String paymentMethod, {
    bool shouldPrint = false,
    bool isPaid = true,
  }) async {
    if (_cart.isEmpty) return;
    if (_selectedOrderType == null) {
      _toast('Please select an Order Type first', T.warn);
      return;
    }
    if (_isDineIn && _selectedTable == null) {
      _toast('Please select a Table for Dine in orders', T.warn);
      return;
    }
    if (!_isDineIn && _selectedTable != null) {
      _selectedTable = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: T.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CircularProgressIndicator(
            color: T.primary,
            strokeWidth: 3,
          ),
        ),
      ),
    );

    int? createdOrderId;
    final isEdit = widget.editOrderId != null;

    try {
      // 1. Stock pre-check
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
          _toast(
            'Insufficient stock for ${res['name']} (have $qty, need ${c.quantity})',
            T.danger,
          );
          return;
        }
      }

      // 2. Restore old stock if editing
      if (isEdit) {
        final oldItems = await _supabase
            .from('order_items')
            .select('inventory_item_id, quantity')
            .eq('order_id', widget.editOrderId!);
        for (final oi in oldItems as List) {
          if (oi['inventory_item_id'] != null) {
            await _supabase.rpc(
              'increment_inventory',
              params: {
                'p_item_id': oi['inventory_item_id'],
                'p_quantity': oi['quantity'],
              },
            );
          }
        }
        await _supabase
            .from('order_items')
            .delete()
            .eq('order_id', widget.editOrderId!);
      }

      // 3. Create / update order — uses order_status (PGRST204 fix)
      final orderData = <String, dynamic>{
        'customer_id': _selectedCustomer?.id,
        'order_type_id': _selectedOrderType?.id,
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

      int orderId;
      if (isEdit) {
        orderId = widget.editOrderId!;
        await _supabase.from('orders').update(orderData).eq('id', orderId);
      } else {
        final res = await _supabase
            .from('orders')
            .insert(orderData)
            .select('id')
            .single();
        orderId = res['id'] as int;
        createdOrderId = orderId;
      }

      // 4. Items
      final rows = _cart
          .map(
            (c) => {
              'order_id': orderId,
              'menu_item_id': c.product.isInventoryItem ? null : c.product.id,
              'inventory_item_id': c.product.isInventoryItem
                  ? c.product.id
                  : null,
              'quantity': c.quantity,
              'unit_price': c.product.price,
              'item_total': c.total,
              'item_status': c.product.requiresPrep
                  ? 'pending_kitchen'
                  : 'completed',
            },
          )
          .toList();
      await _supabase.from('order_items').insert(rows);

      // 5. Stock decrement
      for (final c in _cart) {
        if (!c.product.isInventoryItem) continue;
        final ok = await _supabase.rpc(
          'decrement_inventory',
          params: {'p_item_id': c.product.id, 'p_quantity': c.quantity},
        );
        if (ok != true) {
          throw 'Stock for "${c.product.name}" changed during checkout. Please retry.';
        }
      }

      // 6. Print
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
          if (mounted) _toast('Print failed: $e', T.danger);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        if (isEdit) {
          Navigator.pop(context, true);
        } else {
          _clearCart();
          _toast('Order #$orderId saved', T.success);
        }
      }
    } catch (e) {
      if (createdOrderId != null) {
        try {
          await _supabase
              .from('order_items')
              .delete()
              .eq('order_id', createdOrderId);
          await _supabase.from('orders').delete().eq('id', createdOrderId);
        } catch (_) {
          /* best effort */
        }
      }
      if (mounted) {
        Navigator.pop(context);
        _toast('Checkout failed: $e', T.danger);
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
              c == T.success
                  ? Icons.check_circle_rounded
                  : c == T.danger
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── BUILD ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: T.bg,
        body: Center(
          child: CircularProgressIndicator(color: T.primary, strokeWidth: 3),
        ),
      );
    }
    final w = MediaQuery.sizeOf(context).width;
    return w < 720 ? _phoneScaffold() : _tabletScaffold();
  }

  Widget _tabletScaffold() => Scaffold(
    backgroundColor: T.bg,
    resizeToAvoidBottomInset: true,
    body: SafeArea(
      child: Row(
        children: [
          Expanded(flex: 4, child: _cartPanel()),
          Container(width: 1, color: T.line),
          Expanded(flex: 6, child: _menuPanel()),
        ],
      ),
    ),
  );

  Widget _phoneScaffold() => Scaffold(
    backgroundColor: T.bg,
    resizeToAvoidBottomInset: true,
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(108),
      child: Container(
        decoration: const BoxDecoration(
          color: T.surface,
          border: Border(bottom: BorderSide(color: T.line)),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    const _BrandMark(size: 32),
                    const SizedBox(width: 10),
                    Text('POS Terminal', style: _ui(16, w: FontWeight.w800)),
                    const Spacer(),
                    if (widget.editOrderId != null)
                      _EditPill(id: widget.editOrderId!),
                  ],
                ),
              ),
              TabBar(
                controller: _tabCtrl,
                labelColor: T.primary,
                unselectedLabelColor: T.muted,
                indicatorColor: T.primary,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: T.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_cart.length}',
                              style: _ui(
                                10,
                                w: FontWeight.w900,
                                c: Colors.white,
                              ),
                            ),
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
      children: [_menuPanel(showHeader: false), _cartPanel(showHeader: false)],
    ),
  );

  // ─── CART PANEL ─────────────────────────────────────────────────────
  Widget _cartPanel({bool showHeader = true}) => Container(
    color: T.surface,
    child: Column(
      children: [
        if (showHeader && widget.editOrderId != null) _editBanner(),
        _orderSettingsBar(),
        _cartHeader(),
        Expanded(child: _cartList()),
        _billingSummary(),
        _payButton(),
      ],
    ),
  );

  Widget _editBanner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    color: T.warnBg,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.edit_note_rounded, color: T.warn, size: 18),
        const SizedBox(width: 8),
        Text(
          'EDITING ORDER #${widget.editOrderId}',
          style: _eyebrow(11, c: T.warn),
        ),
      ],
    ),
  );

  Widget _menuPanel({bool showHeader = true}) {
    if (_isCheckoutMode) {
      return _EmbeddedCheckoutPanel(
        totalUSD: _finalTotalUSD,
        exchangeRate: _exchangeRate,
        onExchangeRateChanged: (r) => setState(() => _exchangeRate = r),
        onBack: () => setState(() => _isCheckoutMode = false),
        onConfirm: (m, p, paid) =>
            _processCheckout(m, shouldPrint: p, isPaid: paid),
      );
    }
    return Container(
      color: T.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) _menuHeader(),
          _viewToggle(),
          _categoryTabs(),
          Expanded(child: _itemsGrid()),
        ],
      ),
    );
  }

  // ─── ORDER SETTINGS ─────────────────────────────────────────────────
  Widget _orderSettingsBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: const BoxDecoration(
      color: T.surface,
      border: Border(bottom: BorderSide(color: T.lineSoft)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ORDER SETTINGS', style: _eyebrow(10)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Selector(
                label: 'Customer',
                value: _selectedCustomer?.name ?? 'Walk-in',
                icon: Icons.person_outline_rounded,
                color: T.info,
                onTap: () => _selectDialog<PosCustomer>(
                  'Select Customer',
                  _customers,
                  (i) => setState(() => _selectedCustomer = i),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Selector(
                label: 'Type',
                value: _selectedOrderType?.name ?? 'Type',
                icon: Icons.shopping_bag_outlined,
                color: T.warn,
                onTap: () => _selectDialog<PosOrderType>(
                  'Order Type',
                  _orderTypes,
                  (i) => setState(() {
                    _selectedOrderType = i;
                    if (!_isDineIn) _selectedTable = null;
                  }),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Opacity(
                opacity: _isDineIn ? 1.0 : 0.45,
                child: _Selector(
                  label: 'Table',
                  value: _isDineIn
                      ? (_selectedTable?.name ?? 'Table')
                      : 'Dine in only',
                  icon: Icons.table_restaurant_outlined,
                  color: T.success,
                  onTap: !_isDineIn
                      ? () => _toast(
                          'Tables are only available for Dine in orders',
                          T.warn,
                        )
                      : () => _selectDialog<PosTable>(
                          'Select Table',
                          _tables,
                          (i) => setState(() => _selectedTable = i),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _cartHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text('Current Order', style: _ui(16, w: FontWeight.w800)),
            if (_cart.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: T.primaryL,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_cart.length} ${_cart.length == 1 ? "item" : "items"}',
                  style: _ui(10, w: FontWeight.w800, c: T.primaryD),
                ),
              ),
            ],
          ],
        ),
        if (widget.editOrderId == null)
          _IconBtn(
            icon: Icons.delete_sweep_outlined,
            color: T.danger,
            tooltip: 'Clear cart',
            onTap: _cart.isEmpty ? null : _clearCart,
          )
        else
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel_outlined, color: T.danger, size: 16),
            label: Text(
              'Cancel Edit',
              style: _ui(12, w: FontWeight.w700, c: T.danger),
            ),
          ),
      ],
    ),
  );

  Widget _cartList() {
    if (_cart.isEmpty) {
      return const _EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Cart is empty',
        hint: 'Tap items in the menu to add',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: _cart.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final item = _cart[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: T.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: T.lineSoft),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: _ui(13, w: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${item.product.price.toStringAsFixed(2)} ea',
                      style: _mono(10.5, w: FontWeight.w600, c: T.muted),
                    ),
                  ],
                ),
              ),
              _QtyStepper(
                quantity: item.quantity,
                onDec: () => _updateQty(i, -1),
                onInc: () => _updateQty(i, 1),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '\$${item.total.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: _mono(14, w: FontWeight.w900, c: T.primary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── BILLING ────────────────────────────────────────────────────────
  Widget _billingSummary() => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
    decoration: const BoxDecoration(
      color: T.surface,
      border: Border(top: BorderSide(color: T.lineSoft)),
    ),
    child: Column(
      children: [
        _row('Subtotal', '\$${_subtotalUSD.toStringAsFixed(2)}'),
        _interactiveRow(
          'Discount (\$)',
          '-\$${_discountAmount.toStringAsFixed(2)}',
          T.danger,
          () {
            if (_isCheckoutMode) return;
            _numberDialog(
              'Apply Discount',
              'Flat discount in USD',
              _discountAmount,
              false,
              (v) => setState(() => _discountAmount = v),
            );
          },
        ),
        _interactiveRow(
          'Tax (${_taxPercent.toStringAsFixed(1)}%)',
          '+\$${_taxAmountUSD.toStringAsFixed(2)}',
          T.ink2,
          () {
            if (_isCheckoutMode) return;
            _numberDialog(
              'Apply Tax',
              'Tax percentage',
              _taxPercent,
              true,
              (v) => setState(() => _taxPercent = v),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: T.lineSoft),
        ),
        _row(
          'Total (USD)',
          '\$${_finalTotalUSD.toStringAsFixed(2)}',
          isTotal: true,
        ),
        _row(
          'Total (LBP)',
          '${roundToNearest5000(_finalTotalUSD * _exchangeRate)} LBP',
          isTotal: true,
          color: T.primary,
        ),
      ],
    ),
  );

  Widget _row(String label, String val, {bool isTotal = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: _ui(
                isTotal ? 13 : 12,
                w: isTotal ? FontWeight.w800 : FontWeight.w600,
                c: isTotal ? T.ink : T.muted,
              ),
            ),
            Text(
              val,
              style: _mono(
                isTotal ? 16 : 13,
                w: FontWeight.w800,
                c: color ?? T.ink,
              ),
            ),
          ],
        ),
      );

  Widget _interactiveRow(
    String label,
    String val,
    Color valColor,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: _ui(
                  12,
                  w: FontWeight.w600,
                  c: _isCheckoutMode ? T.muted2 : T.info,
                ),
              ),
              const SizedBox(width: 4),
              if (!_isCheckoutMode)
                const Icon(Icons.edit_rounded, size: 10, color: T.info),
            ],
          ),
          Text(
            val,
            style: _mono(13, w: FontWeight.w800, c: valColor),
          ),
        ],
      ),
    ),
  );

  void _numberDialog(
    String title,
    String hint,
    double cur,
    bool isPercent,
    Function(double) onSave,
  ) {
    final ctrl = TextEditingController(text: cur > 0 ? cur.toString() : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: T.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: _ui(17, w: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: _mono(16, w: FontWeight.w800),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: isPercent ? null : '\$ ',
            suffixText: isPercent ? ' %' : null,
            filled: true,
            fillColor: T.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: _ui(13, w: FontWeight.w700, c: T.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: T.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              onSave(double.tryParse(ctrl.text) ?? 0.0);
              Navigator.pop(ctx);
            },
            child: Text(
              'Apply',
              style: _ui(13, w: FontWeight.w800, c: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payButton() {
    final isEdit = widget.editOrderId != null;
    final label = _isCheckoutMode
        ? 'BACK TO MENU'
        : (isEdit ? 'UPDATE ORDER' : 'PROCEED TO CHECKOUT');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: T.surface,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _cart.isEmpty
                ? null
                : LinearGradient(
                    colors: _isCheckoutMode
                        ? [T.ink2, T.ink2.withValues(alpha: 0.85)]
                        : (isEdit
                              ? [T.warn, T.warn.withValues(alpha: 0.85)]
                              : [T.primary, T.primaryD]),
                  ),
            color: _cart.isEmpty ? T.lineSoft : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _cart.isEmpty
                ? []
                : [
                    BoxShadow(
                      color: (_isCheckoutMode ? T.ink2 : T.primary).withValues(
                        alpha: 0.25,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _cart.isEmpty
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      setState(() => _isCheckoutMode = !_isCheckoutMode);
                    },
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isCheckoutMode) ...[
                      const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: _ui(
                        14,
                        w: FontWeight.w800,
                        c: _cart.isEmpty ? T.muted : Colors.white,
                        ls: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectDialog<X>(String title, List<X> items, Function(X?) onSelect) {
    if (_isCheckoutMode) return;
    String query = '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          String nameOf(X x) {
            if (x is PosCustomer) return x.name;
            if (x is PosOrderType) return x.name;
            if (x is PosTable) return x.name;
            return '$x';
          }

          final filtered = items
              .where(
                (i) => nameOf(i).toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
          return AlertDialog(
            backgroundColor: T.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title, style: _ui(17, w: FontWeight.w800)),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    onChanged: (v) => setS(() => query = v),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: T.muted2,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: T.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 320,
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No matches',
                              style: _ui(13, c: T.muted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const Divider(color: T.lineSoft, height: 1),
                            itemBuilder: (_, i) => ListTile(
                              dense: true,
                              title: Text(
                                nameOf(filtered[i]),
                                style: _ui(13.5, w: FontWeight.w600),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: T.muted2,
                              ),
                              onTap: () {
                                onSelect(filtered[i]);
                                Navigator.pop(ctx);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  onSelect(null);
                  Navigator.pop(ctx);
                },
                child: Text(
                  'Clear',
                  style: _ui(13, w: FontWeight.w700, c: T.danger),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: _ui(13, w: FontWeight.w700, c: T.muted),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _menuHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
    child: Row(
      children: [
        const _BrandMark(size: 38),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('POS Terminal', style: _ui(20, w: FontWeight.w800, ls: -0.3)),
            Text(
              'Zaytouna Park',
              style: _ui(11, w: FontWeight.w600, c: T.muted),
            ),
          ],
        ),
      ],
    ),
  );

  // ─── VIEW TOGGLE (Menu / Retail) ────────────────────────────────────
  Widget _viewToggle() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: T.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _seg(
            PosView.menu,
            Icons.restaurant_menu_rounded,
            'Kitchen',
            T.primary,
          ),
          _seg(
            PosView.inventory,
            Icons.shopping_basket_outlined,
            'Retail',
            T.warn,
          ),
        ],
      ),
    ),
  );

  Widget _seg(PosView v, IconData icon, String label, Color active) {
    final selected = _currentView == v;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _currentView = v;
            _selectedCategory = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? T.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? active : T.muted2),
              const SizedBox(width: 6),
              Text(
                label,
                style: _ui(
                  12,
                  w: FontWeight.w800,
                  c: selected ? active : T.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryTabs() {
    final cats = _currentCategories;
    if (cats.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: cats.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            if (i == 0) {
              return _CatPill(
                title: 'All',
                isSelected: _selectedCategory == null,
                accent: _viewAccent,
                onTap: () => setState(() => _selectedCategory = null),
              );
            }
            final c = cats[i - 1];
            return _CatPill(
              title: c.name,
              isSelected: _selectedCategory?.id == c.id,
              accent: _viewAccent,
              onTap: () => setState(() => _selectedCategory = c),
            );
          },
        ),
      ),
    );
  }

  Widget _itemsGrid() {
    final items = _currentDisplayItems;
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No items here',
        hint: 'Try a different category or section',
      );
    }
    return LayoutBuilder(
      builder: (_, c) {
        final cols = (c.maxWidth / 165).floor().clamp(2, 6);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _ProductTile(
            item: items[i],
            accent: items[i].isInventoryItem ? T.warn : T.primary,
            onTap: () => _addToCart(items[i]),
          ),
        );
      },
    );
  }
}

// ─── REUSABLE WIDGETS (unchanged from before) ─────────────────────────
class _BrandMark extends StatelessWidget {
  final double size;
  const _BrandMark({this.size = 36});
  @override
  Widget build(BuildContext context) => Container(
    height: size,
    width: size,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [T.primary, T.primaryD],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(size * 0.28),
      boxShadow: [
        BoxShadow(
          color: T.primary.withValues(alpha: 0.25),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Center(
      child: Icon(
        Icons.point_of_sale_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    ),
  );
}

class _EditPill extends StatelessWidget {
  final int id;
  const _EditPill({required this.id});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: T.warnBg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text('Edit #$id', style: _eyebrow(10, c: T.warn)),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, hint;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.hint,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: T.surfaceAlt,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: T.muted2),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: _ui(14, w: FontWeight.w800, c: T.ink2),
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: _ui(12, w: FontWeight.w500, c: T.muted),
        ),
      ],
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? tooltip;
  final VoidCallback? onTap;
  const _IconBtn({
    required this.icon,
    required this.color,
    this.tooltip,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: onTap == null ? T.muted2 : color),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

class _QtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDec, onInc;
  const _QtyStepper({
    required this.quantity,
    required this.onDec,
    required this.onInc,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: T.bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: T.lineSoft),
    ),
    child: Row(
      children: [
        _btn(Icons.remove_rounded, onDec),
        Container(
          width: 28,
          alignment: Alignment.center,
          child: Text('$quantity', style: _mono(13, w: FontWeight.w800)),
        ),
        _btn(Icons.add_rounded, onInc),
      ],
    ),
  );
  Widget _btn(IconData i, VoidCallback onTap) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(i, size: 14, color: T.ink),
      ),
    ),
  );
}

class _Selector extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Selector({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          border: Border.all(color: color.withValues(alpha: 0.20)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 13, color: color),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: _eyebrow(9)),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: _ui(12, w: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: T.muted2,
              size: 16,
            ),
          ],
        ),
      ),
    ),
  );
}

class _CatPill extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;
  const _CatPill({
    required this.title,
    required this.isSelected,
    required this.accent,
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
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? accent : T.surface,
          border: Border.all(color: isSelected ? accent : T.line),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: _ui(
            12,
            w: FontWeight.w800,
            c: isSelected ? Colors.white : T.muted,
          ),
        ),
      ),
    ),
  );
}

class _ProductTile extends StatefulWidget {
  final PosProduct item;
  final Color accent;
  final VoidCallback onTap;
  const _ProductTile({
    required this.item,
    required this.accent,
    required this.onTap,
  });
  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final accent = widget.accent;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.97 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: T.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: T.lineSoft),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.02 : 0.04),
                blurRadius: _pressed ? 4 : 8,
                offset: Offset(0, _pressed ? 1 : 3),
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
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _fallback(accent),
                          ),
                        )
                      : _fallback(accent),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _ui(
                          11.5,
                          w: FontWeight.w700,
                        ).copyWith(height: 1.15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: _mono(14, w: FontWeight.w900, c: accent),
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

  Widget _fallback(Color accent) {
    final icon = widget.item.isInventoryItem
        ? Icons.shopping_basket_rounded
        : Icons.restaurant_rounded;
    return Center(
      child: Icon(icon, size: 30, color: accent.withValues(alpha: 0.55)),
    );
  }
}

// ─── EMBEDDED CHECKOUT PANEL (unchanged) ──────────────────────────────
class _EmbeddedCheckoutPanel extends StatefulWidget {
  final double totalUSD, exchangeRate;
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
  late double rate;
  late TextEditingController _rateCtrl;

  @override
  void initState() {
    super.initState();
    rate = widget.exchangeRate;
    _rateCtrl = TextEditingController(text: rate.toInt().toString());
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  double get receivedUSD => tenderedUSD + (tenderedLBP / rate);
  double get changeUSD => receivedUSD - widget.totalUSD;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _IconBtn(
              icon: Icons.arrow_back_rounded,
              color: T.ink,
              onTap: widget.onBack,
            ),
            const SizedBox(width: 4),
            Text(
              'Complete Checkout',
              style: _ui(22, w: FontWeight.w800, ls: -0.3),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [T.primary, T.primaryD],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: T.primary.withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AMOUNT DUE',
                style: _eyebrow(10, c: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 6),
              Text(
                '\$${widget.totalUSD.toStringAsFixed(2)}',
                style: _mono(30, w: FontWeight.w900, c: Colors.white),
              ),
              Text(
                '${roundToNearest5000(widget.totalUSD * rate)} LBP',
                style: _mono(
                  14,
                  w: FontWeight.w700,
                  c: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _input(
                'Tender USD',
                (v) => setState(() => tenderedUSD = double.tryParse(v) ?? 0),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _input(
                'Tender LBP',
                (v) => setState(() => tenderedLBP = int.tryParse(v) ?? 0),
                prefix: 'LBP ',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _input(
                'Exchange Rate (LBP/\$)',
                (v) {
                  final r = double.tryParse(v) ?? 90000.0;
                  setState(() => rate = r > 0 ? r : 90000.0);
                  widget.onExchangeRateChanged(rate);
                },
                prefix: 'LBP ',
                controller: _rateCtrl,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 22),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: T.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: T.lineSoft),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _changeRow(
                      'Return USD',
                      '\$${changeUSD.toStringAsFixed(2)}',
                      changeUSD < 0 ? T.danger : T.success,
                    ),
                    const SizedBox(height: 4),
                    _changeRow(
                      'Return LBP',
                      '${roundToNearest5000(changeUSD * rate)} LBP',
                      changeUSD < 0 ? T.danger : T.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _methodBtn(
                'SAVE UNPAID',
                Icons.receipt_long_rounded,
                T.warn,
                onTap: () => widget.onConfirm('pending', true, false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _methodBtn(
                'CARD',
                Icons.credit_card_rounded,
                T.info,
                onTap: () => widget.onConfirm('card', false, true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _methodBtn(
                'CASH',
                Icons.payments_rounded,
                T.success,
                onTap: () => widget.onConfirm('cash', false, true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _methodBtn(
                'PRINT & PAY',
                Icons.print_rounded,
                T.primary,
                isPrimary: true,
                onTap: () => widget.onConfirm('cash', true, true),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _input(
    String label,
    Function(String) onChange, {
    String prefix = '\$ ',
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _eyebrow(10)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: _mono(18, w: FontWeight.w800),
          decoration: InputDecoration(
            prefixText: prefix,
            prefixStyle: _mono(16, w: FontWeight.w700, c: T.muted2),
            filled: true,
            fillColor: T.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: T.lineSoft),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: T.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
          onChanged: onChange,
        ),
      ],
    );
  }

  Widget _changeRow(String label, String val, Color color) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: _ui(12, w: FontWeight.w700, c: T.ink2),
      ),
      Text(
        val,
        style: _mono(14, w: FontWeight.w900, c: color),
      ),
    ],
  );

  Widget _methodBtn(
    String label,
    IconData icon,
    Color color, {
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    final underpaid = changeUSD < 0 && isPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: underpaid
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onTap();
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isPrimary && !underpaid
                ? LinearGradient(colors: [color, color.withValues(alpha: 0.82)])
                : null,
            color: !isPrimary ? T.surface : (underpaid ? T.lineSoft : null),
            border: Border.all(color: underpaid ? T.line : color, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isPrimary && !underpaid
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary
                    ? Colors.white
                    : (underpaid ? T.muted2 : color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: _ui(
                  12,
                  w: FontWeight.w800,
                  c: isPrimary ? Colors.white : (underpaid ? T.muted2 : color),
                  ls: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
