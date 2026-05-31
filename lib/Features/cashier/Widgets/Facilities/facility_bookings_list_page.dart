// ignore_for_file: use_build_context_synchronously
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
  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFD1FAE5);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEE2E2);
  static const warn = Color(0xFFD97706);
  static const warnBg = Color(0xFFFEF3C7);
  static const info = Color(0xFF2563EB);
  static const infoBg = Color(0xFFDBEAFE);
}

// ─── MODEL ──────────────────────────────────────────────────────────────────
class _Booking {
  final int id;
  final int facilityId;
  final String facilityName;
  final String facilityType;
  final int? customerId;
  final String customerName;
  final String customerPhone;
  final DateTime startAt; // local
  final DateTime endAt; // local
  final String status;
  final double totalCost;

  _Booking({
    required this.id,
    required this.facilityId,
    required this.facilityName,
    required this.facilityType,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.totalCost,
  });

  Duration get duration => endAt.difference(startAt);

  /// True if start and end are on the same local calendar day.
  bool get sameDay =>
      startAt.year == endAt.year &&
      startAt.month == endAt.month &&
      startAt.day == endAt.day;

  String _two(int n) => n.toString().padLeft(2, '0');

  String _hm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

  String _md(DateTime t) => '${_monthAbbr(t.month)} ${t.day}'; // e.g. "May 28"

  String get timeRange {
    if (sameDay) return '${_hm(startAt)} – ${_hm(endAt)}';
    // Overnight / multi-day booking
    return '${_md(startAt)} ${_hm(startAt)} → ${_md(endAt)} ${_hm(endAt)}';
  }

  static String _monthAbbr(int m) => const [
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
  ][m - 1];
}

// ─── PAGE ───────────────────────────────────────────────────────────────────
class FacilityBookingsListPage extends StatefulWidget {
  const FacilityBookingsListPage({super.key});

  @override
  State<FacilityBookingsListPage> createState() =>
      _FacilityBookingsListPageState();
}

class _FacilityBookingsListPageState extends State<FacilityBookingsListPage> {
  final _sb = Supabase.instance.client;
  DateTime _date = DateTime.now();
  String _statusFilter = 'all'; // all|confirmed|cancelled|completed|no_show
  List<_Booking> _bookings = [];
  Set<int> _conflictIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _dateStr =>
      '${_date.year}-${_two(_date.month)}-${_two(_date.day)}';

  /// Local midnight at the start of the selected date.
  DateTime get _dayStart => DateTime(_date.year, _date.month, _date.day);

  /// Local midnight at the start of the day AFTER the selected date.
  DateTime get _dayEnd => _dayStart.add(const Duration(days: 1));

  // ─── LOAD ─────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch any booking that OVERLAPS with the selected day:
      //   start_at < dayEnd  AND  end_at > dayStart
      // This naturally includes overnight cabin bookings.
      final rows = await _sb
          .from('facility_bookings')
          .select(
            'id, start_at, end_at, status, total_cost, '
            'facilities(id, name, facility_types(name)), '
            'customers(id, name, phone)',
          )
          .lt('start_at', _dayEnd.toUtc().toIso8601String())
          .gt('end_at', _dayStart.toUtc().toIso8601String())
          .order('start_at');

      final list = (rows as List).map<_Booking>((r) {
        final f = r['facilities'];
        final fMap = f is Map ? f : (f is List && f.isNotEmpty ? f.first : {});
        final ft = fMap['facility_types'];
        final ftMap = ft is Map
            ? ft
            : (ft is List && ft.isNotEmpty ? ft.first : {});

        final c = r['customers'];
        final cMap = c is Map ? c : (c is List && c.isNotEmpty ? c.first : {});

        return _Booking(
          id: (r['id'] as num).toInt(),
          facilityId: (fMap['id'] as num?)?.toInt() ?? 0,
          facilityName: fMap['name'] as String? ?? 'Unknown facility',
          facilityType: ftMap['name'] as String? ?? 'Other',
          customerId: (cMap['id'] as num?)?.toInt(),
          customerName: cMap['name'] as String? ?? 'Walk-in',
          customerPhone: cMap['phone'] as String? ?? '',
          startAt: DateTime.parse(r['start_at'] as String).toLocal(),
          endAt: DateTime.parse(r['end_at'] as String).toLocal(),
          status: r['status'] as String? ?? 'confirmed',
          totalCost: (r['total_cost'] as num?)?.toDouble() ?? 0,
        );
      }).toList();

