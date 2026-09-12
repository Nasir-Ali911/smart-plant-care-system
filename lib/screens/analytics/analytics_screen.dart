import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smart_plant_care/services/plant_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
  });

  @override
  State<AnalyticsScreen> createState() =>
      _AnalyticsScreenState();
}

class _AnalyticsScreenState
    extends State<AnalyticsScreen> {
  final PlantService _plantService =
      PlantService();

  List<Map<String, dynamic>> _logs = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  // ============================================================
  // LOAD HISTORICAL DATA
  // ============================================================

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Map<String, dynamic>> logs =
          await _plantService.fetchRecentLogs(
        limit: 50,
      );

      if (!mounted) return;

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load historical data.\n$e';
      });
    }
  }

  // ============================================================
  // VALUE HELPERS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  dynamic _getValue(
    Map<String, dynamic> log,
    String key,
  ) {
    if (log.containsKey(key)) {
      return log[key];
    }

    final String lowerKey =
        key.toLowerCase();

    for (final entry in log.entries) {
      if (entry.key.toLowerCase() ==
          lowerKey) {
        return entry.value;
      }
    }

    return null;
  }

  DateTime? _getTimestamp(
    Map<String, dynamic> log,
  ) {
    final dynamic value =
        _getValue(log, 'Timestamp');

    final int timestamp =
        _toInt(value);

    if (timestamp <= 0) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(
      timestamp,
    );
  }

  String _formatTime(
    Map<String, dynamic> log,
  ) {
    final DateTime? dateTime =
        _getTimestamp(log);

    if (dateTime == null) {
      return '--';
    }

    final DateTime local =
        dateTime.toLocal();

    final String hour =
        local.hour.toString().padLeft(2, '0');

    final String minute =
        local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatDateTime(
    Map<String, dynamic> log,
  ) {
    final DateTime? dateTime =
        _getTimestamp(log);

    if (dateTime == null) {
      return 'Unknown time';
    }

    final DateTime local =
        dateTime.toLocal();

    final String day =
        local.day.toString().padLeft(2, '0');

    final String month =
        local.month.toString().padLeft(2, '0');

    final String hour =
        local.hour.toString().padLeft(2, '0');

    final String minute =
        local.minute.toString().padLeft(2, '0');

    return '$day/$month/${local.year} '
        '$hour:$minute';
  }

  // ============================================================
  // CHART DATA
  // ============================================================

  List<FlSpot> _createSpots(
    String field,
  ) {
    final List<FlSpot> spots = [];

    for (int i = 0;
        i < _logs.length;
        i++) {
      final double value =
          _toDouble(
        _getValue(
          _logs[i],
          field,
        ),
      );

      spots.add(
        FlSpot(
          i.toDouble(),
          value,
        ),
      );
    }

    return spots;
  }

  double _maxValue(
    List<FlSpot> spots,
  ) {
    if (spots.isEmpty) {
      return 10;
    }

    double max =
        spots.first.y;

    for (final FlSpot spot in spots) {
      if (spot.y > max) {
        max = spot.y;
      }
    }

    if (max <= 0) {
      return 10;
    }

    return max * 1.2;
  }

  double _minValue(
    List<FlSpot> spots,
  ) {
    if (spots.isEmpty) {
      return 0;
    }

    double min =
        spots.first.y;

    for (final FlSpot spot in spots) {
      if (spot.y < min) {
        min = spot.y;
      }
    }

    return min < 0 ? min * 1.2 : 0;
  }

  // ============================================================
  // CHART WIDGET
  // ============================================================

  Widget _buildLineChart({
    required String title,
    required String unit,
    required String field,
    required IconData icon,
  }) {
    final List<FlSpot> spots =
        _createSpots(field);

    if (spots.isEmpty) {
      return _buildEmptyChartCard(
        title,
        icon,
      );
    }

    final double maxY =
        _maxValue(spots);

    final double minY =
        _minValue(spots);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.05),
            blurRadius: 12,
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
                    const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF134E39)
                          .withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(0xFF134E39),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        const Color(0xFF1F2937),
                  ),
                ),
              ),
              Text(
                unit,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color:
                      Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 230,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine:
                      false,
                  horizontalInterval:
                      _calculateInterval(
                    minY,
                    maxY,
                  ),
                ),

                borderData:
                    FlBorderData(
                  show: false,
                ),

                titlesData:
                    FlTitlesData(
                  topTitles:
                      const AxisTitles(
                    sideTitles:
                        SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles:
                      const AxisTitles(
                    sideTitles:
                        SideTitles(
                      showTitles: false,
                    ),
                  ),
                  leftTitles:
                      AxisTitles(
                    sideTitles:
                        SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval:
                          _calculateInterval(
                        minY,
                        maxY,
                      ),
                      getTitlesWidget:
                          (
                        double value,
                        TitleMeta meta,
                      ) {
                        return Text(
                          value
                              .toStringAsFixed(
                            0,
                          ),
                          style:
                              GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles:
                      AxisTitles(
                    sideTitles:
                        SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval:
                          _bottomInterval(),
                      getTitlesWidget:
                          (
                        double value,
                        TitleMeta meta,
                      ) {
                        final int index =
                            value.round();

                        if (index <
                                0 ||
                            index >=
                                _logs.length) {
                          return const SizedBox();
                        }

                        return Text(
                          _formatTime(
                            _logs[index],
                          ),
                          style:
                              GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                lineTouchData:
                    LineTouchData(
                  touchTooltipData:
                      LineTouchTooltipData(
                    getTooltipItems:
                        (
                      List<
                          LineBarSpot>
                          touchedSpots,
                    ) {
                      return touchedSpots
                          .map(
                        (
                          LineBarSpot spot,
                        ) {
                          final int index =
                              spot.x.round();

                          String time =
                              '';

                          if (index >= 0 &&
                              index <
                                  _logs
                                      .length) {
                            time =
                                _formatDateTime(
                              _logs[index],
                            );
                          }

                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} $unit\n'
                            '$time',
                            GoogleFonts.poppins(
                              color:
                                  Colors.white,
                              fontSize:
                                  11,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          );
                        },
                      ).toList();
                    },
                  ),
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3,
                    dotData:
                        FlDotData(
                      show:
                          spots.length <=
                              20,
                    ),
                    belowBarData:
                        BarAreaData(
                      show: true,
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

  double _calculateInterval(
    double min,
    double max,
  ) {
    final double range =
        max - min;

    if (range <= 10) {
      return 2;
    }

    if (range <= 50) {
      return 10;
    }

    if (range <= 200) {
      return 50;
    }

    return 200;
  }

  double _bottomInterval() {
    if (_logs.length <= 6) {
      return 1;
    }

    if (_logs.length <= 12) {
      return 2;
    }

    if (_logs.length <= 25) {
      return 5;
    }

    return 10;
  }

  Widget _buildEmptyChartCard(
    String title,
    IconData icon,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color:
                const Color(0xFF134E39),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$title\nNo historical data available.',
              style:
                  GoogleFonts.poppins(
                fontSize: 13,
                color:
                    Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LATEST READING
  // ============================================================

  Widget _buildLatestReading() {
    if (_logs.isEmpty) {
      return const SizedBox();
    }

    final Map<String, dynamic> latest =
        _logs.last;

    final double temperature =
        _toDouble(
      _getValue(
        latest,
        'Temperature',
      ),
    );

    final double humidity =
        _toDouble(
      _getValue(
        latest,
        'Humidity',
      ),
    );

    final double light =
        _toDouble(
      _getValue(
        latest,
        'LightIntensity',
      ),
    );

    final String soil =
        _getValue(
              latest,
              'SoilStatus',
            )
            ?.toString()
            .toUpperCase() ??
        'UNKNOWN';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 20,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            const Color(0xFF134E39),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sensors,
                color: Colors.white,
                size: 21,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Latest Reading',
                  style:
                      GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatDateTime(
                  latest,
                ),
                style:
                    GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              _buildLatestValue(
                Icons.thermostat,
                temperature
                    .toStringAsFixed(1),
                '°C',
              ),
              _buildLatestValue(
                Icons.water_drop,
                humidity
                    .toStringAsFixed(1),
                '%',
              ),
              _buildLatestValue(
                Icons.wb_sunny,
                light
                    .toStringAsFixed(0),
                'ADC',
              ),
              _buildLatestValue(
                Icons.grass,
                soil,
                '',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestValue(
    IconData icon,
    String value,
    String unit,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 18,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            overflow:
                TextOverflow.ellipsis,
            style:
                GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style:
                  GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SOIL HISTORY
  // ============================================================

  Widget _buildSoilHistory() {
    if (_logs.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.05,
            ),
            blurRadius: 12,
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
                    const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF134E39)
                          .withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: const Icon(
                  Icons.grass,
                  color:
                      Color(0xFF134E39),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Soil Condition History',
                style:
                    GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      const Color(0xFF1F2937),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ..._logs.reversed
              .take(10)
              .map(
            (
              log,
            ) {
              final String soil =
                  _getValue(
                        log,
                        'SoilStatus',
                      )
                      ?.toString()
                      .toUpperCase() ??
                  'UNKNOWN';

              final String message =
                  _soilMessage(
                soil,
              );

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(
                        shape:
                            BoxShape.circle,
                        color:
                            _soilColor(
                          soil,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        message,
                        style:
                            GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(
                        log,
                      ),
                      style:
                          GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors
                            .grey
                            .shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _soilMessage(
    String soil,
  ) {
    switch (soil) {
      case 'DRY':
        return 'Needs Water';

      case 'MOIST':
      case 'NORMAL':
        return 'Healthy';

      case 'WET':
        return 'Well Watered';

      default:
        return soil;
    }
  }

  Color _soilColor(
    String soil,
  ) {
    switch (soil) {
      case 'DRY':
        return Colors.red;

      case 'MOIST':
      case 'NORMAL':
        return Colors.green;

      case 'WET':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // SCREEN
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7F6),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF134E39),
        foregroundColor:
            Colors.white,
        elevation: 0,
        title: Text(
          'Analytics',
          style:
              GoogleFonts.poppins(
            fontSize: 19,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                'Refresh',
            onPressed:
                _isLoading
                    ? null
                    : _loadLogs,
            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF134E39),
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  color:
                      const Color(0xFF134E39),
                  onRefresh:
                      _loadLogs,
                  child:
                      SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildLatestReading(),

                        Text(
                          'Historical Sensor Data',
                          style:
                              GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                const Color(
                              0xFF1F2937,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          '${_logs.length} readings loaded',
                          style:
                              GoogleFonts.poppins(
                            fontSize: 12,
                            color:
                                Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        _buildLineChart(
                          title:
                              'Temperature',
                          unit:
                              '°C',
                          field:
                              'Temperature',
                          icon:
                              Icons.thermostat,
                        ),

                        _buildLineChart(
                          title:
                              'Humidity',
                          unit:
                              '%',
                          field:
                              'Humidity',
                          icon:
                              Icons.water_drop,
                        ),

                        _buildLineChart(
                          title:
                              'Light Intensity',
                          unit:
                              'ADC',
                          field:
                              'LightIntensity',
                          icon:
                              Icons.wb_sunny,
                        ),

                        _buildSoilHistory(),

                        const SizedBox(
                          height: 10,
                        ),

                        Center(
                          child: Text(
                            'Data source: SmartPlant/Logs',
                            style:
                                GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors
                                  .grey
                                  .shade500,
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
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 55,
              color:
                  Colors.red.shade400,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              'Could not load analytics',
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.poppins(
                fontSize: 17,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              _errorMessage ??
                  'Unknown error',
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.poppins(
                fontSize: 12,
                color: Colors
                    .grey
                    .shade600,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton.icon(
              onPressed:
                  _loadLogs,
              icon:
                  const Icon(
                Icons.refresh,
              ),
              label:
                  const Text(
                'Try Again',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF134E39,
                ),
                foregroundColor:
                    Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}