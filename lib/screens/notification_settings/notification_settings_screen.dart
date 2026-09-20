import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smart_plant_care/services/notification_settings_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationSettingsService _service =
      NotificationSettingsService.instance;

  Map<String, dynamic> _settings = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings =
        await _service.getSettings();

    if (!mounted) return;

    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _updateSetting(
    String key,
    bool value,
  ) async {
    setState(() {
      _settings[key] = value;
    });

    try {
      await _service.updateSetting(
        key,
        value,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save notification setting.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required String settingKey,
    required IconData icon,
  }) {
    final bool value =
        _settings[settingKey] == true;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: SwitchListTile(
        value: value,
        onChanged: (newValue) {
          _updateSetting(
            settingKey,
            newValue,
          );
        },
        secondary: Icon(icon),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: SwitchListTile(
                    value:
                        _settings['enabled'] == true,
                    onChanged: (value) {
                      _updateSetting(
                        'enabled',
                        value,
                      );
                    },
                    secondary: const Icon(
                      Icons.notifications_active,
                    ),
                    title: Text(
                      'Notifications',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Enable or disable Smart Plant Care notifications.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Notification Categories',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                _buildSwitchTile(
                  title: 'Soil Moisture',
                  subtitle:
                      'Alerts related to dry or wet soil conditions.',
                  settingKey: 'soilMoisture',
                  icon: Icons.water_drop,
                ),

                _buildSwitchTile(
                  title: 'Irrigation',
                  subtitle:
                      'Pump and automatic watering events.',
                  settingKey: 'irrigation',
                  icon: Icons.local_drink,
                ),

                _buildSwitchTile(
                  title: 'Environmental Alerts',
                  subtitle:
                      'Temperature, humidity and light alerts.',
                  settingKey: 'environmental',
                  icon: Icons.thermostat,
                ),

                _buildSwitchTile(
                  title: 'Device Alerts',
                  subtitle:
                      'Device connection and system alerts.',
                  settingKey: 'deviceAlerts',
                  icon: Icons.memory,
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'These settings control notification categories inside Smart Plant Care. '
                      'Android notification permission is managed separately by the operating system.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}