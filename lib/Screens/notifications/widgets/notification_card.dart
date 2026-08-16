import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final bool isUnread;
  final String priority;
  final VoidCallback onDelete;
  final VoidCallback onMarkAsRead;

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.isUnread,
    required this.priority,
    required this.onDelete,
    required this.onMarkAsRead,
  });

  Color _getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return const Color(0xFF5A7865);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.done_all, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onMarkAsRead();
          return false; // Don't dismiss the card, just trigger action
        } else {
          onDelete();
          return true; // Dismiss the card
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFE4EDE6).withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? const Color(0xFF134E39).withOpacity(0.3) : const Color(0xFFD0E2D4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE4EDE6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF134E39),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF134E39),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          priority,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getPriorityColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF5A7865),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF5A7865),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF134E39),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}