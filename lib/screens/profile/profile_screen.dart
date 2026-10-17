import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smart_plant_care/screens/profile/widgets/profile_header.dart';
import 'package:smart_plant_care/screens/profile/widgets/profile_tile.dart';
import 'package:smart_plant_care/screens/profile/widgets/stat_card.dart';
import 'package:smart_plant_care/screens/settings/settings_screen.dart';
import 'package:smart_plant_care/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _backgroundColor = Color(0xFFE4EDE6);
  static const Color _primaryColor = Color(0xFF134E39);

  bool _isSavingProfile = false;
  bool _isSendingResetEmail = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(),
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final user = _user;
    if (user == null) {
      _showMessage('Please sign in again to edit your profile.');
      return;
    }

    final nameController = TextEditingController(
      text: user.displayName ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 50,
            decoration: const InputDecoration(
              labelText: 'Display name',
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name.';
              }
              if (value.trim().length < 2) {
                return 'Name must contain at least 2 characters.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true || !mounted) {
      nameController.dispose();
      return;
    }

    final name = nameController.text.trim();
    nameController.dispose();

    setState(() => _isSavingProfile = true);
    try {
      await user.updateDisplayName(name);
      await user.reload();

      // Keep a lightweight profile record for app features that use RTDB.
      await FirebaseDatabase.instance.ref('Users/${user.uid}/Profile').update({
        'displayName': name,
        'email': user.email,
        'updatedAt': ServerValue.timestamp,
      });

      if (!mounted) return;
      setState(() {});
      _showMessage('Profile updated successfully.');
    } on FirebaseException catch (e) {
      _showMessage(e.message ?? 'Could not update your profile.');
    } catch (_) {
      _showMessage('Could not update your profile. Please try again.');
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) {
      _showMessage('No email address is linked to this account.');
      return;
    }

    setState(() => _isSendingResetEmail = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage('Password reset link sent to $email.');
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'invalid-email' => 'The account email address is invalid.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' => 'Check your internet connection and try again.',
        _ => e.message ?? 'Could not send the password reset email.',
      };
      _showMessage(message);
    } catch (_) {
      _showMessage('Could not send the password reset email. Please try again.');
    } finally {
      if (mounted) setState(() => _isSendingResetEmail = false);
    }
  }

  Future<void> _showPrivacySecurity() async {
    final user = _user;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy & Security',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Account email: ${user?.email ?? 'Not signed in'}',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                user?.emailVerified == true
                    ? 'Email status: Verified'
                    : 'Email status: Not verified',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: user?.emailVerified == true
                      ? _primaryColor
                      : Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_reset, color: _primaryColor),
                title: const Text('Reset password'),
                subtitle: Text(
                  user?.email == null
                      ? 'No account email is available'
                      : 'Send a secure reset link to your email',
                ),
                trailing: _isSendingResetEmail
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: user?.email == null || _isSendingResetEmail
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        _sendPasswordReset();
                      },
              ),
              if (user?.emailVerified == false)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.mark_email_unread_outlined,
                    color: _primaryColor,
                  ),
                  title: const Text('Verify email'),
                  subtitle: const Text('Send an email verification link'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    try {
                      await user?.sendEmailVerification();
                      _showMessage('Verification link sent to ${user?.email}.');
                    } on FirebaseAuthException catch (e) {
                      _showMessage(
                        e.message ?? 'Could not send the verification email.',
                      );
                    } catch (_) {
                      _showMessage('Could not send the verification email.');
                    }
                  },
                ),
              const SizedBox(height: 8),
              Text(
                'You can request a password reset or verify your email here. '
                'Your password is never displayed in the app.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showHelpSupport() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Smart Plant Care Help',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Quick troubleshooting\n\n'
          '• If readings look old, check that the controller is powered on '
          'and connected to Wi-Fi.\n\n'
          '• If soil moisture is DRY, check the sensor probe and soil contact.\n\n'
          '• If the pump does not respond, check the water supply, tubing, '
          'power, and relay connections before retrying.\n\n'
          '• If alerts do not arrive, open Settings and review notification '
          'permissions.\n\n'
          '• If sign-in fails, check your connection or use Password Reset '
          'under Privacy & Security.',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAboutApp() async {
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
          'A plant monitoring and irrigation application with live sensor '
          'readings, manual and automatic watering, event history, alerts, '
          'and AI-based soil forecasting.',
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Log Out',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    try {
      await AuthService().signOut();
      if (mounted) context.go('/login');
    } catch (_) {
      _showMessage('Unable to log out. Please try again.');
    }
  }

  int _countRecords(dynamic value) {
    if (value is Map) return value.length;
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

    final plantsRef = FirebaseDatabase.instance.ref('Users/$uid/Plants');
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

            return LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 10) / 2;
                return Row(
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'My Plants',
                        value: plantSnapshot.hasError
                            ? '—'
                            : plantCount.toString(),
                        icon: Icons.eco_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: cardWidth,
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
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 18),
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
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, color: _primaryColor),
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
            icon: _isSavingProfile
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_outlined, color: _primaryColor),
            onPressed: _isSavingProfile ? null : _showEditProfileDialog,
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
                    onTap: _showEditProfileDialog,
                  ),
                  const Divider(height: 1, indent: 56),
                  ProfileTile(
                    icon: Icons.eco_outlined,
                    title: 'My Plants',
                    onTap: () => context.go('/home'),
                  ),
                ],
              ),
              _sectionTitle('Preferences & Security'),
              _buildCard(
                children: [
                  ProfileTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: _openSettings,
                  ),
                  const Divider(height: 1, indent: 56),
                  ProfileTile(
                    icon: Icons.notifications_none_outlined,
                    title: 'Notification Settings',
                    onTap: _openSettings,
                  ),
                  const Divider(height: 1, indent: 56),
                  ProfileTile(
                    icon: Icons.lock_outline,
                    title: 'Privacy & Security',
                    onTap: _showPrivacySecurity,
                  ),
                ],
              ),
              _sectionTitle('Support'),
              _buildCard(
                children: [
                  ProfileTile(
                    icon: Icons.help_outline,
                    title: 'Help & Troubleshooting',
                    onTap: _showHelpSupport,
                  ),
                  const Divider(height: 1, indent: 56),
                  ProfileTile(
                    icon: Icons.info_outline,
                    title: 'About Smart Plant Care',
                    onTap: _showAboutApp,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showLogoutDialog,
                  icon: const Icon(Icons.logout),
                  label: Text(
                    'Log Out',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
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