import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlantFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const PlantFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF134E39),
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF134E39),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: isSelected ? const Color(0xFF134E39) : const Color(0xFFD0E2D4),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }
}