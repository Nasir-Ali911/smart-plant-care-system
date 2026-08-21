import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Keep the splash screen visible for at least 3 seconds
      await Future.wait([
        firebaseInitialization,
        Future.delayed(const Duration(seconds: 3)),
      ]);
    } catch (error) {
      debugPrint('Startup initialization error: $error');

      // Still wait briefly so the splash does not disappear abruptly.
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;

    // Navigate only after initialization and after the widget is mounted.
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4EDE6),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Logo and circular background
                      Center(
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFD0E2D4),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.eco,
                              size: 85,
                              color: Color(0xFF134E39),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Title
                      Text(
                        'Smart Plant Care',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF134E39),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'AI-Based Plant Monitoring System',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5A7865),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Bottom icon
                      const Icon(
                        Icons.spa_outlined,
                        size: 32,
                        color: Color(0xFF134E39),
                      ),

                      const SizedBox(height: 12),

                      // Version
                      Text(
                        'Version 1.0.0',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF134E39),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Bottom curve
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: BottomCurveClipper(),
                  child: Container(
                    height: 130,
                    color: const Color(0xFF2C5E4B),
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

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, 35);

    path.quadraticBezierTo(
      size.width / 2,
      -25,
      size.width,
      35,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}