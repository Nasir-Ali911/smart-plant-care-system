class AiForecastModel {
  final bool success;
  final String timestamp;
  final String currentSoilStatus;
  final String forecastSoilStatus;
  final double dryProbability;
  final double wetProbability;
  final int horizonMinutes;
  final String recommendation;
  final bool pumpActivation;
  final String model;

  AiForecastModel({
    required this.success,
    required this.timestamp,
    required this.currentSoilStatus,
    required this.forecastSoilStatus,
    required this.dryProbability,
    required this.wetProbability,
    required this.horizonMinutes,
    required this.recommendation,
    required this.pumpActivation,
    required this.model,
  });

  factory AiForecastModel.fromJson(Map<String, dynamic> json) {
    final current = json['current'] ?? {};
    final forecast = json['forecast'] ?? {};
    final recommendation = json['recommendation'] ?? {};

    return AiForecastModel(
      success: json['success'] == true,
      timestamp: json['timestamp']?.toString() ?? '',
      currentSoilStatus: current['soil_status']?.toString() ?? 'UNKNOWN',
      forecastSoilStatus: forecast['soil_status']?.toString() ?? 'UNKNOWN',
      dryProbability:
          (forecast['dry_probability'] as num?)?.toDouble() ?? 0.0,
      wetProbability:
          (forecast['wet_probability'] as num?)?.toDouble() ?? 0.0,
      horizonMinutes:
          (forecast['horizon_minutes'] as num?)?.toInt() ?? 0,
      recommendation:
          recommendation['message']?.toString() ?? 'No recommendation available.',
      pumpActivation: recommendation['pump_activation'] == true,
      model: json['model']?.toString() ?? 'Unknown',
    );
  }
}