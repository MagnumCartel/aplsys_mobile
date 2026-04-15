import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'supabase_config.dart';

class DetailNotificationScreen extends StatefulWidget {
  final Map<String, dynamic> detailData;

  const DetailNotificationScreen({super.key, required this.detailData});

  @override
  State<DetailNotificationScreen> createState() =>
      _DetailNotificationScreenState();
}

class _DetailNotificationScreenState extends State<DetailNotificationScreen> {
  late String _detailType;
  late String _detailstatus;
  late DateTime _timestamp;
  late String _reason;
  late String _newDetail;
  late String _oldDetail;

  @override
  void initState() {
    super.initState();

    _detailType = widget.detailData["detailtype"] ?? "Unknown";
    _detailstatus = widget.detailData["detailstatus"] ?? "Unknown";
    _reason = widget.detailData["reason"] ?? "";
    _newDetail = widget.detailData["newdetail"] ?? "—";
    _oldDetail = widget.detailData["olddetail"] ?? "—";

    try {
      final raw = widget.detailData["timestamp"]?.toString();

      if (raw == null || raw.trim().isEmpty) {
        _timestamp = DateTime.now();
        return;
      }

      String fixed = raw.replaceAll('/', '-').replaceAll(' ', 'T');

      if (RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$').hasMatch(fixed)) {
        fixed += ':00';
      }

      if (!fixed.contains('Z') && !fixed.contains('+')) {
        _timestamp = DateTime.parse(fixed).toUtc().toLocal();
      } else {
        _timestamp = DateTime.parse(fixed).toLocal();
      }
    } catch (e) {
      debugPrint("Timestamp parse error: $e");
      _timestamp = DateTime.now();
    }
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
                    .from('detailrequest')
                    .update({'is_read': true})
                    .eq(
                      'detailrequestid',
                      widget.detailData['detailrequestid'],
                    );

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

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy – hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Detail Request',
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
              color: _detailstatus == 'Approved'
                  ? const Color.fromRGBO(39, 55, 110, 1.0)
                  : _detailstatus == 'Rejected' || _detailstatus == 'Cancelled'
                  ? const Color.fromRGBO(161, 35, 35, 1.0)
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _detailstatus,
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
            Text(
              "Your Detail Request of $_detailType has been $_detailstatus.",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 20),

            const Text(
              'Type of Detail',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBox(_detailType),
            const SizedBox(height: 16),

            const Text(
              'Old Detail',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBox(_oldDetail),
            const SizedBox(height: 16),

            const Text(
              'New Detail',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBox(_newDetail),
            const SizedBox(height: 16),

            const Text(
              'Date Submitted',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBox(_formatDate(_timestamp)),
            const SizedBox(height: 16),

            const Text('Reason', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildBox(_reason),
            const SizedBox(height: 24),

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
      width: double.infinity,
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
        softWrap: false,
      ),
    );
  }
}
