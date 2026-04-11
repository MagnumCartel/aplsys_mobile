import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'supabase_config.dart';
import 'detailnotif.dart';
import 'leavenotif.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class AppNotification {
  final int id;
  final String source; // "leave" or "detail"
  final String title;
  final String message;
  bool isRead;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.source,
    required this.title,
    required this.message,
    required this.isRead,
    required this.timestamp,
  });
}

String formatLeaveMessage(DateTime start, DateTime end, String status) {
  final s = DateFormat("MMM d, yyyy").format(start);
  final e = DateFormat("MMM d, yyyy").format(end);
  return "Your Leave Request from $s to $e has been $status.";
}

String formatDetailMessage(String type, String detailStatus) {
  return "Your Detail Request of $type has been $detailStatus.";
}

class _NotificationPageState extends State<NotificationPage> {
  bool showUnreadOnly = false;
  bool isLoading = true;

  List<AppNotification> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    // 1️⃣ Fetch employeeid using user.id
    final empRes = await SupabaseConfig.client
        .from("employee")
        .select("employeeid")
        .eq("user_id", user.id)
        .single();

    final employeeId = empRes["employeeid"];

    // 2️⃣ Fetch leave notifications (ONLY approval/rejection)
    final leaveRes = await SupabaseConfig.client
        .from("leave")
        .select()
        .eq("employeeid", employeeId)
        .inFilter("status", ["Approved", "Rejected"]); // ← FILTER

    // 3️⃣ Fetch detail request notifications (ONLY approval/rejection)
    final detailRes = await SupabaseConfig.client
        .from("detailrequest")
        .select()
        .eq("employeeid", employeeId)
        .inFilter("detailstatus", ["Approved", "Rejected"]); // ← FILTER

    List<AppNotification> temp = [];

    // Parse Leave
    for (var row in leaveRes) {
      temp.add(
        AppNotification(
          id: row["leaveid"],
          source: "leave",
          title: "APLsys",
          message: formatLeaveMessage(
            DateTime.parse(row["start_date"]),
            DateTime.parse(row["end_date"]),
            row["status"],
          ),
          isRead: row["is_read"] == true,
          timestamp:
              DateTime.tryParse(row["timestamp"] ?? row["start_date"]) ??
              DateTime.now(),
        ),
      );
    }

    // Parse Detail Request
    for (var row in detailRes) {
      temp.add(
        AppNotification(
          id: row["detailrequestid"],
          source: "detail",
          title: "APLsys",
          message: formatDetailMessage(row["detailtype"], row["detailstatus"]),
          isRead: row["is_read"] == true,
          timestamp: DateTime.tryParse(row["timestamp"]) ?? DateTime.now(),
        ),
      );
    }

    temp.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {
      notifications = temp;
      isLoading = false;
    });
  }

  Map<String, List<AppNotification>> groupByMonth(List<AppNotification> list) {
    final map = <String, List<AppNotification>>{};

    for (var n in list) {
      final key = DateFormat("MMMM yyyy").format(n.timestamp);
      map.putIfAbsent(key, () => []);
      map[key]!.add(n);
    }

    return map;
  }

  Future<void> markAllAsRead() async {
    for (var n in notifications) {
      // Mark as read if it's unread
      if (!n.isRead) {
        n.isRead = true; // update UI immediately
        setState(() {}); // refresh UI

        if (n.source == "leave") {
          await SupabaseConfig.client
              .from("leave")
              .update({"is_read": true})
              .eq("leaveid", n.id);
        } else {
          await SupabaseConfig.client
              .from("detailrequest")
              .update({"is_read": true})
              .eq("detailrequestid", n.id);
        }
      }
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All notifications marked as read")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filtered = showUnreadOnly
        ? notifications.where((n) => !n.isRead).toList()
        : notifications;

    final grouped = groupByMonth(filtered);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notification",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: markAllAsRead,
            child: const Text(
              "Mark all as read",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildTab("All", !showUnreadOnly),
                const SizedBox(width: 8),
                _buildTab("Unread", showUnreadOnly),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: grouped.entries.map((entry) {
                  final month = entry.key;
                  final items = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        month,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...items.map(_buildTile),

                      const SizedBox(height: 25),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => showUnreadOnly = label == "Unread"),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF27376E) : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(AppNotification n) {
    return InkWell(
      onTap: () async {
        // 🔥 1. Mark as read immediately
        if (!n.isRead) {
          n.isRead = true;
          setState(() {});

          if (n.source == "leave") {
            await SupabaseConfig.client
                .from("leave")
                .update({"is_read": true})
                .eq("leaveid", n.id);
          } else {
            await SupabaseConfig.client
                .from("detailrequest")
                .update({"is_read": true})
                .eq("detailrequestid", n.id);
          }
        }

        //  2. Continue your navigation
        if (n.source == "leave") {
          final res = await SupabaseConfig.client
              .from("leave")
              .select()
              .eq("leaveid", n.id)
              .single();

          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LeaveNotificationScreen(leaveData: res),
              ),
            );
          }
        } else {
          final res = await SupabaseConfig.client
              .from("detailrequest")
              .select()
              .eq("detailrequestid", n.id)
              .single();

          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailNotificationScreen(detailData: res),
              ),
            );
          }
        }
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFB71C1C),
              child: Icon(Icons.notifications, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: n.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
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
