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

  static const Color _backgroundColor = Color(0xFFE4EDE6);
  static const Color _primaryColor = Color(0xFF134E39);

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Log Out',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    try {
      await AuthService().signOut();

      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Unable to log out. Please try again.');
      }
    }
  }

  int _countRecords(dynamic value) {
    if (value is Map) {
      return value.length;
    }

    if (value is List) {
      return value.where((item) => item != null).length;
    }

    return 0;
  }

  Widget _buildStatistics(String? uid) {
    if (uid == null) {
      return const Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(
            width: 150,
            child: StatCard(
              title: 'My Plants',
              value: '0',
              icon: Icons.eco_outlined,
            ),
          ),
          SizedBox(
            width: 150,
            child: StatCard(
              title: 'Watering Events',
              value: '0',
              icon: Icons.water_drop_outlined,
            ),
          ),
        ],
      );
    }

    final plantsRef =
        FirebaseDatabase.instance.ref('Users/$uid/Plants');

    final wateringRef =
        FirebaseDatabase.instance.ref('SmartPlant/WateringEvents');

    return StreamBuilder<DatabaseEvent>(
      stream: plantsRef.onValue,
      builder: (context, plantSnapshot) {
        final plantCount = plantSnapshot.hasData
            ? _countRecords(plantSnapshot.data!.snapshot.value)
            : 0;

        return StreamBuilder<DatabaseEvent>(
          stream: wateringRef.onValue,
          builder: (context, wateringSnapshot) {
            final wateringCount = wateringSnapshot.hasData
                ? _countRecords(wateringSnapshot.data!.snapshot.value)
                : 0;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 150,
                  child: StatCard(
                    title: 'My Plants',
                    value: plantSnapshot.hasError
                        ? '—'
                        : plantCount.toString(),
                    icon: Icons.eco_outlined,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: StatCard(
                    title: 'Watering Events',
                    value: wateringSnapshot.hasError
                        ? '—'
                        : wateringCount.toString(),
                    icon: Icons.water_drop_outlined,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
        top: 18,
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _primaryColor,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: _primaryColor,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            color: _primaryColor,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(
              Icons.edit_outlined,
              color: _primaryColor,
            ),
            onPressed: () => _showMessage(
              context,
              'Profile editing is not available yet.',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileHeader(),

              _sectionTitle('Your Overview'),

              _buildStatistics(uid),

              _sectionTitle('Account'),

              _buildCard(
                children: [
                  ProfileTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    onTap: () => _showMessage(
                      context,
                      'Profile editing is not available yet.',
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ProfileTile(
                    icon: Icons.eco_outlined,
                    title: 'My Plants',
                    onTap: () => context.go('/home'),
                  ),
                  const Divider(height: 1, indent: 56),
                  ProfileTile(
                    icon: Icons.devices_outlined,
                    title: 'Connected Devices',
                    onTap: () => _showMessage(
                      context,
                      'Device management is not available here yet.',
                    ),
                  ),
                ],
              ),

              _sectionTitle('Preferences & Support'),

              _buildCard(
                children: [
                  ProfileTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => _openSettings(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  ProfileTile(
                    icon: Icons.notifications_none_outlined,
                    title: 'Notification Settings',
                    onTap: () => _openSettings(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  ProfileTile(
                    icon: Icons.lock_outline,
                    title: 'Privacy & Security',
                    onTap: () => _showMessage(
                      context,
                      'Privacy options are not available on this page yet.',
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ProfileTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () => _showMessage(
                      context,
                      'Help and support will be available soon.',
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ProfileTile(
                    icon: Icons.info_outline,
                    title: 'About App',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Smart Plant Care',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(
                          Icons.local_florist,
                          color: _primaryColor,
                          size: 36,
                        ),
                        children: [
                          const Text(
                            'An intelligent plant monitoring and '
                            'irrigation system with sensor monitoring, '
                            'automated watering, and AI-based forecasting.',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),

              _sectionTitle('App Information'),

              _buildCard(
                children: [
                  ProfileTile(
                    icon: Icons.phone_android_outlined,
                    title: 'App Version',
                    onTap: () => _showMessage(
                      context,
                      'Smart Plant Care version 1.0.0',
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ProfileTile(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () => _showMessage(
                      context,
                      'Terms and conditions are not available yet.',
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ProfileTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _showMessage(
                      context,
                      'Privacy policy is not available yet.',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout),
                  label: Text(
                    'Log Out',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(
                      color: Colors.red.shade200,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Text(
                  'Smart Plant Care • v1.0.0',
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}