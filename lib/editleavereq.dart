import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'supabase_config.dart';

class EditLeaveRequestForm extends StatefulWidget {
  final Map<String, dynamic> existingData;

  const EditLeaveRequestForm({super.key, required this.existingData});

  @override
  State<EditLeaveRequestForm> createState() => _EditLeaveRequestFormState();
}

class _EditLeaveRequestFormState extends State<EditLeaveRequestForm> {
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _creditLeave = false;
  bool _isSelectingStart = true;
  bool _isFormFilled = false;
  DateTime _calendarFocusedDay = DateTime.now();
  String? _otherType;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _otherTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _selectedType = widget.existingData['type'];
    _startDate = DateTime.parse(widget.existingData['start_date']);
    _endDate = DateTime.parse(widget.existingData['end_date']);
    _reasonController.text = widget.existingData['reason'] ?? '';
    _creditLeave = widget.existingData['is_paid'] ?? false;
    _calendarFocusedDay = _startDate ?? DateTime.now();
    _otherType = widget.existingData['if_other'];
    if (_selectedType == 'Other') {
      _otherTypeController.text = _otherType ?? '';
    }

    _fromController.text = DateFormat('yyyy-MM-dd').format(_startDate!);
    _toController.text = DateFormat('yyyy-MM-dd').format(_endDate!);

