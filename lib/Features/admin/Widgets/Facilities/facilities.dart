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
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 48.h, 24.w, 20.h),
      color: Colors.white,
      child: Row(
        children: [
          Column(
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
              Text(
                'Park Areas & Assets',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'New Facility',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              elevation: 0,
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

    return GridView.builder(
      padding: EdgeInsets.all(24.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1100
            ? 4
            : (MediaQuery.of(context).size.width > 700 ? 3 : 2),
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 1.1,
      ),
      itemCount: _facilities.length,
      itemBuilder: (context, index) {
        final f = _facilities[index];
        return _FacilityCard(facility: f);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FACILITY CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _FacilityCard extends StatelessWidget {
  final Facility facility;
  const _FacilityCard({required this.facility});

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
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.bed, size: 18.sp, color: statusColor),
              ),
              _StatusBadge(isAvailable: facility.isAvailable),
            ],
          ),
          const Spacer(),
          Text(
            facility.name,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            facility.typeName,
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 11.sp),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoItem(
                label: 'CAPACITY',
                value: '${facility.capacity ?? "∞"}',
              ),
              _InfoItem(
                label: 'PRICE/HR',
                value: '\$${facility.pricePerHour.toStringAsFixed(0)}',
              ),
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
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        ),
      ],
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
      content: SizedBox(
        width: 400.w,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: _inputStyle('Category / Type'),
                dropdownColor: Colors.white,
                iconEnabledColor: const Color(0xFF22C55E),
                items: widget.types
                    .map(
                      (t) => DropdownMenuItem(
                        value: t['id'] as int,
                        child: Text(
                          t['name'],
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1A1D26),
                          ),
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
