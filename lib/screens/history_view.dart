import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/reading_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/bp_category.dart';
import '../models/reading.dart';
import 'reading_form_screen.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key, required this.repository});

  final ReadingRepository repository;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Reading>>(
      valueListenable: repository.readings,
      builder: (context, readings, _) {
        if (readings.isEmpty) return const _EmptyState();
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
          itemCount: readings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, i) => _ReadingTile(
            reading: readings[i],
            // List is newest first, so the previous reading is the next item.
            previous: i + 1 < readings.length ? readings[i + 1] : null,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReadingFormScreen(
                  repository: repository,
                  existing: readings[i],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.reading, this.previous, this.onTap});

  final Reading reading;
  final Reading? previous;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final category = BpCategory.of(reading.systolic, reading.diastolic);
    final prev = previous;
    final when = DateFormat.yMMMd(l.localeName)
        .add_Hm()
        .format(reading.timestamp);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 52,
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${reading.systolic}/${reading.diastolic}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('mmHg', style: theme.textTheme.bodySmall),
                        if (reading.pulse != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${reading.pulse}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$when · ${category.label(l)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (reading.note != null)
                      Text(
                        reading.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (prev != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    DeltaText(reading.systolic - prev.systolic),
                    DeltaText(reading.diastolic - prev.diastolic),
                  ],
                ),
              if (reading.imagePath != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.photo_outlined,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a change such as "▲ 5" (higher pressure, red) or "▼ 3" (green).
class DeltaText extends StatelessWidget {
  const DeltaText(this.delta, {super.key, this.style});

  final num delta;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.labelLarge;
    final rounded = delta.round();
    if (rounded == 0) {
      return Text('= 0', style: base?.copyWith(color: Colors.grey));
    }
    final up = rounded > 0;
    return Text(
      '${up ? '▲' : '▼'} ${rounded.abs()}',
      style: base?.copyWith(
        color: up ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(l.noReadingsTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l.noReadingsBody, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
