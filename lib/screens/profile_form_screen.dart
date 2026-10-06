import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/profile.dart';
import '../theme.dart';
import '../widgets/common_actions.dart';

/// Creates a profile (first launch or "Add profile") or edits one.
///
/// When pushed, pops with the saved [Profile]. As the root screen on first
/// launch it signs the new profile in directly.
class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key, required this.controller, this.existing});

  final AppController controller;
  final Profile? existing;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _year = TextEditingController(
    text: widget.existing?.birthYear?.toString(),
  );
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  late bool _pinEnabled = widget.existing?.hasPin ?? false;
  bool _saving = false;

  bool get _hadPin => widget.existing?.hasPin ?? false;

  @override
  void dispose() {
    for (final c in [_name, _year, _pin, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = widget.controller.store.profiles;
    final year = int.tryParse(_year.text);
    final existing = widget.existing;
    final Profile profile;
    if (existing == null) {
      profile = await repo.create(
        name: _name.text,
        birthYear: year,
        pin: _pinEnabled ? _pin.text : null,
      );
    } else {
      // null keeps the PIN, '' removes it.
      final String? pin = !_pinEnabled
          ? (_hadPin ? '' : null)
          : (_pin.text.isEmpty ? null : _pin.text);
      profile = await repo.update(
        existing,
        name: _name.text,
        birthYear: year,
        pin: pin,
      );
      widget.controller.profileUpdated(profile);
    }

    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context, profile);
    } else {
      await widget.controller.signIn(profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final firstRun = widget.existing == null && !Navigator.canPop(context);
    final title = widget.existing != null
        ? l.editProfile
        : (firstRun ? l.welcomeTitle : l.addProfile);

    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            const HelpButton(),
            LanguageButton(controller: widget.controller),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (firstRun) ...[
                Icon(
                  Icons.monitor_heart_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  l.welcomeBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
              ],
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l.name,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _year,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: l.birthYearOptional,
                  prefixIcon: const Icon(Icons.cake_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final year = int.tryParse(v);
                  final now = DateTime.now().year;
                  return year == null || year < 1900 || year > now
                      ? l.invalidYear
                      : null;
                },
              ),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.lock_outline),
                  title: Text(l.pinLock),
                  subtitle: Text(l.pinLockHint),
                  value: _pinEnabled,
                  onChanged: (v) => setState(() => _pinEnabled = v),
                ),
              ),
              if (_pinEnabled) ...[
                const SizedBox(height: 8),
                _pinField(_pin, _hadPin ? l.newPinOptional : l.pin, (v) {
                  if ((v == null || v.isEmpty) && _hadPin) return null;
                  return v == null || v.length < 4 ? l.pinTooShort : null;
                }),
                const SizedBox(height: 12),
                _pinField(
                  _confirm,
                  l.confirmPin,
                  (v) => v != _pin.text ? l.pinMismatch : null,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(widget.existing == null ? l.createProfile : l.save),
              ),
              const SizedBox(height: 16),
              const CreditText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pinField(
    TextEditingController controller,
    String label,
    String? Function(String?) validator,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.pin_outlined),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
