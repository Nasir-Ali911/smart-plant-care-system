import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CameraService {
  // Temporary prototype IP.
  // This may change when the ESP32-CAM reconnects to the hotspot.
  static const String cameraIp = '10.46.12.64';

  static String get captureUrl => 'http://$cameraIp/fyp/capture';

  static Future<Uint8List> captureImage() async {
    final response = await http
        .get(Uri.parse(captureUrl))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Camera returned HTTP ${response.statusCode}',
      );
    }

    if (response.bodyBytes.isEmpty) {
      throw Exception('Camera returned an empty image.');
    }

    return response.bodyBytes;
  }
}