import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:smart_plant_care/screens/profile/widgets/profile_header.dart';
import 'package:smart_plant_care/screens/profile/widgets/stat_card.dart';
import 'package:smart_plant_care/screens/profile/widgets/profile_tile.dart';
import 'package:smart_plant_care/screens/settings/settings_screen.dart';
import 'package:smart_plant_care/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF134E39),
            ),
          ),
          content: Text(
            'Are you sure you want to log out of your account?',
            style: GoogleFonts.poppins(
              color: const Color(0xFF5A7865),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF5A7865),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);

                await AuthService().signOut();

                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFE4EDE6),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        // Since this screen is also used as a bottom
        // navigation tab, don't force Navigator.pop().
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF134E39),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/home');
            }
          },
        ),

        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E39),
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF134E39),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Profile editing will be available soon.',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor:
                      const Color(0xFF134E39),
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // =====================================================
            // PROFILE HEADER
            // =====================================================

            const ProfileHeader(),

            const SizedBox(height: 20),

            // =====================================================
            // STATISTICS
            // =====================================================

            _buildStatistics(uid),

            const SizedBox(height: 20),

            // =====================================================
            // QUICK ACTIONS
            // =====================================================

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ProfileTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Profile editing will be available soon.',
                            style:
                                GoogleFonts.poppins(
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor:
                              const Color(0xFF134E39),
                        ),
                      );
                    },
                  ),

                  ProfileTile(
                    icon: Icons.eco_outlined,
                    title: 'My Plants',
                    onTap: () {
                      context.go('/home');
                    },
                  ),

                  ProfileTile(
                    icon: Icons.wifi_rounded,
                    title: 'Connected Devices',
                    onTap: () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Device management is available from Device Setup.',
                            style:
                                GoogleFonts.poppins(
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor:
                              const Color(0xFF134E39),
                        ),
                      );
                    },
                  ),

                  ProfileTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                  ProfileTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notification Settings',
                    onTap: () {},
                  ),

                  ProfileTile(
                    icon: Icons.lock_outline,
                    title: 'Privacy & Security',
                    onTap: () {},
                  ),

                  ProfileTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {},
                  ),

                  ProfileTile(
                    icon: Icons.info_outline,
                    title: 'About App',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =====================================================
            // APP INFORMATION
            // =====================================================

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ProfileTile(
                    icon: Icons.system_update_alt,
                    title: 'App Version (v1.0.0)',
                    onTap: () {},
                  ),
                  ProfileTile(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () {},
                  ),
                  ProfileTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =====================================================
            // LOGOUT
            // =====================================================

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Colors.red,
                    width: 1.5,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                onPressed: () =>
                    _showLogoutDialog(context),
                icon: const Icon(
                  Icons.logout_rounded,
                ),
                label: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics(String? uid) {
    if (uid == null) {
      return _statisticsGrid(
        totalPlants: 0,
      );
    }

    final plantsRef = FirebaseDatabase
        .instance
        .ref('Users/$uid/Plants');

    return StreamBuilder<DatabaseEvent>(
      stream: plantsRef.onValue,
      builder: (context, snapshot) {
        int totalPlants = 0;

        if (snapshot.hasData &&
            snapshot.data!.snapshot.value != null) {
          final value =
              snapshot.data!.snapshot.value;

          if (value is Map) {
            totalPlants = value.length;
          }
        }

        return _statisticsGrid(
          totalPlants: totalPlants,
        );
      },
    );
  }

  Widget _statisticsGrid({
    required int totalPlants,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        StatCard(
          title: 'Plants',
          value: totalPlants.toString(),
          icon: Icons.eco,
        ),
        const StatCard(
          title: 'Connected Devices',
          value: '1',
          icon: Icons.wifi,
        ),
        const StatCard(
          title: 'Successful Irrigations',
          value: '0',
          icon: Icons.water_drop,
        ),
        const StatCard(
          title: 'Health Score',
          value: '92%',
          icon: Icons.favorite,
        ),
      ],
    );
  }
}