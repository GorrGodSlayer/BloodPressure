# Pression Tracker

Android app (Flutter) that tracks blood pressure over time from photos of an
electronic blood pressure monitor.

## Features

- **Photo reading** – take or pick a photo of the monitor; the values are read
  on the device, by a purpose-built reader for seven-segment LCD digits plus
  ML Kit OCR for monitors with regular fonts. It copes with shadows,
  tilted or italic digits, backlit displays, over- or under-exposure and a
  monitor that fills only part of the frame. Values are always shown for
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
| `lib/services/seven_segment.dart` | Reads seven-segment LCD digits from pixels |
| `lib/services/bp_parser.dart` | Picks SYS/DIA/PULSE out of recognised numbers |
| `lib/services/ocr_service.dart` | Runs ML Kit and the segment reader, merges results |
| `tool/ocr_probe.dart` | Stress-tests the reader on 130+ image variants (`dart run tool/ocr_probe.dart`) |
| `lib/data/` | SQLite store, profiles, settings, browser demo store |
| `lib/screens/` | UI |
| `test/` | Reader (real photo + synthetic displays), parser, statistics, profile and localization tests |

The release APK is currently signed with the debug key; set up a release
keystore before publishing to the Play Store.
