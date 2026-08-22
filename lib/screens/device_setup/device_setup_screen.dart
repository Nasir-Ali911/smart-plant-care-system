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

  Future<void> _handleConnect() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LiveMonitoringScreen(),
      ),
    );
  }

  void _handleScanAgain() {
    if (_isLoading) return;

    // Scan functionality can be added here later.
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      resizeToAvoidBottomInset: true,

      // ================================================================
      // APP BAR
      // ================================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF134E39),
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          'Device Setup',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E39),
          ),
        ),
      ),

      // ================================================================
      // BODY
      // ================================================================
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,

          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            32 + bottomSafeArea,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================================
              // WELCOME CARD
              // ==========================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: const Color(0xFFD0E2D4),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.wifi_tethering,
                      size: 40,
                      color: Color(0xFF134E39),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connect your Smart Plant Device',
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF134E39),
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'Follow the steps below to connect your ESP32-based monitoring system.',
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              height: 1.4,
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

              // ==========================================================
              // DEVICE CONNECTION CARD
              // ==========================================================
              const DeviceCard(),

              const SizedBox(height: 22),

              // ==========================================================
              // SETUP STEPS TITLE
              // ==========================================================
              Text(
                'Setup Steps',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF134E39),
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================================
              // STEP 1
              // ==========================================================
              const SetupStepCard(
                stepNumber: '1',
                title: 'Power on ESP32 device',
              ),

              // ==========================================================
              // STEP 2
              // ==========================================================
              const SetupStepCard(
                stepNumber: '2',
                title: 'Connect phone to ESP32 Wi-Fi hotspot',
              ),

              // ==========================================================
              // STEP 3
              // ==========================================================
              const SetupStepCard(
                stepNumber: '3',
                title: 'Enter Home Wi-Fi credentials below',
              ),

              // ==========================================================
              // STEP 4
              // ==========================================================
              const SetupStepCard(
                stepNumber: '4',
                title: 'Establish secure local connection',
              ),

              // ==========================================================
              // STEP 5
              // ==========================================================
              const SetupStepCard(
                stepNumber: '5',
                title: 'Finish setup and view telemetry',
              ),

              const SizedBox(height: 12),

              // ==========================================================
              // WI-FI CONFIGURATION
              // ==========================================================
              Text(
                'Wi-Fi Configuration',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF134E39),
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================================
              // SSID FIELD
              // ==========================================================
              TextField(
                controller: _ssidController,
                textInputAction: TextInputAction.next,

                decoration: InputDecoration(
                  labelText: 'Wi-Fi Name (SSID)',
                  hintText: 'Enter home network name',

                  filled: true,
                  fillColor: Colors.white,

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF134E39),
                      width: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================================
              // PASSWORD FIELD
              // ==========================================================
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,

                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter network password',

                  filled: true,
                  fillColor: Colors.white,

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF134E39),
                      width: 1.2,
                    ),
                  ),

                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',

                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF5A7865),
                    ),

                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==========================================================
              // SENSOR PREVIEW HEADER
              // ==========================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Sensor Preview',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF134E39),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Flexible(
                    child: Text(
                      'Waiting for device...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF5A7865),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==========================================================
              // SENSOR PREVIEW GRID
              // ==========================================================
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),

                // More vertical room for sensor card content.
                childAspectRatio: 1.45,

                children: const [
                  SensorPreviewCard(
                    title: 'Temperature',
                    value: '-- °C',
                    icon: Icons.thermostat,
                  ),

                  SensorPreviewCard(
                    title: 'Soil Moisture',
                    value: '-- %',
                    icon: Icons.water_drop,
                  ),

                  SensorPreviewCard(
                    title: 'Humidity',
                    value: '-- %',
                    icon: Icons.air,
                  ),

                  SensorPreviewCard(
                    title: 'Light Intensity',
                    value: '-- %',
                    icon: Icons.wb_sunny_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ==========================================================
              // CONNECT DEVICE BUTTON
              // ==========================================================
              SizedBox(
                width: double.infinity,
                child: ActionButton(
                  label: 'Connect Device',
                  onPressed: _handleConnect,
                  isPrimary: true,
                  isLoading: _isLoading,
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================================
              // SCAN AGAIN BUTTON
              // ==========================================================
              SizedBox(
                width: double.infinity,
                child: ActionButton(
                  label: 'Scan Again',
                  onPressed: _handleScanAgain,
                  isPrimary: false,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}