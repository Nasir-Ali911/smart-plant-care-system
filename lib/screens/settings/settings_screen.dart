import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/section_header.dart';
import 'widgets/settings_tile.dart';
import 'widgets/settings_switch_tile.dart';
import 'package:smart_plant_care/screens/about/about_screen.dart'; // <- Imported About Screen

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local state variables for switches
  bool _isDarkMode = false;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _reminderNotifications = true;
  bool _automaticIrrigation = true;
  bool _temperatureAlerts = true;
  bool _soilMoistureAlerts = true;
  bool _humidityAlerts = false;

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Reset Settings',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF134E39),
            ),
          ),
          content: Text(
            'Are you sure you want to reset all settings to their default values?',
            style: GoogleFonts.poppins(
              color: const Color(0xFF5A7865),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF5A7865)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF134E39),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isDarkMode = false;
                  _pushNotifications = true;
                  _emailNotifications = false;
                  _reminderNotifications = true;
                  _automaticIrrigation = true;
                  _temperatureAlerts = true;
                  _soilMoistureAlerts = true;
                  _humidityAlerts = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Settings reset successfully.',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: const Color(0xFF134E39),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                'Reset',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4EDE6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF134E39), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E39),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Section 1: Appearance ---
            const SectionHeader(title: 'Appearance'),
            SettingsSwitchTile(
              title: 'Dark Mode',
              icon: Icons.dark_mode_outlined,
              value: _isDarkMode,
              onChanged: (val) => setState(() => _isDarkMode = val),
            ),
            SettingsTile(
              title: 'Language',
              icon: Icons.language_outlined,
              trailingText: 'English',
              onTap: () {},
            ),
            SettingsTile(
              title: 'Font Size',
              icon: Icons.text_fields_rounded,
              trailingText: 'Medium',
              onTap: () {},
            ),

            // --- Section 2: Notifications ---
            const SectionHeader(title: 'Notifications'),
            SettingsSwitchTile(
              title: 'Push Notifications',
              icon: Icons.notifications_active_outlined,
              value: _pushNotifications,
              onChanged: (val) => setState(() => _pushNotifications = val),
            ),
            SettingsSwitchTile(
              title: 'Email Notifications',
              icon: Icons.email_outlined,
              value: _emailNotifications,
              onChanged: (val) => setState(() => _emailNotifications = val),
            ),
            SettingsSwitchTile(
              title: 'Reminder Notifications',
              icon: Icons.alarm_rounded,
              value: _reminderNotifications,
              onChanged: (val) => setState(() => _reminderNotifications = val),
            ),

            // --- Section 3: Plant Monitoring ---
            const SectionHeader(title: 'Plant Monitoring'),
            SettingsSwitchTile(
              title: 'Automatic Irrigation',
              icon: Icons.water_drop_outlined,
              value: _automaticIrrigation,
              onChanged: (val) => setState(() => _automaticIrrigation = val),
            ),
            SettingsSwitchTile(
              title: 'Temperature Alerts',
              icon: Icons.thermostat_outlined,
              value: _temperatureAlerts,
              onChanged: (val) => setState(() => _temperatureAlerts = val),
            ),
            SettingsSwitchTile(
              title: 'Soil Moisture Alerts',
              icon: Icons.grass_rounded,
              value: _soilMoistureAlerts,
              onChanged: (val) => setState(() => _soilMoistureAlerts = val),
            ),
            SettingsSwitchTile(
              title: 'Humidity Alerts',
              icon: Icons.air_rounded,
              value: _humidityAlerts,
              onChanged: (val) => setState(() => _humidityAlerts = val),
            ),

            // --- Section 4: Device ---
            const SectionHeader(title: 'Device'),
            SettingsTile(
              title: 'Wi-Fi Settings',
              icon: Icons.wifi_rounded,
              onTap: () {},
            ),
            SettingsTile(
              title: 'Reconnect Device',
              icon: Icons.settings_input_antenna_rounded,
              onTap: () {},
            ),
            SettingsTile(
              title: 'Firmware Version',
              icon: Icons.info_outline_rounded,
              trailingText: 'v1.0.0',
              onTap: () {},
            ),

            // --- Section 5: Application ---
            const SectionHeader(title: 'Application'),
            SettingsTile(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip_outlined,
              onTap: () {},
            ),
            SettingsTile(
              title: 'Terms & Conditions',
              icon: Icons.description_outlined,
              onTap: () {},
            ),
            SettingsTile(
              title: 'About App', // <- Linked to AboutScreen
              icon: Icons.info_outline_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                );
              },
            ),
            SettingsTile(
              title: 'Rate Application',
              icon: Icons.star_outline_rounded,
              onTap: () {},
            ),
            SettingsTile(
              title: 'Share Application',
              icon: Icons.share_outlined,
              onTap: () {},
            ),

            const SizedBox(height: 24),

            // --- Bottom Reset Button ---
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF134E39), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _showResetDialog,
              child: Text(
                'Reset Settings',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF134E39),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}