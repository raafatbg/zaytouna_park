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
  static const surfaceAlt = Color(0xFFF5F5F0);
  static const ink = Color(0xFF0A0F0D);
  static const ink2 = Color(0xFF2D3438);
  static const muted = Color(0xFF64748B);
  static const muted2 = Color(0xFF94A3B8);
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
class ManageTablesPage extends StatefulWidget {
  const ManageTablesPage({super.key});
  @override
  State<ManageTablesPage> createState() => _ManageTablesPageState();
}

class _ManageTablesPageState extends State<ManageTablesPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _tables = [];

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
      _toast('Error loading tables: $e', err: true);
    }
  }

  void _toast(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: _f(13.sp, FontWeight.w600, Colors.white)),
        backgroundColor: err ? _T.danger : _T.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  // ─── Add / Edit dialog ───────────────────────────────────────────────
  void _showAddTableDialog([Map<String, dynamic>? existing]) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final capCtrl = TextEditingController(
      text: existing?['capacity']?.toString() ?? '',
    );
    bool isAvailable = existing?['is_available'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              backgroundColor: _T.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              titlePadding: EdgeInsets.fromLTRB(24.w, 22.h, 24.w, 8.h),
              contentPadding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 8.h),
              actionsPadding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: _T.primaryL,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_rounded : Icons.add_rounded,
                      color: _T.primary,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Table' : 'Add New Table',
                      style: _f(18.sp, FontWeight.w800, _T.ink),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(
                      nameCtrl,
                      'Table name',
                      'e.g. Table 1, Patio A',
                      icon: Icons.label_outline_rounded,
                    ),
                    SizedBox(height: 14.h),
                    _field(
                      capCtrl,
                      'Seating capacity',
                      'e.g. 4',
                      icon: Icons.people_alt_outlined,
                      keyboard: TextInputType.number,
                    ),
                    SizedBox(height: 14.h),
                    Container(
                      decoration: BoxDecoration(
                        color: _T.surfaceAlt,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: _T.line),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14.w),
                        title: Text(
                          'Available for orders',
                          style: _f(13.sp, FontWeight.w700, _T.ink),
                        ),
                        subtitle: Text(
                          'Allow new orders on this table.',
                          style: _f(11.sp, FontWeight.w500, _T.muted),
                        ),
                        value: isAvailable,
                        activeThumbColor: _T.primary,
                        onChanged: (v) => setSt(() => isAvailable = v),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: _f(13.sp, FontWeight.w600, _T.muted),
                  ),
                ),
                SizedBox(width: 4.w),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 22.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      HapticFeedback.mediumImpact();
                      return;
                    }
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    setState(() => _isLoading = true);
                    try {
                      final data = {
                        'name': nameCtrl.text.trim(),
                        'capacity': int.tryParse(capCtrl.text.trim()),
                        'is_available': isAvailable,
                      };
                      if (isEditing) {
                        await _supabase
                            .from('restaurant_tables')
                            .update(data)
                            .eq('id', existing['id']);
                      } else {
                        await _supabase.from('restaurant_tables').insert(data);
                      }
                      HapticFeedback.lightImpact();
                      if (mounted) {
                        _toast(isEditing ? 'Table updated' : 'Table created');
                      }
                      _fetchTables();
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _isLoading = false);
                      _toast('Error saving table: $e', err: true);
                    }
                  },
                  child: Text(
                    isEditing ? 'Save changes' : 'Create table',
                    style: _f(13.sp, FontWeight.w700, Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    String hint, {
    IconData? icon,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      style: _f(14.sp, FontWeight.w600, _T.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: _f(12.sp, FontWeight.w600, _T.muted),
        hintStyle: _f(13.sp, FontWeight.w500, _T.muted2),
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: _T.primary, size: 18.sp),
        filled: true,
        fillColor: _T.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: _T.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: _T.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: _T.primary, width: 1.6),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      ),
    );
  }

  // ─── Delete confirmation ─────────────────────────────────────────────
  Future<void> _deleteTable(dynamic id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _T.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: _T.dangerBg,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: _T.danger,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Delete table?',
                style: _f(17.sp, FontWeight.w800, _T.ink),
              ),
            ),
          ],
        ),
        content: Text(
          'Delete "$name"? This cannot be undone, and tables with linked orders cannot be removed.',
          style: _f(13.sp, FontWeight.w500, _T.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: _f(13.sp, FontWeight.w600, _T.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: _f(13.sp, FontWeight.w700, Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await _supabase.from('restaurant_tables').delete().eq('id', id);
      _toast('Table deleted');
      _fetchTables();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _toast('Cannot delete: it may have linked orders. ($e)', err: true);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────
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
          'Manage Tables',
          style: _f(18.sp, FontWeight.w800, _T.ink, ls: -0.4),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: _T.line),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _T.primary,
        elevation: 2,
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddTableDialog();
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Table',
          style: _f(13.sp, FontWeight.w700, Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _T.primary))
          : _tables.isEmpty
          ? _empty()
          : RefreshIndicator(
              color: _T.primary,
              onRefresh: _fetchTables,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 90.h),
                itemCount: _tables.length,
                separatorBuilder: (_, _) => SizedBox(height: 10.h),
                itemBuilder: (_, i) => _row(_tables[i]),
              ),
            ),
    );
  }

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
              Icons.table_restaurant_rounded,
              size: 44.sp,
              color: _T.primary,
            ),
          ),
          SizedBox(height: 16.h),
          Text('No tables yet', style: _f(17.sp, FontWeight.w800, _T.ink)),
          SizedBox(height: 6.h),
          Text(
            'Add your first table to start seating guests.',
            style: _f(13.sp, FontWeight.w500, _T.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _row(Map<String, dynamic> t) {
    final isAvailable = t['is_available'] == true;
    final name = (t['name'] ?? 'Unnamed').toString();
    final cap = t['capacity'];

    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _T.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: isAvailable ? _T.successBg : _T.dangerBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.table_restaurant_rounded,
            color: isAvailable ? _T.success : _T.danger,
            size: 20.sp,
          ),
        ),
        title: Text(name, style: _f(15.sp, FontWeight.w800, _T.ink)),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Row(
            children: [
              Icon(Icons.people_alt_rounded, size: 12.sp, color: _T.muted),
              SizedBox(width: 4.w),
              Text(
                'Seats ${cap ?? '—'}',
                style: _f(11.sp, FontWeight.w600, _T.muted),
              ),
              SizedBox(width: 10.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isAvailable ? _T.successBg : _T.dangerBg,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  isAvailable ? 'Active' : 'Disabled',
                  style: _f(
                    10.sp,
                    FontWeight.w800,
                    isAvailable ? _T.success : _T.danger,
                    ls: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_rounded, color: _T.primary, size: 20.sp),
              onPressed: () => _showAddTableDialog(t),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: _T.danger,
                size: 20.sp,
              ),
              onPressed: () => _deleteTable(t['id'], name),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
