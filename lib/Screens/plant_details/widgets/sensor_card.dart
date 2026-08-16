import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SensorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String status;

  const SensorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0EC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF134E39), size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4EDDA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF155724),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF5A7865),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF134E39),
            ),
          ),
        ],
      ),
    );
  }
}