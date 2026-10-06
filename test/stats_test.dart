import 'package:flutter_test/flutter_test.dart';
import 'package:pression_tracker/models/bp_category.dart';
import 'package:pression_tracker/models/reading.dart';
import 'package:pression_tracker/services/stats.dart';

Reading _r(DateTime t, int sys, int dia, [int? pulse]) =>
    Reading(timestamp: t, systolic: sys, diastolic: dia, pulse: pulse);

void main() {
  test('BpCategory follows ACC/AHA thresholds', () {
    expect(BpCategory.of(115, 75), BpCategory.normal);
    expect(BpCategory.of(125, 78), BpCategory.elevated);
    expect(BpCategory.of(132, 70), BpCategory.stage1);
    expect(BpCategory.of(118, 85), BpCategory.stage1);
    expect(BpCategory.of(145, 85), BpCategory.stage2);
    expect(BpCategory.of(185, 100), BpCategory.crisis);
  });

  group('ranges and averages', () {
    final now = DateTime(2026, 10, 6, 12);
    final readings = [
      _r(now.subtract(const Duration(days: 1)), 120, 80, 70),
      _r(now.subtract(const Duration(days: 5)), 130, 90),
      _r(now.subtract(const Duration(days: 10)), 140, 95, 80),
    ];

    test('filterRange keeps only the selected period', () {
      expect(filterRange(readings, TrendRange.days7, now).length, 2);
      expect(filterRange(readings, TrendRange.all, now).length, 3);
    });

    test('previousPeriod returns the period before', () {
      final prev = previousPeriod(readings, TrendRange.days7, now);
      expect(prev.single.systolic, 140);
      expect(previousPeriod(readings, TrendRange.all, now), isEmpty);
    });

    test('Averages ignore missing pulse', () {
      final avg = Averages.of(filterRange(readings, TrendRange.days7, now));
      expect(avg.count, 2);
      expect(avg.systolic, 125);
      expect(avg.diastolic, 85);
      expect(avg.pulse, 70);
    });
  });
}
