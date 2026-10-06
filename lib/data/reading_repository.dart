import 'package:flutter/foundation.dart';

import '../models/reading.dart';

/// Persists the readings and photos of one profile.
abstract class ReadingRepository {
  /// All readings, newest first.
  final ValueNotifier<List<Reading>> readings = ValueNotifier(const []);

  bool isStoredPhoto(String path);

  /// Copies a picked/captured image into permanent app storage.
  Future<String> storePhoto(String sourcePath);

  Future<void> save(Reading reading);

  Future<void> delete(Reading reading);

  /// Removes every reading and photo of this profile.
  Future<void> deleteAll();
}
