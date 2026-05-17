// lib/Features/Tables/manage_tables_screen.dart
// Zaytouna POS - Manage Tables (Admin)

// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';

class ManageTablesScreen extends StatefulWidget {
  const ManageTablesScreen({super.key});

  @override
  State<ManageTablesScreen> createState() => _ManageTablesScreenState();
}

class _ManageTablesScreenState extends State<ManageTablesScreen> {
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

  Future<void> _deleteTable(int id) async {
    try {
      await _supabase.from('restaurant_tables').delete().eq('id', id);
      _fetchTables();
      _showToast('Table deleted', const Color(0xFF10B981));
    } catch (e) {
      _showToast('Failed to delete table', const Color(0xFFEF4444));
    }
  }

  void _showTableDialog({Map<String, dynamic>? tableToEdit}) {
    final isEditing = tableToEdit != null;
    final nameCtrl = TextEditingController(
      text: isEditing ? tableToEdit['name'] : '',
    );
    final capCtrl = TextEditingController(
      text: isEditing ? tableToEdit['capacity']?.toString() : '',
    );
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            isEditing ? 'Edit Table' : 'Add New Table',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Table Name (e.g. T-01)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: capCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ], // Only allow numbers
                decoration: InputDecoration(
                  labelText: 'Seat Capacity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8860B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameCtrl.text.isEmpty) {
                        _showToast(
                          'Table name is required',
                          const Color(0xFFEF4444),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      // FIX: Ensure capacity is never null by providing a default (e.g., 4)
                      final parsedCapacity =
                          int.tryParse(capCtrl.text.trim()) ?? 4;

                      final data = {
                        'name': nameCtrl.text.trim(),
                        'capacity': parsedCapacity,
                        'is_available': isEditing
                            ? (tableToEdit['is_available'] ?? true)
                            : true,
                      };

                      try {
                        if (isEditing) {
                          await _supabase
                              .from('restaurant_tables')
                              .update(data)
                              .eq('id', tableToEdit['id']);
                        } else {
                          await _supabase
                              .from('restaurant_tables')
                              .insert(data);
                        }

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _fetchTables();
                          _showToast(
                            isEditing ? 'Table updated' : 'Table created',
                            const Color(0xFF10B981),
                          );
                        }
                      } on PostgrestException catch (e) {
                        // This catches Supabase specific errors (like Unique Name violations)
                        print('Supabase Error: ${e.message}');
                        setDialogState(() => isSubmitting = false);

                        // If it's a unique constraint violation on the name
                        if (e.code == '23505') {
                          _showToast(
                            'A table with this name already exists',
                            const Color(0xFFEF4444),
                          );
                        } else {
                          _showToast(e.message, const Color(0xFFEF4444));
                        }
                      } catch (e) {
                        print('General Error: $e');
                        setDialogState(() => isSubmitting = false);
                        _showToast(
                          'Failed to save table',
                          const Color(0xFFEF4444),
                        );
                      }
                    },
              child: isSubmitting
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isEditing ? 'Save' : 'Create',
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(String msg, Color color) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              'SETTINGS',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8B6914),
              ),
            ),
            Text(
              'Manage Tables',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212529),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showTableDialog(),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            label: const Text(
              'Add Table',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB8860B),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(width: 16.w),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB8860B)),
            )
          : ListView.builder(
              padding: EdgeInsets.all(20.w),
              itemCount: _tables.length,
              itemBuilder: (context, index) {
                final table = _tables[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    leading: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: const Icon(
                        Icons.table_bar_rounded,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                    title: Text(
                      table['name'],
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${table['capacity'] ?? 'Unknown'} Seats'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: Color(0xFF3B82F6),
                          ),
                          onPressed: () => _showTableDialog(tableToEdit: table),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_rounded,
                            color: Color(0xFFEF4444),
                          ),
                          onPressed: () => _deleteTable(table['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
