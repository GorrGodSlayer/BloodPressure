import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'data/app_store.dart';
import 'data/settings.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/profile_form_screen.dart';
import 'screens/profile_picker_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(
    await AppStore.open(),
    await Settings.load(),
  );
  await controller.restoreSession();
  runApp(PressionTrackerApp(controller: controller));
}

class PressionTrackerApp extends StatelessWidget {
  const PressionTrackerApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final profiles = controller.store.profiles.profiles;
    return ListenableBuilder(
      listenable: Listenable.merge([controller, profiles]),
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: controller.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _home(profiles.value.isEmpty),
      ),
    );
  }

  Widget _home(bool noProfiles) {
    final profile = controller.profile;
    if (profile != null) {
      return HomeScreen(key: ValueKey(profile.id), controller: controller);
    }
    if (noProfiles) return ProfileFormScreen(controller: controller);
    return ProfilePickerScreen(controller: controller);
  }
}
