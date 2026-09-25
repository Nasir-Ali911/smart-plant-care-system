import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smart_plant_care/screens/add_plant/add_plant_screen.dart';
import 'package:smart_plant_care/screens/analytics/analytics_screen.dart';
import 'package:smart_plant_care/screens/device_setup/device_setup_screen.dart';
import 'package:smart_plant_care/screens/notifications/notifications_screen.dart';
import 'package:smart_plant_care/screens/profile/profile_screen.dart';
import 'package:smart_plant_care/screens/plants/plants_screen.dart';

import 'package:smart_plant_care/services/plant_service.dart';
import 'package:smart_plant_care/services/ai_recommendation_service.dart';
import 'package:smart_plant_care/services/ai_forecast_service.dart';

import 'package:smart_plant_care/models/ai_forecast_model.dart';

import 'package:smart_plant_care/screens/dashboard/widgets/quick_action_card.dart';
import 'package:smart_plant_care/screens/dashboard/widgets/recent_activity_card.dart';
import 'package:smart_plant_care/screens/dashboard/widgets/sensor_card.dart';

// ================================================================
// LOCAL DESIGN CONSTANTS
// ================================================================

const Color _kPrimary = Color(0xFF134E39);
const Color _kBackground = Color(0xFFF4F7F5);
const Color _kSurface = Colors.white;
const Color _kSoftGreen = Color(0xFFE7F3ED);
const Color _kSoftGreenAlt = Color(0xFFF4F7F5);
const Color _kAmber = Color(0xFFE08C0B);
const Color _kRed = Color(0xFFD64545);

// ================================================================
// PRIVATE VIEW MODEL
// ================================================================

class _DashboardSnapshot {
  final double? temperature;
  final double? humidity;
  final double? lightIntensity;
  final String soilStatus;
  final bool deviceDataAvailable;
  final bool? pumpManual;
  final double dryDurationHours;
  final AIRecommendation? aiRecommendation;
  final List<_ActivityEntry> recentActivity;

  const _DashboardSnapshot({
    required this.temperature,
    required this.humidity,
    required this.lightIntensity,
    required this.soilStatus,
    required this.deviceDataAvailable,
    required this.pumpManual,
    required this.dryDurationHours,
    required this.aiRecommendation,
    required this.recentActivity,
  });
}

class _ActivityEntry {
  final String title;
  final String subtitle;
  final DateTime? timestamp;
  final IconData icon;
  final Color color;

  const _ActivityEntry({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}

// ================================================================
// ANIMATED ENTRANCE HELPER
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
      begin: const Offset(0, 0.06),
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
// DASHBOARD SCREEN
// ================================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PlantService _plantService = PlantService();

  // ==============================================================
  // FIREBASE REFERENCES
  // ==============================================================

  late final DatabaseReference _smartPlantRef;
  late final Query _logsQuery;

  // ==============================================================
  // AI FORECAST
  // ==============================================================

  late Future<AiForecastModel> _aiForecastFuture;

  // ==============================================================
  // UI STATE
  // ==============================================================

  int _currentIndex = 0;

  String _userName = 'User';

  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();

    _smartPlantRef = _database.ref('SmartPlant');

    // Realtime historical log query.
    //
    // Used for:
    // - dry-duration calculation
    // - recent activity
    // - AI recommendation context
    _logsQuery = _database.ref('SmartPlant/Logs').limitToLast(1500);

    // ------------------------------------------------------------
    // AI Soil Forecast
    //
    // IMPORTANT:
    // Keep the Future in State instead of calling the API inside
    // build(). Firebase stream rebuilds must not trigger repeated
    // HTTP requests.
    // ------------------------------------------------------------
    _aiForecastFuture = AiForecastService.getForecast();

    _loadUserProfile();
  }

  // ==============================================================
  // USER PROFILE
  // ==============================================================

