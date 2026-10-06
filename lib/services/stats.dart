import '../models/reading.dart';

enum TrendRange {
  days7(Duration(days: 7)),
  days30(Duration(days: 30)),
  days90(Duration(days: 90)),
  all(null);

  final Duration? duration;

  const TrendRange(this.duration);
}

/// Readings within [range] ending at [now].
List<Reading> filterRange(
  List<Reading> readings,
  TrendRange range,
  DateTime now,
) {
  final d = range.duration;
  if (d == null) return readings;
  final start = now.subtract(d);
  return readings.where((r) => r.timestamp.isAfter(start)).toList();
}

/// Readings in the equally long period immediately before [range].
List<Reading> previousPeriod(
  List<Reading> readings,
  TrendRange range,
  DateTime now,
) {
  final d = range.duration;
  if (d == null) return const [];
  final end = now.subtract(d);
  final start = end.subtract(d);
  return readings
      .where((r) => r.timestamp.isAfter(start) && !r.timestamp.isAfter(end))
      .toList();
}

class Averages {
  final int count;
  final double? systolic;
  final double? diastolic;
  final double? pulse;

  const Averages(this.count, this.systolic, this.diastolic, this.pulse);

  factory Averages.of(List<Reading> readings) {
    if (readings.isEmpty) return const Averages(0, null, null, null);
    double mean(Iterable<int> v) => v.reduce((a, b) => a + b) / v.length;
    final pulses = readings.map((r) => r.pulse).whereType<int>();
    return Averages(
      readings.length,
      mean(readings.map((r) => r.systolic)),
      mean(readings.map((r) => r.diastolic)),
      pulses.isEmpty ? null : mean(pulses),
    );
  }
}
