import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pression_tracker/l10n/app_localizations.dart';
import 'package:pression_tracker/screens/help_screen.dart';

Widget _app(Locale locale) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const HelpScreen(),
);

void main() {
  testWidgets('help screen is shown in English', (tester) async {
    await tester.pumpWidget(_app(const Locale('en')));
    expect(find.text('How it works'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Normal'), 200);
    expect(find.text('Normal'), findsOneWidget);
  });

  testWidgets('help screen is shown in Italian', (tester) async {
    await tester.pumpWidget(_app(const Locale('it')));
    expect(find.text('Come funziona'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Crisi ipertensiva'), 200);
    expect(find.text('Normale'), findsOneWidget);
    expect(find.text('Crisi ipertensiva'), findsOneWidget);
  });
}
