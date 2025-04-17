// 📁 lib/screens/exercise_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'menstruation_phase_utils.dart';
import 'exercise_detail_screen.dart';
import 'prediction_utils.dart';

class ExerciseScreen extends StatefulWidget {
  @override
  _ExerciseScreenState createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  String currentPhase = "";
  ExerciseRecommendation? todayRecommendation;

  @override
  void initState() {
    super.initState();
    determinePhase();
  }

  Future<void> determinePhase() async {
    final prefs = await SharedPreferences.getInstance();
    final cycleLength =
        int.tryParse(prefs.getString('cycle_length') ?? "28") ?? 28;
    final periodDuration =
        int.tryParse(prefs.getString('period_duration') ?? "5") ?? 5;
    final loggedDates = prefs.getStringList('logged_periods') ?? [];

    if (loggedDates.isEmpty) return;

    final periodDates = loggedDates.map((d) => DateTime.parse(d)).toList();
    final lastPeriod = getLastPeriodDate(periodDates);
    if (lastPeriod == null) return;

    final phase = getMenstrualPhase(
      DateTime.now(),
      lastPeriod,
      cycleLength,
      periodDuration,
    );

    final recommendations = getPhaseExerciseRecommendations();

    setState(() {
      currentPhase = phase;
      todayRecommendation = recommendations[phase];
    });
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = getPhaseExerciseRecommendations();

    return Scaffold(
      appBar: AppBar(
        title: Text("Exercise Recommendations"),
        backgroundColor: Colors.pinkAccent,
      ),
      backgroundColor: Colors.pink.shade50,
      body:
          todayRecommendation == null
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Phase: $currentPhase",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      todayRecommendation!.description,
                      style: TextStyle(color: Colors.grey[700], fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Why these exercises?",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(todayRecommendation!.benefit),
                    const SizedBox(height: 12),
                    Text(
                      "Suggested Exercises:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...todayRecommendation!.suggestedExercises.map(
                      (exercise) => Text("• $exercise"),
                    ),
                    const Divider(height: 32),
                    Text(
                      "Explore All Phases",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: recommendations.keys.length,
                        itemBuilder: (context, index) {
                          final phase = recommendations.keys.elementAt(index);
                          final rec = recommendations[phase]!;

                          return Card(
                            child: ListTile(
                              title: Text(rec.title),
                              subtitle: Text(
                                rec.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ExerciseDetailScreen(
                                          phase: phase,
                                          recommendation: rec,
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
