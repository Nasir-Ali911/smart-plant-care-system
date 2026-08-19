import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_plant_care/screens/device_setup/widgets/device_card.dart';
import 'package:smart_plant_care/screens/device_setup/widgets/setup_step_card.dart';
import 'package:smart_plant_care/screens/device_setup/widgets/sensor_preview_card.dart';
import 'package:smart_plant_care/screens/device_setup/widgets/action_button.dart';
import 'package:smart_plant_care/screens/live_monitoring/live_monitoring_screen.dart';

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleConnect() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    // --- Navigate to Live Monitoring Screen ---
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LiveMonitoringScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF134E39)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Device Setup',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E39),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Welcome Card ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFD0E2D4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_tethering, size: 40, color: Color(0xFF134E39)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect your Smart Plant Device',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF134E39),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Follow the steps below to connect your ESP32-based monitoring system.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF5A7865),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Connection Status Card ---
            const DeviceCard(),
            const SizedBox(height: 20),

            // --- Setup Steps Section ---
            Text(
              'Setup Steps',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF134E39),
              ),
            ),
            const SizedBox(height: 12),
            const SetupStepCard(stepNumber: '1', title: 'Power on ESP32 device'),
            const SetupStepCard(stepNumber: '2', title: 'Connect phone to ESP32 Wi-Fi hotspot'),
            const SetupStepCard(stepNumber: '3', title: 'Enter Home Wi-Fi credentials below'),
            const SetupStepCard(stepNumber: '4', title: 'Establish secure local connection'),
            const SetupStepCard(stepNumber: '5', title: 'Finish setup and view telemetry'),
            const SizedBox(height: 20),

            // --- Wi-Fi Configuration Section ---
            Text(
              'Wi-Fi Configuration',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF134E39),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ssidController,
              decoration: InputDecoration(
                labelText: 'Wi-Fi Name (SSID)',
                hintText: 'Enter home network name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter network password',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF5A7865)),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Sensor Preview Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sensor Preview',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF134E39),
                  ),
                ),
                Text(
                  'Waiting for device...',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF5A7865),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: const [
                SensorPreviewCard(title: 'Temperature', value: '-- °C', icon: Icons.thermostat),
                SensorPreviewCard(title: 'Soil Moisture', value: '-- %', icon: Icons.water_drop),
                SensorPreviewCard(title: 'Humidity', value: '-- %', icon: Icons.air),
                SensorPreviewCard(title: 'Light Intensity', value: '-- %', icon: Icons.wb_sunny_outlined),
              ],
            ),
            const SizedBox(height: 30),

            // --- Action Buttons ---
            ActionButton(
              label: 'Connect Device',
              onPressed: _handleConnect,
              isPrimary: true,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            ActionButton(
              label: 'Scan Again',
              onPressed: () {},
              isPrimary: false,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}