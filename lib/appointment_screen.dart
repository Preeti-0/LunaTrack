import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'appointment_model.dart';
import '../services/api_service.dart';
import 'reschedule_modal.dart';

class AppointmentScreen extends StatefulWidget {
  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  late Future<List<Appointment>> _appointments;

  @override
  void initState() {
    super.initState();
    _appointments = ApiService.fetchAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: FutureBuilder<List<Appointment>>(
        future: _appointments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load appointments'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'You have no appointments yet.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          final appointments = snapshot.data!;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appt = appointments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            appt.doctor.imageUrl != null &&
                                    appt.doctor.imageUrl!.isNotEmpty
                                ? NetworkImage(appt.doctor.imageUrl!)
                                : const AssetImage(
                                      "assets/icons/doctor_placeholder.png",
                                    )
                                    as ImageProvider,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appt.doctor.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        appt.doctor.specialization,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Status Chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        appt.status == 'completed'
                                            ? Colors.green
                                            : Colors.amber,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    appt.status == 'completed'
                                        ? 'Completed'
                                        : 'Pending',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '📅 ${DateFormat('EEEE, MMM d, yyyy').format(appt.appointmentDate)}',
                            ),
                            Text('🕒 ${appt.appointmentTime}'),
                            const SizedBox(height: 4),
                            Text('📝 Reason: ${appt.reason}'),
                            const SizedBox(height: 4),

                            // ✅ Insert this check here:
                            if (appt.status == 'pending')
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  child: const Text("Reschedule"),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (_) => RescheduleModal(
                                            appointmentId: appt.id,
                                            currentDate: appt.appointmentDate,
                                            currentTime: appt.appointmentTime,
                                          ),
                                    );
                                  },
                                ),
                              ),

                            const SizedBox(height: 4),
                            Text(
                              appt.createdAt != null
                                  ? 'Booked on ${DateFormat('MMM d, yyyy').format(appt.createdAt!)}'
                                  : 'Booked on Unknown',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
