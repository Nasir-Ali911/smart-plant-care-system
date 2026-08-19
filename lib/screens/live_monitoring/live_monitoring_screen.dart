import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:smart_plant_care/screens/live_monitoring/widgets/device_status_card.dart';
import 'package:smart_plant_care/screens/live_monitoring/widgets/sensor_card.dart';
import 'package:smart_plant_care/screens/live_monitoring/widgets/irrigation_control_card.dart';
import 'package:smart_plant_care/screens/live_monitoring/widgets/device_info_card.dart';
import 'package:smart_plant_care/screens/live_monitoring/widgets/recent_logs_card.dart';

class LiveMonitoringScreen extends StatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  State<LiveMonitoringScreen> createState() => _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends State<LiveMonitoringScreen> {
  final DatabaseReference _plantRef =
      FirebaseDatabase.instance.ref('SmartPlant');

  bool _isRefreshing = false;

  // ------------------------------------------------------------
  // Safely convert Firebase values to double
  // ------------------------------------------------------------
  double? _parseDouble(dynamic value) {
    if (value == null) return null;

    return double.tryParse(value.toString());
  }

  // ------------------------------------------------------------
  // Manual refresh
  //
  // Realtime Database already updates automatically through
  // onValue, so there is technically nothing to "download".
  // This button simply gives the user confirmation.
  // ------------------------------------------------------------
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Small visual delay so the user sees the refresh action.
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isRefreshing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Live sensor data is being monitored from Firebase.',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF134E39),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ------------------------------------------------------------
  // Determine sensor status
  // ------------------------------------------------------------
  String _temperatureStatus(double? temperature) {
    if (temperature == null) return 'No Data';

    if (temperature >= 18 && temperature <= 35) {
      return 'Optimal';
    }

    if (temperature < 18) {
      return 'Too Low';
    }

    return 'Too High';
  }

  String _humidityStatus(double? humidity) {
    if (humidity == null) return 'No Data';

    if (humidity >= 40 && humidity <= 80) {
      return 'Optimal';
    }

    if (humidity < 40) {
      return 'Low';
    }

    return 'High';
  }

  String _soilStatus(String soilStatus) {
    if (soilStatus == '--' || soilStatus.isEmpty) {
      return 'No Data';
    }

    final lower = soilStatus.toLowerCase();

    if (lower.contains('dry') || lower.contains('water')) {
      return 'Needs Water';
    }

    if (lower.contains('wet') || lower.contains('moist')) {
      return 'Moist';
    }

    return 'Normal';
  }

