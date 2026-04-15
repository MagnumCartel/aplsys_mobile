import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'supabase_config.dart';
import 'editleavereq.dart';

class EditLeaveScreen extends StatefulWidget {
  final Map<String, dynamic> leaveData;

  const EditLeaveScreen({super.key, required this.leaveData});

  @override
  State<EditLeaveScreen> createState() => _EditLeaveScreenState();
}

class _EditLeaveScreenState extends State<EditLeaveScreen> {
  late String _selectedType;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _status;
  final TextEditingController _commentController = TextEditingController();
  late String _ifOther;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.leaveData["type"] ?? "";
    _startDate = DateTime.parse(widget.leaveData["start_date"]);
    _endDate = DateTime.parse(widget.leaveData["end_date"]);
    _commentController.text = widget.leaveData["reason"] ?? '';
    _status = widget.leaveData["status"] ?? '';
    _ifOther = widget.leaveData['if_other'] ?? '';
  }

  void _cancelRequest() {
    if (_status != 'Pending') return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this request?'),
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
                    .update({'status': 'Cancelled'})
                    .eq('leaveid', widget.leaveData['leaveid']);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Leave cancelled successfully!'),
                  ),
                );

                Navigator.pop(context, true);
              } catch (e) {
                debugPrint('Error cancelling leave: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error cancelling leave: $e')),
                );
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

  void _navigateToEdit() async {
    if (_status != 'Pending') return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditLeaveRequestForm(existingData: widget.leaveData),
      ),
    );

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, EEE').format(date).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _endDate.difference(_startDate).inDays + 1;

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
                  : _status == 'Rejected' || _status == 'Cancelled'
                  ? const Color.fromRGBO(161, 35, 35, 1.0)
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_status, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TYPE ---
            const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: _selectedType),
              readOnly: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            if (_selectedType == 'Other') ...[
              const Text(
                'Other',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: _ifOther),
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
            ],

            // --- DATE ---
            const Text('From:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(_startDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Column(
                    children: [
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                      Text(
                        '$duration day${duration > 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Text(
                    _formatDate(_endDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- REASON ---
            const Text('Reason', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              readOnly: true,
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),

            // --- BUTTONS ---
            ElevatedButton(
              onPressed: _status == 'Pending' ? _navigateToEdit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _status == 'Pending'
                    ? const Color.fromRGBO(39, 55, 110, 1.0)
                    : Colors.grey.shade400,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Edit', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _status == 'Pending' ? _cancelRequest : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _status == 'Pending'
                    ? const Color.fromRGBO(161, 35, 35, 1.0)
                    : Colors.grey.shade300,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Cancel Request',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
