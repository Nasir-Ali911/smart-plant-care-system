import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImagePickerCard extends StatelessWidget {
  const ImagePickerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFD0E2D4),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF134E39), width: 1.5),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              size: 40,
              color: Color(0xFF134E39),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to add plant image',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5A7865),
            ),
          ),
        ],
      ),
    );
  }
}