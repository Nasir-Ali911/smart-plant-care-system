class AIRecommendation {
  final String title;
  final String message;
  final String urgency;
  final double score;
  final double? mlProbability;

  AIRecommendation({
    required this.title,
    required this.message,
    required this.urgency,
    required this.score,
    this.mlProbability,
  });
}

class AIRecommendationService {
  static AIRecommendation generateRecommendation({
    required double temperature,
    required double humidity,
    required int lightIntensity,
    required String soilStatus,
    required double dryDurationHours,
    double? mlProbability,
  }) {
    double score = 0;

    final soil = soilStatus.toUpperCase();

    // ------------------------------------------------
    // 1. Soil condition
    // ------------------------------------------------
    if (soil.contains('DRY')) {
      score += 50;
    } else if (soil.contains('MOIST')) {
      score += 20;
    } else if (soil.contains('WET')) {
      score += 0;
    }

    // ------------------------------------------------
    // 2. Dry duration
    // ------------------------------------------------
    if (dryDurationHours >= 12) {
      score += 25;
    } else if (dryDurationHours >= 6) {
      score += 18;
    } else if (dryDurationHours >= 3) {
      score += 10;
    } else if (dryDurationHours >= 1) {
      score += 5;
    }

    // ------------------------------------------------
    // 3. Temperature
    // ------------------------------------------------
    if (temperature >= 32) {
      score += 10;
    } else if (temperature >= 30) {
      score += 7;
    } else if (temperature >= 27) {
      score += 3;
    }

    // ------------------------------------------------
    // 4. Humidity
    // ------------------------------------------------
    if (humidity < 60) {
      score += 10;
    } else if (humidity < 70) {
      score += 5;
    }

    // ------------------------------------------------
    // 5. Light
    // ------------------------------------------------
    if (lightIntensity >= 800) {
      score += 5;
    } else if (lightIntensity >= 650) {
      score += 3;
    }

    // ------------------------------------------------
    // 6. ML probability
    // ------------------------------------------------
    if (mlProbability != null) {
      score += mlProbability * 20;
    }

    score = score.clamp(0, 100);

    // ------------------------------------------------
    // Final recommendation
    // ------------------------------------------------

    if (soil.contains('DRY') && score >= 70) {
      return AIRecommendation(
        title: 'Watering Recommended',
        message:
            'The soil is dry and current environmental conditions indicate increased water demand. Watering is recommended.',
        urgency: 'HIGH',
        score: score,
        mlProbability: mlProbability,
      );
    }

    if (soil.contains('DRY') && score >= 50) {
      return AIRecommendation(
        title: 'Watering May Be Needed Soon',
        message:
            'The soil is currently dry. Temperature, humidity and recent dry duration suggest that watering may be required soon.',
        urgency: 'MEDIUM',
        score: score,
        mlProbability: mlProbability,
      );
    }

    if (soil.contains('MOIST')) {
      return AIRecommendation(
        title: 'Plant Condition Healthy',
        message:
            'Soil moisture is currently adequate. Continue monitoring environmental conditions and avoid unnecessary watering.',
        urgency: 'LOW',
        score: score,
        mlProbability: mlProbability,
      );
    }

    if (soil.contains('WET')) {
      return AIRecommendation(
        title: 'No Watering Required',
        message:
            'The soil is currently wet. Additional watering is not recommended at this time.',
        urgency: 'LOW',
        score: score,
        mlProbability: mlProbability,
      );
    }

    return AIRecommendation(
      title: 'Continue Monitoring',
      message:
          'Current sensor conditions do not indicate an immediate need for watering.',
      urgency: 'LOW',
      score: score,
      mlProbability: mlProbability,
    );
  }
}