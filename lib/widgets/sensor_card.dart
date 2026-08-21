import 'package:flutter/material.dart';

import 'package:smart_plant_care/constants/app_colors.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String unit;
  final String? status;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.unit = '',
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // TOP ROW
          // ======================================================

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),

              const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ======================================================
          // TITLE
          // ======================================================

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 5),

          // ======================================================
          // VALUE + STATUS
          // ======================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --------------------------------------------------
              // VALUE
              // --------------------------------------------------

              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
              ),

              // --------------------------------------------------
              // UNIT
              // --------------------------------------------------

              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),

                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],

              // --------------------------------------------------
              // STATUS BADGE
              // --------------------------------------------------

              if (status != null && status!.isNotEmpty) ...[
                const SizedBox(width: 8),

                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusBackgroundColor(status!),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusTextColor(status!),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BACKGROUND COLOR
  // ============================================================

  Color _getStatusBackgroundColor(String status) {
    final String normalized = status.toLowerCase();

    if (normalized.contains('needs water') ||
        normalized.contains('dry')) {
      return Colors.red.withOpacity(0.10);
    }

    if (normalized.contains('high')) {
      return Colors.orange.withOpacity(0.10);
    }

    if (normalized.contains('low')) {
      return Colors.blue.withOpacity(0.10);
    }

    if (normalized.contains('normal')) {
      return Colors.green.withOpacity(0.10);
    }

    if (normalized.contains('waiting')) {
      return Colors.grey.withOpacity(0.10);
    }

    return AppColors.primary.withOpacity(0.10);
  }

  // ============================================================
  // STATUS TEXT COLOR
  // ============================================================

  Color _getStatusTextColor(String status) {
    final String normalized = status.toLowerCase();

    if (normalized.contains('needs water') ||
        normalized.contains('dry')) {
      return Colors.red.shade700;
    }

    if (normalized.contains('high')) {
      return Colors.orange.shade700;
    }

    if (normalized.contains('low')) {
      return Colors.blue.shade700;
    }

    if (normalized.contains('normal')) {
      return Colors.green.shade700;
    }

    if (normalized.contains('waiting')) {
      return Colors.grey.shade700;
    }

    return AppColors.primary;
  }
}