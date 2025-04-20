import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../constants/api_constants.dart';
import '../doctor_model.dart';
import '../appointment_model.dart';

class ApiService {
  // 🔐 Unified Login
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
      await prefs.setString('access', data['access']);
      await prefs.setString('refresh', data['refresh']);
      await prefs.setString('role', data['role']);
      await prefs.setString('email', data['email']);
      await prefs.setString('first_name', data['first_name']);
      await prefs.setString('username', data['username']);
      if (data['profile_image'] != null) {
        await prefs.setString('profile_image', data['profile_image']);
      }
    }

    return response;
  }

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
      return true;
    } else {
      print("❌ Registration failed: ${response.body}");
      return false;
    }
  }

  static Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<http.Response> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/api/forgot-password/');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
  }

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

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    if (token == null) {
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/profile/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch profile: ${response.body}");
      return null;
    }
  }

  static Future<void> logSymptoms(List<int> symptomIds) async {
    final token = await _getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('$baseUrl/api/log-symptoms/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'symptom_ids': symptomIds}),
    );

    if (response.statusCode != 200) {
      print("❌ Failed to log symptoms: ${response.body}");
    }
  }

  static Future<void> logPeriodDates(List<DateTime> periodDates) async {
    final token = await _getToken();
    if (token == null) return;

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

    if (!(response.statusCode == 200 || response.statusCode == 201)) {
      print("❌ Failed to sync period dates: ${response.body}");
    }
  }

  static Future<List<Doctor>> fetchDoctors() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/doctors/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) => Doctor.fromJson(json)).toList();
    } else {
      print('❌ Failed to fetch doctors: ${response.body}');
      throw Exception('Failed to load doctors');
    }
  }

  static Future<bool> bookAppointment({
    required int doctorId,
    required DateTime date,
    required String time,
    required String reason,
  }) async {
    final token = await _getToken();
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

  static Future<List<Appointment>> fetchAppointments() async {
    final token = await _getToken();

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

  static Future<List<String>> getBookedTimes(
    int doctorId,
    DateTime date,
  ) async {
    final token = await _getToken();

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
      return [];
    }
  }

  static Future<bool> bookAppointmentWithPayment({
    required int doctorId,
    required DateTime date,
    required String time,
    required String reason,
    required String paymentToken,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/book-appointment-with-payment/'),
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

  static Future<List<dynamic>> fetchDoctorAppointments({String? date}) async {
    final token = await _getToken();
    final uri =
        date != null
            ? Uri.parse('$baseUrl/api/doctor-appointments/?date=$date')
            : Uri.parse('$baseUrl/api/doctor-appointments/');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(
        "❌ Error fetching doctor appointments: ${response.statusCode} ${response.body}",
      );
      throw Exception("Failed to load appointments");
    }
  }

  static Future<bool> markAppointmentCompleted(int id) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/api/update-appointment-status/$id/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': 'completed'}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> bookAppointmentWithoutPayment({
    required int doctorId,
    required DateTime date,
    required String time,
    required String reason,
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
      }),
    );

    return response.statusCode == 201;
  }

  Future<String?> initiateKhaltiPayment({
    required int amount,
    required String orderId,
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/initiate-khalti-payment/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount, // e.g. 50000 for Rs. 500
        'order_id': orderId,
        'name': name,
        'email': email,
        'phone': phone,
      }),
    );

    final data = jsonDecode(response.body);
    return data['payment_url']; // This will be opened
  }

  static Future<bool> verifyKhaltiPayment(
    String token,
    int amount,
    String accessToken,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/verify-khalti-payment/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'token': token, 'amount': amount}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'Completed';
    } else {
      print("❌ Verification failed: ${response.body}");
      return false;
    }
  }

  static Future<Doctor> fetchLoggedInDoctor() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/doctor-profile/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("📦 Doctor Profile Response: ${response.body}");

    if (response.statusCode == 200) {
      return Doctor.fromJson(json.decode(response.body));
    } else {
      print(
        "❌ Doctor profile load failed: ${response.statusCode} ${response.body}",
      );
      throw Exception("Doctor profile not found.");
    }
  }

  static Future<bool> updateDoctorProfile(Map<String, dynamic> data) async {
    final token = await _getToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/api/doctor-profile/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access');
  }

  static Future<List<Map<String, dynamic>>> fetchReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/reminders/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to fetch reminders');
    }
  }
}
