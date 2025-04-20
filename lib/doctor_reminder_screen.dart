// 📁 doctor_reminder_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';

class DoctorReminderScreen extends StatefulWidget {
  const DoctorReminderScreen({super.key});

  @override
  State<DoctorReminderScreen> createState() => _DoctorReminderScreenState();
}

class _DoctorReminderScreenState extends State<DoctorReminderScreen> {
  List<dynamic> _reminders = [];
  bool _loading = true;

  final Map<String, String> emojiMap = {
    "log_period": "🩸",
    "next_period_start": "🌸",
    "fertile_window_start": "🌱",
    "ovulation_day": "💡",
    "take_med": "💊",
    "log_symptom": "📋",
    "drink_water": "💧",
    "appointment_booked": "🩺",
    "appointment_reminder": "⏰",
    "new_appointment": "👨‍⚕️",
    "reschedule_alert": "🔄",
    "same_day_reminder": "📅",
    "custom": "🔔",
  };

  @override
  void initState() {
    super.initState();
    fetchReminders();
  }

  Future<void> fetchReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/reminders/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final today = DateTime.now();

        final todayReminders =
            data.where((reminder) {
              final date = DateTime.parse(reminder['date']);
              return date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
            }).toList();

        setState(() {
          _reminders = todayReminders;
          _loading = false;
        });
      } else {
        print("Failed to load doctor reminders");
        setState(() => _loading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Reminders")),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _reminders.isEmpty
              ? const Center(child: Text("No reminders for today."))
              : ListView.builder(
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  final r = _reminders[index];
                  final emoji = emojiMap[r['reminder_type']] ?? "🔔";

                  return Dismissible(
                    key: Key(r['id'].toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      setState(() {
                        _reminders.removeWhere((item) => item['id'] == r['id']);
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Marked as done ✅")),
                      );
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.green,
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    child: ListTile(
                      leading: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(r['message'] ?? "No message"),
                      subtitle: Text("⏰ ${r['time']}"),
                    ),
                  );
                },
              ),
    );
  }
}
