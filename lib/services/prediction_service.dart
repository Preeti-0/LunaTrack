import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class PredictionService {
  static Future<Map<String, dynamic>?> fetchPredictions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/predict-dates/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ Prediction fetch failed: ${response.body}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    }

    return null;
  }
}
