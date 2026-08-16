import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_plant_care/models/user_model.dart';
import 'package:smart_plant_care/services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // AUTH STATE
  // ============================================================

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================================
  // LOGIN
  // ============================================================

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = credential.user;

      if (user != null) {
        debugPrint('LOGIN SUCCESSFUL: ${user.uid}');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      // ----------------------------------------------------------
      // STEP 1: CREATE FIREBASE AUTH ACCOUNT
      // ----------------------------------------------------------

      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        throw 'Registration failed. User account was not created.';
      }

      debugPrint(
        'STEP 1: Firebase Auth account created: ${user.uid}',
      );

      // ----------------------------------------------------------
      // STEP 2: SET DISPLAY NAME IN FIREBASE AUTH
      // ----------------------------------------------------------

      await user.updateDisplayName(name.trim());

      await user.reload();

      final User? updatedUser = _auth.currentUser;

      debugPrint(
        'STEP 2: Firebase Auth display name saved: ${updatedUser?.displayName}',
      );

      // ----------------------------------------------------------
      // STEP 3: CREATE USER MODEL
      // ----------------------------------------------------------

      final UserModel userModel = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      );

      // ----------------------------------------------------------
      // STEP 4: SAVE PROFILE TO FIRESTORE
      // ----------------------------------------------------------

      debugPrint('STEP 3: Saving profile to Firestore...');

      await _firestoreService.saveUserProfile(userModel);

      debugPrint(
        'STEP 4: Firestore profile saved successfully',
      );

      return updatedUser ?? user;
    } on FirebaseAuthException catch (e) {
      debugPrint('FIREBASE AUTH ERROR: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');

      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('REGISTRATION ERROR: $e');

      throw e.toString().replaceFirst(
            'Exception: ',
            '',
          );
    }
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ============================================================
  // FIREBASE ERROR HANDLER
  // ============================================================

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';

      case 'wrong-password':
        return 'Wrong password provided for that user.';

      case 'email-already-in-use':
        return 'The account already exists for that email.';

      case 'invalid-email':
        return 'The email address is badly formatted.';

      case 'weak-password':
        return 'The password provided is too weak.';

      case 'user-disabled':
        return 'This user account has been disabled.';

      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';

      case 'operation-not-allowed':
        return 'Email/password registration is disabled in Firebase Authentication.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      default:
        return e.message ??
            'Authentication failed. Please try again.';
    }
  }
}