import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IrrigationCard extends StatelessWidget {
  const IrrigationCard({super.key});

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.water_drop_outlined, color: Color(0xFF134E39), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Smart Irrigation',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF134E39),
                    ),
                  ),
                ],
              ),
              Switch(
                value: true,
                activeColor: const Color(0xFF134E39),
                onChanged: (val) {},
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('Last Run', '2 hours ago'),
              _buildInfoColumn('Next Scheduled', '6:00 PM'),
              _buildInfoColumn('Water Tank', '75%'),
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
            fontWeight: FontWeight.w600,
            color: const Color(0xFF134E39),
          ),
        ),
      ],
    );
  }
}