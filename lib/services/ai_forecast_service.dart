import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/ai_forecast_model.dart';

class AiForecastService {
  // Flask server running on your PC
  static const String baseUrl = 'https://nasir.pythonanywhere.com';

  static Future<AiForecastModel> getForecast() async {
    final url = Uri.parse('$baseUrl/api/soil-forecast');

    final response = await http
        .get(url)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'AI API returned HTTP ${response.statusCode}',
      );
    }

    final Map<String, dynamic> jsonData =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (jsonData['success'] != true) {
      throw Exception(
        jsonData['error']?.toString() ?? 'AI forecast failed',
      );
    }

    return AiForecastModel.fromJson(jsonData);
  }
}