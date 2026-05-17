// lib/Features/Facilities/facilities_management.dart
// Zaytouna POS - Facilities & Asset Management (Connected to Supabase)

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────────────────────

class Facility {
  final int id;
  final String name;
  final int typeId;
  final String typeName;
  final int? capacity;
  final double pricePerHour;
  final bool isAvailable;

  Facility({
    required this.id,
    required this.name,
    required this.typeId,
    required this.typeName,
    this.capacity,
    required this.pricePerHour,
    required this.isAvailable,
  });

  factory Facility.fromSupabase(Map<String, dynamic> map) {
    return Facility(
      id: map['id'] ?? 0,
      name: map['name'] ?? 'Unnamed Spot',
      typeId: map['type_id'] ?? 0,
      typeName: map['facility_types']?['name'] ?? 'General',
      capacity: map['capacity'],
      pricePerHour: (map['price_per_hour'] as num?)?.toDouble() ?? 0.0,
      isAvailable: map['is_available'] ?? true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({super.key});

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Facility> _facilities = [];
  List<Map<String, dynamic>> _types = [];

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
  }

  Future<void> _fetchFacilities() async {
    setState(() => _isLoading = true);
    try {
      // Fetch types for the dropdown
      final typesData = await _supabase
          .from('facility_types')
          .select('id, name');

      // Fetch facilities with a join on types
      final facilitiesData = await _supabase
          .from('facilities')
          .select('*, facility_types(name)')
          .order('name', ascending: true);

      setState(() {
        _types = List<Map<String, dynamic>>.from(typesData);
        _facilities = (facilitiesData as List)
            .map((f) => Facility.fromSupabase(f))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      _showToast("Error: $e", Colors.red);
      setState(() => _isLoading = false);
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          _AddFacilityDialog(types: _types, onSuccess: _fetchFacilities),
    );
  }

  void _showEditDialog(Facility facility) {
    showDialog(
      context: context,
      builder: (context) => _EditFacilityDialog(
        facility: facility,
        types: _types,
        onSuccess: _fetchFacilities,
      ),
    );
  }

  Future<void> _deleteFacility(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Facility',
          style: GoogleFonts.dmSerifDisplay(fontSize: 20.sp),
        ),
        content: Text(
          'Are you sure you want to delete this facility? This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase.from('facilities').delete().eq('id', id);
      _showToast('Facility deleted', const Color(0xFF22C55E));
      _fetchFacilities();
    } catch (e) {
      _showToast('Failed to delete facility', const Color(0xFFEF4444));
    }
  }

  void _showToast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8), // Match Inventory BG
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF22C55E)),
                  )
                : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 500;

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 48.h, 24.w, 20.h),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FACILITIES',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF22C55E),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Park Areas & Assets',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Text(
                  '${_facilities.length} facilities available',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // FIX: Responsive Button - drops text on small mobile screens
          ElevatedButton(
            onPressed: _showAddDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12.w : 20.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white),
                if (!isMobile) ...[
                  SizedBox(width: 8.w),
                  Text(
                    'New Facility',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_facilities.isEmpty) {
      return Center(
        child: Text(
          "No facilities found. Add your first area!",
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    // FIX: Dynamic Column Count & Aspect Ratio based on screen width
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    double aspectRatio = 2.5; // Wider cards for mobile list view

    if (width > 1100) {
      crossAxisCount = 4;
      aspectRatio = 1.1;
    } else if (width > 800) {
      crossAxisCount = 3;
      aspectRatio = 1.1;
    } else if (width > 550) {
      crossAxisCount = 2;
      aspectRatio = 1.2;
    }

    return GridView.builder(
      padding: EdgeInsets.all(24.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: aspectRatio,
      ),
      itemCount: _facilities.length,
      itemBuilder: (context, index) {
        final f = _facilities[index];
        return _FacilityCard(
          facility: f,
          onEdit: () => _showEditDialog(f),
          onDelete: () => _deleteFacility(f.id),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FACILITY CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _FacilityCard extends StatelessWidget {
  final Facility facility;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FacilityCard({
    required this.facility,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = facility.isAvailable
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.bed, size: 18.sp, color: statusColor),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      facility.typeName,
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 11.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20.sp,
                  color: Colors.grey[700],
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: const Color(0xFFEF4444)),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') return onEdit();
                  if (value == 'delete') return onDelete();
                },
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  label: 'CAPACITY',
                  value: '${facility.capacity ?? "∞"}',
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _InfoItem(
                  label: 'PRICE/HR',
                  value: '\$${facility.pricePerHour.toStringAsFixed(0)}',
                  alignRight: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 8.h,
            children: [
              _StatusBadge(isAvailable: facility.isAvailable),
              _TagChip(label: facility.typeName),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isAvailable;
  const _StatusBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        isAvailable ? 'READY' : 'BOOKED',
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label, value;
  final bool alignRight;
  const _InfoItem({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8.sp,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          color: const Color(0xFF4B5563),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ADD DIALOG (COLORS FIXED)
// ─────────────────────────────────────────────────────────────────────────────

class _AddFacilityDialog extends StatefulWidget {
  final List<Map<String, dynamic>> types;
  final VoidCallback onSuccess;

  const _AddFacilityDialog({required this.types, required this.onSuccess});

  @override
  State<_AddFacilityDialog> createState() => _AddFacilityDialogState();
}

class _AddFacilityDialogState extends State<_AddFacilityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: "10");
  final _capCtrl = TextEditingController(text: "4");
  int? _selectedTypeId;
  bool _isSaving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedTypeId == null) return;

    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('facilities').insert({
        'name': _nameCtrl.text.trim(),
        'type_id': _selectedTypeId,
        'capacity': int.tryParse(_capCtrl.text),
        'price_per_hour': double.tryParse(_priceCtrl.text),
        'is_available': true,
      });
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Save failed: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent, // Kills the Material 3 purple tint
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        'Add New Area',
        style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF1A1D26)),
      ),
      // FIX: Use BoxConstraints instead of fixed width so it shrinks on mobile
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxWidth: 400.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: _inputStyle('Category / Type'),
                dropdownColor: Colors.white,
                iconEnabledColor: const Color(0xFF22C55E),
                isExpanded: true, // Prevents text overflow inside dropdown
                items: widget.types
                    .map(
                      (t) => DropdownMenuItem(
                        value: t['id'] as int,
                        child: Text(
                          t['name'],
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1A1D26),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedTypeId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputStyle('Name (e.g. Picnic Area B)'),
                style: GoogleFonts.inter(color: const Color(0xFF1A1D26)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capCtrl,
                      decoration: _inputStyle('Capacity'),
                      style: GoogleFonts.inter(color: const Color(0xFF1A1D26)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: _inputStyle('Price/hr'),
                      style: GoogleFonts.inter(color: const Color(0xFF1A1D26)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            disabledBackgroundColor: const Color(
              0xFF22C55E,
            ).withOpacity(0.6), // Keeps green tone when saving
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Create Facility',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  InputDecoration _inputStyle(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.inter(
      fontSize: 12.sp,
      color: const Color(0xFF6B7280),
    ),
    filled: true,
    fillColor: const Color(0xFFF0F2F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(
        color: Color(0xFF22C55E),
        width: 1.5,
      ), // Active Focus Green
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(
        color: Color(0xFFEF4444),
        width: 1.5,
      ), // Red Error
    ),
  );
}

class _EditFacilityDialog extends StatefulWidget {
  final Facility facility;
  final List<Map<String, dynamic>> types;
  final VoidCallback onSuccess;

  const _EditFacilityDialog({
    required this.facility,
    required this.types,
    required this.onSuccess,
  });

  @override
  State<_EditFacilityDialog> createState() => _EditFacilityDialogState();
}

class _EditFacilityDialogState extends State<_EditFacilityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _capCtrl;
  int? _selectedTypeId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedTypeId = widget.facility.typeId;
    _nameCtrl = TextEditingController(text: widget.facility.name);
    _priceCtrl = TextEditingController(
      text: widget.facility.pricePerHour.toStringAsFixed(0),
    );
    _capCtrl = TextEditingController(
      text: widget.facility.capacity?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedTypeId == null) return;

    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client
          .from('facilities')
          .update({
            'name': _nameCtrl.text.trim(),
            'type_id': _selectedTypeId,
            'capacity': int.tryParse(_capCtrl.text),
            'price_per_hour': double.tryParse(_priceCtrl.text),
          })
          .eq('id', widget.facility.id);
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Update failed: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputStyle(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.inter(
      fontSize: 12.sp,
      color: const Color(0xFF6B7280),
    ),
    filled: true,
    fillColor: const Color(0xFFF0F2F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        'Edit Facility',
        style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF1A1D26)),
      ),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxWidth: 400.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: _inputStyle('Category / Type'),
                dropdownColor: Colors.white,
                iconEnabledColor: const Color(0xFF22C55E),
                isExpanded: true,
                items: widget.types
                    .map(
                      (t) => DropdownMenuItem(
                        value: t['id'] as int,
                        child: Text(
                          t['name'],
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1A1D26),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedTypeId = v),
                value: _selectedTypeId,
                validator: (v) => v == null ? 'Required' : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputStyle('Name (e.g. Picnic Area B)'),
                style: GoogleFonts.inter(color: const Color(0xFF1A1D26)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capCtrl,
                      decoration: _inputStyle('Capacity'),
                      style: GoogleFonts.inter(color: const Color(0xFF1A1D26)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: _inputStyle('Price/hr'),
                      style: GoogleFonts.inter(color: const Color(0xFF1A1D26)),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            disabledBackgroundColor: const Color(0xFF22C55E).withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Save Changes',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}