  String _lightStatus(double? lightIntensity) {
    if (lightIntensity == null) return 'No Data';

    // This is a basic prototype-level interpretation.
    if (lightIntensity >= 300 && lightIntensity <= 1000) {
      return 'Optimal';
    }

    if (lightIntensity < 300) {
      return 'Low';
    }

    return 'High';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Optimal':
      case 'Moist':
      case 'Normal':
        return const Color(0xFF134E39);

      case 'Needs Water':
      case 'Low':
      case 'High':
      case 'Too Low':
      case 'Too High':
        return Colors.orange;

      case 'No Data':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF134E39),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Live Monitoring',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E39),
          ),
        ),
      ),

      // ----------------------------------------------------------
      // LIVE FIREBASE STREAM
      // ----------------------------------------------------------
      body: StreamBuilder<DatabaseEvent>(
        stream: _plantRef.onValue,

        builder: (context, snapshot) {
          // ------------------------------------------------------
          // Default values
          // ------------------------------------------------------
          double? temperature;
          double? humidity;
          double? lightIntensity;

          String soilStatus = '--';

          bool hasTelemetry = false;

          // ------------------------------------------------------
          // Read Firebase SmartPlant node
          // ------------------------------------------------------
          if (snapshot.hasData &&
              snapshot.data!.snapshot.exists &&
              snapshot.data!.snapshot.value != null) {
            final rawData = snapshot.data!.snapshot.value;

            if (rawData is Map) {
              final data = Map<dynamic, dynamic>.from(rawData);

              temperature = _parseDouble(data['Temperature']);

              humidity = _parseDouble(data['Humidity']);

              lightIntensity =
                  _parseDouble(data['LightIntensity']);

              soilStatus =
                  data['SoilStatus']?.toString() ?? '--';

              hasTelemetry =
                  temperature != null ||
                  humidity != null ||
                  lightIntensity != null ||
                  soilStatus != '--';
            }
          }

          // ------------------------------------------------------
          // Sensor statuses
          // ------------------------------------------------------
          final String temperatureStatus =
              _temperatureStatus(temperature);

          final String humidityStatus =
              _humidityStatus(humidity);

          final String soilStatusLabel =
              _soilStatus(soilStatus);

          final String lightStatus =
              _lightStatus(lightIntensity);

          // ------------------------------------------------------
          // Device connection status
          //
          // For this prototype, the presence of live telemetry
          // indicates that the ESP8266 is communicating with
          // Firebase.
          // ------------------------------------------------------
          final bool deviceConnected = hasTelemetry;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                // ==================================================
                // DEVICE STATUS
                // ==================================================
                DeviceStatusCard(
                  // If your current DeviceStatusCard does not
                  // accept parameters, see note below.
                ),

                const SizedBox(height: 20),

                // ==================================================
                // CONNECTION INFORMATION
                // ==================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        deviceConnected
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color: deviceConnected
                            ? const Color(0xFF134E39)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          deviceConnected
                              ? 'ESP8266 telemetry connected to Firebase'
                              : 'Waiting for ESP8266 telemetry',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF134E39),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // SENSOR READINGS
                // ==================================================
                Text(
                  'Live Sensor Readings',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF134E39),
                  ),
                ),

                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.3,

                  children: [

                    // ------------------------------------------------
                    // TEMPERATURE
                    // ------------------------------------------------
                    SensorCard(
                      title: 'Temperature',
                      value: temperature != null
                          ? '${temperature.toStringAsFixed(1)}°C'
                          : '-- °C',
                      status: temperatureStatus,
                      icon: Icons.thermostat,
                      statusColor:
                          _statusColor(temperatureStatus),
                    ),

                    // ------------------------------------------------
                    // HUMIDITY
                    // ------------------------------------------------
                    SensorCard(
                      title: 'Humidity',
                      value: humidity != null
                          ? '${humidity.toStringAsFixed(1)}%'
                          : '-- %',
                      status: humidityStatus,
                      icon: Icons.air,
                      statusColor:
                          _statusColor(humidityStatus),
                    ),

                    // ------------------------------------------------
                    // SOIL STATUS
                    // ------------------------------------------------
                    SensorCard(
                      title: 'Soil Status',
                      value: soilStatus,
                      status: soilStatusLabel,
                      icon: Icons.water_drop,
                      statusColor:
                          _statusColor(soilStatusLabel),
                    ),

                    // ------------------------------------------------
                    // LIGHT
                    // ------------------------------------------------
                    SensorCard(
                      title: 'Light Intensity',
                      value: lightIntensity != null
                          ? lightIntensity.toStringAsFixed(1)
                          : '--',
                      status: lightStatus,
                      icon: Icons.wb_sunny_outlined,
                      statusColor:
                          _statusColor(lightStatus),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ==================================================
                // IRRIGATION
                // ==================================================
                const IrrigationControlCard(),

                const SizedBox(height: 20),

                // ==================================================
                // DEVICE INFORMATION
                // ==================================================
                const DeviceInfoCard(),

                const SizedBox(height: 20),

                // ==================================================
                // RECENT LOGS
                // ==================================================
                const RecentLogsCard(),

                const SizedBox(height: 30),

                // ==================================================
                // REFRESH
                // ==================================================
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed:
                        _isRefreshing ? null : _handleRefresh,

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF134E39),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),

                    child: _isRefreshing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Refresh Data',
                            style:
                                GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}