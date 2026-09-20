import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smart_plant_care/screens/notifications/widgets/notification_card.dart';
import 'package:smart_plant_care/screens/notifications/widgets/notification_filter.dart';
import 'package:smart_plant_care/screens/notifications/widgets/notification_summary.dart';
import 'package:smart_plant_care/screens/notifications/widgets/empty_notification.dart';
import 'package:smart_plant_care/screens/notification_settings/notification_settings_screen.dart';
import 'package:smart_plant_care/services/notification_history_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database =
      FirebaseDatabase.instance;

  String _selectedFilter = 'All';

  // ============================================================
  // FIREBASE NOTIFICATION REFERENCE
  // ============================================================

  DatabaseReference? get _notificationsRef {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _database.ref(
      'Users/${user.uid}/Notifications',
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _goBackToHome() {
    context.go('/home');
  }

  // ============================================================
  // PARSE FIREBASE NOTIFICATIONS
  // ============================================================

  List<Map<String, dynamic>> _parseNotifications(
    DataSnapshot snapshot,
  ) {
    if (!snapshot.exists || snapshot.value is! Map) {
      return [];
    }

    final Map<dynamic, dynamic> rawData =
        Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );

    final List<Map<String, dynamic>> notifications = [];

    for (final MapEntry<dynamic, dynamic> entry
        in rawData.entries) {
      if (entry.value is! Map) {
        continue;
      }

      final Map<dynamic, dynamic> data =
          Map<dynamic, dynamic>.from(
        entry.value as Map,
      );

      final Map<String, dynamic> notification = {
        'id': entry.key.toString(),
        'title':
            data['title']?.toString() ?? 'Notification',
        'message':
            data['message']?.toString() ?? '',
        'category':
            data['category']?.toString() ?? 'General',
        'priority':
            data['priority']?.toString() ?? 'LOW',
        'type':
            data['type']?.toString() ?? '',
        'timestamp':
            _parseTimestamp(data['timestamp']),
        'isRead':
            data['isRead'] == true,
      };

      notifications.add(notification);
    }

    // Newest notification first.
    notifications.sort(
      (a, b) {
        final DateTime? aTime =
            a['timestamp'] as DateTime?;

        final DateTime? bTime =
            b['timestamp'] as DateTime?;

        if (aTime == null && bTime == null) {
          return 0;
        }

        if (aTime == null) {
          return 1;
        }

        if (bTime == null) {
          return -1;
        }

        return bTime.compareTo(aTime);
      },
    );

    return notifications;
  }

  // ============================================================
  // TIMESTAMP PARSER
  // ============================================================

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return _epochToDateTime(value);
    }

    if (value is double) {
      return _epochToDateTime(
        value.toInt(),
      );
    }

    final num? numeric =
        num.tryParse(value.toString());

    if (numeric != null) {
      return _epochToDateTime(
        numeric.toInt(),
      );
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  DateTime _epochToDateTime(int value) {
    // Seconds-based Unix timestamp.
    if (value < 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(
        value * 1000,
      );
    }

    // Milliseconds-based Unix timestamp.
    return DateTime.fromMillisecondsSinceEpoch(
      value,
    );
  }

  // ============================================================
  // TIME FORMATTER
  // ============================================================

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) {
      return 'Unknown time';
    }

    final DateTime now = DateTime.now();

    final Duration difference =
        now.difference(timestamp);

    if (difference.isNegative) {
      return 'Just now';
    }

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${timestamp.day.toString().padLeft(2, '0')}/'
        '${timestamp.month.toString().padLeft(2, '0')}/'
        '${timestamp.year}';
  }

  // ============================================================
  // NOTIFICATION ICON
  // ============================================================

  IconData _notificationIcon(
    Map<String, dynamic> notification,
  ) {
    // Convert nullable Firebase values into
    // guaranteed non-null strings.
    final String type =
        (notification['type']?.toString() ?? '')
            .trim()
            .toLowerCase();

    final String category =
        (notification['category']?.toString() ?? '')
            .trim()
            .toLowerCase();

    final String priority =
        (notification['priority']?.toString() ?? '')
            .trim()
            .toLowerCase();

    // ------------------------------------------------------------
    // Soil / water
    // ------------------------------------------------------------

    if (type.contains('soil') ||
        type.contains('water') ||
        category.contains('soil') ||
        category.contains('sensor')) {
      return Icons.water_drop;
    }

    // ------------------------------------------------------------
    // Irrigation / pump
    // ------------------------------------------------------------

    if (type.contains('irrigation') ||
        type.contains('pump') ||
        type.contains('watering') ||
        category.contains('irrigation')) {
      return Icons.water;
    }

    // ------------------------------------------------------------
    // Temperature
    // ------------------------------------------------------------

    if (type.contains('temperature') ||
        category.contains('temperature')) {
      return Icons.thermostat;
    }

    // ------------------------------------------------------------
    // Humidity
    // ------------------------------------------------------------

    if (type.contains('humidity') ||
        category.contains('humidity')) {
      return Icons.air;
    }

    // ------------------------------------------------------------
    // Light
    // ------------------------------------------------------------

    if (type.contains('light') ||
        category.contains('light')) {
      return Icons.light_mode;
    }

    // ------------------------------------------------------------
    // Device
    // ------------------------------------------------------------

    if (type.contains('device') ||
        category.contains('device') ||
        type.contains('connection')) {
      return Icons.memory;
    }

    // ------------------------------------------------------------
    // Offline / warning / high priority
    // ------------------------------------------------------------

    if (type.contains('offline') ||
        type.contains('warning') ||
        priority == 'high') {
      return Icons.warning_amber_rounded;
    }

    // ------------------------------------------------------------
    // Default
    // ------------------------------------------------------------

    return Icons.notifications_outlined;
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> _filterNotifications(
    List<Map<String, dynamic>> notifications,
  ) {
    if (_selectedFilter == 'All') {
      return notifications;
    }

    return notifications.where(
      (Map<String, dynamic> notification) {
        final String category =
            notification['category']
                ?.toString() ??
            '';

        return category == _selectedFilter;
      },
    ).toList();
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================

  Future<void> _markAsRead(
    String id,
  ) async {
    try {
      await NotificationHistoryService
          .instance
          .markAsRead(id);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update notification.',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // DELETE ONE
  // ============================================================

  Future<void> _deleteNotification(
    String id,
  ) async {
    try {
      await NotificationHistoryService
          .instance
          .deleteNotification(id);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete notification.',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> _markAllAsRead() async {
    try {
      await NotificationHistoryService
          .instance
          .markAllAsRead();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All notifications marked as read',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
          backgroundColor:
              const Color(0xFF134E39),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update notifications.',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final DatabaseReference? notificationsRef =
        _notificationsRef;

    // ----------------------------------------------------------
    // USER NOT LOGGED IN
    // ----------------------------------------------------------

    if (notificationsRef == null) {
      return Scaffold(
        backgroundColor:
            const Color(0xFFF4F7F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF134E39),
            ),
            onPressed: _goBackToHome,
          ),
          title: Text(
            'Notifications',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF134E39),
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Please sign in to view notifications.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // MAIN SCREEN
    // ----------------------------------------------------------

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7F5),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF134E39),
          ),
          tooltip: 'Back to Home',
          onPressed: _goBackToHome,
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
            icon: const Icon(
              Icons.done_all,
              color: Color(0xFF134E39),
            ),
            tooltip: 'Mark All Read',
            onPressed: _markAllAsRead,
          ),
        ],
      ),

      // ========================================================
      // NOTIFICATION STREAM
      // ========================================================

      body: StreamBuilder<DatabaseEvent>(
        stream: notificationsRef.onValue,

        builder: (
          BuildContext context,
          AsyncSnapshot<DatabaseEvent> snapshot,
        ) {
          // ----------------------------------------------------
          // ERROR
          // ----------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load notifications.',
                style: GoogleFonts.poppins(
                  color: Colors.red.shade700,
                ),
              ),
            );
          }

          // ----------------------------------------------------
          // LOADING
          // ----------------------------------------------------

          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF134E39),
              ),
            );
          }

          // ----------------------------------------------------
          // PARSE DATA
          // ----------------------------------------------------

          final List<Map<String, dynamic>>
              notifications =
              snapshot.hasData
                  ? _parseNotifications(
                      snapshot.data!.snapshot,
                    )
                  : <Map<String, dynamic>>[];

          // ----------------------------------------------------
          // COUNTS
          // ----------------------------------------------------

          final int totalCount =
              notifications.length;

          final int unreadCount =
              notifications.where(
            (Map<String, dynamic> notification) {
              return notification['isRead'] != true;
            },
          ).length;

          final int alertCount =
              notifications.where(
            (Map<String, dynamic> notification) {
              final String priority =
                  notification['priority']
                          ?.toString()
                          .toLowerCase() ??
                      '';

              return priority == 'high';
            },
          ).length;

          final int completedCount =
              notifications.where(
            (Map<String, dynamic> notification) {
              return notification['isRead'] == true;
            },
          ).length;

          // ----------------------------------------------------
          // FILTER
          // ----------------------------------------------------

          final List<Map<String, dynamic>>
              displayedList =
              _filterNotifications(
            notifications,
          );

          // ----------------------------------------------------
          // CONTENT
          // ----------------------------------------------------

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                NotificationSummary(
                  totalCount: totalCount,
                  unreadCount: unreadCount,
                  alertCount: alertCount,
                  completedCount:
                      completedCount,
                ),

                const SizedBox(height: 20),

                NotificationFilter(
                  selectedFilter:
                      _selectedFilter,
                  onFilterChanged:
                      (String filter) {
                    setState(() {
                      _selectedFilter =
                          filter;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // EMPTY STATE
                // ------------------------------------------------

                if (displayedList.isEmpty)
                  const EmptyNotification()

                // ------------------------------------------------
                // NOTIFICATION LIST
                // ------------------------------------------------

                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount:
                        displayedList.length,
                    itemBuilder:
                        (
                      BuildContext context,
                      int index,
                    ) {
                      final Map<String, dynamic>
                          item =
                          displayedList[index];

                      return NotificationCard(
                        title: item['title']
                            ?.toString() ??
                            'Notification',

                        message: item['message']
                            ?.toString() ??
                            '',

                        time: _formatTime(
                          item['timestamp']
                              as DateTime?,
                        ),

                        icon:
                            _notificationIcon(
                          item,
                        ),

                        isUnread:
                            item['isRead'] != true,

                        priority:
                            item['priority']
                                    ?.toString() ??
                                'LOW',

                        onDelete: () {
                          _deleteNotification(
                            item['id']
                                ?.toString() ??
                                '',
                          );
                        },

                        onMarkAsRead: () {
                          _markAsRead(
                            item['id']
                                ?.toString() ??
                                '',
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),

      // ========================================================
      // SETTINGS
      // ========================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const NotificationSettingsScreen(),
            ),
          );
        },

        backgroundColor:
            const Color(0xFF134E39),

        icon: const Icon(
          Icons.settings_outlined,
          color: Colors.white,
        ),

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