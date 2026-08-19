import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/app_logo.dart';
import 'widgets/info_card.dart';
import 'widgets/feature_tile.dart';
import 'widgets/developer_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          'About Smart Plant Care',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E39),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Logo Section ---
            const AppLogo(),
            const SizedBox(height: 28),

            // --- Application Description ---
            InfoCard(
              title: 'Overview',
              child: Text(
                'Smart Plant Care is an IoT-powered mobile application that helps users monitor environmental conditions, manage smart irrigation, and track plant health through connected sensors and intelligent monitoring.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF5A7865),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Key Features Section ---
            Text(
              'Key Features',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF134E39),
              ),
            ),
            const SizedBox(height: 12),
            const FeatureTile(
              icon: Icons.show_chart_rounded,
              title: 'Real-Time Monitoring',
              description: 'Live sensor tracking for temperature, humidity, and soil moisture.',
            ),
            const FeatureTile(
              icon: Icons.water_drop_rounded,
              title: 'Smart Irrigation',
              description: 'Automated water scheduling based on real-time soil conditions.',
            ),
            const FeatureTile(
              icon: Icons.settings_input_antenna_rounded,
              title: 'ESP32 Device Integration',
              description: 'Seamless hardware connectivity via Wi-Fi and microcontroller units.',
            ),
            const FeatureTile(
              icon: Icons.eco_rounded,
              title: 'Plant Management',
              description: 'Organize and track individual plant health metrics across multiple zones.',
            ),
            const FeatureTile(
              icon: Icons.notifications_active_rounded,
              title: 'Notifications & Alerts',
              description: 'Instant push alerts for critical water levels and environment changes.',
            ),
            const FeatureTile(
              icon: Icons.psychology_rounded,
              title: 'AI-Based Insights',
              description: 'Intelligent recommendations for optimal plant growth and care.',
            ),
            const SizedBox(height: 20),

            // --- Developer Information ---
            InfoCard(
              title: 'Developer Information',
              child: Column(
                children: const [
                  DeveloperCard(
                    label: 'Developer Name',
                    value: 'Nasir Ali',
                    icon: Icons.person_rounded,
                  ),
                  DeveloperCard(
                    label: 'Project Type',
                    value: 'Final Year Project (BSCS)',
                    icon: Icons.school_rounded,
                  ),
                  DeveloperCard(
                    label: 'Institution',
                    value: 'Virtual University of Pakistan',
                    icon: Icons.account_balance_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Technology Stack ---
            InfoCard(
              title: 'Technology Stack',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _TechChip(label: 'Flutter'),
                  _TechChip(label: 'Material 3'),
                  _TechChip(label: 'Google Fonts'),
                  _TechChip(label: 'ESP32 IoT'),
                  _TechChip(label: 'Python / RAG'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Footer Copyright ---
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2026 Smart Plant Care',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5A7865),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Made with ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF5A7865),
                        ),
                      ),
                      const Icon(Icons.favorite, color: Colors.red, size: 14),
                      Text(
                        ' using Flutter',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF5A7865),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Private helper widget for technology stack chips
class _TechChip extends StatelessWidget {
  final String label;

  const _TechChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE4EDE6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF134E39),
        ),
      ),
    );
  }
}