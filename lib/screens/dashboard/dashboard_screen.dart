import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smart_plant_care/screens/add_plant/add_plant_screen.dart';
import 'package:smart_plant_care/screens/analytics/analytics_screen.dart';
import 'package:smart_plant_care/screens/device_setup/device_setup_screen.dart';
import 'package:smart_plant_care/screens/notifications/notifications_screen.dart';
import 'package:smart_plant_care/screens/profile/profile_screen.dart';
import 'package:smart_plant_care/screens/plants/plants_screen.dart';

import 'package:smart_plant_care/services/plant_service.dart';
import 'package:smart_plant_care/services/ai_recommendation_service.dart';

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

  // ================================================================
  // FIREBASE REFERENCES
  // ================================================================

  late final DatabaseReference _smartPlantRef;
  late final Query _logsQuery;

  // ================================================================
  // UI STATE
  // ================================================================

  int _currentIndex = 0;
  String _userName = 'User';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();

    _smartPlantRef = _database.ref('SmartPlant');

    // One realtime log query reused for:
    // - AI dry-duration calculation
    // - Recent activity
    _logsQuery = _database.ref('SmartPlant/Logs').limitToLast(1500);

    _loadUserProfile();
  }

  // ================================================================
  // USER PROFILE
  // ================================================================

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

      try {
        final DocumentSnapshot snapshot =
            await _firestore.collection('users').doc(user.uid).get();

        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>?;

          name = data?['name']?.toString() ??
              data?['displayName']?.toString() ??
              '';
        }
      } catch (_) {
        // Fall back to Firebase Authentication.
      }

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

  // ================================================================
  // TEXT HELPERS
  // ================================================================

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

  String _getSoilStatusText(String status) {
    switch (status.trim().toUpperCase()) {
      case 'DRY':
        return 'Needs Water';

      case 'MOIST':
      case 'NORMAL':
        return 'Healthy';

      case 'WET':
        return 'Well Watered';

      default:
        return '--';
    }
  }

  String _getTemperatureStatus(double? value) {
    if (value == null) return '--';

    if (value < 15) {
      return 'Cold';
    }

    if (value <= 30) {
      return 'Normal';
    }

    return 'High';
  }

  String _getHumidityStatus(double? value) {
    if (value == null) return '--';

    if (value < 40) {
      return 'Low';
    }

    if (value <= 70) {
      return 'Normal';
    }

    return 'High';
  }

  String _getLightStatus(double? value) {
    if (value == null) return '--';

    // Raw LDR ADC value.
    if (value < 300) {
      return 'Low Light';
    }

    if (value < 700) {
      return 'Moderate';
    }

    return 'Bright';
  }

  // ================================================================
  // SAFE PARSERS
  // ================================================================

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''),
        ) ??
        0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString().replaceAll(RegExp(r'[^0-9\-]'), ''),
        ) ??
        0;
  }

  double? _toNullableDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

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

    return DateTime.tryParse(value.toString());
  }

  String _normalizeSoilStatus(dynamic raw) {
    final String value =
        raw?.toString().trim().toUpperCase() ?? '';

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
        return value.isEmpty ? '--' : value;
    }
  }

  // ================================================================
  // DRY DURATION — BACKWARD SCAN
  // ================================================================

  double _calculateDryDurationHours(
    DataSnapshot? logSnapshot,
    String currentSoilStatus,
  ) {
    if (logSnapshot == null) {
      return 0.0;
    }

    final String currentSoil =
        currentSoilStatus.trim().toUpperCase();

    if (!currentSoil.contains('DRY')) {
      return 0.0;
    }

    final records = <Map<String, dynamic>>[];

    for (final child in logSnapshot.children) {
      final dynamic data = child.value;

      if (data is Map) {
        final DateTime? timestamp =
            _parseTimestamp(data['Timestamp']);

        if (timestamp != null) {
          records.add({
            'timestamp': timestamp,
            'soilStatus':
                data['SoilStatus']?.toString() ?? '',
          });
        }
      }
    }

    if (records.isEmpty) {
      return 0.0;
    }

    records.sort((a, b) {
      final DateTime first =
          a['timestamp'] as DateTime;

      final DateTime second =
          b['timestamp'] as DateTime;

      return first.compareTo(second);
    });

    DateTime? dryStart;

    for (int i = records.length - 1; i >= 0; i--) {
      final String status =
          records[i]['soilStatus']
              .toString()
              .trim()
              .toUpperCase();

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

    final int minutes =
        now.difference(dryStart).inMinutes;

    final double hours = minutes / 60.0;

    return hours.clamp(0.0, 24.0).toDouble();
  }

  // ================================================================
  // RECENT ACTIVITY DATA HELPER
  //
  // IMPORTANT:
  // This is deliberately named _getRecentActivity because
  // _buildRecentActivity is already used by the UI builder below.
  // ================================================================

  List<_ActivityEntry> _getRecentActivity(
    DataSnapshot? logSnapshot,
  ) {
    if (logSnapshot == null) {
      return const [];
    }

    final entries = <_ActivityEntry>[];

    for (final child in logSnapshot.children) {
      final dynamic data = child.value;

      if (data is! Map) {
        continue;
      }

      final DateTime? timestamp =
          _parseTimestamp(data['Timestamp']);

      final String soil =
          data['SoilStatus']?.toString().trim() ?? '';

      final dynamic temperature =
          data['Temperature'];

      final dynamic light =
          data['LightIntensity'];

      // --------------------------------------------------------------
      // Soil activity
      // --------------------------------------------------------------

      if (soil.isNotEmpty) {
        final String upper =
            soil.toUpperCase();

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
            color: upper.contains('DRY')
                ? _kAmber
                : _kPrimary,
          ),
        );
      }

      // --------------------------------------------------------------
      // Temperature activity
      // --------------------------------------------------------------

      else if (temperature != null) {
        entries.add(
          _ActivityEntry(
            title: 'Temperature updated',
            subtitle:
                '${_toDouble(temperature).toStringAsFixed(1)}°C',
            timestamp: timestamp,
            icon: Icons.thermostat_outlined,
            color: Colors.orange,
          ),
        );
      }

      // --------------------------------------------------------------
      // Light activity
      // --------------------------------------------------------------

      else if (light != null) {
        entries.add(
          _ActivityEntry(
            title: 'Light intensity updated',
            subtitle:
                '${_toInt(light)} ADC',
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

    final Duration difference =
        DateTime.now().difference(timestamp);

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

  // ================================================================
  // BUILD IMMUTABLE SNAPSHOT
  // ================================================================

  _DashboardSnapshot _buildSnapshot(
    DataSnapshot? sensorSnapshot,
    DataSnapshot? logSnapshot,
  ) {
    final dynamic rawSensor =
        sensorSnapshot?.value;

    double? temperature;
    double? humidity;
    double? lightIntensity;

    String soilStatus = '--';

    bool deviceDataAvailable = false;

    bool? pumpManual;

    if (rawSensor is Map) {
      temperature =
          _toNullableDouble(
        rawSensor['Temperature'],
      );

      humidity =
          _toNullableDouble(
        rawSensor['Humidity'],
      );

      lightIntensity =
          _toNullableDouble(
        rawSensor['LightIntensity'],
      );

      soilStatus =
          _normalizeSoilStatus(
        rawSensor['SoilStatus'],
      );

      final String deviceValue =
          rawSensor['Device']?.toString() ?? '';

      deviceDataAvailable =
          deviceValue.isNotEmpty;

      // ------------------------------------------------------------
      // PumpManual parsing
      // ------------------------------------------------------------

      final dynamic control =
          rawSensor['Control'];

      if (control is Map &&
          control.containsKey('PumpManual')) {
        final dynamic raw =
            control['PumpManual'];

        if (raw is bool) {
          pumpManual = raw;
        } else if (raw is num) {
          pumpManual = raw != 0;
        } else if (raw is String) {
          final String lower =
              raw.trim().toLowerCase();

          if (lower == 'true' ||
              lower == '1' ||
              lower == 'on') {
            pumpManual = true;
          } else if (lower == 'false' ||
              lower == '0' ||
              lower == 'off') {
            pumpManual = false;
          }
        }
      }
    }

    // --------------------------------------------------------------
    // Historical dry duration
    // --------------------------------------------------------------

    final double dryDurationHours =
        _calculateDryDurationHours(
      logSnapshot,
      soilStatus,
    );

    // --------------------------------------------------------------
    // Recommendation
    //
    // mlProbability intentionally remains null because the current
    // experimental ML model has not been validated sufficiently.
    // --------------------------------------------------------------

    AIRecommendation? recommendation;

    if (rawSensor is Map) {
      recommendation =
          AIRecommendationService.generateRecommendation(
        temperature: temperature ?? 0.0,
        humidity: humidity ?? 0.0,
        lightIntensity:
            (lightIntensity ?? 0).toInt(),
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
      deviceDataAvailable:
          deviceDataAvailable,
      pumpManual: pumpManual,
      dryDurationHours:
          dryDurationHours,
      aiRecommendation:
          recommendation,
      recentActivity:
          _getRecentActivity(logSnapshot),
    );
  }

  // ================================================================
  // NAVIGATION
  // ================================================================

  Future<void> _openAnalytics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AnalyticsScreen(),
      ),
    );
  }

  Future<void> _openAddPlant() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddPlantScreen(),
      ),
    );
  }

  Future<void> _openDeviceSetup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const DeviceSetupScreen(),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const NotificationsScreen(),
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ProfileScreen(),
      ),
    );
  }

  // ================================================================
  // MANUAL WATERING
  // ================================================================

  Future<void> _startManualWatering() async {
    try {
      await _plantService
          .triggerManualWatering(true);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('Pump turned ON'),
          duration:
              Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Unable to turn pump ON: $e'),
        ),
      );
    }
  }

  Future<void> _stopManualWatering() async {
    try {
      await _plantService
          .triggerManualWatering(false);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('Pump turned OFF'),
          duration:
              Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Unable to turn pump OFF: $e'),
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
          title: const Text(
            'Manual Watering',
          ),
          content: const Text(
            'Control the water pump manually from here.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _stopManualWatering();
              },
              child: const Text('Pump OFF'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _startManualWatering();
              },
              child: const Text('Pump ON'),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // HOME SCREEN
  // ================================================================

  Widget _buildHomeScreen() {
    return StreamBuilder<DatabaseEvent>(
      stream: _smartPlantRef.onValue,
      builder: (context, sensorAsync) {
        if (sensorAsync.connectionState ==
                ConnectionState.waiting &&
            !sensorAsync.hasData) {
          return _buildLoadingScreen();
        }

        if (sensorAsync.hasError) {
          return _buildErrorScreen(
            sensorAsync.error.toString(),
          );
        }

        final DataSnapshot? sensorSnapshot =
            sensorAsync.data?.snapshot;

        return StreamBuilder<DatabaseEvent>(
          stream: _logsQuery.onValue,
          builder: (context, logAsync) {
            final DataSnapshot? logSnapshot =
                logAsync.hasError
                    ? null
                    : logAsync.data?.snapshot;

            final _DashboardSnapshot snapshot =
                _buildSnapshot(
              sensorSnapshot,
              logSnapshot,
            );

            return RefreshIndicator(
              onRefresh: () async {
                try {
                  await _smartPlantRef.get();
                  await _logsQuery.get();
                } catch (_) {}
              },
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  100,
                ),
                children: [
                  _buildHeader(),

                  const SizedBox(height: 20),

                  _buildHeroCard(snapshot),

                  const SizedBox(height: 20),

                  _buildAiSection(snapshot),

                  const SizedBox(height: 24),

                  _buildSensorCards(snapshot),

                  const SizedBox(height: 24),

                  _buildIrrigationCard(snapshot),

                  const SizedBox(height: 24),

                  _buildQuickActions(),

                  const SizedBox(height: 24),

                  _buildRecentActivity(snapshot),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
                      _isLoadingProfile
                          ? '...'
                          : _userName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  const Text(
                    '👋',
                    style:
                        TextStyle(fontSize: 18),
                  ),
                ],
              ),

              const SizedBox(height: 2),

              Text(
                'Smart Plant Care',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w500,
                  color:
                      Colors.grey.shade500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: _openNotifications,
          icon: const Icon(
            Icons.notifications_none_rounded,
          ),
        ),

        IconButton(
          onPressed: _openProfile,
          icon: const Icon(
            Icons.account_circle_outlined,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // HERO CARD
  // ================================================================

  Widget _buildHeroCard(
    _DashboardSnapshot s,
  ) {
    final String soilText =
        _getSoilStatusText(
      s.soilStatus,
    );

    final bool hasData =
        s.temperature != null ||
        s.humidity != null ||
        s.lightIntensity != null ||
        s.soilStatus != '--';

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.08),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: 0.14,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plant Monitoring',
                      style:
                          GoogleFonts.poppins(
                        color:
                            Colors.white,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      soilText == '--'
                          ? 'Waiting for data'
                          : soilText,
                      style:
                          GoogleFonts.poppins(
                        color:
                            Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroPill(
                icon: Icons.sensors,
                label:
                    s.deviceDataAvailable
                        ? 'Device data available'
                        : 'No device data',
                tone:
                    s.deviceDataAvailable
                        ? _kSoftGreen
                        : Colors.white24,
                textColor:
                    s.deviceDataAvailable
                        ? _kPrimary
                        : Colors.white,
              ),

              _heroPill(
                icon:
                    Icons.cloud_done_outlined,
                label: hasData
                    ? 'Data available'
                    : 'Waiting for data',
                tone:
                    Colors.white24,
                textColor:
                    Colors.white,
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
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color: tone,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),

          const SizedBox(width: 6),

          Text(
            label,
            style:
                GoogleFonts.poppins(
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // AI RECOMMENDATION
  // ================================================================

  Widget _buildAiSection(
    _DashboardSnapshot s,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'AI Watering Recommendation',
        ),

        const SizedBox(height: 10),

        if (s.aiRecommendation == null)
          _unavailableCard(
            'Waiting for current Firebase sensor data...',
          )
        else
          _aiCard(
            s.aiRecommendation!,
          ),
      ],
    );
  }

  Widget _aiCard(
    AIRecommendation rec,
  ) {
    final Color urgencyColor =
        _urgencyColor(rec.urgency);

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: urgencyColor
              .withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.04),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.all(10),
                decoration:
                    BoxDecoration(
                  color: _kSoftGreen,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
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
                  style:
                      GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            rec.message,
            style:
                GoogleFonts.poppins(
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
                  value:
                      '${rec.score.toStringAsFixed(0)}/100',
                  valueColor:
                      _kPrimary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _metricBox(
                  label: 'Urgency',
                  value:
                      rec.urgency,
                  valueColor:
                      urgencyColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Based on current sensor readings and historical soil trends.',
            style:
                GoogleFonts.poppins(
              fontSize: 10.5,
              fontStyle:
                  FontStyle.italic,
              color:
                  Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color: _kSoftGreenAlt,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                GoogleFonts.poppins(
              fontSize: 11,
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style:
                GoogleFonts.poppins(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _urgencyColor(
    String urgency,
  ) {
    switch (
        urgency.toUpperCase()) {
      case 'HIGH':
        return _kRed;

      case 'MEDIUM':
        return _kAmber;

      default:
        return _kPrimary;
    }
  }

  // ================================================================
  // LIVE ENVIRONMENT
  // ================================================================

  Widget _buildSensorCards(
    _DashboardSnapshot s,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Live Environment',
        ),

        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          children: [
            SensorCard(
              title: 'Temperature',
              value: s.temperature != null
                  ? s.temperature!
                      .toStringAsFixed(1)
                  : '--',
              unit: '°C',
              icon:
                  Icons.thermostat_outlined,
              iconColor:
                  Colors.orange,
              status:
                  _getTemperatureStatus(
                s.temperature,
              ),
              isLoading:
                  s.temperature == null,
              isActive:
                  s.temperature != null,
            ),

            SensorCard(
              title: 'Humidity',
              value: s.humidity != null
                  ? s.humidity!
                      .toStringAsFixed(1)
                  : '--',
              unit: '%',
              icon:
                  Icons.water_drop_outlined,
              iconColor:
                  Colors.blue,
              status:
                  _getHumidityStatus(
                s.humidity,
              ),
              isLoading:
                  s.humidity == null,
              isActive:
                  s.humidity != null,
            ),

            SensorCard(
              title: 'Light Intensity',
              value: s.lightIntensity != null
                  ? s.lightIntensity!
                      .toStringAsFixed(0)
                  : '--',

              // Raw LDR ADC value.
              unit: 'ADC',

              icon:
                  Icons.wb_sunny_outlined,
              iconColor:
                  Colors.amber,
              status:
                  _getLightStatus(
                s.lightIntensity,
              ),
              isLoading:
                  s.lightIntensity == null,
              isActive:
                  s.lightIntensity != null,
            ),

            SensorCard(
              title: 'Soil Moisture',
              value:
                  s.soilStatus == '--'
                      ? '--'
                      : s.soilStatus,
              unit: '',
              icon:
                  Icons.grass_outlined,
              iconColor:
                  _kPrimary,
              status:
                  _getSoilStatusText(
                s.soilStatus,
              ),
              isLoading:
                  s.soilStatus == '--',
              isActive:
                  s.soilStatus != '--',
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // SMART IRRIGATION
  // ================================================================

  Widget _buildIrrigationCard(
    _DashboardSnapshot s,
  ) {
    final bool? pump =
        s.pumpManual;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Smart Irrigation',
        ),

        const SizedBox(height: 12),

        Container(
          padding:
              const EdgeInsets.all(16),
          decoration:
              BoxDecoration(
            color: _kSurface,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color:
                  Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: 0.04,
                ),
                blurRadius: 10,
                offset:
                    const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(
                      10,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          _kSoftGreen,
                      borderRadius:
                          BorderRadius
                              .circular(12),
                    ),
                    child: const Icon(
                      Icons.water_drop_outlined,
                      color:
                          _kPrimary,
                      size: 22,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Water Pump',
                          style:
                              GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          'Manual control',
                          style:
                              GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                _kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (pump != null)
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        color: pump
                            ? _kSoftGreen
                            : Colors
                                .grey
                                .shade100,
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration:
                                BoxDecoration(
                              shape:
                                  BoxShape
                                      .circle,
                              color: pump
                                  ? _kPrimary
                                  : Colors
                                      .grey
                                      .shade500,
                            ),
                          ),

                          const SizedBox(
                            width: 6,
                          ),

                          Text(
                            pump
                                ? 'Pump ON'
                                : 'Pump OFF',
                            style:
                                GoogleFonts
                                    .poppins(
                              fontSize:
                                  11,
                              fontWeight:
                                  FontWeight
                                      .w600,
                              color: pump
                                  ? _kPrimary
                                  : Colors
                                      .grey
                                      .shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              SizedBox(
                width:
                    double.infinity,
                child:
                    OutlinedButton.icon(
                  onPressed:
                      _showWateringDialog,
                  icon:
                      const Icon(
                    Icons.tune,
                  ),
                  label: Text(
                    'Manual Control',
                    style:
                        GoogleFonts.poppins(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        _kPrimary,
                    side:
                        const BorderSide(
                      color:
                          _kPrimary,
                      width: 1.2,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // QUICK ACTIONS
  // ================================================================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Quick Actions',
        ),

        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.7,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          children: [
            QuickActionCard(
              title: 'Add Plant',
              subtitle:
                  'Register a new plant',
              icon:
                  Icons.add_circle_outline,
              iconColor:
                  _kPrimary,
              onTap:
                  _openAddPlant,
            ),

            QuickActionCard(
              title: 'Water Now',
              subtitle:
                  'Control pump manually',
              icon:
                  Icons.water_drop_outlined,
              iconColor:
                  Colors.blue,
              onTap:
                  _showWateringDialog,
            ),

            QuickActionCard(
              title: 'Device Setup',
              subtitle:
                  'Configure your device',
              icon:
                  Icons.settings_outlined,
              iconColor:
                  Colors.orange,
              onTap:
                  _openDeviceSetup,
            ),

            QuickActionCard(
              title: 'Analytics',
              subtitle:
                  'View historical data',
              icon:
                  Icons.analytics_outlined,
              iconColor:
                  _kPrimary,
              onTap:
                  _openAnalytics,
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // RECENT ACTIVITY — UI BUILDER
  // ================================================================

  Widget _buildRecentActivity(
    _DashboardSnapshot s,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionTitle(
                'Recent Activity',
              ),
            ),

            TextButton(
              onPressed:
                  _openAnalytics,
              child:
                  const Text(
                'View Analytics',
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        if (s.recentActivity.isEmpty)
          _unavailableCard(
            'No log entries available yet.',
          )
        else
          ...s.recentActivity.map(
            (entry) =>
                RecentActivityCard(
              title:
                  entry.title,
              subtitle:
                  entry.subtitle,
              time:
                  _relativeTime(
                entry.timestamp,
              ),
              icon:
                  entry.icon,
              iconColor:
                  entry.color,
            ),
          ),
      ],
    );
  }

  // ================================================================
  // SHARED WIDGETS
  // ================================================================

  Widget _sectionTitle(
    String text,
  ) {
    return Text(
      text,
      style:
          GoogleFonts.poppins(
        fontSize: 17,
        fontWeight:
            FontWeight.w700,
        color:
            Colors.black87,
      ),
    );
  }

  Widget _unavailableCard(
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: _kSurface,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.03,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
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
              style:
                  GoogleFonts.poppins(
                fontSize: 13,
                color:
                    Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // LOADING / ERROR
  // ================================================================

  Widget _buildLoadingScreen() {
    return const Center(
      child:
          CircularProgressIndicator(),
    );
  }

  Widget _buildErrorScreen(
    String error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),

            const SizedBox(
              height: 15,
            ),

            Text(
              'Unable to load dashboard',
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.poppins(
                fontSize: 18,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              error,
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.poppins(
                fontSize: 12,
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              child:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // BOTTOM NAVIGATION
  // ================================================================

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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          _kBackground,

      body: SafeArea(
        child:
            _buildBody(),
      ),

      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            _currentIndex,

        onDestinationSelected:
            (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        backgroundColor:
            Colors.white,

        indicatorColor:
            const Color(
          0xFFDCEDE5,
        ),

        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon:
                Icon(Icons.home),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.local_florist_outlined,
            ),
            selectedIcon: Icon(
              Icons.local_florist,
            ),
            label: 'Plants',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.notifications_none,
            ),
            selectedIcon: Icon(
              Icons.notifications,
            ),
            label: 'Notifications',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}