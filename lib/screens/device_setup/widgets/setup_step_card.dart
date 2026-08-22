import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SetupStepCard extends StatelessWidget {
  final String stepNumber;
  final String title;

  const SetupStepCard({
    super.key,
    required this.stepNumber,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD0E2D4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF134E39),
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF134E39),
              ),
            ),
          ),
        ],
      ),
    );
  }
}