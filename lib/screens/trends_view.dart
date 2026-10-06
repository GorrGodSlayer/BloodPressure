import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/reading_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/bp_category.dart';
import '../models/reading.dart';
import '../services/stats.dart';
import 'history_view.dart';

const _sysColor = Color(0xFFC62828);
const _diaColor = Color(0xFF1565C0);
const _pulseColor = Color(0xFF8A8A8A);

class TrendsView extends StatefulWidget {
  const TrendsView({super.key, required this.repository});

  final ReadingRepository repository;

  @override
  State<TrendsView> createState() => _TrendsViewState();
}

class _TrendsViewState extends State<TrendsView> {
  TrendRange _range = TrendRange.days30;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ValueListenableBuilder<List<Reading>>(
      valueListenable: widget.repository.readings,
      builder: (context, readings, _) {
        if (readings.isEmpty) {
          return Center(child: Text(l.addReadingsForTrends));
        }
        final now = DateTime.now();
        final current = filterRange(readings, _range, now);
        final previous = previousPeriod(readings, _range, now);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            SegmentedButton<TrendRange>(
              segments: [
                for (final r in TrendRange.values)
                  ButtonSegment(value: r, label: Text(rangeLabel(l, r))),
              ],
              selected: {_range},
              onSelectionChanged: (s) => setState(() => _range = s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 16),
            if (current.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text(l.noReadingsInPeriod)),
              )
            else ...[
              _AverageCard(
                avg: Averages.of(current),
                prevAvg: Averages.of(previous),
                range: _range,
              ),
              const SizedBox(height: 12),
              _ChartCard(readings: current),
              const SizedBox(height: 12),
              _CategoryCard(readings: current),
            ],
          ],
        );
      },
    );
  }
}

String rangeLabel(AppLocalizations l, TrendRange range) => switch (range) {
  TrendRange.days7 => l.range7,
  TrendRange.days30 => l.range30,
  TrendRange.days90 => l.range90,
  TrendRange.all => l.rangeAll,
};

class _AverageCard extends StatelessWidget {
  const _AverageCard({
    required this.avg,
    required this.prevAvg,
    required this.range,
  });

  final Averages avg;
  final Averages prevAvg;
  final TrendRange range;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasPrev = prevAvg.count > 0;

    Widget stat(String label, double? value, double? prev, String unit) {
      return Expanded(
        child: Column(
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            Text(
              value == null ? '–' : value.round().toString(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(unit, style: theme.textTheme.bodySmall),
            if (hasPrev && value != null && prev != null)
              DeltaText(value - prev),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.averageCount(avg.count), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                stat(l.systolic, avg.systolic, prevAvg.systolic, 'mmHg'),
                stat(l.diastolic, avg.diastolic, prevAvg.diastolic, 'mmHg'),
                stat(l.pulse, avg.pulse, prevAvg.pulse, 'bpm'),
              ],
            ),
            if (hasPrev) ...[
              const SizedBox(height: 8),
              Text(
                l.comparePrevious(rangeLabel(l, range)),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.readings});

  /// Newest first.
  final List<Reading> readings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ordered = readings.reversed.toList();

    double x(Reading r) => r.timestamp.millisecondsSinceEpoch.toDouble();
    var minX = x(ordered.first);
    var maxX = x(ordered.last);
    const day = 86400000.0;
    if (maxX - minX < day) {
      minX -= day / 2;
      maxX += day / 2;
    }

    final values = [
      for (final r in ordered) ...[
        r.systolic,
        r.diastolic,
        if (r.pulse != null) r.pulse!,
      ],
    ];
    final minY = (math.min(values.reduce(math.min), 60) / 10).floor() * 10.0;
    final maxY = (math.max(values.reduce(math.max), 140) / 10).ceil() * 10.0;
    final spanDays = (maxX - minX) / day;
    final dateFormat = spanDays > 60
        ? DateFormat.MMMd(l.localeName)
        : DateFormat.Md(l.localeName);

    LineChartBarData line(
      List<FlSpot> spots,
      Color color, {
      bool dashed = false,
    }) => LineChartBarData(
      spots: spots,
      color: color,
      barWidth: dashed ? 1.5 : 2.5,
      dashArray: dashed ? [4, 4] : null,
      dotData: FlDotData(show: spots.length <= 40),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          children: [
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    line([
                      for (final r in ordered)
                        FlSpot(x(r), r.systolic.toDouble()),
                    ], _sysColor),
                    line([
                      for (final r in ordered)
                        FlSpot(x(r), r.diastolic.toDouble()),
                    ], _diaColor),
                    line(
                      [
                        for (final r in ordered)
                          if (r.pulse != null)
                            FlSpot(x(r), r.pulse!.toDouble()),
                      ],
                      _pulseColor,
                      dashed: true,
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 120,
                        color: _sysColor.withValues(alpha: 0.35),
                        strokeWidth: 1,
                        dashArray: [2, 4],
                      ),
                      HorizontalLine(
                        y: 80,
                        color: _diaColor.withValues(alpha: 0.35),
                        strokeWidth: 1,
                        dashArray: [2, 4],
                      ),
                    ],
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.4),
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 36,
                        getTitlesWidget: (v, meta) => Text(
                          v.toInt().toString(),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: (maxX - minX) / 4,
                        getTitlesWidget: (v, meta) {
                          if (v == meta.min || v == meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              dateFormat.format(
                                DateTime.fromMillisecondsSinceEpoch(v.toInt()),
                              ),
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => [
                        for (final s in spots)
                          LineTooltipItem(
                            '${s.y.toInt()}',
                            TextStyle(
                              color: s.bar.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                _Legend(color: _sysColor, label: l.systolic),
                _Legend(color: _diaColor, label: l.diastolic),
                _Legend(color: _pulseColor, label: l.pulse),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 3, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.readings});

  final List<Reading> readings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final counts = {for (final c in BpCategory.values) c: 0};
    for (final r in readings) {
      counts.update(BpCategory.of(r.systolic, r.diastolic), (n) => n + 1);
    }
    final total = readings.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.readingsByCategory, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  for (final e in counts.entries)
                    if (e.value > 0)
                      Expanded(
                        flex: e.value,
                        child: Container(height: 12, color: e.key.color),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final e in counts.entries)
              if (e.value > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 5, backgroundColor: e.key.color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.key.label(l))),
                      Text('${e.value} · ${(100 * e.value / total).round()}%'),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            Text(l.categoryDisclaimer, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
