import 'package:flutter/material.dart';

import 'package:smart_plant_care/constants/app_colors.dart';
import 'package:smart_plant_care/models/plant_model.dart';

class PlantCard extends StatelessWidget {
  final PlantModel plant;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Your PlantModel uses "status", not "healthStatus".
    final String plantStatus =
        plant.status.trim().isEmpty ? 'Normal' : plant.status;

    final bool isHealthy =
        plantStatus.toLowerCase() == 'healthy' ||
        plantStatus.toLowerCase() == 'normal';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 4,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            // =====================================================
            // PLANT IMAGE
            // =====================================================

            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                height: 70,
                color: AppColors.primary.withOpacity(0.1),
                child: plant.imageUrl.isNotEmpty
                    ? Image.network(
                        plant.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder:
                            (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder:
                            (context, error, stackTrace) {
                          return const Icon(
                            Icons.local_florist,
                            color: AppColors.primary,
                            size: 30,
                          );
                        },
                      )
                    : const Icon(
                        Icons.local_florist,
                        color: AppColors.primary,
                        size: 30,
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // =====================================================
            // PLANT DETAILS
            // =====================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Plant name
                  Text(
                    plant.name.isNotEmpty
                        ? plant.name
                        : 'Unnamed Plant',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Species
                  Text(
                    plant.species.isNotEmpty
                        ? plant.species
                        : 'Unknown species',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // =================================================
                  // STATUS CHIP
                  // =================================================

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isHealthy
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(6),
                      ),
                      child: Text(
                        plantStatus,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isHealthy
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // =====================================================
            // DELETE BUTTON
            // =====================================================

            if (onDelete != null)
              IconButton(
                tooltip: 'Delete Plant',
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.redAccent,
                ),
                onPressed: onDelete,
              ),

            // =====================================================
            // ARROW
            // =====================================================

            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}