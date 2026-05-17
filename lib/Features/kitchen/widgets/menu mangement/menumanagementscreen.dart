// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui'; // Added for PointerDeviceKind (mouse dragging)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── MODELS ─────────────────────────────────────────────────────────────

class MenuCategory {
  final int id;
  final String name;

  MenuCategory({required this.id, required this.name});

  factory MenuCategory.fromJson(Map<String, dynamic> json) =>
      MenuCategory(id: json['id'], name: json['name']);
}

class MenuItemModel {
  final int id;
  final String name;
  final int categoryId;
  final String categoryName;
  final double price;
  final bool isAvailable;
  final bool requiresPreparation;
  final int? prepTimeMinutes;
  final String? imageUrl;

  MenuItemModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.requiresPreparation,
    this.prepTimeMinutes,
    this.imageUrl,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      categoryName: json['categories'] != null
          ? json['categories']['name']
          : 'Unknown',
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      isAvailable: json['is_available'] as bool? ?? true,
      requiresPreparation: json['requires_preparation'] as bool? ?? false,
      prepTimeMinutes: json['preparation_time_minutes'] as int?,
      imageUrl: json['image_url'] as String?,
    );
  }

  MenuItemModel copyWith({bool? isAvailable}) {
    return MenuItemModel(
      id: id,
      categoryId: categoryId,
      categoryName: categoryName,
      name: name,
      price: price,
      isAvailable: isAvailable ?? this.isAvailable,
      requiresPreparation: requiresPreparation,
      prepTimeMinutes: prepTimeMinutes,
      imageUrl: imageUrl,
    );
  }
}

