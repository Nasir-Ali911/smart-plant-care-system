import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceStatusCard extends StatelessWidget {
  const DeviceStatusCard({super.key});

  // Convert Wi-Fi RSSI (-30 to -90 dBm) into an approximate percentage.
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
            status: 'Connection Error',
            rssiText: '--',
            signalPercentage: 0,
            isConnected: false,
          );
        }

        // ----------------------------------------------------------
        // Firebase Data
        // ----------------------------------------------------------

        String status = 'Offline';
        int wifiRSSI = 0;

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value;

          if (data is Map) {
            status = data['Status']?.toString() ?? 'Offline';

            final rssiValue = data['WiFiRSSI'];

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
    required String status,
    required String rssiText,
    required int signalPercentage,
    required bool isConnected,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Expanded(
                child: Row(
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
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF134E39),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ----------------------------------------------------
              // Connection Status
              // ----------------------------------------------------

              Container(
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
                  children: [

                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isConnected
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isConnected
                            ? const Color(0xFF134E39)
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // --------------------------------------------------------
          // Divider
          // --------------------------------------------------------

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(
              color: Color(0xFFF4F7F5),
              height: 1,
            ),
          ),

          // --------------------------------------------------------
          // Device Details
          // --------------------------------------------------------

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              const _StatusDetailItem(
                label: 'Connection',
                value: 'Wi-Fi',
              ),

              _StatusDetailItem(
                label: 'Signal Strength',
                value: '$signalPercentage%',
              ),

              _StatusDetailItem(
                label: 'RSSI',
                value: rssiText,
              ),
            ],
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

        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF5A7865),
          ),
        ),

        const SizedBox(height: 2),

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