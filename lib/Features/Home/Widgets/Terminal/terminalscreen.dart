// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Menu Item Model
class MenuItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final Color color;
  final IconData icon;
  final bool popular;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.color,
    required this.icon,
    this.popular = false,
  });
}

// Cart Item Model
class CartItem {
  final MenuItem item;
  int qty;

  CartItem({required this.item, this.qty = 1});
}

// Table Model
class Table {
  final int id;
  final String name;
  final String status;

  const Table({required this.id, required this.name, required this.status});
}

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  // Menu Items Data
  final List<MenuItem> menuItems = const [
    MenuItem(
      id: 'a1',
      name: 'Crispy Calamari',
      price: 14.99,
      category: 'Appetizers',
      color: Color(0xFFFF9800),
      icon: Icons.restaurant,
      popular: true,
    ),
    MenuItem(
      id: 'a2',
      name: 'Bruschetta',
      price: 10.99,
      category: 'Appetizers',
      color: Color(0xFFFF9800),
      icon: Icons.bakery_dining,
      popular: false,
    ),
    MenuItem(
      id: 'a3',
      name: 'Soup of the Day',
      price: 8.99,
      category: 'Appetizers',
      color: Color(0xFFFF9800),
      icon: Icons.soup_kitchen,
      popular: false,
    ),
    MenuItem(
      id: 'a4',
      name: 'Caesar Salad',
      price: 12.99,
      category: 'Appetizers',
      color: Color(0xFFFF9800),
      icon: Icons.eco,
      popular: false,
    ),
    MenuItem(
      id: 'a5',
      name: 'Spring Rolls',
      price: 9.99,
      category: 'Appetizers',
      color: Color(0xFFFF9800),
      icon: Icons.ramen_dining,
      popular: false,
    ),
    MenuItem(
      id: 'm1',
      name: 'Grilled Salmon',
      price: 28.99,
      category: 'Main Course',
      color: Color(0xFFE53935),
      icon: Icons.set_meal,
      popular: true,
    ),
    MenuItem(
      id: 'm2',
      name: 'Ribeye Steak',
      price: 42.99,
      category: 'Main Course',
      color: Color(0xFFE53935),
      icon: Icons.restaurant_menu,
      popular: true,
    ),
    MenuItem(
      id: 'm3',
      name: 'Lobster Tail',
      price: 54.99,
      category: 'Main Course',
      color: Color(0xFFE53935),
      icon: Icons.egg_alt,
      popular: false,
    ),
    MenuItem(
      id: 'm4',
      name: 'Chicken Parmesan',
      price: 24.99,
      category: 'Main Course',
      color: Color(0xFFE53935),
      icon: Icons.fastfood,
      popular: false,
    ),
    MenuItem(
      id: 'm5',
      name: 'Lamb Chops',
      price: 38.99,
      category: 'Main Course',
      color: Color(0xFFE53935),
      icon: Icons.lunch_dining,
      popular: false,
    ),
    MenuItem(
      id: 'm6',
      name: 'Vegetable Risotto',
      price: 22.99,
      category: 'Main Course',
      color: Color(0xFFE53935),
      icon: Icons.rice_bowl,
      popular: false,
    ),
    MenuItem(
      id: 'm7',
      name: 'Duck Confit',
      price: 36.99,
      category: 'Main Course',
      color: Color(0xFFE53935),
      icon: Icons.dinner_dining,
      popular: false,
    ),
    MenuItem(
      id: 'm8',
      name: 'Sea Bass',
      price: 32.99,
      category: 'Main Course',
      color: Color(0xFFE53935),
      icon: Icons.set_meal,
      popular: false,
    ),
    MenuItem(
      id: 'd1',
      name: 'Tiramisu',
      price: 10.99,
      category: 'Desserts',
      color: Color(0xFF9C27B0),
      icon: Icons.cake,
      popular: true,
    ),
    MenuItem(
      id: 'd2',
      name: 'Creme Brulee',
      price: 11.99,
      category: 'Desserts',
      color: Color(0xFF9C27B0),
      icon: Icons.icecream,
      popular: false,
    ),
    MenuItem(
      id: 'd3',
      name: 'Chocolate Lava Cake',
      price: 13.99,
      category: 'Desserts',
      color: Color(0xFF9C27B0),
      icon: Icons.cookie,
      popular: false,
    ),
    MenuItem(
      id: 'd4',
      name: 'NY Cheesecake',
      price: 10.99,
      category: 'Desserts',
      color: Color(0xFF9C27B0),
      icon: Icons.cake,
      popular: false,
    ),
    MenuItem(
      id: 'd5',
      name: 'Tarte Tatin',
      price: 12.99,
      category: 'Desserts',
      color: Color(0xFF9C27B0),
      icon: Icons.pie_chart,
      popular: false,
    ),
    MenuItem(
      id: 'r1',
      name: 'House Red Wine',
      price: 12.99,
      category: 'Drinks',
      color: Color(0xFF2196F3),
      icon: Icons.wine_bar,
      popular: true,
    ),
    MenuItem(
      id: 'r2',
      name: 'House White Wine',
      price: 12.99,
      category: 'Drinks',
      color: Color(0xFF2196F3),
      icon: Icons.wine_bar,
      popular: false,
    ),
    MenuItem(
      id: 'r3',
      name: 'Craft Cocktail',
      price: 15.99,
      category: 'Drinks',
      color: Color(0xFF2196F3),
      icon: Icons.local_bar,
      popular: false,
    ),
    MenuItem(
      id: 'r4',
      name: 'Espresso',
      price: 4.99,
      category: 'Drinks',
      color: Color(0xFF2196F3),
      icon: Icons.coffee,
      popular: false,
    ),
    MenuItem(
      id: 'r5',
      name: 'Fresh Juice',
      price: 6.99,
      category: 'Drinks',
      color: Color(0xFF2196F3),
      icon: Icons.local_drink,
      popular: false,
    ),
    MenuItem(
      id: 'r6',
      name: 'Sparkling Water',
      price: 5.99,
      category: 'Drinks',
      color: Color(0xFF2196F3),
      icon: Icons.water_drop,
      popular: false,
    ),
    MenuItem(
      id: 's1',
      name: 'Truffle Fries',
      price: 9.99,
      category: 'Sides',
      color: Color(0xFF4CAF50),
      icon: Icons.lunch_dining,
      popular: true,
    ),
    MenuItem(
      id: 's2',
      name: 'Garlic Bread',
      price: 6.99,
      category: 'Sides',
      color: Color(0xFF4CAF50),
      icon: Icons.bakery_dining,
      popular: false,
    ),
    MenuItem(
      id: 's3',
      name: 'Mashed Potatoes',
      price: 7.99,
      category: 'Sides',
      color: Color(0xFF4CAF50),
      icon: Icons.rice_bowl,
      popular: false,
    ),
    MenuItem(
      id: 's4',
      name: 'Grilled Asparagus',
      price: 8.99,
      category: 'Sides',
      color: Color(0xFF4CAF50),
      icon: Icons.eco,
      popular: false,
    ),
    MenuItem(
      id: 's5',
      name: 'Onion Rings',
      price: 8.99,
      category: 'Sides',
      color: Color(0xFF4CAF50),
      icon: Icons.circle,
      popular: false,
    ),
    MenuItem(
      id: 'sp1',
      name: 'Chef Special Tasting Menu',
      price: 89.99,
      category: 'Specials',
      color: Color(0xFFC7942D),
      icon: Icons.star,
      popular: true,
    ),
    MenuItem(
      id: 'sp2',
      name: 'Wine Pairing Experience',
      price: 45.99,
      category: 'Specials',
      color: Color(0xFFC7942D),
      icon: Icons.wine_bar,
      popular: false,
    ),
    MenuItem(
      id: 'sp3',
      name: 'Anniversary Package',
      price: 129.99,
      category: 'Specials',
      color: Color(0xFFC7942D),
      icon: Icons.favorite,
      popular: false,
    ),
  ];

  final List<String> categories = [
    'All',
    'Appetizers',
    'Main Course',
    'Desserts',
    'Drinks',
    'Sides',
    'Specials',
  ];

  final List<Table> tables = const [
    Table(id: 1, name: 'Table 1', status: 'available'),
    Table(id: 2, name: 'Table 2', status: 'occupied'),
    Table(id: 3, name: 'Table 3', status: 'available'),
    Table(id: 4, name: 'Table 4', status: 'available'),
    Table(id: 5, name: 'Table 5', status: 'occupied'),
    Table(id: 6, name: 'Table 6', status: 'available'),
    Table(id: 7, name: 'VIP 1', status: 'available'),
    Table(id: 8, name: 'VIP 2', status: 'occupied'),
  ];

  List<CartItem> cart = [];
  String selectedCategory = 'All';
  String searchQuery = '';
  double discount = 0;
  String orderType = 'dineIn';
  Table? selectedTable;
  String selectedPaymentMethod = 'cash';
  String paymentStatus = 'paid';
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  double get subtotal =>
      cart.fold(0, (sum, item) => sum + (item.item.price * item.qty));
  double get discountAmount => subtotal * discount;
  double get total => subtotal - discountAmount;
  int get totalItems => cart.fold(0, (sum, item) => sum + item.qty);

  @override
  void dispose() {
    customerNameController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void addToCart(MenuItem item) {
    setState(() {
      final existingIndex = cart.indexWhere((c) => c.item.id == item.id);
      if (existingIndex >= 0) {
        cart[existingIndex].qty++;
      } else {
        cart.add(CartItem(item: item));
      }
    });
  }

  void updateCartItemQty(int index, int delta) {
    setState(() {
      cart[index].qty += delta;
      if (cart[index].qty <= 0) {
        cart.removeAt(index);
      }
    });
  }

  void removeFromCart(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  void clearCart() {
    setState(() {
      cart.clear();
      discount = 0;
      customerNameController.clear();
    });
  }

  void setDiscount(double value) {
    setState(() {
      discount = value;
    });
  }

  List<MenuItem> get filteredItems {
    return menuItems.where((item) {
      bool matchesCategory =
          selectedCategory == 'All' || item.category == selectedCategory;
      bool matchesSearch =
          searchQuery.isEmpty ||
          item.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  int getCartQty(String itemId) {
    final cartItem = cart.where((c) => c.item.id == itemId).firstOrNull;
    return cartItem?.qty ?? 0;
  }

  void showPaymentModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentModal(
        total: total,
        orderInfo: _getOrderInfo(),
        itemCount: totalItems,
        onSave: (status) {
          setState(() {
            cart.clear();
            discount = 0;
            customerNameController.clear();
          });
          Navigator.pop(context);
          _showToast(status);
        },
      ),
    );
  }

  String _getOrderInfo() {
    String info = '';
    if (orderType == 'dineIn' && selectedTable != null) {
      info = selectedTable!.name;
    } else if (orderType == 'takeout') {
      info = customerNameController.text.isNotEmpty
          ? customerNameController.text
          : 'Takeout';
    } else {
      info = customerNameController.text.isNotEmpty
          ? customerNameController.text
          : 'Delivery';
    }
    return info;
  }

  void _showToast(String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              status == 'paid' ? Icons.check_circle : Icons.schedule,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              status == 'paid'
                  ? 'Payment received! Order saved as PAID'
                  : 'Order saved as PENDING',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: status == 'paid'
            ? const Color(0xFF2E7D4A)
            : const Color(0xFFD97A1F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                _buildCategoriesBar(),
                Expanded(child: _buildProductsGrid()),
              ],
            ),
          ),
          // Order Panel
          _buildOrderPanel(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E5F0)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC7942D), Color(0xFFD4AA4A)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 24),
          _buildNavItem(Icons.add_circle, true),
          _buildNavItem(Icons.table_restaurant, false),
          _buildNavItem(Icons.kitchen, false),
          _buildNavItem(Icons.receipt_long, false),
          const Spacer(),
          _buildNavItem(Icons.settings, false),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF8F9FC) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: isActive ? const Color(0xFFC7942D) : const Color(0xFF8A90AD),
        size: 22,
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: const Color(0xFFE2E5F0))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'FINE DINING POS',
                style: GoogleFonts.syne(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFC7942D),
                  letterSpacing: 2,
                ),
              ),
              Text(
                'New Order',
                style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Search Bar
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E5F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF8A90AD), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Search menu items...',
                        hintStyle: TextStyle(color: Color(0xFF8A90AD)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFFC7942D),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Order Type Selector
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E5F0)),
            ),
            child: Row(
              children: [
                _buildOrderTypeBtn('dineIn', 'Dine In', Icons.table_restaurant),
                _buildOrderTypeBtn('takeout', 'Takeout', Icons.takeout_dining),
                _buildOrderTypeBtn(
                  'delivery',
                  'Delivery',
                  Icons.delivery_dining,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Customer Name Input
          Container(
            height: 44,
            width: 180,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E5F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF8A90AD), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: customerNameController,
                    decoration: const InputDecoration(
                      hintText: 'Customer name...',
                      hintStyle: TextStyle(
                        color: Color(0xFF8A90AD),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Table Selector
          if (orderType == 'dineIn') _buildTableSelector(),
        ],
      ),
    );
  }

  Widget _buildOrderTypeBtn(
    String type,
    String label,
    IconData icon, {
    bool isLast = false,
  }) {
    bool isActive = orderType == type;
    return GestureDetector(
      onTap: () => setState(() {
        orderType = type;
        if (type != 'dineIn') selectedTable = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFC7942D) : Colors.transparent,
          border: isLast
              ? null
              : Border(right: BorderSide(color: const Color(0xFFE2E5F0))),
          borderRadius: isLast
              ? const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : const Color(0xFF8A90AD),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF8A90AD),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableSelector() {
    return GestureDetector(
      onTap: () => _showTableDropdown(),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selectedTable != null
                ? const Color(0xFFC7942D)
                : const Color(0xFFE2E5F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.table_restaurant,
              color: const Color(0xFF8A90AD),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              selectedTable?.name ?? 'Select Table',
              style: const TextStyle(fontSize: 13),
            ),
            if (selectedTable != null) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selectedTable!.status == 'available'
                      ? const Color(0xFF2E7D4A)
                      : const Color(0xFFC73B3B),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTableDropdown() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: tables.map((table) {
              return ListTile(
                onTap: () {
                  setState(() => selectedTable = table);
                  Navigator.pop(context);
                },
                title: Text(table.name),
                trailing: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: table.status == 'available'
                        ? const Color(0xFF2E7D4A)
                        : const Color(0xFFC73B3B),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(color: Color(0xFFF8F9FC)),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = categories[index];
          bool isActive = selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFC7942D) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFFC7942D)
                      : const Color(0xFFE2E5F0),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFFC7942D).withOpacity(0.25),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF8A90AD),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid() {
    final items = filteredItems;
    return Container(
      color: const Color(0xFFF8F9FC),
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildProductCard(items[index]),
      ),
    );
  }

  Widget _buildProductCard(MenuItem item) {
    final qty = getCartQty(item.id);
    final inCart = qty > 0;

    return GestureDetector(
      onTap: () => addToCart(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: inCart ? item.color : const Color(0xFFE2E5F0),
            width: inCart ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [item.color.withOpacity(0.1), Colors.transparent],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(child: Icon(item.icon, size: 48, color: item.color)),
                    if (item.popular)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC7942D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Popular',
                                style: GoogleFonts.aBeeZee(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (inCart)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: item.color.withOpacity(0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$qty',
                              style: GoogleFonts.aBeeZee(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info Area
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category,
                      style: GoogleFonts.aBeeZee(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: item.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFC7942D),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFC7942D), Color(0xFFD4AA4A)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC7942D).withOpacity(0.25),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderPanel() {
    return Container(
      width: 400,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 32),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE2E5F0)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFFC7942D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Order',
                        style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.table_restaurant,
                            size: 12,
                            color: const Color(0xFFC7942D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getOrderInfo(),
                            style: GoogleFonts.aBeeZee(
                              fontSize: 11,
                              color: const Color(0xFFC7942D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (cart.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalItems items',
                      style: GoogleFonts.aBeeZee(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC7942D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: clearCart,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFC73B3B).withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFC73B3B),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Cart Items
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2F8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_basket_outlined,
                            size: 32,
                            color: Color(0xFFB0B5CA),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Your order is empty',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap items to add them to your order',
                          style: GoogleFonts.aBeeZee(
                            fontSize: 12,
                            color: const Color(0xFFB0B5CA),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return _buildCartItem(item, index);
                    },
                  ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: const Color(0xFFE2E5F0))),
            ),
            child: Column(
              children: [
                // Discount
                Row(
                  children: [
                    Text(
                      'DISCOUNT',
                      style: GoogleFonts.aBeeZee(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: const Color(0xFF8A90AD),
                      ),
                    ),
                    const Spacer(),
                    _buildDiscountChip('None', 0),
                    _buildDiscountChip('5%', 0.05),
                    _buildDiscountChip('10%', 0.10),
                    _buildDiscountChip('15%', 0.15),
                  ],
                ),
                const SizedBox(height: 16),
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: TextStyle(color: const Color(0xFF8A90AD)),
                    ),
                    Text(
                      '\$${subtotal.toStringAsFixed(2)}',
                      style: GoogleFonts.aBeeZee(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discount',
                        style: TextStyle(color: const Color(0xFF2E7D4A)),
                      ),
                      Text(
                        '-\$${discountAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.aBeeZee(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D4A),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 14),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF8A90AD),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: GoogleFonts.syne(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFC7942D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Payment Methods
                Row(
                  children: [
                    _buildPaymentMethod(
                      'cash',
                      Icons.payments,
                      'Cash',
                      const Color(0xFF2E7D4A),
                    ),
                    const SizedBox(width: 10),
                    _buildPaymentMethod(
                      'card',
                      Icons.credit_card,
                      'Card',
                      const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 10),
                    _buildPaymentMethod(
                      'split',
                      Icons.call_split,
                      'Split',
                      const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Charge Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: cart.isEmpty ? null : showPaymentModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC7942D),
                      disabledBackgroundColor: const Color(0xFFF0F2F8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'CHARGE \$${total.toStringAsFixed(2)}',
                          style: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountChip(String label, double value) {
    bool isActive = discount == value;
    return GestureDetector(
      onTap: () => setDiscount(value),
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF8F9FC) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? (value == 0
                      ? const Color(0xFFE2E5F0)
                      : const Color(0xFF2E7D4A))
                : const Color(0xFFE2E5F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.aBeeZee(
            fontSize: 10,
            color: isActive && value > 0
                ? const Color(0xFF2E7D4A)
                : const Color(0xFF8A90AD),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(
    String method,
    IconData icon,
    String label,
    Color color,
  ) {
    bool isActive = selectedPaymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPaymentMethod = method),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? color : color.withOpacity(0.2),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: item.item.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.item.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '\$${item.item.price.toStringAsFixed(2)} each',
                style: GoogleFonts.aBeeZee(
                  fontSize: 11,
                  color: const Color(0xFF8A90AD),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E5F0)),
          ),
          child: Row(
            children: [
              _buildQtyBtn(Icons.remove, () => updateCartItemQty(index, -1)),
              SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    '${item.qty}',
                    style: GoogleFonts.aBeeZee(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              _buildQtyBtn(Icons.add, () => updateCartItemQty(index, 1)),
            ],
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 64,
          child: Text(
            '\$${(item.item.price * item.qty).toStringAsFixed(2)}',
            style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w800),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => removeFromCart(index),
          child: const Icon(Icons.close, size: 16, color: Color(0xFFB0B5CA)),
        ),
      ],
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 16, color: const Color(0xFF8A90AD)),
      ),
    );
  }
}

// Payment Modal
class PaymentModal extends StatefulWidget {
  final double total;
  final String orderInfo;
  final int itemCount;
  final Function(String) onSave;

  const PaymentModal({
    super.key,
    required this.total,
    required this.orderInfo,
    required this.itemCount,
    required this.onSave,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  final TextEditingController _amountController = TextEditingController();
  String _paymentStatus = 'paid';
  double _change = 0;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.total.toStringAsFixed(2);
    _amountController.addListener(_updateChange);
  }

  void _updateChange() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      _change = amount - widget.total;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant,
                size: 32,
                color: Color(0xFFC7942D),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              'Payment Details',
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.orderInfo} - ${widget.itemCount} items',
              style: GoogleFonts.aBeeZee(
                fontSize: 12,
                color: const Color(0xFF8A90AD),
              ),
            ),
            const SizedBox(height: 8),
            // Total Amount
            Text(
              '\$${widget.total.toStringAsFixed(2)}',
              style: GoogleFonts.syne(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFC7942D),
              ),
            ),
            const SizedBox(height: 24),
            // Amount Received Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount Received',
                  style: GoogleFonts.abel(
                    fontSize: 12,
                    color: const Color(0xFF8A90AD),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E5F0)),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '\$',
                          style: GoogleFonts.aBeeZee(
                            fontSize: 16,
                            color: const Color(0xFF8A90AD),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.aBeeZee(
                            fontSize: 18,
                            color: const Color(0xFF1A1D2E),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Change Display
            if (_change >= 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Change Due',
                    style: GoogleFonts.abel(
                      fontSize: 12,
                      color: const Color(0xFF8A90AD),
                    ),
                  ),
                  Text(
                    '\$${_change.toStringAsFixed(2)}',
                    style: GoogleFonts.aBeeZee(
                      fontSize: 13,
                      color: const Color(0xFF2E7D4A),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            // Status Options
            Row(
              children: [
                _buildStatusOption(
                  'paid',
                  'Paid',
                  Icons.check_circle,
                  const Color(0xFF2E7D4A),
                ),
                const SizedBox(width: 12),
                _buildStatusOption(
                  'pending',
                  'Pending',
                  Icons.schedule,
                  const Color(0xFFD97A1F),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E5F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.abel(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8A90AD),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => widget.onSave(_paymentStatus),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC7942D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Order',
                      style: GoogleFonts.abel(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    String status,
    String label,
    IconData icon,
    Color color,
  ) {
    bool isActive = _paymentStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentStatus = status),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color : const Color(0xFFE2E5F0),
              width: 2,
            ),
            color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.abel(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
