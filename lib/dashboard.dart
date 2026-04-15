import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'supabase_config.dart';
import 'leaverequest.dart';
import 'editleave.dart';
import 'detailoverview.dart';

class DashboardPage extends StatefulWidget {
  final Future<void> Function()? onRefreshMain;

  const DashboardPage({super.key, this.onRefreshMain});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int leaveCredits = 0;

  // Tabs
  int mainTab = 0; // 0 = Leave Request, 1 = Detail Request
  int leaveSubTab = 0;
  int detailSubTab = 0;

  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> leaveRequests = [];
  List<Map<String, dynamic>> detailRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    setState(() => isLoading = true);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('No logged-in user found');

      final employee = await SupabaseConfig.client
          .from('employee')
          .select('employeeid, leavecredit')
          .eq('user_id', user.id)
          .maybeSingle();

      if (employee == null) throw Exception('Employee not found');

      final employeeId = employee['employeeid'];

      final rawCredit = employee['leavecredit'];
      final leaveCredit = rawCredit is num
          ? rawCredit
          : double.tryParse(rawCredit?.toString() ?? '0') ?? 0;

      final leaveResponse = await SupabaseConfig.client
          .from('leave')
          .select()
          .eq('employeeid', employeeId);

      final detailResponse = await SupabaseConfig.client
          .from('detailrequest')
          .select()
          .eq('employeeid', employeeId);

      final leaves = List<Map<String, dynamic>>.from(leaveResponse);
      final details = List<Map<String, dynamic>>.from(detailResponse);

      leaves.sort((a, b) {
        DateTime? parseDate(dynamic d) {
          if (d == null) return null;
          return DateTime.tryParse(d.toString().replaceAll('/', '-'));
        }

        final aStart = parseDate(a['start_date']);
        final bStart = parseDate(b['start_date']);

        if (aStart != null && bStart != null) {
          final cmp = bStart.compareTo(aStart);
          if (cmp != 0) return cmp;
        } else if (aStart == null) {
          return 1;
        } else if (bStart == null) {
          return -1;
        }

        final aEnd = parseDate(a['end_date']);
        final bEnd = parseDate(b['end_date']);

        if (aEnd != null && bEnd != null) {
          return bEnd.compareTo(aEnd);
        } else if (aEnd == null) {
          return 1;
        } else if (bEnd == null) {
          return -1;
        }

        return 0;
      });

      details.sort((a, b) {
        final aDate = DateTime.tryParse(a['timestamp']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['timestamp']?.toString() ?? '');

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });

      setState(() {
        leaveRequests = leaves;
        detailRequests = details;
        leaveCredits = leaveCredit.toInt();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await fetchRequests();

    if (widget.onRefreshMain != null) {
      await widget.onRefreshMain!();
    }
  }

  // Filtering
  List<Map<String, dynamic>> get filteredLeaves {
    switch (leaveSubTab) {
      case 1:
        return leaveRequests.where((r) => r["status"] == "Pending").toList();
      case 2:
        return leaveRequests.where((r) => r["status"] == "Approved").toList();
      case 3:
        return leaveRequests.where((r) => r["status"] == "Rejected").toList();
      case 4:
        return leaveRequests.where((r) => r["status"] == "Cancelled").toList();
      default:
        return leaveRequests;
    }
  }

  List<Map<String, dynamic>> get filteredDetails {
    switch (detailSubTab) {
      case 1:
        return detailRequests
            .where((r) => r["detailstatus"] == "Pending")
            .toList();
      case 2:
        return detailRequests
            .where((r) => r["detailstatus"] == "Approved")
            .toList();
      case 3:
        return detailRequests
            .where((r) => r["detailstatus"] == "Rejected")
            .toList();
      case 4:
        return detailRequests
            .where((r) => r["detailstatus"] == "Cancelled")
            .toList();
      default:
        return detailRequests;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Leave",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaveRequestForm(),
                ),
              );
              fetchRequests();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.timer,
                  color: Color.fromRGBO(39, 55, 110, 1.0),
                ),
                title: const Text("Leave Credit"),
                subtitle: const Text("Remaining"),
                trailing: Text(
                  "$leaveCredits",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(161, 35, 35, 1.0),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            _buildMainTabs(),
            const SizedBox(height: 8),
            _buildSubTabs(),
            const SizedBox(height: 16),

            mainTab == 0
                ? _buildLeaveRequestsList()
                : _buildDetailRequestsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTab("Leave Request", 0, mainTab, (i) => mainTab = i),
          _buildTab("Detail Request", 1, mainTab, (i) => mainTab = i),
        ],
      ),
    );
  }

  Widget _buildSubTabs() {
    final tabs = ["All", "Pending", "Approved", "Rejected", "Cancelled"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (i) {
            if (mainTab == 0) {
              return _buildTab(
                tabs[i],
                i,
                leaveSubTab,
                (val) => leaveSubTab = val,
              );
            } else {
              return _buildTab(
                tabs[i],
                i,
                detailSubTab,
                (val) => detailSubTab = val,
              );
            }
          }),
        ),
      ),
    );
  }

  Widget _buildTab(
    String text,
    int index,
    int currentIndex,
    ValueChanged<int> onTap,
  ) {
    final bool isSelected = currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: TextButton(
        onPressed: () => setState(() => onTap(index)),
        style: TextButton.styleFrom(
          backgroundColor: isSelected
              ? const Color.fromRGBO(39, 55, 110, 1.0)
              : Colors.grey.shade200,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(0, 32), // smaller height
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveRequestsList() {
    final list = filteredLeaves;
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "No leave requests found.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final req = list[index];
        final formatter = DateFormat('MMMM d, yyyy');

        String formatDate(String? d) {
          if (d == null || d.isEmpty) return '';
          final clean = d.replaceAll('/', '-');
          return formatter.format(DateTime.parse(clean));
        }

        final dateText = req["end_date"] != null
            ? "${formatDate(req["start_date"])} - ${formatDate(req["end_date"])}"
            : formatDate(req["start_date"]);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(dateText),
            subtitle: Text(req["type"] ?? ""),
            trailing: Container(
              constraints: const BoxConstraints(minWidth: 90),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(req["status"]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                textAlign: TextAlign.center,
                req["status"],
                style: TextStyle(
                  color: _getStatusTextColor(req["status"]),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditLeaveScreen(leaveData: req),
                ),
              );
              fetchRequests();
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRequestsList() {
    final list = filteredDetails;
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "No detail requests found.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final req = list[index];
        final formatter = DateFormat('MMMM d, yyyy');

        String formatDate(String? d) {
          if (d == null || d.isEmpty) return '';
          final clean = d.replaceAll('/', '-');
          try {
            return formatter.format(DateTime.parse(clean));
          } catch (_) {
            return '';
          }
        }

        final dateText = formatDate(req["timestamp"]?.toString());
        final status = req["detailstatus"]?.toString() ?? "Unknown";

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(dateText.isNotEmpty ? dateText : "No date"),
            subtitle: Text(req["detailtype"]?.toString() ?? "Unknown"),
            trailing: Container(
              constraints: const BoxConstraints(minWidth: 90),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _getStatusTextColor(status),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailOverviewScreen(detailData: req),
                ),
              );
              fetchRequests();
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Approved":
        return const Color.fromRGBO(39, 55, 110, 1.0);
      case "Rejected":
      case "Cancelled":
        return const Color.fromRGBO(161, 35, 35, 1.0);
      case "Pending":
        return const Color.fromRGBO(210, 210, 210, 1.0);
      default:
        return const Color.fromRGBO(240, 240, 240, 1.0);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.white;
      default:
        return Colors.white;
    }
  }
}
