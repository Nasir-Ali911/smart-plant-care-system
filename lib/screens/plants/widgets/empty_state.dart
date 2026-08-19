import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlantEmptyState extends StatelessWidget {
  const PlantEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD0E2D4),
              ),
              child: const Icon(
                Icons.eco_outlined,
                size: 40,
                color: Color(0xFF134E39),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Plants Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF134E39),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first plant.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5A7865),
              ),
            ),
          ],
        ),
      ),
    );
  }
}