// lib/Features/Home/home_screen.dart
// Zaytouna POS - Light Theme Desktop Edition

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Light Theme Palette ─────────────────────────────────────────────────────

class VoraColors {
  VoraColors._();

  // Light Theme Colors
  static const bg = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0F2F5);
  static const surface3 = Color(0xFFE8EBF0);
  static const bdr = Color(0xFFE2E5EA);
  static const bdr2 = Color(0xFFD0D5DC);
  static const text = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF6B7280);
  static const muted = Color(0xFF9CA3AF);

  // Accent Colors for tiles
  static const gold = Color(0xFFC8A96E);
  static const goldLight = Color(0xFFF5E6D3);
  static const red = Color(0xFFEF4444);
  static const redLight = Color(0xFFFEE2E2);
  static const green = Color(0xFF22C55E);
  static const greenLight = Color(0xFFDCFCE7);
  static const blue = Color(0xFF3B82F6);
  static const blueLight = Color(0xFFDBEAFE);
  static const purple = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFFEDE9FE);
  static const orange = Color(0xFFF97316);
  static const orangeLight = Color(0xFFFFEDD5);
  static const yellow = Color(0xFFEAB308);
  static const yellowLight = Color(0xFFFEF9C3);
  static const cyan = Color(0xFF06B6D4);
  static const cyanLight = Color(0xFFCFFAFE);
  static const pink = Color(0xFFEC4899);
  static const pinkLight = Color(0xFFFCE7F3);
  static const indigo = Color(0xFF6366F1);
  static const indigoLight = Color(0xFFE0E7FF);
}

// ─── Fonts ───────────────────────────────────────────────────────────────────

class VoraFonts {
  VoraFonts._();

  static TextStyle serif(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) {
    return GoogleFonts.dmSerifDisplay(
      fontSize: size,
      fontWeight: w,
      color: color ?? VoraColors.text,
    );
  }

