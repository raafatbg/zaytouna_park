// lib/Features/Expenses/expenses_screen.dart
// Zaytouna POS - Expenses Screen (Connected to Supabase)

// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LIGHT THEME PALETTE
// ─────────────────────────────────────────────────────────────────────────────

class ExpenseColors {
  ExpenseColors._();

  static const bg = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0F2F5);
  static const surface3 = Color(0xFFE8EBF0);
  static const border = Color(0xFFE2E5EA);
  static const borderLight = Color(0xFFEDF0F4);

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

  static const gray = Color(0xFF6B7280);
}

// ─────────────────────────────────────────────────────────────────────────────
//  FONTS
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
//  EXPENSES SCREEN (OPTIMIZED)
// ─────────────────────────────────────────────────────────────────────────────

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late final SupabaseClient _supabase;

  // Color shortcuts
  Color get bg => ExpenseColors.bg;
  Color get surface => ExpenseColors.surface;
  Color get surface2 => ExpenseColors.surface2;
  Color get surface3 => ExpenseColors.surface3;
  Color get border => ExpenseColors.border;
  Color get textClr => ExpenseColors.text;
  Color get textMuted => ExpenseColors.textSecondary;
  Color get textDim => ExpenseColors.textMuted;

  // State variables
  String _searchQuery = '';
  ExpenseCategory? _filterCategory;
  bool _isLoading = true;

  // CACHED DATA
  List<ExpenseItem> _expenses = [];
  List<ExpenseItem> _cachedFiltered = [];

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

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _loadExpenses();
  }

  // Parsers to work around the single 'description' column in your DB schema
  ExpenseCategory _extractCategory(String text) {
    if (text.startsWith('[supplies]')) return ExpenseCategory.supplies;
    if (text.startsWith('[utilities]')) return ExpenseCategory.utilities;
    if (text.startsWith('[rent]')) return ExpenseCategory.rent;
    if (text.startsWith('[salaries]')) return ExpenseCategory.salaries;
    if (text.startsWith('[marketing]')) return ExpenseCategory.marketing;
    if (text.startsWith('[maintenance]')) return ExpenseCategory.maintenance;
    return ExpenseCategory.other;
  }

  String _extractTitle(String text) {
    final noCat = text.replaceAll(RegExp(r'^\[.*?\]\s*'), '');
    final parts = noCat.split(' | ');
    return parts.isNotEmpty ? parts[0].trim() : 'Expense';
  }

  String _extractDesc(String text) {
    final parts = text.split(' | ');
    return parts.length > 1 ? parts[1].trim() : '';
  }

  Color _getColorForCategory(ExpenseCategory category) {
    return _categories.firstWhere((c) => c.category == category).color;
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('expenses')
          .select('id, description, amount, created_at')
          .order('created_at', ascending: false);

      final expenses = <ExpenseItem>[];
      for (var exp in data) {
        final rawDesc = exp['description']?.toString() ?? '';
        final category = _extractCategory(rawDesc);

        expenses.add(
          ExpenseItem(
            id: exp['id'].toString(),
            title: _extractTitle(rawDesc),
            description: _extractDesc(rawDesc),
            amount: (exp['amount'] as num?)?.toDouble() ?? 0.0,
            category: category,
            date: DateTime.parse(exp['created_at']),
            color: _getColorForCategory(category),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _expenses = expenses;
          _recalculateFiltered();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading expenses: $e');
      if (mounted) {
        _showToast('Failed to load expenses', ExpenseColors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  void _recalculateFiltered() {
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

    _cachedFiltered = list;
  }

  void _updateFilters({String? search, ExpenseCategory? category}) {
    bool changed = false;

    if (search != null && search != _searchQuery) {
      _searchQuery = search;
      changed = true;
    }
    if (category != _filterCategory) {
      _filterCategory = category;
      changed = true;
    }

    if (changed) {
      setState(() => _recalculateFiltered());
    }
  }

  void _updateExpensesList() {
    setState(() => _recalculateFiltered());
  }

  // Computed properties
  double get _totalExpenses => _expenses.fold(0, (s, e) => s + e.amount);
  double get _monthlyExpenses => _expenses
      .where(
        (e) =>
            e.date.month == DateTime.now().month &&
            e.date.year == DateTime.now().year,
      )
      .fold(0, (s, e) => s + e.amount);
  int get _expenseCount => _expenses.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: ExpenseColors.green))
          : LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    _TopBar(),
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
                              totalExpenses: _totalExpenses,
                              monthlyExpenses: _monthlyExpenses,
                              expenseCount: _expenseCount,
                              constraints: constraints,
                            ),
                            SizedBox(height: 24.h),
                            _CategoriesSection(
                              categories: _categories,
                              selectedCategory: _filterCategory,
                              onCategorySelected: (c) =>
                                  _updateFilters(category: c),
                              constraints: constraints,
                            ),
                            SizedBox(height: 24.h),
                            _ExpensesListSection(
                              expenses: _cachedFiltered,
                              searchQuery: _searchQuery,
                              onSearchChanged: (s) => _updateFilters(search: s),
                              onAddPressed: _showAddExpenseDialog,
                              onDeleteExpense: (id) async {
                                try {
                                  await _supabase
                                      .from('expenses')
                                      .delete()
                                      .eq('id', int.parse(id));
                                  setState(() {
                                    _expenses.removeWhere((e) => e.id == id);
                                    _updateExpensesList();
                                  });
                                  _showToast(
                                    'Expense deleted',
                                    ExpenseColors.green,
                                  );
                                } catch (e) {
                                  _showToast(
                                    'Failed to delete expense',
                                    ExpenseColors.red,
                                  );
                                }
                              },
                              categories: _categories,
                              constraints: constraints,
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

  // ── DIALOGS ──────────────────────────────────────────────────────────────────

  void _showAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    ExpenseCategory selectedCategory = ExpenseCategory.supplies;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
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
          // FIX: Constrained box and SingleChildScrollView prevents keyboard overflow
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxWidth: 340.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DialogField(label: 'Title', ctrl: titleCtrl),
                  SizedBox(height: 12.h),
                  _DialogField(label: 'Description', ctrl: descCtrl),
                  SizedBox(height: 12.h),
                  _DialogField(
                    label: 'Amount \$',
                    ctrl: amountCtrl,
                    isNumber: true,
                  ),
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
                            onTap: () =>
                                set(() => selectedCategory = c.category),
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
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
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
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (titleCtrl.text.isEmpty || amountCtrl.text.isEmpty) {
                        return;
                      }
                      set(() => isSubmitting = true);

                      try {
                        // Database formatting trick
                        final combinedDesc =
                            '[${selectedCategory.name}] ${titleCtrl.text} | ${descCtrl.text}';

                        final res = await _supabase
                            .from('expenses')
                            .insert({
                              'description': combinedDesc,
                              'amount': double.parse(amountCtrl.text),
                              'recorded_by_id': _supabase.auth.currentUser?.id,
                            })
                            .select()
                            .single();

                        if (mounted) {
                          final cat = _categories.firstWhere(
                            (c) => c.category == selectedCategory,
                          );
                          setState(() {
                            _expenses.insert(
                              0,
                              ExpenseItem(
                                id: res['id'].toString(),
                                title: titleCtrl.text,
                                description: descCtrl.text,
                                amount: double.parse(amountCtrl.text),
                                category: selectedCategory,
                                date: DateTime.parse(res['created_at']),
                                color: cat.color,
                              ),
                            );
                            _updateExpensesList();
                          });
                          Navigator.pop(ctx);
                          _showToast(
                            'Expense added successfully',
                            ExpenseColors.green,
                          );
                        }
                      } catch (e) {
                        set(() => isSubmitting = false);
                        _showToast('Failed to add expense', ExpenseColors.red);
                      }
                    },
              child: isSubmitting
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
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

// ─────────────────────────────────────────────────────────────────────────────
//  SEPARATE WIDGETS (for cleaner rebuilds)
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatefulWidget {
  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  String _currentTime = '';
  String _currentDate = '';
  Timer? _timer;

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

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateDateTime(),
    );
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Detect mobile size to hide certain elements
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: ExpenseColors.surface,
        border: Border(
          bottom: BorderSide(color: ExpenseColors.border, width: 1),
        ),
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
              color: ExpenseColors.surface2,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.menu_rounded,
              size: 20.sp,
              color: ExpenseColors.text,
            ),
          ),
          SizedBox(width: 16.w),
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
          // FIX: Wrap title column in Expanded
          Expanded(
            child: Column(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Expenses',
                  style: ExpenseFonts.sans(
                    12.sp,
                    w: FontWeight.w600,
                    color: ExpenseColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // FIX: Hide Time & Date container on smaller mobile screens
          if (!isMobile) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: ExpenseColors.surface2,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: const BoxDecoration(
                      color: ExpenseColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '$_currentTime  ·  $_currentDate',
                    style: ExpenseFonts.mono(
                      10.sp,
                      color: ExpenseColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
          ],
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: ExpenseColors.blueLight,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: ExpenseColors.border, width: 1.5),
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
  }
}

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
            color: ExpenseColors.redLight,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5.w,
                height: 5.w,
                decoration: const BoxDecoration(
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
          'Monitor and manage your venue expenses efficiently.',
          style: ExpenseFonts.sans(12.sp, color: ExpenseColors.textSecondary),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final double totalExpenses;
  final double monthlyExpenses;
  final int expenseCount;
  final BoxConstraints constraints;

  const _SummaryCards({
    required this.totalExpenses,
    required this.monthlyExpenses,
    required this.expenseCount,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SD(
        'Total Expenses',
        '\$${totalExpenses.toStringAsFixed(0)}',
        Icons.account_balance_wallet_outlined,
        ExpenseColors.red,
        ExpenseColors.redLight,
        'All time',
      ),
      _SD(
        'This Month',
        '\$${monthlyExpenses.toStringAsFixed(0)}',
        Icons.calendar_month_rounded,
        ExpenseColors.orange,
        ExpenseColors.orangeLight,
        'Current month',
      ),
      _SD(
        'Expenses',
        '$expenseCount',
        Icons.receipt_long_rounded,
        ExpenseColors.blue,
        ExpenseColors.blueLight,
        'Total entries',
      ),
      const _SD(
        'Categories',
        '7',
        Icons.category_rounded,
        ExpenseColors.purple,
        ExpenseColors.purpleLight,
        'Active',
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
        color: ExpenseColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ExpenseColors.border),
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
                  color: data.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(data.icon, size: 20.sp, color: data.accent),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: data.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  data.sub,
                  style: ExpenseFonts.mono(9.sp, color: data.accent),
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
              style: ExpenseFonts.serif(22.sp, w: FontWeight.w800),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            data.label,
            style: ExpenseFonts.sans(11.sp, color: ExpenseColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final List<CategoryData> categories;
  final ExpenseCategory? selectedCategory;
  final Function(ExpenseCategory?) onCategorySelected;
  final BoxConstraints constraints;

  const _CategoriesSection({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = constraints.maxWidth > 900
        ? 7
        : constraints.maxWidth > 600
        ? 4
        : 2;
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
                color: ExpenseColors.textSecondary,
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
            childAspectRatio: constraints.maxWidth > 800 ? 1.0 : 1.1,
          ),
          itemCount: categories.length,
          itemBuilder: (ctx, i) => _CategoryTile(
            data: categories[i],
            isSelected: selectedCategory == categories[i].category,
            onTap: () => onCategorySelected(
              selectedCategory == categories[i].category
                  ? null
                  : categories[i].category,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: ExpenseColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? data.color : ExpenseColors.border,
          ),
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
                color: ExpenseColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesListSection extends StatelessWidget {
  final List<ExpenseItem> expenses;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback onAddPressed;
  final Function(String) onDeleteExpense;
  final List<CategoryData> categories;
  final BoxConstraints constraints;

  const _ExpensesListSection({
    required this.expenses,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onAddPressed,
    required this.onDeleteExpense,
    required this.categories,
    required this.constraints,
  });

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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0 && now.day == date.day) return 'Today';
    if (diff.inDays == 1 || (diff.inDays == 0 && now.day != date.day)) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day} ${_months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = constraints.maxWidth > 800;
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
                color: ExpenseColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: ExpenseColors.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: ExpenseColors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 18.sp,
                color: ExpenseColors.textSecondary,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  style: ExpenseFonts.sans(12.sp),
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search expenses...',
                    hintStyle: ExpenseFonts.sans(
                      11.sp,
                      color: ExpenseColors.textDim,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  cursorColor: ExpenseColors.green,
                ),
              ),
              if (searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () => onSearchChanged(''),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16.sp,
                    color: ExpenseColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: onAddPressed,
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
        Container(
          decoration: BoxDecoration(
            color: ExpenseColors.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: ExpenseColors.border),
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
              if (expenses.isEmpty)
                Padding(
                  padding: EdgeInsets.all(36.w),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 40.sp,
                          color: ExpenseColors.textDim,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No expenses found',
                          style: ExpenseFonts.sans(
                            13.sp,
                            color: ExpenseColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...expenses.asMap().entries.map(
                  (entry) => _ExpenseRow(
                    expense: entry.value,
                    isLast: entry.key == expenses.length - 1,
                    isDesktop: isDesktop,
                    formatDate: _formatDate,
                    onDelete: () => onDeleteExpense(entry.value.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final ExpenseItem expense;
  final bool isLast;
  final bool isDesktop;
  final String Function(DateTime) formatDate;
  final VoidCallback onDelete;

  const _ExpenseRow({
    required this.expense,
    required this.isLast,
    required this.isDesktop,
    required this.formatDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20.w : 14.w,
        vertical: isDesktop ? 14.h : 12.h,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: ExpenseColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: expense.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              expense.categoryIcon,
              size: 20.sp,
              color: expense.color,
            ),
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
                  style: ExpenseFonts.sans(
                    10.sp,
                    color: ExpenseColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // FIX: Ensuring large amounts do not overflow
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-\$${expense.amount.toStringAsFixed(2)}',
                  style: ExpenseFonts.mono(
                    12.sp,
                    w: FontWeight.w600,
                    color: ExpenseColors.red,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  formatDate(expense.date),
                  style: ExpenseFonts.mono(
                    9.sp,
                    color: ExpenseColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 18.sp,
              color: ExpenseColors.textSecondary,
            ),
            itemBuilder: (_) => [
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
              if (v == 'delete') onDelete();
            },
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool isNumber;

  const _DialogField({
    required this.label,
    required this.ctrl,
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
          style: ExpenseFonts.sans(
            9.sp,
            w: FontWeight.w600,
            color: ExpenseColors.textDim,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          height: 40.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: ExpenseColors.surface2,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: ExpenseColors.border),
          ),
          child: TextField(
            controller: ctrl,
            style: ExpenseFonts.sans(12.sp),
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: isNumber
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : [],
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            cursorColor: ExpenseColors.green,
          ),
        ),
      ],
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
