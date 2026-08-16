import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_plant_care/screens/notifications/widgets/notification_card.dart';
import 'package:smart_plant_care/screens/notifications/widgets/notification_filter.dart';
import 'package:smart_plant_care/screens/notifications/widgets/notification_summary.dart';
import 'package:smart_plant_care/screens/notifications/widgets/empty_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  // Dummy notification list data
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Low Soil Moisture',
      'message': 'Soil moisture has dropped below 30%. Consider watering the plant.',
      'time': '10 mins ago',
      'icon': Icons.water_drop,
      'isUnread': true,
      'priority': 'High',
      'category': 'Sensors',
    },
    {
      'title': 'Automatic Irrigation Started',
      'message': 'Scheduled watering cycle initiated successfully for Sector A.',
      'time': '45 mins ago',
      'icon': Icons.sync,
      'isUnread': true,
      'priority': 'Medium',
      'category': 'Irrigation',
    },
    {
      'title': 'ESP32 Connected Successfully',
      'message': 'Device re-established stable local Wi-Fi connection.',
      'time': '2 hours ago',
      'icon': Icons.wifi,
      'isUnread': false,
      'priority': 'Low',
      'category': 'Devices',
    },
    {
      'title': 'Temperature Returned to Normal',
      'message': 'Greenhouse temperature stabilized at 24°C.',
      'time': '3 hours ago',
      'icon': Icons.thermostat,
      'isUnread': false,
      'priority': 'Low',
      'category': 'Sensors',
    },
    {
      'title': 'Device Offline Warning',
      'message': 'ESP32 failed to ping server for over 10 minutes.',
      'time': '5 hours ago',
      'icon': Icons.warning_amber_rounded,
      'isUnread': false,
      'priority': 'High',
      'category': 'System',
    },
    {
      'title': 'Water Tank Low',
      'message': 'Reservoir water level is under 15%. Refill soon.',
      'time': 'Yesterday',
      'icon': Icons.water_outlined,
      'isUnread': false,
      'priority': 'Medium',
      'category': 'Irrigation',
    },
    {
      'title': 'Firmware Update Available',
      'message': 'New v1.0.5 ESP32 patch available for installation.',
      'time': '2 days ago',
      'icon': Icons.system_update,
      'isUnread': false,
      'priority': 'Low',
      'category': 'System',
    },
    {
      'title': 'Humidity Updated',
      'message': 'Logged 60% relative humidity reading.',
      'time': '2 days ago',
      'icon': Icons.air,
      'isUnread': false,
      'priority': 'Low',
      'category': 'Sensors',
    },
  ];

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'All') {
      return _notifications;
    }
    return _notifications.where((n) => n['category'] == _selectedFilter).toList();
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['isUnread'] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All notifications marked as read',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF134E39),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _notifications.length;
    final unreadCount = _notifications.where((n) => n['isUnread'] == true).length;
    final alertCount = _notifications.where((n) => n['priority'] == 'High').length;
    final completedCount = _notifications.where((n) => n['isUnread'] == false).length;

    final displayedList = _filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF134E39)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E39),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF134E39)),
            tooltip: 'Mark All Read',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Summary Cards ---
            NotificationSummary(
              totalCount: totalCount,
              unreadCount: unreadCount,
              alertCount: alertCount,
              completedCount: completedCount,
            ),
            const SizedBox(height: 20),

            // --- Filter Chips ---
            NotificationFilter(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
            const SizedBox(height: 20),

            // --- Notification List or Empty State ---
            displayedList.isEmpty
                ? const EmptyNotification()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedList.length,
                    itemBuilder: (context, index) {
                      final item = displayedList[index];
                      // Find real index in original list for state updates
                      final originalIndex = _notifications.indexOf(item);

                      return NotificationCard(
                        title: item['title'],
                        message: item['message'],
                        time: item['time'],
                        icon: item['icon'],
                        isUnread: item['isUnread'],
                        priority: item['priority'],
                        onDelete: () {
                          setState(() {
                            _notifications.removeAt(originalIndex);
                          });
                        },
                        onMarkAsRead: () {
                          setState(() {
                            _notifications[originalIndex]['isUnread'] = false;
                          });
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Notification Settings (Demo)',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF134E39),
            ),
          );
        },
        backgroundColor: const Color(0xFF134E39),
        icon: const Icon(Icons.settings_outlined, color: Colors.white),
        label: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}