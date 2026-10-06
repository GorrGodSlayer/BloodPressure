# Pression Tracker

Android app (Flutter) that tracks blood pressure over time from photos of an
electronic blood pressure monitor.

## Features

- **Photo reading** – take or pick a photo of the monitor; on-device ML Kit OCR
  reads systolic, diastolic and pulse. Values are always shown for
  confirmation and can be corrected before saving.
- **History** – every reading with its ACC/AHA category and the change from the
  previous reading.
- **Trends** – 7 / 30 / 90 day or all-time chart, averages compared with the
  previous period, readings per category.
- **Profiles** – several local profiles on one phone, each with its own
  readings and an optional PIN.
- **Languages** – English and Italian (follows the system, or choose in the app).
- **Help** – the `?` button explains how the app works.

All data stays on the device (SQLite + app storage). Nothing is uploaded.

> Not a medical device. Categories are informational only.

## Install

Download the APK from the latest
[release](../../releases) and open it on your phone (allow installs from
unknown sources).

## Development

```sh
flutter pub get
flutter test
flutter run                      # device or emulator
flutter run -d web-server        # browser UI preview (in-memory)
flutter build apk --release
```

Strings live in `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb`;
`flutter gen-l10n` (run automatically on build) regenerates the Dart code.

### Project layout

| Path | Purpose |
| --- | --- |
| `lib/services/bp_parser.dart` | Picks SYS/DIA/PULSE out of OCR text |
| `lib/services/ocr_service.dart` | ML Kit text recognition |
| `lib/data/` | SQLite store, profiles, settings, browser demo store |
| `lib/screens/` | UI |
| `test/` | Parser, statistics, profile and localization tests |

The release APK is currently signed with the debug key; set up a release
keystore before publishing to the Play Store.
