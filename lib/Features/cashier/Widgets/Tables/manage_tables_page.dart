// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';

// Assuming ZaytounaColors and ZaytounaTypography are imported here
// import 'package:zaytouna_park/Path/To/Your/Zaytouna_Theme.dart';

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
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('restaurant_tables')
          .select()
          .order('name', ascending: true);

      setState(() {
        _tables = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tables: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddTableDialog([Map<String, dynamic>? existingTable]) {
    final isEditing = existingTable != null;
    final nameCtrl = TextEditingController(text: existingTable?['name'] ?? '');
    final capCtrl = TextEditingController(
      text: existingTable?['capacity']?.toString() ?? '',
    );
    bool isAvailable = existingTable?['is_available'] ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              title: Text(
                isEditing ? 'Edit Table' : 'Add New Table',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Table Name (e.g., Table 1, Patio A)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: capCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Seating Capacity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SwitchListTile(
                    title: const Text('Is Available?'),
                    subtitle: const Text(
                      'Allow orders to be assigned to this table.',
                    ),
                    value: isAvailable,
                    activeThumbColor: const Color(
                      0xFFB8860B,
                    ), // Zaytouna Primary
                    onChanged: (val) => setStateDialog(() => isAvailable = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8860B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    Navigator.pop(context); // close dialog
                    setState(() => _isLoading = true);

                    try {
                      final tableData = {
                        'name': nameCtrl.text,
                        'capacity': int.tryParse(capCtrl.text),
                        'is_available': isAvailable,
                      };

                      if (isEditing) {
                        await _supabase
                            .from('restaurant_tables')
                            .update(tableData)
                            .eq('id', existingTable['id']);
                      } else {
                        await _supabase
                            .from('restaurant_tables')
                            .insert(tableData);
                      }
                      _fetchTables(); // Refresh list
                    } catch (e) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error saving table: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(
                    isEditing ? 'Save Changes' : 'Create Table',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTable(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table?'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _supabase.from('restaurant_tables').delete().eq('id', id);
      _fetchTables();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete table. It might have associated orders. Error: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
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
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Manage Tables',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFB8860B), // Primary
        onPressed: () => _showAddTableDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Table',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB8860B)),
            )
          : _tables.isEmpty
          ? const Center(
              child: Text('No tables configured yet. Add your first table!'),
            )
          : ListView.separated(
              padding: EdgeInsets.all(20.w),
              itemCount: _tables.length,
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final table = _tables[index];
                final isAvailable = table['is_available'] == true;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 8.h,
                    ),
                    leading: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : const Color(0xFFEF4444).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.table_restaurant_rounded,
                        color: isAvailable
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    title: Text(
                      table['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      'Capacity: ${table['capacity'] ?? 'N/A'} • ${isAvailable ? 'Active' : 'Disabled'}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: Colors.blue,
                          ),
                          onPressed: () => _showAddTableDialog(table),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_rounded,
                            color: Colors.red,
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
