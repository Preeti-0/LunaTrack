import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SymptomLoggingScreen extends StatefulWidget {
  @override
  _SymptomLoggingScreenState createState() => _SymptomLoggingScreenState();
}

Map<String, int> symptomIdMap = {
  'Cravings': 1,
  'Nausea': 2,
  'Cramps': 3,
  'Mood swings': 4,
  'Acne': 5,
  'Headache': 6,
  'Backache': 7,
  'Fatigue': 8,
  'Insomnia': 9,
  'Tender breasts': 10,
  'Abdominal pain': 11,
  'Vaginal itching': 12,
  'Vaginal dryness': 13,
};

class _SymptomLoggingScreenState extends State<SymptomLoggingScreen> {
  final Map<String, List<Map<String, dynamic>>> symptomCategories = {
    'Menstrual Flow': [
      {'label': 'Light', 'icon': Icons.opacity},
      {'label': 'Medium', 'icon': Icons.invert_colors},
      {'label': 'Heavy', 'icon': Icons.water_drop},
      {'label': 'Blood Clots', 'icon': Icons.bubble_chart},
    ],
    'Symptoms': [
      {'label': 'Cravings', 'icon': Icons.fastfood},
      {'label': 'Nausea', 'icon': Icons.sick},
      {'label': 'Cramps', 'icon': Icons.waves},
      {'label': 'Mood swings', 'icon': Icons.sentiment_very_dissatisfied},
      {'label': 'Acne', 'icon': Icons.face_retouching_natural},
      {'label': 'Headache', 'icon': Icons.health_and_safety},
      {'label': 'Backache', 'icon': Icons.accessibility_new},
      {'label': 'Fatigue', 'icon': Icons.battery_alert},
      {'label': 'Insomnia', 'icon': Icons.bedtime},
      {'label': 'Tender breasts', 'icon': Icons.favorite},
      {'label': 'Abdominal pain', 'icon': Icons.pan_tool},
      {'label': 'Vaginal itching', 'icon': Icons.healing},
      {'label': 'Vaginal dryness', 'icon': Icons.air},
    ],
    'Mood': [
      {'label': '😌 Calm', 'icon': null},
      {'label': '😊 Happy', 'icon': null},
      {'label': '😄 Energetic', 'icon': null},
      {'label': '😘 Frisky', 'icon': null},
      {'label': '😠 Irritated', 'icon': null},
      {'label': '😢 Sad', 'icon': null},
      {'label': '😟 Anxious', 'icon': null},
      {'label': '😞 Depressed', 'icon': null},
      {'label': '😕 Confused', 'icon': null},
      {'label': '🤯 Obsessive thoughts', 'icon': null},
      {'label': '😔 Very self-critical', 'icon': null},
      {'label': '😣 Feeling guilty', 'icon': null},
    ],
    'Vaginal Discharge': [
      {'label': 'No discharge', 'icon': Icons.block},
      {'label': 'Creamy', 'icon': Icons.cloud},
      {'label': 'Watery', 'icon': Icons.opacity},
      {'label': 'Sticky', 'icon': Icons.bubble_chart},
      {'label': 'Egg white', 'icon': Icons.egg},
      {'label': 'Spotting', 'icon': Icons.brightness_1},
      {'label': 'Unusual', 'icon': Icons.warning},
      {'label': 'Clumpy white', 'icon': Icons.blur_on},
      {'label': 'Gray', 'icon': Icons.grain},
    ],
    'Digestion and Stool': [
      {'label': 'Nausea', 'icon': Icons.sick},
      {'label': 'Bloating', 'icon': Icons.airline_seat_legroom_extra},
      {'label': 'Constipation', 'icon': Icons.hourglass_bottom},
      {'label': 'Diarrhea', 'icon': Icons.water_damage},
    ],
  };

