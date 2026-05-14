// lib/Features/Inventory/category_screen.dart
// Zaytouna POS - Categories Screen (Connected to Supabase)

// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LIGHT THEME PALETTE
// ─────────────────────────────────────────────────────────────────────────────

class CategoryColors {
  CategoryColors._();

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

class CategoryFonts {
  CategoryFonts._();

  static TextStyle display(
    double size, {
    FontWeight w = FontWeight.w700,
    Color? color,
  }) => GoogleFonts.dmSerifDisplay(
    fontSize: size,
    fontWeight: w,
    color: color ?? CategoryColors.text,
  );

  static TextStyle sans(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color ?? CategoryColors.text,
  );

  static TextStyle mono(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: w,
    color: color ?? CategoryColors.text,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────────────────────

class ItemCategory {
  final int id;
  String name;
  int itemCount;
  final IconData icon;
  final Color color;
  double totalValue;

  ItemCategory({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.icon,
    required this.color,
    required this.totalValue,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  CATEGORIES SCREEN (OPTIMIZED)
// ─────────────────────────────────────────────────────────────────────────────

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late final SupabaseClient _supabase;
  final _searchCtrl = TextEditingController();

  List<ItemCategory> _categories = [];
  List<ItemCategory> _cachedFiltered = [];
  String _searchQuery = '';
  bool _isLoading = true;

  // Color shortcuts
  Color get bg => CategoryColors.bg;
  Color get surface => CategoryColors.surface;
  Color get surface2 => CategoryColors.surface2;
  Color get border => CategoryColors.border;
  Color get textClr => CategoryColors.text;
  Color get textMuted => CategoryColors.textSecondary;
  Color get textDim => CategoryColors.textMuted;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _loadCategories();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('oil') || lower.contains('vinegar')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('sea') || lower.contains('fish')) {
      return Icons.set_meal_rounded;
    }
    if (lower.contains('meat') || lower.contains('poultry')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('bev') || lower.contains('drink')) {
      return Icons.local_drink_rounded;
    }
    if (lower.contains('dairy') ||
        lower.contains('egg') ||
        lower.contains('milk')) {
      return Icons.egg_alt_rounded;
    }
    if (lower.contains('bake') || lower.contains('bread')) {
      return Icons.bakery_dining_rounded;
    }
    if (lower.contains('spice') || lower.contains('herb')) {
      return Icons.grass_rounded;
    }
    if (lower.contains('clean') || lower.contains('supplies')) {
      return Icons.cleaning_services_rounded;
    }
    if (lower.contains('froz') || lower.contains('ice')) {
      return Icons.ac_unit_rounded;
    }
    if (lower.contains('veg') || lower.contains('fruit')) {
      return Icons.eco_rounded;
    }
    return Icons.category_rounded;
  }

  Color _getCategoryColor(int id) {
    final colors = [
      CategoryColors.blue,
      CategoryColors.green,
      CategoryColors.orange,
      CategoryColors.purple,
      CategoryColors.cyan,
      CategoryColors.pink,
      CategoryColors.red,
      CategoryColors.indigo,
      CategoryColors.yellow,
    ];
    return colors[id.abs() % colors.length];
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      // Fetch categories and items concurrently to prevent N+1 query lag
      final results = await Future.wait([
        _supabase.from('inventory_categories').select('id, name').order('name'),
        _supabase
            .from('inventory_items')
            .select('category_id, current_quantity, cost_per_unit'),
      ]);

      final catsData = results[0] as List<dynamic>;
      final itemsData = results[1] as List<dynamic>;

      final categories = <ItemCategory>[];

      for (var cat in catsData) {
        final catId = cat['id'] as int;
        final catName = cat['name'] as String;

        int itemCount = 0;
        double totalValue = 0.0;

        // Group item metrics in Dart memory (blazing fast)
        for (var item in itemsData) {
          if (item['category_id'] == catId) {
            itemCount++;
            final qty = (item['current_quantity'] as num?)?.toDouble() ?? 0.0;
            final cost = (item['cost_per_unit'] as num?)?.toDouble() ?? 0.0;
            totalValue += (qty * cost);
          }
        }

        categories.add(
          ItemCategory(
            id: catId,
            name: catName,
            itemCount: itemCount,
            icon: _getCategoryIcon(catName),
            color: _getCategoryColor(catId),
            totalValue: totalValue,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _recalculateFiltered();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        _showToast('Failed to load categories', CategoryColors.red);
        setState(() => _isLoading = false);
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
    var list = List<ItemCategory>.from(_categories);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) => c.name.toLowerCase().contains(q)).toList();
    }

    list.sort((a, b) => a.name.compareTo(b.name));
    _cachedFiltered = list;
  }

  void _addCategory(String name) async {
    if (name.trim().isEmpty) return;

    try {
      final newCat = await _supabase
          .from('inventory_categories')
          .insert({'name': name.trim()})
          .select()
          .single();

      if (mounted) {
        final catName = newCat['name'] as String;
        final catId = newCat['id'] as int;

        setState(() {
          _categories.add(
            ItemCategory(
              id: catId,
              name: catName,
              itemCount: 0,
              icon: _getCategoryIcon(catName),
              color: _getCategoryColor(catId),
              totalValue: 0.0,
            ),
          );
          _recalculateFiltered();
        });
        _showToast('Category "$name" created', CategoryColors.green);
      }
    } catch (e) {
      print('Error adding category: $e');
      if (mounted) {
        _showToast(
          'Failed to create category. It may already exist.',
          CategoryColors.red,
        );
      }
    }
  }

  void _editCategory(ItemCategory cat, String newName) async {
    if (newName.trim().isEmpty) return;

    try {
      await _supabase
          .from('inventory_categories')
          .update({'name': newName.trim()})
          .eq('id', cat.id);

      if (mounted) {
        setState(() {
          cat.name = newName.trim();
          _recalculateFiltered();
        });
        _showToast('Category updated', CategoryColors.green);
      }
    } catch (e) {
      print('Error editing category: $e');
      if (mounted) _showToast('Failed to update category', CategoryColors.red);
    }
  }

  void _deleteCategory(ItemCategory cat) async {
    try {
      await _supabase.from('inventory_categories').delete().eq('id', cat.id);

      if (mounted) {
        setState(() {
          _categories.removeWhere((c) => c.id == cat.id);
          _recalculateFiltered();
        });
        _showToast('Category deleted', CategoryColors.green);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        // SQL State 23503 is foreign_key_violation
        if (e.code == '23503') {
          _showToast(
            'Cannot delete: This category still contains items.',
            CategoryColors.orange,
          );
        } else {
          _showToast('Failed to delete category', CategoryColors.red);
        }
      }
    } catch (e) {
      print('Error deleting category: $e');
      if (mounted) {
        _showToast('An unexpected error occurred', CategoryColors.red);
      }
    }
  }

  // ✅ Computed properties
  int get _totalCategories => _categories.length;
  int get _totalItems => _categories.fold(0, (s, c) => s + c.itemCount);
  double get _totalValue => _categories.fold(0.0, (s, c) => s + c.totalValue);
  double get _avgItemsPerCategory =>
      _totalCategories > 0 ? _totalItems / _totalCategories : 0;

  void _showToast(String msg, Color color) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.w),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        content: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 18.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                msg,
                style: CategoryFonts.sans(
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

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Create New Category',
          style: CategoryFonts.display(16.sp, w: FontWeight.w800),
        ),
        // FIX: Replaced fixed SizedBox with flexible Container
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxWidth: 320.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add a new category to organize your inventory items.',
                style: CategoryFonts.sans(11.sp, color: textMuted),
              ),
              SizedBox(height: 16.h),
              _DialogField(
                label: 'Category Name',
                ctrl: nameCtrl,
                icon: Icons.category_rounded,
                hint: 'e.g., Spices, Grains, Sauces',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: CategoryFonts.sans(12.sp, color: textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CategoryColors.green,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                _addCategory(nameCtrl.text);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Create Category',
              style: CategoryFonts.sans(
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

  void _showEditDialog(ItemCategory cat) {
    final nameCtrl = TextEditingController(text: cat.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Edit Category',
          style: CategoryFonts.display(16.sp, w: FontWeight.w800),
        ),
        // FIX: Replaced fixed SizedBox with flexible Container
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxWidth: 320.w),
          child: _DialogField(
            label: 'Category Name',
            ctrl: nameCtrl,
            icon: cat.icon,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: CategoryFonts.sans(12.sp, color: textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CategoryColors.blue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                _editCategory(cat, nameCtrl.text);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Save Changes',
              style: CategoryFonts.sans(
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

  void _showDeleteConfirm(ItemCategory cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Delete Category',
          style: CategoryFonts.display(16.sp, w: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${cat.name}"?',
              style: CategoryFonts.sans(13.sp, color: textClr),
            ),
            SizedBox(height: 8.h),
            Text(
              'This category contains ${cat.itemCount} items.',
              style: CategoryFonts.sans(11.sp, color: textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: CategoryFonts.sans(12.sp, color: textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CategoryColors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () {
              _deleteCategory(cat);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: CategoryFonts.sans(
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

  void _showCategoryOptions(ItemCategory cat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.name, style: CategoryFonts.display(18.sp)),
                      Text(
                        '${cat.itemCount} items',
                        style: CategoryFonts.sans(11.sp, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(cat);
              },
              leading: Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: CategoryColors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: CategoryColors.blue,
                  size: 18.sp,
                ),
              ),
              title: Text(
                'Edit Category',
                style: CategoryFonts.sans(13.sp, w: FontWeight.w600),
              ),
              subtitle: Text(
                'Change category name',
                style: CategoryFonts.sans(11.sp, color: textMuted),
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(cat);
              },
              leading: Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: CategoryColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.delete_rounded,
                  color: CategoryColors.red,
                  size: 18.sp,
                ),
              ),
              title: Text(
                'Delete Category',
                style: CategoryFonts.sans(13.sp, w: FontWeight.w600),
              ),
              subtitle: Text(
                'Permanently remove',
                style: CategoryFonts.sans(11.sp, color: textMuted),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: CategoryColors.purple),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    _TopBar(
                      searchCtrl: _searchCtrl,
                      onAdd: _showAddCategoryDialog,
                    ),
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
                              totalCategories: _totalCategories,
                              totalItems: _totalItems,
                              totalValue: _totalValue,
                              avgItemsPerCategory: _avgItemsPerCategory,
                              constraints: constraints,
                            ),
                            SizedBox(height: 24.h),
                            _CategoriesGrid(
                              categories: _cachedFiltered,
                              onTap: _showCategoryOptions,
                              onAdd: _showAddCategoryDialog,
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
    // Determine if we have space to show the titles
    final showTitle = MediaQuery.of(context).size.width > 600;

    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: CategoryColors.surface,
        border: Border(bottom: BorderSide(color: CategoryColors.border)),
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
              color: CategoryColors.purple,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.category_rounded,
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
                  'CATEGORIES',
                  style: CategoryFonts.sans(
                    8.sp,
                    w: FontWeight.w700,
                    color: CategoryColors.purple,
                  ),
                ),
                Text(
                  'Product Groups',
                  style: CategoryFonts.display(16.sp, w: FontWeight.w700),
                ),
              ],
            ),
          ],
          const Spacer(),
          // FIX: Wrap in Flexible with BoxConstraints
          Flexible(
            flex: 2,
            child: Container(
              constraints: BoxConstraints(maxWidth: 240.w),
              height: 40.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: CategoryColors.surface2,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: CategoryColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18.sp,
                    color: CategoryColors.textSecondary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      style: CategoryFonts.sans(12.sp),
                      decoration: InputDecoration(
                        hintText: 'Search categories...',
                        hintStyle: CategoryFonts.sans(
                          11.sp,
                          color: CategoryColors.textMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      cursorColor: CategoryColors.purple,
                    ),
                  ),
                  if (searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => searchCtrl.clear(),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16.sp,
                        color: CategoryColors.textSecondary,
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
                color: CategoryColors.purple,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: CategoryColors.purple.withOpacity(0.3),
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
                      'New Category',
                      style: CategoryFonts.sans(
                        12.sp,
                        w: FontWeight.w600,
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
            backgroundColor: CategoryColors.purpleLight,
            child: Text(
              'S',
              style: TextStyle(
                color: CategoryColors.purple,
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
            color: CategoryColors.purpleLight,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5.w,
                height: 5.w,
                decoration: const BoxDecoration(
                  color: CategoryColors.purple,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'INVENTORY ORGANIZATION',
                style: CategoryFonts.sans(
                  8.sp,
                  w: FontWeight.w700,
                  color: CategoryColors.purple,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text('Product Categories', style: CategoryFonts.display(36.sp)),
        SizedBox(height: 6.h),
        Text(
          'Organize your inventory into logical groups for better management.',
          style: CategoryFonts.sans(12.sp, color: CategoryColors.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SUMMARY CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final int totalCategories;
  final int totalItems;
  final double totalValue;
  final double avgItemsPerCategory;
  final BoxConstraints constraints;

  const _SummaryCards({
    required this.totalCategories,
    required this.totalItems,
    required this.totalValue,
    required this.avgItemsPerCategory,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SD(
        'Total Categories',
        '$totalCategories',
        Icons.category_rounded,
        CategoryColors.purple,
        CategoryColors.purpleLight,
        'Active groups',
      ),
      _SD(
        'Total Items',
        '$totalItems',
        Icons.inventory_2_rounded,
        CategoryColors.blue,
        CategoryColors.blueLight,
        'Across all categories',
      ),
      _SD(
        'Total Value',
        '\$${totalValue.toStringAsFixed(2)}',
        Icons.account_balance_wallet_outlined,
        CategoryColors.green,
        CategoryColors.greenLight,
        'Inventory worth',
      ),
      _SD(
        'Avg per Category',
        avgItemsPerCategory.toStringAsFixed(1),
        Icons.bar_chart_rounded,
        CategoryColors.orange,
        CategoryColors.orangeLight,
        'Items per group',
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
        color: CategoryColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: CategoryColors.border),
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
                  style: CategoryFonts.mono(9.sp, color: data.accent),
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
              style: CategoryFonts.display(22.sp, w: FontWeight.w800),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            data.label,
            style: CategoryFonts.sans(
              11.sp,
              color: CategoryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CATEGORIES GRID (FIXED FOR RESPONSIVENESS)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoriesGrid extends StatelessWidget {
  final List<ItemCategory> categories;
  final Function(ItemCategory) onTap;
  final VoidCallback onAdd;
  final BoxConstraints constraints;

  const _CategoriesGrid({
    required this.categories,
    required this.onTap,
    required this.onAdd,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: Dynamic crossAxisCount and childAspectRatio
    int crossAxisCount = 2;
    double childAspectRatio = 0.85;

    if (constraints.maxWidth >= 1200) {
      crossAxisCount = 5;
      childAspectRatio = 1.0;
    } else if (constraints.maxWidth >= 900) {
      crossAxisCount = 4;
      childAspectRatio = 0.95;
    } else if (constraints.maxWidth >= 600) {
      crossAxisCount = 3;
      childAspectRatio = 0.9;
    } else if (constraints.maxWidth < 400) {
      crossAxisCount = 2;
      childAspectRatio = 0.75; // More vertical space for narrow phones
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: categories.length + 1,
      itemBuilder: (context, index) {
        if (index == categories.length) return _AddCategoryCard(onTap: onAdd);
        return _CategoryCard(
          category: categories[index],
          onTap: () => onTap(categories[index]),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ItemCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: CategoryColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: CategoryColors.border),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 24.sp,
                  ),
                ),
                Icon(
                  Icons.more_vert_rounded,
                  size: 18.sp,
                  color: CategoryColors.textSecondary,
                ),
              ],
            ),
            const Spacer(),
            Text(
              category.name,
              style: CategoryFonts.sans(16.sp, w: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            Text(
              '${category.itemCount} items',
              style: CategoryFonts.sans(
                11.sp,
                color: CategoryColors.textSecondary,
              ),
            ),
            SizedBox(height: 12.h),
            Divider(color: CategoryColors.surface2, height: 1),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock Value',
                  style: CategoryFonts.sans(
                    10.sp,
                    color: CategoryColors.textMuted,
                  ),
                ),
                // FIX: Expanded to prevent total value from causing a RenderFlex error
                Expanded(
                  child: Text(
                    '\$${category.totalValue.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: CategoryFonts.mono(
                      11.sp,
                      w: FontWeight.w700,
                      color: CategoryColors.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCategoryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CategoryColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: CategoryColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: CategoryColors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                Icons.add_rounded,
                color: CategoryColors.purple,
                size: 28.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'New Category',
              style: CategoryFonts.sans(
                14.sp,
                w: FontWeight.w600,
                color: CategoryColors.purple,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Create a group',
              style: CategoryFonts.sans(
                11.sp,
                color: CategoryColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DIALOG FIELD
// ─────────────────────────────────────────────────────────────────────────────

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final String? hint;

  const _DialogField({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: CategoryFonts.sans(
            9.sp,
            w: FontWeight.w600,
            color: CategoryColors.textDim,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: CategoryColors.surface2,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: CategoryColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16.sp, color: CategoryColors.textSecondary),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: CategoryFonts.sans(12.sp),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: CategoryFonts.sans(
                      11.sp,
                      color: CategoryColors.textMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  cursorColor: CategoryColors.purple,
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
