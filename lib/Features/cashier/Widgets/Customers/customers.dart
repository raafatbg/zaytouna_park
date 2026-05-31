// lib/Features/cashier/Widgets/Customers/customers_screen.dart
// Zaytouna POS — Customers Screen (gold + Inter, with real order history)

// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── PALETTE (gold, matches terminal/orders/dashboard) ────────────────────
class CustomerColors {
  CustomerColors._();

  static const bg = Color(0xFFFAFAF7);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF5F5F0);
  static const surface3 = Color(0xFFEDEDE5);
  static const border = Color(0xFFE5E7EB);

  static const text = Color(0xFF0A0F0D);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const textDim = Color(0xFFCBD5E1);

  // PRIMARY = ZAYTOUNA GOLD (kept named `blue` so existing refs still work)
  static const blue = Color(0xFFB8860B);
  static const blueLight = Color(0xFFFFF7DB);
  static const blueDim = Color(0x1AB8860B);

  static const green = Color(0xFF059669);
  static const greenLight = Color(0xFFD1FAE5);
  static const greenDim = Color(0x1A059669);

  static const red = Color(0xFFDC2626);
  static const redLight = Color(0xFFFEE2E2);
  static const redDim = Color(0x1FDC2626);

  static const orange = Color(0xFFD97706);
  static const orangeLight = Color(0xFFFEF3C7);
  static const orangeDim = Color(0x1AD97706);

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
}

// ─── FONTS (Inter + tabular figures) ──────────────────────────────────────
class CustomerFonts {
  CustomerFonts._();

  static TextStyle display(
    double size, {
    FontWeight w = FontWeight.w800,
    Color? color,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color ?? CustomerColors.text,
    letterSpacing: -0.3,
  );

  static TextStyle sans(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color ?? CustomerColors.text,
  );

  static TextStyle mono(
    double size, {
    FontWeight w = FontWeight.w600,
    Color? color,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color ?? CustomerColors.text,
    letterSpacing: -0.2,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

// ─── MODELS ───────────────────────────────────────────────────────────────
class LedgerEntry {
  final String id;
  final String type; // 'purchase' | 'payment'
  final double amount;
  final String note;
  final DateTime date;
  LedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
  });
}

class Customer {
  final String id;
  String name;
  String phone;
  String email;
  DateTime createdAt;
  int loyaltyPoints;
  double totalSpent;
  DateTime? lastVisit;
  DateTime joinDate;
  List<LedgerEntry> ledger;
  final Color color;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.createdAt,
    required this.loyaltyPoints,
    required this.totalSpent,
    this.lastVisit,
    required this.joinDate,
    List<LedgerEntry>? ledger,
    Color? color,
  }) : ledger = ledger ?? [],
       color = color ?? _avatarColor(id);

  static Color _avatarColor(String id) {
    const palette = [
      CustomerColors.blue,
      CustomerColors.green,
      CustomerColors.orange,
      CustomerColors.purple,
      CustomerColors.cyan,
      CustomerColors.pink,
      CustomerColors.red,
      CustomerColors.yellow,
    ];
    return palette[id.hashCode.abs() % palette.length];
  }

  double get totalPurchases => ledger
      .where((e) => e.type == 'purchase')
      .fold(0.0, (s, e) => s + e.amount);
  double get totalPayments => ledger
      .where((e) => e.type == 'payment')
      .fold(0.0, (s, e) => s + e.amount);
  double get balance => totalPurchases - totalPayments;
  int get transactionCount => ledger.length;
  int get orderCount => ledger.where((e) => e.type == 'purchase').length;
  bool get isSettled => balance.abs() < 0.005;
}

