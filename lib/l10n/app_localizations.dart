import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Pression Tracker'**
  String get appTitle;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trends;

  /// No description provided for @newReading.
  ///
  /// In en, this message translates to:
  /// **'New reading'**
  String get newReading;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the monitor'**
  String get takePhoto;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get choosePhoto;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get enterManually;

  /// No description provided for @readingDisplay.
  ///
  /// In en, this message translates to:
  /// **'Reading the display…'**
  String get readingDisplay;

  /// No description provided for @editReading.
  ///
  /// In en, this message translates to:
  /// **'Edit reading'**
  String get editReading;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this reading?'**
  String get deleteReadingTitle;

  /// No description provided for @deleteReadingBody.
  ///
  /// In en, this message translates to:
  /// **'The reading and its photo will be removed.'**
  String get deleteReadingBody;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @rangeError.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max}'**
  String rangeError(String min, String max);

  /// No description provided for @photoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable'**
  String get photoUnavailable;

  /// No description provided for @ocrIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Could not read every value from the photo. Please fill in the missing numbers.'**
  String get ocrIncomplete;

  /// No description provided for @ocrComplete.
  ///
  /// In en, this message translates to:
  /// **'Values read from the photo. Check them against the display before saving.'**
  String get ocrComplete;

  /// No description provided for @systolic.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get systolic;

  /// No description provided for @diastolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get diastolic;

  /// No description provided for @pulse.
  ///
  /// In en, this message translates to:
  /// **'Pulse'**
  String get pulse;

  /// No description provided for @pulseOptional.
  ///
  /// In en, this message translates to:
  /// **'Pulse (optional)'**
  String get pulseOptional;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. after coffee, left arm, before medication'**
  String get noteHint;

  /// No description provided for @noReadingsTitle.
  ///
  /// In en, this message translates to:
  /// **'No readings yet'**
  String get noReadingsTitle;

  /// No description provided for @noReadingsBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New reading\" and take a photo of your blood pressure monitor. The values are read automatically and you can correct them before saving.'**
  String get noReadingsBody;

  /// No description provided for @addReadingsForTrends.
  ///
  /// In en, this message translates to:
  /// **'Add readings to see trends.'**
  String get addReadingsForTrends;

  /// No description provided for @noReadingsInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No readings in this period.'**
  String get noReadingsInPeriod;

  /// No description provided for @averageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Average · 1 reading} other{Average · {count} readings}}'**
  String averageCount(int count);

  /// No description provided for @comparePrevious.
  ///
  /// In en, this message translates to:
  /// **'Arrows compare with the previous {period}.'**
  String comparePrevious(String period);

  /// No description provided for @range7.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get range7;

  /// No description provided for @range30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get range30;

  /// No description provided for @range90.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get range90;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get rangeAll;

  /// No description provided for @readingsByCategory.
  ///
  /// In en, this message translates to:
  /// **'Readings by category'**
  String get readingsByCategory;

  /// No description provided for @categoryDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Categories follow the ACC/AHA guideline and are for information only. Talk to your doctor about your readings.'**
  String get categoryDisclaimer;

  /// No description provided for @catNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get catNormal;

  /// No description provided for @catElevated.
  ///
  /// In en, this message translates to:
  /// **'Elevated'**
  String get catElevated;

  /// No description provided for @catStage1.
  ///
  /// In en, this message translates to:
  /// **'High – Stage 1'**
  String get catStage1;

  /// No description provided for @catStage2.
  ///
  /// In en, this message translates to:
  /// **'High – Stage 2'**
  String get catStage2;

  /// No description provided for @catCrisis.
  ///
  /// In en, this message translates to:
  /// **'Hypertensive crisis'**
  String get catCrisis;

  /// No description provided for @catNormalRange.
  ///
  /// In en, this message translates to:
  /// **'< 120 and < 80'**
  String get catNormalRange;

  /// No description provided for @catElevatedRange.
  ///
  /// In en, this message translates to:
  /// **'120–129 and < 80'**
  String get catElevatedRange;

  /// No description provided for @catStage1Range.
  ///
  /// In en, this message translates to:
  /// **'130–139 or 80–89'**
  String get catStage1Range;

  /// No description provided for @catStage2Range.
  ///
  /// In en, this message translates to:
  /// **'≥ 140 or ≥ 90'**
  String get catStage2Range;

  /// No description provided for @catCrisisRange.
  ///
  /// In en, this message translates to:
  /// **'> 180 or > 120'**
  String get catCrisisRange;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Create a profile to start tracking your blood pressure. Each person using this phone can have their own profile.'**
  String get welcomeBody;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get createProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @addProfile.
  ///
  /// In en, this message translates to:
  /// **'Add profile'**
  String get addProfile;

  /// No description provided for @whoIsMeasuring.
  ///
  /// In en, this message translates to:
  /// **'Who is measuring?'**
  String get whoIsMeasuring;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @birthYearOptional.
  ///
  /// In en, this message translates to:
  /// **'Birth year (optional)'**
  String get birthYearOptional;

  /// No description provided for @invalidYear.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid year'**
  String get invalidYear;

  /// No description provided for @pinLock.
  ///
  /// In en, this message translates to:
  /// **'Protect with a PIN'**
  String get pinLock;

  /// No description provided for @pinLockHint.
  ///
  /// In en, this message translates to:
  /// **'The PIN is asked when opening this profile.'**
  String get pinLockHint;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @newPinOptional.
  ///
  /// In en, this message translates to:
  /// **'New PIN (leave empty to keep the current one)'**
  String get newPinOptional;

  /// No description provided for @pinTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use 4 to 8 digits'**
  String get pinTooShort;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinMismatch;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN for {name}'**
  String enterPin(String name);

  /// No description provided for @wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get wrongPin;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @switchProfile.
  ///
  /// In en, this message translates to:
  /// **'Switch profile'**
  String get switchProfile;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get deleteProfile;

  /// No description provided for @deleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteProfileTitle(String name);

  /// No description provided for @deleteProfileBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes the profile and all its readings and photos.'**
  String get deleteProfileBody;

  /// No description provided for @bornIn.
  ///
  /// In en, this message translates to:
  /// **'Born in {year}'**
  String bornIn(String year);

  /// No description provided for @readingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No readings} =1{1 reading} other{{count} readings}}'**
  String readingsCount(int count);

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemLanguage;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get help;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'Pression Tracker reads your blood pressure monitor from a photo and keeps a history of your measurements.'**
  String get helpIntro;

  /// No description provided for @helpStep1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Take a photo'**
  String get helpStep1Title;

  /// No description provided for @helpStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New reading\" and photograph the monitor display. For the best results use good light, hold the phone straight in front of the screen, fill the frame with the display and avoid reflections.'**
  String get helpStep1Body;

  /// No description provided for @helpStep2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Check the values'**
  String get helpStep2Title;

  /// No description provided for @helpStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Systolic, diastolic and pulse are read automatically. LCD digits can be misread, so compare the numbers with the display and correct them if needed. You can also change the date and time or add a note.'**
  String get helpStep2Body;

  /// No description provided for @helpStep3Title.
  ///
  /// In en, this message translates to:
  /// **'3. History'**
  String get helpStep3Title;

  /// No description provided for @helpStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Every reading is listed with its category colour. The arrows show the change from the previous reading: a red ▲ means higher, a green ▼ means lower. Tap a reading to edit or delete it.'**
  String get helpStep3Body;

  /// No description provided for @helpStep4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Trends'**
  String get helpStep4Title;

  /// No description provided for @helpStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Choose a period to see the average values, a chart over time and how many readings fall into each category. The arrows compare the averages with the period before.'**
  String get helpStep4Body;

  /// No description provided for @helpCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure categories (mmHg)'**
  String get helpCategoriesTitle;

  /// No description provided for @helpProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get helpProfilesTitle;

  /// No description provided for @helpProfilesBody.
  ///
  /// In en, this message translates to:
  /// **'Each person can have their own profile with separate readings. Add a PIN to keep a profile private. Use the account button at the top right to edit, switch or delete profiles and to change the language.'**
  String get helpProfilesBody;

  /// No description provided for @helpPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get helpPrivacyTitle;

  /// No description provided for @helpPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this phone: photos are read on the device and no data is sent anywhere.'**
  String get helpPrivacyBody;

  /// No description provided for @helpDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This app is not a medical device and does not replace the advice of your doctor.'**
  String get helpDisclaimer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
