import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationFilter extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const NotificationFilter({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final List<String> _filters = const [
    'All',
    'System',
    'Irrigation',
    'Sensors',
    'Devices',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 8, right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onFilterChanged(filter);
                }
              },
              selectedColor: const Color(0xFF134E39),
              backgroundColor: Colors.white,
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF134E39),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : const Color(0xFFD0E2D4),
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}