// ─── CUSTOMERS SCREEN ─────────────────────────────────────────────────────
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late final SupabaseClient _supabase;
  final _searchCtrl = TextEditingController();

  List<Customer> _customers = [];
  List<Customer> _cachedFiltered = [];
  String _searchQuery = '';
  Customer? _selected;
  bool _loading = true;

  Color get bg => CustomerColors.bg;
  Color get surface => CustomerColors.surface;
  Color get surface2 => CustomerColors.surface2;
  Color get border => CustomerColors.border;
  Color get textClr => CustomerColors.text;
  Color get textMuted => CustomerColors.textSecondary;
  Color get textDim => CustomerColors.textMuted;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _loadCustomers();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    try {
      final data = await _supabase
          .from('customers')
          .select(
            'id, name, email, phone, loyalty_points, total_spent, created_at',
          )
          .order('created_at', ascending: false);

      final customers = <Customer>[];
      for (final c in data) {
        final name = c['name'] as String?;
        if (name == null || name.trim().isEmpty) continue;
        customers.add(
          Customer(
            id: c['id'].toString(),
            name: name,
            email: c['email'] ?? '',
            phone: c['phone'] ?? '',
            createdAt: DateTime.parse(
              c['created_at'] ?? DateTime.now().toIso8601String(),
            ),
            loyaltyPoints: (c['loyalty_points'] as num?)?.toInt() ?? 0,
            totalSpent: (c['total_spent'] as num?)?.toDouble() ?? 0.0,
            lastVisit: null,
            joinDate: DateTime.parse(
              c['created_at'] ?? DateTime.now().toIso8601String(),
            ),
          ),
        );
      }

      // Pull real order history into each customer's ledger.
      await _loadOrdersInto(customers);

      if (mounted) {
        setState(() {
          _customers = customers;
          _recalculateFiltered();
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading customers: $e');
      if (mounted) {
        setState(() {
          _customers = [];
          _recalculateFiltered();
          _loading = false;
        });
        _showToast('Could not load customers: $e', CustomerColors.red);
      }
    }
  }

  /// Pulls every non-voided order linked to any of these customers and turns
  /// each one into ledger entries: a "purchase" for the full order total and
  /// a "payment" for whatever has been paid (0 if unpaid).
  /// balance = purchases − payments. 0 ⇒ Settled, > 0 ⇒ Owed.
  Future<void> _loadOrdersInto(List<Customer> customers) async {
    if (customers.isEmpty) return;
    final ids = customers.map((c) => c.id).toList();

    try {
      final orders = await _supabase
          .from('orders')
          .select()
          .inFilter('customer_id', ids)
          .order('created_at', ascending: true);

      final byCustomer = <String, Customer>{for (final c in customers) c.id: c};

      for (final o in orders) {
        final cid = o['customer_id']?.toString();
        if (cid == null) continue;
        final cust = byCustomer[cid];
        if (cust == null) continue;

        // Skip voided/cancelled under either column name
        final status = (o['order_status'] ?? o['status'])
            ?.toString()
            .toLowerCase();
        if (status == 'voided' ||
            status == 'cancelled' ||
            status == 'canceled') {
          continue;
        }

        // Defensive: real total column name varies across deployments
        final total =
            (o['total'] as num?)?.toDouble() ??
            (o['total_amount'] as num?)?.toDouble() ??
            (o['grand_total'] as num?)?.toDouble() ??
            (o['amount'] as num?)?.toDouble() ??
            0.0;

        final payStatus = (o['payment_status'] ?? o['paid_status'])
            ?.toString()
            .toLowerCase();
        final paid =
            (o['paid_amount'] as num?)?.toDouble() ??
            (o['amount_paid'] as num?)?.toDouble() ??
            (payStatus == 'paid' || payStatus == 'fully_paid' ? total : 0.0);

        final date =
            DateTime.tryParse(o['created_at']?.toString() ?? '') ??
            DateTime.now();

        final oid = o['id']?.toString() ?? '?';
        final shortId = oid.length > 6 ? oid.substring(0, 6) : oid;

        cust.ledger.add(
          LedgerEntry(
            id: 'O$oid-P',
            type: 'purchase',
            amount: total,
            note: 'Order #$shortId',
            date: date,
          ),
        );

        if (paid > 0) {
          cust.ledger.add(
            LedgerEntry(
              id: 'O$oid-Y',
              type: 'payment',
              amount: paid,
              note: paid >= total ? 'Paid in full' : 'Partial payment',
              date: date,
            ),
          );
        }
      }

      // Stable chronological order inside each customer
      for (final cust in customers) {
        cust.ledger.sort((a, b) => a.date.compareTo(b.date));
      }
    } catch (e) {
      // Non-fatal — customers still load, ledger just stays empty
      print('Order history unavailable: $e');
    }
  }

  void _onSearchChanged() => _updateSearch(_searchCtrl.text);

  void _updateSearch(String query) {
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
        _recalculateFiltered();
      });
    }
  }

  void _recalculateFiltered() {
    var list = List<Customer>.from(_customers);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.phone.contains(q) ||
                c.email.toLowerCase().contains(q) ||
                c.id.toLowerCase().contains(q),
          )
          .toList();
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    _cachedFiltered = list;
  }

  Future<void> _addCustomer(Customer c) async {
    try {
      final newCust = await _supabase
          .from('customers')
          .insert({
            'name': c.name,
            'email': c.email,
            'phone': c.phone,
            'loyalty_points': c.loyaltyPoints,
          })
          .select()
          .single();

      final created = Customer(
        id: newCust['id'].toString(),
        name: newCust['name'],
        email: newCust['email'] ?? '',
        phone: newCust['phone'] ?? '',
        createdAt: DateTime.parse(
          newCust['created_at'] ?? DateTime.now().toIso8601String(),
        ),
        loyaltyPoints: (newCust['loyalty_points'] as num?)?.toInt() ?? 0,
        totalSpent: (newCust['total_spent'] as num?)?.toDouble() ?? 0.0,
        lastVisit: null,
        joinDate: DateTime.parse(
          newCust['created_at'] ?? DateTime.now().toIso8601String(),
        ),
      );

      setState(() {
        _customers.add(created);
        _recalculateFiltered();
      });
      _showToast('Customer added', CustomerColors.green);
    } catch (e) {
      print('Error adding customer: $e');
      _showToast('Failed to add customer', CustomerColors.red);
    }
  }

  Future<void> _deleteCustomer(String id) async {
    try {
      await _supabase.from('customers').delete().eq('id', id);
      setState(() {
        _customers.removeWhere((c) => c.id == id);
        if (_selected?.id == id) _selected = null;
        _recalculateFiltered();
      });
      _showToast('Customer deleted', CustomerColors.green);
    } catch (e) {
      print('Error deleting customer: $e');
      _showToast('Failed to delete customer', CustomerColors.red);
    }
  }

  Future<void> _editCustomer(Customer u) async {
    try {
      await _supabase
          .from('customers')
          .update({
            'name': u.name,
            'email': u.email,
            'phone': u.phone,
            'loyalty_points': u.loyaltyPoints,
          })
          .eq('id', u.id);

      setState(() {
        final i = _customers.indexWhere((c) => c.id == u.id);
        if (i != -1) _customers[i] = u;
        if (_selected?.id == u.id) _selected = u;
        _recalculateFiltered();
      });
      _showToast('Customer updated', CustomerColors.blue);
    } catch (e) {
      print('Error editing customer: $e');
      _showToast('Failed to update customer', CustomerColors.red);
    }
  }

  void _addLedgerEntry(Customer c, LedgerEntry e) {
    setState(() {
      c.ledger.add(e);
      if (_selected?.id == c.id) _selected = c;
      _recalculateFiltered();
    });
  }

  int get _totalCustomers => _customers.length;
  double get _totalReceivables =>
      _customers.fold(0.0, (s, c) => s + (c.balance > 0 ? c.balance : 0));
  double get _totalPurchases =>
      _customers.fold(0.0, (s, c) => s + c.totalPurchases);
  int get _activeBalances => _customers.where((c) => c.balance > 0.005).length;

  void _showToast(String msg, Color color) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
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
            Expanded(
              child: Text(
                msg,
                style: CustomerFonts.sans(
                  13.sp,
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

  // ── Dialogs ─────────────────────────────────────────────────────────────
  void _showAddDialog() {
    final nc = TextEditingController();
    final pc = TextEditingController();
    final ec = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => _CustomerFormDialog(
        isEdit: false,
        nameCtrl: nc,
        phoneCtrl: pc,
        emailCtrl: ec,
        onSave: () {
          if (nc.text.trim().isNotEmpty) {
            _addCustomer(
              Customer(
                id: 'C${(_customers.length + 1).toString().padLeft(3, '0')}',
                name: nc.text.trim(),
                phone: pc.text.trim(),
                email: ec.text.trim(),
                createdAt: DateTime.now(),
                joinDate: DateTime.now(),
                loyaltyPoints: 0,
                totalSpent: 0.0,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditDialog(Customer c) {
    final nc = TextEditingController(text: c.name);
    final pc = TextEditingController(text: c.phone);
    final ec = TextEditingController(text: c.email);

    showDialog(
      context: context,
      builder: (_) => _CustomerFormDialog(
        isEdit: true,
        nameCtrl: nc,
        phoneCtrl: pc,
        emailCtrl: ec,
        onSave: () {
          _editCustomer(
            Customer(
              id: c.id,
              name: nc.text.trim(),
              phone: pc.text.trim(),
              email: ec.text.trim(),
              createdAt: c.createdAt,
              joinDate: c.joinDate,
              loyaltyPoints: c.loyaltyPoints,
              totalSpent: c.totalSpent,
              ledger: c.ledger,
              color: c.color,
            ),
          );
        },
      ),
    );
  }

  void _showLedgerDialog(Customer c) {
    final ac = TextEditingController();
    final note = TextEditingController();
    String selectedType = 'payment';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => _LedgerDialog(
          customer: c,
          amountCtrl: ac,
          noteCtrl: note,
          selectedType: selectedType,
          onTypeChanged: (t) => set(() => selectedType = t),
          onSave: (type) {
            final amt = double.tryParse(ac.text) ?? 0;
            if (amt <= 0) return;
            _addLedgerEntry(
              c,
              LedgerEntry(
                id: 'L${DateTime.now().millisecondsSinceEpoch}',
                type: type,
                amount: amt,
                note: note.text.trim().isEmpty
                    ? (type == 'payment' ? 'Payment received' : 'New purchase')
                    : note.text.trim(),
                date: DateTime.now(),
              ),
            );
            _showToast(
              type == 'payment' ? 'Payment recorded' : 'Purchase recorded',
              CustomerColors.green,
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(Customer c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Delete Customer',
          style: CustomerFonts.display(16.sp, w: FontWeight.w800),
        ),
        content: Text(
          'Remove "${c.name}" permanently? This action cannot be undone.',
          style: CustomerFonts.sans(13.sp, color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: CustomerFonts.sans(12.sp, color: textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomerColors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteCustomer(c.id);
            },
            child: Text(
              'Delete',
              style: CustomerFonts.sans(
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

  void _showDetailSheet(Customer c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailSheet(
        customer: c,
        onEdit: () {
          Navigator.pop(context);
          _showEditDialog(c);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(c);
        },
        onLedger: () {
          Navigator.pop(context);
          _showLedgerDialog(c);
        },
        onHistory: () {
          Navigator.pop(context);
          _OrderHistorySheet.show(context, c);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              _TopBar(searchCtrl: _searchCtrl, onAdd: _showAddDialog),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: CustomerColors.blue,
                          strokeWidth: 3,
                        ),
                      )
                    : RefreshIndicator(
                        color: CustomerColors.blue,
                        onRefresh: _loadCustomers,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _WelcomeHeader(),
                              SizedBox(height: 24.h),
                              _SummaryCards(
                                totalCustomers: _totalCustomers,
                                totalReceivables: _totalReceivables,
                                totalPurchases: _totalPurchases,
                                activeBalances: _activeBalances,
                                constraints: constraints,
                              ),
                              SizedBox(height: 24.h),
                              if (isWide && _selected != null)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _CustomerTable(
                                        customers: _cachedFiltered,
                                        selected: _selected,
                                        onSelect: (c) =>
                                            setState(() => _selected = c),
                                        onEdit: _showEditDialog,
                                        onDelete: _confirmDelete,
                                        onLedger: _showLedgerDialog,
                                      ),
                                    ),
                                    SizedBox(width: 20.w),
                                    Expanded(
                                      child: _DetailPanel(
                                        customer: _selected!,
                                        onEdit: () =>
                                            _showEditDialog(_selected!),
                                        onDelete: () =>
                                            _confirmDelete(_selected!),
                                        onLedger: () =>
                                            _showLedgerDialog(_selected!),
                                        onHistory: () =>
                                            _OrderHistorySheet.show(
                                              context,
                                              _selected!,
                                            ),
                                        onClose: () =>
                                            setState(() => _selected = null),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                _CustomerTable(
                                  customers: _cachedFiltered,
                                  selected: _selected,
                                  onSelect: (c) {
                                    setState(() => _selected = c);
                                    if (!isWide) _showDetailSheet(c);
                                  },
                                  onEdit: _showEditDialog,
                                  onDelete: _confirmDelete,
                                  onLedger: _showLedgerDialog,
                                ),
                              SizedBox(height: 32.h),
                            ],
                          ),
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

// ─── TOP BAR ──────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final VoidCallback onAdd;
  const _TopBar({required this.searchCtrl, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final showTitle = MediaQuery.of(context).size.width > 600;
    final user = Supabase.instance.client.auth.currentUser;
    final initial = (user?.email?.isNotEmpty ?? false)
        ? user!.email![0].toUpperCase()
        : 'U';

    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: CustomerColors.surface,
        border: const Border(bottom: BorderSide(color: CustomerColors.border)),
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
              gradient: const LinearGradient(
                colors: [CustomerColors.blue, Color(0xFF8B6914)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: CustomerColors.blue.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.people_alt_rounded,
              size: 20.sp,
              color: Colors.white,
            ),
          ),
          if (showTitle) ...[
            SizedBox(width: 12.w),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUSTOMERS',
                  style: CustomerFonts.sans(
                    8.sp,
                    w: FontWeight.w800,
                    color: CustomerColors.blue,
                  ).copyWith(letterSpacing: 1.4),
                ),
                Text(
                  'Client Management',
                  style: CustomerFonts.display(16.sp, w: FontWeight.w800),
                ),
              ],
            ),
          ],
          const Spacer(),
          Flexible(
            flex: 2,
            child: Container(
              constraints: BoxConstraints(maxWidth: 240.w),
              height: 40.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: CustomerColors.surface2,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: CustomerColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18.sp,
                    color: CustomerColors.textSecondary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      style: CustomerFonts.sans(12.sp),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: CustomerFonts.sans(
                          11.sp,
                          color: CustomerColors.textMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      cursorColor: CustomerColors.blue,
                    ),
                  ),
                  if (searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => searchCtrl.clear(),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16.sp,
                        color: CustomerColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              height: 40.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CustomerColors.blue, Color(0xFF8B6914)],
                ),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: CustomerColors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 18.sp, color: Colors.white),
                  if (showTitle) ...[
                    SizedBox(width: 6.w),
                    Text(
                      'Add Customer',
                      style: CustomerFonts.sans(
                        12.sp,
                        w: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: 10.w),
          CircleAvatar(
            radius: 18.r,
            backgroundColor: CustomerColors.blueLight,
            child: Text(
              initial,
              style: TextStyle(
                color: CustomerColors.blue,
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

// ─── WELCOME HEADER ───────────────────────────────────────────────────────
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
            color: CustomerColors.blueLight,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5.w,
                height: 5.w,
                decoration: const BoxDecoration(
                  color: CustomerColors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'CUSTOMER MANAGEMENT',
                style: CustomerFonts.sans(
                  8.sp,
                  w: FontWeight.w800,
                  color: CustomerColors.blue,
                ).copyWith(letterSpacing: 1.4),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Client Directory',
          style: CustomerFonts.display(32.sp, w: FontWeight.w800),
        ),
        SizedBox(height: 6.h),
        Text(
          'Manage your customers, track balances, and view transaction history.',
          style: CustomerFonts.sans(12.sp, color: CustomerColors.textSecondary),
        ),
      ],
    );
  }
}

// ─── SUMMARY CARDS ────────────────────────────────────────────────────────
class _SummaryCards extends StatelessWidget {
  final int totalCustomers;
  final double totalReceivables;
  final double totalPurchases;
  final int activeBalances;
  final BoxConstraints constraints;

  const _SummaryCards({
    required this.totalCustomers,
    required this.totalReceivables,
    required this.totalPurchases,
    required this.activeBalances,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SD(
        'Total Customers',
        '$totalCustomers',
        Icons.people_alt_rounded,
        CustomerColors.blue,
        CustomerColors.blueLight,
        'Active accounts',
      ),
      _SD(
        'Outstanding Owed',
        '\$${totalReceivables.toStringAsFixed(2)}',
        Icons.account_balance_wallet_outlined,
        CustomerColors.orange,
        CustomerColors.orangeLight,
        'Not yet paid',
      ),
      _SD(
        'Total Purchases',
        '\$${totalPurchases.toStringAsFixed(2)}',
        Icons.shopping_cart_rounded,
        CustomerColors.green,
        CustomerColors.greenLight,
        'All time',
      ),
      _SD(
        'Customers Owing',
        '$activeBalances',
        Icons.pending_actions_rounded,
        CustomerColors.purple,
        CustomerColors.purpleLight,
        'With balance',
      ),
    ];

    if (constraints.maxWidth >= 900) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(width: 16.w),
            Expanded(child: _SummaryCard(data: cards[i])),
          ],
        ],
      );
    } else if (constraints.maxWidth >= 600) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _SummaryCard(data: cards[0])),
              SizedBox(width: 12.w),
              Expanded(child: _SummaryCard(data: cards[1])),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: _SummaryCard(data: cards[2])),
              SizedBox(width: 12.w),
              Expanded(child: _SummaryCard(data: cards[3])),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            _SummaryCard(data: cards[i]),
            if (i < 3) SizedBox(height: 10.h),
          ],
        ],
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final _SD data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: CustomerColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: CustomerColors.border),
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
                  color: data.accentDim,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(data.icon, size: 20.sp, color: data.accent),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: data.accentDim,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  data.sub,
                  style: CustomerFonts.mono(9.sp, color: data.accent),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: CustomerFonts.mono(22.sp, w: FontWeight.w800),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            data.label,
            style: CustomerFonts.sans(
              11.sp,
              color: CustomerColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CUSTOMER TABLE ───────────────────────────────────────────────────────
class _CustomerTable extends StatelessWidget {
  final List<Customer> customers;
  final Customer? selected;
  final Function(Customer) onSelect;
  final Function(Customer) onEdit;
  final Function(Customer) onDelete;
  final Function(Customer) onLedger;

  const _CustomerTable({
    required this.customers,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onLedger,
  });

  static const _headers = [
    'ID',
    'Customer',
    'Contact',
    'Purchases',
    'Paid',
    'Status',
    'Orders',
    '',
  ];

  List<double> get _widths => [
    70.w,
    220.w,
    180.w,
    110.w,
    110.w,
    130.w,
    90.w,
    140.w,
  ];

  double get _tableWidth => _widths.fold(0.0, (a, b) => a + b) + 32.w;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: CustomerColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _tableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: CustomerColors.surface2,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(14.r),
                  ),
                  border: const Border(
                    bottom: BorderSide(color: CustomerColors.border),
                  ),
                ),
                child: Row(
                  children: List.generate(
                    _headers.length,
                    (i) => SizedBox(
                      width: _widths[i],
                      child: Text(
                        _headers[i],
                        style: CustomerFonts.sans(
                          9.sp,
                          w: FontWeight.w800,
                          color: CustomerColors.textDim,
                        ).copyWith(letterSpacing: 1.2),
                      ),
                    ),
                  ),
                ),
              ),
              if (customers.isEmpty)
                Padding(
                  padding: EdgeInsets.all(48.w),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CustomerColors.surface2,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.people_outline_rounded,
                            size: 36.sp,
                            color: CustomerColors.textMuted,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No customers found',
                          style: CustomerFonts.sans(
                            14.sp,
                            w: FontWeight.w700,
                            color: CustomerColors.text,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Add your first customer to get started',
                          style: CustomerFonts.sans(
                            12.sp,
                            color: CustomerColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...customers.map(
                  (c) => _TableRow(
                    customer: c,
                    isSelected: selected?.id == c.id,
                    colWidths: _widths,
                    onTap: () => onSelect(c),
                    onEdit: () => onEdit(c),
                    onDelete: () => onDelete(c),
                    onLedger: () => onLedger(c),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  final Customer customer;
  final bool isSelected;
  final List<double> colWidths;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLedger;

  const _TableRow({
    required this.customer,
    required this.isSelected,
    required this.colWidths,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onLedger,
  });

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final settled = c.isSettled;
    final statusColor = settled ? CustomerColors.green : CustomerColors.orange;
    final statusBg = settled
        ? CustomerColors.greenLight
        : CustomerColors.orangeLight;
    final statusLabel = settled
        ? 'Settled'
        : 'Owes \$${c.balance.toStringAsFixed(2)}';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? CustomerColors.blueLight
                : (_hovered ? CustomerColors.surface2 : CustomerColors.surface),
            border: Border(
              bottom: const BorderSide(color: CustomerColors.border),
              left: BorderSide(
                color: widget.isSelected
                    ? CustomerColors.blue
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: widget.colWidths[0],
                child: Text(
                  c.id,
                  style: CustomerFonts.mono(
                    10.sp,
                    color: CustomerColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: widget.colWidths[1],
                child: Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: c.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          c.name.isNotEmpty ? c.name[0].toUpperCase() : 'U',
                          style: CustomerFonts.sans(
                            12.sp,
                            w: FontWeight.w800,
                            color: c.color,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.name,
                            overflow: TextOverflow.ellipsis,
                            style: CustomerFonts.sans(
                              12.sp,
                              w: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            c.email,
                            overflow: TextOverflow.ellipsis,
                            style: CustomerFonts.sans(
                              10.sp,
                              color: CustomerColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: widget.colWidths[2],
                child: Text(
                  c.phone,
                  style: CustomerFonts.mono(
                    10.sp,
                    color: CustomerColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: widget.colWidths[3],
                child: Text(
                  '\$${c.totalPurchases.toStringAsFixed(2)}',
                  style: CustomerFonts.mono(
                    11.sp,
                    w: FontWeight.w700,
                    color: CustomerColors.blue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: widget.colWidths[4],
                child: Text(
                  '\$${c.totalPayments.toStringAsFixed(2)}',
                  style: CustomerFonts.mono(
                    11.sp,
                    w: FontWeight.w700,
                    color: CustomerColors.green,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: widget.colWidths[5],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          settled
                              ? Icons.check_circle_rounded
                              : Icons.access_time_rounded,
                          size: 11.sp,
                          color: statusColor,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            statusLabel,
                            style: CustomerFonts.mono(
                              10.sp,
                              w: FontWeight.w700,
                              color: statusColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: widget.colWidths[6],
                child: Text(
                  '${c.orderCount}',
                  style: CustomerFonts.sans(
                    11.sp,
                    w: FontWeight.w700,
                    color: CustomerColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: widget.colWidths[7],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionButton(
                      icon: Icons.receipt_long_rounded,
                      color: CustomerColors.blue,
                      onTap: () => _OrderHistorySheet.show(context, c),
                    ),
                    SizedBox(width: 6.w),
                    _ActionButton(
                      icon: Icons.payments_outlined,
                      color: CustomerColors.green,
                      onTap: widget.onLedger,
                    ),
                    SizedBox(width: 6.w),
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      color: CustomerColors.textSecondary,
                      onTap: widget.onEdit,
                    ),
                    SizedBox(width: 6.w),
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: CustomerColors.red,
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Icon(icon, size: 16.sp, color: color),
      ),
    );
  }
}

// ─── DETAIL PANEL (Desktop) ───────────────────────────────────────────────
class _DetailPanel extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLedger;
  final VoidCallback onHistory;
  final VoidCallback onClose;

  const _DetailPanel({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onLedger,
    required this.onHistory,
    required this.onClose,
  });

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final settled = customer.isSettled;
    final balColor = settled ? CustomerColors.green : CustomerColors.orange;

    return Container(
      decoration: BoxDecoration(
        color: CustomerColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: CustomerColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Text(
                  'Customer Details',
                  style: CustomerFonts.sans(13.sp, w: FontWeight.w800),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18.sp,
                    color: CustomerColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CustomerColors.border),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: customer.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : 'U',
                      style: CustomerFonts.display(
                        24.sp,
                        color: customer.color,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  customer.name,
                  style: CustomerFonts.display(18.sp, w: FontWeight.w800),
                ),
                SizedBox(height: 4.h),
                Text(
                  customer.id,
                  style: CustomerFonts.mono(
                    11.sp,
                    color: CustomerColors.textSecondary,
                  ),
                ),
                SizedBox(height: 16.h),
                _DetailRow(icon: Icons.phone_rounded, label: customer.phone),
                SizedBox(height: 8.h),
                _DetailRow(icon: Icons.email_rounded, label: customer.email),
                SizedBox(height: 8.h),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Customer since ${_formatDate(customer.createdAt)}',
                ),
                SizedBox(height: 16.h),
                // Big status banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: settled
                        ? CustomerColors.greenLight
                        : CustomerColors.orangeLight,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: balColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        settled
                            ? Icons.check_circle_rounded
                            : Icons.account_balance_wallet_rounded,
                        color: balColor,
                        size: 20.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              settled ? 'Settled' : 'Outstanding',
                              style: CustomerFonts.sans(
                                12.sp,
                                w: FontWeight.w800,
                                color: balColor,
                              ),
                            ),
                            Text(
                              settled
                                  ? 'All paid'
                                  : 'Owes \$${customer.balance.toStringAsFixed(2)}',
                              style: CustomerFonts.sans(
                                10.sp,
                                color: CustomerColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        settled
                            ? '\$0.00'
                            : '\$${customer.balance.toStringAsFixed(2)}',
                        style: CustomerFonts.mono(
                          16.sp,
                          w: FontWeight.w800,
                          color: balColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: CustomerColors.surface2,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '\$${customer.totalPurchases.toStringAsFixed(2)}',
                              style: CustomerFonts.mono(
                                14.sp,
                                w: FontWeight.w800,
                                color: CustomerColors.blue,
                              ),
                            ),
                            Text(
                              'Purchases',
                              style: CustomerFonts.sans(
                                10.sp,
                                color: CustomerColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '\$${customer.totalPayments.toStringAsFixed(2)}',
                              style: CustomerFonts.mono(
                                14.sp,
                                w: FontWeight.w800,
                                color: CustomerColors.green,
                              ),
                            ),
                            Text(
                              'Paid',
                              style: CustomerFonts.sans(
                                10.sp,
                                color: CustomerColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${customer.orderCount}',
                              style: CustomerFonts.mono(
                                14.sp,
                                w: FontWeight.w800,
                                color: CustomerColors.purple,
                              ),
                            ),
                            Text(
                              'Orders',
                              style: CustomerFonts.sans(
                                10.sp,
                                color: CustomerColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Text(
                      'Recent Transactions',
                      style: CustomerFonts.sans(12.sp, w: FontWeight.w800),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onHistory,
                      child: Text(
                        'See all (${customer.ledger.length})',
                        style: CustomerFonts.sans(
                          11.sp,
                          w: FontWeight.w700,
                          color: CustomerColors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                if (customer.ledger.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Text(
                      'No transactions yet',
                      style: CustomerFonts.sans(
                        11.sp,
                        color: CustomerColors.textMuted,
                      ),
                    ),
                  )
                else
                  ...customer.ledger.reversed
                      .take(3)
                      .map((e) => _TransactionRow(entry: e)),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onLedger,
                        icon: Icon(Icons.add_rounded, size: 16.sp),
                        label: const Text('Transaction'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomerColors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      color: CustomerColors.textSecondary,
                      style: IconButton.styleFrom(
                        backgroundColor: CustomerColors.surface2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: CustomerColors.red,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: CustomerColors.red.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: CustomerColors.textSecondary),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            label,
            style: CustomerFonts.sans(12.sp),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final LedgerEntry entry;
  const _TransactionRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isPurchase = entry.type == 'purchase';
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CustomerColors.border.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: isPurchase ? CustomerColors.blue : CustomerColors.green,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              entry.note,
              style: CustomerFonts.sans(11.sp),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            isPurchase
                ? '−\$${entry.amount.toStringAsFixed(2)}'
                : '+\$${entry.amount.toStringAsFixed(2)}',
            style: CustomerFonts.mono(
              11.sp,
              w: FontWeight.w700,
              color: isPurchase ? CustomerColors.red : CustomerColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DETAIL SHEET (Mobile) ────────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLedger;
  final VoidCallback onHistory;

  const _DetailSheet({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onLedger,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final settled = customer.isSettled;
    final balColor = settled ? CustomerColors.green : CustomerColors.orange;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: CustomerColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: CustomerColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: customer.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Center(
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'U',
                style: CustomerFonts.display(24.sp, color: customer.color),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            customer.name,
            style: CustomerFonts.display(18.sp, w: FontWeight.w800),
          ),
          Text(
            customer.id,
            style: CustomerFonts.mono(
              11.sp,
              color: CustomerColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          // Status banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: settled
                  ? CustomerColors.greenLight
                  : CustomerColors.orangeLight,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  settled
                      ? Icons.check_circle_rounded
                      : Icons.account_balance_wallet_rounded,
                  color: balColor,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    settled
                        ? 'Account Settled'
                        : 'Owes \$${customer.balance.toStringAsFixed(2)}',
                    style: CustomerFonts.sans(
                      12.sp,
                      w: FontWeight.w800,
                      color: balColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: CustomerColors.surface2,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '\$${customer.totalPurchases.toStringAsFixed(2)}',
                        style: CustomerFonts.mono(
                          14.sp,
                          w: FontWeight.w800,
                          color: CustomerColors.blue,
                        ),
                      ),
                      Text(
                        'Purchases',
                        style: CustomerFonts.sans(
                          10.sp,
                          color: CustomerColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${customer.orderCount}',
                        style: CustomerFonts.mono(
                          14.sp,
                          w: FontWeight.w800,
                          color: CustomerColors.purple,
                        ),
                      ),
                      Text(
                        'Orders',
                        style: CustomerFonts.sans(
                          10.sp,
                          color: CustomerColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onHistory,
              icon: Icon(Icons.receipt_long_rounded, size: 16.sp),
              label: Text('View full history (${customer.ledger.length})'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CustomerColors.blue,
                side: const BorderSide(color: CustomerColors.blue),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onLedger,
                  icon: Icon(Icons.add_rounded, size: 16.sp),
                  label: const Text('Transaction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomerColors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: CustomerColors.surface2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: CustomerColors.red,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: CustomerColors.red.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── FORM DIALOG ──────────────────────────────────────────────────────────
class _CustomerFormDialog extends StatelessWidget {
  final bool isEdit;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final VoidCallback onSave;

  const _CustomerFormDialog({
    required this.isEdit,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CustomerColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        isEdit ? 'Edit Customer' : 'Add New Customer',
        style: CustomerFonts.display(16.sp, w: FontWeight.w800),
      ),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxWidth: 320.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(
              label: 'Full Name',
              ctrl: nameCtrl,
              icon: Icons.person_outline_rounded,
            ),
            SizedBox(height: 12.h),
            _DialogField(
              label: 'Phone Number',
              ctrl: phoneCtrl,
              icon: Icons.phone_outlined,
            ),
            SizedBox(height: 12.h),
            _DialogField(
              label: 'Email Address',
              ctrl: emailCtrl,
              icon: Icons.email_outlined,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: CustomerFonts.sans(
              12.sp,
              color: CustomerColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: CustomerColors.blue,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          onPressed: () {
            onSave();
            Navigator.pop(context);
          },
          child: Text(
            isEdit ? 'Save Changes' : 'Add Customer',
            style: CustomerFonts.sans(
              12.sp,
              w: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;

  const _DialogField({
    required this.label,
    required this.ctrl,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: CustomerFonts.sans(
            9.sp,
            w: FontWeight.w800,
            color: CustomerColors.textDim,
          ).copyWith(letterSpacing: 1.2),
        ),
        SizedBox(height: 6.h),
        Container(
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: CustomerColors.surface2,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: CustomerColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16.sp, color: CustomerColors.textSecondary),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: CustomerFonts.sans(12.sp),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  cursorColor: CustomerColors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── LEDGER DIALOG ────────────────────────────────────────────────────────
class _LedgerDialog extends StatelessWidget {
  final Customer customer;
  final TextEditingController amountCtrl;
  final TextEditingController noteCtrl;
  final String selectedType;
  final Function(String) onTypeChanged;
  final Function(String) onSave;

  const _LedgerDialog({
    required this.customer,
    required this.amountCtrl,
    required this.noteCtrl,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CustomerColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'New Transaction',
            style: CustomerFonts.display(16.sp, w: FontWeight.w800),
          ),
          SizedBox(height: 4.h),
          Text(
            'For ${customer.name}',
            style: CustomerFonts.sans(
              11.sp,
              color: CustomerColors.textSecondary,
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxWidth: 300.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _typePill(
                    selected: selectedType == 'payment',
                    color: CustomerColors.green,
                    icon: Icons.arrow_downward_rounded,
                    label: 'Payment',
                    onTap: () => onTypeChanged('payment'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _typePill(
                    selected: selectedType == 'purchase',
                    color: CustomerColors.blue,
                    icon: Icons.arrow_upward_rounded,
                    label: 'Purchase',
                    onTap: () => onTypeChanged('purchase'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _DialogField(
              label: 'Amount (\$)',
              ctrl: amountCtrl,
              icon: Icons.attach_money_rounded,
            ),
            SizedBox(height: 12.h),
            _DialogField(
              label: 'Note (Optional)',
              ctrl: noteCtrl,
              icon: Icons.note_outlined,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: CustomerFonts.sans(
              12.sp,
              color: CustomerColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedType == 'payment'
                ? CustomerColors.green
                : CustomerColors.blue,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          onPressed: () {
            onSave(selectedType);
            Navigator.pop(context);
          },
          child: Text(
            'Record ${selectedType == 'payment' ? 'Payment' : 'Purchase'}',
            style: CustomerFonts.sans(
              12.sp,
              w: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _typePill({
    required bool selected,
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.12) : CustomerColors.surface2,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: selected ? color : CustomerColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: selected ? color : CustomerColors.textSecondary,
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: CustomerFonts.sans(
              11.sp,
              w: FontWeight.w700,
              color: selected ? color : CustomerColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SD {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color accent;
  final Color accentDim;
  const _SD(
    this.label,
    this.value,
    this.icon,
    this.accent,
    this.accentDim,
    this.sub,
  );
}

// ─── FULL ORDER HISTORY SHEET ─────────────────────────────────────────────
class _OrderHistorySheet extends StatelessWidget {
  final Customer customer;
  const _OrderHistorySheet({required this.customer});

  static void show(BuildContext context, Customer c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OrderHistorySheet(customer: c),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final bal = customer.balance;
    final settled = customer.isSettled;
    final entries = customer.ledger.reversed.toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: CustomerColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: CustomerColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: customer.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase()
                            : 'U',
                        style: CustomerFonts.display(
                          18.sp,
                          color: customer.color,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: CustomerFonts.display(
                            15.sp,
                            w: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Order History',
                          style: CustomerFonts.sans(
                            11.sp,
                            color: CustomerColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: CustomerColors.surface2,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18.sp,
                        color: CustomerColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: settled
                      ? CustomerColors.greenLight
                      : CustomerColors.orangeLight,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: settled
                        ? CustomerColors.green.withOpacity(0.3)
                        : CustomerColors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      settled
                          ? Icons.check_circle_rounded
                          : Icons.account_balance_wallet_rounded,
                      color: settled
                          ? CustomerColors.green
                          : CustomerColors.orange,
                      size: 22.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settled ? 'Account Settled' : 'Outstanding Balance',
                            style: CustomerFonts.sans(
                              12.sp,
                              w: FontWeight.w800,
                              color: settled
                                  ? CustomerColors.green
                                  : CustomerColors.orange,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            settled
                                ? 'All purchases are fully paid'
                                : 'Customer owes \$${bal.toStringAsFixed(2)}',
                            style: CustomerFonts.sans(
                              11.sp,
                              color: CustomerColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      settled ? '\$0.00' : '\$${bal.toStringAsFixed(2)}',
                      style: CustomerFonts.mono(
                        18.sp,
                        w: FontWeight.w800,
                        color: settled
                            ? CustomerColors.green
                            : CustomerColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Expanded(
                    child: _miniStat(
                      'Total Purchases',
                      '\$${customer.totalPurchases.toStringAsFixed(2)}',
                      CustomerColors.blue,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _miniStat(
                      'Total Paid',
                      '\$${customer.totalPayments.toStringAsFixed(2)}',
                      CustomerColors.green,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _miniStat(
                      'Orders',
                      '${customer.orderCount}',
                      CustomerColors.purple,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            const Divider(height: 1, color: CustomerColors.border),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 40.sp,
                              color: CustomerColors.textMuted,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'No transactions yet',
                              style: CustomerFonts.sans(
                                13.sp,
                                w: FontWeight.w700,
                                color: CustomerColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scroll,
                      padding: EdgeInsets.all(20.w),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => SizedBox(height: 8.h),
                      itemBuilder: (_, i) {
                        final e = entries[i];
                        final isPurchase = e.type == 'purchase';
                        final color = isPurchase
                            ? CustomerColors.blue
                            : CustomerColors.green;
                        return Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: CustomerColors.surface,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: CustomerColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  isPurchase
                                      ? Icons.shopping_cart_rounded
                                      : Icons.payments_rounded,
                                  color: color,
                                  size: 18.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.note,
                                      style: CustomerFonts.sans(
                                        12.sp,
                                        w: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      _fmt(e.date),
                                      style: CustomerFonts.sans(
                                        10.sp,
                                        color: CustomerColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isPurchase ? '−' : '+'}\$${e.amount.toStringAsFixed(2)}',
                                style: CustomerFonts.mono(
                                  13.sp,
                                  w: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Container(
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10.r),
      border: Border.all(color: color.withOpacity(0.18)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: CustomerFonts.mono(14.sp, w: FontWeight.w800, color: color),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: CustomerFonts.sans(
            9.sp,
            color: CustomerColors.textSecondary,
          ).copyWith(letterSpacing: 0.5),
        ),
      ],
    ),
  );
}