    _reasonController.addListener(_checkForm);
    _checkForm();
  }

  void _checkForm() {
    setState(() {
      _isFormFilled =
          _selectedType != null &&
          _startDate != null &&
          _endDate != null &&
          _reasonController.text.isNotEmpty;
    });
  }

  void _handleDateSelection(DateTime selectedDate) {
    setState(() {
      if (_isSelectingStart) {
        _startDate = selectedDate;
        _fromController.text = _dateFormat.format(selectedDate);
        _endDate = null;
        _toController.clear();
        _isSelectingStart = false;
      } else {
        if (_startDate != null && selectedDate.isBefore(_startDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("End date cannot be before start date"),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _endDate = selectedDate;
        _toController.text = _dateFormat.format(selectedDate);
        _isSelectingStart = true;
      }
      _checkForm();
    });
  }

  Future<void> _submitForm() async {
    if (!_isFormFilled) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Edit?"),
        content: Text(
          "Type: $_selectedType\n"
          "From: ${_dateFormat.format(_startDate!)}\n"
          "To: ${_dateFormat.format(_endDate!)}\n"
          "Reason: ${_reasonController.text}\n"
          "Credit Leave: ${_creditLeave ? 'Yes' : 'No'}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color.fromRGBO(39, 55, 110, 1.0)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(39, 55, 110, 1.0),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final leaveId = widget.existingData['leaveid'];
      await SupabaseConfig.client
          .from('leave')
          .update({
            'type': _selectedType,
            'start_date': _dateFormat.format(_startDate!),
            'end_date': _dateFormat.format(_endDate!),
            'reason': _reasonController.text,
            'is_paid': _creditLeave,
            'if_other': _selectedType == 'Other'
                ? _otherTypeController.text
                : null,
          })
          .eq('leaveid', leaveId);

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Leave Updated"),
            content: const Text(
              "Your leave request has been updated successfully.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
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
      debugPrint("❌ Error updating leave: $error");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating leave: $error")));
    }
  }

  Widget _buildCalendar() {
    final today = DateTime.now();
    final firstAllowedDay = DateTime(today.year, today.month, today.day);

    final focusedDay = _isSelectingStart
        ? (_startDate ?? today)
        : (_endDate ?? _startDate ?? today);

    return TableCalendar(
      firstDay: DateTime(2025, 1, 1),
      lastDay: DateTime(2100, 12, 31),
      focusedDay: _calendarFocusedDay,
      selectedDayPredicate: (day) => (day == _startDate) || (day == _endDate),
      rangeStartDay: _startDate,
      rangeEndDay: _endDate,
      calendarFormat: CalendarFormat.month,

      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),

      calendarBuilders: CalendarBuilders(
        headerTitleBuilder: (context, date) {
          return InkWell(
            onTap: () async {
              final newDate = await showMonthPicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2025),
                lastDate: DateTime(2100),
                monthPickerDialogSettings: const MonthPickerDialogSettings(
                  headerSettings: PickerHeaderSettings(
                    headerBackgroundColor: Color.fromRGBO(39, 55, 110, 1.0),
                  ),
                  dialogSettings: PickerDialogSettings(
                    dialogBackgroundColor: Colors.white,
                  ),
                  dateButtonsSettings: PickerDateButtonsSettings(
                    selectedMonthBackgroundColor: Color.fromRGBO(
                      224,
                      224,
                      224,
                      1.0,
                    ),
                    unselectedMonthsTextColor: Colors.black,
                    unselectedYearsTextColor: Colors.black,
                    selectedMonthTextColor: Colors.black,
                    selectedYearTextColor: Colors.black,
                    currentMonthTextColor: Colors.black,
                    currentYearTextColor: Colors.black,
                  ),
                  actionBarSettings: PickerActionBarSettings(
                    confirmWidget: Text(
                      'Confirm',
                      style: TextStyle(color: Color.fromRGBO(39, 55, 110, 1.0)),
                    ),
                    cancelWidget: Text(
                      'Cancel',
                      style: TextStyle(color: Color.fromRGBO(39, 55, 110, 1.0)),
                    ),
                  ),
                ),
              );

              if (newDate != null) {
                setState(() {
                  _calendarFocusedDay = DateTime(
                    newDate.year,
                    newDate.month,
                    1,
                  );
                });
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat.yMMMM().format(date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          );
        },
      ),

      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Colors.white70),
        weekendStyle: TextStyle(color: Colors.white70),
      ),

      calendarStyle: CalendarStyle(
        isTodayHighlighted: false,
        defaultTextStyle: const TextStyle(color: Colors.white),
        weekendTextStyle: const TextStyle(color: Colors.white),
        outsideTextStyle: const TextStyle(color: Colors.white38),
        disabledTextStyle: const TextStyle(color: Colors.white38),
        selectedDecoration: const BoxDecoration(
          color: Color.fromRGBO(224, 224, 224, 1.0),
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(color: Colors.black),
        rangeHighlightColor: const Color.fromRGBO(224, 224, 224, 1.0),
        rangeStartDecoration: const BoxDecoration(
          color: Color.fromRGBO(224, 224, 224, 1.0),
          shape: BoxShape.circle,
        ),
        rangeEndDecoration: const BoxDecoration(
          color: Color.fromRGBO(224, 224, 224, 1.0),
          shape: BoxShape.circle,
        ),
      ),

      enabledDayPredicate: (day) => !day.isBefore(firstAllowedDay),

      onDaySelected: (selectedDay, focusedDay) {
        if (selectedDay.isBefore(firstAllowedDay)) return;
        _handleDateSelection(selectedDay);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Leave",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Type",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                hint: const Text("Type of Leave"),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items:
                    [
                          "Sick",
                          "Vacation",
                          "Public Holiday",
                          "Bereavement",
                          "Parental Leave",
                          "Maternity Leave",
                          "Emergency",
                          "Other",
                        ]
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _checkForm();
                  });
                },
              ),
              const SizedBox(height: 20),

              if (_selectedType == "Other") ...[
                TextField(
                  controller: _otherTypeController,
                  onChanged: (val) {
                    _otherType = val;
                    _checkForm();
                  },
                  decoration: const InputDecoration(
                    labelText: "Other:",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSelectingStart = true),
                      child: TextField(
                        controller: _fromController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: "From",

                          labelStyle: TextStyle(
                            color: _isSelectingStart
                                ? const Color.fromRGBO(39, 55, 110, 1.0)
                                : theme.textTheme.bodyMedium!.color,
                          ),
                          border: const OutlineInputBorder(),
                          hintText: "Select start date",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSelectingStart = false),
                      child: TextField(
                        controller: _toController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: "To",
                          labelStyle: TextStyle(
                            color: !_isSelectingStart
                                ? const Color.fromRGBO(39, 55, 110, 1.0)
                                : theme.textTheme.bodyMedium!.color,
                          ),
                          border: const OutlineInputBorder(),
                          hintText: "Select end date",
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(39, 55, 110, 1.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: _buildCalendar(),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Reason",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter reason for leave",
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Checkbox(
                    value: _creditLeave,
                    onChanged: (val) =>
                        setState(() => _creditLeave = val ?? false),
                  ),
                  const Text("Paid Leave", style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 30),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormFilled
                        ? const Color.fromRGBO(39, 55, 110, 1.0)
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                  ),
                  onPressed: _isFormFilled ? _submitForm : null,
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
