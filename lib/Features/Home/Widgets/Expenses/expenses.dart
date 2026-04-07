// lib/Features/Expenses/expenses_screen.dart
// Zaytouna POS - Expenses Screen (Light Theme - Home Page Style)

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LIGHT THEME PALETTE (Matching Home Page)
// ─────────────────────────────────────────────────────────────────────────────

class ExpenseColors {
  ExpenseColors._();

  // Base Colors
  static const bg = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0F2F5);
  static const surface3 = Color(0xFFE8EBF0);
  static const border = Color(0xFFE2E5EA);
  static const borderLight = Color(0xFFEDF0F4);

  // Text Colors
  static const text = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const textDim = Color(0xFFCBD5E1);

  // Accent Colors
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
}

// ─────────────────────────────────────────────────────────────────────────────
//  FONTS (Matching Home Page Style)
// ─────────────────────────────────────────────────────────────────────────────

class ExpenseFonts {
  ExpenseFonts._();

  static TextStyle serif(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.dmSerifDisplay(
    fontSize: size,
    fontWeight: w,
    color: color ?? ExpenseColors.text,
  );

  static TextStyle sans(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color ?? ExpenseColors.text,
  );

  static TextStyle mono(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: w,
    color: color ?? ExpenseColors.text,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum ExpenseCategory {
  supplies,
  utilities,
  rent,
  salaries,
  marketing,
  maintenance,
  other,
}

class ExpenseItem {
  final String id;
  final String title;
  final String description;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? receipt;
  final Color color;

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    this.receipt,
    required this.color,
  });

  String get categoryLabel {
    switch (category) {
      case ExpenseCategory.supplies:
        return 'Supplies';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.salaries:
        return 'Salaries';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case ExpenseCategory.supplies:
        return Icons.inventory_2_rounded;
      case ExpenseCategory.utilities:
        return Icons.electrical_services_rounded;
      case ExpenseCategory.rent:
        return Icons.home_work_rounded;
      case ExpenseCategory.salaries:
        return Icons.people_rounded;
      case ExpenseCategory.marketing:
        return Icons.campaign_rounded;
      case ExpenseCategory.maintenance:
        return Icons.build_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }
}

class CategoryData {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final ExpenseCategory category;

  const CategoryData({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.category,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  EXPENSES SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // Color shortcuts
  Color get bg => ExpenseColors.bg;
  Color get surface => ExpenseColors.surface;
  Color get surface2 => ExpenseColors.surface2;
  Color get surface3 => ExpenseColors.surface3;
  Color get border => ExpenseColors.border;
  Color get textClr => ExpenseColors.text;
  Color get textMuted => ExpenseColors.textSecondary;
  Color get textDim => ExpenseColors.textMuted;

  String _currentTime = '';
  String _currentDate = '';
  Timer? _timer;
  String _searchQuery = '';
  ExpenseCategory? _filterCategory;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Expense categories (matching home page tile style)
  static const List<CategoryData> _categories = [
    CategoryData(
      title: 'Supplies',
      icon: Icons.inventory_2_rounded,
      color: ExpenseColors.blue,
      bgColor: ExpenseColors.blueLight,
      category: ExpenseCategory.supplies,
    ),
    CategoryData(
      title: 'Utilities',
      icon: Icons.electrical_services_rounded,
      color: ExpenseColors.yellow,
      bgColor: ExpenseColors.yellowLight,
      category: ExpenseCategory.utilities,
    ),
    CategoryData(
      title: 'Rent',
      icon: Icons.home_work_rounded,
      color: ExpenseColors.purple,
      bgColor: ExpenseColors.purpleLight,
      category: ExpenseCategory.rent,
    ),
    CategoryData(
      title: 'Salaries',
      icon: Icons.people_rounded,
      color: ExpenseColors.green,
      bgColor: ExpenseColors.greenLight,
      category: ExpenseCategory.salaries,
    ),
    CategoryData(
      title: 'Marketing',
      icon: Icons.campaign_rounded,
      color: ExpenseColors.orange,
      bgColor: ExpenseColors.orangeLight,
      category: ExpenseCategory.marketing,
    ),
    CategoryData(
      title: 'Maintenance',
      icon: Icons.build_rounded,
      color: ExpenseColors.cyan,
      bgColor: ExpenseColors.cyanLight,
      category: ExpenseCategory.maintenance,
    ),
    CategoryData(
      title: 'Other',
      icon: Icons.more_horiz_rounded,
      color: ExpenseColors.textMuted,
      bgColor: ExpenseColors.surface2,
      category: ExpenseCategory.other,
    ),
  ];

  // Mock expense data
  late List<ExpenseItem> _expenses;

  @override
  void initState() {
    super.initState();
    _expenses = _mockExpenses();
    _updateDateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateDateTime(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateDateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _currentDate =
          '${_days[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';
    });
  }

  List<ExpenseItem> _mockExpenses() => [
    ExpenseItem(
      id: '1',
      title: 'Kitchen Supplies',
      description: 'Cleaning materials, napkins, containers',
      amount: 245.50,
      category: ExpenseCategory.supplies,
      date: DateTime.now().subtract(const Duration(days: 1)),
      color: ExpenseColors.blue,
    ),
    ExpenseItem(
      id: '2',
      title: 'Electricity Bill',
      description: 'Monthly electricity - March 2024',
      amount: 890.00,
      category: ExpenseCategory.utilities,
      date: DateTime.now().subtract(const Duration(days: 2)),
      color: ExpenseColors.yellow,
    ),
    ExpenseItem(
      id: '3',
      title: 'Staff Salaries',
      description: 'Restaurant staff payment - Week 12',
      amount: 4500.00,
      category: ExpenseCategory.salaries,
      date: DateTime.now().subtract(const Duration(days: 3)),
      color: ExpenseColors.green,
    ),
    ExpenseItem(
      id: '4',
      title: 'Social Media Ads',
      description: 'Facebook & Instagram promotion',
      amount: 350.00,
      category: ExpenseCategory.marketing,
      date: DateTime.now().subtract(const Duration(days: 4)),
      color: ExpenseColors.orange,
    ),
    ExpenseItem(
      id: '5',
      title: 'AC Repair',
      description: 'Kitchen AC unit maintenance',
      amount: 180.00,
      category: ExpenseCategory.maintenance,
      date: DateTime.now().subtract(const Duration(days: 5)),
      color: ExpenseColors.cyan,
    ),
    ExpenseItem(
      id: '6',
      title: 'Monthly Rent',
      description: 'Restaurant space rent - March',
      amount: 3000.00,
      category: ExpenseCategory.rent,
      date: DateTime.now().subtract(const Duration(days: 6)),
      color: ExpenseColors.purple,
    ),
    ExpenseItem(
      id: '7',
      title: 'POS Paper Rolls',
      description: 'Receipt paper, label rolls',
      amount: 45.00,
      category: ExpenseCategory.supplies,
      date: DateTime.now().subtract(const Duration(days: 7)),
      color: ExpenseColors.blue,
    ),
    ExpenseItem(
      id: '8',
      title: 'Water Bill',
      description: 'Monthly water supply - March',
      amount: 220.00,
      category: ExpenseCategory.utilities,
      date: DateTime.now().subtract(const Duration(days: 8)),
      color: ExpenseColors.yellow,
    ),
  ];

  List<ExpenseItem> get _filtered {
    var list = List<ExpenseItem>.from(_expenses);
    if (_filterCategory != null) {
      list = list.where((e) => e.category == _filterCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (e) =>
                e.title.toLowerCase().contains(q) ||
                e.description.toLowerCase().contains(q),
          )
          .toList();
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double get _totalExpenses => _expenses.fold(0, (s, e) => s + e.amount);
  double get _monthlyExpenses => _filtered
      .where((e) => e.date.month == DateTime.now().month)
      .fold(0, (s, e) => s + e.amount);
  int get _expenseCount => _expenses.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              _topBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _welcomeHeader(),
                      SizedBox(height: 24.h),
                      _summaryCards(constraints),
                      SizedBox(height: 24.h),
                      _categoriesSection(constraints),
                      SizedBox(height: 24.h),
                      _expensesListSection(constraints),
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

  // ── Top Bar ──────────────────────────────────────────────────────────────────

  Widget _topBar() => Container(
    height: 64.h,
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    decoration: BoxDecoration(
      color: surface,
      border: Border(bottom: BorderSide(color: border, width: 1)),
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
        // Hamburger Menu
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: surface2,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(Icons.menu_rounded, size: 20.sp, color: textClr),
        ),
        SizedBox(width: 16.w),

        // Logo
        Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: ExpenseColors.green,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.park_rounded, size: 22.sp, color: Colors.white),
            ),
            SizedBox(width: 10.w),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ZAYTOUNA PARK',
                  style: ExpenseFonts.sans(
                    8.sp,
                    w: FontWeight.w700,
                    color: ExpenseColors.green,
                  ),
                ),
                Text(
                  'Expenses',
                  style: ExpenseFonts.sans(
                    12.sp,
                    w: FontWeight.w600,
                    color: textClr,
                  ),
                ),
              ],
            ),
          ],
        ),

        const Spacer(),

        // Time & Date
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: surface2,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  color: ExpenseColors.green,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '$_currentTime  ·  $_currentDate',
                style: ExpenseFonts.mono(10.sp, color: textMuted),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),

        // User Avatar
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: ExpenseColors.blueLight,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Center(
            child: Text(
              'S',
              style: ExpenseFonts.sans(
                16.sp,
                w: FontWeight.w700,
                color: ExpenseColors.blue,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ── Welcome Header ───────────────────────────────────────────────────────────

  Widget _welcomeHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: ExpenseColors.redLight,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5.w,
              height: 5.w,
              decoration: BoxDecoration(
                color: ExpenseColors.red,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              'EXPENSE TRACKER',
              style: ExpenseFonts.sans(
                8.sp,
                w: FontWeight.w700,
                color: ExpenseColors.red,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 12.h),
      Text('Track Your Expenses', style: ExpenseFonts.serif(36.sp)),
      SizedBox(height: 6.h),
      Text(
        'Monitor and manage your restaurant expenses efficiently.',
        style: ExpenseFonts.sans(12.sp, color: textMuted),
      ),
    ],
  );

  // ── Summary Cards (Matching Home Page Style) ─────────────────────────────────

  Widget _summaryCards(BoxConstraints c) {
    final cards = [
      _SD(
        'Total Expenses',
        '\$${_totalExpenses.toStringAsFixed(0)}',
        Icons.account_balance_wallet_outlined,
        ExpenseColors.red,
        ExpenseColors.redLight,
        'All time',
      ),
      _SD(
        'This Month',
        '\$${_monthlyExpenses.toStringAsFixed(0)}',
        Icons.calendar_month_rounded,
        ExpenseColors.orange,
        ExpenseColors.orangeLight,
        'Current month',
      ),
      _SD(
        'Expenses',
        '$_expenseCount',
        Icons.receipt_long_rounded,
        ExpenseColors.blue,
        ExpenseColors.blueLight,
        'Total entries',
      ),
      _SD(
        'Categories',
        '7',
        Icons.category_rounded,
        ExpenseColors.purple,
        ExpenseColors.purpleLight,
        'Active',
      ),
    ];

    if (c.maxWidth >= 900) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(width: 16.w),
            Expanded(child: _summaryCard(cards[i])),
          ],
        ],
      );
    } else if (c.maxWidth >= 600) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _summaryCard(cards[0])),
              SizedBox(width: 12.w),
              Expanded(child: _summaryCard(cards[1])),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: _summaryCard(cards[2])),
              SizedBox(width: 12.w),
              Expanded(child: _summaryCard(cards[3])),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            _summaryCard(cards[i]),
            if (i < 3) SizedBox(height: 10.h),
          ],
        ],
      );
    }
  }

  Widget _summaryCard(_SD d) => Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(color: border),
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
                color: _colorWithOpacity(d.accent, 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(d.icon, size: 20.sp, color: d.accent),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _colorWithOpacity(d.accent, 0.12),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                d.sub,
                style: ExpenseFonts.mono(9.sp, color: d.accent),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            d.value,
            style: ExpenseFonts.serif(22.sp, w: FontWeight.w800),
          ),
        ),
        SizedBox(height: 2.h),
        Text(d.label, style: ExpenseFonts.sans(11.sp, color: textMuted)),
      ],
    ),
  );

  Color _colorWithOpacity(Color color, double opacity) =>
      color.withOpacity(opacity);

  // ── Categories Grid (Matching Home Page Tile Style) ───────────────────────────

  Widget _categoriesSection(BoxConstraints c) {
    final isDesktop = c.maxWidth > 800;
    int crossAxisCount = 2;
    if (c.maxWidth > 600) crossAxisCount = 4;
    if (c.maxWidth > 900) crossAxisCount = 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EXPENSE CATEGORIES',
              style: ExpenseFonts.sans(
                11.sp,
                w: FontWeight.w700,
                color: textMuted,
              ),
            ),
            Row(
              children: [
                Text(
                  'View all',
                  style: ExpenseFonts.sans(
                    11.sp,
                    w: FontWeight.w600,
                    color: ExpenseColors.green,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14.sp,
                  color: ExpenseColors.green,
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: isDesktop ? 1.0 : 1.1,
          ),
          itemCount: _categories.length,
          itemBuilder: (ctx, i) => _categoryTile(_categories[i]),
        ),
      ],
    );
  }

  Widget _categoryTile(CategoryData data) {
    final isSelected = _filterCategory == data.category;
    return GestureDetector(
      onTap: () =>
          setState(() => _filterCategory = isSelected ? null : data.category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isSelected ? data.color : border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.06 : 0.02),
              blurRadius: isSelected ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: data.bgColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(data.icon, size: 24.sp, color: data.color),
            ),
            SizedBox(height: 8.h),
            Text(
              data.title,
              style: ExpenseFonts.sans(
                11.sp,
                w: FontWeight.w600,
                color: textClr,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Expenses List (Matching Home Page Activity Style) ────────────────────────

  Widget _expensesListSection(BoxConstraints c) {
    final isDesktop = c.maxWidth > 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT EXPENSES',
              style: ExpenseFonts.sans(
                11.sp,
                w: FontWeight.w700,
                color: textMuted,
              ),
            ),
            Row(
              children: [
                Text(
                  'See all',
                  style: ExpenseFonts.sans(
                    11.sp,
                    w: FontWeight.w600,
                    color: ExpenseColors.green,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14.sp,
                  color: ExpenseColors.green,
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Search bar
        Container(
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 18.sp, color: textMuted),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  style: ExpenseFonts.sans(12.sp),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search expenses...',
                    hintStyle: ExpenseFonts.sans(11.sp, color: textDim),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  cursorColor: ExpenseColors.green,
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _searchQuery = ''),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16.sp,
                    color: textMuted,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Add Expense Button
        GestureDetector(
          onTap: _showAddExpenseDialog,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: ExpenseColors.green,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: ExpenseColors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 18.sp, color: Colors.white),
                SizedBox(width: 8.w),
                Text(
                  'Add New Expense',
                  style: ExpenseFonts.sans(
                    12.sp,
                    w: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // Expenses list (matching activity feed style)
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_filtered.isEmpty)
                Padding(
                  padding: EdgeInsets.all(36.w),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 40.sp,
                          color: textDim,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No expenses found',
                          style: ExpenseFonts.sans(13.sp, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._filtered.asMap().entries.map(
                  (entry) => _expenseRow(
                    entry.value,
                    entry.key == _filtered.length - 1,
                    isDesktop,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _expenseRow(
    ExpenseItem expense,
    bool isLast,
    bool isDesktop,
  ) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: isDesktop ? 20.w : 14.w,
      vertical: isDesktop ? 14.h : 12.h,
    ),
    decoration: BoxDecoration(
      border: isLast ? null : Border(bottom: BorderSide(color: border)),
    ),
    child: Row(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: _colorWithOpacity(expense.color, 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(expense.categoryIcon, size: 20.sp, color: expense.color),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.title,
                style: ExpenseFonts.sans(12.sp, w: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                expense.description,
                style: ExpenseFonts.sans(10.sp, color: textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '-\$${expense.amount.toStringAsFixed(2)}',
              style: ExpenseFonts.mono(
                12.sp,
                w: FontWeight.w600,
                color: ExpenseColors.red,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _formatDate(expense.date),
              style: ExpenseFonts.mono(9.sp, color: textMuted),
            ),
          ],
        ),
        SizedBox(width: 8.w),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, size: 18.sp, color: textMuted),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_rounded,
                    size: 16.sp,
                    color: ExpenseColors.red,
                  ),
                  SizedBox(width: 8.w),
                  Text('Delete', style: TextStyle(color: ExpenseColors.red)),
                ],
              ),
            ),
          ],
          onSelected: (v) {
            if (v == 'delete') {
              setState(() => _expenses.removeWhere((e) => e.id == expense.id));
              _showToast('Expense deleted', ExpenseColors.green);
            }
          },
        ),
      ],
    ),
  );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day} ${_months[date.month - 1]}';
  }

  // ── Add Expense Dialog ───────────────────────────────────────────────────────

  void _showAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    ExpenseCategory selectedCategory = ExpenseCategory.supplies;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Expense',
                style: ExpenseFonts.serif(18.sp, w: FontWeight.w800),
              ),
              SizedBox(height: 4.h),
              Text(
                'Record a new expense entry',
                style: ExpenseFonts.sans(11.sp, color: textMuted),
              ),
            ],
          ),
          content: SizedBox(
            width: 340.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('Title', titleCtrl),
                SizedBox(height: 12.h),
                _dialogField('Description', descCtrl),
                SizedBox(height: 12.h),
                _dialogField('Amount \$', amountCtrl),
                SizedBox(height: 12.h),
                Text(
                  'Category',
                  style: ExpenseFonts.sans(
                    9.sp,
                    w: FontWeight.w600,
                    color: textDim,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _categories
                      .map(
                        (c) => GestureDetector(
                          onTap: () => set(() => selectedCategory = c.category),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: selectedCategory == c.category
                                  ? c.bgColor
                                  : surface2,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: selectedCategory == c.category
                                    ? c.color
                                    : border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  c.icon,
                                  size: 14.sp,
                                  color: selectedCategory == c.category
                                      ? c.color
                                      : textMuted,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  c.title,
                                  style: ExpenseFonts.sans(
                                    10.sp,
                                    color: selectedCategory == c.category
                                        ? c.color
                                        : textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: ExpenseFonts.sans(12.sp, color: textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ExpenseColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
              ),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                  final cat = _categories.firstWhere(
                    (c) => c.category == selectedCategory,
                  );
                  setState(
                    () => _expenses.insert(
                      0,
                      ExpenseItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleCtrl.text,
                        description: descCtrl.text,
                        amount: double.tryParse(amountCtrl.text) ?? 0,
                        category: selectedCategory,
                        date: DateTime.now(),
                        color: cat.color,
                      ),
                    ),
                  );
                  Navigator.pop(ctx);
                  _showToast('Expense added', ExpenseColors.green);
                }
              },
              child: Text(
                'Add Expense',
                style: ExpenseFonts.sans(
                  12.sp,
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

  Widget _dialogField(String label, TextEditingController ctrl) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: ExpenseFonts.sans(9.sp, w: FontWeight.w600, color: textDim),
      ),
      SizedBox(height: 6.h),
      Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: surface2,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: border),
        ),
        child: TextField(
          controller: ctrl,
          style: ExpenseFonts.sans(12.sp),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10.h),
          ),
          cursorColor: ExpenseColors.green,
        ),
      ),
    ],
  );

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
              style: ExpenseFonts.sans(
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
}

class _SD {
  final String label, value, sub;
  final IconData icon;
  final Color accent, accentDim;
  const _SD(
    this.label,
    this.value,
    this.icon,
    this.accent,
    this.accentDim,
    this.sub,
  );
}
