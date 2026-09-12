import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smart_plant_care/screens/add_plant/add_plant_screen.dart';
import 'package:smart_plant_care/screens/analytics/analytics_screen.dart';
import 'package:smart_plant_care/screens/device_setup/device_setup_screen.dart';
import 'package:smart_plant_care/screens/notifications/notifications_screen.dart';
import 'package:smart_plant_care/screens/profile/profile_screen.dart';
import 'package:smart_plant_care/screens/plants/plants_screen.dart';

import 'package:smart_plant_care/services/plant_service.dart';

import 'package:smart_plant_care/screens/dashboard/widgets/quick_action_card.dart';
import 'package:smart_plant_care/screens/dashboard/widgets/recent_activity_card.dart';
import 'package:smart_plant_care/screens/dashboard/widgets/sensor_card.dart';
import 'package:smart_plant_care/screens/dashboard/widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseDatabase _database =
      FirebaseDatabase.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final PlantService _plantService =
      PlantService();

  late DatabaseReference _smartPlantRef;
  late DatabaseReference _plantsRef;

  int _currentIndex = 0;

  String _userName = 'User';

  bool _isLoadingProfile = true;

  double? _temperature;
  double? _humidity;
  double? _lightIntensity;

  String _soilStatus = '--';
  String _deviceStatus = 'Offline';

  @override
  void initState() {
    super.initState();

    final String? uid =
        _auth.currentUser?.uid;

    _smartPlantRef =
        _database.ref('SmartPlant');

    if (uid != null) {
      _plantsRef =
          _database.ref('Users/$uid/Plants');
    } else {
      _plantsRef =
          _database.ref('Users/invalid/Plants');
    }

    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final User? user =
          _auth.currentUser;

      if (user == null) {
        return;
      }

      String name = '';

      try {
        final DocumentSnapshot snapshot =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .get();

        if (snapshot.exists) {
          final data =
              snapshot.data()
                  as Map<String, dynamic>?;

          name =
              data?['name']?.toString() ??
              data?['displayName']?.toString() ??
              '';
        }
      } catch (_) {
        // Continue with Firebase Auth data.
      }

      if (name.isEmpty) {
        name =
            user.displayName ?? '';
      }

      if (name.isEmpty &&
          user.email != null) {
        name =
            user.email!
                .split('@')
                .first;
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

  String _getGreeting() {
    final int hour =
        DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    }

    if (hour < 17) {
      return 'Good Afternoon';
    }

    return 'Good Evening';
  }

  String _getSoilStatusText(
    String status,
  ) {
    switch (status.toUpperCase()) {
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

  String _getTemperatureStatus(
    double? value,
  ) {
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

  String _getHumidityStatus(
    double? value,
  ) {
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

  String _getLightStatus(
    double? value,
  ) {
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

  Future<void> _openPlants() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const PlantsScreen(),
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

  // ============================================================
  // MANUAL WATERING
  // ============================================================

  Future<void> _startManualWatering() async {
    try {
      await _plantService
          .triggerManualWatering(true);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Pump turned ON',
          ),
          duration:
              Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to turn pump ON: $e',
          ),
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
          content: Text(
            'Pump turned OFF',
          ),
          duration:
              Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to turn pump OFF: $e',
          ),
        ),
      );
    }
  }

  Future<void> _showWateringDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
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
                Navigator.pop(context);
                await _stopManualWatering();
              },
              child: const Text(
                'Pump OFF',
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _startManualWatering();
              },
              child: const Text(
                'Pump ON',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HOME SCREEN
  // ============================================================

  Widget _buildHomeScreen() {
    return StreamBuilder<DatabaseEvent>(
      stream: _smartPlantRef.onValue,
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasError) {
          return _buildErrorScreen(
            snapshot.error.toString(),
          );
        }

        final dynamic rawData =
            snapshot.data?.snapshot.value;

        if (rawData is Map) {
          final Map<dynamic, dynamic> data =
              rawData;

          _temperature =
              _parseDouble(
            data['Temperature'],
          );

          _humidity =
              _parseDouble(
            data['Humidity'],
          );

          _lightIntensity =
              _parseDouble(
            data['LightIntensity'],
          );

          _soilStatus =
              data['SoilStatus']
                      ?.toString() ??
                  '--';

          final String device =
              data['Device']
                      ?.toString() ??
                  '';

          _deviceStatus =
              device.isEmpty
                  ? 'Offline'
                  : 'Online';
        }

        return RefreshIndicator(
          onRefresh: () async {
            try {
              await _smartPlantRef
                  .get();
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
              _buildPlantOverview(),
              const SizedBox(height: 20),
              _buildSensorCards(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildRecentActivity(),
            ],
          ),
        );
      },
    );
  }

  double? _parseDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

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
                  fontSize: 14,
                  color:
                      Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _userName,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      const Color(0xFF134E39),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed:
              _openNotifications,
          icon: const Icon(
            Icons
                .notifications_none_rounded,
          ),
        ),
        IconButton(
          onPressed: _openProfile,
          icon: const Icon(
            Icons
                .account_circle_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildPlantOverview() {
    final String soilText =
        _getSoilStatusText(
      _soilStatus,
    );

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            const Color(0xFF134E39),
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.08,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Plant Health',
                  style:
                      GoogleFonts.poppins(
                    color:
                        Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  soilText,
                  style:
                      GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withOpacity(0.14),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              _deviceStatus,
              style:
                  GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCards() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Sensor Readings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight:
                FontWeight.w600,
          ),
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
              value:
                  _temperature != null
                      ? _temperature!
                          .toStringAsFixed(1)
                      : '--',
              unit: '°C',
              icon:
                  Icons.thermostat_outlined,
              iconColor:
                  Colors.orange,
              status:
                  _getTemperatureStatus(
                _temperature,
              ),
              isLoading:
                  _temperature == null,
              isActive:
                  _temperature != null,
            ),
            SensorCard(
              title: 'Humidity',
              value:
                  _humidity != null
                      ? _humidity!
                          .toStringAsFixed(1)
                      : '--',
              unit: '%',
              icon:
                  Icons.water_drop_outlined,
              iconColor:
                  Colors.blue,
              status:
                  _getHumidityStatus(
                _humidity,
              ),
              isLoading:
                  _humidity == null,
              isActive:
                  _humidity != null,
            ),
            SensorCard(
              title: 'Light Intensity',
              value:
                  _lightIntensity != null
                      ? _lightIntensity!
                          .toStringAsFixed(0)
                      : '--',
              // ESP8266 LDR value is raw ADC,
              // not lux.
              unit: 'ADC',
              icon:
                  Icons.wb_sunny_outlined,
              iconColor:
                  Colors.amber,
              status:
                  _getLightStatus(
                _lightIntensity,
              ),
              isLoading:
                  _lightIntensity == null,
              isActive:
                  _lightIntensity != null,
            ),
            SensorCard(
              title: 'Soil Moisture',
              value:
                  _soilStatus == '--'
                      ? '--'
                      : _soilStatus,
              unit: '',
              icon:
                  Icons.grass_outlined,
              iconColor:
                  const Color(0xFF134E39),
              status:
                  _getSoilStatusText(
                _soilStatus,
              ),
              isLoading:
                  _soilStatus == '--',
              isActive:
                  _soilStatus != '--',
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight:
                FontWeight.w600,
          ),
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
                  const Color(0xFF134E39),
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
                  const Color(0xFF134E39),
              onTap:
                  _openAnalytics,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Activity',
                style:
                    GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed:
                  _openAnalytics,
              child: const Text(
                'View Analytics',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Activity 1
        RecentActivityCard(
          title:
              'Sensor monitoring active',
          subtitle:
              'Live sensor data is being received',
          time:
              'Active now',
          icon:
              Icons.sensors_outlined,
          iconColor:
              const Color(0xFF134E39),
        ),

        const SizedBox(height: 10),

        // Activity 2
        RecentActivityCard(
          title:
              'Historical logging enabled',
          subtitle:
              'Sensor readings are saved to Firebase',
          time:
              'Recently',
          icon:
              Icons.history_outlined,
          iconColor:
              Colors.blue,
        ),
      ],
    );
  }

  // ============================================================
  // LOADING / ERROR
  // ============================================================

  Widget _buildLoadingScreen() {
    return const Center(
      child: CircularProgressIndicator(),
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
            const SizedBox(height: 15),
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 20),
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

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

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
          const Color(0xFFF7F9F7),
      body: SafeArea(
        child: _buildBody(),
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
            const Color(0xFFDCEDE5),
        destinations: const [
          NavigationDestination(
            icon:
                Icon(Icons.home_outlined),
            selectedIcon:
                Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.local_florist_outlined),
            selectedIcon:
                Icon(Icons.local_florist),
            label: 'Plants',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.notifications_none),
            selectedIcon:
                Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.person_outline),
            selectedIcon:
                Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}