  final Map<String, Map<String, String>> guidance = {
    'Cramps': {
      'food': 'Banana',
      'benefit': 'Rich in magnesium; helps relax muscles',
    },
    'Nausea': {'food': 'Ginger tea', 'benefit': 'Soothes stomach lining'},
    'Headache': {'food': 'Spinach', 'benefit': 'Magnesium reduces headache'},
    'Fatigue': {'food': 'Almonds', 'benefit': 'Boosts energy levels'},
    'Backache': {'food': 'Salmon', 'benefit': 'Omega-3 reduces inflammation'},
    'Sad': {'food': 'Dark chocolate', 'benefit': 'Boosts serotonin and mood'},
    'Anxious': {'food': 'Chamomile tea', 'benefit': 'Calms nervous system'},
    'Irritated': {'food': 'Avocado', 'benefit': 'Supports hormone balance'},
    'Vaginal dryness': {'food': 'Avocado', 'benefit': 'Supports healthy fats'},
    'Clumpy white': {'food': 'Garlic', 'benefit': 'Antifungal properties'},
    'Unusual': {
      'food': 'Yogurt',
      'benefit': 'Probiotics restore good bacteria',
    },
    'Bloating': {
      'food': 'Ginger tea',
      'benefit': 'Reduces digestive discomfort',
    },
    'Constipation': {
      'food': 'Papaya',
      'benefit': 'High fiber boosts bowel movement',
    },
    'Diarrhea': {'food': 'Banana', 'benefit': 'Replenishes electrolytes'},
  };

  Map<String, Set<String>> selectedValues = {};

  List<Map<String, String>> generateGuidance() {
    List<Map<String, String>> result = [];
    selectedValues.forEach((category, values) {
      for (var val in values) {
        if (guidance.containsKey(val)) {
          result.add({
            'symptom': val,
            'food': guidance[val]!['food']!,
            'benefit': guidance[val]!['benefit']!,
          });
        }
      }
    });
    return result;
  }

  void showFlowInfo(String flowType) {
    Map<String, String> info = {
      'Light':
          'Light flow may be caused by stress or hormonal imbalance. Eat iron-rich foods.',
      'Medium':
          'A normal and healthy flow. Stay hydrated and eat fruits and veggies.',
      'Heavy':
          'Heavy flow can be due to estrogen dominance. Eat anti-inflammatory foods.',
      'Blood Clots':
          'Could be due to thickened lining. Focus on iron and omega-3 rich foods.',
    };

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('$flowType Flow Info'),
            content: Text(info[flowType] ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
    );
  }

  Future<void> handleSubmit() async {
    final selected = selectedValues['Symptoms'] ?? {};
    List<int> ids =
        selected.map((label) => symptomIdMap[label]).whereType<int>().toList();

    if (ids.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select symptoms.")));
      return;
    }

    try {
      await ApiService.logSymptoms(ids);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Symptoms submitted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed to submit symptoms.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF6F9),
      appBar: AppBar(
        title: Text("Log Symptoms"),
        backgroundColor: Colors.pinkAccent,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        symptomCategories.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.pink,
                                ),
                              ),
                              SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children:
                                    entry.value.map((item) {
                                      final label = item['label'];
                                      final icon = item['icon'];
                                      final isSelected =
                                          selectedValues[entry.key]?.contains(
                                            label,
                                          ) ??
                                          false;

                                      return ChoiceChip(
                                        avatar:
                                            icon != null
                                                ? Icon(
                                                  icon,
                                                  size: 16,
                                                  color:
                                                      isSelected
                                                          ? Colors.white
                                                          : Colors.pink,
                                                )
                                                : null,
                                        label: Text(label),
                                        selected: isSelected,
                                        shape: StadiumBorder(
                                          side: BorderSide(
                                            color: Colors.pinkAccent,
                                          ),
                                        ),
                                        backgroundColor: Colors.white,
                                        labelStyle: TextStyle(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.pink,
                                        ),
                                        selectedColor: Colors.pinkAccent,
                                        onSelected: (selected) {
                                          setState(() {
                                            selectedValues.putIfAbsent(
                                              entry.key,
                                              () => <String>{},
                                            );
                                            if (selected) {
                                              selectedValues[entry.key]!.add(
                                                label,
                                              );
                                              if (entry.key == 'Menstrual Flow')
                                                showFlowInfo(label);
                                            } else {
                                              selectedValues[entry.key]!.remove(
                                                label,
                                              );
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                              SizedBox(height: 24),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: StadiumBorder(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 14,
                      ),
                    ),
                    child: Text("Submit"),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      final list = generateGuidance();
                      showDialog(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: Text(
                                "Nutritional Guidance",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content:
                                  list.isEmpty
                                      ? Text("No suggestions available.")
                                      : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children:
                                            list.map((item) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 6,
                                                    ),
                                                child: RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 14,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text:
                                                            "${item['food']} for ${item['symptom']}: ",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: item['benefit'],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                              actions: [
                                TextButton(
                                  child: Text("Close"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.pinkAccent,
                      side: BorderSide(color: Colors.pinkAccent),
                      shape: StadiumBorder(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    child: Text("Give Nutritional Guidance"),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
