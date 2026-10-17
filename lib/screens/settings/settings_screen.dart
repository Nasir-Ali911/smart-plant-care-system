import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'package:smart_plant_care/screens/about/about_screen.dart';
import 'package:smart_plant_care/services/app_settings.dart';
import 'widgets/section_header.dart';
import 'widgets/settings_tile.dart';
import 'widgets/settings_switch_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _green = Color(0xFF134E39);

  Future<void> _showInfo(
    BuildContext context,
    String title,
    String body,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _green,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(body, style: GoogleFonts.poppins(fontSize: 13)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSettings(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Reset Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: _green,
          ),
        ),
        content: Text(
          'Switch the app appearance back to Light Mode?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await AppSettings.instance.setDarkMode(false);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appearance reset to Light Mode.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          const SectionHeader(title: 'Appearance'),
          SettingsSwitchTile(
            title: 'Dark Mode',
            icon: Icons.dark_mode_outlined,
            value: dark,
            onChanged: (value) => AppSettings.instance.setDarkMode(value),
          ),

          const SectionHeader(title: 'Device Help'),
          SettingsTile(
            title: 'Wi-Fi Troubleshooting',
            icon: Icons.wifi_rounded,
            onTap: () => _showInfo(
              context,
              'Wi-Fi Troubleshooting',
              'The ESP8266 uses the Wi-Fi credentials configured in its firmware. '
                  'To change networks, update those credentials in the firmware and upload it again. '
                  'Make sure the controller has stable power and that the selected Wi-Fi network has internet access.',
            ),
          ),
          SettingsTile(
            title: 'Reconnect Device',
            icon: Icons.settings_input_antenna_rounded,
            onTap: () => _showInfo(
              context,
              'Reconnect Device',
              '1. Check that the ESP8266 is powered.\n'
                  '2. Check the Wi-Fi credentials in the firmware.\n'
                  '3. Confirm the network can access Firebase.\n'
                  '4. Restart the controller and allow it time to reconnect.\n\n'
                  'This app cannot remotely change the controller’s Wi-Fi credentials.',
            ),
          ),

          const SectionHeader(title: 'Application'),
          SettingsTile(
            title: 'Privacy & Data',
            icon: Icons.privacy_tip_outlined,
            onTap: () => _showInfo(
              context,
              'Privacy & Data',
              'Smart Plant Care uses Firebase Authentication and Realtime Database for account and plant data. '
                  'Camera images may be uploaded to the configured image-hosting service. '
                  'Avoid storing passwords or other sensitive personal information in plant records.',
            ),
          ),
          SettingsTile(
            title: 'Terms & Conditions',
            icon: Icons.description_outlined,
            onTap: () => _showInfo(
              context,
              'Terms & Conditions',
              'Smart Plant Care is a monitoring and assistance tool. Sensor readings and forecasts may be imperfect. '
                  'Check water availability, tubing, electrical safety, and actual plant conditions before relying on irrigation automation.',
            ),
          ),
          SettingsTile(
            title: 'About App',
            icon: Icons.info_outline_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AboutScreen(),
              ),
            ),
          ),
          SettingsTile(
            title: 'Share Application',
            icon: Icons.share_outlined,
            onTap: () => SharePlus.instance.share(
              ShareParams(
                text: 'Smart Plant Care — plant monitoring, irrigation control, alerts, and AI-based soil forecasting.',
              ),
            ),
          ),

          const SizedBox(height: 24),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _green, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _resetSettings(context),
            child: Text(
              'Reset Appearance',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _green,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}