// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── DESIGN TOKENS ──────────────────────────────────────────────────────────
class _T {
  static const primary = Color(0xFFB8860B);
  static const primaryD = Color(0xFF8B6914);
  static const primaryL = Color(0xFFFFF7DB);
  static const bg = Color(0xFFFAFAF7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F5F0);
  static const ink = Color(0xFF0A0F0D);
  static const ink2 = Color(0xFF2D3438);
  static const muted = Color(0xFF64748B);
  static const muted2 = Color(0xFF94A3B8);
  static const line = Color(0xFFE5E7EB);
  static const lineSoft = Color(0xFFF1F2F4);
  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFD1FAE5);
  static const danger = Color(0xFFDC2626);
}

// ─── MODELS ─────────────────────────────────────────────────────────────────
class _Facility {
  final int id;
  final String name;
  final String typeName;
  final double pricePerHour;
  final int? capacity;
  _Facility({
    required this.id,
    required this.name,
    required this.typeName,
    required this.pricePerHour,
    this.capacity,
  });
}

class _Customer {
  final int id;
  final String name;
  final String phone;
  _Customer({required this.id, required this.name, required this.phone});
}

// ─── PAGE ───────────────────────────────────────────────────────────────────
class FacilitiesBookingPage extends StatefulWidget {
  const FacilitiesBookingPage({super.key});

  @override
  State<FacilitiesBookingPage> createState() => _FacilitiesBookingPageState();
}

class _FacilitiesBookingPageState extends State<FacilitiesBookingPage> {
  final _sb = Supabase.instance.client;

  // Data
  List<_Facility> _facilities = [];
  List<_Customer> _customers = [];
  Set<String> _types = {'All'};

