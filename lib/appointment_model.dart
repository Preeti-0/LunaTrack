import 'doctor_model.dart';

class Appointment {
  final int id;
  final Doctor doctor;
  final DateTime appointmentDate;
  final DateTime? createdAt;
  final String appointmentTime;
  final String reason;
  final String status; // <-- already declared correctly

  Appointment({
    required this.id,
    required this.doctor,
    required this.appointmentDate,
    this.createdAt,
    required this.appointmentTime,
    required this.reason,
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      doctor: Doctor.fromJson(json['doctor']),
      appointmentDate: DateTime.parse(json['appointment_date']),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      appointmentTime: json['appointment_time'],
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending', // <-- fixed this line
    );
  }
}
