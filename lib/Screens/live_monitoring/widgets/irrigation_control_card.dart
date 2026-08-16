import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IrrigationControlCard extends StatefulWidget {
  const IrrigationControlCard({super.key});

  @override
  State<IrrigationControlCard> createState() => _IrrigationControlCardState();
}

class _IrrigationControlCardState extends State<IrrigationControlCard> {
  bool _isAutoMode = true;
  bool _isIrrigating = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0E2D4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    color: Color(0xFF134E39),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Irrigation Control',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF134E39),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isIrrigating ? const Color(0xFFD0E2D4) : const Color(0xFFF4F7F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isIrrigating ? 'ON' : 'OFF',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF134E39),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(color: Color(0xFFF4F7F5), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoItem(label: 'Last Irrigation', value: '2 Hours Ago'),
                  SizedBox(height: 8),
                  _InfoItem(label: 'Next Scheduled', value: '6:00 PM'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        'Auto Mode',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF5A7865),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _isAutoMode,
                        activeColor: const Color(0xFF134E39),
                        onChanged: (value) {
                          setState(() {
                            _isAutoMode = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isIrrigating = !_isIrrigating;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isIrrigating ? 'Manual irrigation started (Demo)' : 'Manual irrigation stopped (Demo)',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF134E39),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              icon: Icon(
                _isIrrigating ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
              ),
              label: Text(
                _isIrrigating ? 'Stop Manual Water' : 'Start Manual Water',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF134E39),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF5A7865),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E39),
          ),
        ),
      ],
    );
  }
}