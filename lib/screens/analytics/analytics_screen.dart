import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smart_plant_care/services/plant_service.dart';

// ================================================================
// DESIGN CONSTANTS (match project visual identity)
// ================================================================

const Color _kPrimary = Color(0xFF134E39);
const Color _kBackground = Color(0xFFF4F7F5);
const Color _kSurface = Colors.white;
const Color _kSoftGreen = Color(0xFFE7F3ED);
const Color _kAmber = Color(0xFFE08C0B);
const Color _kRed = Color(0xFFD64545);

// ================================================================
// TIME RANGE ENUM
// ================================================================

enum _AnalyticsRange { hours24, days7, days30 }

extension _AnalyticsRangeX on _AnalyticsRange {
  String get label {
    switch (this) {
      case _AnalyticsRange.hours24:
        return '24 Hours';
      case _AnalyticsRange.days7:
        return '7 Days';
      case _AnalyticsRange.days30:
        return '30 Days';
    }
  }

  IconData get icon {
    switch (this) {
      case _AnalyticsRange.hours24:
        return Icons.schedule;
      case _AnalyticsRange.days7:
        return Icons.date_range_outlined;
      case _AnalyticsRange.days30:
        return Icons.calendar_month_outlined;
    }
  }

  Duration get duration {
    switch (this) {
      case _AnalyticsRange.hours24:
        return const Duration(hours: 24);
      case _AnalyticsRange.days7:
        return const Duration(days: 7);
      case _AnalyticsRange.days30:
        return const Duration(days: 30);
    }
  }
}

// ================================================================
// ENTRANCE ANIMATION WRAPPER
// ================================================================

