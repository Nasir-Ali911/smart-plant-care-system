import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:smart_plant_care/models/plant_model.dart';

import 'package:smart_plant_care/screens/plant_details/widgets/plant_camera_card.dart';
import 'package:smart_plant_care/screens/plant_details/widgets/plant_header.dart';
import 'package:smart_plant_care/screens/plant_details/widgets/sensor_card.dart';
import 'package:smart_plant_care/screens/plant_details/widgets/irrigation_card.dart';
import 'package:smart_plant_care/screens/plant_details/widgets/info_tile.dart';
import 'package:smart_plant_care/screens/plant_details/widgets/section_title.dart';

import 'package:smart_plant_care/screens/edit_plant/edit_plant_screen.dart';

import 'package:smart_plant_care/services/ai_recommendation_service.dart';

class PlantDetailsScreen extends StatelessWidget {
  final PlantModel plant;

  const PlantDetailsScreen({
    super.key,
    required this.plant,
  });

  // ============================================================
  // SAFE CONVERSIONS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value
                  .toString()
                  .replaceAll(RegExp(r'[^0-9.\-]'), ''),
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
          value
                  .toString()
                  .replaceAll(RegExp(r'[^0-9\-]'), ''),
        ) ??
        0;
  }

  // ============================================================
  // TIMESTAMP PARSER
  //
  // Supports:
  // - Unix milliseconds
  // - Unix seconds
  // - ISO date strings
  // ============================================================

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      final int number = value.toInt();

      // Unix milliseconds.
      if (number > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(
          number,
        );
      }

      // Unix seconds.
      if (number > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(
          number * 1000,
        );
      }
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // SOIL STATUS NORMALIZATION
  // ============================================================

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
        return value.isEmpty ? 'UNKNOWN' : value;
    }
  }

  // ============================================================
  // DRY DURATION
  //
  // Finds the beginning of the current continuous DRY period
  // from the available historical Firebase logs.
  // ============================================================

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

    // Sort oldest -> newest.
    records.sort(
      (a, b) {
        final DateTime first =
            a['timestamp'] as DateTime;

        final DateTime second =
            b['timestamp'] as DateTime;

        return first.compareTo(second);
      },
    );

    DateTime? dryStart;

    // Scan backwards through the current continuous DRY period.
    for (int i = records.length - 1; i >= 0; i--) {
      final String status =
          records[i]['soilStatus']
              .toString()
              .trim()
              .toUpperCase();

      if (status.contains('DRY')) {
        dryStart =
            records[i]['timestamp'] as DateTime;
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

    final double hours =
        minutes / 60.0;

    return hours.clamp(
      0.0,
      24.0,
    ).toDouble();
  }

  // ============================================================
  // AI RECOMMENDATION CARD
  // ============================================================

  Widget _buildAIRecommendationCard(
    DataSnapshot sensorSnapshot,
    DataSnapshot? logSnapshot,
  ) {
    final dynamic rawData =
        sensorSnapshot.value;

    if (rawData is! Map) {
      return _buildUnavailableCard(
        'Waiting for current Firebase sensor data...',
      );
    }

    // ----------------------------------------------------------
    // Current Firebase sensor values
    // ----------------------------------------------------------

    final double temperature =
        _toDouble(
      rawData['Temperature'],
    );

    final double humidity =
        _toDouble(
      rawData['Humidity'],
    );

    final int lightIntensity =
        _toInt(
      rawData['LightIntensity'],
    );

    final String soilStatus =
        _normalizeSoilStatus(
      rawData['SoilStatus'],
    );

    // ----------------------------------------------------------
    // Historical dry duration
    // ----------------------------------------------------------

    final double dryDurationHours =
        _calculateDryDurationHours(
      logSnapshot,
      soilStatus,
    );

    // ----------------------------------------------------------
    // Recommendation
    //
    // mlProbability intentionally remains null.
    //
    // The current experimental Random Forest model is not being
    // presented as a validated production prediction model.
    // ----------------------------------------------------------

    final AIRecommendation recommendation =
        AIRecommendationService
            .generateRecommendation(
      temperature: temperature,
      humidity: humidity,
      lightIntensity: lightIntensity,
      soilStatus: soilStatus,
      dryDurationHours:
          dryDurationHours,
      mlProbability: null,
    );

    final Color urgencyColor =
        _getUrgencyColor(
      recommendation.urgency,
    );

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: urgencyColor.withValues(
            alpha: 0.12,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
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
          // ======================================================
          // RECOMMENDATION HEADER
          // ======================================================

          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.all(10),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE7F3ED,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color:
                      Color(0xFF134E39),
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  recommendation.title,
                  style:
                      GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        const Color(
                      0xFF134E39,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // MESSAGE
          // ======================================================

          Text(
            recommendation.message,
            style:
                GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 18),

          // ======================================================
          // SCORE + URGENCY
          // ======================================================

          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  label:
                      'Recommendation Score',
                  value:
                      '${recommendation.score.toStringAsFixed(0)}/100',
                  valueColor:
                      const Color(
                    0xFF134E39,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildMetricBox(
                  label: 'Urgency',
                  value:
                      recommendation
                          .urgency,
                  valueColor:
                      urgencyColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // ACTUAL FIREBASE INPUTS
          // ======================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(12),
            decoration:
                BoxDecoration(
              color:
                  Colors.grey.shade50,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              border: Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Sensor Inputs',
                  style:
                      GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        const Color(
                      0xFF134E39,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                _buildInputRow(
                  'Temperature',
                  '${temperature.toStringAsFixed(1)}°C',
                ),

                _buildInputRow(
                  'Humidity',
                  '${humidity.toStringAsFixed(1)}%',
                ),

                _buildInputRow(
                  'Light Intensity',
                  '$lightIntensity ADC',
                ),

                _buildInputRow(
                  'Soil Status',
                  soilStatus,
                ),

                _buildInputRow(
                  'Dry Duration',
                  '${dryDurationHours.toStringAsFixed(1)} hours',
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Recommendation generated from current '
            'sensor readings and available historical soil data.',
            style:
                GoogleFonts.poppins(
              fontSize: 10,
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

  // ============================================================
  // METRIC BOX
  // ============================================================

  Widget _buildMetricBox({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF4F7F5),
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
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT ROW
  // ============================================================

  Widget _buildInputRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  GoogleFonts.poppins(
                fontSize: 11,
                color:
                    Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style:
                GoogleFonts.poppins(
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
              color:
                  Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // URGENCY COLOR
  // ============================================================

  Color _getUrgencyColor(
    String urgency,
  ) {
    switch (
        urgency.trim().toUpperCase()) {
      case 'HIGH':
        return const Color(
          0xFFD64545,
        );

      case 'MEDIUM':
        return const Color(
          0xFFE08C0B,
        );

      default:
        return const Color(
          0xFF134E39,
        );
    }
  }

  // ============================================================
  // UNAVAILABLE CARD
  // ============================================================

  Widget _buildUnavailableCard(
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
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
            color:
                Color(0xFF134E39),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ----------------------------------------------------------
    // Firebase references
    // ----------------------------------------------------------

    final DatabaseReference sensorReference =
        FirebaseDatabase.instance.ref(
      'SmartPlant',
    );

    final Query logsReference =
        FirebaseDatabase.instance
            .ref('SmartPlant/Logs')
            .limitToLast(1500);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7F5),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color:
                Color(0xFF134E39),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          plant.name,
          style:
              GoogleFonts.poppins(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
            color:
                const Color(
              0xFF134E39,
            ),
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color:
                  Color(0xFF134E39),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          EditPlantScreen(
                    plant: plant,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          16.0,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // 1. PLANT HEADER
            // ==================================================

            PlantHeader(
              plant: plant,
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // 2. CAMERA
            // ==================================================

            const PlantCameraCard(),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // 3. ENVIRONMENTAL MONITORING
            // ==================================================

            const SectionTitle(
              title:
                  'Environmental Monitoring',
            ),

            const SizedBox(
              height: 8,
            ),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                SensorCard(
                  icon:
                      Icons.thermostat_outlined,
                  title:
                      'Temperature',
                  value:
                      plant.temperature,
                  status:
                      'Live',
                ),

                SensorCard(
                  icon:
                      Icons.water_drop_outlined,
                  title:
                      'Soil Moisture',
                  value:
                      plant.moisture,
                  status:
                      'Live',
                ),

                const SensorCard(
                  icon:
                      Icons.air_outlined,
                  title:
                      'Humidity',
                  value:
                      'Live',
                  status:
                      'Firebase',
                ),

                const SensorCard(
                  icon:
                      Icons.wb_sunny_outlined,
                  title:
                      'Light Intensity',
                  value:
                      'Live',
                  status:
                      'Firebase',
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // 4. AI WATERING RECOMMENDATION
            // ==================================================

            const SectionTitle(
              title:
                  'AI Watering Recommendation',
            ),

            const SizedBox(
              height: 8,
            ),

            StreamBuilder<DatabaseEvent>(
              stream:
                  sensorReference.onValue,
              builder:
                  (
                context,
                sensorSnapshot,
              ) {
                if (sensorSnapshot
                        .connectionState ==
                    ConnectionState.waiting) {
                  return Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets.all(
                      24,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child:
                        const Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                }

                if (sensorSnapshot
                    .hasError) {
                  return _buildUnavailableCard(
                    'Unable to read current Firebase sensor data.',
                  );
                }

                final DatabaseEvent?
                    sensorEvent =
                    sensorSnapshot.data;

                if (sensorEvent ==
                    null) {
                  return _buildUnavailableCard(
                    'Waiting for current Firebase sensor data...',
                  );
                }

                return StreamBuilder<
                    DatabaseEvent>(
                  stream:
                      logsReference.onValue,
                  builder:
                      (
                    context,
                    logSnapshot,
                  ) {
                    DataSnapshot?
                        historicalSnapshot;

                    if (!logSnapshot
                            .hasError &&
                        logSnapshot.data !=
                            null) {
                      historicalSnapshot =
                          logSnapshot
                              .data!
                              .snapshot;
                    }

                    return _buildAIRecommendationCard(
                      sensorEvent.snapshot,
                      historicalSnapshot,
                    );
                  },
                );
              },
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // 5. SMART IRRIGATION
            // ==================================================

            const SectionTitle(
              title:
                  'Smart Irrigation',
            ),

            const SizedBox(
              height: 8,
            ),

            const IrrigationCard(),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // 6. PLANT INFORMATION
            // ==================================================

            const SectionTitle(
              title:
                  'Plant Information',
            ),

            const SizedBox(
              height: 8,
            ),

            InfoTile(
              label:
                  'Species',
              value:
                  plant.species,
              icon:
                  Icons.eco_outlined,
            ),

            InfoTile(
              label:
                  'Location',
              value:
                  plant.location,
              icon:
                  Icons.location_on_outlined,
            ),

            // --------------------------------------------------
            // Existing static project information.
            // These are NOT being presented as Firebase history.
            // --------------------------------------------------

            const InfoTile(
              label:
                  'Planting Date',
              value:
                  '12 Jan 2026',
              icon:
                  Icons.calendar_today_outlined,
            ),

            InfoTile(
              label:
                  'Last Watered',
              value:
                  plant.lastUpdated,
              icon:
                  Icons.access_time_outlined,
            ),

            const InfoTile(
              label:
                  'Growth Stage',
              value:
                  'Vegetative',
              icon:
                  Icons.trending_up_outlined,
            ),

            const InfoTile(
              label:
                  'Sensor Status',
              value:
                  'Active',
              icon:
                  Icons.sensors_outlined,
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // 7. EXISTING RECENT LOG UI
            //
            // NOTE:
            // These entries are currently static UI content.
            // They are NOT used by the AI recommendation.
            // ==================================================

            const SectionTitle(
              title:
                  'Recent Logs',
            ),

            const SizedBox(
              height: 8,
            ),

            Container(
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(
                      alpha: 0.03,
                    ),
                    blurRadius: 10,
                    offset:
                        const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),
              child:
                  const Column(
                children: [
                  ListTile(
                    leading:
                        Icon(
                      Icons.water_drop,
                      color:
                          Color(0xFF134E39),
                    ),
                    title:
                        Text(
                      'Moisture Updated',
                    ),
                    subtitle:
                        Text(
                      'Soil moisture level stabilized',
                    ),
                    trailing:
                        Text(
                      '10m ago',
                      style:
                          TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ),

                  Divider(
                    height: 1,
                  ),

                  ListTile(
                    leading:
                        Icon(
                      Icons.thermostat,
                      color:
                          Color(0xFF134E39),
                    ),
                    title:
                        Text(
                      'Temperature Changed',
                    ),
                    subtitle:
                        Text(
                      'Recorded ambient reading',
                    ),
                    trailing:
                        Text(
                      '1h ago',
                      style:
                          TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ),

                  Divider(
                    height: 1,
                  ),

                  ListTile(
                    leading:
                        Icon(
                      Icons.power_settings_new,
                      color:
                          Color(0xFF134E39),
                    ),
                    title:
                        Text(
                      'Irrigation Started',
                    ),
                    subtitle:
                        Text(
                      'Automated cycle ran for 2 minutes',
                    ),
                    trailing:
                        Text(
                      '2h ago',
                      style:
                          TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // 8. VIEW HISTORY
            // ==================================================

            SizedBox(
              width:
                  double.infinity,
              height: 50,
              child:
                  ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF134E39,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // History navigation can be connected
                  // to AnalyticsScreen later.
                },
                child:
                    Text(
                  'View History',
                  style:
                      GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}