import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceInfoCard extends StatelessWidget {
  const DeviceInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference deviceRef =
        FirebaseDatabase.instance.ref('SmartPlant/Device');

    return StreamBuilder<DatabaseEvent>(
      stream: deviceRef.onValue,
      builder: (context, snapshot) {
        // ----------------------------------------------------------
        // Loading
        // ----------------------------------------------------------

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCard(
            firmwareVersion: 'Loading...',
            ipAddress: 'Loading...',
            macAddress: 'Loading...',
            uptime: 'Loading...',
          );
        }

        // ----------------------------------------------------------
        // Error
        // ----------------------------------------------------------

        if (snapshot.hasError) {
          return _buildCard(
            firmwareVersion: 'Unavailable',
            ipAddress: 'Unavailable',
            macAddress: 'Unavailable',
            uptime: 'Unavailable',
          );
        }

        // ----------------------------------------------------------
        // Default values
        // ----------------------------------------------------------

        String firmwareVersion = 'Unavailable';
        String ipAddress = 'Unavailable';
        String macAddress = 'Unavailable';
        String uptime = 'Unavailable';

        // ----------------------------------------------------------
        // Read Firebase data
        // ----------------------------------------------------------

        if (snapshot.hasData &&
            snapshot.data!.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value;

          if (data is Map) {
            firmwareVersion =
                data['FirmwareVersion']?.toString() ??
                    'Unavailable';

            ipAddress =
                data['IPAddress']?.toString() ??
                    'Unavailable';

            macAddress =
                data['MACAddress']?.toString() ??
                    'Unavailable';

            // ------------------------------------------------------
            // Convert uptime seconds into readable format
            // ------------------------------------------------------

            final dynamic uptimeValue =
                data['UptimeSeconds'];

            int uptimeSeconds = 0;

            if (uptimeValue is int) {
              uptimeSeconds = uptimeValue;
            } else if (uptimeValue is double) {
              uptimeSeconds = uptimeValue.toInt();
            } else {
              uptimeSeconds = int.tryParse(
                    uptimeValue?.toString() ?? '',
                  ) ??
                  0;
            }

            uptime = _formatUptime(uptimeSeconds);
          }
        }

        return _buildCard(
          firmwareVersion: firmwareVersion,
          ipAddress: ipAddress,
          macAddress: macAddress,
          uptime: uptime,
        );
      },
    );
  }

  // ==============================================================
  // FORMAT UPTIME
  // ==============================================================

  String _formatUptime(int seconds) {
    if (seconds <= 0) {
      return '0 Minutes';
    }

    final int days = seconds ~/ 86400;

    final int hours =
        (seconds % 86400) ~/ 3600;

    final int minutes =
        (seconds % 3600) ~/ 60;

    if (days > 0) {
      return '$days Days, $hours Hours';
    }

    if (hours > 0) {
      return '$hours Hours, $minutes Minutes';
    }

    if (minutes > 0) {
      return '$minutes Minutes';
    }

    return '$seconds Seconds';
  }

  // ==============================================================
  // CARD UI
  // ==============================================================

  Widget _buildCard({
    required String firmwareVersion,
    required String ipAddress,
    required String macAddress,
    required String uptime,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD0E2D4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // --------------------------------------------------------
          // Header
          // --------------------------------------------------------

          Row(
            children: [

              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF134E39),
                size: 20,
              ),

              const SizedBox(width: 8),

              Text(
                'Device Information',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF134E39),
                ),
              ),
            ],
          ),

          // --------------------------------------------------------
          // Divider
          // --------------------------------------------------------

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Divider(
              color: Color(0xFFF4F7F5),
              height: 1,
            ),
          ),

          // --------------------------------------------------------
          // Firmware
          // --------------------------------------------------------

          _InfoRow(
            label: 'Firmware Version',
            value: firmwareVersion,
          ),

          const SizedBox(height: 8),

          // --------------------------------------------------------
          // IP Address
          // --------------------------------------------------------

          _InfoRow(
            label: 'Wi-Fi IP Address',
            value: ipAddress,
          ),

          const SizedBox(height: 8),

          // --------------------------------------------------------
          // MAC Address
          // --------------------------------------------------------

          _InfoRow(
            label: 'MAC Address',
            value: macAddress,
          ),

          const SizedBox(height: 8),

          // --------------------------------------------------------
          // Uptime
          // --------------------------------------------------------

          _InfoRow(
            label: 'Uptime',
            value: uptime,
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// INFORMATION ROW
// ==================================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ----------------------------------------------------------
        // Label
        // ----------------------------------------------------------

        Expanded(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF5A7865),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // ----------------------------------------------------------
        // Value
        // ----------------------------------------------------------

        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF134E39),
            ),
          ),
        ),
      ],
    );
  }
}