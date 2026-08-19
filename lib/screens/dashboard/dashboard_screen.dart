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
  int _currentIndex = 0;

  // ============================================================
  // FIREBASE REFERENCES
  // ============================================================

  final DatabaseReference _plantRef =
      FirebaseDatabase.instance.ref('SmartPlant');

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // USER NAME
  // ============================================================

  String _userName = 'User';

  bool _isLoadingUserName = true;

  // ============================================================
  // CURRENT USER'S PLANTS
  // ============================================================

  DatabaseReference get _userPlantsRef {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return FirebaseDatabase.instance.ref(
        'Users/invalid/Plants',
      );
    }

    return FirebaseDatabase.instance.ref(
      'Users/$uid/Plants',
    );
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadUserProfile();
  }

  // ============================================================
  // LOAD USER PROFILE FROM FIRESTORE
  // ============================================================

  Future<void> _loadUserProfile() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _userName = 'User';
            _isLoadingUserName = false;
          });
        }

        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      if (snapshot.exists) {
        final data = snapshot.data();

        final String name =
            data?['name']?.toString().trim() ?? '';

        if (mounted) {
          setState(() {
            if (name.isNotEmpty) {
              _userName = name;
            } else {
              _userName = _getNameFromEmail(user.email);
            }

            _isLoadingUserName = false;
          });
        }
      } else {
        // Fallback to Firebase Authentication display name/email
        if (mounted) {
          setState(() {
            _userName = user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : _getNameFromEmail(user.email);

            _isLoadingUserName = false;
          });
        }
      }
    } catch (e) {
      debugPrint(
        'ERROR LOADING USER PROFILE: $e',
      );

      final User? user = _auth.currentUser;

      if (mounted) {
        setState(() {
          _userName = user?.displayName?.trim().isNotEmpty == true
              ? user!.displayName!.trim()
              : _getNameFromEmail(user?.email);

          _isLoadingUserName = false;
        });
      }
    }
  }

  // ============================================================
  // EMAIL FALLBACK NAME
  // ============================================================

  String _getNameFromEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'User';
    }

    final String namePart = email.split('@').first;

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
  // SENSOR STATUS HELPERS
  // ============================================================

  String _getSoilStatus(String soilStatus) {
    final status = soilStatus.toLowerCase();

    if (status.contains('dry') ||
        status.contains('needs water')) {
      return 'Needs Water';
    }

    if (status.contains('wet') ||
        status.contains('moist') ||
        status.contains('normal')) {
      return 'Normal';
    }

    if (status == 'waiting...' ||
        status.isEmpty) {
      return 'Waiting';
    }

    return 'Live';
  }

  String _getTemperatureStatus(double temperature) {
    if (temperature < 10) {
      return 'Low';
    }

    if (temperature > 40) {
      return 'High';
    }

    return 'Normal';
  }

  String _getHumidityStatus(double humidity) {
    if (humidity < 30) {
      return 'Low';
    }

    if (humidity > 80) {
      return 'High';
    }

    return 'Normal';
  }

  String _getLightStatus(double lightIntensity) {
    if (lightIntensity < 100) {
      return 'Low';
    }

    if (lightIntensity > 1000) {
      return 'High';
    }

    return 'Normal';
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
      stream: _plantRef.onValue,
      builder: (context, sensorSnapshot) {
        // ========================================================
        // DEFAULT SENSOR VALUES
        // ========================================================

        double temperature = 0.0;
        double humidity = 0.0;
        double lightIntensity = 0.0;

        String soilStatus = 'Waiting...';

        bool sensorDataAvailable = false;

        // ========================================================
        // READ LIVE SENSOR DATA
        // ========================================================

        if (sensorSnapshot.hasData &&
            sensorSnapshot.data!.snapshot.value != null) {
          final rawValue =
              sensorSnapshot.data!.snapshot.value;

          if (rawValue is Map) {
            final data =
                Map<dynamic, dynamic>.from(rawValue);

            temperature =
                double.tryParse(
                      data['Temperature']
                              ?.toString() ??
                          '',
                    ) ??
                    0.0;

            humidity =
                double.tryParse(
                      data['Humidity']
                              ?.toString() ??
                          '',
                    ) ??
                    0.0;

            lightIntensity =
                double.tryParse(
                      data['LightIntensity']
                              ?.toString() ??
                          '',
                    ) ??
                    0.0;

            soilStatus =
                data['SoilStatus']?.toString() ??
                    'Waiting...';

            sensorDataAvailable = true;
          }
        }

        // ========================================================
        // SENSOR STATUS
        // ========================================================

        final String temperatureStatus =
            sensorDataAvailable
                ? _getTemperatureStatus(
                    temperature,
                  )
                : 'Waiting';

        final String soilStatusLabel =
            sensorDataAvailable
                ? _getSoilStatus(
                    soilStatus,
                  )
                : 'Waiting';

        final String humidityStatus =
            sensorDataAvailable
                ? _getHumidityStatus(
                    humidity,
                  )
                : 'Waiting';

        final String lightStatus =
            sensorDataAvailable
                ? _getLightStatus(
                    lightIntensity,
                  )
                : 'Waiting';

        // ========================================================
        // DYNAMIC GREETING
        // ========================================================

        final String greeting = _getGreeting();

        // ========================================================
        // ALL SCREENS
        // ========================================================

        final List<Widget> screens = [
          // ======================================================
          // HOME DASHBOARD
          // ======================================================

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                // =================================================
                // HEADER
                // =================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ------------------------------------------------
                    // GREETING
                    // ------------------------------------------------

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoadingUserName
                                ? '$greeting,'
                                : '$greeting,\n$_userName',
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

                    // ------------------------------------------------
                    // NOTIFICATION + PROFILE
                    // ------------------------------------------------

                    Row(
                      children: [
                        // =================================================
                        // NOTIFICATIONS
                        // =================================================

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
                                  builder:
                                      (context) =>
                                          const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        // =================================================
                        // PROFILE ICON
                        // =================================================

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
                  ],
                ),

                const SizedBox(
                  height: 24,
                ),

                // =================================================
                // PLANT OVERVIEW
                // =================================================

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

                // =================================================
                // USER PLANTS
                // =================================================

                StreamBuilder<DatabaseEvent>(
                  stream: _userPlantsRef.onValue,
                  builder:
                      (
                        context,
                        plantSnapshot,
                      ) {
                    int totalPlants = 0;

                    if (plantSnapshot.hasData &&
                        plantSnapshot
                                .data!
                                .snapshot
                                .value !=
                            null) {
                      final value =
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
                      childAspectRatio: 1.5,
                      children: [
                        SummaryCard(
                          title: 'Total Plants',
                          value:
                              totalPlants
                                  .toString(),
                          icon:
                              Icons.eco_outlined,
                        ),

                        SummaryCard(
                          title:
                              'Sensor Readings',
                          value:
                              sensorDataAvailable
                                  ? '4'
                                  : '0',
                          icon:
                              Icons.sensors,
                        ),

                        SummaryCard(
                          title: 'Soil',
                          value:
                              sensorDataAvailable
                                  ? soilStatusLabel
                                  : 'Waiting',
                          icon:
                              Icons
                                  .water_drop_outlined,
                        ),

                        SummaryCard(
                          title: 'Device',
                          value:
                              sensorDataAvailable
                                  ? 'Connected'
                                  : 'Offline',
                          icon: Icons.wifi,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(
                  height: 24,
                ),

                // =================================================
                // ENVIRONMENT MONITORING
                // =================================================

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

                Column(
                  children: [
                    // =================================================
                    // TEMPERATURE
                    // =================================================

                    SensorCard(
                      title: 'Temperature',
                      value:
                          sensorDataAvailable
                              ? '${temperature.toStringAsFixed(1)}°C'
                              : 'Waiting...',
                      icon:
                          Icons.thermostat,
                      status:
                          temperatureStatus,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // =================================================
                    // SOIL
                    // =================================================

                    SensorCard(
                      title: 'Soil Status',
                      value:
                          sensorDataAvailable
                              ? soilStatus
                              : 'Waiting...',
                      icon: Icons.grass,
                      status:
                          soilStatusLabel,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // =================================================
                    // HUMIDITY
                    // =================================================

                    SensorCard(
                      title: 'Humidity',
                      value:
                          sensorDataAvailable
                              ? '${humidity.toStringAsFixed(1)}%'
                              : 'Waiting...',
                      icon: Icons.air,
                      status:
                          humidityStatus,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // =================================================
                    // LIGHT
                    // =================================================

                    SensorCard(
                      title:
                          'Light Intensity',
                      value:
                          sensorDataAvailable
                              ? lightIntensity
                                  .toStringAsFixed(
                                  1,
                                )
                              : 'Waiting...',
                      icon: Icons
                          .wb_sunny_outlined,
                      status:
                          lightStatus,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 24,
                ),

                // =================================================
                // QUICK ACTIONS
                // =================================================

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
                      child: QuickActionCard(
                        title: 'Add Plant',
                        icon: Icons
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
                      child: QuickActionCard(
                        title: 'Device Setup',
                        icon: Icons
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

                // =================================================
                // RECENT ACTIVITY
                // =================================================

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
                      time: '2 hours ago',
                      icon:
                          Icons.water_drop,
                    ),

                    RecentActivityCard(
                      title:
                          'ESP8266 Device connected',
                      time: '5 hours ago',
                      icon: Icons.wifi,
                    ),

                    RecentActivityCard(
                      title:
                          'Sensor telemetry updated',
                      time: 'Just now',
                      icon: Icons.sync,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 24,
                ),
              ],
            ),
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
}