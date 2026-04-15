import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'detailsrequest.dart';
import 'supabase_config.dart';
import 'image.dart';

String formatTo12Hour(String time24) {
  final parsed = DateFormat('HH:mm:ss').parse(time24);
  return DateFormat('h:mm a').format(parsed);
}

class ProfilePage extends StatefulWidget {
  final VoidCallback? onRefreshMain;

  const ProfilePage({super.key, this.onRefreshMain});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? employeeData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEmployeeData();
  }

  Future<void> fetchEmployeeData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await SupabaseConfig.client
          .from('employee')
          .select('''
            employeeid,
            firstname,
            lastname,
            birthdate,
            age,
            gender,
            marital_status,
            address,
            contact,
            email,
            employeeimage,
            position(positionname),
            department(departmentname),
            sss_number,
            pagibig_number,
            philhealth_number,
            bir_number,
            shiftstart,
            shiftend
          ''')
          .eq('user_id', user.id)
          .single();

      setState(() {
        employeeData = response;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching employee data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await fetchEmployeeData();
    widget.onRefreshMain?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (employeeData == null) {
      return const Scaffold(
        body: Center(child: Text("No employee data found.")),
      );
    }

    final e = employeeData!;
    final positionName = e['position']?['positionname'] ?? 'N/A';
    final departmentName = e['department']?['departmentname'] ?? 'N/A';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _buildImageProvider(
                          e['employeeimage'],
                        ),
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () async {
                            final base64 = await pickImageBase64();
                            if (base64 == null) return;

                            final url = await uploadImageToSupabase(
                              e['employeeid'],
                              base64,
                            );
                            if (url == null) return;

                            await updateEmployeeImage(e['employeeid'], url);
                            await fetchEmployeeData();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${e['firstname']} ${e['lastname']}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text("Employee ID: #${e['employeeid']}"),
                        Text("Position: $positionName"),
                        Text("Department: $departmentName"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SectionCard(
              title: "Personal Information",
              children: [
                _DetailRow(label: "Birthday", value: e['birthdate'] ?? 'N/A'),
                _DetailRow(label: "Age", value: "${e['age'] ?? 'N/A'}"),
                _DetailRow(label: "Gender", value: e['gender'] ?? 'N/A'),
                _DetailRow(
                  label: "Marital Status",
                  value: e['marital_status'] ?? 'N/A',
                ),
                _DetailRow(label: "Address", value: e['address'] ?? 'N/A'),
                _DetailRow(label: "Contact", value: e['contact'] ?? 'N/A'),
                _DetailRow(label: "Email", value: e['email'] ?? 'N/A'),
              ],
            ),

            SectionCard(
              title: "Statutory Information",
              children: [
                _DetailRow(label: "SSS", value: e['sss_number'] ?? 'N/A'),
                _DetailRow(
                  label: "PAG-IBIG",
                  value: e['pagibig_number'] ?? 'N/A',
                ),
                _DetailRow(
                  label: "PhilHealth",
                  value: e['philhealth_number'] ?? 'N/A',
                ),
                _DetailRow(label: "BIR", value: e['bir_number'] ?? 'N/A'),
              ],
            ),

            SectionCard(
              title: "Work Schedule",
              children: [
                _DetailRow(
                  label: "Shift",
                  value: (e['shiftstart'] != null && e['shiftend'] != null)
                      ? "${formatTo12Hour(e['shiftstart'])} - ${formatTo12Hour(e['shiftend'])}"
                      : 'N/A',
                ),
              ],
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(39, 55, 110, 1.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DetailsRequestPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Request change details",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _buildImageProvider(String? url) {
    if (url == null || url.isEmpty) {
      return const AssetImage("assets/Placeholder.jpg");
    }
    return NetworkImage(url);
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
