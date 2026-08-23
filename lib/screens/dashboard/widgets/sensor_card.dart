import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_plant_care/constants/app_colors.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String unit;
  final String? status;
  final bool isLoading;
  final bool isActive;
  final VoidCallback? onTap;
  final double? progressValue;
  final Color? statusColor;
  final Widget? trailing;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.unit = '',
    this.status,
    this.isLoading = false,
    this.isActive = true,
    this.onTap,
    this.progressValue,
    this.statusColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen =
        MediaQuery.of(context).size.width < 360;

    final Color effectiveColor =
        isActive ? iconColor : Colors.grey;

    final Color effectiveStatusColor =
        statusColor ?? effectiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(
            isSmallScreen ? 12 : 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? [
                      Colors.white,
                      effectiveColor.withValues(alpha: 0.03),
                    ]
                  : [
                      Colors.grey.shade100,
                      Colors.grey.shade50,
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? effectiveColor.withValues(alpha: 0.2)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
                spreadRadius: 1,
              ),
              if (isActive)
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --------------------------------------------------
              // HEADER
              // --------------------------------------------------
              Row(
                children: [
                  // Icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0.8,
                      end: 1.0,
                    ),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      width: isSmallScreen ? 36 : 42,
                      height: isSmallScreen ? 36 : 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            effectiveColor.withValues(alpha: 0.15),
                            effectiveColor.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              effectiveColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: effectiveColor,
                        size: isSmallScreen ? 20 : 22,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Title
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Trailing / Loading / Status
                  if (trailing != null)
                    trailing!
                  else if (isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          effectiveColor,
                        ),
                      ),
                    )
                  else if (isActive)
                    _buildStatusIndicator(
                      effectiveColor,
                    ),
                ],
              ),

              SizedBox(
                height: isSmallScreen ? 12 : 16,
              ),

              // --------------------------------------------------
              // VALUE
              // --------------------------------------------------
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder:
                    (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  key: ValueKey(
                    '$value-$isLoading',
                  ),
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        isLoading ? '---' : value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize:
                              isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.black87
                              : Colors.grey.shade500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    // Unit
                    if (unit.isNotEmpty && !isLoading) ...[
                      const SizedBox(width: 6),
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 3),
                        child: Text(
                          unit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize:
                                isSmallScreen ? 10 : 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // --------------------------------------------------
              // STATUS CHIP
              // --------------------------------------------------
              if (status != null &&
                  status!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildStatusChip(
                  status!,
                  effectiveStatusColor,
                  isSmallScreen,
                ),
              ],

              // --------------------------------------------------
              // PROGRESS BAR
              // --------------------------------------------------
              if (isLoading &&
                  progressValue != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor:
                        effectiveColor.withValues(
                      alpha: 0.1,
                    ),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      effectiveColor,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS INDICATOR
  // ============================================================

  Widget _buildStatusIndicator(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(
    String status,
    Color color,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: isSmallScreen ? 10 : 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 9 : 11,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  IconData _getStatusIcon(String status) {
    final String upperStatus =
        status.toUpperCase();

    if (upperStatus.contains('HIGH') ||
        upperStatus.contains('DRY')) {
      return Icons.warning_amber_rounded;
    }

    if (upperStatus.contains('LOW')) {
      return Icons.arrow_downward_rounded;
    }

    if (upperStatus.contains('NORMAL') ||
        upperStatus.contains('HEALTHY')) {
      return Icons.check_circle_rounded;
    }

    if (upperStatus.contains('WET')) {
      return Icons.water_drop_rounded;
    }

    if (upperStatus.contains('WAITING')) {
      return Icons.hourglass_empty_rounded;
    }

    return Icons.info_rounded;
  }
}

// ================================================================
// GAUGE SENSOR CARD
// ================================================================

class GaugeSensorCard extends StatelessWidget {
  final String title;
  final double value;
  final double minValue;
  final double maxValue;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final Color? warningColor;
  final VoidCallback? onTap;

  const GaugeSensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.unit,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.warningColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage =
        ((value - minValue) /
                (maxValue - minValue))
            .clamp(0.0, 1.0);

    final Color effectiveColor =
        percentage > 0.8 || percentage < 0.2
            ? (warningColor ?? Colors.orange)
            : iconColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: effectiveColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${value.toStringAsFixed(1)}$unit',
                    style: GoogleFonts.poppins(
                      fontWeight:
                          FontWeight.w700,
                      fontSize: 18,
                      color: effectiveColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor:
                      effectiveColor.withValues(
                    alpha: 0.1,
                  ),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    effectiveColor,
                  ),
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$minValue$unit',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    '$maxValue$unit',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// COMPACT SENSOR CARD
// ================================================================

class CompactSensorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String unit;
  final bool isLoading;

  const CompactSensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.unit = '',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  iconColor.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color:
                        Colors.grey.shade600,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  isLoading ? '---' : value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}