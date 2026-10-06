// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pression Tracker';

  @override
  String get history => 'History';

  @override
  String get trends => 'Trends';

  @override
  String get newReading => 'New reading';

  @override
  String get takePhoto => 'Take a photo of the monitor';

  @override
  String get choosePhoto => 'Choose a photo';

  @override
  String get enterManually => 'Enter manually';

  @override
  String get readingDisplay => 'Reading the display…';

  @override
  String get editReading => 'Edit reading';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get deleteReadingTitle => 'Delete this reading?';

  @override
  String get deleteReadingBody => 'The reading and its photo will be removed.';

  @override
  String get required => 'Required';

  @override
  String rangeError(String min, String max) {
    return '$min–$max';
  }

  @override
  String get photoUnavailable => 'Photo unavailable';

  @override
  String get ocrIncomplete =>
      'Could not read every value from the photo. Please fill in the missing numbers.';

  @override
  String get ocrComplete =>
      'Values read from the photo. Check them against the display before saving.';

  @override
  String get systolic => 'Systolic';

  @override
  String get diastolic => 'Diastolic';

  @override
  String get pulse => 'Pulse';

  @override
  String get pulseOptional => 'Pulse (optional)';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get noteHint => 'e.g. after coffee, left arm, before medication';

  @override
  String get noReadingsTitle => 'No readings yet';

  @override
  String get noReadingsBody =>
      'Tap \"New reading\" and take a photo of your blood pressure monitor. The values are read automatically and you can correct them before saving.';

  @override
  String get addReadingsForTrends => 'Add readings to see trends.';

  @override
  String get noReadingsInPeriod => 'No readings in this period.';

  @override
  String averageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Average · $count readings',
      one: 'Average · 1 reading',
    );
    return '$_temp0';
  }

  @override
  String comparePrevious(String period) {
    return 'Arrows compare with the previous $period.';
  }

  @override
  String get range7 => '7 days';

  @override
  String get range30 => '30 days';

  @override
  String get range90 => '90 days';

  @override
  String get rangeAll => 'All';

  @override
  String get readingsByCategory => 'Readings by category';

  @override
  String get categoryDisclaimer =>
      'Categories follow the ACC/AHA guideline and are for information only. Talk to your doctor about your readings.';

  @override
  String get catNormal => 'Normal';

  @override
  String get catElevated => 'Elevated';

  @override
  String get catStage1 => 'High – Stage 1';

  @override
  String get catStage2 => 'High – Stage 2';

  @override
  String get catCrisis => 'Hypertensive crisis';

  @override
  String get catNormalRange => '< 120 and < 80';

  @override
  String get catElevatedRange => '120–129 and < 80';

  @override
  String get catStage1Range => '130–139 or 80–89';

  @override
  String get catStage2Range => '≥ 140 or ≥ 90';

  @override
  String get catCrisisRange => '> 180 or > 120';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get welcomeBody =>
      'Create a profile to start tracking your blood pressure. Each person using this phone can have their own profile.';

  @override
  String get createProfile => 'Create profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get addProfile => 'Add person';

  @override
  String get peopleOnDevice => 'People on this device';

  @override
  String get viewingNow => 'Viewing now';

  @override
  String get tapToSwitch => 'Tap to switch';

  @override
  String get whoIsMeasuring => 'Who is measuring?';

  @override
  String get name => 'Name';

  @override
  String get birthYearOptional => 'Birth year (optional)';

  @override
  String get invalidYear => 'Enter a valid year';

  @override
  String get pinLock => 'Protect with a PIN';

  @override
  String get pinLockHint => 'The PIN is asked when opening this profile.';

  @override
  String get pin => 'PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get newPinOptional => 'New PIN (leave empty to keep the current one)';

  @override
  String get pinTooShort => 'Use 4 to 8 digits';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String enterPin(String name) {
    return 'Enter the PIN for $name';
  }

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String get unlock => 'Unlock';

  @override
  String get switchProfile => 'Switch profile';

  @override
  String get deleteProfile => 'Delete profile';

  @override
  String deleteProfileTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteProfileBody =>
      'This permanently deletes the profile and all its readings and photos.';

  @override
  String bornIn(String year) {
    return 'Born in $year';
  }

  @override
  String readingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count readings',
      one: '1 reading',
      zero: 'No readings',
    );
    return '$_temp0';
  }

  @override
  String get account => 'Account';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System default';

  @override
  String get help => 'How it works';

  @override
  String get helpIntro =>
      'Pression Tracker reads your blood pressure monitor from a photo and keeps a history of your measurements.';

  @override
  String get helpStep1Title => '1. Take a photo';

  @override
  String get helpStep1Body =>
      'Tap \"New reading\" and photograph the monitor display. For the best results use good light, hold the phone straight in front of the screen, fill the frame with the display and avoid reflections.';

  @override
  String get helpStep2Title => '2. Check the values';

  @override
  String get helpStep2Body =>
      'Systolic, diastolic and pulse are read automatically. LCD digits can be misread, so compare the numbers with the display and correct them if needed. You can also change the date and time or add a note.';

  @override
  String get helpStep3Title => '3. History';

  @override
  String get helpStep3Body =>
      'Every reading is listed with its category colour. The arrows show the change from the previous reading: a red ▲ means higher, a green ▼ means lower. Tap a reading to edit or delete it.';

  @override
  String get helpStep4Title => '4. Trends';

  @override
  String get helpStep4Body =>
      'Choose a period to see the average values, a chart over time and how many readings fall into each category. The arrows compare the averages with the period before.';

  @override
  String get helpCategoriesTitle => 'Blood pressure categories (mmHg)';

  @override
  String get helpProfilesTitle => 'Profiles';

  @override
  String get helpProfilesBody =>
      'Every family member can have their own profile with separate readings, history and trends. Tap the name at the top right to switch to another person, add a new one, edit or delete a profile, or change the language. Add a PIN to keep a profile private.';

  @override
  String get helpPrivacyTitle => 'Privacy';

  @override
  String get helpPrivacyBody =>
      'Everything stays on this phone: photos are read on the device and no data is sent anywhere.';

  @override
  String get madeBy => 'Made by Alex Rogatski';

  @override
  String get helpDisclaimer =>
      'This app is not a medical device and does not replace the advice of your doctor.';
}
