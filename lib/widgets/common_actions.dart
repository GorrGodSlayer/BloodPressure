import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';
import '../screens/help_screen.dart';

/// Small "Made by" credit line.
class CreditText extends StatelessWidget {
  const CreditText({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        AppLocalizations.of(context).madeBy,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The "?" button that opens the help screen.
class HelpButton extends StatelessWidget {
  const HelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: AppLocalizations.of(context).help,
      onPressed: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const HelpScreen())),
    );
  }
}

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.translate),
      tooltip: AppLocalizations.of(context).language,
      onPressed: () => showLanguageDialog(context, controller),
    );
  }
}

Future<void> showLanguageDialog(
  BuildContext context,
  AppController controller,
) async {
  final l = AppLocalizations.of(context);
  final current = controller.settings.localeCode ?? '';
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l.language),
      children: [
        for (final (code, label) in [
          ('', l.systemLanguage),
          ('en', 'English'),
          ('it', 'Italiano'),
        ])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, code),
            child: Row(
              children: [
                Icon(
                  code == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(label),
              ],
            ),
          ),
      ],
    ),
  );
  if (choice != null) {
    await controller.setLocale(choice.isEmpty ? null : choice);
  }
}
