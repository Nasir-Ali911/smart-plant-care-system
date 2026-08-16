import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationSummary extends StatelessWidget {
  final int totalCount;
  final int unreadCount;
  final int alertCount;
  final int completedCount;

  const NotificationSummary({
    super.key,
    required this.totalCount,
    required this.unreadCount,
    required this.alertCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(label: 'All', count: totalCount.toString(), color: const Color(0xFF134E39))),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(label: 'Unread', count: unreadCount.toString(), color: Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(label: 'Alerts', count: alertCount.toString(), color: Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(label: 'Done', count: completedCount.toString(), color: Colors.green)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0E2D4)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5A7865),
            ),
          ),
        ],
      ),
    );
  }
}