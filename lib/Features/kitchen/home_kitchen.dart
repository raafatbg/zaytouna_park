// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── MODELS ─────────────────────────────────────────────────────────────

class KdsItem {
  final int id;
  final int orderId;
  final String itemName;
  final int quantity;
  final String? instructions;
  final DateTime createdAt;
  bool isCrossedOut;

  KdsItem({
    required this.id,
    required this.orderId,
    required this.itemName,
    required this.quantity,
    this.instructions,
    required this.createdAt,
    this.isCrossedOut = false,
  });

  factory KdsItem.fromJson(Map<String, dynamic> json) {
    return KdsItem(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      itemName: json['menu_items']['name'] as String? ?? 'Unknown Item',
      quantity: json['quantity'] as int,
      instructions: json['special_instructions'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

class KdsTicket {
  final int orderId;
  final DateTime orderTime;
  final List<KdsItem> items;

  KdsTicket({
    required this.orderId,
    required this.orderTime,
    required this.items,
  });

  int get minutesElapsed => DateTime.now().difference(orderTime).inMinutes;
}

// ─── THEME & COLORS ────────────────────────────────────────────────────

class AppTheme {
  // Backgrounds
  static const Color bgPrimary = Color(0xFFFAFAFA);
  static const Color bgSecondary = Colors.white;
  static const Color bgTertiary = Color(0xFFF5F5F5);

  // Accent Colors - Vibrant & Bold
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentTeal = Color(0xFF00D9D9);
  static const Color accentPurple = Color(0xFFB833FF);
  static const Color accentPink = Color(0xFFFF006E);
  static const Color accentYellow = Color(0xFFFFD60A);
  static const Color accentGreen = Color(0xFF00D98E);

  // Status Colors
  static const Color success = Color(0xFF00AA6E);
  static const Color warning = Color(0xFFFF9C00);
  static const Color danger = Color(0xFFFF3B3B);
  static const Color info = Color(0xFF0066FF);

  // Text Colors
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color borderColor = Color(0xFFE5E5E5);

  // Typography
  static TextStyle displayBold() => GoogleFonts.plusJakartaSans(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: textDark,
    letterSpacing: -1,
  );

  static TextStyle headingXL() => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textDark,
    letterSpacing: -0.5,
  );

  static TextStyle headingLg() => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textDark,
    letterSpacing: -0.3,
  );

  static TextStyle headingMd() => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textDark,
    letterSpacing: -0.2,
  );

  static TextStyle bodyMd() => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textDark,
  );

  static TextStyle bodySm() => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textMuted,
  );

  static TextStyle labelMd() => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: textDark,
    letterSpacing: 0.5,
  );
}

