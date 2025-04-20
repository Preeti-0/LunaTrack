import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'doctor_model.dart';
import 'login.dart';
import 'edit_doctor_profile_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  _DoctorDashboardScreenState createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  Doctor? _doctor;
  List<dynamic> _appointments = [];
  bool _loading = true;
  int _selectedIndex = 0;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    setState(() => _loading = true);
    try {
      final doctor = await ApiService.fetchLoggedInDoctor();
      final appointments = await ApiService.fetchDoctorAppointments(
        date:
            _selectedDate != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                : null,
      );
      setState(() {
        _doctor = doctor;
        _appointments = appointments;
        _loading = false;
      });
    } catch (e) {
      print("Error loading doctor data: $e");
      setState(() => _loading = false);
    }
  }

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage:
                  (_doctor?.imageUrl?.isNotEmpty ?? false)
                      ? NetworkImage(_doctor!.imageUrl!)
                      : null,
              child:
                  (_doctor?.imageUrl?.isEmpty ?? true)
                      ? const Icon(Icons.person, size: 35)
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _doctor?.name != null &&
                            !_doctor!.name.toLowerCase().startsWith("dr.")
                        ? "Dr. ${_doctor!.name}"
                        : _doctor?.name ?? "No Name Set",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _doctor?.specialization ?? 'No Specialization',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => EditDoctorProfileScreen(
                                currentProfile: {
                                  'name': _doctor?.name ?? '',
                                  'specialization':
                                      _doctor?.specialization ?? '',
                                  'location': _doctor?.location ?? '',
                                  'experience': _doctor?.experience ?? '',
                                  'phone': _doctor?.phone ?? '',
                                  'education': _doctor?.education ?? '',
                                  'about': _doctor?.about ?? '',
                                  'available_days':
                                      _doctor?.availableDays ?? '',
                                  'available_time':
                                      _doctor?.availableTime ?? '',
                                  'image': _doctor?.imageUrl ?? '',
                                },
                              ),
                        ),
                      );
                      if (updated == true) _loadDoctorData();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic appt) {
    final appointmentDateTime = DateTime.parse(
      "${appt['appointment_date']} ${appt['appointment_time']}",
    );
    final now = DateTime.now();
    final isPast = now.isAfter(appointmentDateTime);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          "Patient: ${appt['user_name'] ?? 'Unknown'}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: ${appt['appointment_date']}"),
            Text("Time: ${appt['appointment_time']}"),
            Text("Reason: ${appt['reason'] ?? ''}"),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      appt['payment_token'] != null
                          ? Icons.verified
                          : Icons.hourglass_bottom,
                      color:
                          appt['payment_token'] != null
                              ? Colors.green
                              : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appt['payment_token'] != null ? "Paid" : "Pay Later",
                      style: TextStyle(
                        color:
                            appt['payment_token'] != null
                                ? Colors.green
                                : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        appt['status'] == 'completed'
                            ? Colors.green
                            : Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appt['status'] == 'completed' ? 'Completed' : 'Pending',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (appt['status'] == 'pending' && isPast)
              TextButton(
                onPressed: () async {
                  final success = await ApiService.markAppointmentCompleted(
                    appt['id'],
                  );
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marked as completed')),
                    );
                    _loadDoctorData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update status')),
                    );
                  }
                },
                child: const Text("Mark as Completed"),
              ),
            if (appt['status'] == 'pending' && !isPast)
              TextButton(
                onPressed: null,
                child: const Text(
                  "Mark as Completed",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(List<dynamic> appointmentList) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadDoctorData,
        child:
            appointmentList.isEmpty
                ? const Center(child: Text("No Appointments Found"))
                : ListView.builder(
                  itemCount: appointmentList.length,
                  itemBuilder:
                      (context, index) =>
                          _buildAppointmentCard(appointmentList[index]),
                ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            "Filter by Date:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2023),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadDoctorData();
              }
            },
            child: Text(
              _selectedDate == null
                  ? "Pick Date"
                  : DateFormat('yyyy-MM-dd').format(_selectedDate!),
            ),
          ),
          const Spacer(),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() => _selectedDate = null);
                _loadDoctorData();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayAppointments =
        _appointments.where((a) => a['appointment_date'] == today).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileCard(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
          child: Text(
            "Today's Appointments",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        _buildAppointmentList(todayAppointments),
      ],
    );
  }

  Widget _buildAppointmentsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateFilter(),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "All Appointments",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        _buildAppointmentList(_appointments),
      ],
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout),
        label: const Text("Log Out"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_selectedIndex) {
      case 0:
        bodyContent = _buildDashboardTab();
        break;
      case 1:
        bodyContent = _buildAppointmentsTab();
        break;
      case 2:
        bodyContent = _buildProfileTab();
        break;
      default:
        bodyContent = const Center(child: Text("Unknown tab"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDoctorData,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/doctor-reminders');
            },
          ),
        ],
      ),
      body: bodyContent,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
