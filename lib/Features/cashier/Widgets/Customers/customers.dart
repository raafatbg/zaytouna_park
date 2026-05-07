// lib/Features/Customers/customers_screen.dart
// Zaytouna POS - Customers Screen (Matching Inventory/Expenses Design)

// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LIGHT THEME PALETTE (Matching Inventory/Expenses)
// ─────────────────────────────────────────────────────────────────────────────

class CustomerColors {
  CustomerColors._();

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
}

// ─────────────────────────────────────────────────────────────────────────────
//  FONTS (Matching Inventory/Expenses)
// ─────────────────────────────────────────────────────────────────────────────

class CustomerFonts {
  CustomerFonts._();

  static TextStyle display(
    double size, {
    FontWeight w = FontWeight.w700,
    Color? color,
  }) => GoogleFonts.dmSerifDisplay(
    fontSize: size,
    fontWeight: w,
    color: color ?? CustomerColors.text,
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
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: w,
    color: color ?? CustomerColors.text,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────────────────────

class LedgerEntry {
  final String id;
  final String type;
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
       color = color ?? _getRandomColor(id);

  static Color _getRandomColor(String id) {
    final colors = [
      CustomerColors.blue,
      CustomerColors.green,
      CustomerColors.orange,
      CustomerColors.purple,
      CustomerColors.cyan,
      CustomerColors.pink,
      CustomerColors.red,
      CustomerColors.yellow,
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  double get totalPurchases => ledger
      .where((e) => e.type == 'purchase')
      .fold(0.0, (s, e) => s + e.amount);

  double get totalPayments => ledger
      .where((e) => e.type == 'payment')
      .fold(0.0, (s, e) => s + e.amount);

  double get balance => totalPurchases - totalPayments;

  int get transactionCount => ledger.length;
}

// ─────────────────────────────────────────────────────────────────────────────
//  MOCK DATA
// ─────────────────────────────────────────────────────────────────────────────

final _mockCustomers = <Customer>[
  Customer(
    id: 'C001',
    name: 'Alice Martin',
    phone: '+1 555 010 1234',
    email: 'alice@example.com',
    createdAt: DateTime(2024, 1, 12),
    joinDate: DateTime(2024, 1, 12),
    loyaltyPoints: 0,
    totalSpent: 0.0,
    ledger: [
      LedgerEntry(
        id: 'L001',
        type: 'purchase',
        amount: 4820.50,
        note: 'Invoice #101 - Catering Event',
        date: DateTime(2024, 3, 1),
      ),
      LedgerEntry(
        id: 'L002',
        type: 'payment',
        amount: 4700.50,
        note: 'Partial payment - Feb',
        date: DateTime(2024, 3, 10),
      ),
    ],
  ),
  Customer(
    id: 'C002',
    name: 'Bob Johnson',
    phone: '+1 555 020 5678',
    email: 'bob@example.com',
    createdAt: DateTime(2024, 3, 5),
    joinDate: DateTime(2024, 3, 5),
    loyaltyPoints: 0,
    totalSpent: 0.0,
    ledger: [
      LedgerEntry(
        id: 'L003',
        type: 'purchase',
        amount: 1340.00,
        note: 'Invoice #102',
        date: DateTime(2024, 3, 8),
      ),
      LedgerEntry(
        id: 'L004',
        type: 'payment',
        amount: 1340.00,
        note: 'Paid in full',
        date: DateTime(2024, 3, 15),
      ),
    ],
  ),
  Customer(
    id: 'C003',
    name: 'Diana Chen',
    phone: '+1 555 030 9012',
    email: 'diana.chen@example.com',
    createdAt: DateTime(2024, 2, 18),
    joinDate: DateTime(2024, 2, 18),
    loyaltyPoints: 0,
    totalSpent: 0.0,
    ledger: [
      LedgerEntry(
        id: 'L005',
        type: 'purchase',
        amount: 2350.75,
        note: 'Invoice #103 - Corporate Lunch',
        date: DateTime(2024, 2, 20),
      ),
      LedgerEntry(
        id: 'L006',
        type: 'purchase',
        amount: 890.25,
        note: 'Invoice #107 - Additional items',
        date: DateTime(2024, 3, 5),
      ),
      LedgerEntry(
        id: 'L007',
        type: 'payment',
        amount: 1500.00,
        note: 'Deposit',
        date: DateTime(2024, 2, 22),
      ),
    ],
  ),
  Customer(
    id: 'C004',
    name: 'Ethan Williams',
    phone: '+1 555 040 3456',
    email: 'ethan.w@example.com',
    createdAt: DateTime(2024, 3, 1),
    joinDate: DateTime(2024, 3, 1),
    loyaltyPoints: 0,
    totalSpent: 0.0,
    ledger: [
      LedgerEntry(
        id: 'L008',
        type: 'purchase',
        amount: 567.80,
        note: 'Invoice #108',
        date: DateTime(2024, 3, 12),
      ),
    ],
  ),
  Customer(
    id: 'C005',
    name: 'Fatima Al-Rashid',
    phone: '+1 555 050 7890',
    email: 'fatima@example.com',
    createdAt: DateTime(2024, 1, 25),
    joinDate: DateTime(2024, 1, 25),
    loyaltyPoints: 0,
    totalSpent: 0.0,
    ledger: [
      LedgerEntry(
        id: 'L009',
        type: 'purchase',
        amount: 3450.00,
        note: 'Invoice #095 - Wedding Reception',
        date: DateTime(2024, 2, 14),
      ),
      LedgerEntry(
        id: 'L010',
        type: 'payment',
        amount: 3450.00,
        note: 'Full payment',
        date: DateTime(2024, 2, 14),
      ),
      LedgerEntry(
        id: 'L011',
        type: 'purchase',
        amount: 780.00,
        note: 'Invoice #110',
        date: DateTime(2024, 3, 18),
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  CUSTOMERS SCREEN (OPTIMIZED)
// ─────────────────────────────────────────────────────────────────────────────

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

  // Color shortcuts
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
    try {
      final data = await _supabase
          .from('customers')
          .select('id, name, email, phone, loyalty_points');
      final customers = <Customer>[];
      for (var cust in data) {
        customers.add(
          Customer(
            id: cust['id'].toString(),
            name: cust['name'],
            email: cust['email'] ?? '',
            phone: cust['phone'] ?? '',
            createdAt: DateTime.parse(
              cust['created_at'] ?? DateTime.now().toIso8601String(),
            ),
            loyaltyPoints: (cust['loyalty_points'] as num?)?.toInt() ?? 0,
            totalSpent: (cust['total_spent'] as num?)?.toDouble() ?? 0.0,
            lastVisit: cust['last_visit'] != null
                ? DateTime.parse(cust['last_visit'])
                : null,
            joinDate: DateTime.parse(
              cust['created_at'] ?? DateTime.now().toIso8601String(),
            ),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _customers = customers;
          _recalculateFiltered();
        });
      }
    } catch (e) {
      print('Error loading customers: $e');
      // Fallback to mock data
      if (mounted) {
        setState(() {
          _customers = List.from(_mockCustomers);
          _recalculateFiltered();
        });
      }
    }
  }

  void _onSearchChanged() {
    _updateSearch(_searchCtrl.text);
  }

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

  void _updateCustomersList() {
    setState(() {
      _recalculateFiltered();
    });
  }

  void _addCustomer(Customer c) async {
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

      final customer = Customer(
        id: newCust['id'].toString(),
        name: newCust['name'],
        email: newCust['email'] ?? '',
        phone: newCust['phone'] ?? '',
        createdAt: DateTime.parse(
          newCust['created_at'] ?? DateTime.now().toIso8601String(),
        ),
        loyaltyPoints: (newCust['loyalty_points'] as num?)?.toInt() ?? 0,
        totalSpent: (newCust['total_spent'] as num?)?.toDouble() ?? 0.0,
        lastVisit: newCust['last_visit'] != null
            ? DateTime.parse(newCust['last_visit'])
            : null,
        joinDate: DateTime.parse(
          newCust['created_at'] ?? DateTime.now().toIso8601String(),
        ),
      );

      setState(() {
        _customers.add(customer);
        _recalculateFiltered();
      });
      _showToast('Customer added', CustomerColors.green);
    } catch (e) {
      print('Error adding customer: $e');
      _showToast('Failed to add customer', CustomerColors.red);
    }
  }

  void _deleteCustomer(String id) async {
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

  void _editCustomer(Customer u) async {
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
      _updateCustomersList();
    });
  }

  // ✅ Computed properties
  int get _totalCustomers => _customers.length;
  double get _totalReceivables => _customers.fold(0.0, (s, c) => s + c.balance);
  double get _totalPurchases =>
      _customers.fold(0.0, (s, c) => s + c.totalPurchases);
  int get _activeBalances => _customers.where((c) => c.balance > 0).length;

  void _showToast(String msg, Color color) {
    HapticFeedback.lightImpact();
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
            Text(
              msg,
              style: CustomerFonts.sans(
                13.sp,
                w: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────

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
            _showToast('Customer added', CustomerColors.green);
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
          _showToast('Customer updated', CustomerColors.blue);
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
                                onSelect: (c) => setState(() => _selected = c),
                                onEdit: _showEditDialog,
                                onDelete: _confirmDelete,
                                onLedger: _showLedgerDialog,
                              ),
                            ),
                            SizedBox(width: 20.w),
                            Expanded(
                              child: _DetailPanel(
                                customer: _selected!,
                                onEdit: () => _showEditDialog(_selected!),
                                onDelete: () => _confirmDelete(_selected!),
                                onLedger: () => _showLedgerDialog(_selected!),
                                onClose: () => setState(() => _selected = null),
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
  final VoidCallback onAdd;

  const _TopBar({required this.searchCtrl, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: CustomerColors.surface,
        border: Border(bottom: BorderSide(color: CustomerColors.border)),
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
              color: CustomerColors.blue,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.people_alt_rounded,
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
                'CUSTOMERS',
                style: CustomerFonts.sans(
                  8.sp,
                  w: FontWeight.w700,
                  color: CustomerColors.blue,
                ),
              ),
              Text(
                'Client Management',
                style: CustomerFonts.display(16.sp, w: FontWeight.w700),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 240.w,
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
                      hintText: 'Search customers...',
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
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              height: 40.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: CustomerColors.blue,
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
                  SizedBox(width: 6.w),
                  Text(
                    'Add Customer',
                    style: CustomerFonts.sans(
                      12.sp,
                      w: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10.w),
          CircleAvatar(
            radius: 18.r,
            backgroundColor: CustomerColors.blueLight,
            child: Text(
              'S',
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
                  w: FontWeight.w700,
                  color: CustomerColors.blue,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text('Client Directory', style: CustomerFonts.display(36.sp)),
        SizedBox(height: 6.h),
        Text(
          'Manage your customers, track balances, and view transaction history.',
          style: CustomerFonts.sans(12.sp, color: CustomerColors.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SUMMARY CARDS
// ─────────────────────────────────────────────────────────────────────────────

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
        'Total Receivables',
        '\$${totalReceivables.toStringAsFixed(2)}',
        Icons.account_balance_wallet_outlined,
        CustomerColors.orange,
        CustomerColors.orangeLight,
        'Outstanding',
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
        'Active Balances',
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
              style: CustomerFonts.display(22.sp, w: FontWeight.w800),
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

// ─────────────────────────────────────────────────────────────────────────────
//  CUSTOMER TABLE
// ─────────────────────────────────────────────────────────────────────────────

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
    'Payments',
    'Balance',
    'Transactions',
    '',
  ];
  static const _widths = [
    70.0,
    200.0,
    200.0,
    110.0,
    110.0,
    110.0,
    100.0,
    120.0,
  ];
  double get _tableWidth => _widths.fold(0.0, (a, b) => a + b) + 32;

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
      child: Column(
        children: [
          // Header
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: _tableWidth,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: CustomerColors.surface2,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
                border: Border(
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
                        w: FontWeight.w600,
                        color: CustomerColors.textDim,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Rows
          if (customers.isEmpty)
            Padding(
              padding: EdgeInsets.all(48.w),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 48.sp,
                      color: CustomerColors.textDim,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No customers found',
                      style: CustomerFonts.sans(
                        14.sp,
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
                totalWidth: _tableWidth,
                onTap: () => onSelect(c),
                onEdit: () => onEdit(c),
                onDelete: () => onDelete(c),
                onLedger: () => onLedger(c),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TABLE ROW
// ─────────────────────────────────────────────────────────────────────────────

class _TableRow extends StatefulWidget {
  final Customer customer;
  final bool isSelected;
  final List<double> colWidths;
  final double totalWidth;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLedger;

  const _TableRow({
    required this.customer,
    required this.isSelected,
    required this.colWidths,
    required this.totalWidth,
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
    final bal = c.balance;
    final balColor = bal == 0
        ? CustomerColors.green
        : (bal < 0 ? CustomerColors.red : CustomerColors.orange);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: widget.totalWidth,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? CustomerColors.blue.withOpacity(0.04)
                  : (_hovered
                        ? CustomerColors.surface2
                        : CustomerColors.surface),
              border: Border(
                bottom: BorderSide(color: CustomerColors.border),
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
                            c.name[0].toUpperCase(),
                            style: CustomerFonts.sans(
                              12.sp,
                              w: FontWeight.w700,
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
                                w: FontWeight.w600,
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
                  ),
                ),
                SizedBox(
                  width: widget.colWidths[3],
                  child: Text(
                    '\$${c.totalPurchases.toStringAsFixed(2)}',
                    style: CustomerFonts.mono(
                      11.sp,
                      w: FontWeight.w600,
                      color: CustomerColors.blue,
                    ),
                  ),
                ),
                SizedBox(
                  width: widget.colWidths[4],
                  child: Text(
                    '\$${c.totalPayments.toStringAsFixed(2)}',
                    style: CustomerFonts.mono(
                      11.sp,
                      w: FontWeight.w600,
                      color: CustomerColors.green,
                    ),
                  ),
                ),
                SizedBox(
                  width: widget.colWidths[5],
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: balColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      bal == 0 ? 'Settled' : '\$${bal.toStringAsFixed(2)}',
                      style: CustomerFonts.mono(
                        10.sp,
                        w: FontWeight.w600,
                        color: balColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: widget.colWidths[6],
                  child: Text(
                    '${c.transactionCount} entries',
                    style: CustomerFonts.sans(
                      11.sp,
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
        width: 32.w,
        height: 32.w,
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

// ─────────────────────────────────────────────────────────────────────────────
//  DETAIL PANEL (Desktop)
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLedger;
  final VoidCallback onClose;

  const _DetailPanel({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onLedger,
    required this.onClose,
  });

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
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
                  style: CustomerFonts.sans(13.sp, w: FontWeight.w700),
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
          Divider(height: 1, color: CustomerColors.border),
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
                      customer.name[0].toUpperCase(),
                      style: CustomerFonts.display(
                        24.sp,
                        color: customer.color,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(customer.name, style: CustomerFonts.display(18.sp)),
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
                SizedBox(height: 20.h),
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
                                w: FontWeight.w700,
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
                                w: FontWeight.w700,
                                color: CustomerColors.green,
                              ),
                            ),
                            Text(
                              'Payments',
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
                              '\$${customer.balance.toStringAsFixed(2)}',
                              style: CustomerFonts.mono(
                                14.sp,
                                w: FontWeight.w700,
                                color: customer.balance == 0
                                    ? CustomerColors.green
                                    : (customer.balance < 0
                                          ? CustomerColors.red
                                          : CustomerColors.orange),
                              ),
                            ),
                            Text(
                              'Balance',
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
                SizedBox(height: 20.h),
                if (customer.ledger.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Recent Transactions',
                        style: CustomerFonts.sans(12.sp, w: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        'See all',
                        style: CustomerFonts.sans(
                          11.sp,
                          color: CustomerColors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ...customer.ledger.reversed
                      .take(3)
                      .map((e) => _TransactionRow(entry: e)),
                ],
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onLedger,
                        icon: Icon(Icons.add_rounded, size: 16.sp),
                        label: Text('Add Transaction'),
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
                      icon: Icon(
                        Icons.edit_outlined,
                        color: CustomerColors.textSecondary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: CustomerColors.surface2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
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
        Text(label, style: CustomerFonts.sans(12.sp)),
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
                ? '-\$${entry.amount.toStringAsFixed(2)}'
                : '+\$${entry.amount.toStringAsFixed(2)}',
            style: CustomerFonts.mono(
              11.sp,
              w: FontWeight.w600,
              color: isPurchase ? CustomerColors.red : CustomerColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DETAIL SHEET (Mobile)
// ─────────────────────────────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLedger;

  const _DetailSheet({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onLedger,
  });

  @override
  Widget build(BuildContext context) {
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
                customer.name[0].toUpperCase(),
                style: CustomerFonts.display(24.sp, color: customer.color),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(customer.name, style: CustomerFonts.display(18.sp)),
          Text(
            customer.id,
            style: CustomerFonts.mono(
              11.sp,
              color: CustomerColors.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
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
                          w: FontWeight.w700,
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
                        '\$${customer.balance.toStringAsFixed(2)}',
                        style: CustomerFonts.mono(
                          14.sp,
                          w: FontWeight.w700,
                          color: CustomerColors.orange,
                        ),
                      ),
                      Text(
                        'Balance',
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
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onLedger,
                  icon: Icon(Icons.add_rounded, size: 16.sp),
                  label: Text('Transaction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomerColors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: CustomerColors.surface2,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: CustomerColors.red),
                style: IconButton.styleFrom(
                  backgroundColor: CustomerColors.red.withOpacity(0.08),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FORM DIALOG
// ─────────────────────────────────────────────────────────────────────────────

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
      content: SizedBox(
        width: 320.w,
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
              w: FontWeight.w600,
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
            w: FontWeight.w600,
            color: CustomerColors.textDim,
          ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  LEDGER DIALOG
// ─────────────────────────────────────────────────────────────────────────────

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
      content: SizedBox(
        width: 300.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTypeChanged('payment'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: selectedType == 'payment'
                            ? CustomerColors.green.withOpacity(0.12)
                            : CustomerColors.surface2,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: selectedType == 'payment'
                              ? CustomerColors.green
                              : CustomerColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 14.sp,
                            color: selectedType == 'payment'
                                ? CustomerColors.green
                                : CustomerColors.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Payment',
                            style: CustomerFonts.sans(
                              11.sp,
                              w: FontWeight.w600,
                              color: selectedType == 'payment'
                                  ? CustomerColors.green
                                  : CustomerColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTypeChanged('purchase'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: selectedType == 'purchase'
                            ? CustomerColors.blue.withOpacity(0.12)
                            : CustomerColors.surface2,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: selectedType == 'purchase'
                              ? CustomerColors.blue
                              : CustomerColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 14.sp,
                            color: selectedType == 'purchase'
                                ? CustomerColors.blue
                                : CustomerColors.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Purchase',
                            style: CustomerFonts.sans(
                              11.sp,
                              w: FontWeight.w600,
                              color: selectedType == 'purchase'
                                  ? CustomerColors.blue
                                  : CustomerColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
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
              w: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
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
