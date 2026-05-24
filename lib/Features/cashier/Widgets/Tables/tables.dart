// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';

// Assuming you have your typography and colors available,
// if not, make sure they are imported from your theme file.

class TablesPage extends StatefulWidget {
  const TablesPage({super.key});

  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _tables = [];

  @override
  void initState() {
    super.initState();
    _fetchTables();
  }

  Future<void> _fetchTables() async {
    setState(() => _isLoading = true);
    try {
      // Fetch tables ordered by name
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
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tables: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // bg
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)), // textDark
        title: Text(
          'Restaurant Floor Plan',
          style: GoogleFonts.inter(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFB8860B).withOpacity(0.1), // Primary light
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFB8860B)),
              onPressed: () {
                HapticFeedback.lightImpact();
                _fetchTables();
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB8860B)),
            )
          : _tables.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: const Color(0xFFB8860B),
              onRefresh: _fetchTables,
              child: GridView.builder(
                padding: EdgeInsets.all(24.w),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220.w,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_restaurant_outlined,
            size: 64.sp,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            'No tables configured yet.',
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/manage-tables'),
            icon: const Icon(Icons.add, color: Color(0xFFB8860B)),
            label: Text(
              'Go to Manage Tables',
              style: GoogleFonts.inter(
                color: const Color(0xFFB8860B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    // True = Green (Free), False = Red (Occupied/Disabled)
    final bool isAvailable = table['is_available'] == true;
    final String name = table['name'];
    final int? capacity = table['capacity'];

    final Color primaryColor = isAvailable
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final Color bgColor = isAvailable
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFFEE2E2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (isAvailable) {
            // Navigate to POS to open a new order
            Navigator.pushNamed(context, Routes.pos);
          } else {
            // Give a hint that it's occupied
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name is currently occupied.'),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isAvailable
                  ? const Color(0xFF10B981).withOpacity(0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.table_restaurant_rounded,
                  size: 32.sp,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (capacity != null) ...[
                SizedBox(height: 4.h),
                Text(
                  'Seats $capacity',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  isAvailable ? 'AVAILABLE' : 'OCCUPIED',
                  style: GoogleFonts.inter(
                    color: primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.sp,
                    letterSpacing: 0.5,
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
