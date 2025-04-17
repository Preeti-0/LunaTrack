import 'doctor_model.dart';

class Appointment {
  final int id;
  final Doctor doctor;
  final DateTime appointmentDate;
  final DateTime? createdAt;
  final String appointmentTime;
  final String reason;

  Appointment({
    required this.id,
    required this.doctor,
    required this.appointmentDate,
    this.createdAt,
    required this.appointmentTime,
    required this.reason,
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
      appointmentTime:
          json['appointment_time'], // This is a String like "11:00"
      reason: json['reason'] ?? '',
    );
  }
}
