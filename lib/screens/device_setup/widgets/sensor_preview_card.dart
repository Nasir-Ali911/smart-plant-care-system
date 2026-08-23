import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SensorPreviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isActive;

  const SensorPreviewCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor =
        isActive ? const Color(0xFF134E39) : Colors.grey;

    final Color secondaryColor =
        isActive ? const Color(0xFF5A7865) : Colors.grey.shade500;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? const Color(0xFFD0E2D4)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: secondaryColor,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? const Color(0xFF2E7D32)
                      : Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}