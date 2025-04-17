// 📁 lib/menstruation_phase_utils.dart

String getMenstrualPhase(
  DateTime today,
  DateTime lastPeriodStart,
  int cycleLength,
  int periodDuration,
) {
  final cycleDay = today.difference(lastPeriodStart).inDays % cycleLength;

  if (cycleDay < periodDuration) {
    return 'Menstruation';
  } else if (cycleDay >= periodDuration && cycleDay < (cycleLength - 14 - 1)) {
    return 'Follicular';
  } else if (cycleDay >= (cycleLength - 14 - 1) &&
      cycleDay <= (cycleLength - 14 + 1)) {
    return 'Ovulation';
  } else {
    return 'Luteal';
  }
}

class ExerciseRecommendation {
  final String title;
  final String description;
  final String benefit;
  final List<String> suggestedExercises;
  final Map<String, String> videoLinks;

  ExerciseRecommendation({
    required this.title,
    required this.description,
    required this.benefit,
    required this.suggestedExercises,
    required this.videoLinks,
  });
}

Map<String, ExerciseRecommendation> getPhaseExerciseRecommendations() {
  return {
    "Menstruation": ExerciseRecommendation(
      title: "Menstruation Phase",
      description:
          "This is the bleeding phase, typically lasting 3–7 days. Hormone levels are low, which may cause cramping, fatigue, and mood shifts.",
      benefit:
          "Gentle movement can improve circulation, reduce discomfort, and boost mood naturally.",
      suggestedExercises: [
        "Light Walking",
        "Gentle Yoga",
        "Stretching",
        "Breathing Exercises",
        "Foam Rolling",
      ],
      videoLinks: {
        "Light Walking": "https://www.youtube.com/watch?v=_EIZxRf6pEw",
        "Gentle Yoga": "https://www.youtube.com/watch?v=HGBakyNJhU0",
        "Stretching": "https://www.youtube.com/watch?v=qaPP2wWcYhM&t=1s",
        "Breathing Exercises":
            "https://www.youtube.com/watch?v=xVTGU4de8Ik&t=60s",
        "Foam Rolling": "https://www.youtube.com/watch?v=0KmwOIUCjPs",
      },
    ),
    "Follicular": ExerciseRecommendation(
      title: "Follicular Phase",
      description:
          "This phase starts after menstruation and ends before ovulation. Estrogen rises and boosts energy, strength, and mood.",
      benefit:
          "A great time to focus on performance, muscle building, and cardio as strength peaks.",
      suggestedExercises: [
        "Running or Jogging",
        "HIIT",
        "Weight Training",
        "Dance Workouts",
        "Cycling",
      ],
      videoLinks: {
        "Running or Jogging": "https://www.youtube.com/watch?v=aczynOXAl0E",
        "HIIT": "https://www.youtube.com/watch?v=vFai116E69M",
        "Weight Training": "https://www.youtube.com/watch?v=U0bhE67HuDY",
        "Dance Workouts": "https://www.youtube.com/watch?v=VaoV1PrYft4",
        "Cycling": "https://www.youtube.com/watch?v=-7xvqQeoA8c",
      },
    ),
    "Ovulation": ExerciseRecommendation(
      title: "Ovulation Phase",
      description:
          "Mid-cycle, ovulation brings peak physical and emotional energy. You may feel confident and powerful.",
      benefit:
          "Maximize endurance and strength. Best time for intense workouts.",
      suggestedExercises: [
        "Sprinting",
        "CrossFit",
        "Powerlifting",
        "Team Sports",
      ],
      videoLinks: {
        "Sprinting": "https://www.youtube.com/watch?v=4rFPN-JZrW4",
        "CrossFit": "https://www.youtube.com/watch?v=5t08CLczdK4",
        "Powerlifting": "https://www.youtube.com/watch?v=sQ_fH0dfktE",
        "Some Sports": "https://www.youtube.com/watch?v=mt7Miwj3elA",
      },
    ),
    "Luteal": ExerciseRecommendation(
      title: "Luteal Phase",
      description:
          "After ovulation, progesterone rises. You might feel tired or experience PMS symptoms like bloating or irritability.",
      benefit:
          "Focus on low-impact exercise to balance mood, manage fatigue, and reduce stress.",
      suggestedExercises: [
        "Yoga (restorative)",
        "Pilates",
        "Walking",
        "Swimming",
        "Low-impact Cardio",
      ],
      videoLinks: {
        "Yoga (restorative)": "https://www.youtube.com/watch?v=IX0QcvZVJ-c",
        "Pilates": "https://www.youtube.com/watch?v=lCg_gh_fppI",
        "Walking": "https://www.youtube.com/watch?v=IUN7N0wPC1o",
        "Swimming": "https://www.youtube.com/watch?v=QGONkbRQdf4",
        "Low-impact Cardio": "https://www.youtube.com/watch?v=ml6cT4AZdqI",
      },
    ),
  };
}
