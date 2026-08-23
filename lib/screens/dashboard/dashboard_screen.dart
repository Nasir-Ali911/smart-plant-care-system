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
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late DatabaseReference _smartPlantRef;
  late DatabaseReference _plantsRef;

  // ============================================================
  // USER
  // ============================================================

  String _userName = 'User';
  bool _isLoadingProfile = true;

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
  // LOAD USER PROFILE
  // ============================================================

  Future<void> _loadUserProfile() async {
    if (mounted) {
      setState(() {
        _isLoadingProfile = true;
      });
    }

    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _userName = 'User';
            _isLoadingProfile = false;
          });
        }
        return;
      }

      // Try Firestore user profile first
      try {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _firestore.collection('users').doc(user.uid).get();

        if (snapshot.exists) {
          final Map<String, dynamic>? data = snapshot.data();
          final String name = data?['name']?.toString().trim() ?? '';

          if (name.isNotEmpty) {
            if (mounted) {
              setState(() {
                _userName = _formatName(name);
                _isLoadingProfile = false;
              });
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('Firestore profile lookup failed: $e');
      }

      // Firebase Auth fallback
      final String displayName = user.displayName?.trim() ?? '';

      if (displayName.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userName = _formatName(displayName);
            _isLoadingProfile = false;
          });
        }
        return;
      }

      // Email fallback
      if (mounted) {
        setState(() {
          _userName = _formatName(
            _getNameFromEmail(user.email),
          );
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('ERROR LOADING USER PROFILE: $e');

      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
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
        .where((word) => word.isNotEmpty)
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

    final String namePart = email.split('@').first;

    return namePart.isEmpty ? 'User' : namePart;
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

  SoilResult _processSoilStatus(String value) {
    if (value.trim().isEmpty) {
      return const SoilResult(
        status: 'Waiting',
        message: 'Waiting for sensor data',
      );
    }

    final String upper = value.toUpperCase();

    if (upper.contains('DRY')) {
      return const SoilResult(
        status: 'DRY',
        message: 'Needs Water',
      );
    }

    if (upper.contains('MOIST')) {
      return const SoilResult(
        status: 'MOIST',
        message: 'Healthy',
      );
    }

    if (upper.contains('WET')) {
      return const SoilResult(
        status: 'WET',
        message: 'Well Watered',
      );
    }

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

  String _getTemperatureStatus(double value) {
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

  String _getHumidityStatus(double value) {
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

  String _getLightStatus(double value) {
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

  double? _toDouble(dynamic value) {
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
    if (deviceValue == null) {
      return temperature != null ||
          humidity != null ||
          light != null ||
          (soilStatus != null && soilStatus.isNotEmpty);
    }

    if (deviceValue is bool) {
      return deviceValue;
    }

    final String value =
        deviceValue.toString().trim().toLowerCase();

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
        return Colors.green;

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
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _smartPlantRef.onValue,
      builder: (context, sensorSnapshot) {
        // Loading state
        if (sensorSnapshot.connectionState ==
            ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Error state
        if (sensorSnapshot.hasError) {
          return _buildErrorScreen(
            sensorSnapshot.error.toString(),
          );
        }

        // ========================================================
        // SENSOR DATA
        // ========================================================

        double? temperature;
        double? humidity;
        double? lightIntensity;

        String soilStatusValue = '';

        bool sensorDataAvailable = false;
        bool deviceConnected = false;

        if (sensorSnapshot.hasData &&
            sensorSnapshot.data!.snapshot.value != null) {
          final Object? rawValue =
              sensorSnapshot.data!.snapshot.value;

          if (rawValue is Map) {
            final Map<dynamic, dynamic> data =
                Map<dynamic, dynamic>.from(rawValue);

            temperature = _toDouble(
              data['Temperature'],
            );

            humidity = _toDouble(
              data['Humidity'],
            );

            lightIntensity = _toDouble(
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

            deviceConnected = _getDeviceStatus(
              data['Device'],
              temperature: temperature,
              humidity: humidity,
              light: lightIntensity,
              soilStatus: soilStatusValue,
            );

            _deviceConnected = deviceConnected;
            _temperature = temperature;
            _humidity = humidity;
            _lightIntensity = lightIntensity;

            if (sensorDataAvailable) {
              final SoilResult soil =
                  _processSoilStatus(
                soilStatusValue,
              );

              _soilStatus = soil.status;
              _soilMessage = soil.message;
            }
          }
        }

        // ========================================================
        // SOIL
        // ========================================================

        final SoilResult soil =
            sensorDataAvailable
                ? _processSoilStatus(
                    soilStatusValue,
                  )
                : const SoilResult(
                    status: 'Waiting',
                    message: 'Waiting for sensor data',
                  );

        // ========================================================
        // SENSOR STATUS
        // ========================================================

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

        // ========================================================
        // GREETING
        // ========================================================

        final String greeting = _getGreeting();

        // ========================================================
        // SCREENS
        // ========================================================

        final List<Widget> screens = [
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
            lightStatus: lightStatus,
            deviceConnected:
                deviceConnected,
          ),
          const PlantsScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ];

        // ========================================================
        // SCAFFOLD
        // ========================================================

        return Scaffold(
          backgroundColor:
              const Color(0xFFE4EDE6),

          body: SafeArea(
            child: AnimatedSwitcher(
              duration:
                  const Duration(milliseconds: 300),
              transitionBuilder:
                  (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child:
                    screens[_currentIndex],
              ),
            ),
          ),

          // ======================================================
          // BOTTOM NAVIGATION
          // ======================================================

          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset:
                      const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
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
          ),
        );
      },
    );
  }

  // ============================================================
  // LOADING SCREEN
  // ============================================================

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor:
          const Color(0xFFE4EDE6),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF134E39),
              strokeWidth: 3,
            ),

            const SizedBox(height: 20),

            Text(
              'Loading your dashboard...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight:
                    FontWeight.w500,
                color:
                    const Color(0xFF5A7865),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR SCREEN
  // ============================================================

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFE4EDE6),

      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Container(
                width: 80,
                height: 80,

                decoration:
                    BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red
                      .withOpacity(0.1),
                ),

                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Unable to load data',
                style:
                    GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      const Color(0xFF134E39),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Please check your connection and try again',
                textAlign:
                    TextAlign.center,
                style:
                    GoogleFonts.poppins(
                  fontSize: 14,
                  color:
                      const Color(0xFF5A7865),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF134E39,
                  ),
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),

                child: Text(
                  'Retry',
                  style:
                      GoogleFonts.poppins(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    required bool deviceConnected,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadUserProfile();

        if (mounted) {
          setState(() {});
        }
      },

      color:
          const Color(0xFF134E39),

      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding: EdgeInsets.symmetric(
          horizontal:
              MediaQuery.of(context).size.width *
                  0.05,
          vertical: 16,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            // ====================================================
            // HEADER
            // ====================================================

            _buildHeader(greeting),

            const SizedBox(height: 24),

            // ====================================================
            // PLANT OVERVIEW
            // ====================================================

            Text(
              'Plant Overview',
              style:
                  GoogleFonts.poppins(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
                color:
                    const Color(0xFF134E39),
              ),
            ),

            const SizedBox(height: 12),

            _buildPlantOverview(
              sensorDataAvailable,
              soil,
              deviceConnected,
            ),

            const SizedBox(height: 24),

            // ====================================================
            // ENVIRONMENT MONITORING
            // ====================================================

            Text(
              'Environment Monitoring',
              style:
                  GoogleFonts.poppins(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
                color:
                    const Color(0xFF134E39),
              ),
            ),

            const SizedBox(height: 12),

            _buildSensorCards(
              temperature: temperature,
              humidity: humidity,
              lightIntensity:
                  lightIntensity,
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

            const SizedBox(height: 24),

            // ====================================================
            // QUICK ACTIONS
            // ====================================================

            Text(
              'Quick Actions',
              style:
                  GoogleFonts.poppins(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
                color:
                    const Color(0xFF134E39),
              ),
            ),

            const SizedBox(height: 12),

            _buildQuickActions(),

            const SizedBox(height: 24),

            // ====================================================
            // RECENT ACTIVITY
            // ====================================================

            Text(
              'Recent Activity',
              style:
                  GoogleFonts.poppins(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
                color:
                    const Color(0xFF134E39),
              ),
            ),

            const SizedBox(height: 12),

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
                      'ESP8622 Device connected',
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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(String greeting) {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  _buildNotificationButton(),

                  const SizedBox(width: 8),

                  _buildProfileAvatar(),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                '$greeting,',
                style:
                    GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      const Color(0xFF134E39),
                  height: 1.2,
                ),
              ),

              Text(
                _userName,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      const Color(0xFF134E39),
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 4),

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
                      const Color(0xFF5A7865),
                ),
              ),
            ],
          );
        }

        return Row(
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

                  const SizedBox(height: 2),

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

                  const SizedBox(height: 4),

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

            const SizedBox(width: 10),

            _buildNotificationButton(),

            const SizedBox(width: 8),

            _buildProfileAvatar(),
          ],
        );
      },
    );
  }

  // ============================================================
  // NOTIFICATION BUTTON
  // ============================================================

  Widget _buildNotificationButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: IconButton(
        icon: const Icon(
          Icons.notifications_outlined,
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
    );
  }

  // ============================================================
  // PROFILE AVATAR
  // ============================================================

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: _openProfile,

      child: Container(
        width: 48,
        height: 48,

        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              const Color(0xFFD0E2D4),
          border: Border.all(
            color:
                const Color(0xFF134E39)
                    .withOpacity(0.3),
            width: 2,
          ),
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
    );
  }

  // ============================================================
  // PLANT OVERVIEW
  // ============================================================

  Widget _buildPlantOverview(
    bool sensorDataAvailable,
    SoilResult soil,
    bool deviceConnected,
  ) {
    return StreamBuilder<DatabaseEvent>(
      stream: _plantsRef.onValue,

      builder:
          (context, plantSnapshot) {
        int totalPlants = 0;

        if (plantSnapshot.hasData) {
          final Object? value =
              plantSnapshot
                  .data!
                  .snapshot
                  .value;

          if (value is Map) {
            totalPlants = value.length;
          }
        }

        return GridView.count(
          crossAxisCount:
              MediaQuery.of(context)
                          .size
                          .width >
                      600
                  ? 4
                  : 2,

          crossAxisSpacing: 12,

          mainAxisSpacing: 12,

          shrinkWrap: true,

          physics:
              const NeverScrollableScrollPhysics(),

          childAspectRatio: 1.55,

          children: [
            SummaryCard(
              title: 'Total Plants',
              value:
                  totalPlants.toString(),
              icon:
                  Icons.eco_outlined,
              iconColor:
                  Colors.green,
            ),

            SummaryCard(
              title: 'Sensor Readings',
              value:
                  sensorDataAvailable
                      ? '4'
                      : '0',
              icon:
                  Icons.sensors_outlined,
              iconColor:
                  Colors.blue,
            ),

            SummaryCard(
              title: 'Soil Monitoring',
              value:
                  soil.status == 'Waiting'
                      ? 'Waiting'
                      : soil.message,
              subtitle:
                  soil.status == 'Waiting'
                      ? null
                      : soil.status,
              icon:
                  Icons.water_drop_outlined,
              iconColor:
                  _soilColor(),
            ),

            SummaryCard(
              title: 'Device',
              value:
                  deviceConnected
                      ? 'Connected'
                      : 'Offline',
              icon:
                  Icons.devices_outlined,
              iconColor:
                  deviceConnected
                      ? Colors.green
                      : Colors.grey,
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SENSOR CARDS
  // ============================================================

  Widget _buildSensorCards({
    required double? temperature,
    required double? humidity,
    required double? lightIntensity,
    required SoilResult soil,
    required bool sensorDataAvailable,
    required String temperatureStatus,
    required String humidityStatus,
    required String lightStatus,
  }) {
    return Column(
      children: [
        // ========================================================
        // TEMPERATURE
        // ========================================================

        SensorCard(
          title: 'Temperature',

          value: temperature != null
              ? '${temperature.toStringAsFixed(1)}°C'
              : '--',

          icon: Icons.thermostat,

          iconColor: Colors.orange,

          status: temperatureStatus,

          // FIXED:
          // showLoading -> isLoading
          isLoading: temperature == null,

          isActive:
              temperature != null,
        ),

        const SizedBox(height: 12),

        // ========================================================
        // SOIL STATUS
        // ========================================================

        SensorCard(
          title: 'Soil Status',

          value:
              sensorDataAvailable
                  ? soil.status
                  : '--',

          icon: Icons.grass,

          iconColor: _soilColor(),

          status:
              sensorDataAvailable
                  ? soil.message
                  : 'Waiting',

          // FIXED:
          // showLoading -> isLoading
          isLoading:
              !sensorDataAvailable,

          isActive:
              sensorDataAvailable,
        ),

        const SizedBox(height: 12),

        // ========================================================
        // HUMIDITY
        // ========================================================

        SensorCard(
          title: 'Humidity',

          value: humidity != null
              ? '${humidity.toStringAsFixed(1)}%'
              : '--',

          icon: Icons.air,

          iconColor: Colors.blue,

          status: humidityStatus,

          // FIXED:
          // showLoading -> isLoading
          isLoading: humidity == null,

          isActive:
              humidity != null,
        ),

        const SizedBox(height: 12),

        // ========================================================
        // LIGHT INTENSITY
        // ========================================================

        SensorCard(
          title: 'Light Intensity',

          value: lightIntensity != null
              ? lightIntensity.toStringAsFixed(0)
              : '--',

          unit: 'lux',

          icon:
              Icons.wb_sunny_outlined,

          iconColor: Colors.amber,

          status: lightStatus,

          // FIXED:
          // showLoading -> isLoading
          isLoading:
              lightIntensity == null,

          isActive:
              lightIntensity != null,
        ),
      ],
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: QuickActionCard(
            title: 'Add Plant',
            icon:
                Icons.add_circle_outline,

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AddPlantScreen(),
                ),
              );
            },
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: QuickActionCard(
            title: 'Device Setup',
            icon: Icons
                .settings_input_antenna_rounded,

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const DeviceSetupScreen(),
                ),
              );
            },
          ),
        ),
      ],
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