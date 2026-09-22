class SensorModel {
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double lightIntensity;
  final String soilStatus;
  final String lightStatus;
  final DateTime timestamp;

  SensorModel({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.lightIntensity,
    required this.soilStatus,
    required this.lightStatus,
    required this.timestamp,
  });

  // ============================================================
  // CONVERT REALTIME DATABASE /SmartPlant DATA TO SensorModel
  // ============================================================

  factory SensorModel.fromMap(Map<String, dynamic> map) {
    return SensorModel(
      temperature: _toDouble(map['Temperature']),
      humidity: _toDouble(map['Humidity']),
      soilMoisture: _toDouble(map['SoilMoistureRaw']),
      lightIntensity: _toDouble(map['LightIntensity']),
      soilStatus: map['SoilStatus']?.toString() ?? 'UNKNOWN',
      lightStatus: map['LightStatus']?.toString() ?? 'UNKNOWN',
      timestamp: _parseTimestamp(map['Timestamp']),
    );
  }

  // ============================================================
  // CONVERT SensorModel TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'Temperature': temperature,
      'Humidity': humidity,
      'SoilMoistureRaw': soilMoisture,
      'LightIntensity': lightIntensity,
      'SoilStatus': soilStatus,
      'LightStatus': lightStatus,
      'Timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // ============================================================
  // SAFE DOUBLE CONVERSION
  // ============================================================

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  // ============================================================
  // SAFE TIMESTAMP CONVERSION
  // ============================================================

  static DateTime _parseTimestamp(dynamic value) {
    if (value is num) {
      final int timestamp = value.toInt();

      // Firebase timestamps are normally milliseconds.
      // However, support Unix seconds as well.
      if (timestamp < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(
          timestamp * 1000,
        );
      }

      return DateTime.fromMillisecondsSinceEpoch(
        timestamp,
      );
    }

    if (value is String) {
      final DateTime? parsed =
          DateTime.tryParse(value);

      if (parsed != null) {
        return parsed;
      }

      final int? numeric =
          int.tryParse(value);

      if (numeric != null) {
        if (numeric < 10000000000) {
          return DateTime.fromMillisecondsSinceEpoch(
            numeric * 1000,
          );
        }

        return DateTime.fromMillisecondsSinceEpoch(
          numeric,
        );
      }
    }

    return DateTime.now();
  }
}