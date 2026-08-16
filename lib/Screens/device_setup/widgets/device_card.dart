import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ESP32 Smart Plant Monitor',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF134E39),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Not Connected',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE4EDE6)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('Connection', 'Wi-Fi'),
              _buildInfoColumn('Signal', '--%'),
              _buildInfoColumn('Battery', 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF5A7865),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E39),
          ),
        ),
      ],
    );
  }
}