// ─── MENU MANAGEMENT SCREEN ─────────────────────────────────────────────

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<MenuItemModel> _menuItems = [];
  List<MenuItemModel> _filteredItems = [];
  List<MenuCategory> _categories = [];

  // NEW: State variable to track the currently selected category filter
  int? _selectedFilterCatId;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // UPDATED: Now filters by BOTH search text and selected category
  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _menuItems.where((item) {
        final matchesSearch =
            query.isEmpty ||
            item.name.toLowerCase().contains(query) ||
            item.categoryName.toLowerCase().contains(query);
        final matchesCategory =
            _selectedFilterCatId == null ||
            item.categoryId == _selectedFilterCatId;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final catsRes = await _supabase
          .from('categories')
          .select('id, name')
          .eq('is_active', true)
          .order('name');

      final itemsRes = await _supabase
          .from('menu_items')
          .select(
            'id, name, price, is_available, requires_preparation, preparation_time_minutes, image_url, category_id, categories(name)',
          )
          .order('name');

      if (mounted) {
        _categories = (catsRes as List)
            .map((c) => MenuCategory.fromJson(c))
            .toList();
        _menuItems = (itemsRes as List)
            .map((i) => MenuItemModel.fromJson(i))
            .toList();

        _filterItems();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching menu data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(MenuItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Confirm Delete'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${item.name}"?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('menu_items').delete().eq('id', item.id);
      _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (mounted) {
        if (errorStr.contains('foreign key') || errorStr.contains('violates')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot delete this product because it exists in past order receipts. Please turn off "Availability" instead.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleAvailability(int id, bool currentStatus) async {
    setState(() {
      final index = _menuItems.indexWhere((i) => i.id == id);
      if (index != -1) {
        _menuItems[index] = _menuItems[index].copyWith(
          isAvailable: !currentStatus,
        );
        _filterItems();
      }
    });

    try {
      await _supabase
          .from('menu_items')
          .update({'is_available': !currentStatus})
          .eq('id', id);
    } catch (e) {
      if (mounted) {
        setState(() {
          final index = _menuItems.indexWhere((i) => i.id == id);
          if (index != -1) {
            _menuItems[index] = _menuItems[index].copyWith(
              isAvailable: currentStatus,
            );
            _filterItems();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddEditDialog({MenuItemModel? existingItem}) {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add an Active Category first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => _AddEditItemDialog(
        existingItem: existingItem,
        categories: _categories,
        supabase: _supabase,
        onSuccess: _fetchData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── RESPONSIVE HEADER ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                // Title Area
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Kitchen Menu Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add, edit, and organize your kitchen & grab-and-go products.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Search & Add Button Area
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      width:
                          260, // Fixed width for search ensures it stays neat
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Add Product',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20, // Increased touch area
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _showAddEditDialog(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── CATEGORY FILTER BAR ───
          _buildCategoryFilterBar(),

          // ─── DATA TABLE AREA ───
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _headerText('PRODUCT'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _headerText('CATEGORY'),
                                ),
                                Expanded(flex: 1, child: _headerText('PRICE')),
                                Expanded(flex: 2, child: _headerText('TYPE')),
                                Expanded(
                                  flex: 1,
                                  child: _headerText(
                                    'STATUS',
                                    align: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 100), // Actions space
                              ],
                            ),
                          ),
                          // Table Rows
                          Expanded(
                            child: _filteredItems.isEmpty
                                ? Center(
                                    child: Text(
                                      'No products found.',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _filteredItems.length,
                                    separatorBuilder: (context, index) =>
                                        Divider(
                                          height: 1,
                                          color: Colors.grey.shade100,
                                        ),
                                    itemBuilder: (context, index) {
                                      final item = _filteredItems[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24.0,
                                          vertical: 16.0,
                                        ),
                                        child: Row(
                                          children: [
                                            // Product Name & Image/Icon
                                            Expanded(
                                              flex: 3,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFF3F4F6,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child:
                                                          item.imageUrl !=
                                                                  null &&
                                                              item
                                                                  .imageUrl!
                                                                  .isNotEmpty
                                                          ? Image.network(
                                                              item.imageUrl!,
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (
                                                                    context,
                                                                    error,
                                                                    stackTrace,
                                                                  ) =>
                                                                      _fallbackIcon(
                                                                        item,
                                                                      ),
                                                            )
                                                          : _fallbackIcon(item),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      item.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFF111827,
                                                        ),
                                                        fontSize: 15,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Category
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                item.categoryName,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            // Price
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                '\$${item.price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF111827),
                                                ),
                                              ),
                                            ),
                                            // Type Chip
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        item.requiresPreparation
                                                        ? const Color(
                                                            0xFFFFF7ED,
                                                          )
                                                        : const Color(
                                                            0xFFEFF6FF,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          item.requiresPreparation
                                                          ? const Color(
                                                              0xFFFED7AA,
                                                            )
                                                          : const Color(
                                                              0xFFBFDBFE,
                                                            ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    item.requiresPreparation
                                                        ? 'Kitchen (Prep)'
                                                        : 'Retail (Grab)',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          item.requiresPreparation
                                                          ? const Color(
                                                              0xFFC2410C,
                                                            )
                                                          : const Color(
                                                              0xFF1D4ED8,
                                                            ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Status Toggle
                                            Expanded(
                                              flex: 1,
                                              child: Switch(
                                                value: item.isAvailable,
                                                onChanged: (v) =>
                                                    _toggleAvailability(
                                                      item.id,
                                                      item.isAvailable,
                                                    ),
                                                activeColor: const Color(
                                                  0xFF10B981,
                                                ),
                                                activeTrackColor: const Color(
                                                  0xFFD1FAE5,
                                                ),
                                              ),
                                            ),
                                            // Actions
                                            SizedBox(
                                              width: 100,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit_outlined,
                                                      color: Color(0xFF3B82F6),
                                                      size: 20,
                                                    ),
                                                    tooltip: 'Edit',
                                                    onPressed: () =>
                                                        _showAddEditDialog(
                                                          existingItem: item,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Color(0xFFEF4444),
                                                      size: 20,
                                                    ),
                                                    tooltip: 'Delete',
                                                    onPressed: () =>
                                                        _deleteItem(item),
                                                  ),
                                                ],
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
                  ),
          ),
        ],
      ),
    );
  }

  // ─── NEW: CATEGORY FILTER UI ───
  Widget _buildCategoryFilterBar() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: SizedBox(
        height: 38,
        // Using ScrollConfiguration allows mouse dragging on web/desktop
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              _buildCategoryChip('All Categories', null),
              ..._categories.map((c) => _buildCategoryChip(c.name, c.id)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, int? categoryId) {
    final isSelected = _selectedFilterCatId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilterCatId = categoryId;
            _filterItems();
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerText(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _fallbackIcon(MenuItemModel item) {
    return Icon(
      item.requiresPreparation ? Icons.restaurant : Icons.shopping_bag_outlined,
      size: 20,
      color: Colors.grey.shade600,
    );
  }
}

// ─── ADD / EDIT DIALOG ───────────────────────────

class _AddEditItemDialog extends StatefulWidget {
  final MenuItemModel? existingItem;
  final List<MenuCategory> categories;
  final SupabaseClient supabase;
  final VoidCallback onSuccess;

  const _AddEditItemDialog({
    this.existingItem,
    required this.categories,
    required this.supabase,
    required this.onSuccess,
  });

  @override
  State<_AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<_AddEditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _prepTimeCtrl;
  late TextEditingController _imageUrlCtrl;

  late int _selectedCatId;
  late bool _requiresPrep;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingItem?.name ?? '');
    _priceCtrl = TextEditingController(
      text: widget.existingItem?.price.toString() ?? '',
    );
    _prepTimeCtrl = TextEditingController(
      text: widget.existingItem?.prepTimeMinutes?.toString() ?? '',
    );
    _imageUrlCtrl = TextEditingController(
      text: widget.existingItem?.imageUrl ?? '',
    );

    _requiresPrep = widget.existingItem?.requiresPreparation ?? true;

    int? initialCatId = widget.existingItem?.categoryId;
    if (initialCatId != null &&
        !widget.categories.any((c) => c.id == initialCatId)) {
      initialCatId = widget.categories.first.id;
    }
    _selectedCatId = initialCatId ?? widget.categories.first.id;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _prepTimeCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final itemData = {
      'name': _nameCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text) ?? 0.0,
      'category_id': _selectedCatId,
      'image_url': _imageUrlCtrl.text.trim().isEmpty
          ? null
          : _imageUrlCtrl.text.trim(),
      'requires_preparation': _requiresPrep,
      'preparation_time_minutes': _requiresPrep
          ? (int.tryParse(_prepTimeCtrl.text) ?? 0)
          : null,
    };

    try {
      if (widget.existingItem == null) {
        await widget.supabase.from('menu_items').insert(itemData);
      } else {
        await widget.supabase
            .from('menu_items')
            .update(itemData)
            .eq('id', widget.existingItem!.id);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product saved successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.existingItem == null ? 'Add New Product' : 'Edit Product',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
        ),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _nameCtrl,
                        label: 'Product Name',
                        icon: Icons.fastfood_outlined,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildTextField(
                        controller: _priceCtrl,
                        label: 'Price (\$)',
                        icon: Icons.attach_money,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _imageUrlCtrl,
                  label: 'Image URL (Optional)',
                  icon: Icons.image_outlined,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(
                      Icons.category_outlined,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                  ),
                  value: _selectedCatId,
                  items: widget.categories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCatId = v!),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _requiresPrep
                        ? const Color(0xFFFFF7ED)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _requiresPrep
                          ? const Color(0xFFFED7AA)
                          : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Requires Kitchen Prep',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          _requiresPrep
                              ? 'Item will be sent to the Kitchen Display.'
                              : 'Grab & Go. Cashier hands directly to customer.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        value: _requiresPrep,
                        activeColor: const Color(0xFFF59E0B),
                        inactiveThumbColor: const Color(0xFF3B82F6),
                        inactiveTrackColor: const Color(0xFFDBEAFE),
                        onChanged: (v) => setState(() => _requiresPrep = v),
                      ),
                      if (_requiresPrep) ...[
                        const Divider(height: 24),
                        _buildTextField(
                          controller: _prepTimeCtrl,
                          label: 'Estimated Prep Time (Minutes)',
                          icon: Icons.timer_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!_isSaving)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _isSaving ? null : _saveData,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Save Product',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
