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
  // UPLOAD IMAGE TO CLOUDINARY
  // ============================================================

  Future<String?> _uploadImageToCloudinary(
    XFile imageFile,
  ) async {
    try {
      // ----------------------------------------------------------
      // CLOUDINARY UPLOAD URL
      // ----------------------------------------------------------

      final Uri uploadUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/'
        '$_cloudName/image/upload',
      );

      // ----------------------------------------------------------
      // CREATE MULTIPART REQUEST
      // ----------------------------------------------------------

      final request = http.MultipartRequest(
        'POST',
        uploadUrl,
      );

      // ----------------------------------------------------------
      // UNSIGNED UPLOAD PRESET
      // ----------------------------------------------------------

      request.fields['upload_preset'] =
          _uploadPreset;

      // ----------------------------------------------------------
      // READ IMAGE
      // ----------------------------------------------------------

      final imageBytes =
          await imageFile.readAsBytes();

      // ----------------------------------------------------------
      // ADD IMAGE TO REQUEST
      // ----------------------------------------------------------

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: imageFile.name,
        ),
      );

      // ----------------------------------------------------------
      // SEND REQUEST
      // ----------------------------------------------------------

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      // ----------------------------------------------------------
      // SUCCESS
      // ----------------------------------------------------------

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

      // ----------------------------------------------------------
      // CLOUDINARY ERROR
      // ----------------------------------------------------------

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

    // Optional image
    XFile? imageFile,
  }) async {
    // ----------------------------------------------------------
    // GET CURRENT USER
    // ----------------------------------------------------------

    final String? uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      throw Exception(
        'No authenticated user found.',
      );
    }

    // ----------------------------------------------------------
    // CREATE NEW PLANT REFERENCE
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // UPLOAD IMAGE IF SELECTED
    // ----------------------------------------------------------

    String? imageUrl;

    if (imageFile != null) {
      imageUrl =
          await _uploadImageToCloudinary(
        imageFile,
      );
    }

    // ----------------------------------------------------------
    // CREATE PLANT DATA
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // SAVE IMAGE URL
    // ----------------------------------------------------------

    if (imageUrl != null &&
        imageUrl.isNotEmpty) {
      plantData['imageUrl'] =
          imageUrl;
    }

    // ----------------------------------------------------------
    // SAVE TO FIREBASE
    // ----------------------------------------------------------

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

    // Optional new image
    XFile? imageFile,

    // Delete existing image
    bool removeImage = false,
  }) async {
    // ----------------------------------------------------------
    // GET CURRENT USER
    // ----------------------------------------------------------

    final String? uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      throw Exception(
        'No authenticated user found.',
      );
    }

    // ----------------------------------------------------------
    // PLANT DATABASE REFERENCE
    // ----------------------------------------------------------

    final DatabaseReference plantRef =
        _dbRef.child(
      'Users/$uid/Plants/$plantId',
    );

    // ----------------------------------------------------------
    // BASIC PLANT DATA
    // ----------------------------------------------------------

    final Map<String, dynamic> updateData = {
      'name': name,
      'species': species,
      'type': species,
      'location': location,
      'status': category,
      'moisture': wateringSchedule,
      'lastUpdated': 'Just now',
    };

    // ----------------------------------------------------------
    // REMOVE EXISTING IMAGE
    // ----------------------------------------------------------
    //
    // Firebase will remove the imageUrl field when null
    // is written through update().
    //

    if (removeImage) {
      updateData['imageUrl'] = null;
    }

    // ----------------------------------------------------------
    // UPLOAD NEW IMAGE
    // ----------------------------------------------------------
    //
    // If the user selected a new image, upload it to
    // Cloudinary and save the new URL.
    //
    // This takes priority over removeImage if both happen
    // to be true.
    //

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

    // ----------------------------------------------------------
    // UPDATE FIREBASE
    // ----------------------------------------------------------

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
    // ----------------------------------------------------------
    // GET CURRENT USER
    // ----------------------------------------------------------

    final String? uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      throw Exception(
        'No authenticated user found.',
      );
    }

    // ----------------------------------------------------------
    // DELETE FIREBASE PLANT RECORD
    // ----------------------------------------------------------
    //
    // The Cloudinary image itself is NOT deleted here.
    //
    // Deleting Cloudinary assets requires an authenticated
    // server-side API secret.
    //
    // The API secret must NEVER be placed inside Flutter.
    //

    await _dbRef
        .child(
          'Users/$uid/Plants/$plantId',
        )
        .remove();
  }
}