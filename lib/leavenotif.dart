import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'supabase_config.dart';

class LeaveNotificationScreen extends StatefulWidget {
  final Map<String, dynamic> leaveData;

  const LeaveNotificationScreen({super.key, required this.leaveData});

  @override
  State<LeaveNotificationScreen> createState() =>
      _LeaveNotificationScreenState();
}

class _LeaveNotificationScreenState extends State<LeaveNotificationScreen> {
  late String _leaveType;
  late String _status;
  late String _reason;
  late bool _isPaid;
  late String _ifOther;
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _timestamp;

  @override
  void initState() {
    super.initState();

    _leaveType = widget.leaveData["type"] ?? "Unknown";
    _status = widget.leaveData["status"] ?? "Unknown";
    _reason = widget.leaveData["reason"] ?? "";
    _isPaid = widget.leaveData["is_paid"] == true;
    _ifOther = widget.leaveData["if_other"] ?? "";

    // Parse dates safely
    try {
      _startDate = DateTime.parse(widget.leaveData["start_date"]);
      _endDate = DateTime.parse(widget.leaveData["end_date"]);
    } catch (_) {
      _startDate = DateTime.now();
      _endDate = DateTime.now();
    }

    try {
      final raw = widget.leaveData["timestamp"]?.toString();
      _timestamp = DateTime.parse(raw!.replaceAll('/', '-'));
    } catch (_) {
      _timestamp = DateTime.now();
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  int _calculateDuration() {
    return _endDate.difference(_startDate).inDays + 1;
  }

  void _deleteNotification() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'No',
              style: TextStyle(color: Color.fromRGBO(39, 55, 110, 1.0)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await SupabaseConfig.client
                    .from('leave')
                    .update({
                      'is_read': true,
                    }) // or delete notif table if exists
                    .eq('leaveid', widget.leaveData['leaveid']);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification deleted successfully!'),
                  ),
                );

                Navigator.pop(context, true);
              } catch (e) {
                debugPrint('Error deleting notification: $e');
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(161, 35, 35, 1.0),
            ),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final durationDays = _calculateDuration();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Leave Request',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _status == 'Approved'
                  ? const Color.fromRGBO(39, 55, 110, 1.0)
                  : _status == 'Rejected'
                  ? const Color.fromRGBO(161, 35, 35, 1.0)
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MESSAGE
            Text(
              "Your Leave Request from ${_formatDate(_startDate)} to ${_formatDate(_endDate)} has been $_status.",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 20),

            // TYPE OF LEAVE
            const Text(
              'Type of Leave',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBox(_leaveType),

            if (_leaveType == "Other") ...[
              const SizedBox(height: 16),
              const Text(
                'Other (Specify)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildBox(_ifOther),
            ],

            const SizedBox(height: 16),

            // START DATE
            const Text(
              'Start Date',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBox(_formatDate(_startDate)),

            const SizedBox(height: 16),

            // END DATE
            const Text(
              'End Date',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBox(_formatDate(_endDate)),

            const SizedBox(height: 16),

            // DURATION
            const Text(
              'Duration',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBox("$durationDays Day${durationDays > 1 ? 's' : ''}"),

            const SizedBox(height: 16),

            // REASON
            const Text('Reason', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: _reason),
              readOnly: true,
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // PAID LEAVE
            const Text(
              'Paid Leave',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBox(_isPaid ? "Yes" : "No"),

            const SizedBox(height: 30),

            // DELETE BUTTON
            ElevatedButton(
              onPressed: _deleteNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(161, 35, 35, 1.0),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Delete Notification',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(String text) {
    return Container(
      width: double.infinity, // ← makes all boxes same width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
        overflow: TextOverflow.visible,
        softWrap: false, // ← prevents wrapping
      ),
    );
  }
}