  Future<void> _loadUserProfile() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _userName = 'User';
          _isLoadingProfile = false;
        });

        return;
      }

      String name = '';

      // ------------------------------------------------------------
      // Firestore profile
      // ------------------------------------------------------------

      try {
        final DocumentSnapshot snapshot =
            await _firestore.collection('users').doc(user.uid).get();

        if (snapshot.exists) {
          final dynamic rawData = snapshot.data();

          if (rawData is Map<String, dynamic>) {
            name = rawData['name']?.toString() ??
                rawData['displayName']?.toString() ??
                '';
          }
        }
      } catch (_) {
        // Firebase Auth fallback below.
      }

      // ------------------------------------------------------------
      // Firebase Authentication fallback
      // ------------------------------------------------------------

      if (name.isEmpty) {
        name = user.displayName ?? '';
      }

      if (name.isEmpty && user.email != null) {
        name = user.email!.split('@').first;
      }

      if (name.isEmpty) {
        name = 'User';
      }

      if (!mounted) return;

      setState(() {
        _userName = name;
        _isLoadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _userName = 'User';
        _isLoadingProfile = false;
      });
    }
  }

  // ==============================================================
  // REFRESH AI FORECAST
  // ==============================================================

  Future<void> _refreshAiForecast() async {
    if (!mounted) return;

    setState(() {
      _aiForecastFuture = AiForecastService.getForecast();
    });

    try {
      await _aiForecastFuture;
    } catch (_) {
      // FutureBuilder will display the error state.
    }
  }

  // ==============================================================
  // TEXT HELPERS
  // ==============================================================

  String _getGreeting() {
    final int hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    }

    if (hour < 17) {
      return 'Good Afternoon';
    }

    return 'Good Evening';
  }

  // IMPORTANT:
  // Firebase/ESP8266 may send:
  // DRY
  // MOIST
  // NORMAL
  // WET
  // WET (Soil is fine)
  //
  // Therefore contains() is intentionally used here.
  String _getSoilStatusText(String status) {
    final String value = status.trim().toUpperCase();

    if (value.contains('DRY')) {
      return 'Needs Water';
    }

    if (value.contains('MOIST') || value.contains('NORMAL')) {
      return 'Healthy';
    }

    if (value.contains('WET')) {
      return 'Well Watered';
    }

    return '--';
  }

  String _getTemperatureStatus(double? value) {
    if (value == null) {
      return '--';
    }

    if (value < 15) {
      return 'Cold';
    }

    if (value <= 30) {
      return 'Normal';
    }

    return 'High';
  }

  String _getHumidityStatus(double? value) {
    if (value == null) {
      return '--';
    }

    if (value < 40) {
      return 'Low';
    }

    if (value <= 70) {
      return 'Normal';
    }

    return 'High';
  }

  String _getLightStatus(double? value) {
    if (value == null) {
      return '--';
    }

    // Raw LDR ADC value.
    if (value < 300) {
      return 'Low Light';
    }

    if (value < 700) {
      return 'Moderate';
    }

    return 'Bright';
  }

  // ==============================================================
  // SAFE PARSERS
  // ==============================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''),
        ) ??
        0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString().replaceAll(RegExp(r'[^0-9\-]'), ''),
        ) ??
        0;
  }

  double? _toNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) {
      return null;
    }

    // Numeric Firebase timestamp.
    if (value is num) {
      final int number = value.toInt();

      // Milliseconds since epoch.
      if (number > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(number);
      }

      // Seconds since epoch.
      if (number > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(number * 1000);
      }
    }

    // String timestamp.
    final DateTime? parsed = DateTime.tryParse(value.toString());

    if (parsed != null) {
      return parsed;
    }

    // Numeric string timestamp.
    final int? numeric = int.tryParse(value.toString());

    if (numeric != null) {
      if (numeric > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(numeric);
      }

      if (numeric > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(numeric * 1000);
      }
    }

    return null;
  }

  // ==============================================================
  // SOIL STATUS NORMALIZATION
  // ==============================================================

  String _normalizeSoilStatus(dynamic raw) {
    final String value = raw?.toString().trim().toUpperCase() ?? '';

    if (value.contains('DRY')) {
      return 'DRY';
    }

    if (value.contains('MOIST')) {
      return 'MOIST';
    }

    if (value.contains('NORMAL')) {
      return 'NORMAL';
    }

    if (value.contains('WET')) {
      return 'WET';
    }

    return value.isEmpty ? '--' : value;
  }

  // ==============================================================
  // DRY DURATION — BACKWARD SCAN
  // ==============================================================

  double _calculateDryDurationHours(
    DataSnapshot? logSnapshot,
    String currentSoilStatus,
  ) {
    if (logSnapshot == null) {
      return 0.0;
    }

    final String currentSoil = currentSoilStatus.trim().toUpperCase();

    if (!currentSoil.contains('DRY')) {
      return 0.0;
    }

    final List<Map<String, dynamic>> records = [];

    for (final DataSnapshot child in logSnapshot.children) {
      final dynamic data = child.value;

      if (data is Map) {
        final DateTime? timestamp = _parseTimestamp(data['Timestamp']);

        if (timestamp != null) {
          records.add({
            'timestamp': timestamp,
            'soilStatus': data['SoilStatus']?.toString() ?? '',
          });
        }
      }
    }

    if (records.isEmpty) {
      return 0.0;
    }

    records.sort((a, b) {
      final DateTime first = a['timestamp'] as DateTime;
      final DateTime second = b['timestamp'] as DateTime;

      return first.compareTo(second);
    });

    DateTime? dryStart;

    for (int i = records.length - 1; i >= 0; i--) {
      final String status =
          records[i]['soilStatus'].toString().trim().toUpperCase();

      if (status.contains('DRY')) {
        dryStart = records[i]['timestamp'] as DateTime;
      } else {
        break;
      }
    }

    if (dryStart == null) {
      return 0.0;
    }

    final DateTime now = DateTime.now();

    final int minutes = now.difference(dryStart).inMinutes;

    final double hours = minutes / 60.0;

    return hours.clamp(0.0, 24.0).toDouble();
  }

  // ==============================================================
  // RECENT ACTIVITY DATA
  // ==============================================================

  List<_ActivityEntry> _getRecentActivity(DataSnapshot? logSnapshot) {
    if (logSnapshot == null) {
      return const [];
    }

    final List<_ActivityEntry> entries = [];

    for (final DataSnapshot child in logSnapshot.children) {
      final dynamic data = child.value;

      if (data is! Map) {
        continue;
      }

      final DateTime? timestamp = _parseTimestamp(data['Timestamp']);

      final String soil = data['SoilStatus']?.toString().trim() ?? '';

      final dynamic temperature = data['Temperature'];

      final dynamic light = data['LightIntensity'];

      // ------------------------------------------------------------
      // Soil activity
      // ------------------------------------------------------------

      if (soil.isNotEmpty) {
        final String upper = soil.toUpperCase();

        entries.add(
          _ActivityEntry(
            title: 'Soil moisture: $soil',
            subtitle: upper.contains('DRY')
                ? 'Soil is now DRY'
                : upper.contains('WET')
                    ? 'Soil is now WET'
                    : 'Soil moisture updated',
            timestamp: timestamp,
            icon: upper.contains('WET')
                ? Icons.water_outlined
                : Icons.water_drop_outlined,
            color: upper.contains('DRY') ? _kAmber : _kPrimary,
          ),
        );
      }

      // ------------------------------------------------------------
      // Temperature activity
      // ------------------------------------------------------------

      else if (temperature != null) {
        entries.add(
          _ActivityEntry(
            title: 'Temperature updated',
            subtitle: '${_toDouble(temperature).toStringAsFixed(1)}°C',
            timestamp: timestamp,
            icon: Icons.thermostat_outlined,
            color: Colors.orange,
          ),
        );
      }

      // ------------------------------------------------------------
      // Light activity
      // ------------------------------------------------------------

      else if (light != null) {
        entries.add(
          _ActivityEntry(
            title: 'Light intensity updated',
            subtitle: '${_toInt(light)} ADC',
            timestamp: timestamp,
            icon: Icons.wb_sunny_outlined,
            color: Colors.amber,
          ),
        );
      }
    }

    entries.sort((a, b) {
      final DateTime? at = a.timestamp;
      final DateTime? bt = b.timestamp;

      if (at == null && bt == null) {
        return 0;
      }

      if (at == null) {
        return 1;
      }

      if (bt == null) {
        return -1;
      }

      return bt.compareTo(at);
    });

    return entries.take(3).toList();
  }

  String _relativeTime(DateTime? timestamp) {
    if (timestamp == null) {
      return 'Logged';
    }

    final Duration difference = DateTime.now().difference(timestamp);

    if (difference.isNegative) {
      return 'Just now';
    }

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} h ago';
    }

    return '${difference.inDays} d ago';
  }

  // ==============================================================
  // BUILD DASHBOARD SNAPSHOT
  // ==============================================================

  _DashboardSnapshot _buildSnapshot(
    DataSnapshot? sensorSnapshot,
    DataSnapshot? logSnapshot,
  ) {
    final dynamic rawSensor = sensorSnapshot?.value;

    double? temperature;
    double? humidity;
    double? lightIntensity;

    String soilStatus = '--';

    bool deviceDataAvailable = false;

    bool? pumpManual;

    if (rawSensor is Map) {
      temperature = _toNullableDouble(rawSensor['Temperature']);

      humidity = _toNullableDouble(rawSensor['Humidity']);

      lightIntensity = _toNullableDouble(rawSensor['LightIntensity']);

      soilStatus = _normalizeSoilStatus(rawSensor['SoilStatus']);

      // ------------------------------------------------------------
      // Device data availability
      // ------------------------------------------------------------

      final dynamic device = rawSensor['Device'];

      deviceDataAvailable = device is Map
          ? device.isNotEmpty
          : device != null;

      // ------------------------------------------------------------
      // PumpManual parsing
      // ------------------------------------------------------------

      final dynamic control = rawSensor['Control'];

      if (control is Map && control.containsKey('PumpManual')) {
        final dynamic raw = control['PumpManual'];

        if (raw is bool) {
          pumpManual = raw;
        } else if (raw is num) {
          pumpManual = raw != 0;
        } else if (raw is String) {
          final String lower = raw.trim().toLowerCase();

          if (lower == 'true' || lower == '1' || lower == 'on') {
            pumpManual = true;
          } else if (lower == 'false' ||
              lower == '0' ||
              lower == 'off') {
            pumpManual = false;
          }
        }
      }
    }

    // ------------------------------------------------------------
    // Historical dry duration
    // ------------------------------------------------------------

    final double dryDurationHours =
        _calculateDryDurationHours(logSnapshot, soilStatus);

    // ------------------------------------------------------------
    // AI recommendation
    //
    // This remains the rule-based recommendation system.
    // The Random Forest forecast is displayed separately.
    // ------------------------------------------------------------

    AIRecommendation? recommendation;

    if (rawSensor is Map) {
      recommendation = AIRecommendationService.generateRecommendation(
        temperature: temperature ?? 0.0,
        humidity: humidity ?? 0.0,
        lightIntensity: (lightIntensity ?? 0).toInt(),
        soilStatus: soilStatus,
        dryDurationHours: dryDurationHours,
        mlProbability: null,
      );
    }

    return _DashboardSnapshot(
      temperature: temperature,
      humidity: humidity,
      lightIntensity: lightIntensity,
      soilStatus: soilStatus,
      deviceDataAvailable: deviceDataAvailable,
      pumpManual: pumpManual,
      dryDurationHours: dryDurationHours,
      aiRecommendation: recommendation,
      recentActivity: _getRecentActivity(logSnapshot),
    );
  }

  // ==============================================================
  // NAVIGATION
  // ==============================================================

  Future<void> _openAnalytics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
    );
  }

  Future<void> _openAddPlant() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPlantScreen()),
    );
  }

  Future<void> _openDeviceSetup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeviceSetupScreen()),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  // ==============================================================
  // MANUAL WATERING
  // ==============================================================

  Future<void> _startManualWatering() async {
    try {
      await _plantService.triggerManualWatering(true);

      if (!mounted) return;

      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pump turned ON'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to turn pump ON: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _stopManualWatering() async {
    try {
      await _plantService.triggerManualWatering(false);

      if (!mounted) return;

      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pump turned OFF'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to turn pump OFF: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showWateringDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kSoftGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  color: _kPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Manual Watering',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Control the water pump manually. This overrides any scheduled watering.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _stopManualWatering();
              },
              icon: const Icon(Icons.power_settings_new, size: 18),
              label: const Text('Pump OFF'),
              style: TextButton.styleFrom(
                foregroundColor: _kRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _startManualWatering();
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Pump ON'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==============================================================
  // HOME SCREEN
  // ==============================================================

  Widget _buildHomeScreen() {
    return StreamBuilder<DatabaseEvent>(
      stream: _smartPlantRef.onValue,
      builder: (context, sensorAsync) {
        if (sensorAsync.connectionState == ConnectionState.waiting &&
            !sensorAsync.hasData) {
          return _buildLoadingScreen();
        }

        if (sensorAsync.hasError) {
          return _buildErrorScreen(sensorAsync.error.toString());
        }

        final DataSnapshot? sensorSnapshot = sensorAsync.data?.snapshot;

        return StreamBuilder<DatabaseEvent>(
          stream: _logsQuery.onValue,
          builder: (context, logAsync) {
            final DataSnapshot? logSnapshot =
                logAsync.hasError ? null : logAsync.data?.snapshot;

            final _DashboardSnapshot snapshot =
                _buildSnapshot(sensorSnapshot, logSnapshot);

            return RefreshIndicator(
              color: _kPrimary,
              onRefresh: () async {
                try {
                  await _smartPlantRef.get();
                  await _logsQuery.get();
                } catch (_) {}

                // Refresh the Random Forest prediction as well.
                await _refreshAiForecast();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dashboard refreshed'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  _FadeSlideIn(child: _buildHeader()),

                  const SizedBox(height: 22),

                  _FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: _buildHeroCard(snapshot),
                  ),

                  const SizedBox(height: 24),

                  _FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: _buildAiSection(snapshot),
                  ),

                  const SizedBox(height: 24),

                  _FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
                    child: _buildAiForecastSection(),
                  ),

                  const SizedBox(height: 24),

                  _FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: _buildSensorCards(snapshot),
                  ),

                  const SizedBox(height: 24),

                  _FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: _buildIrrigationCard(snapshot),
                  ),

                  const SizedBox(height: 24),

                  _FadeSlideIn(
                    delay: const Duration(milliseconds: 360),
                    child: _buildQuickActions(),
                  ),

                  const SizedBox(height: 24),

                  _FadeSlideIn(
                    delay: const Duration(milliseconds: 420),
                    child: _buildRecentActivity(snapshot),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==============================================================
  // HEADER
  // ==============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 2),

              Row(
                children: [
                  Flexible(
                    child: Text(
                      _isLoadingProfile ? '...' : _userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  const Text(
                    '👋',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),

              const SizedBox(height: 2),

              Text(
                'Smart Plant Care',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        _headerIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: _openNotifications,
        ),

        const SizedBox(width: 6),

        _headerIconButton(
          icon: Icons.account_circle_outlined,
          onTap: _openProfile,
        ),
      ],
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(
            icon,
            color: _kPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // HERO CARD
  // ==============================================================

  Widget _buildHeroCard(_DashboardSnapshot s) {
    final String soilText = _getSoilStatusText(s.soilStatus);

    final bool hasData = s.temperature != null ||
        s.humidity != null ||
        s.lightIntensity != null ||
        s.soilStatus != '--';

    return Container(
      padding: const EdgeInsets.all(20),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.28),
            blurRadius: 20,
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plant Monitoring',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: hasData
                                ? const Color(0xFF7CE0B0)
                                : Colors.white54,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 6),

                        Flexible(
                          child: Text(
                            soilText == '--'
                                ? 'Waiting for data'
                                : soilText,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroPill(
                icon: Icons.sensors,
                label: s.deviceDataAvailable
                    ? 'Device online'
                    : 'No device data',
                tone: s.deviceDataAvailable
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.08),
                textColor: Colors.white,
              ),

              _heroPill(
                icon: Icons.cloud_done_outlined,
                label: hasData ? 'Live data' : 'Waiting',
                tone: Colors.white.withValues(alpha: 0.12),
                textColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill({
    required IconData icon,
    required String label,
    required Color tone,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),

          const SizedBox(width: 6),

          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // EXISTING AI RECOMMENDATION
  // ==============================================================

  Widget _buildAiSection(_DashboardSnapshot s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'AI Watering Recommendation',
          icon: Icons.auto_awesome,
        ),

        const SizedBox(height: 12),

        if (s.aiRecommendation == null)
          _unavailableCard(
            'Waiting for current Firebase sensor data...',
          )
        else
          _aiCard(s.aiRecommendation!),
      ],
    );
  }

  Widget _aiCard(AIRecommendation rec) {
    final Color urgencyColor = _urgencyColor(rec.urgency);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: urgencyColor.withValues(alpha: 0.18),
          width: 1.2,
        ),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kSoftGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: _kPrimary,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  rec.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            rec.message,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.5,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _metricBox(
                  label: 'Score',
                  value: '${rec.score.toStringAsFixed(0)}/100',
                  valueColor: _kPrimary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _metricBox(
                  label: 'Urgency',
                  value: rec.urgency,
                  valueColor: urgencyColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Based on current sensor readings and historical soil trends.',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // NEW AI SOIL FORECAST
  // ==============================================================

  Widget _buildAiForecastSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'AI Soil Forecast',
          icon: Icons.insights_outlined,
        ),

        const SizedBox(height: 12),

        FutureBuilder<AiForecastModel>(
          future: _aiForecastFuture,
          builder: (context, snapshot) {
            // ------------------------------------------------------
            // Loading
            // ------------------------------------------------------

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _unavailableCard('Loading AI soil forecast...');
            }

            // ------------------------------------------------------
            // Error
            // ------------------------------------------------------

            if (snapshot.hasError) {
              return _aiForecastErrorCard(snapshot.error);
            }

            // ------------------------------------------------------
            // Missing data
            // ------------------------------------------------------

            final AiForecastModel? forecast = snapshot.data;

            if (forecast == null) {
              return _unavailableCard('No AI forecast available.');
            }

            if (!forecast.success) {
              return _unavailableCard(
                'AI forecast could not be generated.',
              );
            }

            // ------------------------------------------------------
            // Forecast available
            // ------------------------------------------------------

            return _aiForecastCard(forecast);
          },
        ),
      ],
    );
  }

  Widget _aiForecastCard(AiForecastModel forecast) {
    final bool forecastDry =
        forecast.forecastSoilStatus.toUpperCase().contains('DRY');

    final Color forecastColor = forecastDry ? _kAmber : _kPrimary;

    final IconData forecastIcon = forecastDry
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: forecastColor.withValues(alpha: 0.20),
          width: 1.2,
        ),
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
          // --------------------------------------------------------
          // Header
          // --------------------------------------------------------

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kSoftGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: _kPrimary,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Random Forest Forecast',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Predictive soil-state analysis',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: forecastColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      forecastIcon,
                      size: 15,
                      color: forecastColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      forecast.forecastSoilStatus,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: forecastColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------------
          // Current vs forecast
          // --------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: _forecastMetricBox(
                  label: 'Current Soil',
                  value: forecast.currentSoilStatus,
                  valueColor: _kPrimary,
                  icon: Icons.water_drop_outlined,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _forecastMetricBox(
                  label: 'Forecast',
                  value: forecast.forecastSoilStatus,
                  valueColor: forecastColor,
                  icon: forecastDry
                      ? Icons.warning_amber_outlined
                      : Icons.check_circle_outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // --------------------------------------------------------
          // Probability bar
          // --------------------------------------------------------

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kSoftGreenAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Dry Probability',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '${(forecast.dryProbability * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kAmber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: forecast.dryProbability.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor:
                        _kPrimary.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      forecastDry ? _kAmber : _kPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _metricBox(
                        label: 'Wet Probability',
                        value:
                            '${(forecast.wetProbability * 100).toStringAsFixed(1)}%',
                        valueColor: _kPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // --------------------------------------------------------
          // Forecast horizon
          // --------------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kSoftGreenAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 19,
                  color: _kPrimary,
                ),

                const SizedBox(width: 8),

                Text(
                  'Forecast horizon',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),

                const Spacer(),

                Text(
                  '${forecast.horizonMinutes} minutes',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // --------------------------------------------------------
          // Recommendation
          // --------------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: forecastDry
                  ? _kAmber.withValues(alpha: 0.08)
                  : _kSoftGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: forecastDry
                    ? _kAmber.withValues(alpha: 0.15)
                    : _kPrimary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  forecastDry
                      ? Icons.water_drop_outlined
                      : Icons.check_circle_outline,
                  size: 20,
                  color: forecastColor,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Recommendation',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: forecastColor,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        forecast.recommendation,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          height: 1.45,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // --------------------------------------------------------
          // Advisory-only notice
          // --------------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.grey.shade700,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Advisory only — AI forecast does not control the water pump. Pump operation remains manual.',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      height: 1.45,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // --------------------------------------------------------
          // Model + timestamp
          // --------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: Text(
                  'Model: ${forecast.model}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Flexible(
                child: Text(
                  'Data: ${forecast.timestamp}',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _forecastMetricBox({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSoftGreenAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: valueColor,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiForecastErrorCard(Object? error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.orange.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  color: _kAmber,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  'AI Forecast Unavailable',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Make sure the Python Flask AI API is running and the device is connected to the same network.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'API: https://nasir.pythonanywhere.com/api/soil-forecast',
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // METRIC BOX
  // ==============================================================

  Widget _metricBox({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSoftGreenAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _urgencyColor(String urgency) {
    switch (urgency.toUpperCase()) {
      case 'HIGH':
        return _kRed;

      case 'MEDIUM':
        return _kAmber;

      default:
        return _kPrimary;
    }
  }

  // ==============================================================
  // LIVE ENVIRONMENT
  // ==============================================================

  Widget _buildSensorCards(_DashboardSnapshot s) {
    final double temperature = s.temperature ?? 0.0;

    final double humidity = s.humidity ?? 0.0;

    final double light = s.lightIntensity ?? 0.0;

    final String soilStatus = _getSoilStatusText(s.soilStatus);

    final bool hasTemperature = s.temperature != null;

    final bool hasHumidity = s.humidity != null;

    final bool hasLight = s.lightIntensity != null;

    final bool hasSoil = s.soilStatus != '--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Live Environment',
          icon: Icons.sensors_outlined,
        ),

        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // ------------------------------------------------------
            // Temperature
            // ------------------------------------------------------

            SensorCard(
              title: 'Temperature',
              value: hasTemperature
                  ? temperature.toStringAsFixed(1)
                  : '---',
              unit: '°C',
              icon: Icons.thermostat_outlined,
              iconColor: Colors.deepOrange,
              status: hasTemperature
                  ? _getTemperatureStatus(temperature)
                  : 'Waiting',
              statusColor: hasTemperature
                  ? _getTemperatureStatus(temperature) == 'Normal'
                      ? _kPrimary
                      : _kAmber
                  : Colors.grey,
              isLoading: !hasTemperature,
              isActive: hasTemperature,
            ),

            // ------------------------------------------------------
            // Humidity
            // ------------------------------------------------------

            SensorCard(
              title: 'Humidity',
              value: hasHumidity
                  ? humidity.toStringAsFixed(1)
                  : '---',
              unit: '%',
              icon: Icons.water_drop_outlined,
              iconColor: Colors.blue,
              status: hasHumidity
                  ? _getHumidityStatus(humidity)
                  : 'Waiting',
              statusColor: hasHumidity
                  ? _getHumidityStatus(humidity) == 'Normal'
                      ? _kPrimary
                      : _kAmber
                  : Colors.grey,
              isLoading: !hasHumidity,
              isActive: hasHumidity,
            ),

            // ------------------------------------------------------
            // Light
            // ------------------------------------------------------

            SensorCard(
              title: 'Light Intensity',
              value: hasLight ? light.toStringAsFixed(0) : '---',
              unit: 'ADC',
              icon: Icons.wb_sunny_outlined,
              iconColor: Colors.amber.shade700,
              status: hasLight
                  ? _getLightStatus(light)
                  : 'Waiting',
              statusColor: hasLight
                  ? _getLightStatus(light) == 'Moderate'
                      ? _kPrimary
                      : _kAmber
                  : Colors.grey,
              isLoading: !hasLight,
              isActive: hasLight,
            ),

            // ------------------------------------------------------
            // Soil
            // ------------------------------------------------------

            SensorCard(
              title: 'Soil Moisture',
              value: hasSoil ? soilStatus : '---',
              unit: '',
              icon: Icons.grass_outlined,
              iconColor: _kPrimary,
              status: hasSoil ? s.soilStatus : 'Waiting',
              statusColor: hasSoil
                  ? s.soilStatus.toUpperCase().contains('DRY')
                      ? _kRed
                      : s.soilStatus.toUpperCase().contains('WET')
                          ? Colors.blue
                          : _kPrimary
                  : Colors.grey,
              isLoading: !hasSoil,
              isActive: hasSoil,
            ),
          ],
        ),
      ],
    );
  }

  // ==============================================================
  // SMART IRRIGATION
  // ==============================================================

  Widget _buildIrrigationCard(_DashboardSnapshot s) {
    final bool? pump = s.pumpManual;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Smart Irrigation',
          icon: Icons.water_drop_outlined,
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
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
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kSoftGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.water_drop_outlined,
                      color: _kPrimary,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Water Pump',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'Manual control',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (pump != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: pump
                            ? _kSoftGreen
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: pump
                                  ? _kPrimary
                                  : Colors.grey.shade500,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Text(
                            pump ? 'Pump ON' : 'Pump OFF',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: pump
                                  ? _kPrimary
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showWateringDialog,
                  icon: const Icon(Icons.tune),
                  label: Text(
                    'Manual Control',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(
                      color: _kPrimary,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // QUICK ACTIONS
  // ==============================================================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Quick Actions',
          icon: Icons.bolt_outlined,
        ),

        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            QuickActionCard(
              title: 'Add Plant',
              subtitle: 'Register a new plant',
              icon: Icons.add_circle_outline,
              iconColor: _kPrimary,
              onTap: _openAddPlant,
            ),

            QuickActionCard(
              title: 'Water Now',
              subtitle: 'Control pump manually',
              icon: Icons.water_drop_outlined,
              iconColor: Colors.blue,
              onTap: _showWateringDialog,
            ),

            QuickActionCard(
              title: 'Device Setup',
              subtitle: 'Configure your device',
              icon: Icons.settings_outlined,
              iconColor: Colors.orange,
              onTap: _openDeviceSetup,
            ),

            QuickActionCard(
              title: 'Analytics',
              subtitle: 'View historical data',
              icon: Icons.analytics_outlined,
              iconColor: _kPrimary,
              onTap: _openAnalytics,
            ),
          ],
        ),
      ],
    );
  }

  // ==============================================================
  // RECENT ACTIVITY
  // ==============================================================

  Widget _buildRecentActivity(_DashboardSnapshot s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Recent Activity',
          icon: Icons.history,
          trailing: TextButton(
            onPressed: _openAnalytics,
            style: TextButton.styleFrom(
              foregroundColor: _kPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              'View All',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        if (s.recentActivity.isEmpty)
          _unavailableCard('No log entries available yet.')
        else
          ...s.recentActivity.map(
            (entry) => RecentActivityCard(
              title: entry.title,
              subtitle: entry.subtitle,
              time: _relativeTime(entry.timestamp),
              icon: entry.icon,
              iconColor: entry.color,
            ),
          ),
      ],
    );
  }

  // ==============================================================
  // SHARED WIDGETS
  // ==============================================================

  Widget _sectionTitle(
    String text, {
    IconData? icon,
    Widget? trailing,
  }) {
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

        if (trailing != null) trailing,
      ],
    );
  }

  Widget _unavailableCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: _kPrimary,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // LOADING / ERROR
  // ==============================================================

  Widget _buildLoadingScreen() {
    return const Center(
      child: CircularProgressIndicator(color: _kPrimary),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 42,
                color: _kRed,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Unable to load dashboard',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _aiForecastFuture = AiForecastService.getForecast();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
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

  // ==============================================================
  // BODY NAVIGATION
  // ==============================================================

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();

      case 1:
        return const PlantsScreen();

      case 2:
        return const NotificationsScreen();

      case 3:
        return const ProfileScreen();

      default:
        return _buildHomeScreen();
    }
  }

  // ==============================================================
  // MAIN BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,

      body: SafeArea(
        child: _buildBody(),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          elevation: 0,
          height: 68,
          indicatorColor: const Color(0xFFDCEDE5),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: _kPrimary),
              label: 'Home',
            ),

            NavigationDestination(
              icon: Icon(Icons.local_florist_outlined),
              selectedIcon: Icon(Icons.local_florist, color: _kPrimary),
              label: 'Plants',
            ),

            NavigationDestination(
              icon: Icon(Icons.notifications_none),
              selectedIcon: Icon(Icons.notifications, color: _kPrimary),
              label: 'Alerts',
            ),

            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: _kPrimary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}