import 'package:flutter/material.dart';

class DoctorAppointmentScreen extends StatefulWidget {
  final List<dynamic> appointments;

  const DoctorAppointmentScreen({Key? key, required this.appointments})
    : super(key: key);

  @override
  State<DoctorAppointmentScreen> createState() =>
      _DoctorAppointmentScreenState();
}

class _DoctorAppointmentScreenState extends State<DoctorAppointmentScreen> {
  @override
  Widget build(BuildContext context) {
    final appointments = widget.appointments;

    if (appointments.isEmpty) {
      return const Center(
        child: Text('No appointments found.', style: TextStyle(fontSize: 16)),
      );
    }

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "👤 Patient: ${appt['user_name'] ?? 'Unknown'}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("📅 Date: ${appt['appointment_date']}"),
                Text("🕒 Time: ${appt['appointment_time']}"),
                Text("📝 Reason: ${appt['reason'] ?? 'N/A'}"),
                const SizedBox(height: 4),
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
                    const SizedBox(width: 6),
                    Text(
                      appt['payment_token'] != null ? 'Paid' : 'Pay Later',
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
              ],
            ),
          ),
        );
      },
    );
  }
}
