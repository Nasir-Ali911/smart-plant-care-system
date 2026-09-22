import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final bool isSmallScreen = MediaQuery.of(context).size.width < 360;

    final Color effectiveColor = isActive ? iconColor : Colors.grey;

    final Color effectiveStatusColor = statusColor ?? effectiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive && onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? [
                      Colors.white,
                      effectiveColor.withValues(alpha: 0.04),
                    ]
                  : [
                      Colors.grey.shade100,
                      Colors.grey.shade50,
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? effectiveColor.withValues(alpha: 0.20)
                  : Colors.grey.shade300,
              width: 1.4,
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
                  color: effectiveColor.withValues(alpha: 0.10),
                  blurRadius: 22,
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
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: isSmallScreen ? 38 : 44,
                      height: isSmallScreen ? 38 : 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            effectiveColor.withValues(alpha: 0.16),
                            effectiveColor.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: effectiveColor.withValues(alpha: 0.22),
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
                        height: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  if (trailing != null)
                    trailing!
                  else if (isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          effectiveColor,
                        ),
                      ),
                    )
                  else if (isActive)
                    _buildStatusIndicator(effectiveColor),
                ],
              ),

              SizedBox(height: isSmallScreen ? 10 : 12),

              // --------------------------------------------------
              // VALUE
              // --------------------------------------------------
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.94, end: 1.0)
                          .animate(animation),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Row(
                  key: ValueKey('$value-$isLoading'),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isLoading ? '---' : value,
                          maxLines: 1,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 18 : 22,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? Colors.black87
                                : Colors.grey.shade500,
                            letterSpacing: 0.2,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),

                    if (unit.isNotEmpty && !isLoading) ...[
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          unit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 10 : 12,
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
              if (status != null && status!.isNotEmpty) ...[
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _buildStatusChip(
                    status!,
                    effectiveStatusColor,
                    isSmallScreen,
                  ),
                ),
              ],

              // --------------------------------------------------
              // PROGRESS BAR
              // --------------------------------------------------
              if (isLoading && progressValue != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    tween: Tween(
                      begin: 0,
                      end: progressValue!.clamp(0.0, 1.0),
                    ),
                    builder: (context, animValue, child) {
                      return LinearProgressIndicator(
                        value: animValue,
                        backgroundColor:
                            effectiveColor.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          effectiveColor,
                        ),
                        minHeight: 6,
                      );
                    },
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
  // STATUS INDICATOR — animated breathing dot
  // ============================================================

  Widget _buildStatusIndicator(Color color) {
    return _PulsingDot(color: color);
  }

  // ============================================================
  // STATUS CHIP — animated color transition
  // ============================================================

  Widget _buildStatusChip(
    String status,
    Color color,
    bool isSmallScreen,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
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
          Text(
            status,
            maxLines: 1,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    final String upperStatus = status.toUpperCase();

    if (upperStatus.contains('HIGH') || upperStatus.contains('DRY')) {
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
// PULSING DOT — internal helper
// ================================================================

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final double t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.30 + 0.30 * t),
                blurRadius: 6 + 4 * t,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
        );
      },
    );
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
    final double safeRange = (maxValue - minValue).abs() < 1e-9
        ? 1.0
        : (maxValue - minValue);

    final double percentage =
        ((value - minValue) / safeRange).clamp(0.0, 1.0);

    final bool isWarning = percentage > 0.8 || percentage < 0.2;

    final Color effectiveColor =
        isWarning ? (warningColor ?? Colors.orange) : iconColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                effectiveColor.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: effectiveColor.withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: effectiveColor.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          effectiveColor.withValues(alpha: 0.16),
                          effectiveColor.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: effectiveColor.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: effectiveColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: effectiveColor,
                    ),
                    child: Text('${value.toStringAsFixed(1)}$unit'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: percentage),
                  builder: (context, animValue, child) {
                    return LinearProgressIndicator(
                      value: animValue,
                      backgroundColor:
                          effectiveColor.withValues(alpha: 0.10),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        effectiveColor,
                      ),
                      minHeight: 8,
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$minValue$unit',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(percentage * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        color: effectiveColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$maxValue$unit',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
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
    return Material(
      color: Colors.transparent,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              iconColor.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.15),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    iconColor.withValues(alpha: 0.15),
                    iconColor.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.22),
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            isLoading ? '---' : value,
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                      if (unit.isNotEmpty && !isLoading) ...[
                        const SizedBox(width: 3),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1.5),
                          child: Text(
                            unit,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
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