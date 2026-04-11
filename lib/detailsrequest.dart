import 'package:flutter/material.dart';
import 'supabase_config.dart';

class DetailsRequestPage extends StatefulWidget {
  const DetailsRequestPage({super.key});

  @override
  State<DetailsRequestPage> createState() => _DetailsRequestPageState();
}

class _DetailsRequestPageState extends State<DetailsRequestPage> {
  final List<Map<String, dynamic>> _detailRequests = [
    {
      "selectedDetail": null,
      "oldController": TextEditingController(),
      "newController": TextEditingController(),
      "commentController": TextEditingController(),
    },
  ];

  bool _isNextEnabled = false;
  bool _isFormValid = false;
  Map<String, dynamic>? _employeeData;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeData();
  }

  Future<void> _fetchEmployeeData() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception("No user is currently logged in.");

      final employeeResponse = await SupabaseConfig.client
          .from('employee')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (employeeResponse == null) {
        throw Exception("No matching employee found for this user.");
      }

      setState(() {
        _employeeData = employeeResponse;
      });
    } catch (error) {}
  }

  void _updateNextButtonState() {
    setState(() {
      _isNextEnabled = _detailRequests.any(
        (req) =>
            req["selectedDetail"] != null &&
            req["newController"].text.isNotEmpty,
      );
    });
  }

  void _updateAddButtonState() {
    setState(() {
      _isFormValid = _detailRequests.every(
        (req) =>
            req["selectedDetail"] != null &&
            req["newController"].text.isNotEmpty,
      );
    });
  }

  void _addRequest() {
    setState(() {
      _detailRequests.add({
        "selectedDetail": null,
        "oldController": TextEditingController(),
        "newController": TextEditingController(),
        "commentController": TextEditingController(),
      });
      _isNextEnabled = false;
      _isFormValid = false;
    });
  }

  Future<void> _removeRequest(int index) async {
    if (_detailRequests.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("At least one request must remain."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Request"),
        content: const Text("Are you sure you want to delete this field?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color.fromRGBO(39, 55, 110, 1.0)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Color.fromRGBO(161, 35, 35, 1.0)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _detailRequests.removeAt(index);
        _updateNextButtonState();
        _updateAddButtonState();
      });
    }
  }

  Future<void> _showConfirmationDialog() async {
    if (!_isFormValid) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Changes"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _detailRequests.map((req) {
              final detail = req["selectedDetail"] ?? "N/A";
              final oldText = req["oldController"].text;
              final newText = req["newController"].text;
              final comment = req["commentController"].text;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Detail: $detail",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("Old: $oldText"),
                  Text("New: $newText"),
                  if (comment.isNotEmpty) Text("Comment: $comment"),
                  const Divider(),
                ],
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color.fromRGBO(39, 55, 110, 1.0)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(39, 55, 110, 1.0),
            ),
            onPressed: () async {
              Navigator.pop(context, true);
              await _submitRequests();
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRequests() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception("No user is currently logged in.");

      // Get the employee record linked to this user
      final employeeResponse = await SupabaseConfig.client
          .from('employee')
          .select('employeeid')
          .eq('user_id', user.id)
          .maybeSingle();

      if (employeeResponse == null) {
        throw Exception("No matching employee found for this user.");
      }

      final employeeId = employeeResponse['employeeid'];

      for (var req in _detailRequests) {
        // Insert into detailrequest table
        await SupabaseConfig.client.from('detailrequest').insert({
          'employeeid': employeeId,
          'detailtype': req['selectedDetail'],
          'olddetail': req['oldController'].text,
          'newdetail': req['newController'].text,
          'comment': req['commentController'].text.isNotEmpty
              ? req['commentController'].text
              : null,
          'detailstatus': 'Pending',
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Request Submitted"),
            content: const Text(
              "Your change request has been sent successfully.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  "OK",
                  style: TextStyle(color: Color.fromRGBO(39, 55, 110, 1.0)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      print("❌ Error submitting requests: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting request: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (var i = 0; i < _detailRequests.length; i++) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(bottom: 16),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Change Details",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_detailRequests.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Color.fromRGBO(161, 35, 35, 1.0),
                                ),
                                onPressed: () => _removeRequest(i),
                              ),
                          ],
                        ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _detailRequests[i]["selectedDetail"],
                          hint: const Text("Select Detail"),
                          items:
                              const [
                                "Address",
                                "Contact Number",
                                "Email Address",
                                "Marital Status",
                              ].map((d) {
                                return DropdownMenuItem(
                                  value: d,
                                  child: Text(d),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _detailRequests[i]["selectedDetail"] = value;
                              if (_employeeData != null) {
                                switch (value) {
                                  case "Address":
                                    _detailRequests[i]["oldController"].text =
                                        _employeeData!["address"] ?? "";
                                    break;
                                  case "Contact Number":
                                    _detailRequests[i]["oldController"].text =
                                        _employeeData!["contact"] ?? "";
                                    break;
                                  case "Email Address":
                                    _detailRequests[i]["oldController"].text =
                                        _employeeData!["email"] ?? "";
                                    break;
                                  case "Marital Status":
                                    _detailRequests[i]["oldController"].text =
                                        _employeeData!["marital_status"] ?? "";
                                    break;
                                }
                              }
                              _updateNextButtonState();
                              _updateAddButtonState();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _detailRequests[i]["oldController"],
                          decoration: const InputDecoration(
                            labelText: "Old Detail",
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _detailRequests[i]["newController"],
                          decoration: const InputDecoration(
                            labelText: "New Detail",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            _updateNextButtonState();
                            _updateAddButtonState();
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _detailRequests[i]["commentController"],
                          decoration: const InputDecoration(
                            labelText: "Comment (optional)",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 32),
                  color: _isFormValid
                      ? const Color.fromRGBO(39, 55, 110, 1.0)
                      : Colors.grey,
                  onPressed: _isFormValid ? _addRequest : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNextEnabled
                          ? const Color.fromRGBO(39, 55, 110, 1.0)
                          : Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                    ),
                    onPressed: _isNextEnabled ? _showConfirmationDialog : null,
                    child: const Text(
                      "Next",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
