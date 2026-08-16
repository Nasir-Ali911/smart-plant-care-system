import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentActivityCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;

  const RecentActivityCard({
    super.key,
    required this.title,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFD0E2D4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF134E39),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF134E39),
          ),
        ),
        subtitle: Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5A7865),
          ),
        ),
      ),
    );
  }
}