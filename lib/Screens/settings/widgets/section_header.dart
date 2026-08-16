import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF134E39), // Deep forest green matching your theme
        ),
      ),
    );
  }
}