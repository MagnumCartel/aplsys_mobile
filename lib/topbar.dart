import 'package:flutter/material.dart';
import 'login.dart';
import 'profile.dart';
import 'dashboard.dart';
import 'notif.dart';
import 'supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaveApp extends StatefulWidget {
  final String userName;
  const LeaveApp({super.key, required this.userName});

  @override
  State<LeaveApp> createState() => _LeaveAppState();
}

class _LeaveAppState extends State<LeaveApp> {
  int _unreadCount = 0;
  int _selectedIndex = 0;

  Future<void> _fetchUnreadCount() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final empRes = await SupabaseConfig.client
        .from("employee")
        .select("employeeid")
        .eq("user_id", user.id)
        .single();

    final employeeId = empRes["employeeid"];

    final leaveUnread = await SupabaseConfig.client
        .from("leave")
        .select("leaveid")
        .eq("employeeid", employeeId)
        .eq("is_read", false)
        .inFilter("status", ["Approved", "Rejected"]);

    final detailUnread = await SupabaseConfig.client
        .from("detailrequest")
        .select("detailrequestid")
        .eq("employeeid", employeeId)
        .eq("is_read", false)
        .inFilter("detailstatus", ["Approved", "Rejected"]);

    setState(() {
      _unreadCount = leaveUnread.length + detailUnread.length;
    });
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Confirm Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to log out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close dialog using its own context
              Navigator.pop(dialogContext);

              // Sign out
              await SupabaseConfig.client.auth.signOut();

              if (!mounted) return;

              // Navigate using ROOT navigator
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(161, 35, 35, 1.0),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardPage(onRefreshMain: _fetchUnreadCount),
      ProfilePage(onRefreshMain: _fetchUnreadCount),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(39, 55, 110, 1.0),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _confirmLogout,
          color: Colors.white,
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                color: Colors.white,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                  _fetchUnreadCount();
                },
              ),

              if (_unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromRGBO(161, 35, 35, 1.0),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  late final RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();

    _channel = SupabaseConfig.client
        .channel('unread-listener')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'leave',
          callback: (_) => _fetchUnreadCount(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'detailrequest',
          callback: (_) => _fetchUnreadCount(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    SupabaseConfig.client.removeChannel(_channel);
    super.dispose();
  }
}
