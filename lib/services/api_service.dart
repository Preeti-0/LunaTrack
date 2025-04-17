import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../constants/api_constants.dart';
import '../doctor_model.dart';
import '../appointment_model.dart';

class ApiService {
  // 🔐 Login
  static Future<http.Response> loginUser(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/token/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);
    } else {
      print("❌ Login failed: \${response.body}");
    }

    return response;
  }

  // 📝 Register
  static Future<bool> registerUser(
    String username,
    String email,
    String password,
    String role,
  ) async {
    final url = Uri.parse('$baseUrl/api/register/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      print("✅ Registration successful, now logging in...");
      final loginRes = await loginUser(email, password);
      return loginRes.statusCode == 200;
    } else {
      print("❌ Registration failed: \${response.body}");
      return false;
    }
  }

  // 🚪 Logout
  static Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // 🔑 Forgot Password
  static Future<http.Response> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/api/forgot-password/');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
  }

  // 🔁 Reset Password
  static Future<http.Response> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/api/reset-password/');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
        'new_password': newPassword,
      }),
    );
  }

  // 👤 Profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      print("❌ No access token found");
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/profile/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch profile: \${response.body}");
      return null;
    }
  }

  // 🧪 Log Symptoms
  static Future<void> logSymptoms(List<int> symptomIds) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      print("❌ Token not found. Please login again.");
      return;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/log-symptoms/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'symptom_ids': symptomIds}),
    );

    if (response.statusCode == 200) {
      print("✅ Symptoms logged successfully");
    } else {
      print("❌ Failed to log symptoms: \${response.body}");
    }
  }

  // 📅 Log Period
  static Future<void> logPeriodDates(List<DateTime> periodDates) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      print("❌ Token not found. Please login again.");
      return;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/period-logs/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'dates': periodDates.map((d) => d.toIso8601String()).toList(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ Period dates synced with backend");
    } else {
      print("❌ Failed to sync period dates: \${response.body}");
    }
  }

  // 🔹 Get list of doctors
  static Future<List<Doctor>> fetchDoctors() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/doctors/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => Doctor.fromJson(json)).toList();
      } catch (e, stackTrace) {
        print('❌ Decoding error: $e');
        print('📍 Stack trace: $stackTrace'); // Add this too
        throw Exception('Failed to decode doctor data');
      }
    } else {
      print('❌ Failed to fetch doctors: \${response.body}');
      throw Exception('Failed to load doctors');
    }
  }

  // 🔹 Book appointment
  static Future<bool> bookAppointment({
    required int doctorId,
    required DateTime date,
    required String time,
    required String reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.post(
      Uri.parse('$baseUrl/api/appointments/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'doctor_id': doctorId,
        'appointment_date': DateFormat('yyyy-MM-dd').format(date),
        'appointment_time': time,
        'reason': reason,
      }),
    );

    return response.statusCode == 201;
  }

  // 🔹 View appointments
  static Future<List<Appointment>> fetchAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/appointments/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => Appointment.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch appointments');
    }
  }

  // 🔹 Get booked times for doctor on a given day
  static Future<List<String>> getBookedTimes(
    int doctorId,
    DateTime date,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/booked-times/?doctor_id=$doctorId&date=${DateFormat('yyyy-MM-dd').format(date)}',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['booked_times']);
    } else {
      print('❌ Failed to fetch booked times: \${response.body}');
      return [];
    }
  }

  // 🔐 Access token helper for this file
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 🔄 Book appointment after payment
  static Future<bool> bookAppointmentWithPayment({
    required int doctorId,
    required DateTime date,
    required String time,
    required String reason,
    required String paymentToken,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/appointments/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'doctor_id': doctorId,
        'appointment_date': date.toIso8601String().split("T")[0],
        'appointment_time': time,
        'reason': reason,
        'payment_token': paymentToken,
      }),
    );

    return response.statusCode == 201;
  }
}
