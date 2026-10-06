import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/bp_category.dart';
import '../theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(title: Text(l.help)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(l.helpIntro, style: theme.textTheme.bodyLarge),
            ),
            _Section(Icons.photo_camera, l.helpStep1Title, l.helpStep1Body),
            _Section(Icons.fact_check, l.helpStep2Title, l.helpStep2Body),
            _Section(Icons.list_alt, l.helpStep3Title, l.helpStep3Body),
            _Section(Icons.show_chart, l.helpStep4Title, l.helpStep4Body),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.helpCategoriesTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final c in BpCategory.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 6, backgroundColor: c.color),
                            const SizedBox(width: 10),
                            Expanded(child: Text(c.label(l))),
                            Text(c.range(l)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _Section(
              Icons.people_outline,
              l.helpProfilesTitle,
              l.helpProfilesBody,
            ),
            _Section(Icons.lock_outline, l.helpPrivacyTitle, l.helpPrivacyBody),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                l.helpDisclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
