import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:smart_plant_care/screens/dashboard/widgets/summary_card.dart';
import 'package:smart_plant_care/screens/dashboard/widgets/sensor_card.dart';
import 'package:smart_plant_care/screens/dashboard/widgets/quick_action_card.dart';
import 'package:smart_plant_care/screens/dashboard/widgets/recent_activity_card.dart';

import 'package:smart_plant_care/screens/plants/plants_screen.dart';
import 'package:smart_plant_care/screens/add_plant/add_plant_screen.dart';
import 'package:smart_plant_care/screens/device_setup/device_setup_screen.dart';
import 'package:smart_plant_care/screens/notifications/notifications_screen.dart';
import 'package:smart_plant_care/screens/profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ============================================================
  // NAVIGATION
  // ============================================================

  int _currentIndex = 0;

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseDatabase _database =
      FirebaseDatabase.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  late DatabaseReference _smartPlantRef;
  late DatabaseReference _plantsRef;

  // ============================================================
  // USER
  // ============================================================

  String _userName = 'User';

  // ============================================================
  // SENSOR DATA
  // ============================================================

  double? _temperature;
  double? _humidity;
  double? _lightIntensity;

  String _soilStatus = 'Waiting';
  String _soilMessage = 'Waiting for sensor data';

  // ============================================================
  // DEVICE
  // ============================================================

  bool _deviceConnected = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _smartPlantRef = _database.ref('SmartPlant');
    _plantsRef = _database.ref('Plants');

    _loadUserProfile();
  }

  // ============================================================
  // USER PLANTS
  //
  // Your current Firebase structure has /Plants as the actual
  // plant collection, so the dashboard count is taken from there.
  // ============================================================

  // ============================================================
  // LOAD USER PROFILE
  // ============================================================

  Future<void> _loadUserProfile() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _userName = 'User';
          });
        }

        return;
      }

      // ----------------------------------------------------------
      // First try Firestore user profile
      // ----------------------------------------------------------

      try {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .get();

        if (snapshot.exists) {
          final Map<String, dynamic>? data =
              snapshot.data();

          final String name =
              data?['name']?.toString().trim() ?? '';

          if (name.isNotEmpty) {
            if (mounted) {
              setState(() {
                _userName = _formatName(name);
              });
            }

            return;
          }
        }
      } catch (e) {
        debugPrint(
          'Firestore profile lookup failed: $e',
        );
      }

      // ----------------------------------------------------------
      // Firebase Auth fallback
      // ----------------------------------------------------------

      final String displayName =
          user.displayName?.trim() ?? '';

      if (displayName.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userName =
                _formatName(displayName);
          });
        }

        return;
      }

      // ----------------------------------------------------------
      // Email fallback
      // ----------------------------------------------------------

      if (mounted) {
        setState(() {
          _userName =
              _formatName(
            _getNameFromEmail(user.email),
          );
        });
      }
    } catch (e) {
      debugPrint(
        'ERROR LOADING USER PROFILE: $e',
      );
    }
  }

  // ============================================================
  // FORMAT USER NAME
  // ============================================================

  String _formatName(String name) {
    final String cleaned = name.trim();

    if (cleaned.isEmpty) {
      return 'User';
    }

    return cleaned
        .split(' ')
        .where(
          (word) => word.isNotEmpty,
        )
        .map(
          (word) =>
              word[0].toUpperCase() +
              word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  // ============================================================
  // EMAIL FALLBACK
  // ============================================================

  String _getNameFromEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'User';
    }

    final String namePart =
        email.split('@').first;

    if (namePart.isEmpty) {
      return 'User';
    }

    return namePart;
  }

  // ============================================================
  // DYNAMIC GREETING
  // ============================================================

  String _getGreeting() {
    final int hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    }

    if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    }

    if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    }

    return 'Good Night';
  }

  // ============================================================
  // SOIL PROCESSING
  // ============================================================

  SoilResult _processSoilStatus(
    String value,
  ) {
    if (value.trim().isEmpty) {
      return const SoilResult(
        status: 'Waiting',
        message: 'Waiting for sensor data',
      );
    }

    final String upper =
        value.toUpperCase();

    // ----------------------------------------------------------
    // DRY
    // ----------------------------------------------------------

    if (upper.contains('DRY')) {
      return const SoilResult(
        status: 'DRY',
        message: 'Needs Water',
      );
    }

    // ----------------------------------------------------------
    // MOIST
    // ----------------------------------------------------------

    if (upper.contains('MOIST')) {
      return const SoilResult(
        status: 'MOIST',
        message: 'Healthy',
      );
    }

    // ----------------------------------------------------------
    // WET
    // ----------------------------------------------------------

    if (upper.contains('WET')) {
      return const SoilResult(
        status: 'WET',
        message: 'Well Watered',
      );
    }

    // ----------------------------------------------------------
    // NORMAL
    // ----------------------------------------------------------

    if (upper.contains('NORMAL')) {
      return const SoilResult(
        status: 'MOIST',
        message: 'Healthy',
      );
    }

    return SoilResult(
      status: value,
      message: '',
    );
  }

  // ============================================================
  // TEMPERATURE STATUS
  // ============================================================

  String _getTemperatureStatus(
    double value,
  ) {
    if (value < 10) {
      return 'Low';
    }

    if (value > 40) {
      return 'High';
    }

    return 'Normal';
  }

  // ============================================================
  // HUMIDITY STATUS
  // ============================================================

  String _getHumidityStatus(
    double value,
  ) {
    if (value < 30) {
      return 'Low';
    }

    if (value > 80) {
      return 'High';
    }

    return 'Normal';
  }

  // ============================================================
  // LIGHT STATUS
  // ============================================================

  String _getLightStatus(
    double value,
  ) {
    if (value < 100) {
      return 'Low';
    }

    if (value > 1000) {
      return 'High';
    }

    return 'Normal';
  }

  // ============================================================
  // NUMBER CONVERSION
  // ============================================================

  double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    );
  }

  // ============================================================
  // DEVICE STATUS
  // ============================================================

  bool _getDeviceStatus(
    dynamic deviceValue, {
    double? temperature,
    double? humidity,
    double? light,
    String? soilStatus,
  }) {
    // ----------------------------------------------------------
    // If there is no explicit Device value, use live sensor
    // data as evidence that the ESP device is online.
    // ----------------------------------------------------------

    if (deviceValue == null) {
      return temperature != null ||
          humidity != null ||
          light != null ||
          (soilStatus != null &&
              soilStatus.isNotEmpty);
    }

    if (deviceValue is bool) {
      return deviceValue;
    }

    final String value =
        deviceValue.toString()
            .trim()
            .toLowerCase();

    if (value == 'connected' ||
        value == 'online' ||
        value == 'true' ||
        value == '1') {
      return true;
    }

    if (value == 'disconnected' ||
        value == 'offline' ||
        value == 'false' ||
        value == '0') {
      return false;
    }

    return value.isNotEmpty;
  }

  // ============================================================
  // SOIL COLOR
  // ============================================================

  Color _soilColor() {
    switch (_soilStatus) {
      case 'DRY':
        return Colors.red;

      case 'MOIST':
        return Colors.orange;

      case 'WET':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // DEVICE COLOR
  // ============================================================

  Color _deviceColor() {
    return _deviceConnected
        ? Colors.green
        : Colors.grey;
  }

  // ============================================================
  // OPEN PROFILE
  // ============================================================

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ProfileScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<DatabaseEvent>(
      stream: _smartPlantRef.onValue,
      builder: (
        context,
        sensorSnapshot,
      ) {
        // --------------------------------------------------------
        // READ SENSOR DATA
        // --------------------------------------------------------

        double? temperature;
        double? humidity;
        double? lightIntensity;

        String soilStatusValue = '';

        bool sensorDataAvailable = false;

        if (sensorSnapshot.hasData &&
            sensorSnapshot
                    .data!
                    .snapshot
                    .value !=
                null) {
          final Object? rawValue =
              sensorSnapshot
                  .data!
                  .snapshot
                  .value;

          if (rawValue is Map) {
            final Map<dynamic, dynamic>
                data =
                Map<dynamic, dynamic>.from(
              rawValue,
            );

            temperature =
                _toDouble(
              data['Temperature'],
            );

            humidity =
                _toDouble(
              data['Humidity'],
            );

            lightIntensity =
                _toDouble(
              data['LightIntensity'],
            );

            soilStatusValue =
                data['SoilStatus']
                        ?.toString()
                        .trim() ??
                    '';

            sensorDataAvailable =
                temperature != null ||
                    humidity != null ||
                    lightIntensity != null ||
                    soilStatusValue.isNotEmpty;

            // ----------------------------------------------------
            // DEVICE
            // ----------------------------------------------------

            final bool device =
                _getDeviceStatus(
              data['Device'],
              temperature: temperature,
              humidity: humidity,
              light: lightIntensity,
              soilStatus: soilStatusValue,
            );

            // Keep local state synchronized.
            if (_deviceConnected != device) {
              WidgetsBinding.instance
                  .addPostFrameCallback(
                (_) {
                  if (mounted) {
                    setState(() {
                      _deviceConnected =
                          device;
                    });
                  }
                },
              );
            }
          }
        }

        // --------------------------------------------------------
        // SOIL
        // --------------------------------------------------------

        final SoilResult soil =
            sensorDataAvailable
                ? _processSoilStatus(
                    soilStatusValue,
                  )
                : const SoilResult(
                    status: 'Waiting',
                    message:
                        'Waiting for sensor data',
                  );

        // --------------------------------------------------------
        // SENSOR STATUS
        // --------------------------------------------------------

        final String temperatureStatus =
            temperature != null
                ? _getTemperatureStatus(
                    temperature,
                  )
                : 'Waiting';

        final String humidityStatus =
            humidity != null
                ? _getHumidityStatus(
                    humidity,
                  )
                : 'Waiting';

        final String lightStatus =
            lightIntensity != null
                ? _getLightStatus(
                    lightIntensity,
                  )
                : 'Waiting';

        // --------------------------------------------------------
        // GREETING
        // --------------------------------------------------------

        final String greeting =
            _getGreeting();

        // ========================================================
        // ALL SCREENS
        // ========================================================

        final List<Widget> screens = [
          // ======================================================
          // HOME
          // ======================================================

          _buildHomeScreen(
            greeting: greeting,
            temperature: temperature,
            humidity: humidity,
            lightIntensity: lightIntensity,
            soil: soil,
            sensorDataAvailable:
                sensorDataAvailable,
            temperatureStatus:
                temperatureStatus,
            humidityStatus:
                humidityStatus,
            lightStatus:
                lightStatus,
          ),

          // ======================================================
          // PLANTS
          // ======================================================

          const PlantsScreen(),

          // ======================================================
          // NOTIFICATIONS
          // ======================================================

          const NotificationsScreen(),

          // ======================================================
          // PROFILE
          // ======================================================

          const ProfileScreen(),
        ];

        // ========================================================
        // MAIN SCAFFOLD
        // ========================================================

        return Scaffold(
          backgroundColor:
              const Color(0xFFE4EDE6),

          body: SafeArea(
            child: screens[_currentIndex],
          ),

          // ======================================================
          // BOTTOM NAVIGATION
          // ======================================================

          bottomNavigationBar:
              BottomNavigationBar(
            currentIndex:
                _currentIndex,

            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },

            type:
                BottomNavigationBarType.fixed,

            backgroundColor:
                Colors.white,

            selectedItemColor:
                const Color(0xFF134E39),

            unselectedItemColor:
                const Color(0xFF5A7865),

            selectedLabelStyle:
                GoogleFonts.poppins(
              fontSize: 12,
              fontWeight:
                  FontWeight.bold,
            ),

            unselectedLabelStyle:
                GoogleFonts.poppins(
              fontSize: 12,
              fontWeight:
                  FontWeight.w500,
            ),

            items: const [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.home_outlined,
                ),
                activeIcon: Icon(
                  Icons.home,
                ),
                label: 'Home',
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.eco_outlined,
                ),
                activeIcon: Icon(
                  Icons.eco,
                ),
                label: 'Plants',
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.notifications_outlined,
                ),
                activeIcon: Icon(
                  Icons.notifications,
                ),
                label: 'Notifications',
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.person_outline,
                ),
                activeIcon: Icon(
                  Icons.person,
                ),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // HOME SCREEN
  // ============================================================

  Widget _buildHomeScreen({
    required String greeting,
    required double? temperature,
    required double? humidity,
    required double? lightIntensity,
    required SoilResult soil,
    required bool sensorDataAvailable,
    required String temperatureStatus,
    required String humidityStatus,
    required String lightStatus,
  }) {
    return SingleChildScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,

        children: [
          // ======================================================
          // HEADER
          // ======================================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      '$greeting,',
                      style:
                          GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            const Color(
                          0xFF134E39,
                        ),
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      _userName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            const Color(
                          0xFF134E39,
                        ),
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Monitor your smart plants effortlessly.',
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w500,
                        color:
                            const Color(
                          0xFF5A7865,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // ==================================================
              // NOTIFICATION
              // ==================================================

              Container(
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: IconButton(
                  icon: const Icon(
                    Icons
                        .notifications_outlined,
                    color:
                        Color(0xFF134E39),
                  ),

                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              // ==================================================
              // PROFILE
              // ==================================================

              GestureDetector(
                onTap: _openProfile,

                child: Container(
                  width: 48,
                  height: 48,

                  decoration:
                      const BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Color(0xFFD0E2D4),
                  ),

                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color:
                          Color(0xFF134E39),
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          // ======================================================
          // PLANT OVERVIEW
          // ======================================================

          Text(
            'Plant Overview',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
              color:
                  const Color(0xFF134E39),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          StreamBuilder<DatabaseEvent>(
            stream: _plantsRef.onValue,

            builder: (
              context,
              plantSnapshot,
            ) {
              int totalPlants = 0;

              if (plantSnapshot.hasData) {
                final Object? value =
                    plantSnapshot
                        .data!
                        .snapshot
                        .value;

                if (value is Map) {
                  totalPlants =
                      value.length;
                }
              }

              return GridView.count(
                crossAxisCount: 2,

                crossAxisSpacing: 12,
                mainAxisSpacing: 12,

                shrinkWrap: true,

                physics:
                    const NeverScrollableScrollPhysics(),

                childAspectRatio: 1.55,

                children: [
                  // =================================================
                  // TOTAL PLANTS
                  // =================================================

                  SummaryCard(
                    title:
                        'Total Plants',
                    value:
                        totalPlants
                            .toString(),
                    icon:
                        Icons
                            .eco_outlined,
                    iconColor:
                        Colors.green,
                  ),

                  // =================================================
                  // SENSOR READINGS
                  // =================================================

                  SummaryCard(
                    title:
                        'Sensor Readings',
                    value:
                        sensorDataAvailable
                            ? '4'
                            : '0',
                    icon:
                        Icons
                            .sensors_outlined,
                    iconColor:
                        Colors.blue,
                  ),

                  // =================================================
                  // SOIL MONITORING
                  // =================================================

                  SummaryCard(
                    title:
                        'Soil Monitoring',

                    value:
                        soil.status ==
                                'Waiting'
                            ? 'Waiting'
                            : soil.message,

                    subtitle:
                        soil.status ==
                                'Waiting'
                            ? null
                            : soil.status,

                    icon:
                        Icons
                            .water_drop_outlined,

                    iconColor:
                        _soilColor(),
                  ),

                  // =================================================
                  // DEVICE
                  // =================================================

                  SummaryCard(
                    title:
                        'Device',

                    value:
                        _deviceConnected
                            ? 'Connected'
                            : 'Offline',

                    icon:
                        Icons
                            .devices_outlined,

                    iconColor:
                        _deviceColor(),
                  ),
                ],
              );
            },
          ),

          const SizedBox(
            height: 24,
          ),

          // ======================================================
          // ENVIRONMENT MONITORING
          // ======================================================

          Text(
            'Environment Monitoring',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
              color:
                  const Color(0xFF134E39),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // TEMPERATURE
          // ======================================================

          SensorCard(
            title: 'Temperature',

            value:
                temperature != null
                    ? '${temperature.toStringAsFixed(1)}°C'
                    : 'Waiting...',

            icon:
                Icons.thermostat,

            iconColor:
                Colors.orange,

            status:
                temperatureStatus,
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // SOIL
          // ======================================================

          SensorCard(
            title:
                'Soil Status',

            value:
                sensorDataAvailable
                    ? soil.status
                    : 'Waiting...',

            icon:
                Icons.grass,

            iconColor:
                _soilColor(),

            status:
                sensorDataAvailable
                    ? soil.message
                    : 'Waiting',
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // HUMIDITY
          // ======================================================

          SensorCard(
            title:
                'Humidity',

            value:
                humidity != null
                    ? '${humidity.toStringAsFixed(1)}%'
                    : 'Waiting...',

            icon:
                Icons.air,

            iconColor:
                Colors.blue,

            status:
                humidityStatus,
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // LIGHT
          // ======================================================

          SensorCard(
            title:
                'Light Intensity',

            value:
                lightIntensity != null
                    ? lightIntensity
                        .toStringAsFixed(0)
                    : 'Waiting...',

            unit:
                'lux',

            icon:
                Icons
                    .wb_sunny_outlined,

            iconColor:
                Colors.amber,

            status:
                lightStatus,
          ),

          const SizedBox(
            height: 24,
          ),

          // ======================================================
          // QUICK ACTIONS
          // ======================================================

          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
              color:
                  const Color(0xFF134E39),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              Expanded(
                child:
                    QuickActionCard(
                  title:
                      'Add Plant',

                  icon:
                      Icons
                          .add_circle_outline,

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const AddPlantScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    QuickActionCard(
                  title:
                      'Device Setup',

                  icon:
                      Icons
                          .settings_input_antenna_rounded,

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const DeviceSetupScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          // ======================================================
          // RECENT ACTIVITY
          // ======================================================

          Text(
            'Recent Activity',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
              color:
                  const Color(0xFF134E39),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          const Column(
            children: [
              RecentActivityCard(
                title:
                    'Irrigation started',
                time:
                    '2 hours ago',
                icon:
                    Icons.water_drop,
              ),

              RecentActivityCard(
                title:
                    'ESP32 Device connected',
                time:
                    '5 hours ago',
                icon:
                    Icons.wifi,
              ),

              RecentActivityCard(
                title:
                    'Sensor telemetry updated',
                time:
                    'Just now',
                icon:
                    Icons.sync,
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SOIL RESULT MODEL
// ================================================================

class SoilResult {
  final String status;
  final String message;

  const SoilResult({
    required this.status,
    required this.message,
  });
}