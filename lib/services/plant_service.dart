import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class PlantService {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref();

  // ============================================================
  // CLOUDINARY CONFIGURATION
  // ============================================================

  static const String _cloudName = 'upxfoprq';
  static const String _uploadPreset = 'smart_plant_images';

  // ============================================================
  // GET PLANTS STREAM
  // ============================================================

  Stream<DatabaseEvent> getPlantsStream() {
    final String? uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      throw Exception(
        'No authenticated user found.',
      );
    }

    return _dbRef
        .child('Users/$uid/Plants')
        .onValue;
  }

  // ============================================================
  // MANUAL PUMP CONTROL
  // ============================================================

  Future<void> triggerManualWatering(bool turnOn) async {
    final DatabaseReference controlRef =
        FirebaseDatabase.instance.ref(
      'SmartPlant/Control',
    );

    await controlRef.set({
      'PumpManual': turnOn ? 'ON' : 'OFF',
      'Timestamp': ServerValue.timestamp,
    });
  }

  // ============================================================
  // HISTORICAL SENSOR LOGS
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchRecentLogs({
    int limit = 50,
  }) async {
    final DatabaseReference logsRef =
        _dbRef.child('SmartPlant/Logs');

    final DatabaseEvent event = await logsRef
        .orderByChild('Timestamp')
        .limitToLast(limit)
        .once();

    final Object? value = event.snapshot.value;

    if (value == null) {
      return [];
    }

    if (value is! Map) {
      return [];
    }

    final Map<dynamic, dynamic> rawLogs =
        Map<dynamic, dynamic>.from(value);

    final List<Map<String, dynamic>> logs = [];

    for (final entry in rawLogs.entries) {
      final dynamic rawValue = entry.value;

      if (rawValue is! Map) {
        continue;
      }

      final Map<dynamic, dynamic> rawLog =
          Map<dynamic, dynamic>.from(rawValue);

      final Map<String, dynamic> log = {};

      rawLog.forEach((key, value) {
        log[key.toString()] = value;
      });

      logs.add(log);
    }

    // Oldest → newest
    logs.sort((a, b) {
      final int timestampA =
          _toInt(a['Timestamp']);

      final int timestampB =
          _toInt(b['Timestamp']);

      return timestampA.compareTo(timestampB);
    });

    return logs;
  }

  // ============================================================
  // SENSOR VALUE HELPERS
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

  // ============================================================
  // CLOUDINARY IMAGE UPLOAD
  // ============================================================

  Future<String?> _uploadImageToCloudinary(
    XFile imageFile,
  ) async {
    try {
      final Uri uploadUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/'
        '$_cloudName/image/upload',
      );

      final request = http.MultipartRequest(
        'POST',
        uploadUrl,
      );

      request.fields['upload_preset'] =
          _uploadPreset;

      final imageBytes =
          await imageFile.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: imageFile.name,
        ),
      );

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body);

        final String? secureUrl =
            data['secure_url'];

        if (secureUrl == null ||
            secureUrl.isEmpty) {
          throw Exception(
            'Cloudinary did not return an image URL.',
          );
        }

        return secureUrl;
      }

      throw Exception(
        'Cloudinary upload failed.\n'
        'Status: ${response.statusCode}\n'
        'Response: ${response.body}',
      );
    } catch (e) {
      throw Exception(
        'Image upload failed: $e',
      );
    }
  }

  // ============================================================
  // ADD PLANT
  // ============================================================

  Future<void> addPlant({
    required String name,
    required String species,
    required String location,
    required String moisture,
    required String temperature,
    required String status,
    XFile? imageFile,
  }) async {
    final String? uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      throw Exception(
        'No authenticated user found.',
      );
    }

    final DatabaseReference newPlantRef =
        _dbRef
            .child('Users/$uid/Plants')
            .push();

    final String? plantId =
        newPlantRef.key;

    if (plantId == null) {
      throw Exception(
        'Unable to generate plant ID.',
      );
    }

    String? imageUrl;

    if (imageFile != null) {
      imageUrl =
          await _uploadImageToCloudinary(
        imageFile,
      );
    }

    final Map<String, dynamic> plantData = {
      'name': name,
      'species': species,
      'type': species,
      'location': location,
      'moisture': moisture,
      'temperature': temperature,
      'status': status,
      'createdAt': ServerValue.timestamp,
    };

    if (imageUrl != null &&
        imageUrl.isNotEmpty) {
      plantData['imageUrl'] =
          imageUrl;
    }

    await newPlantRef.set(
      plantData,
    );
  }

  // ============================================================
  // UPDATE PLANT
  // ============================================================

  Future<void> updatePlant({
    required String plantId,
    required String name,
    required String species,
    required String location,
    required String category,
    required String wateringSchedule,
    XFile? imageFile,
    bool removeImage = false,
  }) async {
    final String? uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      throw Exception(
        'No authenticated user found.',
      );
    }

    final DatabaseReference plantRef =
        _dbRef.child(
      'Users/$uid/Plants/$plantId',
    );

    final Map<String, dynamic> updateData = {
      'name': name,
      'species': species,
      'type': species,
      'location': location,
      'status': category,
      'moisture': wateringSchedule,
      'lastUpdated': 'Just now',
    };

    if (removeImage) {
      updateData['imageUrl'] = null;
    }

    if (imageFile != null) {
      final String? imageUrl =
          await _uploadImageToCloudinary(
        imageFile,
      );

      if (imageUrl != null &&
          imageUrl.isNotEmpty) {
        updateData['imageUrl'] =
            imageUrl;
      }
    }

    await plantRef.update(
      updateData,
    );
  }

  // ============================================================
  // DELETE PLANT
  // ============================================================

  Future<void> deletePlant(
    String plantId,
  ) async {
    final String? uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      throw Exception(
        'No authenticated user found.',
      );
    }

    await _dbRef
        .child(
          'Users/$uid/Plants/$plantId',
        )
        .remove();
  }
}