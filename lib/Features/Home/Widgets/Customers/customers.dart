// lib/Features/Customers/customers_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LEDGER ENTRY MODEL
//  type: 'purchase' | 'payment'
//  purchase = customer owes more (debit on customer)
//  payment  = customer pays off debt (credit on customer)
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
//  CUSTOMER MODEL
//  balance > 0  → customer owes us  (دَيْن pending)
//  balance == 0 → settled
//  balance < 0  → we owe customer   (overpaid)
// ─────────────────────────────────────────────────────────────────────────────

class Customer {
  final String id;
  String name;
  String phone;
  String email;
  DateTime createdAt;
  List<LedgerEntry> ledger;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.createdAt,
    List<LedgerEntry>? ledger,
  }) : ledger = ledger ?? [];

  double get totalPurchases => ledger
      .where((e) => e.type == 'purchase')
      .fold(0.0, (s, e) => s + e.amount);

  /// Positive = customer still owes us
  double get balance {
    final purchases = ledger
        .where((e) => e.type == 'purchase')
        .fold(0.0, (s, e) => s + e.amount);
    final payments = ledger
        .where((e) => e.type == 'payment')
        .fold(0.0, (s, e) => s + e.amount);
    return purchases - payments;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DUMMY DATA
// ─────────────────────────────────────────────────────────────────────────────

final _dummyCustomers = <Customer>[
  Customer(
    id: 'C001',
    name: 'Alice Martin',
    phone: '+1 555 010 1234',
    email: 'alice@example.com',
    createdAt: DateTime(2024, 1, 12),
    ledger: [
      LedgerEntry(
        id: 'L001',
        type: 'purchase',
        amount: 4820.50,
        note: 'Invoice #101',
        date: DateTime(2024, 2, 1),
      ),
      LedgerEntry(
        id: 'L002',
        type: 'payment',
        amount: 4700.50,
        note: 'Daf3a Feb',
        date: DateTime(2024, 2, 10),
      ),
    ],
  ),
  Customer(
    id: 'C002',
    name: 'Bob Johnson',
    phone: '+1 555 020 5678',
    email: 'bob@example.com',
    createdAt: DateTime(2024, 3, 5),
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
    name: 'Clara Reyes',
    phone: '+1 555 030 9012',
    email: 'clara@example.com',
    createdAt: DateTime(2023, 11, 20),
    ledger: [
      LedgerEntry(
        id: 'L005',
        type: 'purchase',
        amount: 9200.75,
        note: 'Invoice #103',
        date: DateTime(2023, 12, 1),
      ),
      LedgerEntry(
        id: 'L006',
        type: 'payment',
        amount: 8750.75,
        note: 'Daf3a Dec',
        date: DateTime(2023, 12, 20),
      ),
    ],
  ),
  Customer(
    id: 'C004',
    name: 'David Kim',
    phone: '+1 555 040 3456',
    email: 'david@example.com',
    createdAt: DateTime(2024, 6, 1),
    ledger: [
      LedgerEntry(
        id: 'L007',
        type: 'purchase',
        amount: 580.25,
        note: 'Invoice #104',
        date: DateTime(2024, 6, 3),
      ),
    ],
  ),
  Customer(
    id: 'C005',
    name: 'Eva Nguyen',
    phone: '+1 555 050 7890',
    email: 'eva@example.com',
    createdAt: DateTime(2024, 2, 28),
    ledger: [
      LedgerEntry(
        id: 'L008',
        type: 'purchase',
        amount: 3100.00,
        note: 'Invoice #105',
        date: DateTime(2024, 3, 1),
      ),
      LedgerEntry(
        id: 'L009',
        type: 'payment',
        amount: 3100.00,
        note: 'Daf3a full',
        date: DateTime(2024, 3, 5),
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  CUSTOMERS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CustomersScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  const CustomersScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  final List<Customer> _customers = List.from(_dummyCustomers);
  List<Customer> _filtered = List.from(_dummyCustomers);
  Customer? _selected;

  bool get _dark => widget.isDark;
  Color get bg => _dark ? const Color(0xFF0A0A0F) : const Color(0xFFF1F4F9);
  Color get surface =>
      _dark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  Color get bdr2 => _dark ? const Color(0x18FFFFFF) : const Color(0x22000000);
  Color get textClr =>
      _dark ? const Color(0xFFF0EFF8) : const Color(0xFF0F0F1A);
  Color get textMut =>
      _dark ? const Color(0x73F0EFF8) : const Color(0x88000000);
  static const Color red = Color(0xFFFF3B3B);

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_customers)
          : _customers
                .where(
                  (c) =>
                      c.name.toLowerCase().contains(q) ||
                      c.phone.contains(q) ||
                      c.email.toLowerCase().contains(q) ||
                      c.id.toLowerCase().contains(q),
                )
                .toList();
    });
  }

  void _addCustomer(Customer c) => setState(() {
    _customers.add(c);
    _onSearch();
  });
  void _deleteCustomer(String id) => setState(() {
    _customers.removeWhere((c) => c.id == id);
    if (_selected?.id == id) _selected = null;
    _onSearch();
  });
  void _editCustomer(Customer u) => setState(() {
    final i = _customers.indexWhere((c) => c.id == u.id);
    if (i != -1) _customers[i] = u;
    if (_selected?.id == u.id) _selected = u;
    _onSearch();
  });
  void _addLedgerEntry(Customer c, LedgerEntry e) => setState(() {
    c.ledger.add(e);
    if (_selected?.id == c.id) _selected = c;
    _onSearch();
  });

  // ── Dialogs ──────────────────────────────────────────────

  void _showAddDialog() {
    final nc = TextEditingController(),
        pc = TextEditingController(),
        ec = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _CustomerFormDialog(
        isDark: _dark,
        isEdit: false,
        nameCtrl: nc,
        phoneCtrl: pc,
        emailCtrl: ec,
        onSave: () => _addCustomer(
          Customer(
            id: 'C${(_customers.length + 1).toString().padLeft(3, '0')}',
            name: nc.text.trim(),
            phone: pc.text.trim(),
            email: ec.text.trim(),
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(Customer c) {
    final nc = TextEditingController(text: c.name),
        pc = TextEditingController(text: c.phone),
        ec = TextEditingController(text: c.email);
    showDialog(
      context: context,
      builder: (_) => _CustomerFormDialog(
        isDark: _dark,
        isEdit: true,
        nameCtrl: nc,
        phoneCtrl: pc,
        emailCtrl: ec,
        onSave: () => _editCustomer(
          Customer(
            id: c.id,
            name: nc.text.trim(),
            phone: pc.text.trim(),
            email: ec.text.trim(),
            createdAt: c.createdAt,
            ledger: c.ledger,
          ),
        ),
      ),
    );
  }

  void _showLedgerDialog(Customer c) {
    final ac = TextEditingController(), note = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _LedgerDialog(
        isDark: _dark,
        customer: c,
        amountCtrl: ac,
        noteCtrl: note,
        initialType: 'payment',
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
                  ? (type == 'payment' ? 'Daf3a' : 'Purchase')
                  : note.text.trim(),
              date: DateTime.now(),
            ),
          );
        },
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
          side: BorderSide(color: bdr2),
        ),
        title: Text(
          'Delete Customer',
          style: GoogleFonts.syne(
            color: textClr,
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Remove "${c.name}" permanently?',
          style: GoogleFonts.dmSans(color: textMut, fontSize: 12.5.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: textMut, fontSize: 12.sp),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteCustomer(c.id);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Container(
      color: bg,
      child: Column(
        children: [
          _Header(
            isDark: _dark,
            searchCtrl: _searchCtrl,
            onAdd: _showAddDialog,
            onToggleTheme: widget.onToggleTheme,
          ),
          Expanded(
            child: isWide && _selected != null
                ? Row(
                    children: [
                      Expanded(
                        child: _CustomerTable(
                          isDark: _dark,
                          customers: _filtered,
                          selected: _selected,
                          onSelect: (c) => setState(() => _selected = c),
                          onEdit: _showEditDialog,
                          onDelete: _confirmDelete,
                          onLedger: _showLedgerDialog,
                        ),
                      ),
                      _DetailPanel(
                        isDark: _dark,
                        customer: _selected!,
                        onEdit: () => _showEditDialog(_selected!),
                        onDelete: () => _confirmDelete(_selected!),
                        onLedger: () => _showLedgerDialog(_selected!),
                        onClose: () => setState(() => _selected = null),
                      ),
                    ],
                  )
                : _CustomerTable(
                    isDark: _dark,
                    customers: _filtered,
                    selected: _selected,
                    onSelect: (c) {
                      setState(() => _selected = c);
                      if (!isWide) _showDetailSheet(c);
                    },
                    onEdit: _showEditDialog,
                    onDelete: _confirmDelete,
                    onLedger: _showLedgerDialog,
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
        isDark: _dark,
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
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER  — overflow-safe with Expanded search
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isDark;
  final TextEditingController searchCtrl;
  final VoidCallback onAdd, onToggleTheme;
  const _Header({
    required this.isDark,
    required this.searchCtrl,
    required this.onAdd,
    required this.onToggleTheme,
  });

  Color get surface =>
      isDark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  Color get surf2 => isDark ? const Color(0xFF16161F) : const Color(0xFFEEF0F6);
  Color get bdr => isDark ? const Color(0x0FFFFFFF) : const Color(0x18000000);
  Color get bdr2 => isDark ? const Color(0x18FFFFFF) : const Color(0x22000000);
  Color get textClr =>
      isDark ? const Color(0xFFF0EFF8) : const Color(0xFF0F0F1A);
  Color get textMut =>
      isDark ? const Color(0x73F0EFF8) : const Color(0x88000000);
  static const Color red = Color(0xFFFF3B3B);
  static const Color gold = Color(0xFFF5C842);
  static const Color goldDim = Color(0x1AF5C842);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: bdr)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CUSTOMER MANAGEMENT',
                style: GoogleFonts.dmMono(
                  fontSize: 7.sp,
                  color: red,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Customers',
                style: GoogleFonts.syne(
                  color: textClr,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
              ),
            ],
          ),
          SizedBox(width: 14.w),
          // Search — Expanded so it never overflows
          Expanded(
            child: Container(
              height: 34.h,
              decoration: BoxDecoration(
                color: surf2,
                border: Border.all(color: bdr2),
                borderRadius: BorderRadius.circular(9.r),
              ),
              child: TextField(
                controller: searchCtrl,
                style: GoogleFonts.dmSans(color: textClr, fontSize: 12.sp),
                decoration: InputDecoration(
                  hintText: 'Search…',
                  hintStyle: GoogleFonts.dmSans(
                    color: textMut,
                    fontSize: 12.sp,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 15.sp,
                    color: textMut,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Theme toggle
          GestureDetector(
            onTap: onToggleTheme,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: isDark ? goldDim : surf2,
                border: Border.all(color: bdr2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 14.sp,
                color: isDark ? gold : textMut,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Add — intrinsic width, no overflow possible
          GestureDetector(
            onTap: onAdd,
            child: Container(
              height: 32.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: red,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(color: red.withOpacity(0.28), blurRadius: 8),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'Add',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TABLE  — wrapped in horizontal SingleChildScrollView to prevent overflow
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerTable extends StatelessWidget {
  final bool isDark;
  final List<Customer> customers;
  final Customer? selected;
  final ValueChanged<Customer> onSelect, onEdit, onDelete, onLedger;

  const _CustomerTable({
    required this.isDark,
    required this.customers,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onLedger,
  });

  Color get bg => isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF1F4F9);
  Color get surf2 => isDark ? const Color(0xFF16161F) : const Color(0xFFEEF0F6);
  Color get textMut =>
      isDark ? const Color(0x73F0EFF8) : const Color(0x88000000);

  static const List<String> _heads = [
    'ID',
    'Name',
    'Phone',
    'Email',
    'Purchases',
    'Balance',
    'Since',
    '',
  ];
  static const List<double> _widths = [58, 168, 148, 188, 108, 108, 94, 114];
  double get _tableW => _widths.fold(0.0, (a, b) => a + b) + 28;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: Column(
        children: [
          // Header
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: _tableW,
              height: 36.h,
              margin: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: surf2,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.r),
                  topRight: Radius.circular(10.r),
                ),
              ),
              child: Row(
                children: List.generate(
                  _heads.length,
                  (i) => SizedBox(
                    width: _widths[i],
                    child: Text(
                      _heads[i],
                      style: GoogleFonts.dmMono(
                        fontSize: 9.sp,
                        color: textMut,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Rows
          Expanded(
            child: customers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_alt_outlined,
                          size: 34.sp,
                          color: textMut,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'No customers found',
                          style: GoogleFonts.dmSans(
                            color: textMut,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 16.h),
                    itemCount: customers.length,
                    itemBuilder: (_, i) => _TableRow(
                      isDark: isDark,
                      customer: customers[i],
                      isSelected: selected?.id == customers[i].id,
                      colWidths: _widths,
                      totalWidth: _tableW,
                      onTap: () => onSelect(customers[i]),
                      onEdit: () => onEdit(customers[i]),
                      onDelete: () => onDelete(customers[i]),
                      onLedger: () => onLedger(customers[i]),
                    ),
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
  final bool isDark;
  final Customer customer;
  final bool isSelected;
  final List<double> colWidths;
  final double totalWidth;
  final VoidCallback onTap, onEdit, onDelete, onLedger;

  const _TableRow({
    required this.isDark,
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

  Color get surface =>
      widget.isDark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  Color get bdr =>
      widget.isDark ? const Color(0x0FFFFFFF) : const Color(0x18000000);
  Color get textClr =>
      widget.isDark ? const Color(0xFFF0EFF8) : const Color(0xFF0F0F1A);
  Color get textMut =>
      widget.isDark ? const Color(0x73F0EFF8) : const Color(0x88000000);

  static const Color red = Color(0xFFFF3B3B);
  static const Color redDim = Color(0x1FFF3B3B);
  static const Color redSel = Color(0x0DFF3B3B);
  static const Color green = Color(0xFF34C759);
  static const Color greenDim = Color(0x1A34C759);
  static const Color amber = Color(0xFFF5C842);
  static const Color amberDim = Color(0x1AF5C842);

  String _initials(String n) {
    final p = n.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : n.isNotEmpty
        ? n[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final bal = c.balance;
    final isZero = bal == 0;
    final isNeg = bal < 0;
    final balColor = isZero
        ? amber
        : isNeg
        ? green
        : red;
    final balBg = isZero
        ? amberDim
        : isNeg
        ? greenDim
        : redDim;
    final balLabel = isZero
        ? 'Settled'
        : isNeg
        ? '-\$${bal.abs().toStringAsFixed(2)}'
        : '\$${bal.toStringAsFixed(2)}';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.totalWidth,
            height: 52.h,
            margin: EdgeInsets.only(top: 1.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? redSel
                  : _hovered
                  ? surface.withOpacity(0.7)
                  : surface,
              border: Border(
                bottom: BorderSide(color: bdr),
                left: widget.isSelected
                    ? const BorderSide(color: red, width: 2)
                    : const BorderSide(color: Colors.transparent),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: widget.colWidths[0],
                  child: Text(
                    c.id,
                    style: GoogleFonts.dmMono(fontSize: 10.sp, color: textMut),
                  ),
                ),
                SizedBox(
                  width: widget.colWidths[1],
                  child: Row(
                    children: [
                      Container(
                        width: 26.w,
                        height: 26.w,
                        decoration: BoxDecoration(
                          color: redDim,
                          borderRadius: BorderRadius.circular(7.r),
                        ),
                        child: Center(
                          child: Text(
                            _initials(c.name),
                            style: GoogleFonts.syne(
                              fontSize: 9.sp,
                              color: red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          c.name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 12.sp,
                            color: textClr,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: widget.colWidths[2],
                  child: Text(
                    c.phone,
                    style: GoogleFonts.dmMono(fontSize: 10.sp, color: textMut),
                  ),
                ),
                SizedBox(
                  width: widget.colWidths[3],
                  child: Text(
                    c.email,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(fontSize: 11.sp, color: textMut),
                  ),
                ),
                SizedBox(
                  width: widget.colWidths[4],
                  child: Text(
                    '\$${c.totalPurchases.toStringAsFixed(2)}',
                    style: GoogleFonts.dmMono(
                      fontSize: 11.sp,
                      color: textClr,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: widget.colWidths[5],
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 7.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: balBg,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    child: Text(
                      balLabel,
                      style: GoogleFonts.dmMono(
                        fontSize: 10.sp,
                        color: balColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: widget.colWidths[6],
                  child: Text(
                    '${c.createdAt.year}-${c.createdAt.month.toString().padLeft(2, '0')}-${c.createdAt.day.toString().padLeft(2, '0')}',
                    style: GoogleFonts.dmMono(fontSize: 10.sp, color: textMut),
                  ),
                ),
                SizedBox(
                  width: widget.colWidths[7],
                  child: Row(
                    children: [
                      _iconBtn(
                        Icons.payments_outlined,
                        green,
                        widget.onLedger,
                        tip: 'Payment/Purchase',
                      ),
                      SizedBox(width: 3.w),
                      _iconBtn(
                        Icons.edit_outlined,
                        textMut,
                        widget.onEdit,
                        tip: 'Edit',
                      ),
                      SizedBox(width: 3.w),
                      _iconBtn(
                        Icons.delete_outline_rounded,
                        red,
                        widget.onDelete,
                        tip: 'Delete',
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

  Widget _iconBtn(IconData icon, Color color, VoidCallback cb, {String? tip}) {
    final btn = GestureDetector(
      onTap: cb,
      child: Container(
        width: 27.w,
        height: 27.w,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Icon(icon, size: 13.sp, color: color),
      ),
    );
    return tip != null ? Tooltip(message: tip, child: btn) : btn;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DETAIL PANEL  (wide screen)
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final bool isDark;
  final Customer customer;
  final VoidCallback onEdit, onDelete, onLedger, onClose;
  const _DetailPanel({
    required this.isDark,
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onLedger,
    required this.onClose,
  });

  Color get surface =>
      isDark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  Color get surf2 => isDark ? const Color(0xFF16161F) : const Color(0xFFEEF0F6);
  Color get bdr => isDark ? const Color(0x0FFFFFFF) : const Color(0x18000000);
  Color get bdr2 => isDark ? const Color(0x18FFFFFF) : const Color(0x22000000);
  Color get textClr =>
      isDark ? const Color(0xFFF0EFF8) : const Color(0xFF0F0F1A);
  Color get textMut =>
      isDark ? const Color(0x73F0EFF8) : const Color(0x88000000);
  static const Color red = Color(0xFFFF3B3B);
  static const Color redDim = Color(0x1FFF3B3B);
  static const Color green = Color(0xFF34C759);
  static const Color greenDim = Color(0x1A34C759);
  static const Color amber = Color(0xFFF5C842);
  static const Color amberDim = Color(0x1AF5C842);

  String _initials(String n) {
    final p = n.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : n.isNotEmpty
        ? n[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final bal = c.balance;
    final isZero = bal == 0;
    final isNeg = bal < 0;
    final balColor = isZero
        ? amber
        : isNeg
        ? green
        : red;
    final balBg = isZero
        ? amberDim
        : isNeg
        ? greenDim
        : redDim;
    final balLabel = isZero
        ? 'Settled'
        : isNeg
        ? '-\$${bal.abs().toStringAsFixed(2)}'
        : '\$${bal.toStringAsFixed(2)}';

    return Container(
      width: 270.w,
      decoration: BoxDecoration(
        color: surface,
        border: Border(left: BorderSide(color: bdr2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 0),
            child: Row(
              children: [
                Text(
                  'Customer Detail',
                  style: GoogleFonts.syne(
                    color: textClr,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: Icon(Icons.close_rounded, size: 16.sp, color: textMut),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: redDim,
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Center(
                child: Text(
                  _initials(c.name),
                  style: GoogleFonts.syne(
                    fontSize: 19.sp,
                    color: red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Center(
            child: Text(
              c.name,
              style: GoogleFonts.syne(
                color: textClr,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Center(
            child: Text(
              c.id,
              style: GoogleFonts.dmMono(color: textMut, fontSize: 10.sp),
            ),
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              children: [
                _stat(
                  'Purchases',
                  '\$${c.totalPurchases.toStringAsFixed(2)}',
                  textMut,
                  textClr,
                ),
                SizedBox(width: 8.w),
                _stat('Balance', balLabel, textMut, balColor, bg: balBg),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Divider(color: bdr, height: 1),
          SizedBox(height: 10.h),
          _info(Icons.phone_outlined, c.phone),
          _info(Icons.email_outlined, c.email),
          _info(
            Icons.calendar_today_outlined,
            'Since ${c.createdAt.year}-${c.createdAt.month.toString().padLeft(2, '0')}-${c.createdAt.day.toString().padLeft(2, '0')}',
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Text(
              'Ledger',
              style: GoogleFonts.syne(
                color: textClr,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Expanded(
            child: c.ledger.isEmpty
                ? Center(
                    child: Text(
                      'No entries',
                      style: GoogleFonts.dmSans(
                        color: textMut,
                        fontSize: 11.sp,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    itemCount: c.ledger.length,
                    itemBuilder: (_, i) {
                      final e = c.ledger[c.ledger.length - 1 - i];
                      final isPay = e.type == 'payment';
                      return Container(
                        margin: EdgeInsets.only(bottom: 5.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 7.h,
                        ),
                        decoration: BoxDecoration(
                          color: surf2,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPay
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              size: 11.sp,
                              color: isPay ? green : red,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                e.note,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  color: textClr,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ),
                            Text(
                              '${isPay ? '+' : '-'}\$${e.amount.toStringAsFixed(2)}',
                              style: GoogleFonts.dmMono(
                                fontSize: 10.sp,
                                color: isPay ? green : red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onLedger,
                  child: Container(
                    height: 34.h,
                    decoration: BoxDecoration(
                      color: greenDim,
                      borderRadius: BorderRadius.circular(9.r),
                      border: Border.all(color: green.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 13.sp,
                          color: green,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          'Record Payment / Purchase',
                          style: GoogleFonts.dmSans(
                            color: green,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          height: 34.h,
                          decoration: BoxDecoration(
                            color: surf2,
                            border: Border.all(color: bdr2),
                            borderRadius: BorderRadius.circular(9.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 13.sp,
                                color: textClr,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Edit',
                                style: GoogleFonts.dmSans(
                                  color: textClr,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        height: 34.h,
                        width: 34.h,
                        decoration: BoxDecoration(
                          color: redDim,
                          borderRadius: BorderRadius.circular(9.r),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 14.sp,
                          color: red,
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

  Widget _stat(String label, String val, Color lc, Color vc, {Color? bg}) =>
      Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
          decoration: BoxDecoration(
            color:
                bg ??
                (isDark ? const Color(0xFF16161F) : const Color(0xFFEEF0F6)),
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmMono(
                  fontSize: 8.sp,
                  color: lc,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                val,
                style: GoogleFonts.syne(
                  fontSize: 12.sp,
                  color: vc,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _info(IconData icon, String val) => Padding(
    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
    child: Row(
      children: [
        Icon(icon, size: 12.sp, color: textMut),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            val,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(color: textClr, fontSize: 11.sp),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  DETAIL SHEET  (mobile bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final bool isDark;
  final Customer customer;
  final VoidCallback onEdit, onDelete, onLedger;
  const _DetailSheet({
    required this.isDark,
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onLedger,
  });

  Color get surface =>
      isDark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  Color get surf2 => isDark ? const Color(0xFF16161F) : const Color(0xFFEEF0F6);
  Color get bdr2 => isDark ? const Color(0x18FFFFFF) : const Color(0x22000000);
  Color get textClr =>
      isDark ? const Color(0xFFF0EFF8) : const Color(0xFF0F0F1A);
  Color get textMut =>
      isDark ? const Color(0x73F0EFF8) : const Color(0x88000000);
  static const Color red = Color(0xFFFF3B3B);
  static const Color redDim = Color(0x1FFF3B3B);
  static const Color green = Color(0xFF34C759);
  static const Color greenDim = Color(0x1A34C759);
  static const Color amber = Color(0xFFF5C842);
  static const Color amberDim = Color(0x1AF5C842);

  String _initials(String n) {
    final p = n.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : n.isNotEmpty
        ? n[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final bal = c.balance;
    final isZero = bal == 0;
    final isNeg = bal < 0;
    final balColor = isZero
        ? amber
        : isNeg
        ? green
        : red;
    final balBg = isZero
        ? amberDim
        : isNeg
        ? greenDim
        : redDim;
    final balLabel = isZero
        ? 'Settled'
        : isNeg
        ? '-\$${bal.abs().toStringAsFixed(2)}'
        : '\$${bal.toStringAsFixed(2)}';

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        border: Border.all(color: bdr2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: bdr2,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: redDim,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    _initials(c.name),
                    style: GoogleFonts.syne(
                      fontSize: 15.sp,
                      color: red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: GoogleFonts.syne(
                      color: textClr,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    c.id,
                    style: GoogleFonts.dmMono(color: textMut, fontSize: 10.sp),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _chip(
                'Purchases',
                '\$${c.totalPurchases.toStringAsFixed(2)}',
                textMut,
                textClr,
                surf2,
              ),
              SizedBox(width: 8.w),
              _chip('Balance', balLabel, textMut, balColor, balBg),
            ],
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: onLedger,
            child: Container(
              height: 38.h,
              decoration: BoxDecoration(
                color: greenDim,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: green.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments_outlined, size: 14.sp, color: green),
                  SizedBox(width: 6.w),
                  Text(
                    'Record Payment / Purchase',
                    style: GoogleFonts.dmSans(
                      color: green,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    height: 38.h,
                    decoration: BoxDecoration(
                      color: surf2,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Center(
                      child: Text(
                        'Edit',
                        style: GoogleFonts.dmSans(
                          color: textClr,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  height: 38.h,
                  width: 46.w,
                  decoration: BoxDecoration(
                    color: redDim,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16.sp,
                    color: red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String val, Color lc, Color vc, Color bg) =>
      Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmMono(
                  fontSize: 8.sp,
                  color: lc,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                val,
                style: GoogleFonts.syne(
                  fontSize: 12.sp,
                  color: vc,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  CUSTOMER FORM DIALOG  (add / edit — name, phone, email only)
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerFormDialog extends StatelessWidget {
  final bool isDark, isEdit;
  final TextEditingController nameCtrl, phoneCtrl, emailCtrl;
  final VoidCallback onSave;
  const _CustomerFormDialog({
    required this.isDark,
    required this.isEdit,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.onSave,
  });

  Color get surface =>
      isDark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  Color get surf2 => isDark ? const Color(0xFF16161F) : const Color(0xFFEEF0F6);
  Color get bdr2 => isDark ? const Color(0x18FFFFFF) : const Color(0x22000000);
  Color get textClr =>
      isDark ? const Color(0xFFF0EFF8) : const Color(0xFF0F0F1A);
  Color get textMut =>
      isDark ? const Color(0x73F0EFF8) : const Color(0x88000000);
  static const Color red = Color(0xFFFF3B3B);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
        side: BorderSide(color: bdr2),
      ),
      child: SizedBox(
        width: 340.w,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Customer' : 'New Customer',
                style: GoogleFonts.syne(
                  color: textClr,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 14.h),
              _field(
                'Full Name',
                nameCtrl,
                Icons.person_outline,
                TextInputType.name,
              ),
              SizedBox(height: 9.h),
              _field(
                'Phone',
                phoneCtrl,
                Icons.phone_outlined,
                TextInputType.phone,
              ),
              SizedBox(height: 9.h),
              _field(
                'Email',
                emailCtrl,
                Icons.email_outlined,
                TextInputType.emailAddress,
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: surf2,
                          borderRadius: BorderRadius.circular(9.r),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.dmSans(
                              color: textMut,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        onSave();
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: red,
                          borderRadius: BorderRadius.circular(9.r),
                          boxShadow: [
                            BoxShadow(
                              color: red.withOpacity(0.28),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            isEdit ? 'Save Changes' : 'Add Customer',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon,
    TextInputType type,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmMono(
            fontSize: 9.sp,
            color: textMut,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          height: 36.h,
          decoration: BoxDecoration(
            color: surf2,
            border: Border.all(color: bdr2),
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            style: GoogleFonts.dmSans(color: textClr, fontSize: 12.sp),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 13.sp, color: textMut),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10.h),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LEDGER DIALOG  (record payment دفعة or new purchase فاتورة)
// ─────────────────────────────────────────────────────────────────────────────

class _LedgerDialog extends StatefulWidget {
  final bool isDark;
  final Customer customer;
  final TextEditingController amountCtrl, noteCtrl;
  final String initialType;
  final void Function(String type) onSave;
  const _LedgerDialog({
    required this.isDark,
    required this.customer,
    required this.amountCtrl,
    required this.noteCtrl,
    required this.initialType,
    required this.onSave,
  });

  @override
  State<_LedgerDialog> createState() => _LedgerDialogState();
}

class _LedgerDialogState extends State<_LedgerDialog> {
  late String _type;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  Color get surface =>
      widget.isDark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  Color get surf2 =>
      widget.isDark ? const Color(0xFF16161F) : const Color(0xFFEEF0F6);
  Color get bdr2 =>
      widget.isDark ? const Color(0x18FFFFFF) : const Color(0x22000000);
  Color get textClr =>
      widget.isDark ? const Color(0xFFF0EFF8) : const Color(0xFF0F0F1A);
  Color get textMut =>
      widget.isDark ? const Color(0x73F0EFF8) : const Color(0x88000000);
  static const Color red = Color(0xFFFF3B3B);
  static const Color redDim = Color(0x1FFF3B3B);
  static const Color green = Color(0xFF34C759);
  static const Color greenDim = Color(0x1A34C759);

  @override
  Widget build(BuildContext context) {
    final isPay = _type == 'payment';
    final ac = isPay ? green : red;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
        side: BorderSide(color: bdr2),
      ),
      child: SizedBox(
        width: 320.w,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Entry',
                style: GoogleFonts.syne(
                  color: textClr,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'for ${widget.customer.name}',
                style: GoogleFonts.dmSans(color: textMut, fontSize: 11.sp),
              ),
              SizedBox(height: 14.h),
              // Toggle
              Row(
                children: [
                  _typeBtn('Payment (دفعة)', 'payment', green, greenDim),
                  SizedBox(width: 8.w),
                  _typeBtn('Purchase (فاتورة)', 'purchase', red, redDim),
                ],
              ),
              SizedBox(height: 12.h),
              // Amount
              Text(
                'Amount (\$)',
                style: GoogleFonts.dmMono(
                  fontSize: 9.sp,
                  color: textMut,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                height: 36.h,
                decoration: BoxDecoration(
                  color: surf2,
                  border: Border.all(color: ac.withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: TextField(
                  controller: widget.amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.dmMono(
                    color: textClr,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.attach_money_rounded,
                      size: 14.sp,
                      color: ac,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              // Note
              Text(
                'Note (optional)',
                style: GoogleFonts.dmMono(
                  fontSize: 9.sp,
                  color: textMut,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                height: 36.h,
                decoration: BoxDecoration(
                  color: surf2,
                  border: Border.all(color: bdr2),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: TextField(
                  controller: widget.noteCtrl,
                  style: GoogleFonts.dmSans(color: textClr, fontSize: 12.sp),
                  decoration: InputDecoration(
                    hintText: isPay ? 'e.g. Daf3a March' : 'e.g. Invoice #106',
                    hintStyle: GoogleFonts.dmSans(
                      color: textMut,
                      fontSize: 12.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.notes_rounded,
                      size: 13.sp,
                      color: textMut,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: surf2,
                          borderRadius: BorderRadius.circular(9.r),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.dmSans(
                              color: textMut,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final amt =
                            double.tryParse(widget.amountCtrl.text) ?? 0;
                        if (amt <= 0) return;
                        widget.onSave(_type);
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: ac,
                          borderRadius: BorderRadius.circular(9.r),
                          boxShadow: [
                            BoxShadow(
                              color: ac.withOpacity(0.28),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            isPay ? 'Record Payment' : 'Add Purchase',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBtn(String label, String val, Color color, Color dimColor) {
    final active = _type == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 34.h,
          decoration: BoxDecoration(
            color: active ? dimColor : Colors.transparent,
            border: Border.all(color: active ? color.withOpacity(0.4) : bdr2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: active ? color : textMut,
                fontSize: 10.5.sp,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
