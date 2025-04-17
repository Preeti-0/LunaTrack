// 📁 lib/calendar_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'prediction_utils.dart';

class CalendarPage extends StatefulWidget {
  final VoidCallback onGoBack;
  final bool isLogMode;

  CalendarPage({required this.onGoBack, this.isLogMode = false});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DateTime> _loggedPeriods = [];
  Set<DateTime> _tempSelectedDays = {};

  int _cycleLength = 28;
  int _periodDuration = 5;

  Set<DateTime> _periodDays = {};
  Set<DateTime> _fertileDays = {};
  Set<DateTime> _ovulationDays = {};

  @override
  void initState() {
    super.initState();
    widget.isLogMode ? _loadLoggedPeriods() : _loadPredictions();
  }

  Future<void> _fetchCycleInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cycleLength = data['cycle_length'] ?? 28;
        _periodDuration = data['period_duration'] ?? 5;
      }
    } catch (e) {
      print("❌ Failed to fetch profile: $e");
    }
  }

  Future<void> _loadLoggedPeriods() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDates = prefs.getStringList('logged_periods') ?? [];

    await _fetchCycleInfo();

    final periods = savedDates.map((e) => DateTime.parse(e)).toList();
    setState(() {
      _loggedPeriods = periods;
      _tempSelectedDays = periods.toSet();
    });

    _calculateHighlights();
  }

  Future<void> _loadPredictions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/predict-dates/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        Set<DateTime> periodDays = Set.from(
          (data['period_days'] ?? []).map<DateTime>((d) => DateTime.parse(d)),
        );
        Set<DateTime> fertileDays = Set.from(
          (data['fertile_windows'] ?? []).map<DateTime>(
            (d) => DateTime.parse(d),
          ),
        );
        Set<DateTime> ovulationDays = Set.from(
          (data['ovulation_days'] ?? []).map<DateTime>(
            (d) => DateTime.parse(d),
          ),
        );

        // DO NOT filter out anything – keep full predictions for all months
        setState(() {
          _periodDays = periodDays;
          _fertileDays = fertileDays;
          _ovulationDays = ovulationDays;
        });
      } else {
        print("❌ Failed to fetch predictions");
      }
    } catch (e) {
      print("❌ Error fetching predictions: $e");
    }
  }

  Future<void> _saveLoggedPeriods() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    prefs.setStringList(
      'logged_periods',
      _tempSelectedDays.map((d) => d.toIso8601String()).toList(),
    );

    if (token != null) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/period-logs/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'dates': _tempSelectedDays.map((d) => d.toIso8601String()).toList(),
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          print("✅ Synced with backend");
        } else {
          print("❌ Failed to sync: ${response.body}");
        }
      } catch (e) {
        print("❌ Error syncing period logs: $e");
      }
    }

    setState(() {
      _loggedPeriods = _tempSelectedDays.toList();
      _calculateHighlights();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Period log saved successfully"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _calculateHighlights() {
    _periodDays.clear();
    _fertileDays.clear();
    _ovulationDays.clear();

    if (_loggedPeriods.isEmpty) return;

    final lastPeriod = getLastPeriodDate(_loggedPeriods);
    if (lastPeriod == null) return;

    final ovulation = getOvulationDate(lastPeriod, _cycleLength);
    _ovulationDays.add(ovulation);
    _fertileDays.addAll(getFertileWindow(ovulation));
    for (int i = 0; i < _periodDuration; i++) {
      _periodDays.add(lastPeriod.add(Duration(days: i)));
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!widget.isLogMode) return;

    if (selectedDay.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("🚫 Cannot log future dates")));
      return;
    }

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;

      if (_tempSelectedDays.any((d) => _isSameDay(d, selectedDay))) {
        _tempSelectedDays.removeWhere((d) => _isSameDay(d, selectedDay));
      } else {
        _tempSelectedDays.add(selectedDay);
      }

      _calculateHighlights();
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: Text(widget.isLogMode ? "Log Period" : "My Calendar"),
        backgroundColor: Colors.pinkAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            widget.onGoBack();
          },
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2022, 1, 1),
            lastDay: DateTime.utc(2032, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate:
                (day) => _selectedDay != null && _isSameDay(_selectedDay!, day),
            onDaySelected: widget.isLogMode ? _onDaySelected : null,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              todayDecoration: BoxDecoration(
                color: Colors.pink.shade100,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) {
                Color? bgColor;

                if (_tempSelectedDays.any((d) => _isSameDay(d, day))) {
                  bgColor = Colors.pinkAccent.shade200;
                } else if (_periodDays.any((d) => _isSameDay(d, day))) {
                  bgColor = Colors.redAccent.shade100;
                } else if (_ovulationDays.any((d) => _isSameDay(d, day))) {
                  bgColor = Colors.purple.shade100;
                } else if (_fertileDays.any((d) => _isSameDay(d, day))) {
                  bgColor = Colors.green.shade100;
                }

                return Container(
                  margin: EdgeInsets.all(6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight:
                          _isSameDay(day, DateTime.now())
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          Text(
            widget.isLogMode
                ? "📌 Tap to log or unlog a date. Press Save to apply changes."
                : "🗓️ Predicted periods, ovulation & fertile days",
            style: TextStyle(color: Colors.grey[700]),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildLegend(),
          ),
          SizedBox(height: 16),
          if (widget.isLogMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveLoggedPeriods,
                  icon: Icon(Icons.save),
                  label: Text("Save"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade200,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _tempSelectedDays = _loggedPeriods.toSet();
                      _calculateHighlights();
                    });
                  },
                  icon: Icon(Icons.cancel),
                  label: Text("Cancel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(),
        Text(
          "Legend",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        _legendRow("Selected (to log/unlog)", Colors.pinkAccent.shade200),
        _legendRow("Period Days", Colors.redAccent.shade100),
        _legendRow("Fertile Window", Colors.green.shade100),
        _legendRow("Ovulation Day", Colors.purple.shade100),
      ],
    );
  }

  Widget _legendRow(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [_legendCircle(color), SizedBox(width: 6), Text(label)],
      ),
    );
  }

  Widget _legendCircle(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
