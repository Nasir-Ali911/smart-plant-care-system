import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildHeader(
        name: 'User',
        email: '',
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = user.displayName ?? '';

        String email = user.email ?? '';

        // Read name from Firestore if available
        if (snapshot.hasData &&
            snapshot.data!.exists) {
          final data =
              snapshot.data!.data() as Map<String, dynamic>?;

          if (data != null) {
            final firestoreName =
                data['name']?.toString().trim();

            final firestoreEmail =
                data['email']?.toString().trim();

            if (firestoreName != null &&
                firestoreName.isNotEmpty) {
              name = firestoreName;
            }

            if (firestoreEmail != null &&
                firestoreEmail.isNotEmpty) {
              email = firestoreEmail;
            }
          }
        }

        // Final fallback
        if (name.isEmpty) {
          name = _getNameFromEmail(email);
        }

        return _buildHeader(
          name: name,
          email: email,
        );
      },
    );
  }

  Widget _buildHeader({
    required String name,
    required String email,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // =======================================================
          // AVATAR
          // =======================================================

          const CircleAvatar(
            radius: 45,
            backgroundColor: Color(0xFFD0E2D4),
            child: Icon(
              Icons.person,
              size: 50,
              color: Color(0xFF134E39),
            ),
          ),

          const SizedBox(height: 14),

          // =======================================================
          // NAME
          // =======================================================

          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF134E39),
            ),
          ),

          const SizedBox(height: 4),

          // =======================================================
          // TITLE
          // =======================================================

          Text(
            'AI Plant Enthusiast',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5A7865),
            ),
          ),

          const SizedBox(height: 4),

          // =======================================================
          // EMAIL
          // =======================================================

          Text(
            email,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getNameFromEmail(String email) {
    if (email.isEmpty) {
      return 'User';
    }

    final name = email.split('@').first;

    return name.isEmpty ? 'User' : name;
  }
}