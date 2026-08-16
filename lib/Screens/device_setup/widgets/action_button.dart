import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isLoading;

  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.isPrimary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: isPrimary
          ? ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF134E39),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            )
          : OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF134E39)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF134E39),
                ),
              ),
            ),
    );
  }
}