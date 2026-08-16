import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_plant_care/models/user_model.dart';
import 'package:smart_plant_care/models/sensor_model.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // USER PROFILE
  // ============================================================

  /// Creates or updates the user's profile in Firestore.
Future<void> saveUserProfile(UserModel user) async {
  try {
    debugPrint('FIRESTORE: Starting profile write...');
    
    await _db
        .collection('users')
        .doc(user.uid)
        .set(
          user.toMap(),
          SetOptions(merge: true),
        )
        .timeout(
          const Duration(seconds: 10),
        );

    debugPrint('FIRESTORE: Profile write completed!');
  } on FirebaseException catch (e) {
    debugPrint('FIRESTORE ERROR CODE: ${e.code}');
    debugPrint('FIRESTORE ERROR MESSAGE: ${e.message}');

    throw 'Failed to save user profile: ${e.message ?? e.code}';
  } on TimeoutException {
    debugPrint('FIRESTORE ERROR: Write timed out after 10 seconds.');

    throw 'Firestore request timed out. Please check your Firestore configuration and internet connection.';
  } catch (e) {
    debugPrint('FIRESTORE GENERAL ERROR: $e');

    throw e.toString().replaceFirst(
          'Exception: ',
          '',
        );
  }
}

  /// Gets the user's profile from Firestore.
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection('users').doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserModel.fromMap(
        doc.data()!,
        doc.id,
      );
    } on FirebaseException catch (e) {
      throw 'Failed to fetch user profile: ${e.message ?? e.code}';
    } catch (e) {
      throw 'Failed to fetch user profile: $e';
    }
  }

  /// Real-time stream of the current user's profile.
  Stream<UserModel?> getUserProfileStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return UserModel.fromMap(
        snapshot.data()!,
        snapshot.id,
      );
    });
  }

  /// Updates selected fields of a user's profile.
  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .update(data);
    } on FirebaseException catch (e) {
      throw 'Failed to update user profile: ${e.message ?? e.code}';
    } catch (e) {
      throw 'Failed to update user profile: $e';
    }
  }

  /// Deletes the user's Firestore profile.
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .delete();
    } on FirebaseException catch (e) {
      throw 'Failed to delete user profile: ${e.message ?? e.code}';
    } catch (e) {
      throw 'Failed to delete user profile: $e';
    }
  }

  // ============================================================
  // SENSOR TELEMETRY
  // ============================================================

  /// Gets real-time sensor telemetry from Firestore.
  ///
  /// NOTE:
  /// Your current FYP sensor data is actually stored in
  /// Firebase Realtime Database under:
  ///
  /// SmartPlant
  ///
  /// Therefore, do NOT use this method for the current ESP8266
  /// telemetry unless you later move the sensor data to Firestore.
  Stream<SensorModel?> getSensorDataStream(String sensorId) {
    return _db
        .collection('sensor_data')
        .doc(sensorId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return SensorModel.fromMap(
        snapshot.data()!,
      );
    });
  }

  /// Gets one sensor telemetry document.
  Future<SensorModel?> getSensorData(String sensorId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _db
              .collection('sensor_data')
              .doc(sensorId)
              .get();

      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return SensorModel.fromMap(
        snapshot.data()!,
      );
    } on FirebaseException catch (e) {
      throw 'Failed to fetch sensor data: ${e.message ?? e.code}';
    } catch (e) {
      throw 'Failed to fetch sensor data: $e';
    }
  }
}