  // Selection state
  _Facility? _facility;
  _Customer? _customer;
  String _typeFilter = 'All';
  DateTime _date = DateTime.now();
  TimeOfDay _checkIn = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: 0,
  );
  int _hours = 1; // 1-24

  bool _loading = true;
  bool _saving = false;
  String? _error;

  final double _exchangeRate = 90000.0; // LBP per USD —

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  TimeOfDay get _checkOut {
    final endHour = (_checkIn.hour + _hours) % 24;
    return TimeOfDay(hour: endHour, minute: _checkIn.minute);
  }

  bool get _isSameDay => (_checkIn.hour + _hours) <= 24;

  bool get _canConfirm =>
      _facility != null && _customer != null && _hours > 0 && _isSameDay;

  double get _totalUsd => (_facility?.pricePerHour ?? 0) * _hours;
  double get _totalLbp => _totalUsd * _exchangeRate;

  // ─── DATA LOAD ────────────────────────────────────────────────────────────
  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _sb
            .from('facilities')
            .select(
              'id, name, price_per_hour, capacity, is_available, '
              'facility_types(name)',
            )
            .eq('is_available', true)
            .order('name'),
        _sb
            .from('customers')
            .select('id, name, phone')
            .order('name')
            .limit(500),
      ]);

      final fRows = results[0] as List;
      final cRows = results[1] as List;

      _facilities = fRows.map((r) {
        final type = r['facility_types'];
        final typeName = type is Map
            ? (type['name'] as String? ?? 'Other')
            : (type is List && type.isNotEmpty
                  ? (type.first['name'] as String? ?? 'Other')
                  : 'Other');
        return _Facility(
          id: (r['id'] as num).toInt(),
          name: r['name'] as String? ?? 'Unnamed',
          typeName: typeName,
          pricePerHour: (r['price_per_hour'] as num?)?.toDouble() ?? 0,
          capacity: (r['capacity'] as num?)?.toInt(),
        );
      }).toList();

      _customers = cRows.map((r) {
        return _Customer(
          id: (r['id'] as num).toInt(),
          name: r['name'] as String? ?? 'Unnamed',
          phone: r['phone'] as String? ?? '',
        );
      }).toList();

      _types = {'All', ..._facilities.map((f) => f.typeName)};

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ─── CONFIRM ──────────────────────────────────────────────────────────────
  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _confirmBooking() async {
    if (!_canConfirm) {
      String msg = 'Please complete all fields';
      if (_facility == null) {
        msg = 'Please select a facility';
      } else if (_customer == null)
        msg = 'Customer is required';
      else if (!_isSameDay)
        msg = 'Booking must end same day (max 24h)';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: _T.danger));
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final bookingDate =
          '${_date.year}-${_two(_date.month)}-${_two(_date.day)}';
      final checkInStr = '${_two(_checkIn.hour)}:${_two(_checkIn.minute)}:00';
      final checkOutStr =
          '${_two(_checkOut.hour)}:${_two(_checkOut.minute)}:00';

      await _sb.from('facility_bookings').insert({
        'customer_id': _customer!.id,
        'facility_id': _facility!.id,
        'booking_date': bookingDate,
        'check_in_time': checkInStr,
        'check_out_time': checkOutStr,
        'status': 'confirmed',
        'total_cost': _totalUsd,
      });

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booked ${_facility!.name} for ${_customer!.name} '
            '@ $bookingDate ${checkInStr.substring(0, 5)}',
          ),
          backgroundColor: _T.success,
        ),
      );
      // Reset selection but keep filters
      setState(() {
        _facility = null;
        _customer = null;
        _hours = 1;
        _saving = false;
      });
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $e'),
          backgroundColor: _T.danger,
        ),
      );
    }
  }

  // ─── PICKERS ──────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _T.primary,
            onPrimary: Colors.white,
            onSurface: _T.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _checkIn,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _T.primary,
            onPrimary: Colors.white,
            onSurface: _T.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _checkIn = picked);
  }

  Future<void> _pickCustomer() async {
    final result = await showDialog<_Customer>(
      context: context,
      builder: (ctx) => _CustomerPickerDialog(customers: _customers),
    );
    if (result != null) setState(() => _customer = result);
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _T.bg,
        body: Center(child: CircularProgressIndicator(color: _T.primary)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: _T.bg,
        appBar: _appBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: _T.danger, size: 56),
                const SizedBox(height: 12),
                Text(
                  'Could not load: $_error',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: _T.muted),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _T.primary),
                  onPressed: _loadAll,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _typeFilter == 'All'
        ? _facilities
        : _facilities.where((f) => f.typeName == _typeFilter).toList();

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: _appBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (c, cons) {
            final isWide = cons.maxWidth >= 980;
            final main = _buildMain(filtered, cons.maxWidth);
            final summary = _buildSummary();
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: main),
                  Container(width: 1, color: _T.line),
                  SizedBox(width: 360, child: summary),
                ],
              );
            }
            return Column(
              children: [
                Expanded(child: main),
                Container(height: 1, color: _T.line),
                summary,
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: _T.surface,
    elevation: 0,
    title: Text(
      'Book a Facility',
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _T.ink,
        letterSpacing: -0.3,
      ),
    ),
    iconTheme: const IconThemeData(color: _T.ink),
    shape: const Border(bottom: BorderSide(color: _T.line, width: 1)),
  );

  // ─── MAIN COLUMN ──────────────────────────────────────────────────────────
  Widget _buildMain(List<_Facility> filtered, double w) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Type'),
          _typeChips(),
          const SizedBox(height: 20),
          _sectionTitle('Pick a facility'),
          const SizedBox(height: 8),
          _facilityGrid(filtered, w),
          const SizedBox(height: 24),
          _sectionTitle('Date & time'),
          const SizedBox(height: 8),
          _dateTimeRow(),
          const SizedBox(height: 12),
          _hoursStepper(),
          const SizedBox(height: 24),
          _sectionTitle('Customer'),
          const SizedBox(height: 8),
          _customerCard(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      s,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _T.muted,
        letterSpacing: 0.4,
      ),
    ),
  );

  Widget _typeChips() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _types.map((t) {
      final sel = _typeFilter == t;
      return GestureDetector(
        onTap: () => setState(() => _typeFilter = t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? _T.primary : _T.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? _T.primary : _T.line),
          ),
          child: Text(
            t,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: sel ? Colors.white : _T.ink2,
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _facilityGrid(List<_Facility> list, double w) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No facilities available',
            style: GoogleFonts.inter(color: _T.muted2, fontSize: 14),
          ),
        ),
      );
    }
    final cols = (w / 170).floor().clamp(2, 6);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (c, i) {
        final f = list[i];
        final sel = _facility?.id == f.id;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _facility = f);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sel ? _T.primaryL : _T.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? _T.primary : _T.line,
                width: sel ? 2 : 1,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: _T.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _T.surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        f.typeName,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _T.muted,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (sel)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: _T.primary,
                        size: 18,
                      ),
                  ],
                ),
                Text(
                  f.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _T.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  '\$${f.pricePerHour.toStringAsFixed(2)} / hr'
                  '${f.capacity != null ? ' • ${f.capacity} ppl' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _T.primaryD,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dateTimeRow() => Row(
    children: [
      Expanded(
        child: _pickerTile(
          icon: Icons.calendar_today_rounded,
          label: 'Date',
          value: '${_date.year}-${_two(_date.month)}-${_two(_date.day)}',
          onTap: _pickDate,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _pickerTile(
          icon: Icons.access_time_rounded,
          label: 'Check-in',
          value: _checkIn.format(context),
          onTap: _pickTime,
        ),
      ),
    ],
  );

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: _T.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _T.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _T.ink,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _T.muted2),
        ],
      ),
    ),
  );

  Widget _hoursStepper() {
    final overflow = !_isSameDay;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: overflow ? _T.danger : _T.line),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            color: overflow ? _T.danger : _T.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _T.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$_hours hour${_hours == 1 ? '' : 's'}'
                  ' → ends ${_checkOut.format(context)}'
                  '${overflow ? ' (next day — not supported)' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: overflow ? _T.danger : _T.ink,
                  ),
                ),
              ],
            ),
          ),
          _stepBtn(
            Icons.remove_rounded,
            () => setState(() => _hours = (_hours - 1).clamp(1, 24)),
          ),
          const SizedBox(width: 6),
          _stepBtn(
            Icons.add_rounded,
            () => setState(() => _hours = (_hours + 1).clamp(1, 24)),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _T.primaryL,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _T.primary.withValues(alpha: 0.4)),
      ),
      child: Icon(icon, size: 16, color: _T.primaryD),
    ),
  );

  Widget _customerCard() => InkWell(
    onTap: _pickCustomer,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _customer == null ? _T.surface : _T.successBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _customer == null ? _T.line : _T.success),
      ),
      child: Row(
        children: [
          Icon(
            _customer == null
                ? Icons.person_add_alt_1_rounded
                : Icons.person_rounded,
            color: _customer == null ? _T.muted : _T.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _customer == null
                      ? 'Select customer (required)'
                      : _customer!.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _customer == null ? _T.muted : _T.ink,
                  ),
                ),
                if (_customer != null && _customer!.phone.isNotEmpty)
                  Text(
                    _customer!.phone,
                    style: GoogleFonts.inter(fontSize: 12, color: _T.muted),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _T.muted2),
        ],
      ),
    ),
  );

  // ─── SUMMARY / CONFIRM ────────────────────────────────────────────────────
  Widget _buildSummary() {
    return Container(
      decoration: const BoxDecoration(
        color: _T.surface,
        border: Border(top: BorderSide(color: _T.line)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_T.primaryL, Color(0xFFFFEFC0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _T.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _summaryRow('Facility', _facility?.name ?? '—'),
                _summaryRow('Type', _facility?.typeName ?? '—'),
                _summaryRow(
                  'Date',
                  '${_date.year}-${_two(_date.month)}-${_two(_date.day)}',
                ),
                _summaryRow(
                  'Time',
                  '${_checkIn.format(context)} → ${_checkOut.format(context)}',
                ),
                _summaryRow('Duration', '$_hours h'),
                _summaryRow('Customer', _customer?.name ?? '— (required)'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: _T.line),
                ),
                Row(
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.ink2,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${_totalUsd.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _T.primaryD,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'LBP ${_totalLbp.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _T.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _canConfirm ? _T.success : _T.muted2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                _saving ? 'Saving…' : 'Confirm Booking',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              onPressed: _saving ? null : _confirmBooking,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            k,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _T.muted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _T.ink2,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── CUSTOMER PICKER DIALOG ─────────────────────────────────────────────────
class _CustomerPickerDialog extends StatefulWidget {
  final List<_Customer> customers;
  const _CustomerPickerDialog({required this.customers});

  @override
  State<_CustomerPickerDialog> createState() => _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends State<_CustomerPickerDialog> {
  String _q = '';
  late List<_Customer> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.customers;
  }

  void _onChanged(String s) {
    final q = s.toLowerCase().trim();
    setState(() {
      _q = q;
      _filtered = q.isEmpty
          ? widget.customers
          : widget.customers
                .where(
                  (c) =>
                      c.name.toLowerCase().contains(q) ||
                      c.phone.toLowerCase().contains(q),
                )
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        height: 540,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(
                    'Select Customer',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _T.ink,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name or phone…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: _T.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _q.isEmpty
                            ? 'No customers yet'
                            : 'No matches for "$_q"',
                        style: GoogleFonts.inter(color: _T.muted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: _T.lineSoft),
                      itemBuilder: (c, i) {
                        final cust = _filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _T.primaryL,
                            child: Text(
                              cust.name.isNotEmpty
                                  ? cust.name[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.inter(
                                color: _T.primaryD,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            cust.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: _T.ink,
                            ),
                          ),
                          subtitle: cust.phone.isEmpty
                              ? null
                              : Text(
                                  cust.phone,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: _T.muted,
                                  ),
                                ),
                          onTap: () => Navigator.pop(context, cust),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
