// lib/Features/Tables/floor_plan_screen.dart
// Zaytouna POS - Floor Plan (View & Toggle Tables)

// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';

class FloorPlanScreen extends StatefulWidget {
  const FloorPlanScreen({super.key});

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTables();
  }

  Future<void> _fetchTables() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('restaurant_tables')
          .select()
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _tables = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching tables: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Allow staff to quickly toggle table status
  Future<void> _toggleTableStatus(
    int id,
    bool currentStatus,
    String name,
  ) async {
    HapticFeedback.lightImpact();
    final newStatus = !currentStatus;

    // Optimistic UI update for instant feedback
    setState(() {
      final index = _tables.indexWhere((t) => t['id'] == id);
      if (index != -1) _tables[index]['is_available'] = newStatus;
    });

    try {
      await _supabase
          .from('restaurant_tables')
          .update({'is_available': newStatus})
          .eq('id', id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$name marked as ${newStatus ? 'Available' : 'Occupied'}',
          ),
          backgroundColor: newStatus
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Revert if failed
      setState(() {
        final index = _tables.indexWhere((t) => t['id'] == id);
        if (index != -1) _tables[index]['is_available'] = currentStatus;
      });
      print('Error updating table: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF6C757D)),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.cashierDashboard,
            (r) => false,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FLOOR PLAN',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8B6914),
              ),
            ),
            Text(
              'Live Seating Status',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212529),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6C757D)),
            onPressed: _fetchTables,
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB8860B)),
            )
          : RefreshIndicator(
              onRefresh: _fetchTables,
              color: const Color(0xFFB8860B),
              child: _tables.isEmpty
                  ? Center(
                      child: Text(
                        'No tables found. Please add tables in settings.',
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(20.w),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220.w,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.w,
                      ),
                      itemCount: _tables.length,
                      itemBuilder: (context, index) {
                        final table = _tables[index];
                        return _buildTableCard(table);
                      },
                    ),
            ),
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    final id = table['id'] as int;
    final name = table['name'] as String;
    final capacity = table['capacity'] as int?;
    final isAvailable = table['is_available'] as bool? ?? false;

    // Green for available, Red for occupied
    final bgColor = isAvailable
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEE2E2);
    final fgColor = isAvailable
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleTableStatus(id, isAvailable, name),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE9ECEF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.table_restaurant_rounded,
                  size: 32.sp,
                  color: fgColor,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212529),
                ),
              ),
              if (capacity != null) ...[
                SizedBox(height: 4.h),
                Text(
                  '$capacity Seats',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF6C757D),
                  ),
                ),
              ],
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  isAvailable ? 'AVAILABLE' : 'OCCUPIED',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
