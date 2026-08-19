import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFE4EDE6),
      body: Center(
        // Constrain max width so it mimics a mobile device screen on web/tablets
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
                      
                      // --- Logo and Circular Background ---
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
                      
                      // --- Title ---
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
                      
                      // --- Subtitle ---
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
                      
                      // --- Bottom Icon ---
                      const Icon(
                        Icons.spa_outlined,
                        size: 32,
                        color: Color(0xFF134E39),
                      ),
                      const SizedBox(height: 12),
                      
                      // --- Version Text ---
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
              
              // --- Bottom Curve ---
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