class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ================================================================
// ANALYTICS SCREEN
// ================================================================

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final PlantService _plantService = PlantService();

  /// Raw logs fetched once from Firebase (unsorted, unfiltered).
  List<Map<String, dynamic>> _rawLogs = const [];

  /// Currently selected time range.
  _AnalyticsRange _selectedRange = _AnalyticsRange.hours24;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  // ============================================================
  // LOAD HISTORICAL DATA — single fetch, limitToLast(500)
  // ============================================================

  Future<void> _loadLogs() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Map<String, dynamic>> logs =
          await _plantService.fetchRecentLogs(limit: 500);

      if (!mounted) return;

      setState(() {
        _rawLogs = logs;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'We could not load your historical data. Please check your '
            'connection and try again.';
      });
    }
  }

  // ============================================================
  // VALUE HELPERS
  // ============================================================

  double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString());
  }

  dynamic _getValue(Map<String, dynamic> log, String key) {
    if (log.containsKey(key)) return log[key];

    final String lowerKey = key.toLowerCase();
    for (final entry in log.entries) {
      if (entry.key.toLowerCase() == lowerKey) return entry.value;
    }
    return null;
  }

  // ============================================================
  // TIMESTAMP PARSER — ms primary, seconds + ISO fallback
  // All timestamps normalized to local time.
  // ============================================================

  DateTime? _getTimestamp(Map<String, dynamic> log) {
    final dynamic value = _getValue(log, 'Timestamp');
    if (value == null) return null;

    if (value is num) {
      final number = value.toInt();

      if (number > 100000000000) {
        // Unix milliseconds (primary)
        return DateTime.fromMillisecondsSinceEpoch(number).toLocal();
      }
      if (number > 1000000000) {
        // Unix seconds (fallback)
        return DateTime.fromMillisecondsSinceEpoch(number * 1000).toLocal();
      }
    }

    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Unknown time';
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$d/$mo/${local.year} $h:$mi';
  }

  String _formatDay(DateTime? dt) {
    if (dt == null) return '--';
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$d/$mo';
  }

  // ============================================================
  // SOIL STATUS NORMALIZATION
  // ============================================================

  String _normalizeSoilStatus(dynamic raw) {
    final String value = raw?.toString().trim().toUpperCase() ?? '';

    switch (value) {
      case 'DRY':
        return 'DRY';
      case 'MOIST':
        return 'MOIST';
      case 'NORMAL':
        return 'NORMAL';
      case 'WET':
        return 'WET';
      default:
        return 'UNKNOWN';
    }
  }

  // ============================================================
  // RANGE FILTERING + CHRONOLOGICAL SORT
  // ============================================================

  List<Map<String, dynamic>> _filteredLogs() {
    if (_rawLogs.isEmpty) return const [];

    final cutoff = DateTime.now().subtract(_selectedRange.duration);

    final filtered = _rawLogs.where((log) {
      final ts = _getTimestamp(log);
      if (ts == null) return false;
      return ts.isAfter(cutoff);
    }).toList();

    filtered.sort((a, b) {
      final ta = _getTimestamp(a);
      final tb = _getTimestamp(b);

      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;

      return ta.compareTo(tb);
    });

    return filtered;
  }

  int _countInRange(_AnalyticsRange range) {
    if (_rawLogs.isEmpty) return 0;

    final cutoff = DateTime.now().subtract(range.duration);
    int count = 0;

    for (final log in _rawLogs) {
      final ts = _getTimestamp(log);
      if (ts != null && ts.isAfter(cutoff)) count++;
    }

    return count;
  }

  // ============================================================
  // SUMMARY STATISTICS
  // ============================================================

  double? _avgField(List<Map<String, dynamic>> logs, String field) {
    if (logs.isEmpty) return null;

    double sum = 0;
    int n = 0;

    for (final log in logs) {
      final v = _toNullableDouble(_getValue(log, field));
      if (v != null) {
        sum += v;
        n++;
      }
    }

    if (n == 0) return null;
    return sum / n;
  }

  int _countValid(List<Map<String, dynamic>> logs, String field) {
    int n = 0;
    for (final log in logs) {
      if (_toNullableDouble(_getValue(log, field)) != null) n++;
    }
    return n;
  }

  int _countSoilStatus(List<Map<String, dynamic>> logs, String status) {
    int n = 0;
    for (final log in logs) {
      final normalized =
          _normalizeSoilStatus(_getValue(log, 'SoilStatus'));
      if (normalized == status) n++;
    }
    return n;
  }

  // ============================================================
  // SOIL DISTRIBUTION — every distinct label preserved
  // ============================================================

  Map<String, int> _soilDistribution(List<Map<String, dynamic>> logs) {
    final counts = <String, int>{
      'DRY': 0,
      'MOIST': 0,
      'NORMAL': 0,
      'WET': 0,
      'UNKNOWN': 0,
    };

    for (final log in logs) {
      final normalized =
          _normalizeSoilStatus(_getValue(log, 'SoilStatus'));
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }

    return counts;
  }

  // ============================================================
  // CHART DATA — real spots only
  // ============================================================

  List<FlSpot> _createSpots(
    List<Map<String, dynamic>> logs,
    String field,
  ) {
    final spots = <FlSpot>[];

    for (final log in logs) {
      final dt = _getTimestamp(log);
      final value = _toNullableDouble(_getValue(log, field));
      if (dt == null || value == null) continue;

      spots.add(
        FlSpot(dt.millisecondsSinceEpoch.toDouble(), value),
      );
    }

    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  ({double min, double max, double interval}) _adaptiveYAxis(
    List<FlSpot> spots,
  ) {
    if (spots.isEmpty) {
      return (min: 0, max: 10, interval: 2);
    }

    double dataMin = spots.first.y;
    double dataMax = spots.first.y;

    for (final s in spots) {
      if (s.y < dataMin) dataMin = s.y;
      if (s.y > dataMax) dataMax = s.y;
    }

    if ((dataMax - dataMin).abs() < 1e-6) {
      final mid = dataMax;
      final pad = mid.abs() < 1 ? 1.0 : mid.abs() * 0.05;
      dataMin = mid - pad;
      dataMax = mid + pad;
    }

    final double rawRange = dataMax - dataMin;
    final double step = _niceStep(rawRange, targetTicks: 4);

    final double niceMin = (dataMin / step).floorToDouble() * step;
    final double niceMax = (dataMax / step).ceilToDouble() * step;

    if (niceMax - niceMin < 1e-9) {
      return (min: niceMin, max: niceMin + step, interval: step);
    }

    return (min: niceMin, max: niceMax, interval: step);
  }

  double _niceStep(double range, {int targetTicks = 4}) {
    if (range <= 0 || !range.isFinite) return 1;

    final double rawStep = range / targetTicks;
    final double magnitude =
        math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
    final double residual = rawStep / magnitude;

    double niceResidual;
    if (residual <= 1) {
      niceResidual = 1;
    } else if (residual <= 2) {
      niceResidual = 2;
    } else if (residual <= 5) {
      niceResidual = 5;
    } else {
      niceResidual = 10;
    }

    return niceResidual * magnitude;
  }

  double _bottomIntervalMs(
    List<FlSpot> spots,
    _AnalyticsRange range,
  ) {
    if (spots.length < 2) {
      switch (range) {
        case _AnalyticsRange.hours24:
          return 6 * 60 * 60 * 1000;
        case _AnalyticsRange.days7:
          return 24 * 60 * 60 * 1000;
        case _AnalyticsRange.days30:
          return 5 * 24 * 60 * 60 * 1000;
      }
    }

    final double spanMs = spots.last.x - spots.first.x;
    if (spanMs <= 0) {
      switch (range) {
        case _AnalyticsRange.hours24:
          return 6 * 60 * 60 * 1000;
        case _AnalyticsRange.days7:
          return 24 * 60 * 60 * 1000;
        case _AnalyticsRange.days30:
          return 5 * 24 * 60 * 60 * 1000;
      }
    }

    final double targetTicks = 5.0;
    final double rawStep = spanMs / targetTicks;

    const double minute = 60 * 1000;
    const double hour = 60 * minute;
    const double day = 24 * hour;

    if (rawStep <= 15 * minute) return 15 * minute;
    if (rawStep <= 30 * minute) return 30 * minute;
    if (rawStep <= hour) return hour;
    if (rawStep <= 2 * hour) return 2 * hour;
    if (rawStep <= 3 * hour) return 3 * hour;
    if (rawStep <= 6 * hour) return 6 * hour;
    if (rawStep <= 12 * hour) return 12 * hour;
    if (rawStep <= day) return day;
    if (rawStep <= 2 * day) return 2 * day;
    if (rawStep <= 5 * day) return 5 * day;
    if (rawStep <= 7 * day) return 7 * day;
    if (rawStep <= 14 * day) return 14 * day;
    return 30 * day;
  }

  String _formatYLabel(double value, String field) {
    if (field == 'LightIntensity') {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 8),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A6B4E),
                _kPrimary,
                Color(0xFF0D3A2A),
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Analytics',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: _isLoading
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        _loadLogs();
                      },
                icon: AnimatedRotation(
                  turns: _isLoading ? 0.5 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: const Icon(Icons.refresh),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState();

    if (_rawLogs.isEmpty) {
      return RefreshIndicator(
        color: _kPrimary,
        onRefresh: _loadLogs,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _buildEmptyState(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _loadLogs,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FadeSlideIn(child: _buildHeader()),
            const SizedBox(height: 18),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: _buildRangeSelector(),
            ),
            const SizedBox(height: 18),
            ..._buildRangeContent(),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Data source: SmartPlant/Logs',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final int countInRange = _countInRange(_selectedRange);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Plant Analytics',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Container(
                key: ValueKey('$countInRange-${_selectedRange.name}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _kSoftGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.dataset_outlined,
                      size: 12,
                      color: _kPrimary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$countInRange readings',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Historical sensor insights from your Smart Plant Care device',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RANGE SELECTOR
  // ============================================================

  Widget _buildRangeSelector() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: _AnalyticsRange.values.map((range) {
          final bool isSelected = range == _selectedRange;
          final int count = _countInRange(range);
          final bool isEnabled = count >= 1;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _rangeChip(
              label: range.label,
              icon: range.icon,
              selected: isSelected,
              enabled: isEnabled,
              onTap: isEnabled
                  ? () {
                      if (range == _selectedRange) return;
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedRange = range;
                      });
                    }
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _rangeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final Color bg = !enabled
        ? Colors.grey.shade200
        : selected
            ? _kPrimary
            : Colors.white;

    final Color fg = !enabled
        ? Colors.grey.shade500
        : selected
            ? Colors.white
            : _kPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected && enabled
                  ? _kPrimary
                  : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: selected && enabled
                ? [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RANGE CONTENT
  // ============================================================

  List<Widget> _buildRangeContent() {
    final logs = _filteredLogs();

    if (logs.isEmpty) {
      return [
        const SizedBox(height: 40),
        _buildInfoCard(
          title: 'No readings in this range',
          subtitle:
              'Try a different time range or refresh to see the latest data.',
        ),
        const SizedBox(height: 40),
      ];
    }

    return [
      _FadeSlideIn(
        delay: const Duration(milliseconds: 120),
        child: _buildLatestReading(logs),
      ),
      const SizedBox(height: 12),
      _FadeSlideIn(
        delay: const Duration(milliseconds: 160),
        child: _buildContextRow(logs),
      ),
      const SizedBox(height: 22),
      _FadeSlideIn(
        delay: const Duration(milliseconds: 200),
        child: _buildSectionTitle('Summary Statistics', icon: Icons.insights_outlined),
      ),
      const SizedBox(height: 12),
      _FadeSlideIn(
        delay: const Duration(milliseconds: 240),
        child: _buildSummaryGrid(logs),
      ),
      const SizedBox(height: 24),
      _FadeSlideIn(
        delay: const Duration(milliseconds: 280),
        child: _buildChartSection(
          title: 'Temperature Trend',
          unit: '°C',
          field: 'Temperature',
          icon: Icons.thermostat_outlined,
          accent: Colors.orange,
          logs: logs,
        ),
      ),
      const SizedBox(height: 18),
      _FadeSlideIn(
        delay: const Duration(milliseconds: 320),
        child: _buildChartSection(
          title: 'Humidity Trend',
          unit: '%',
          field: 'Humidity',
          icon: Icons.water_drop_outlined,
          accent: Colors.blue,
          logs: logs,
        ),
      ),
      const SizedBox(height: 18),
      _FadeSlideIn(
        delay: const Duration(milliseconds: 360),
        child: _buildChartSection(
          title: 'Light Intensity Trend',
          unit: 'ADC',
          field: 'LightIntensity',
          icon: Icons.wb_sunny_outlined,
          accent: _kAmber,
          logs: logs,
        ),
      ),
      const SizedBox(height: 24),
      _FadeSlideIn(
        delay: const Duration(milliseconds: 400),
        child: _buildSoilDistributionCard(logs),
      ),
      const SizedBox(height: 18),
      _FadeSlideIn(
        delay: const Duration(milliseconds: 440),
        child: _buildWateringInfoCard(),
      ),
      const SizedBox(height: 18),
      _FadeSlideIn(
        delay: const Duration(milliseconds: 480),
        child: _buildRecentSoilReadings(logs),
      ),
    ];
  }

  Widget _buildSectionTitle(String text, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kSoftGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: _kPrimary),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LATEST READING HERO
  // ============================================================

  Widget _buildLatestReading(List<Map<String, dynamic>> logs) {
    final latest = logs.last;

    final double? temperature =
        _toNullableDouble(_getValue(latest, 'Temperature'));
    final double? humidity =
        _toNullableDouble(_getValue(latest, 'Humidity'));
    final double? light =
        _toNullableDouble(_getValue(latest, 'LightIntensity'));

    final String soil =
        _normalizeSoilStatus(_getValue(latest, 'SoilStatus'));

    final DateTime? ts = _getTimestamp(latest);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A6B4E),
            _kPrimary,
            Color(0xFF0D3A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sensors,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Latest Reading',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  _formatDateTime(ts),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _latestTile(
                icon: Icons.thermostat,
                label: 'Temperature',
                value: temperature != null
                    ? temperature.toStringAsFixed(1)
                    : '--',
                unit: '°C',
              ),
              _latestTile(
                icon: Icons.water_drop,
                label: 'Humidity',
                value: humidity != null
                    ? humidity.toStringAsFixed(1)
                    : '--',
                unit: '%',
              ),
              _latestTile(
                icon: Icons.wb_sunny,
                label: 'Light',
                value: light != null ? light.toStringAsFixed(0) : '--',
                unit: 'ADC',
              ),
              _latestTile(
                icon: Icons.grass,
                label: 'Soil',
                value: soil,
                unit: '',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _latestTile({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTEXT ROW (compact factual info)
  // ============================================================

  Widget _buildContextRow(List<Map<String, dynamic>> logs) {
    final int total = logs.length;
    final int nTemp = _countValid(logs, 'Temperature');
    final int nHumid = _countValid(logs, 'Humidity');

    final DateTime? latestTs =
        logs.isNotEmpty ? _getTimestamp(logs.last) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          _contextItem(
            Icons.dataset_outlined,
            'Total readings: $total',
          ),
          _contextItem(
            Icons.thermostat_outlined,
            'Valid Temp: $nTemp',
          ),
          _contextItem(
            Icons.water_drop_outlined,
            'Valid Humidity: $nHumid',
          ),
          _contextItem(
            Icons.schedule,
            'Latest: ${_formatDateTime(latestTs)}',
          ),
        ],
      ),
    );
  }

  Widget _contextItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _kPrimary),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY GRID
  // ============================================================

  Widget _buildSummaryGrid(List<Map<String, dynamic>> logs) {
    final double? avgTemp = _avgField(logs, 'Temperature');
    final double? avgHumid = _avgField(logs, 'Humidity');
    final int nTemp = _countValid(logs, 'Temperature');
    final int nHumid = _countValid(logs, 'Humidity');
    final int dryCount = _countSoilStatus(logs, 'DRY');
    final int total = logs.length;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _summaryCard(
          icon: Icons.thermostat_outlined,
          iconColor: Colors.orange,
          title: 'Avg Temperature',
          value: avgTemp != null ? avgTemp.toStringAsFixed(1) : '--',
          unit: '°C',
          subtitle: nTemp > 0 ? 'n = $nTemp' : 'No readings',
        ),
        _summaryCard(
          icon: Icons.water_drop_outlined,
          iconColor: Colors.blue,
          title: 'Avg Humidity',
          value: avgHumid != null ? avgHumid.toStringAsFixed(1) : '--',
          unit: '%',
          subtitle: nHumid > 0 ? 'n = $nHumid' : 'No readings',
        ),
        _summaryCard(
          icon: Icons.grass_outlined,
          iconColor: _kAmber,
          title: 'Dry Records',
          value: total > 0 ? '$dryCount / $total' : '--',
          unit: '',
          subtitle: total > 0
              ? '${(dryCount / total * 100).toStringAsFixed(1)}% of all records'
              : 'No readings',
        ),
        _summaryCard(
          icon: Icons.dataset_outlined,
          iconColor: _kPrimary,
          title: 'Total Readings',
          value: '$total',
          unit: '',
          subtitle: 'Selected range',
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHART SECTION
  // ============================================================

  Widget _buildChartSection({
    required String title,
    required String unit,
    required String field,
    required IconData icon,
    required Color accent,
    required List<Map<String, dynamic>> logs,
  }) {
    final List<FlSpot> spots = _createSpots(logs, field);

    if (spots.length < 2) {
      return _chartInsufficientCard(
        title: title,
        icon: icon,
        accent: accent,
        spotsCount: spots.length,
      );
    }

    final axis = _adaptiveYAxis(spots);
    final double bottomInterval =
        _bottomIntervalMs(spots, _selectedRange);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                minY: axis.min,
                maxY: axis.max,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: axis.interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: axis.interval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatYLabel(value, field),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: bottomInterval,
                      getTitlesWidget: (value, meta) {
                        final dt = DateTime
                            .fromMillisecondsSinceEpoch(value.toInt())
                            .toLocal();

                        final label =
                            _selectedRange == _AnalyticsRange.hours24
                                ? _formatTime(dt)
                                : _formatDay(dt);

                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => _kPrimary,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final dt = DateTime
                            .fromMillisecondsSinceEpoch(spot.x.toInt())
                            .toLocal();

                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} $unit\n'
                          '${_formatDateTime(dt)}',
                          GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    barWidth: 2.4,
                    color: accent,
                    dotData: FlDotData(show: spots.length <= 20),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.22),
                          accent.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartInsufficientCard({
    required String title,
    required IconData icon,
    required Color accent,
    required int spotsCount,
  }) {
    final String explanation = spotsCount == 0
        ? 'No valid readings of this metric are present in the selected range.'
        : 'Only $spotsCount valid reading${spotsCount == 1 ? '' : 's'} in '
            'the selected range. At least 2 valid readings are required to '
            'display a trend.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Not enough historical data for a trend',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  explanation,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SOIL STATUS DISTRIBUTION
  // ============================================================

  Widget _buildSoilDistributionCard(List<Map<String, dynamic>> logs) {
    final dist = _soilDistribution(logs);
    final total = logs.length;

    const orderedLabels = ['DRY', 'MOIST', 'NORMAL', 'WET', 'UNKNOWN'];
    final presentLabels = orderedLabels
        .where((label) => (dist[label] ?? 0) > 0)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.grass_outlined,
                  color: _kPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Soil Status Distribution',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _kSoftGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'n = $total',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: _kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Distribution of SoilStatus values recorded in this range.',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 14),
          if (presentLabels.isEmpty)
            Text(
              'No soil readings in this range.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            )
          else
            ...presentLabels.map(
              (label) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _soilBar(
                  label,
                  dist[label] ?? 0,
                  total,
                  _soilBarColor(label),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _soilBarColor(String label) {
    switch (label) {
      case 'DRY':
        return _kAmber;
      case 'MOIST':
        return _kPrimary;
      case 'NORMAL':
        return const Color(0xFF2F8F5B);
      case 'WET':
        return Colors.blue;
      default:
        return Colors.grey.shade500;
    }
  }

  Widget _soilBar(String label, int count, int total, Color color) {
    final double pct = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              child: Text(
                '${(pct * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: 8,
                color: color.withValues(alpha: 0.12),
              ),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
                builder: (context, animValue, child) {
                  return FractionallySizedBox(
                    widthFactor: animValue,
                    child: Container(height: 8, color: color),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WATERING INFO — neutral info card
  // ============================================================

  Widget _buildWateringInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kSoftGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: _kPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Watering Statistics',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pump events are not currently included in SmartPlant/Logs, '
                  'so historical irrigation statistics cannot be calculated.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT SOIL READINGS
  // ============================================================

  Widget _buildRecentSoilReadings(List<Map<String, dynamic>> logs) {
    final recent = logs.reversed.take(10).toList();

    if (recent.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history_outlined,
                  color: _kPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recent Soil Readings',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _kSoftGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'latest ${recent.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: _kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...recent.asMap().entries.map((entry) {
            final int index = entry.key;
            final log = entry.value;

            final soil =
                _normalizeSoilStatus(_getValue(log, 'SoilStatus'));
            final dt = _getTimestamp(log);
            final bool isLast = index == recent.length - 1;

            return _recentRow(
              soil: soil,
              dt: dt,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _recentRow({
    required String soil,
    required DateTime? dt,
    required bool isLast,
  }) {
    final Color color = _soilColor(soil);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + connector
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: color, width: 2.5),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          soil,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _soilMessage(soil),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(dt),
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _soilMessage(String soil) {
    switch (soil) {
      case 'DRY':
        return 'Needs Water';
      case 'MOIST':
      case 'NORMAL':
        return 'Healthy';
      case 'WET':
        return 'Well Watered';
      default:
        return 'Unknown';
    }
  }

  Color _soilColor(String soil) {
    switch (soil) {
      case 'DRY':
        return _kAmber;
      case 'MOIST':
        return _kPrimary;
      case 'NORMAL':
        return const Color(0xFF2F8F5B);
      case 'WET':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // INFO CARD (generic neutral)
  // ============================================================

  Widget _buildInfoCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY / LOADING / ERROR
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _kSoftGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insert_chart_outlined,
                  color: _kPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No historical data yet',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Once your device starts recording sensor readings, '
                'analytics will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: _kSoftGreen,
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: _kPrimary,
                strokeWidth: 2.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading historical data…',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Preparing your plant analytics',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 36,
                color: _kRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load analytics',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                _loadLogs();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}