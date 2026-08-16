import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyNotification extends StatelessWidget {
  const EmptyNotification({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFD0E2D4).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: Color(0xFF134E39),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF134E39),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Everything looks good!',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF5A7865),
              ),
            ),
          ],
        ),
      ),
    );
  }
}