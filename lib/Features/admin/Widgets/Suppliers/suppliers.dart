// lib/Features/Suppliers/suppliers_screen.dart
// Zaytouna POS - Suppliers Screen (Connected to Supabase)

// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LIGHT THEME PALETTE
// ─────────────────────────────────────────────────────────────────────────────

class SupplierColors {
  SupplierColors._();

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
  static const pinkDim = Color(0x1FEC4899);

  static const indigo = Color(0xFF6366F1);
  static const indigoLight = Color(0xFFE0E7FF);
}

// ─────────────────────────────────────────────────────────────────────────────
//  FONTS
// ─────────────────────────────────────────────────────────────────────────────

class SupplierFonts {
  SupplierFonts._();

  static TextStyle display(
    double size, {
    FontWeight w = FontWeight.w700,
    Color? color,
  }) => GoogleFonts.dmSerifDisplay(
    fontSize: size,
    fontWeight: w,
    color: color ?? SupplierColors.text,
  );

  static TextStyle sans(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color ?? SupplierColors.text,
  );

  static TextStyle mono(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: w,
    color: color ?? SupplierColors.text,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  MODELS (Mapped to Supabase Schema)
// ─────────────────────────────────────────────────────────────────────────────

class SupplierTransaction {
  final String id;
  final String type;
  final double amount;
  final String note;
  final DateTime date;

  SupplierTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
  });
}

class Supplier {
  final int id;
  String name;
  String contactPerson;
  String phone;
  String email;
  String address;
  bool isActive;
  DateTime createdAt;

  // UI Only / Transient properties
  final Color color;
  List<SupplierTransaction> ledger;

  Supplier({
    required this.id,
    required this.name,
    this.contactPerson = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.isActive = true,
    DateTime? createdAt,
    List<SupplierTransaction>? ledger,
    Color? color,
  }) : ledger = ledger ?? [],
       color = color ?? _getRandomColor(id),
       createdAt = createdAt ?? DateTime.now();

