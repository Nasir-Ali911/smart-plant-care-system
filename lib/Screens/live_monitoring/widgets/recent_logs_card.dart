import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class RecentLogsCard extends StatelessWidget {
  const RecentLogsCard({super.key});

  // ============================================================
  // FIREBASE ROOT
  // ============================================================
  //
  // IMPORTANT:
  // Do NOT put the Firebase URL inside ref().
  //
  // FirebaseDatabase.instance.ref()
  // means the root of your Realtime Database.
  //
  static final DatabaseReference _rootRef =
      FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _rootRef.onValue,

      builder: (context, snapshot) {
        // ========================================================
        // LOADING
        // ========================================================

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCard(
            context,
            logs: const [],
            loading: true,
          );
        }

        // ========================================================
        // ERROR
        // ========================================================

        if (snapshot.hasError) {
          debugPrint(
            'RecentLogsCard Firebase Error: ${snapshot.error}',
          );

          return _buildCard(
            context,
            logs: const [],
            error: true,
          );
        }

        // ========================================================
        // NO DATA
        // ========================================================

        if (!snapshot.hasData) {
          return _buildCard(
            context,
            logs: const [],
            empty: true,
          );
        }

        final DataSnapshot rootSnapshot =
            snapshot.data!.snapshot;

        if (!rootSnapshot.exists ||
            rootSnapshot.value == null) {
          return _buildCard(
            context,
            logs: const [],
            empty: true,
          );
        }

        // ========================================================
        // ROOT DATA
        // ========================================================

        final dynamic rootValue =
            rootSnapshot.value;

        debugPrint(
          '================================================',
        );

        debugPrint(
          'RecentLogsCard: Firebase root received',
        );

        debugPrint(
          'Root type: ${rootValue.runtimeType}',
        );

        // ========================================================
        // FIND LOGS NODE
        // ========================================================

        dynamic logsData;

        if (rootValue is Map) {
          final Map<dynamic, dynamic> rootMap =
              Map<dynamic, dynamic>.from(
            rootValue,
          );

          // ------------------------------------------------------
          // OPTION 1
          //
          // /Logs
          // ------------------------------------------------------

          if (rootMap.containsKey('Logs')) {
            logsData = rootMap['Logs'];

            debugPrint(
              'RecentLogsCard: Found /Logs',
            );
          }

          // ------------------------------------------------------
          // OPTION 2
          //
          // /SmartPlant/Logs
          // ------------------------------------------------------

          if (logsData == null &&
              rootMap.containsKey('SmartPlant')) {
            final dynamic smartPlant =
                rootMap['SmartPlant'];

            if (smartPlant is Map) {
              final Map<dynamic, dynamic>
                  smartPlantMap =
                  Map<dynamic, dynamic>.from(
                smartPlant,
              );

              if (smartPlantMap.containsKey('Logs')) {
                logsData =
                    smartPlantMap['Logs'];

                debugPrint(
                  'RecentLogsCard: Found /SmartPlant/Logs',
                );
              }
            }
          }
        }

        // ========================================================
        // LOGS NOT FOUND
        // ========================================================

        if (logsData == null) {
          debugPrint(
            'RecentLogsCard: No Logs node found.',
          );

          debugPrint(
            'Firebase root data: $rootValue',
          );

          debugPrint(
            '================================================',
          );

          return _buildCard(
            context,
            logs: const [],
            empty: true,
          );
        }

        // ========================================================
        // PARSE LOGS
        // ========================================================

        final List<Map<String, dynamic>> logs =
            _parseLogs(logsData);

        debugPrint(
          'RecentLogsCard: Total logs parsed = '
          '${logs.length}',
        );

        // ========================================================
        // SORT NEWEST FIRST
        // ========================================================

        logs.sort((a, b) {
          final int timeA =
              _timestampToMilliseconds(
            a['timestamp'],
          );

          final int timeB =
              _timestampToMilliseconds(
            b['timestamp'],
          );

          return timeB.compareTo(timeA);
        });

        // ========================================================
        // TAKE ONLY FIVE
        // ========================================================

        final List<Map<String, dynamic>> recentLogs =
            logs.take(5).toList();

        // ========================================================
        // BUILD CARD
        // ========================================================

        return _buildCard(
          context,
          logs: recentLogs,
        );
      },
    );
  }

  // ============================================================
  // PARSE LOGS
  // ============================================================

  static List<Map<String, dynamic>> _parseLogs(
    dynamic logsData,
  ) {
    final List<Map<String, dynamic>> logs = [];

    if (logsData is! Map) {
      debugPrint(
        'RecentLogsCard: Logs data is not a Map.',
      );

      return logs;
    }

    final Map<dynamic, dynamic> logsMap =
        Map<dynamic, dynamic>.from(
      logsData,
    );

    logsMap.forEach((key, value) {
      // ========================================================
      // EACH LOG MUST BE A MAP
      // ========================================================

      if (value is! Map) {
        return;
      }

      final Map<dynamic, dynamic> data =
          Map<dynamic, dynamic>.from(
        value,
      );

      // ========================================================
      // DEBUG INFORMATION
      // ========================================================

      debugPrint(
        '---------------- SENSOR LOG ----------------',
      );

      debugPrint(
        'Log Key: $key',
      );

      debugPrint(
        'Complete Data: $data',
      );

      debugPrint(
        'Temperature: ${data['Temperature']}',
      );

      debugPrint(
        'Humidity: ${data['Humidity']}',
      );

      debugPrint(
        'LightIntensity: ${data['LightIntensity']}',
      );

      debugPrint(
        'SoilStatus: ${data['SoilStatus']}',
      );

      // ========================================================
      // TEMPERATURE
      // ========================================================

      final dynamic temperature =
          _getValue(
        data,
        const [
          'Temperature',
          'temperature',
          'TEMP',
          'Temp',
          'temp',
        ],
      );

      // ========================================================
      // HUMIDITY
      // ========================================================

      final dynamic humidity =
          _getValue(
        data,
        const [
          'Humidity',
          'humidity',
          'HUMIDITY',
          'Hum',
          'hum',
        ],
      );

      // ========================================================
      // LIGHT
      // ========================================================

      final dynamic light =
          _getValue(
        data,
        const [
          'LightIntensity',
          'lightIntensity',
          'Light',
          'light',
          'LDR',
          'ldr',
        ],
      );

      // ========================================================
      // SOIL
      // ========================================================

      final dynamic soil =
          _getValue(
        data,
        const [
          'SoilStatus',
          'soilStatus',
          'Soil',
          'soil',
        ],
      );

      // ========================================================
      // TIMESTAMP
      // ========================================================

      dynamic timestamp =
          _getValue(
        data,
        const [
          'Timestamp',
          'timestamp',
        ],
      );

      if (timestamp == null) {
        timestamp =
            _getValue(
          data,
          const [
            'TimestampMillis',
            'timestampMillis',
          ],
        );
      }

      // ========================================================
      // SAVE PARSED DATA
      // ========================================================

      logs.add({
        'temperature': temperature,
        'humidity': humidity,
        'light': light,
        'soil': soil,
        'timestamp': timestamp,
        'key': key.toString(),
      });

      debugPrint(
        'Parsed Temperature: $temperature',
      );

      debugPrint(
        'Parsed Humidity: $humidity',
      );

      debugPrint(
        '-------------------------------------------',
      );
    });

    return logs;
  }

  // ============================================================
  // GET VALUE FROM MAP
  // ============================================================

  static dynamic _getValue(
    Map<dynamic, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }

    return null;
  }

  // ============================================================
  // DOUBLE CONVERSION
  // ============================================================

  static double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // INTEGER CONVERSION
  // ============================================================

  static int? _toNullableInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // TIMESTAMP CONVERSION
  // ============================================================

  static int _timestampToMilliseconds(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    int timestamp;

    if (value is int) {
      timestamp = value;
    } else if (value is double) {
      timestamp = value.toInt();
    } else {
      timestamp =
          int.tryParse(
                value.toString(),
              ) ??
              0;
    }

    if (timestamp <= 0) {
      return 0;
    }

    // ----------------------------------------------------------
    // Unix timestamp in seconds
    // ----------------------------------------------------------

    if (timestamp < 100000000000) {
      return timestamp * 1000;
    }

    // ----------------------------------------------------------
    // Already milliseconds
    // ----------------------------------------------------------

    return timestamp;
  }

  // ============================================================
  // RELATIVE TIME
  // ============================================================

  static String _formatRelativeTime(
    int timestamp,
  ) {
    if (timestamp <= 0) {
      return 'Time unavailable';
    }

    final int current =
        DateTime.now()
            .millisecondsSinceEpoch;

    int difference =
        current - timestamp;

    if (difference < 0) {
      difference = 0;
    }

    final int seconds =
        difference ~/ 1000;

    if (seconds < 5) {
      return 'Just now';
    }

    if (seconds < 60) {
      return '$seconds sec ago';
    }

    final int minutes =
        seconds ~/ 60;

    if (minutes < 60) {
      return '$minutes min ago';
    }

    final int hours =
        minutes ~/ 60;

    if (hours < 24) {
      return '$hours hr ago';
    }

    final int days =
        hours ~/ 24;

    return '$days days ago';
  }

  // ============================================================
  // CLOCK TIME
  // ============================================================

  static String _formatClockTime(
    int timestamp,
  ) {
    if (timestamp <= 0) {
      return '--:--';
    }

    final DateTime date =
        DateTime.fromMillisecondsSinceEpoch(
      timestamp,
    );

    int hour = date.hour;

    final String period =
        hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    final String minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    return '$hour:$minute $period';
  }

  // ============================================================
  // MAIN CARD
  // ============================================================

  Widget _buildCard(
    BuildContext context, {
    required List<Map<String, dynamic>> logs,
    bool loading = false,
    bool error = false,
    bool empty = false,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              const Color(0xFFD0E2D4),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // ======================================================
          // HEADER
          // ======================================================

          Row(
            children: [

              const Icon(
                Icons.history_rounded,
                color:
                    Color(0xFF134E39),
                size: 20,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Recent Sensor Logs',
                  style:
                      GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        const Color(
                      0xFF134E39,
                    ),
                  ),
                ),
              ),

              // ==================================================
              // LIVE
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),

                decoration: BoxDecoration(
                  color:
                      const Color(
                    0xFFE4EDE6,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: Row(
                  children: [

                    Container(
                      width: 6,
                      height: 6,

                      decoration:
                          const BoxDecoration(
                        color:
                            Color(
                          0xFF134E39,
                        ),
                        shape:
                            BoxShape.circle,
                      ),
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    Text(
                      'LIVE',
                      style:
                          GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            const Color(
                          0xFF134E39,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ======================================================
          // DIVIDER
          // ======================================================

          const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical: 10,
            ),

            child: Divider(
              color:
                  Color(0xFFF4F7F5),
              height: 1,
            ),
          ),

          // ======================================================
          // LOADING
          // ======================================================

          if (loading)
            const Center(
              child: Padding(
                padding:
                    EdgeInsets.all(16),

                child:
                    CircularProgressIndicator(
                  color:
                      Color(0xFF134E39),
                ),
              ),
            )

          // ======================================================
          // ERROR
          // ======================================================

          else if (error)
            const _Message(
              icon:
                  Icons.error_outline,
              message:
                  'Unable to load sensor logs.',
            )

          // ======================================================
          // EMPTY
          // ======================================================

          else if (empty || logs.isEmpty)
            const _Message(
              icon:
                  Icons.history,
              message:
                  'No sensor logs available yet.',
            )

          // ======================================================
          // LOGS
          // ======================================================

          else
            Column(
              children:
                  List.generate(
                logs.length,

                (index) {
                  final Map<String, dynamic>
                      log = logs[index];

                  return _buildLog(
                    log,

                    isLast:
                        index ==
                            logs.length - 1,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD ONE LOG
  // ============================================================

  Widget _buildLog(
    Map<String, dynamic> log, {
    required bool isLast,
  }) {
    // ==========================================================
    // CONVERT VALUES
    // ==========================================================

    final double? temperature =
        _toDouble(
      log['temperature'],
    );

    final double? humidity =
        _toDouble(
      log['humidity'],
    );

    final int? light =
        _toNullableInt(
      log['light'],
    );

    final String soil =
        log['soil']?.toString() ??
            'Unknown';

    final int timestamp =
        _timestampToMilliseconds(
      log['timestamp'],
    );

    final String relativeTime =
        _formatRelativeTime(
      timestamp,
    );

    final String clockTime =
        _formatClockTime(
      timestamp,
    );

    // ==========================================================
    // LOG CARD
    // ==========================================================

    return Container(
      margin:
          EdgeInsets.only(
        bottom:
            isLast ? 0 : 12,
      ),

      padding:
          const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color:
            const Color(0xFFF8FAF8),

        borderRadius:
            BorderRadius.circular(12),

        border: Border.all(
          color:
              const Color(0xFFE4EDE6),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // ======================================================
          // TIME ROW
          // ======================================================

          Row(
            children: [

              const Icon(
                Icons.access_time,
                size: 14,
                color:
                    Color(0xFF5A7865),
              ),

              const SizedBox(
                width: 5,
              ),

              Text(
                clockTime,
                style:
                    GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      const Color(
                    0xFF134E39,
                  ),
                ),
              ),

              const Spacer(),

              Text(
                relativeTime,
                style:
                    GoogleFonts.poppins(
                  fontSize: 10,
                  color:
                      const Color(
                    0xFF5A7865,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          // ======================================================
          // SENSOR VALUES
          // ======================================================

          Wrap(
            spacing: 8,
            runSpacing: 8,

            children: [

              // ==================================================
              // TEMPERATURE
              // ==================================================

              _ValueChip(
                icon:
                    Icons.thermostat,

                label:
                    temperature != null
                        ? '${temperature.toStringAsFixed(1)}°C'
                        : 'Temp --',
              ),

              // ==================================================
              // HUMIDITY
              // ==================================================

              _ValueChip(
                icon:
                    Icons.water_drop_outlined,

                label:
                    humidity != null
                        ? '${humidity.toStringAsFixed(1)}%'
                        : 'Humidity --',
              ),

              // ==================================================
              // SOIL
              // ==================================================

              _ValueChip(
                icon:
                    Icons.grass,

                label:
                    _shortenSoilStatus(
                  soil,
                ),
              ),

              // ==================================================
              // LIGHT
              // ==================================================

              _ValueChip(
                icon:
                    Icons.wb_sunny_outlined,

                label:
                    light != null
                        ? 'Light $light'
                        : 'Light --',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHORTEN SOIL STATUS
  // ============================================================

  static String _shortenSoilStatus(
    String soil,
  ) {
    final String lower =
        soil.toLowerCase();

    if (lower.contains('dry')) {
      return 'Dry';
    }

    if (lower.contains('wet')) {
      return 'Wet';
    }

    if (lower.contains('moist')) {
      return 'Moist';
    }

    return soil;
  }
}

// =================================================================
// VALUE CHIP
// =================================================================

class _ValueChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ValueChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(8),

        border: Border.all(
          color:
              const Color(0xFFD0E2D4),
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [

          Icon(
            icon,
            size: 13,
            color:
                const Color(
              0xFF134E39,
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            label,
            style:
                GoogleFonts.poppins(
              fontSize: 10,
              fontWeight:
                  FontWeight.w500,
              color:
                  const Color(
                0xFF134E39,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// MESSAGE
// =================================================================

class _Message extends StatelessWidget {
  final IconData icon;
  final String message;

  const _Message({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 16,
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Icon(
            icon,
            size: 18,
            color:
                const Color(
              0xFF5A7865,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Flexible(
            child: Text(
              message,
              textAlign:
                  TextAlign.center,

              style:
                  GoogleFonts.poppins(
                fontSize: 11,
                color:
                    const Color(
                  0xFF5A7865,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}