class SensorModel {
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double lightIntensity;
  final double waterLevel;
  final DateTime timestamp;

  SensorModel({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.lightIntensity,
    required this.waterLevel,
    required this.timestamp,
  });

  // Convert Firestore Document to SensorModel
  factory SensorModel.fromMap(Map<String, dynamic> map) {
    return SensorModel(
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      humidity: (map['humidity'] ?? 0.0).toDouble(),
      soilMoisture: (map['soilMoisture'] ?? 0.0).toDouble(),
      lightIntensity: (map['lightIntensity'] ?? 0.0).toDouble(),
      waterLevel: (map['waterLevel'] ?? 0.0).toDouble(),
      timestamp: map['timestamp'] != null
          ? (map['timestamp']).toDate()
          : DateTime.now(),
    );
  }

  // Convert SensorModel to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'soilMoisture': soilMoisture,
      'lightIntensity': lightIntensity,
      'waterLevel': waterLevel,
      'timestamp': timestamp,
    };
  }
}