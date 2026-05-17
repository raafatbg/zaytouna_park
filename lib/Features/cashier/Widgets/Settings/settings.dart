// lib/Features/Settings/settings_screen.dart
// Zaytouna POS - Settings Screen (Light Theme - Home Page Style)

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zaytouna_park/Core/Routers/route_guard.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LIGHT THEME PALETTE (Matching Home Page & Expenses Page)
// ─────────────────────────────────────────────────────────────────────────────

class SettingsColors {
  SettingsColors._();

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

  static const gray = Color(0xFF6B7280);
  static const grayLight = Color(0xFFF3F4F6);
  static const grayDim = Color(0x1A6B7280);
}

// ─────────────────────────────────────────────────────────────────────────────
//  FONTS (Matching Home Page & Expenses Page Style)
// ─────────────────────────────────────────────────────────────────────────────

class SettingsFonts {
  SettingsFonts._();

  static TextStyle serif(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.dmSerifDisplay(
    fontSize: size,
    fontWeight: w,
    color: color ?? SettingsColors.text,
  );

  static TextStyle sans(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color ?? SettingsColors.text,
  );

  static TextStyle mono(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: w,
    color: color ?? SettingsColors.text,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SETTINGS MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum SettingSection {
  profile,
  store,
  system,
  notifications,
  security,
  integrations,
  appearance,
  support,
}

class SettingTile {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final SettingSection section;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SettingTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.section,
    this.onTap,
    this.trailing,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  SETTINGS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = Supabase.instance.client;

  // Color shortcuts
  Color get bg => SettingsColors.bg;
  Color get surface => SettingsColors.surface;
  Color get surface2 => SettingsColors.surface2;
  Color get surface3 => SettingsColors.surface3;
  Color get border => SettingsColors.border;
  Color get textClr => SettingsColors.text;
  Color get textMuted => SettingsColors.textSecondary;
  Color get textDim => SettingsColors.textMuted;

  String _currentTime = '';
  String _currentDate = '';
  Timer? _timer;

  // Local Settings State
  bool _isDark = false;
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _autoBackup = true;
  String _selectedLanguage = 'English';

  // Extra Settings State
  String _currency = 'USD';
  String _taxRate = '11.0';
  String _printerIp = '192.168.1.100';
  bool _autoPrint = true;

  // DB Profile State
  bool _isLoadingProfile = true;
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';
  String _userRole = 'Loading...';

  // Store settings
  String _storeName = 'Zaytouna Park Main Branch';
  String _storeAddress = '123 Restaurant Street, Downtown Area';

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
    _loadUserProfile();
    _loadStoreSettings();
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

  // --- DATABASE OPERATIONS ---

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoadingProfile = false);
        return;
      }

      // Fetch staff data and join with roles
      final data = await _supabase
          .from('staff')
          .select('name, email, roles(name)')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userName = data['name'] ?? 'Unknown User';
          _userEmail = data['email'] ?? user.email ?? 'No Email';

          if (data['roles'] != null) {
            _userRole = data['roles']['name'] ?? 'Staff';
          } else {
            _userRole = 'Staff';
          }
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoadingProfile = false);
        _showToast('Failed to load profile data', isError: true);
      }
    }
  }

  Future<void> _loadStoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _storeName = prefs.getString('storeName') ?? _storeName;
        _storeAddress = prefs.getString('storeAddress') ?? _storeAddress;
        _taxRate = prefs.getString('taxRate') ?? _taxRate;
        _currency = prefs.getString('currency') ?? _currency;
        _printerIp = prefs.getString('printerIp') ?? _printerIp;
        _autoPrint = prefs.getBool('autoPrint') ?? _autoPrint;
        _isDark = prefs.getBool('isDark') ?? _isDark;
        _notificationsEnabled =
            prefs.getBool('pushNotifs') ?? _notificationsEnabled;
        _emailNotifications =
            prefs.getBool('emailNotifs') ?? _emailNotifications;
        _autoBackup = prefs.getBool('autoBackup') ?? _autoBackup;
      });
    }
  }

  // ---------------------------

  List<SettingTile> get _settingsTiles => [
    // Profile Section
    SettingTile(
      title: 'My Profile',
      icon: Icons.person_outline_rounded,
      color: SettingsColors.blue,
      bgColor: SettingsColors.blueLight,
      section: SettingSection.profile,
    ),
    SettingTile(
      title: 'Store Settings',
      icon: Icons.storefront_rounded,
      color: SettingsColors.green,
      bgColor: SettingsColors.greenLight,
      section: SettingSection.store,
    ),
    SettingTile(
      title: 'Staff Management',
      icon: Icons.people_outline_rounded,
      color: SettingsColors.purple,
      bgColor: SettingsColors.purpleLight,
      section: SettingSection.store,
    ),

    // System Section
    SettingTile(
      title: 'General',
      icon: Icons.tune_rounded,
      color: SettingsColors.gray,
      bgColor: SettingsColors.grayLight,
      section: SettingSection.system,
    ),
    SettingTile(
      title: 'Appearance',
      icon: Icons.palette,
      color: SettingsColors.pink,
      bgColor: SettingsColors.pinkLight,
      section: SettingSection.appearance,
    ),
    SettingTile(
      title: 'Language',
      icon: Icons.language_rounded,
      color: SettingsColors.cyan,
      bgColor: SettingsColors.cyanLight,
      section: SettingSection.system,
    ),

    // Notifications Section
    SettingTile(
      title: 'Push Notifications',
      icon: Icons.notifications_none_rounded,
      color: SettingsColors.orange,
      bgColor: SettingsColors.orangeLight,
      section: SettingSection.notifications,
    ),
    SettingTile(
      title: 'Email Alerts',
      icon: Icons.email_outlined,
      color: SettingsColors.red,
      bgColor: SettingsColors.redLight,
      section: SettingSection.notifications,
    ),

    // Security Section
    SettingTile(
      title: 'Security',
      icon: Icons.security_rounded,
      color: SettingsColors.red,
      bgColor: SettingsColors.redLight,
      section: SettingSection.security,
    ),
    SettingTile(
      title: 'Backup & Restore',
      icon: Icons.backup_rounded,
      color: SettingsColors.green,
      bgColor: SettingsColors.greenLight,
      section: SettingSection.security,
    ),

    // Integrations Section
    SettingTile(
      title: 'Printer Settings',
      icon: Icons.print_rounded,
      color: SettingsColors.purple,
      bgColor: SettingsColors.purpleLight,
      section: SettingSection.integrations,
    ),
    SettingTile(
      title: 'Payment Gateways',
      icon: Icons.payment_rounded,
      color: SettingsColors.blue,
      bgColor: SettingsColors.blueLight,
      section: SettingSection.integrations,
    ),

    // Support Section
    SettingTile(
      title: 'Help & Support',
      icon: Icons.help_outline_rounded,
      color: SettingsColors.cyan,
      bgColor: SettingsColors.cyanLight,
      section: SettingSection.support,
    ),
    SettingTile(
      title: 'About',
      icon: Icons.info_outline_rounded,
      color: SettingsColors.gray,
      bgColor: SettingsColors.grayLight,
      section: SettingSection.support,
    ),
  ];

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
                      _userProfileCard(constraints),
                      SizedBox(height: 24.h),
                      _settingsSections(constraints),
                      SizedBox(height: 32.h),
                      _logoutButton(),
                      SizedBox(height: 20.h),
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
        GestureDetector(
          onTap: () => Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.cashierDashboard,
            (r) => false,
          ),
          child: Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: surface2,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.arrow_back_rounded, size: 20.sp, color: textClr),
          ),
        ),
        SizedBox(width: 16.w),
        Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: SettingsColors.green,
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
                  style: SettingsFonts.sans(
                    8.sp,
                    w: FontWeight.w700,
                    color: SettingsColors.green,
                  ),
                ),
                Text(
                  'Settings',
                  style: SettingsFonts.sans(
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
                decoration: const BoxDecoration(
                  color: SettingsColors.green,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '$_currentTime  ·  $_currentDate',
                style: SettingsFonts.mono(10.sp, color: textMuted),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: SettingsColors.blueLight,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Center(
            child: Text(
              _isLoadingProfile
                  ? '...'
                  : (_userName.isNotEmpty ? _userName[0] : 'U'),
              style: SettingsFonts.sans(
                16.sp,
                w: FontWeight.w700,
                color: SettingsColors.blue,
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
          color: SettingsColors.blueLight,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5.w,
              height: 5.w,
              decoration: const BoxDecoration(
                color: SettingsColors.blue,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              'SYSTEM PREFERENCES',
              style: SettingsFonts.sans(
                8.sp,
                w: FontWeight.w700,
                color: SettingsColors.blue,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 12.h),
      Text('Settings', style: SettingsFonts.serif(36.sp)),
      SizedBox(height: 6.h),
      Text(
        'Manage your account and system preferences.',
        style: SettingsFonts.sans(12.sp, color: textMuted),
      ),
    ],
  );

  // ── User Profile Card ────────────────────────────────────────────────────────

  Widget _userProfileCard(BoxConstraints c) {
    final isDesktop = c.maxWidth > 800;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20.w : 16.w),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [surface, SettingsColors.greenLight.withOpacity(0.3)],
        ),
      ),
      child: _isLoadingProfile
          ? Center(
              child: CircularProgressIndicator(color: SettingsColors.green),
            )
          : Row(
              children: [
                Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    color: SettingsColors.greenLight,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: SettingsColors.green, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0] : 'U',
                      style: SettingsFonts.serif(
                        32.sp,
                        w: FontWeight.w800,
                        color: SettingsColors.green,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: SettingsFonts.serif(18.sp, w: FontWeight.w700),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _userEmail,
                        style: SettingsFonts.sans(11.sp, color: textMuted),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: SettingsColors.greenDim,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          _userRole,
                          style: SettingsFonts.sans(
                            9.sp,
                            w: FontWeight.w600,
                            color: SettingsColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showEditProfileDialog(),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: SettingsColors.blueLight,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 16.sp,
                          color: SettingsColors.blue,
                        ),
                        if (isDesktop) ...[
                          SizedBox(width: 6.w),
                          Text(
                            'Edit',
                            style: SettingsFonts.sans(
                              11.sp,
                              w: FontWeight.w600,
                              color: SettingsColors.blue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Settings Sections ────────────────────────────────────────────────────────

  Widget _settingsSections(BoxConstraints c) {
    final Map<SettingSection, List<SettingTile>> groupedTiles = {};
    for (final tile in _settingsTiles) {
      if (!groupedTiles.containsKey(tile.section)) {
        groupedTiles[tile.section] = [];
      }
      groupedTiles[tile.section]!.add(tile);
    }

    return Column(
      children: groupedTiles.entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getSectionTitle(entry.key).toUpperCase(),
                style: SettingsFonts.sans(
                  11.sp,
                  w: FontWeight.w700,
                  color: textMuted,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: List.generate(entry.value.length, (index) {
                    final tile = entry.value[index];
                    final isLast = index == entry.value.length - 1;
                    return _settingTile(tile, isLast);
                  }),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _settingTile(SettingTile tile, bool isLast) {
    Widget? trailing = tile.trailing;

    if (tile.title == 'Push Notifications') {
      trailing = Switch(
        value: _notificationsEnabled,
        onChanged: (v) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('pushNotifs', v);
          setState(() => _notificationsEnabled = v);
        },
        activeColor: SettingsColors.green,
        activeTrackColor: SettingsColors.greenLight,
      );
    } else if (tile.title == 'Email Alerts') {
      trailing = Switch(
        value: _emailNotifications,
        onChanged: (v) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('emailNotifs', v);
          setState(() => _emailNotifications = v);
        },
        activeColor: SettingsColors.green,
        activeTrackColor: SettingsColors.greenLight,
      );
    } else if (tile.title == 'Backup & Restore') {
      trailing = Switch(
        value: _autoBackup,
        onChanged: (v) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('autoBackup', v);
          setState(() => _autoBackup = v);
        },
        activeColor: SettingsColors.green,
        activeTrackColor: SettingsColors.greenLight,
      );
    } else if (tile.title == 'Appearance') {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 16.sp,
            color: textMuted,
          ),
          SizedBox(width: 8.w),
          Switch(
            value: _isDark,
            onChanged: (v) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isDark', v);
              setState(() => _isDark = v);
            },
            activeColor: SettingsColors.green,
            activeTrackColor: SettingsColors.greenLight,
          ),
        ],
      );
    } else if (tile.title == 'Language') {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedLanguage,
            style: SettingsFonts.sans(11.sp, color: textMuted),
          ),
          SizedBox(width: 6.w),
          Icon(Icons.chevron_right_rounded, size: 18.sp, color: textMuted),
        ],
      );
    } else {
      trailing = Icon(
        Icons.chevron_right_rounded,
        size: 18.sp,
        color: textMuted,
      );
    }

    return GestureDetector(
      onTap: () => _handleTileTap(tile),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.transparent, // Required to register taps on entire row
          border: isLast ? null : Border(bottom: BorderSide(color: border)),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: tile.bgColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(tile.icon, size: 18.sp, color: tile.color),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                tile.title,
                style: SettingsFonts.sans(13.sp, w: FontWeight.w500),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _handleTileTap(SettingTile tile) async {
    switch (tile.title) {
      case 'My Profile':
        _showEditProfileDialog();
        break;
      case 'Store Settings':
        _showStoreSettingsDialog();
        break;
      case 'Staff Management':
        _showStaffManagementDialog();
        break;
      case 'General':
        _showGeneralSettingsDialog();
        break;
      case 'Language':
        _showLanguageDialog();
        break;
      case 'Push Notifications':
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pushNotifs', !_notificationsEnabled);
        setState(() => _notificationsEnabled = !_notificationsEnabled);
        break;
      case 'Email Alerts':
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('emailNotifs', !_emailNotifications);
        setState(() => _emailNotifications = !_emailNotifications);
        break;
      case 'Security':
        _showSecurityDialog();
        break;
      case 'Backup & Restore':
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('autoBackup', !_autoBackup);
        setState(() => _autoBackup = !_autoBackup);
        break;
      case 'Printer Settings':
        _showPrinterSettingsDialog();
        break;
      case 'Payment Gateways':
        _showPaymentSettingsDialog();
        break;
      case 'Appearance':
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isDark', !_isDark);
        setState(() => _isDark = !_isDark);
        break;
      case 'Help & Support':
        _showSupportDialog();
        break;
      case 'About':
        _showAboutDialog();
        break;
      default:
        _showToast('Coming soon', isError: false);
        break;
    }
  }

  // ── Logout Button ────────────────────────────────────────────────────────────

  Widget _logoutButton() => GestureDetector(
    onTap: _showLogoutDialog,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: SettingsColors.redLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SettingsColors.red.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout_rounded, size: 18.sp, color: SettingsColors.red),
          SizedBox(width: 10.w),
          Text(
            'Logout',
            style: SettingsFonts.sans(
              14.sp,
              w: FontWeight.w600,
              color: SettingsColors.red,
            ),
          ),
        ],
      ),
    ),
  );

  // ── FULLY WORKING DIALOGS ──────────────────────────────────────────────────

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Edit Profile',
              style: SettingsFonts.serif(18.sp, w: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('Full Name', nameCtrl, enabled: !isSaving),
                SizedBox(height: 12.h),
                _dialogField('Email Address', emailCtrl, enabled: !isSaving),
              ],
            ),
            actions: [
              if (!isSaving)
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: SettingsFonts.sans(12.sp, color: textMuted),
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SettingsColors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        setState(() => isSaving = true);
                        try {
                          final user = _supabase.auth.currentUser;
                          if (user != null) {
                            if (emailCtrl.text.trim() != _userEmail) {
                              await _supabase.auth.updateUser(
                                UserAttributes(email: emailCtrl.text.trim()),
                              );
                            }
                            await _supabase
                                .from('staff')
                                .update({
                                  'name': nameCtrl.text.trim(),
                                  'email': emailCtrl.text.trim(),
                                  'updated_at': DateTime.now()
                                      .toIso8601String(),
                                })
                                .eq('id', user.id);

                            await _loadUserProfile();

                            if (mounted) {
                              Navigator.pop(dialogContext);
                              _showToast('Profile updated successfully');
                            }
                          }
                        } catch (e) {
                          setState(() => isSaving = false);
                          _showToast(
                            'Failed to update profile: $e',
                            isError: true,
                          );
                        }
                      },
                child: isSaving
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: SettingsFonts.sans(
                          12.sp,
                          w: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStoreSettingsDialog() {
    final storeNameCtrl = TextEditingController(text: _storeName);
    final storeAddressCtrl = TextEditingController(text: _storeAddress);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Store Settings',
          style: SettingsFonts.serif(18.sp, w: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField('Store Name', storeNameCtrl),
            SizedBox(height: 12.h),
            _dialogField('Store Address', storeAddressCtrl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: SettingsFonts.sans(12.sp, color: textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SettingsColors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('storeName', storeNameCtrl.text.trim());
              await prefs.setString(
                'storeAddress',
                storeAddressCtrl.text.trim(),
              );

              setState(() {
                _storeName = storeNameCtrl.text.trim();
                _storeAddress = storeAddressCtrl.text.trim();
              });

              if (mounted) {
                Navigator.pop(dialogContext);
                _showToast('Store settings updated locally');
              }
            },
            child: Text(
              'Save Changes',
              style: SettingsFonts.sans(
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

  void _showSecurityDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Change Password',
              style: SettingsFonts.serif(18.sp, w: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(
                  'Current Password (Optional based on auth flow)',
                  currentPassCtrl,
                  obscure: true,
                  enabled: !isSaving,
                ),
                SizedBox(height: 12.h),
                _dialogField(
                  'New Password',
                  newPassCtrl,
                  obscure: true,
                  enabled: !isSaving,
                ),
                SizedBox(height: 12.h),
                _dialogField(
                  'Confirm Password',
                  confirmPassCtrl,
                  obscure: true,
                  enabled: !isSaving,
                ),
              ],
            ),
            actions: [
              if (!isSaving)
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: SettingsFonts.sans(12.sp, color: textMuted),
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SettingsColors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (newPassCtrl.text != confirmPassCtrl.text) {
                          _showToast('Passwords do not match', isError: true);
                          return;
                        }
                        if (newPassCtrl.text.length < 6) {
                          _showToast(
                            'Password must be at least 6 characters',
                            isError: true,
                          );
                          return;
                        }

                        setState(() => isSaving = true);

                        try {
                          await _supabase.auth.updateUser(
                            UserAttributes(password: newPassCtrl.text),
                          );

                          if (mounted) {
                            Navigator.pop(dialogContext);
                            _showToast('Password changed successfully');
                          }
                        } catch (e) {
                          setState(() => isSaving = false);
                          _showToast('Error changing password', isError: true);
                        }
                      },
                child: isSaving
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Update Password',
                        style: SettingsFonts.sans(
                          12.sp,
                          w: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = ['English', 'Arabic', 'French', 'Spanish'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Select Language',
          style: SettingsFonts.serif(18.sp, w: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang, style: SettingsFonts.sans(13.sp)),
              value: lang,
              groupValue: _selectedLanguage,
              activeColor: SettingsColors.green,
              onChanged: (v) {
                setState(() => _selectedLanguage = v!);
                Navigator.pop(dialogContext);
                _showToast('Language changed to $v');
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- NEW DIALOGS ADDED ---

  void _showGeneralSettingsDialog() {
    final taxCtrl = TextEditingController(text: _taxRate);
    final curCtrl = TextEditingController(text: _currency);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'General Preferences',
          style: SettingsFonts.serif(18.sp, w: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField('Tax Rate (%)', taxCtrl, isNumber: true),
            SizedBox(height: 12.h),
            _dialogField('Currency Symbol (e.g. USD, LBP)', curCtrl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: SettingsFonts.sans(12.sp, color: textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SettingsColors.green,
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('taxRate', taxCtrl.text.trim());
              await prefs.setString('currency', curCtrl.text.trim());
              setState(() {
                _taxRate = taxCtrl.text.trim();
                _currency = curCtrl.text.trim();
              });
              if (mounted) {
                Navigator.pop(dialogContext);
                _showToast('General settings updated');
              }
            },
            child: Text(
              'Save',
              style: SettingsFonts.sans(
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

  void _showPrinterSettingsDialog() {
    final ipCtrl = TextEditingController(text: _printerIp);
    bool currentAutoPrint = _autoPrint;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Printer Configuration',
              style: SettingsFonts.serif(18.sp, w: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('Thermal Printer IP Address', ipCtrl),
                SizedBox(height: 12.h),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Auto-print receipt on checkout',
                    style: SettingsFonts.sans(12.sp, w: FontWeight.w600),
                  ),
                  value: currentAutoPrint,
                  onChanged: (v) => setLocalState(() => currentAutoPrint = v),
                  activeColor: SettingsColors.green,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: SettingsFonts.sans(12.sp, color: textMuted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SettingsColors.green,
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('printerIp', ipCtrl.text.trim());
                  await prefs.setBool('autoPrint', currentAutoPrint);
                  setState(() {
                    _printerIp = ipCtrl.text.trim();
                    _autoPrint = currentAutoPrint;
                  });
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    _showToast('Printer settings saved');
                  }
                },
                child: Text(
                  'Save',
                  style: SettingsFonts.sans(
                    12.sp,
                    w: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Payment Gateways',
          style: SettingsFonts.serif(18.sp, w: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currently enabled methods:',
              style: SettingsFonts.sans(12.sp, color: textMuted),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: Icon(
                Icons.payments_rounded,
                color: SettingsColors.green,
              ),
              title: Text(
                'Cash',
                style: SettingsFonts.sans(14.sp, w: FontWeight.w600),
              ),
              trailing: const Icon(
                Icons.check_circle,
                color: SettingsColors.green,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.credit_card_rounded,
                color: SettingsColors.blue,
              ),
              title: Text(
                'Credit/Debit Terminal',
                style: SettingsFonts.sans(14.sp, w: FontWeight.w600),
              ),
              trailing: const Icon(
                Icons.check_circle,
                color: SettingsColors.green,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Note: Stripe/Online payments are managed via the web admin portal.',
              style: SettingsFonts.sans(10.sp, color: textDim),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Close',
              style: SettingsFonts.sans(12.sp, color: SettingsColors.blue),
            ),
          ),
        ],
      ),
    );
  }

  void _showStaffManagementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Staff Roster',
          style: SettingsFonts.serif(18.sp, w: FontWeight.w800),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300.h,
          child: FutureBuilder<List<dynamic>>(
            future: _supabase.from('staff').select('name, email, roles(name)'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: SettingsColors.green),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Text(
                    'Failed to load staff.',
                    style: SettingsFonts.sans(12.sp, color: SettingsColors.red),
                  ),
                );
              }
              final staffList = snapshot.data!;
              return ListView.separated(
                itemCount: staffList.length,
                separatorBuilder: (c, i) => Divider(color: Colors.grey[300]),
                itemBuilder: (context, index) {
                  final s = staffList[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: SettingsColors.purpleLight,
                      child: Text(
                        s['name'] != null ? s['name'][0] : '?',
                        style: TextStyle(
                          color: SettingsColors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      s['name'] ?? 'No Name',
                      style: SettingsFonts.sans(13.sp, w: FontWeight.w600),
                    ),
                    subtitle: Text(
                      s['email'] ?? '',
                      style: SettingsFonts.sans(11.sp, color: textMuted),
                    ),
                    trailing: Text(
                      s['roles']?['name'] ?? 'Staff',
                      style: SettingsFonts.sans(
                        11.sp,
                        color: SettingsColors.green,
                        w: FontWeight.bold,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          Text(
            'Add/Remove staff via Admin Portal',
            style: SettingsFonts.sans(10.sp, color: textDim),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Close',
              style: SettingsFonts.sans(12.sp, color: SettingsColors.blue),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Help & Support',
          style: SettingsFonts.serif(18.sp, w: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need assistance with your POS?',
              style: SettingsFonts.sans(13.sp, color: textClr),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: SettingsColors.blue,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'support@zaytounapark.com',
                  style: SettingsFonts.sans(12.sp, w: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  color: SettingsColors.green,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  '+961 1 234 567',
                  style: SettingsFonts.sans(12.sp, w: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Close',
              style: SettingsFonts.sans(12.sp, color: SettingsColors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: SettingsColors.green,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.park_rounded, size: 24.sp, color: Colors.white),
            ),
            SizedBox(width: 12.w),
            Text(
              'Zaytouna Park',
              style: SettingsFonts.serif(18.sp, w: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Version 1.0.0',
              style: SettingsFonts.sans(13.sp, w: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Text(
              'A complete Point of Sale system for restaurants and cafes.',
              style: SettingsFonts.sans(11.sp, color: textMuted),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Divider(color: border),
            SizedBox(height: 12.h),
            Text(
              '© 2026 Zaytouna Park. All rights reserved.',
              style: SettingsFonts.sans(9.sp, color: textDim),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close', style: SettingsFonts.sans(12.sp)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Logout',
          style: SettingsFonts.serif(18.sp, w: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: SettingsFonts.sans(13.sp, color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: SettingsFonts.sans(12.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SettingsColors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () async {
              await RouteGuard.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: Text(
              'Logout',
              style: SettingsFonts.sans(
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

  Widget _dialogField(
    String label,
    TextEditingController ctrl, {
    bool obscure = false,
    bool enabled = true,
    bool isNumber = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: SettingsFonts.sans(9.sp, w: FontWeight.w600, color: textDim),
      ),
      SizedBox(height: 6.h),
      Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: enabled ? surface2 : surface3,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: border),
        ),
        child: TextField(
          controller: ctrl,
          obscureText: obscure,
          enabled: enabled,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: SettingsFonts.sans(12.sp),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10.h),
          ),
          cursorColor: SettingsColors.green,
        ),
      ),
    ],
  );

  void _showToast(String msg, {bool isError = false}) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? SettingsColors.red : SettingsColors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.w),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                msg,
                style: SettingsFonts.sans(
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

  String _getSectionTitle(SettingSection section) {
    switch (section) {
      case SettingSection.profile:
        return 'Profile & Account';
      case SettingSection.store:
        return 'Store Management';
      case SettingSection.system:
        return 'System Preferences';
      case SettingSection.notifications:
        return 'Notifications';
      case SettingSection.security:
        return 'Security & Backup';
      case SettingSection.integrations:
        return 'Integrations';
      case SettingSection.appearance:
        return 'Appearance';
      case SettingSection.support:
        return 'Support & About';
    }
  }
}