// ─── KITCHEN DASHBOARD SHELL ────────────────────────────────────────────

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _ActiveOrdersView(),
    const _OrderHistoryView(),
    const _MenuReferenceView(),
  ];

  final List<({IconData icon, String label, Color color})> _navItems = [
    (
      icon: Icons.local_fire_department_rounded,
      label: 'Active',
      color: AppTheme.accentOrange,
    ),
    (icon: Icons.history_rounded, label: 'History', color: AppTheme.accentTeal),
    (
      icon: Icons.menu_book_rounded,
      label: 'Reference',
      color: AppTheme.accentPurple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(
          right: BorderSide(color: AppTheme.borderColor, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Bold Design
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor, width: 2),
              ),
            ),
            child: Column(
              children: [
                // Geometric Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.accentOrange, AppTheme.accentPink],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text('KITCHEN', style: AppTheme.headingLg()),
                Text(
                  'WORKFLOW',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentOrange,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nav Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('SECTIONS', style: AppTheme.labelMd()),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            _navItems.length,
            (i) => _buildNavItem(
              i,
              _navItems[i].icon,
              _navItems[i].label,
              _navItems[i].color,
            ),
          ),

          const Spacer(),

          // Footer
          Divider(color: AppTheme.borderColor, height: 2),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Back to POS',
                      style: AppTheme.bodyMd().copyWith(
                        color: AppTheme.textMuted,
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

  Widget _buildNavItem(int index, IconData icon, String title, Color color) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : AppTheme.borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          title,
          style: AppTheme.bodyMd().copyWith(
            color: isSelected ? color : AppTheme.textDark,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }
}

// ─── VIEW 1: ACTIVE ORDERS ─────────────────────────────────────────────

class _ActiveOrdersView extends StatefulWidget {
  const _ActiveOrdersView();
  @override
  State<_ActiveOrdersView> createState() => _ActiveOrdersViewState();
}

class _ActiveOrdersViewState extends State<_ActiveOrdersView>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<KdsTicket> _tickets = [];
  Timer? _pollingTimer;
  Timer? _uiRefreshTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _fetchPendingOrders();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchPendingOrders(isPolling: true),
    );
    _uiRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _uiRefreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingOrders({bool isPolling = false}) async {
    if (!isPolling) setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('order_items')
          .select(
            'id, order_id, quantity, special_instructions, created_at, menu_items (name)',
          )
          .eq('item_status', 'pending_kitchen')
          .order('created_at', ascending: true);

      final List<KdsItem> rawItems = (res as List)
          .map((i) => KdsItem.fromJson(i))
          .toList();
      final Map<int, List<KdsItem>> grouped = {};
      for (var item in rawItems) {
        grouped.putIfAbsent(item.orderId, () => []).add(item);
      }

      final parsedTickets = grouped.entries.map((e) {
        return KdsTicket(
          orderId: e.key,
          orderTime: e.value
              .map((i) => i.createdAt)
              .reduce((a, b) => a.isBefore(b) ? a : b),
          items: e.value,
        );
      }).toList()..sort((a, b) => a.orderTime.compareTo(b.orderTime));

      if (mounted) {
        setState(() {
          for (var newT in parsedTickets) {
            final oldT = _tickets
                .where((t) => t.orderId == newT.orderId)
                .firstOrNull;
            if (oldT != null) {
              for (var newI in newT.items) {
                final oldI = oldT.items
                    .where((i) => i.id == newI.id)
                    .firstOrNull;
                if (oldI != null) newI.isCrossedOut = oldI.isCrossedOut;
              }
            }
          }
          _tickets = parsedTickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !isPolling) setState(() => _isLoading = false);
    }
  }

  Future<void> _markEntireOrderReady(KdsTicket ticket) async {
    try {
      final itemIds = ticket.items.map((i) => i.id).toList();
      await _supabase
          .from('order_items')
          .update({'item_status': 'ready'})
          .inFilter('id', itemIds);
      _fetchPendingOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Order #${ticket.orderId} Ready!',
                  style: AppTheme.bodyMd().copyWith(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  Color _getStatusColor(int minutes) {
    if (minutes >= 20) return AppTheme.danger;
    if (minutes >= 10) return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderColor, width: 2),
            ),
          ),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔥 ACTIVE ORDERS', style: AppTheme.headingXL()),
                  const SizedBox(height: 4),
                  Text(
                    '${_tickets.length} order${_tickets.length != 1 ? 's' : ''} being prepared',
                    style: AppTheme.bodySm(),
                  ),
                ],
              ),
              const Spacer(),
              _buildLiveIndicator(),
              const SizedBox(width: 16),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentOrange.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: () => _fetchPendingOrders(),
                ),
              ),
            ],
          ),
        ),
        // Grid
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          color: AppTheme.accentOrange,
                          strokeWidth: 4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Loading...', style: AppTheme.headingMd()),
                    ],
                  ),
                )
              : _tickets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 60,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('All Orders Done!', style: AppTheme.displayBold()),
                      const SizedBox(height: 8),
                      Text('Kitchen is clear 🎉', style: AppTheme.bodySm()),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _tickets.length,
                  itemBuilder: (_, i) => _buildTicketCard(_tickets[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.accentTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentTeal, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.2,
            ).animate(_pulseController),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppTheme.accentTeal,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'LIVE',
            style: AppTheme.labelMd().copyWith(color: AppTheme.accentTeal),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(KdsTicket ticket) {
    final statusColor = _getStatusColor(ticket.minutesElapsed);
    final minutes = ticket.minutesElapsed;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Color bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${ticket.orderId}', style: AppTheme.displayBold()),
                    Text(
                      '${ticket.items.length} item${ticket.items.length != 1 ? 's' : ''}',
                      style: AppTheme.bodySm(),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: Text(
                    '${minutes}m',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppTheme.borderColor, height: 1, thickness: 2),

          // Items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ticket.items.length,
              separatorBuilder: (_, _) =>
                  Divider(color: AppTheme.borderColor, height: 16),
              itemBuilder: (_, idx) {
                final item = ticket.items[idx];
                return InkWell(
                  onTap: () =>
                      setState(() => item.isCrossedOut = !item.isCrossedOut),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: item.isCrossedOut ? 0.4 : 1.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Qty Badge
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.accentOrange,
                                AppTheme.accentPink,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${item.quantity}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName,
                                style: AppTheme.bodyMd().copyWith(
                                  fontWeight: FontWeight.w700,
                                  decoration: item.isCrossedOut
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (item.instructions != null &&
                                  item.instructions!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.danger,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    '⚠️ ${item.instructions!}',
                                    style: AppTheme.bodySm().copyWith(
                                      color: AppTheme.danger,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.success, AppTheme.accentGreen],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.success.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _markEntireOrderReady(ticket),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'MARK READY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── VIEW 2: ORDER HISTORY ─────────────────────────────────────────────

class _OrderHistoryView extends StatefulWidget {
  const _OrderHistoryView();
  @override
  State<_OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<_OrderHistoryView> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('order_items')
          .select(
            'id, order_id, quantity, item_status, created_at, menu_items (name)',
          )
          .inFilter('item_status', ['ready', 'completed'])
          .order('created_at', ascending: false)
          .limit(100);

      if (mounted) {
        setState(() {
          _historyItems = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderColor, width: 2),
            ),
          ),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📜 HISTORY', style: AppTheme.headingXL()),
                  const SizedBox(height: 4),
                  Text(
                    '${_historyItems.length} completed',
                    style: AppTheme.bodySm(),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentTeal.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => _fetchHistory(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.accentTeal,
                    strokeWidth: 4,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _historyItems.length,
                  itemBuilder: (_, idx) {
                    final item = _historyItems[idx];
                    final date = DateTime.parse(item['created_at']).toLocal();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.accentTeal.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.accentTeal,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.done_all_rounded,
                              color: AppTheme.accentTeal,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${item['order_id']} • ${item['menu_items']['name']}',
                                  style: AppTheme.bodyMd().copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: ${item['quantity']}',
                                  style: AppTheme.bodySm(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                style: AppTheme.bodyMd().copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.success,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  'DONE',
                                  style: AppTheme.labelMd().copyWith(
                                    color: AppTheme.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── VIEW 3: MENU REFERENCE ────────────────────────────────────────────

class _MenuReferenceView extends StatefulWidget {
  const _MenuReferenceView();
  @override
  State<_MenuReferenceView> createState() => _MenuReferenceViewState();
}

class _MenuReferenceViewState extends State<_MenuReferenceView> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('menu_items')
          .select('name, preparation_time_minutes, categories (name)')
          .eq('requires_preparation', true)
          .eq('is_available', true)
          .order('name');

      if (mounted) {
        setState(() {
          _menuItems = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderColor, width: 2),
            ),
          ),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📖 MENU', style: AppTheme.headingXL()),
                  const SizedBox(height: 4),
                  Text('${_menuItems.length} items', style: AppTheme.bodySm()),
                ],
              ),
              const Spacer(),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentPurple.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => _fetchMenu(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.accentPurple,
                    strokeWidth: 4,
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _menuItems.length,
                  itemBuilder: (_, idx) {
                    final item = _menuItems[idx];
                    final prepTime = item['preparation_time_minutes'] ?? 0;

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.borderColor,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: AppTheme.bodyMd().copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.accentPurple,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              item['categories']['name'] ?? 'Menu',
                              style: AppTheme.labelMd().copyWith(
                                color: AppTheme.accentPurple,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentYellow.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.accentYellow,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: AppTheme.accentYellow,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$prepTime min',
                                  style: AppTheme.labelMd().copyWith(
                                    color: AppTheme.accentYellow,
                                  ),
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
    );
  }
}
