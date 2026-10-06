import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/profile.dart';
import '../theme.dart';
import '../widgets/common_actions.dart';
import 'profile_form_screen.dart';

/// "Who is measuring?" — lists the profiles on this device.
class ProfilePickerScreen extends StatelessWidget {
  const ProfilePickerScreen({super.key, required this.controller});

  final AppController controller;

  Future<void> _open(BuildContext context, Profile profile) async {
    if (profile.hasPin && !await showPinDialog(context, controller, profile)) {
      return;
    }
    await controller.signIn(profile);
  }

  Future<void> _add(BuildContext context) async {
    final profile = await Navigator.of(context).push<Profile>(
      MaterialPageRoute(
        builder: (_) => ProfileFormScreen(controller: controller),
      ),
    );
    if (profile != null) await controller.signIn(profile);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.whoIsMeasuring),
          actions: [
            const HelpButton(),
            LanguageButton(controller: controller),
          ],
        ),
        body: ValueListenableBuilder<List<Profile>>(
          valueListenable: controller.store.profiles.profiles,
          builder: (context, profiles, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final p in profiles)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(p.initial)),
                    title: Text(p.name),
                    subtitle: p.birthYear == null
                        ? null
                        : Text(l.bornIn(p.birthYear.toString())),
                    trailing: Icon(
                      p.hasPin ? Icons.lock_outline : Icons.chevron_right,
                    ),
                    onTap: () => _open(context, p),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _add(context),
                icon: const Icon(Icons.person_add_alt),
                label: Text(l.addProfile),
              ),
              const SizedBox(height: 16),
              const CreditText(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks for the profile PIN; true when it was entered correctly.
Future<bool> showPinDialog(
  BuildContext context,
  AppController controller,
  Profile profile,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _PinDialog(controller: controller, profile: profile),
  );
  return ok ?? false;
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.controller, required this.profile});

  final AppController controller;
  final Profile profile;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _check() {
    if (widget.controller.store.profiles.verifyPin(widget.profile, _pin.text)) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = AppLocalizations.of(context).wrongPin);
      _pin.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.enterPin(widget.profile.name)),
      content: TextField(
        controller: _pin,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
        ],
        decoration: InputDecoration(labelText: l.pin, errorText: _error),
        onSubmitted: (_) => _check(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(onPressed: _check, child: Text(l.unlock)),
      ],
    );
  }
}