  factory Supplier.fromSupabase(Map<String, dynamic> data) {
    return Supplier(
      id: data['id'] as int,
      name: data['name'] ?? 'Unknown Supplier',
      contactPerson: data['contact_person'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      isActive: data['is_active'] ?? true,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  static Color _getRandomColor(int id) {
    final colors = [
      SupplierColors.blue,
      SupplierColors.green,
      SupplierColors.orange,
      SupplierColors.purple,
      SupplierColors.cyan,
      SupplierColors.pink,
      SupplierColors.red,
      SupplierColors.indigo,
    ];
    return colors[id.abs() % colors.length];
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
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  late final SupabaseClient _supabase;
  final _searchCtrl = TextEditingController();

  List<Supplier> _suppliers = [];
  List<Supplier> _cachedFiltered = [];
  String _searchQuery = '';
  Supplier? _selected;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _loadSuppliers();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('suppliers')
          .select('*')
          .eq('is_active', true) // Only fetch active suppliers
          .order('name');

      if (mounted) {
        setState(() {
          _suppliers = data.map((json) => Supplier.fromSupabase(json)).toList();
          _recalculateFiltered();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading suppliers: $e');
      if (mounted) {
        _showToast('Failed to load suppliers', SupplierColors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    if (_searchCtrl.text != _searchQuery) {
      setState(() {
        _searchQuery = _searchCtrl.text;
        _recalculateFiltered();
      });
    }
  }

  void _recalculateFiltered() {
    var list = List<Supplier>.from(_suppliers);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (s) =>
                s.name.toLowerCase().contains(q) ||
                s.contactPerson.toLowerCase().contains(q) ||
                s.phone.contains(q) ||
                s.email.toLowerCase().contains(q),
          )
          .toList();
    }

    list.sort((a, b) => a.name.compareTo(b.name));
    _cachedFiltered = list;
  }

  Future<void> _addSupplier(Supplier s) async {
    try {
      final newSup = await _supabase
          .from('suppliers')
          .insert({
            'name': s.name,
            'contact_person': s.contactPerson,
            'email': s.email,
            'phone': s.phone,
            'address': s.address,
            'is_active': true,
          })
          .select()
          .single();

      if (mounted) {
        setState(() {
          _suppliers.add(Supplier.fromSupabase(newSup));
          _recalculateFiltered();
        });
        _showToast('Supplier added successfully', SupplierColors.green);
      }
    } catch (e) {
      print('Error adding supplier: $e');
      if (mounted) _showToast('Failed to add supplier', SupplierColors.red);
    }
  }

  Future<void> _editSupplier(Supplier s) async {
    try {
      await _supabase
          .from('suppliers')
          .update({
            'name': s.name,
            'contact_person': s.contactPerson,
            'email': s.email,
            'phone': s.phone,
            'address': s.address,
          })
          .eq('id', s.id);

      if (mounted) {
        setState(() {
          final i = _suppliers.indexWhere((sup) => sup.id == s.id);
          if (i != -1) _suppliers[i] = s;
          if (_selected?.id == s.id) _selected = s;
          _recalculateFiltered();
        });
        _showToast('Supplier updated', SupplierColors.blue);
      }
    } catch (e) {
      print('Error editing supplier: $e');
      if (mounted) _showToast('Failed to update supplier', SupplierColors.red);
    }
  }

  Future<void> _deleteSupplier(int id) async {
    try {
      // Soft delete: set is_active to false
      await _supabase
          .from('suppliers')
          .update({'is_active': false})
          .eq('id', id);

      if (mounted) {
        setState(() {
          _suppliers.removeWhere((s) => s.id == id);
          if (_selected?.id == id) _selected = null;
          _recalculateFiltered();
        });
        _showToast('Supplier removed', SupplierColors.green);
      }
    } catch (e) {
      print('Error deleting supplier: $e');
      if (mounted) _showToast('Failed to remove supplier', SupplierColors.red);
    }
  }

  void _addTransaction(Supplier s, SupplierTransaction t) {
    setState(() {
      s.ledger.add(t);
      if (_selected?.id == s.id) _selected = s;
      _recalculateFiltered();
    });
    _showToast(
      t.type == 'payment' ? 'Payment recorded' : 'Purchase recorded',
      SupplierColors.green,
    );
  }

  // Computed properties
  int get _totalSuppliers => _suppliers.length;
  double get _totalPayables =>
      _suppliers.fold(0.0, (sum, s) => sum + s.balance);
  double get _totalPurchases =>
      _suppliers.fold(0.0, (sum, s) => sum + s.totalPurchases);
  int get _activeSuppliers =>
      _suppliers.where((s) => s.transactionCount > 0).length;

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
              style: SupplierFonts.sans(
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

  // ── DIALOGS ──────────────────────────────────────────────────────────────────

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => _SupplierFormDialog(
        title: 'Add New Supplier',
        nameCtrl: nameCtrl,
        contactCtrl: contactCtrl,
        phoneCtrl: phoneCtrl,
        emailCtrl: emailCtrl,
        addressCtrl: addressCtrl,
        onSave: () {
          if (nameCtrl.text.trim().isNotEmpty) {
            _addSupplier(
              Supplier(
                id: 0, // DB assigns real ID
                name: nameCtrl.text.trim(),
                contactPerson: contactCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                address: addressCtrl.text.trim(),
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditDialog(Supplier s) {
    final nameCtrl = TextEditingController(text: s.name);
    final contactCtrl = TextEditingController(text: s.contactPerson);
    final phoneCtrl = TextEditingController(text: s.phone);
    final emailCtrl = TextEditingController(text: s.email);
    final addressCtrl = TextEditingController(text: s.address);

    showDialog(
      context: context,
      builder: (_) => _SupplierFormDialog(
        title: 'Edit Supplier',
        nameCtrl: nameCtrl,
        contactCtrl: contactCtrl,
        phoneCtrl: phoneCtrl,
        emailCtrl: emailCtrl,
        addressCtrl: addressCtrl,
        onSave: () {
          _editSupplier(
            Supplier(
              id: s.id,
              name: nameCtrl.text.trim(),
              contactPerson: contactCtrl.text.trim(),
              phone: phoneCtrl.text.trim(),
              email: emailCtrl.text.trim(),
              address: addressCtrl.text.trim(),
              ledger: s.ledger,
              color: s.color,
              createdAt: s.createdAt,
            ),
          );
        },
      ),
    );
  }

  void _showTransactionDialog(Supplier s) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selectedType = 'purchase';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => _TransactionDialog(
          supplier: s,
          amountCtrl: amountCtrl,
          noteCtrl: noteCtrl,
          selectedType: selectedType,
          onTypeChanged: (t) => set(() => selectedType = t),
          onSave: (type) {
            final amt = double.tryParse(amountCtrl.text) ?? 0;
            if (amt <= 0) return;
            _addTransaction(
              s,
              SupplierTransaction(
                id: 'T${DateTime.now().millisecondsSinceEpoch}',
                type: type,
                amount: amt,
                note: noteCtrl.text.trim().isEmpty
                    ? (type == 'purchase' ? 'New purchase' : 'Payment received')
                    : noteCtrl.text.trim(),
                date: DateTime.now(),
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(Supplier s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SupplierColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Remove Supplier',
          style: SupplierFonts.display(16.sp, w: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remove "${s.name}" from your active list?',
              style: SupplierFonts.sans(13.sp, color: SupplierColors.text),
            ),
            SizedBox(height: 8.h),
            Text(
              'This will archive their records safely.',
              style: SupplierFonts.sans(11.sp, color: SupplierColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: SupplierFonts.sans(12.sp, color: SupplierColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SupplierColors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteSupplier(s.id);
            },
            child: Text(
              'Remove',
              style: SupplierFonts.sans(
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

  void _showDetailSheet(Supplier s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailSheet(
        supplier: s,
        onEdit: () {
          Navigator.pop(context);
          _showEditDialog(s);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(s);
        },
        onTransaction: () {
          Navigator.pop(context);
          _showTransactionDialog(s);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: SupplierColors.bg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: SupplierColors.indigo),
            )
          : LayoutBuilder(
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
                              totalSuppliers: _totalSuppliers,
                              totalPayables: _totalPayables,
                              totalPurchases: _totalPurchases,
                              activeSuppliers: _activeSuppliers,
                              constraints: constraints,
                            ),
                            SizedBox(height: 24.h),
                            if (isWide && _selected != null)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _SupplierList(
                                      suppliers: _cachedFiltered,
                                      selected: _selected,
                                      onSelect: (s) =>
                                          setState(() => _selected = s),
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: _DetailPanel(
                                      supplier: _selected!,
                                      onEdit: () => _showEditDialog(_selected!),
                                      onDelete: () =>
                                          _confirmDelete(_selected!),
                                      onTransaction: () =>
                                          _showTransactionDialog(_selected!),
                                      onClose: () =>
                                          setState(() => _selected = null),
                                    ),
                                  ),
                                ],
                              )
                            else
                              _SupplierList(
                                suppliers: _cachedFiltered,
                                selected: _selected,
                                onSelect: (s) {
                                  setState(() => _selected = s);
                                  if (!isWide) _showDetailSheet(s);
                                },
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
        color: SupplierColors.surface,
        border: Border(bottom: BorderSide(color: SupplierColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: SupplierColors.indigo,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.local_shipping_rounded,
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
                'SUPPLIERS',
                style: SupplierFonts.sans(
                  8.sp,
                  w: FontWeight.w700,
                  color: SupplierColors.indigo,
                ),
              ),
              Text(
                'Vendor Management',
                style: SupplierFonts.display(16.sp, w: FontWeight.w700),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 240.w,
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: SupplierColors.surface2,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: SupplierColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18.sp,
                  color: SupplierColors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    style: SupplierFonts.sans(12.sp),
                    decoration: InputDecoration(
                      hintText: 'Search vendors...',
                      hintStyle: SupplierFonts.sans(
                        11.sp,
                        color: SupplierColors.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    cursorColor: SupplierColors.indigo,
                  ),
                ),
                if (searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () => searchCtrl.clear(),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16.sp,
                      color: SupplierColors.textSecondary,
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
                color: SupplierColors.indigo,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: SupplierColors.indigo.withOpacity(0.3),
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
                    'Add Supplier',
                    style: SupplierFonts.sans(
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
            backgroundColor: SupplierColors.indigoLight,
            child: Text(
              'S',
              style: TextStyle(
                color: SupplierColors.indigo,
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
            color: SupplierColors.indigoLight,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5.w,
                height: 5.w,
                decoration: const BoxDecoration(
                  color: SupplierColors.indigo,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'VENDOR DIRECTORY',
                style: SupplierFonts.sans(
                  8.sp,
                  w: FontWeight.w700,
                  color: SupplierColors.indigo,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text('Supplier Network', style: SupplierFonts.display(36.sp)),
        SizedBox(height: 6.h),
        Text(
          'Manage your business partners and procurement history seamlessly.',
          style: SupplierFonts.sans(12.sp, color: SupplierColors.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SUMMARY CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final int totalSuppliers;
  final double totalPayables;
  final double totalPurchases;
  final int activeSuppliers;
  final BoxConstraints constraints;

  const _SummaryCards({
    required this.totalSuppliers,
    required this.totalPayables,
    required this.totalPurchases,
    required this.activeSuppliers,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SD(
        'Total Suppliers',
        '$totalSuppliers',
        Icons.domain_rounded,
        SupplierColors.indigo,
        SupplierColors.indigoLight,
        'Active network',
      ),
      _SD(
        'Total Payables',
        '\$${totalPayables.toStringAsFixed(2)}',
        Icons.account_balance_wallet_outlined,
        SupplierColors.orange,
        SupplierColors.orangeLight,
        'Outstanding balance',
      ),
      _SD(
        'Total Purchases',
        '\$${totalPurchases.toStringAsFixed(2)}',
        Icons.shopping_cart_outlined,
        SupplierColors.blue,
        SupplierColors.blueLight,
        'Lifetime volume',
      ),
      _SD(
        'Active Accounts',
        '$activeSuppliers',
        Icons.verified_user_outlined,
        SupplierColors.green,
        SupplierColors.greenLight,
        'With transactions',
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
        color: SupplierColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: SupplierColors.border),
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
                  style: SupplierFonts.mono(9.sp, color: data.accent),
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
              style: SupplierFonts.display(22.sp, w: FontWeight.w800),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            data.label,
            style: SupplierFonts.sans(
              11.sp,
              color: SupplierColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SUPPLIER LIST
// ─────────────────────────────────────────────────────────────────────────────

class _SupplierList extends StatelessWidget {
  final List<Supplier> suppliers;
  final Supplier? selected;
  final Function(Supplier) onSelect;

  const _SupplierList({
    required this.suppliers,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SupplierColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: SupplierColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: SupplierColors.surface2,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
              border: Border(bottom: BorderSide(color: SupplierColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Supplier Info',
                    style: SupplierFonts.sans(
                      10.sp,
                      w: FontWeight.w600,
                      color: SupplierColors.textDim,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Phone',
                    style: SupplierFonts.sans(
                      10.sp,
                      w: FontWeight.w600,
                      color: SupplierColors.textDim,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Email',
                    style: SupplierFonts.sans(
                      10.sp,
                      w: FontWeight.w600,
                      color: SupplierColors.textDim,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Purchases',
                    style: SupplierFonts.sans(
                      10.sp,
                      w: FontWeight.w600,
                      color: SupplierColors.textDim,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Balance',
                    style: SupplierFonts.sans(
                      10.sp,
                      w: FontWeight.w600,
                      color: SupplierColors.textDim,
                    ),
                  ),
                ),
                SizedBox(width: 40.w),
              ],
            ),
          ),
          if (suppliers.isEmpty)
            Padding(
              padding: EdgeInsets.all(48.w),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.domain_disabled_rounded,
                      size: 48.sp,
                      color: SupplierColors.textDim,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No suppliers match your search.',
                      style: SupplierFonts.sans(
                        14.sp,
                        color: SupplierColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...suppliers.map(
              (s) => _SupplierRow(
                supplier: s,
                isSelected: selected?.id == s.id,
                onTap: () => onSelect(s),
              ),
            ),
        ],
      ),
    );
  }
}

class _SupplierRow extends StatelessWidget {
  final Supplier supplier;
  final bool isSelected;
  final VoidCallback onTap;

  const _SupplierRow({
    required this.supplier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? SupplierColors.indigo.withOpacity(0.04)
              : SupplierColors.surface,
          border: Border(
            bottom: BorderSide(color: SupplierColors.border),
            left: BorderSide(
              color: isSelected ? SupplierColors.indigo : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: supplier.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        supplier.name.isNotEmpty
                            ? supplier.name[0].toUpperCase()
                            : '?',
                        style: SupplierFonts.sans(
                          14.sp,
                          w: FontWeight.w700,
                          color: supplier.color,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          style: SupplierFonts.sans(12.sp, w: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          supplier.contactPerson.isEmpty
                              ? 'No contact'
                              : supplier.contactPerson,
                          style: SupplierFonts.sans(
                            10.sp,
                            color: SupplierColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                supplier.phone.isEmpty ? '-' : supplier.phone,
                style: SupplierFonts.mono(
                  10.sp,
                  color: SupplierColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                supplier.email.isEmpty ? '-' : supplier.email,
                style: SupplierFonts.mono(
                  10.sp,
                  color: SupplierColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '\$${supplier.totalPurchases.toStringAsFixed(0)}',
                style: SupplierFonts.mono(
                  11.sp,
                  w: FontWeight.w600,
                  color: SupplierColors.blue,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '\$${supplier.balance.toStringAsFixed(2)}',
                style: SupplierFonts.mono(
                  11.sp,
                  w: FontWeight.w600,
                  color: supplier.balance == 0
                      ? SupplierColors.green
                      : SupplierColors.orange,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(width: 40.w),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DETAIL PANELS
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTransaction;
  final VoidCallback onClose;

  const _DetailPanel({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
    required this.onTransaction,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SupplierColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: SupplierColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Text(
                  'Supplier Profile',
                  style: SupplierFonts.sans(13.sp, w: FontWeight.w700),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18.sp,
                    color: SupplierColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: SupplierColors.border),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: supplier.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Text(
                      supplier.name.isNotEmpty
                          ? supplier.name[0].toUpperCase()
                          : 'S',
                      style: SupplierFonts.display(
                        24.sp,
                        color: supplier.color,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  supplier.name,
                  style: SupplierFonts.display(18.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Text(
                  supplier.contactPerson.isEmpty
                      ? 'No primary contact'
                      : supplier.contactPerson,
                  style: SupplierFonts.sans(
                    13.sp,
                    color: SupplierColors.textSecondary,
                  ),
                ),
                SizedBox(height: 16.h),
                _DetailRow(
                  icon: Icons.phone_rounded,
                  label: supplier.phone.isEmpty ? 'N/A' : supplier.phone,
                ),
                SizedBox(height: 8.h),
                _DetailRow(
                  icon: Icons.email_rounded,
                  label: supplier.email.isEmpty ? 'N/A' : supplier.email,
                ),
                SizedBox(height: 8.h),
                _DetailRow(
                  icon: Icons.location_on_rounded,
                  label: supplier.address.isEmpty ? 'N/A' : supplier.address,
                ),
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: SupplierColors.surface2,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '\$${supplier.totalPurchases.toStringAsFixed(2)}',
                              style: SupplierFonts.mono(
                                14.sp,
                                w: FontWeight.w700,
                                color: SupplierColors.blue,
                              ),
                            ),
                            Text(
                              'Purchases',
                              style: SupplierFonts.sans(
                                10.sp,
                                color: SupplierColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '\$${supplier.totalPayments.toStringAsFixed(2)}',
                              style: SupplierFonts.mono(
                                14.sp,
                                w: FontWeight.w700,
                                color: SupplierColors.green,
                              ),
                            ),
                            Text(
                              'Payments',
                              style: SupplierFonts.sans(
                                10.sp,
                                color: SupplierColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '\$${supplier.balance.toStringAsFixed(2)}',
                              style: SupplierFonts.mono(
                                14.sp,
                                w: FontWeight.w700,
                                color: supplier.balance == 0
                                    ? SupplierColors.green
                                    : SupplierColors.orange,
                              ),
                            ),
                            Text(
                              'Balance',
                              style: SupplierFonts.sans(
                                10.sp,
                                color: SupplierColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                if (supplier.ledger.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Recent Ledger',
                        style: SupplierFonts.sans(12.sp, w: FontWeight.w600),
                      ),
                      const Spacer(),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ...supplier.ledger.reversed
                      .take(3)
                      .map((e) => _TransactionRow(transaction: e)),
                ],
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onTransaction,
                        icon: Icon(Icons.add_rounded, size: 16.sp),
                        label: const Text('Payment/Bill'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SupplierColors.indigo,
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
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: SupplierColors.textSecondary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: SupplierColors.surface2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: SupplierColors.red,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: SupplierColors.red.withOpacity(0.08),
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

class _DetailSheet extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTransaction;

  const _DetailSheet({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
    required this.onTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: SupplierColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: SupplierColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: supplier.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Center(
              child: Text(
                supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : 'S',
                style: SupplierFonts.display(24.sp, color: supplier.color),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(supplier.name, style: SupplierFonts.display(18.sp)),
          Text(
            supplier.contactPerson.isEmpty
                ? 'No contact info'
                : supplier.contactPerson,
            style: SupplierFonts.sans(
              13.sp,
              color: SupplierColors.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: SupplierColors.surface2,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '\$${supplier.totalPurchases.toStringAsFixed(0)}',
                        style: SupplierFonts.mono(
                          14.sp,
                          w: FontWeight.w700,
                          color: SupplierColors.blue,
                        ),
                      ),
                      Text(
                        'Purchases',
                        style: SupplierFonts.sans(
                          10.sp,
                          color: SupplierColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '\$${supplier.balance.toStringAsFixed(2)}',
                        style: SupplierFonts.mono(
                          14.sp,
                          w: FontWeight.w700,
                          color: supplier.balance == 0
                              ? SupplierColors.green
                              : SupplierColors.orange,
                        ),
                      ),
                      Text(
                        'Balance',
                        style: SupplierFonts.sans(
                          10.sp,
                          color: SupplierColors.textSecondary,
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
                  onPressed: onTransaction,
                  icon: Icon(Icons.add_rounded, size: 16.sp),
                  label: const Text('Add Transaction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SupplierColors.indigo,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: SupplierColors.surface2,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: SupplierColors.red,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: SupplierColors.red.withOpacity(0.08),
                ),
              ),
            ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.sp, color: SupplierColors.textSecondary),
        SizedBox(width: 10.w),
        Expanded(child: Text(label, style: SupplierFonts.sans(12.sp))),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final SupplierTransaction transaction;
  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPurchase = transaction.type == 'purchase';
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: SupplierColors.border.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: isPurchase ? SupplierColors.blue : SupplierColors.green,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              transaction.note,
              style: SupplierFonts.sans(11.sp),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            isPurchase
                ? '-\$${transaction.amount.toStringAsFixed(2)}'
                : '+\$${transaction.amount.toStringAsFixed(2)}',
            style: SupplierFonts.mono(
              11.sp,
              w: FontWeight.w600,
              color: isPurchase ? SupplierColors.red : SupplierColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FORM DIALOGS
// ─────────────────────────────────────────────────────────────────────────────

class _SupplierFormDialog extends StatelessWidget {
  final String title;
  final TextEditingController nameCtrl; // DB: name
  final TextEditingController contactCtrl; // DB: contact_person
  final TextEditingController phoneCtrl; // DB: phone
  final TextEditingController emailCtrl; // DB: email
  final TextEditingController addressCtrl; // DB: address
  final VoidCallback onSave;

  const _SupplierFormDialog({
    required this.title,
    required this.nameCtrl,
    required this.contactCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.addressCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SupplierColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        title,
        style: SupplierFonts.display(16.sp, w: FontWeight.w800),
      ),
      content: SizedBox(
        width: 400.w,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                label: 'Company / Supplier Name *',
                ctrl: nameCtrl,
                icon: Icons.business_outlined,
              ),
              SizedBox(height: 12.h),
              _DialogField(
                label: 'Contact Person',
                ctrl: contactCtrl,
                icon: Icons.person_outline_rounded,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _DialogField(
                      label: 'Phone',
                      ctrl: phoneCtrl,
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _DialogField(
                      label: 'Email',
                      ctrl: emailCtrl,
                      icon: Icons.email_outlined,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _DialogField(
                label: 'Physical Address',
                ctrl: addressCtrl,
                icon: Icons.location_on_outlined,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: SupplierFonts.sans(
              12.sp,
              color: SupplierColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: SupplierColors.indigo,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          onPressed: onSave,
          child: Text(
            'Save Profile',
            style: SupplierFonts.sans(
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

class _TransactionDialog extends StatelessWidget {
  final Supplier supplier;
  final TextEditingController amountCtrl;
  final TextEditingController noteCtrl;
  final String selectedType;
  final Function(String) onTypeChanged;
  final Function(String) onSave;

  const _TransactionDialog({
    required this.supplier,
    required this.amountCtrl,
    required this.noteCtrl,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SupplierColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'New Record',
            style: SupplierFonts.display(16.sp, w: FontWeight.w800),
          ),
          SizedBox(height: 4.h),
          Text(
            'For ${supplier.name}',
            style: SupplierFonts.sans(
              11.sp,
              color: SupplierColors.textSecondary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTypeChanged('purchase'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: selectedType == 'purchase'
                            ? SupplierColors.blue.withOpacity(0.12)
                            : SupplierColors.surface2,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: selectedType == 'purchase'
                              ? SupplierColors.blue
                              : SupplierColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_rounded,
                            size: 14.sp,
                            color: selectedType == 'purchase'
                                ? SupplierColors.blue
                                : SupplierColors.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Invoice/Bill',
                            style: SupplierFonts.sans(
                              11.sp,
                              w: FontWeight.w600,
                              color: selectedType == 'purchase'
                                  ? SupplierColors.blue
                                  : SupplierColors.textSecondary,
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
                    onTap: () => onTypeChanged('payment'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: selectedType == 'payment'
                            ? SupplierColors.green.withOpacity(0.12)
                            : SupplierColors.surface2,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: selectedType == 'payment'
                              ? SupplierColors.green
                              : SupplierColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payments_rounded,
                            size: 14.sp,
                            color: selectedType == 'payment'
                                ? SupplierColors.green
                                : SupplierColors.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Payment',
                            style: SupplierFonts.sans(
                              11.sp,
                              w: FontWeight.w600,
                              color: selectedType == 'payment'
                                  ? SupplierColors.green
                                  : SupplierColors.textSecondary,
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
              label: 'Total Amount (\$)',
              ctrl: amountCtrl,
              icon: Icons.attach_money_rounded,
              isNumber: true,
            ),
            SizedBox(height: 12.h),
            _DialogField(
              label: 'Memo / Reference (Optional)',
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
            style: SupplierFonts.sans(
              12.sp,
              color: SupplierColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedType == 'purchase'
                ? SupplierColors.blue
                : SupplierColors.green,
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
            'Confirm ${selectedType == 'purchase' ? 'Bill' : 'Payment'}',
            style: SupplierFonts.sans(
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
  final bool isNumber;

  const _DialogField({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: SupplierFonts.sans(
            9.sp,
            w: FontWeight.w600,
            color: SupplierColors.textDim,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: SupplierColors.surface2,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: SupplierColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16.sp, color: SupplierColors.textSecondary),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: SupplierFonts.sans(12.sp),
                  keyboardType: isNumber
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  inputFormatters: isNumber
                      ? [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ]
                      : [],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  cursorColor: SupplierColors.indigo,
                ),
              ),
            ],
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
