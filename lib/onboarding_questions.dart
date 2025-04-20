import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class OnboardingQuestionsScreen extends StatefulWidget {
  @override
  _OnboardingQuestionsScreenState createState() =>
      _OnboardingQuestionsScreenState();
}

class _OnboardingQuestionsScreenState extends State<OnboardingQuestionsScreen> {
  final PageController _pageController = PageController();

  DateTime? birthDate;
  String? cycleRegularity;
  String? periodDuration;
  String? cycleLength;
  DateTime? lastPeriodStart;

  bool _isSubmitting = false;

  Future<void> _submitData() async {
    if (birthDate == null ||
        cycleRegularity == null ||
        periodDuration == null ||
        cycleLength == null ||
        lastPeriodStart == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please complete all questions.")));
      return;
    }

    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    if (token == null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Missing access token. Please log in again.")),
      );
      return;
    }

    // Convert "Not Sure" to null
    int? parsedDuration =
        periodDuration != "Not Sure" ? int.tryParse(periodDuration!) : null;
    int? parsedLength =
        cycleLength != "Not Sure" ? int.tryParse(cycleLength!) : null;

    try {
      // PATCH profile
      final profileRes = await http.patch(
        Uri.parse('$baseUrl/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "birth_date": birthDate!.toIso8601String().split('T')[0],
          "cycle_regular": cycleRegularity,
          "period_duration": parsedDuration,
          "cycle_length": parsedLength,
        }),
      );

      if (profileRes.statusCode != 200) {
        setState(() => _isSubmitting = false);
        final body = jsonDecode(profileRes.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Profile error: ${body.toString()}")),
        );
        return;
      }

      // POST period log
      final periodRes = await http.post(
        Uri.parse('$baseUrl/api/period-logs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "dates": [lastPeriodStart!.toIso8601String().split('T')[0]],
        }),
      );

      setState(() => _isSubmitting = false);

      if (periodRes.statusCode == 201) {
        Navigator.pushReplacementNamed(context, "/dashboard");
      } else {
        final err = jsonDecode(periodRes.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Period log failed: ${err.toString()}")),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: ${e.toString()}")));
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildQuestion({
    required String title,
    required Widget child,
    bool showBack = false,
    bool showContinue = true,
    bool isFinal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          child,
          SizedBox(height: 30),
          if (_isSubmitting)
            CircularProgressIndicator()
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showBack)
                  ElevatedButton(
                    onPressed:
                        () => _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                    child: Text("Back"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                if (showContinue && !isFinal)
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text("Next"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                    ),
                  ),
                if (isFinal)
                  ElevatedButton(
                    onPressed: _submitData,
                    child: Text("Submit"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF0F5),
      appBar: AppBar(
        title: Text("Let's Get to Know You"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          // 1. Birth Date
          _buildQuestion(
            title: "1. What is your birth date?",
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => birthDate = picked);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  birthDate == null
                      ? "Select your birth date"
                      : "${birthDate!.toLocal()}".split(' ')[0],
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            showBack: false,
          ),

          // 2. Cycle Regularity
          _buildQuestion(
            title: "2. Is your cycle regular?",
            child: Column(
              children:
                  ["Regular", "Irregular", "Not Sure"]
                      .map(
                        (option) => RadioListTile(
                          title: Text(option),
                          value: option,
                          groupValue: cycleRegularity,
                          onChanged:
                              (val) => setState(
                                () => cycleRegularity = val.toString(),
                              ),
                        ),
                      )
                      .toList(),
            ),
            showBack: true,
          ),

          // 3. Period Duration
          _buildQuestion(
            title: "3. How many days does your period usually last?",
            child: DropdownButtonFormField<String>(
              value: periodDuration,
              onChanged: (value) => setState(() => periodDuration = value),
              items:
                  [...List.generate(10, (i) => (i + 1).toString()), "Not Sure"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            showBack: true,
          ),

          // 4. Cycle Length
          _buildQuestion(
            title: "4. What is your average cycle length?",
            child: DropdownButtonFormField<String>(
              value: cycleLength,
              onChanged: (value) => setState(() => cycleLength = value),
              items:
                  [...List.generate(20, (i) => (20 + i).toString()), "Not Sure"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            showBack: true,
          ),

          // 5. Last Period Start Date
          _buildQuestion(
            title: "5. When did your last period start?",
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => lastPeriodStart = picked);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lastPeriodStart == null
                      ? "Select last period start date"
                      : "${lastPeriodStart!.toLocal()}".split(' ')[0],
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            showBack: true,
            isFinal: true,
          ),
        ],
      ),
    );
  }
}
