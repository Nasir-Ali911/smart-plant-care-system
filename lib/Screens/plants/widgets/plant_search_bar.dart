import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlantSearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;

  const PlantSearchBar({
    super.key,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: GoogleFonts.poppins(
        color: const Color(0xFF134E39),
      ),
      decoration: InputDecoration(
        hintText: 'Search plants...',
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFF5A7865),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFF5A7865),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14.0,
        ),
      ),
    );
  }
}