// 📁 dashboard.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import 'calendar_page.dart';
import 'prediction_utils.dart';
import 'profile_screen.dart';
import 'exercise_screen.dart';
import 'consult_doctor_screen.dart';
import 'appointment_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> screens = [
      HomeTab(
        onNavigateToCalendar: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CalendarPage(
                    isLogMode: true,
                    onGoBack: () {
                      setState(() {});
                    },
                  ),
            ),
          );
        },
      ),
      Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder:
                (_) => CalendarPage(
                  isLogMode: false,
                  onGoBack: () => _onItemTapped(0),
                ),
          );
        },
      ),
      Center(child: Text("Community Page Coming Soon")),
      ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Community',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final VoidCallback onNavigateToCalendar;

  HomeTab({required this.onNavigateToCalendar});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String userName = "";
  final DateTime today = DateTime.now();

  int _cycleDay = 0;
  int _nextPeriodIn = 0;
  int _ovulationIn = 0;
  List<DateTime> _fertileWindow = [];
  bool _periodOngoing = false;
  bool _isFertile = false;
  bool _isOvulation = false;

  @override
  void initState() {
    super.initState();
    fetchUserName();
    calculatePredictions();
  }

  Future<void> fetchUserName() async {
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
        if (!mounted) return;
        setState(() {
          userName = data['first_name'] ?? "";
        });
      }
    } catch (e) {
      print("❌ Error fetching name: $e");
    }
  }

  Future<void> calculatePredictions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final cycleLength =
        int.tryParse(prefs.getString('cycle_length') ?? "28") ?? 28;

    List<DateTime> periodDates = [];

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/period-logs/'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          periodDates = data.map((d) => DateTime.parse(d)).toList();

          await prefs.setStringList(
            'logged_periods',
            periodDates.map((d) => d.toIso8601String()).toList(),
          );
        }
      } catch (e) {
        print("❌ Error loading period logs: $e");
      }
    }

    if (periodDates.isEmpty) return;

    final lastPeriod = getLastPeriodDate(periodDates);
    final now = DateTime.now();
    if (lastPeriod == null) return;

    final ovulation = getOvulationDate(lastPeriod, cycleLength);
    final fertile = getFertileWindow(ovulation);
    final periodRange = List.generate(
      5,
      (i) => lastPeriod.add(Duration(days: i)),
    );

    if (!mounted) return;
    setState(() {
      _cycleDay = calculateCycleDay(lastPeriod);
      _nextPeriodIn = getNextPeriodDate(
        lastPeriod,
        cycleLength,
      ).difference(now).inDays.clamp(0, 999);
      _ovulationIn = ovulation.difference(now).inDays.clamp(0, 999);
      _fertileWindow = fertile;
      _periodOngoing = periodRange.any((d) => isSameDate(d, now));
      _isOvulation = isSameDate(ovulation, now);
      _isFertile = fertile.any((d) => isSameDate(d, now));
    });
  }

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String getMainPredictionText() {
    if (_periodOngoing) return "Your period is ongoing";
    if (_isOvulation) return "You are ovulating today";
    if (_isFertile) return "You are in your fertile window";
    return "Your period starts in $_nextPeriodIn days";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final weekDates = List.generate(
      7,
      (i) => today.subtract(Duration(days: today.weekday - 1 - i)),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.tune),
                Text(
                  "Hi, ${userName.isNotEmpty ? userName : 'User'}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.notifications_none_outlined),
              ],
            ),
            SizedBox(height: 6),
            Center(
              child: Text(
                DateFormat('d MMMM').format(today),
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 68,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final date = weekDates[index];
                  final isToday = isSameDate(date, today);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? Colors.pink : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isToday
                                  ? Colors.pink.shade100
                                  : Colors.transparent,
                        ),
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isToday ? Colors.pink : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: Container(
                width: screenWidth * 0.6,
                height: screenWidth * 0.6,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFE6735D),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.pink.shade100, blurRadius: 20),
                  ],
                ),
                child: Center(
                  child: Text(
                    getMainPredictionText(),
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: widget.onNavigateToCalendar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade100,
                  foregroundColor: Colors.purple,
                  shape: StadiumBorder(),
                  elevation: 2,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Text(
                  "Log Period",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            SizedBox(height: 32),
            Text(
              "My Tools",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 3 / 2,
              children: [
                toolCard(
                  context,
                  "Log Symptoms",
                  Icons.note_add_outlined,
                  Colors.pink.shade50,
                  onTap: () => Navigator.pushNamed(context, '/symptoms'),
                ),
                toolCard(
                  context,
                  "Cycle Day $_cycleDay days",
                  Icons.favorite_border,
                  Colors.red.shade50,
                ),
                toolCard(
                  context,
                  "Ovulation in $_ovulationIn",
                  Icons.waves,
                  Colors.purple.shade50,
                ),
                toolCard(
                  context,
                  "Fertile Window",
                  Icons.calendar_today,
                  Colors.orange.shade50,
                  child: Column(
                    children: [
                      Text(
                        "Fertile Window",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        children:
                            _fertileWindow
                                .map(
                                  (d) => Text(
                                    "${d.day}/${d.month}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.pink,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
                toolCard(
                  context,
                  "Food Tips",
                  Icons.restaurant,
                  Colors.green.shade50,
                ),
                toolCard(
                  context,
                  "Exercises",
                  Icons.fitness_center,
                  Colors.blue.shade50,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ExerciseScreen()),
                      ),
                ),

                toolCard(
                  context,
                  "Read Blog",
                  Icons.menu_book,
                  Colors.amber.shade50,
                ),
                toolCard(
                  context,
                  "Consult Doctor",
                  Icons.local_hospital,
                  Colors.teal.shade50,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ConsultDoctorScreen(),
                        ),
                      ),
                ),
                toolCard(
                  context,
                  "My Appointments",
                  Icons.event_note,
                  Colors.teal.shade50,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AppointmentScreen()),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget toolCard(
    BuildContext context,
    String label,
    IconData icon,
    Color bgColor, {
    VoidCallback? onTap,
    Widget? child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        padding: EdgeInsets.all(14),
        child:
            child ??
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: Colors.pink),
                SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
      ),
    );
  }
}
