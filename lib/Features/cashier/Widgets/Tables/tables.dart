// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';

// ───────────────────────────── Design tokens ─────────────────────────────
class _T {
  static const primary = Color(0xFFB8860B);
  static const primaryL = Color(0xFFFFF7DB);
  static const bg = Color(0xFFFAFAF7);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0A0F0D);
  static const ink2 = Color(0xFF2D3438);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE5E7EB);
  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFD1FAE5);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEE2E2);
}

TextStyle _f(double s, FontWeight w, Color c, {double ls = -0.2}) =>
    GoogleFonts.inter(
      fontSize: s,
      fontWeight: w,
      color: c,
      letterSpacing: ls,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

// ───────────────────────────── Page ─────────────────────────────
class TablesPage extends StatefulWidget {
  const TablesPage({super.key});
  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _tables = [];
  String _filter = 'all'; // all | available | occupied

  @override
  void initState() {
    super.initState();
    _fetchTables();
  }

  Future<void> _fetchTables() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('restaurant_tables')
          .select()
          .order('name', ascending: true);
      if (!mounted) return;
      setState(() {
        _tables = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading tables: $e',
            style: _f(13.sp, FontWeight.w600, Colors.white),
          ),
          backgroundColor: _T.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _visible {
    switch (_filter) {
      case 'available':
        return _tables.where((t) => t['is_available'] == true).toList();
      case 'occupied':
        return _tables.where((t) => t['is_available'] != true).toList();
      default:
        return _tables;
    }
  }

  int get _availableCount =>
      _tables.where((t) => t['is_available'] == true).length;
  int get _occupiedCount =>
      _tables.where((t) => t['is_available'] != true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _T.ink2),
          onPressed: () => context.go(Routes.cashierDashboard),
        ),
        title: Text(
          'Floor Plan',
          style: _f(18.sp, FontWeight.w800, _T.ink, ls: -0.4),
        ),
        actions: [
          IconButton(
            tooltip: 'Manage tables',
            icon: const Icon(Icons.settings_outlined, color: _T.ink2),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(Routes.manageTables);
            },
          ),
          Container(
            margin: EdgeInsets.only(right: 12.w),
            decoration: BoxDecoration(
              color: _T.primaryL,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _T.primary),
              onPressed: () {
                HapticFeedback.lightImpact();
                _fetchTables();
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: _T.line),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _T.primary))
          : _tables.isEmpty
          ? _empty()
          : RefreshIndicator(
              color: _T.primary,
              onRefresh: _fetchTables,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _summary()),
                  SliverToBoxAdapter(child: _filters()),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200.w,
                        childAspectRatio: 0.95,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _card(_visible[i]),
                        childCount: _visible.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── Summary row ─────────────────────────────────────────────────────
  Widget _summary() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Row(
        children: [
          _stat(
            'Total',
            _tables.length.toString(),
            Icons.table_bar_rounded,
            _T.primary,
            _T.primaryL,
          ),
          SizedBox(width: 10.w),
          _stat(
            'Available',
            _availableCount.toString(),
            Icons.check_circle_rounded,
            _T.success,
            _T.successBg,
          ),
          SizedBox(width: 10.w),
          _stat(
            'Occupied',
            _occupiedCount.toString(),
            Icons.event_busy_rounded,
            _T.danger,
            _T.dangerBg,
          ),
        ],
      ),
    );
  }

  Widget _stat(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _T.line),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 16.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: _f(10.sp, FontWeight.w700, _T.muted, ls: 0.5),
                  ),
                  SizedBox(height: 2.h),
                  Text(value, style: _f(18.sp, FontWeight.w800, _T.ink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filter chips ────────────────────────────────────────────────────
  Widget _filters() {
    Widget chip(String id, String label) {
      final selected = _filter == id;
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filter = id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: selected ? _T.primary : _T.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: selected ? _T.primary : _T.line),
          ),
          child: Text(
            label,
            style: _f(
              12.sp,
              FontWeight.w700,
              selected ? Colors.white : _T.ink2,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      child: Row(
        children: [
          chip('all', 'All'),
          SizedBox(width: 8.w),
          chip('available', 'Available'),
          SizedBox(width: 8.w),
          chip('occupied', 'Occupied'),
        ],
      ),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────────
  Widget _empty() => Center(
    child: Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: _T.primaryL,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.table_restaurant_outlined,
              size: 44.sp,
              color: _T.primary,
            ),
          ),
          SizedBox(height: 16.h),
          Text('No tables yet', style: _f(17.sp, FontWeight.w800, _T.ink)),
          SizedBox(height: 6.h),
          Text(
            'Add tables in Manage Tables to start seating guests.',
            style: _f(13.sp, FontWeight.w500, _T.muted),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () => context.push(Routes.manageTables),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Go to Manage Tables',
              style: _f(13.sp, FontWeight.w700, Colors.white),
            ),
          ),
        ],
      ),
    ),
  );

  // ─── Table card ──────────────────────────────────────────────────────
  Widget _card(Map<String, dynamic> t) {
    final isAvailable = t['is_available'] == true;
    final name = (t['name'] ?? 'Unnamed').toString();
    final int? capacity = t['capacity'] is int
        ? t['capacity'] as int
        : int.tryParse('${t['capacity']}');

    final accent = isAvailable ? _T.success : _T.danger;
    final accentBg = isAvailable ? _T.successBg : _T.dangerBg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () {
          HapticFeedback.lightImpact();
          if (!isAvailable) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$name is currently occupied',
                  style: _f(13.sp, FontWeight.w600, Colors.white),
                ),
                backgroundColor: _T.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            );
            return;
          }
          // Pass the selected table to the terminal so dine-in flow can
          // pre-fill it. terminalscreen.dart can read this via
          //   final extra = GoRouterState.of(context).extra as Map?;
          context.push(Routes.pos, extra: {'preselectedTable': t});
        },
        child: Container(
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isAvailable ? _T.success.withValues(alpha: 0.5) : _T.line,
              width: isAvailable ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: accentBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.table_restaurant_rounded,
                    size: 26.sp,
                    color: accent,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _f(15.sp, FontWeight.w800, _T.ink),
                ),
                if (capacity != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'Seats $capacity',
                    style: _f(11.sp, FontWeight.w600, _T.muted),
                  ),
                ],
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    isAvailable ? 'AVAILABLE' : 'OCCUPIED',
                    style: _f(9.sp, FontWeight.w800, accent, ls: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