      // Sort: by start time, tiebreak by facility name.
      list.sort((a, b) {
        final t = a.startAt.compareTo(b.startAt);
        return t != 0 ? t : a.facilityName.compareTo(b.facilityName);
      });

      _bookings = list;
      _conflictIds = _detectConflicts(list);
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ─── CONFLICT DETECTION ───────────────────────────────────────────────────
  // Two confirmed bookings on the same facility conflict if their
  // [start, end) ranges overlap: a.start < b.end AND b.start < a.end.
  Set<int> _detectConflicts(List<_Booking> all) {
    final byFacility = <int, List<_Booking>>{};
    for (final b in all) {
      if (b.status != 'confirmed') continue;
      byFacility.putIfAbsent(b.facilityId, () => []).add(b);
    }
    final conflicts = <int>{};
    byFacility.forEach((_, list) {
      for (int i = 0; i < list.length; i++) {
        for (int j = i + 1; j < list.length; j++) {
          final a = list[i];
          final b = list[j];
          if (a.startAt.isBefore(b.endAt) && b.startAt.isBefore(a.endAt)) {
            conflicts.add(a.id);
            conflicts.add(b.id);
          }
        }
      }
    });
    return conflicts;
  }

  // ─── ACTIONS ──────────────────────────────────────────────────────────────
  Future<void> _cancelBooking(_Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Cancel booking?',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _T.ink,
          ),
        ),
        content: Text(
          '${b.facilityName} @ ${b.timeRange} for ${b.customerName}',
          style: GoogleFonts.inter(fontSize: 13, color: _T.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _T.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _sb
          .from('facility_bookings')
          .update({'status': 'cancelled'})
          .eq('id', b.id);
      HapticFeedback.mediumImpact();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: _T.danger),
      );
    }
  }

  Future<void> _markCompleted(_Booking b) async {
    try {
      await _sb
          .from('facility_bookings')
          .update({'status': 'completed'})
          .eq('id', b.id);
      HapticFeedback.lightImpact();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: _T.danger),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
    if (picked != null && picked != _date) {
      setState(() => _date = picked);
      _load();
    }
  }

  void _shiftDate(int days) {
    setState(() => _date = _date.add(Duration(days: days)));
    _load();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  List<_Booking> get _filtered {
    if (_statusFilter == 'all') return _bookings;
    return _bookings.where((b) => b.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final conflicts = _conflictIds.length;
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.surface,
        elevation: 0,
        title: Text(
          'Facility Bookings',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _T.ink,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: _T.ink),
        shape: const Border(bottom: BorderSide(color: _T.line)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          _dateBar(),
          if (conflicts > 0) _conflictBanner(conflicts),
          _filterChips(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _dateBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    color: _T.surface,
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => _shiftDate(-1),
          color: _T.ink2,
        ),
        Expanded(
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _T.primaryL,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _T.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: _T.primaryD,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _humanDate(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _T.primaryD,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () => _shiftDate(1),
          color: _T.ink2,
        ),
      ],
    ),
  );

  String _humanDate() {
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    final d = DateTime(_date.year, _date.month, _date.day);
    final diff = d.difference(t).inDays;
    if (diff == 0) return 'Today • $_dateStr';
    if (diff == 1) return 'Tomorrow • $_dateStr';
    if (diff == -1) return 'Yesterday • $_dateStr';
    return _dateStr;
  }

  Widget _conflictBanner(int n) => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _T.dangerBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _T.danger.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: _T.danger, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$n booking${n == 1 ? '' : 's'} in conflict — same facility, overlapping times',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _T.danger,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _filterChips() {
    final filters = <(String id, String label, IconData icon, Color color)>[
      ('all', 'All', Icons.list_alt_rounded, _T.muted),
      ('confirmed', 'Confirmed', Icons.check_circle_outline, _T.success),
      ('completed', 'Completed', Icons.task_alt_rounded, _T.info),
      ('cancelled', 'Cancelled', Icons.cancel_outlined, _T.danger),
      ('no_show', 'No-show', Icons.person_off_outlined, _T.warn),
    ];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: filters.length,
        itemBuilder: (c, i) {
          final f = filters[i];
          final sel = _statusFilter == f.$1;
          final count = f.$1 == 'all'
              ? _bookings.length
              : _bookings.where((b) => b.status == f.$1).length;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _statusFilter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: sel ? f.$4 : _T.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? f.$4 : _T.line),
                ),
                child: Row(
                  children: [
                    Icon(f.$3, size: 14, color: sel ? Colors.white : f.$4),
                    const SizedBox(width: 6),
                    Text(
                      '${f.$2} ($count)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : _T.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _T.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _T.danger, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: _T.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _T.primary),
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_rounded, size: 56, color: _T.muted2),
              const SizedBox(height: 12),
              Text(
                _statusFilter == 'all'
                    ? 'No bookings on this date'
                    : 'No "$_statusFilter" bookings',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _T.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _T.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (c, i) => _bookingCard(list[i]),
      ),
    );
  }

  // ─── CARD ─────────────────────────────────────────────────────────────────
  Widget _bookingCard(_Booking b) {
    final isConflict = _conflictIds.contains(b.id);
    final (
      Color statusColor,
      Color statusBg,
      String statusLabel,
    ) = switch (b.status) {
      'confirmed' => (_T.success, _T.successBg, 'Confirmed'),
      'completed' => (_T.info, _T.infoBg, 'Completed'),
      'cancelled' => (_T.danger, _T.dangerBg, 'Cancelled'),
      'no_show' => (_T.warn, _T.warnBg, 'No-show'),
      _ => (_T.muted, _T.surfaceAlt, b.status),
    };
    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConflict ? _T.danger : _T.line,
          width: isConflict ? 2 : 1,
        ),
        boxShadow: isConflict
            ? [
                BoxShadow(
                  color: _T.danger.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: time + status
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: _T.primaryD),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    b.timeRange,
                    style: GoogleFonts.inter(
                      fontSize: b.sameDay ? 15 : 13,
                      fontWeight: FontWeight.w800,
                      color: _T.ink,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!b.sameDay) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _T.infoBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'OVERNIGHT',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _T.info,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                if (isConflict) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _T.dangerBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _T.danger.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 11,
                          color: _T.danger,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'CONFLICT',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: _T.danger,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Facility
            Row(
              children: [
                const Icon(Icons.apartment_rounded, size: 15, color: _T.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${b.facilityName}  ·  ${b.facilityType}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _T.ink2,
                    ),
                  ),
                ),
                Text(
                  '\$${b.totalCost.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _T.primaryD,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Customer
            Row(
              children: [
                const Icon(Icons.person_rounded, size: 15, color: _T.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    b.customerName +
                        (b.customerPhone.isNotEmpty
                            ? '  ·  ${b.customerPhone}'
                            : ''),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _T.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            // Actions (only when confirmed)
            if (b.status == 'confirmed') ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: _T.line),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _T.danger,
                        side: BorderSide(
                          color: _T.danger.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => _cancelBooking(b),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _T.success,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(
                        'Mark Done',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => _markCompleted(b),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