  static TextStyle sans(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: w,
      color: color ?? VoraColors.text,
    );
  }

  static TextStyle mono(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: w,
      color: color ?? VoraColors.text,
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class ActivityData {
  final String title, detail, amount, time;
  final Color color;

  const ActivityData({
    required this.title,
    required this.detail,
    required this.amount,
    required this.time,
    required this.color,
  });
}

// ─── Menu Tile Data ──────────────────────────────────────────────────────────

class MenuTileData {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final int tabIndex;

  const MenuTileData({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.tabIndex,
  });
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final ValueChanged<int> onNavigateTab;
  final VoidCallback onLaunchTerminal;

  const HomeScreen({
    super.key,
    this.isDark = false,
    required this.onToggleTheme,
    required this.onNavigateTab,
    required this.onLaunchTerminal,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;
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

  // Menu tiles matching the Zaytouna POS design
  static const List<MenuTileData> _menuTiles = [
    MenuTileData(
      title: 'POS',
      icon: Icons.point_of_sale_rounded,
      iconColor: VoraColors.blue,
      bgColor: VoraColors.blueLight,
      tabIndex: 0,
    ),
    MenuTileData(
      title: 'Orders',
      icon: Icons.receipt_long_rounded,
      iconColor: VoraColors.green,
      bgColor: VoraColors.greenLight,
      tabIndex: 1,
    ),
    MenuTileData(
      title: 'Deleted Orders',
      icon: Icons.delete_outline_rounded,
      iconColor: VoraColors.red,
      bgColor: VoraColors.redLight,
      tabIndex: 2,
    ),
    MenuTileData(
      title: 'Reports',
      icon: Icons.assessment_rounded,
      iconColor: VoraColors.purple,
      bgColor: VoraColors.purpleLight,
      tabIndex: 3,
    ),
    MenuTileData(
      title: 'Sales Report',
      icon: Icons.trending_up_rounded,
      iconColor: VoraColors.cyan,
      bgColor: VoraColors.cyanLight,
      tabIndex: 4,
    ),
    MenuTileData(
      title: 'Expenses',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: VoraColors.orange,
      bgColor: VoraColors.orangeLight,
      tabIndex: 5,
    ),
    MenuTileData(
      title: 'Inventory',
      icon: Icons.inventory_2_rounded,
      iconColor: VoraColors.yellow,
      bgColor: VoraColors.yellowLight,
      tabIndex: 6,
    ),
    MenuTileData(
      title: 'Suppliers',
      icon: Icons.local_shipping_rounded,
      iconColor: VoraColors.indigo,
      bgColor: VoraColors.indigoLight,
      tabIndex: 7,
    ),
    MenuTileData(
      title: 'Categories',
      icon: Icons.category_rounded,
      iconColor: VoraColors.pink,
      bgColor: VoraColors.pinkLight,
      tabIndex: 8,
    ),
    MenuTileData(
      title: 'Products',
      icon: Icons.restaurant_rounded,
      iconColor: VoraColors.green,
      bgColor: VoraColors.greenLight,
      tabIndex: 9,
    ),
    MenuTileData(
      title: 'Tables',
      icon: Icons.table_restaurant_rounded,
      iconColor: VoraColors.blue,
      bgColor: VoraColors.blueLight,
      tabIndex: 10,
    ),
    MenuTileData(
      title: 'Settings',
      icon: Icons.settings_rounded,
      iconColor: VoraColors.muted,
      bgColor: VoraColors.surface2,
      tabIndex: 11,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateDateTime(),
    );
    _scrollController.addListener(_handleScroll);
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

  void _handleScroll() {
    if (!mounted) return;
    final newOffset = _scrollController.offset;
    final shouldShowShadow = newOffset > 20;
    if (shouldShowShadow != (_scrollOffset > 20)) {
      setState(() => _scrollOffset = newOffset);
    } else {
      _scrollOffset = newOffset;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  static const List<ActivityData> _activities = [
    ActivityData(
      title: 'Order #1842 · Table 7',
      detail: 'Grilled Salmon, Lemonade ×2',
      amount: '+\$54.00',
      time: '2m ago',
      color: VoraColors.green,
    ),
    ActivityData(
      title: 'Order #1841 · Delivery',
      detail: 'Family Platter, Pepsi ×4',
      amount: '+\$112.50',
      time: '7m ago',
      color: VoraColors.blue,
    ),
    ActivityData(
      title: 'Inventory Alert · Napkins',
      detail: 'Stock below threshold (12 left)',
      amount: 'Low',
      time: '15m ago',
      color: VoraColors.red,
    ),
    ActivityData(
      title: 'Order #1840 · Table 3',
      detail: 'Mezze Platter, Arak',
      amount: '+\$88.00',
      time: '22m ago',
      color: VoraColors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: VoraColors.bg,
        body: Column(
          children: [
            // Top Header Bar
            LightTopBar(
              timeStr: _currentTime,
              dateStr: _currentDate,
              scrolled: _scrollOffset > 20,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24.w : 16.w,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      const WelcomeHeader(),

                      // Menu Tiles Grid - 4 columns for desktop
                      SizedBox(height: 24.h),
                      MenuTilesGrid(
                        tiles: _menuTiles,
                        onTileTap: widget.onNavigateTab,
                      ),

                      SizedBox(height: 24.h),
                      SectionHeader(
                        title: 'Recent Activity',
                        action: 'See all',
                        isDesktop: isDesktop,
                      ),
                      SizedBox(height: 12.h),
                      ActivityFeed(activities: _activities),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Light Top Bar ───────────────────────────────────────────────────────────

class LightTopBar extends StatelessWidget {
  final String timeStr;
  final String dateStr;
  final bool scrolled;

  const LightTopBar({
    super.key,
    required this.timeStr,
    required this.dateStr,
    required this.scrolled,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showDate = screenWidth > 600;

    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: VoraColors.surface,
        border: Border(
          bottom: BorderSide(
            color: scrolled ? VoraColors.bdr : Colors.transparent,
            width: 1,
          ),
        ),
        boxShadow: scrolled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Hamburger Menu
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: VoraColors.surface2,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.menu_rounded,
              size: 20.sp,
              color: VoraColors.text,
            ),
          ),
          SizedBox(width: 16.w),

          // Logo with Tree Icon
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: VoraColors.green,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.park_rounded,
                  size: 22.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ZAYTOUNA PARK',
                    style: VoraFonts.sans(
                      8.sp,
                      w: FontWeight.w700,
                      color: VoraColors.green,
                    ),
                  ),
                  Text(
                    'Restaurant POS',
                    style: VoraFonts.sans(
                      12.sp,
                      w: FontWeight.w600,
                      color: VoraColors.text,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Time & Date Chip
          if (showDate) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: VoraColors.surface2,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: VoraColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '$timeStr  ·  $dateStr',
                    style: VoraFonts.mono(
                      10.sp,
                      color: VoraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
          ],

          // User Profile
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: VoraColors.blueLight,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: VoraColors.bdr, width: 1.5),
            ),
            child: Center(
              child: Text(
                'S',
                style: VoraFonts.sans(
                  16.sp,
                  w: FontWeight.w700,
                  color: VoraColors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu Tiles Grid ─────────────────────────────────────────────────────────

class MenuTilesGrid extends StatelessWidget {
  final List<MenuTileData> tiles;
  final ValueChanged<int> onTileTap;

  const MenuTilesGrid({
    super.key,
    required this.tiles,
    required this.onTileTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    // 4 columns for desktop, 3 for tablet, 2 for mobile
    int crossAxisCount = 2;
    if (screenWidth > 600) crossAxisCount = 3;
    if (screenWidth > 900) crossAxisCount = 4;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        childAspectRatio: isDesktop ? 1.15 : 1.0,
      ),
      itemCount: tiles.length,
      itemBuilder: (ctx, i) => MenuTile(data: tiles[i], onTap: onTileTap),
    );
  }
}

class MenuTile extends StatefulWidget {
  final MenuTileData data;
  final ValueChanged<int> onTap;

  const MenuTile({super.key, required this.data, required this.onTap});

  @override
  State<MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<MenuTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap(data.tabIndex);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: VoraColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: _isHovered ? VoraColors.bdr2 : VoraColors.bdr,
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isDesktop ? 64.w : 52.w,
                height: isDesktop ? 64.w : 52.w,
                decoration: BoxDecoration(
                  color: data.bgColor,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: data.iconColor.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  data.icon,
                  size: isDesktop ? 30.sp : 24.sp,
                  color: data.iconColor,
                ),
              ),
              SizedBox(height: isDesktop ? 14.h : 10.h),
              // Title
              Text(
                data.title,
                style: VoraFonts.sans(
                  isDesktop ? 13.sp : 11.sp,
                  w: FontWeight.w600,
                  color: VoraColors.text,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Welcome Header ──────────────────────────────────────────────────────────

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: VoraColors.greenLight,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5.w,
                height: 5.w,
                decoration: const BoxDecoration(
                  color: VoraColors.green,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'RESTAURANT POS READY',
                style: VoraFonts.sans(
                  8.sp,
                  w: FontWeight.w700,
                  color: VoraColors.green,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          isDesktop ? 'Good morning, Salman.' : 'Good morning,\nSalman.',
          style: VoraFonts.serif(
            isDesktop ? 36.sp : 28.sp,
          ).copyWith(height: 1.1),
        ),
        SizedBox(height: 6.h),
        Text(
          "Welcome to your restaurant dashboard.",
          style: VoraFonts.sans(12.sp, color: VoraColors.textSecondary),
        ),
      ],
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title, action;
  final bool isDesktop;

  const SectionHeader({
    super.key,
    required this.title,
    required this.action,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: VoraFonts.sans(
            isDesktop ? 11.sp : 9.sp,
            w: FontWeight.w700,
            color: VoraColors.textSecondary,
          ),
        ),
        Row(
          children: [
            Text(
              action,
              style: VoraFonts.sans(
                isDesktop ? 11.sp : 10.sp,
                w: FontWeight.w600,
                color: VoraColors.green,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.arrow_forward_rounded,
              size: 14.sp,
              color: VoraColors.green,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Activity Feed ───────────────────────────────────────────────────────────

class ActivityFeed extends StatelessWidget {
  final List<ActivityData> activities;
  const ActivityFeed({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      decoration: BoxDecoration(
        color: VoraColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: VoraColors.bdr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          return LightActivityRow(
            activity: activity,
            isLast: index == activities.length - 1,
            isDesktop: isDesktop,
          );
        }).toList(),
      ),
    );
  }
}

class LightActivityRow extends StatelessWidget {
  final ActivityData activity;
  final bool isLast;
  final bool isDesktop;

  const LightActivityRow({
    super.key,
    required this.activity,
    required this.isLast,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20.w : 14.w,
        vertical: isDesktop ? 14.h : 10.h,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: VoraColors.bdr)),
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 8.w : 6.w,
            height: isDesktop ? 8.w : 6.w,
            decoration: BoxDecoration(
              color: activity.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isDesktop ? 16.w : 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: VoraFonts.sans(
                    isDesktop ? 12.sp : 10.sp,
                    w: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  activity.detail,
                  style: VoraFonts.sans(
                    isDesktop ? 10.sp : 8.sp,
                    color: VoraColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 12.w : 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity.amount,
                style: VoraFonts.mono(
                  isDesktop ? 12.sp : 10.sp,
                  w: FontWeight.w500,
                  color: activity.color,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                activity.time,
                style: VoraFonts.mono(
                  isDesktop ? 9.sp : 8.sp,
                  color: VoraColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
