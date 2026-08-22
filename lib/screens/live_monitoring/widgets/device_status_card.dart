import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceStatusCard extends StatelessWidget {
  const DeviceStatusCard({super.key});

  // ==============================================================
  // RSSI TO PERCENTAGE
  // ==============================================================

  int _rssiToPercentage(int rssi) {
    int percentage = 2 * (rssi + 100);

    if (percentage > 100) {
      percentage = 100;
    }

    if (percentage < 0) {
      percentage = 0;
    }

    return percentage;
  }

  // ==============================================================
  // BUILD
  // ==============================================================

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
            context: context,
            status: 'Connecting...',
            rssiText: '--',
            signalPercentage: 0,
            isConnected: false,
          );
        }

        // ----------------------------------------------------------
        // Error
        // ----------------------------------------------------------

        if (snapshot.hasError) {
          return _buildCard(
            context: context,
            status: 'Connection Error',
            rssiText: '--',
            signalPercentage: 0,
            isConnected: false,
          );
        }

        // ----------------------------------------------------------
        // Default values
        // ----------------------------------------------------------

        String status = 'Offline';
        int wifiRSSI = 0;

        // ----------------------------------------------------------
        // Firebase data
        // ----------------------------------------------------------

        if (snapshot.hasData &&
            snapshot.data!.snapshot.value != null) {
          final dynamic data = snapshot.data!.snapshot.value;

          if (data is Map) {
            status = data['Status']?.toString() ?? 'Offline';

            final dynamic rssiValue = data['WiFiRSSI'];

            if (rssiValue is int) {
              wifiRSSI = rssiValue;
            } else if (rssiValue is double) {
              wifiRSSI = rssiValue.toInt();
            } else {
              wifiRSSI = int.tryParse(
                    rssiValue?.toString() ?? '',
                  ) ??
                  0;
            }
          }
        }

        final bool isConnected =
            status.toLowerCase() == 'connected';

        final int signalPercentage =
            _rssiToPercentage(wifiRSSI);

        final String rssiText =
            wifiRSSI == 0 ? '--' : '$wifiRSSI dBm';

        return _buildCard(
          context: context,
          status: isConnected ? 'Connected' : 'Offline',
          rssiText: rssiText,
          signalPercentage: signalPercentage,
          isConnected: isConnected,
        );
      },
    );
  }

  // ==============================================================
  // CARD UI
  // ==============================================================

  Widget _buildCard({
    required BuildContext context,
    required String status,
    required String rssiText,
    required int signalPercentage,
    required bool isConnected,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD0E2D4),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;

          // Use a stacked header on narrow screens.
          final bool isNarrow = width < 360;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // HEADER
              // ----------------------------------------------------

              if (isNarrow)
                _buildNarrowHeader(
                  status: status,
                  isConnected: isConnected,
                )
              else
                _buildWideHeader(
                  status: status,
                  isConnected: isConnected,
                ),

              // ----------------------------------------------------
              // DIVIDER
              // ----------------------------------------------------

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(
                  color: Color(0xFFF4F7F5),
                  height: 1,
                ),
              ),

              // ----------------------------------------------------
              // DEVICE DETAILS
              // ----------------------------------------------------

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StatusDetailItem(
                      label: 'Connection',
                      value: 'Wi-Fi',
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _StatusDetailItem(
                      label: 'Signal Strength',
                      value: '$signalPercentage%',
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _StatusDetailItem(
                      label: 'RSSI',
                      value: rssiText,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ==============================================================
  // WIDE HEADER
  // ==============================================================

  Widget _buildWideHeader({
    required String status,
    required bool isConnected,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.settings_input_antenna_rounded,
          color: Color(0xFF134E39),
          size: 24,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            'ESP8266 Smart Plant Monitor',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF134E39),
            ),
          ),
        ),

        const SizedBox(width: 8),

        _ConnectionBadge(
          status: status,
          isConnected: isConnected,
        ),
      ],
    );
  }

  // ==============================================================
  // NARROW HEADER
  // ==============================================================

  Widget _buildNarrowHeader({
    required String status,
    required bool isConnected,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.settings_input_antenna_rounded,
          color: Color(0xFF134E39),
          size: 24,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESP8266 Smart Plant Monitor',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF134E39),
                ),
              ),

              const SizedBox(height: 8),

              _ConnectionBadge(
                status: status,
                isConnected: isConnected,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// CONNECTION BADGE
// ==================================================================

class _ConnectionBadge extends StatelessWidget {
  final String status;
  final bool isConnected;

  const _ConnectionBadge({
    required this.status,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 130,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isConnected
            ? const Color(0xFFE4EDE6)
            : const Color(0xFFF5E4E4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 6),

          Flexible(
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isConnected
                    ? const Color(0xFF134E39)
                    : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// STATUS DETAIL ITEM
// ==================================================================

class _StatusDetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatusDetailItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 1,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF5A7865),
            ),
          ),
        ),

        const SizedBox(height: 2),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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