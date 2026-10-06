import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_controller.dart';
import '../data/reading_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/profile.dart';
import '../services/bp_parser.dart';
import '../services/ocr_service.dart';
import '../theme.dart';
import '../widgets/common_actions.dart';
import 'history_view.dart';
import 'profile_form_screen.dart';
import 'profile_picker_screen.dart';
import 'reading_form_screen.dart';
import 'trends_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ocr = OcrService();
  final _picker = ImagePicker();
  int _tab = 0;

  ReadingRepository get _repository => widget.controller.readings!;

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _newReading() async {
    final l = AppLocalizations.of(context);
    final source = await showModalBottomSheet<_Source>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l.takePhoto),
              onTap: () => Navigator.pop(context, _Source.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l.choosePhoto),
              onTap: () => Navigator.pop(context, _Source.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l.enterManually),
              onTap: () => Navigator.pop(context, _Source.manual),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    String? imagePath;
    var parsed = const ParsedReading();

    if (source != _Source.manual) {
      final image = await _picker.pickImage(
        source: source == _Source.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 2400,
        imageQuality: 90,
      );
      if (image == null || !mounted) return;
      imagePath = image.path;

      _showBusy(l.readingDisplay);
      try {
        parsed = await _ocr.readMonitor(imagePath);
      } catch (e) {
        debugPrint('OCR failed: $e');
      } finally {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadingFormScreen(
          repository: _repository,
          imagePath: imagePath,
          parsed: imagePath == null ? null : parsed,
        ),
      ),
    );
  }

  void _showBusy(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAccount(Profile profile) async {
    final l = AppLocalizations.of(context);
    final people = widget.controller.store.profiles.profiles.value;
    // Either another Profile to switch to, or an _AccountAction.
    final result = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Text(
                    l.peopleOnDevice,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                for (final p in people)
                  ListTile(
                    leading: CircleAvatar(child: Text(p.initial)),
                    title: Text(p.name),
                    subtitle: Text(
                      p.id == profile.id
                          ? '${l.viewingNow} · ${l.readingsCount(_repository.readings.value.length)}'
                          : (p.birthYear == null
                                ? l.tapToSwitch
                                : l.bornIn(p.birthYear.toString())),
                    ),
                    selected: p.id == profile.id,
                    trailing: p.id == profile.id
                        ? const Icon(Icons.check_circle)
                        : (p.hasPin ? const Icon(Icons.lock_outline) : null),
                    onTap: p.id == profile.id
                        ? null
                        : () => Navigator.pop(context, p),
                  ),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_add_alt),
                  ),
                  title: Text(l.addProfile),
                  onTap: () => Navigator.pop(context, _AccountAction.add),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l.editProfile),
                  onTap: () => Navigator.pop(context, _AccountAction.edit),
                ),
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(l.language),
                  onTap: () => Navigator.pop(context, _AccountAction.language),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(l.deleteProfile),
                  onTap: () => Navigator.pop(context, _AccountAction.delete),
                ),
                const Center(child: CreditText()),
              ],
            ),
          ),
        );
      },
    );
    if (result == null || !mounted) return;

    if (result is Profile) {
      if (result.hasPin &&
          !await showPinDialog(context, widget.controller, result)) {
        return;
      }
      await widget.controller.signIn(result);
      return;
    }

    switch (result as _AccountAction) {
      case _AccountAction.add:
        final added = await Navigator.of(context).push<Profile>(
          MaterialPageRoute(
            builder: (_) => ProfileFormScreen(controller: widget.controller),
          ),
        );
        if (added != null) await widget.controller.signIn(added);
      case _AccountAction.edit:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfileFormScreen(
              controller: widget.controller,
              existing: profile,
            ),
          ),
        );
      case _AccountAction.language:
        await showLanguageDialog(context, widget.controller);
      case _AccountAction.delete:
        await _confirmDelete(profile);
    }
  }

  Future<void> _confirmDelete(Profile profile) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteProfileTitle(profile.name)),
        content: Text(l.deleteProfileBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.controller.deleteProfile(profile);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final profile = widget.controller.profile!;
    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tab == 0 ? l.history : l.trends),
          actions: [
            const HelpButton(),
            Tooltip(
              message: l.account,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: ActionChip(
                  avatar: CircleAvatar(child: Text(profile.initial)),
                  label: Text(profile.name, overflow: TextOverflow.ellipsis),
                  onPressed: () => _showAccount(profile),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: [
            HistoryView(repository: _repository),
            TrendsView(repository: _repository),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _newReading,
          icon: const Icon(Icons.photo_camera),
          label: Text(l.newReading),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.list_alt),
              label: l.history,
            ),
            NavigationDestination(
              icon: const Icon(Icons.show_chart),
              label: l.trends,
            ),
          ],
        ),
      ),
    );
  }
}

enum _Source { camera, gallery, manual }

enum _AccountAction { add, edit, language, delete }
