import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_plant_care/constants/app_colors.dart';
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

class _DeviceSetupScreenState extends State<DeviceSetupScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isScanning = false;
  bool _isConnected = false;
  String _connectionStatus = 'Not Connected';
  String _selectedDevice = 'esp8622-SmartPlant-01';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar(
        'Please fill in all required fields',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate connection process
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isConnected = true;
      _connectionStatus = 'Connected';
    });

    _showSnackBar(
      'Device connected successfully!',
      isError: false,
    );

    // Navigate to live monitoring after short delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LiveMonitoringScreen(),
      ),
    );
  }

  Future<void> _handleScan() async {
    setState(() {
      _isScanning = true;
    });

    // Simulate scanning
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isScanning = false;
    });

    _showSnackBar(
      'Scan complete. Device found: $_selectedDevice',
      isError: false,
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(
          'Device Setup',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              color: AppColors.primary,
            ),
            onPressed: () {
              _showHelpDialog();
            },
            tooltip: 'Help',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + bottomPadding + keyboardHeight,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(isSmallScreen),
                    const SizedBox(height: 20),
                    _buildConnectionStatus(isSmallScreen),
                    const SizedBox(height: 20),
                    _buildSetupSteps(isSmallScreen),
                    const SizedBox(height: 24),
                    _buildWifiConfiguration(isSmallScreen),
                    const SizedBox(height: 24),
                    _buildSensorPreview(isSmallScreen),
                    const SizedBox(height: 28),
                    _buildActionButtons(isSmallScreen),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _buildWelcomeCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD0E2D4),
            const Color(0xFFD0E2D4).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isSmallScreen ? 40 : 48,
            height: isSmallScreen ? 40 : 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.wifi_tethering,
              size: isSmallScreen ? 24 : 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect your Smart Plant Device',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Follow the steps below to connect your esp8622-based monitoring system.',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 11 : 13,
                    color: const Color(0xFF5A7865),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONNECTION STATUS
  // ============================================================

  Widget _buildConnectionStatus(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isConnected
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 36 : 40,
            height: isSmallScreen ? 36 : 40,
            decoration: BoxDecoration(
              color: _isConnected
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isConnected ? Icons.check_circle : Icons.devices,
              color: _isConnected ? Colors.green : Colors.grey,
              size: isSmallScreen ? 18 : 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDevice,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _connectionStatus,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: _isConnected ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusDot(),
        ],
      ),
    );
  }

  Widget _buildStatusDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isConnected ? Colors.green : Colors.grey,
        boxShadow: [
          BoxShadow(
            color: (_isConnected ? Colors.green : Colors.grey)
                .withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SETUP STEPS
  // ============================================================

  Widget _buildSetupSteps(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Setup Steps',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        SetupStepCard(
          stepNumber: '1',
          title: 'Power on esp8622 device',
          isCompleted: _isConnected,
        ),
        SetupStepCard(
          stepNumber: '2',
          title: 'Connect phone to esp8622 Wi-Fi hotspot',
          isCompleted: _isConnected,
        ),
        SetupStepCard(
          stepNumber: '3',
          title: 'Enter Home Wi-Fi credentials below',
          isCompleted: _isConnected,
        ),
        SetupStepCard(
          stepNumber: '4',
          title: 'Establish secure local connection',
          isCompleted: _isConnected,
        ),
        SetupStepCard(
          stepNumber: '5',
          title: 'Finish setup and view telemetry',
          isCompleted: _isConnected,
        ),
      ],
    );
  }

  // ============================================================
  // WIFI CONFIGURATION
  // ============================================================

  Widget _buildWifiConfiguration(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wi-Fi Configuration',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _ssidController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter Wi-Fi name';
            }
            return null;
          },
          decoration: _buildInputDecoration(
            labelText: 'Wi-Fi Name (SSID)',
            hintText: 'Enter home network name',
            prefixIcon: Icons.wifi,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
          decoration: _buildInputDecoration(
            labelText: 'Password',
            hintText: 'Enter network password',
            prefixIcon: Icons.lock,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
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
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.red.shade300,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.red.shade300,
          width: 2,
        ),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.primary, size: 20)
          : null,
      suffixIcon: suffixIcon,
      labelStyle: GoogleFonts.poppins(
        color: Colors.grey.shade600,
      ),
      hintStyle: GoogleFonts.poppins(
        color: Colors.grey.shade400,
      ),
    );
  }

  // ============================================================
  // SENSOR PREVIEW
  // ============================================================

  Widget _buildSensorPreview(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Sensor Preview',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _isConnected ? 'Live data' : 'Waiting for device...',
                  key: ValueKey(_isConnected),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 10 : 11,
                    fontStyle: FontStyle.italic,
                    color: _isConnected ? Colors.green : const Color(0xFF5A7865),
                  ),
                ),
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
          childAspectRatio: isSmallScreen ? 0.95 : 1.05,
          children: [
            SensorPreviewCard(
              title: 'Temperature',
              value: _isConnected ? '24.5 °C' : '-- °C',
              icon: Icons.thermostat,
              isActive: _isConnected,
            ),
            SensorPreviewCard(
              title: 'Soil Moisture',
              value: _isConnected ? '65 %' : '-- %',
              icon: Icons.water_drop,
              isActive: _isConnected,
            ),
            SensorPreviewCard(
              title: 'Humidity',
              value: _isConnected ? '48 %' : '-- %',
              icon: Icons.air,
              isActive: _isConnected,
            ),
            SensorPreviewCard(
              title: 'Light Intensity',
              value: _isConnected ? '850 lux' : '-- %',
              icon: Icons.wb_sunny_outlined,
              isActive: _isConnected,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons(bool isSmallScreen) {
    return Column(
      children: [
        ActionButton(
          label: _isConnected ? 'Connected' : 'Connect Device',
          onPressed: _handleConnect,
          isPrimary: true,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 12),
        ActionButton(
          label: _isScanning ? 'Scanning...' : 'Scan Again',
          onPressed: _handleScan,
          isPrimary: false,
          isLoading: _isScanning,
        ),
      ],
    );
  }

  // ============================================================
  // HELP DIALOG
  // ============================================================

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.help_outline,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Setup Help',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                icon: Icons.power,
                text: 'Ensure your esp8622 device is powered on and nearby',
              ),
              _buildHelpItem(
                icon: Icons.wifi,
                text: 'Connect to the esp8622 Wi-Fi hotspot (usually named "esp8622-SmartPlant")',
              ),
              _buildHelpItem(
                icon: Icons.router,
                text: 'Enter your home Wi-Fi credentials for internet access',
              ),
              _buildHelpItem(
                icon: Icons.sync,
                text: 'The device will automatically connect and start sending data',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Got it',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}