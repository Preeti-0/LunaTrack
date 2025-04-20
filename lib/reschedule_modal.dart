import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RescheduleModal extends StatefulWidget {
  final int appointmentId;
  final DateTime currentDate;
  final String currentTime;

  const RescheduleModal({
    super.key,
    required this.appointmentId,
    required this.currentDate,
    required this.currentTime,
  });

  @override
  State<RescheduleModal> createState() => _RescheduleModalState();
}

class _RescheduleModalState extends State<RescheduleModal> {
  DateTime? _newDate;
  String? _newTime;
  bool _loading = false;

  final List<String> availableTimeSlots = [
    "10:00",
    "11:00",
    "12:00",
    "14:00",
    "15:00",
    "16:00",
    "17:00",
  ];

  Future<void> _submitReschedule() async {
    if (_newDate == null || _newTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.patch(
      Uri.parse(
        'http://192.168.1.70:8000/api/reschedule-appointment/${widget.appointmentId}/',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "appointment_date": DateFormat('yyyy-MM-dd').format(_newDate!),
        "appointment_time": _newTime!,
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment rescheduled successfully')),
      );
    } else {
      final msg = jsonDecode(response.body)['error'] ?? 'Failed to reschedule';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reschedule Appointment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: widget.currentDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) setState(() => _newDate = picked);
            },
            child: Text(
              _newDate == null
                  ? "Pick Date"
                  : DateFormat('yyyy-MM-dd').format(_newDate!),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children:
                availableTimeSlots.map((time) {
                  final selected = _newTime == time;
                  return ChoiceChip(
                    label: Text(time),
                    selected: selected,
                    onSelected: (_) => setState(() => _newTime = time),
                  );
                }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submitReschedule,
          child:
              _loading
                  ? const CircularProgressIndicator()
                  : const Text('Reschedule'),
        ),
      ],
    );
  }
}
