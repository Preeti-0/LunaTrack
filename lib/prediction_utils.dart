// lib/prediction_utils.dart

DateTime? getLastPeriodDate(List<DateTime> periods) {
  if (periods.isEmpty) return null;
  final today = DateTime.now();

  // Sort in descending order (latest first)
  periods.sort((a, b) => b.compareTo(a));

  // Return the latest valid date not in the future
  for (final date in periods) {
    if (!date.isAfter(today)) {
      return date;
    }
  }
  return null;
}

int calculateCycleDay(DateTime lastPeriod) {
  final today = DateTime.now();
  return today.difference(lastPeriod).inDays + 1;
}

DateTime getNextPeriodDate(DateTime lastPeriod, int cycleLength) {
  return lastPeriod.add(Duration(days: cycleLength));
}

DateTime getOvulationDate(DateTime lastPeriod, int cycleLength) {
  // Ovulation is ~14 days before next period
  return lastPeriod.add(Duration(days: cycleLength - 14));
}

List<DateTime> getFertileWindow(DateTime ovulationDate) {
  // Fertile window = 6 days before ovulation, ending on ovulation day
  return List.generate(
    7,
    (index) => ovulationDate.subtract(Duration(days: 5 - index)),
  );
}
