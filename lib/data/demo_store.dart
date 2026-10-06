import 'dart:math';

import '../models/profile.dart';
import '../models/reading.dart';
import 'app_store.dart';
import 'profile_repository.dart';
import 'reading_repository.dart';

/// In-memory store for the browser preview. Each new profile starts with
/// two months of sample readings; nothing survives a page reload.
class DemoAppStore extends AppStore {
  @override
  final MemoryProfileRepository profiles = MemoryProfileRepository();

  final _readings = <int, DemoReadingRepository>{};

  @override
  Future<ReadingRepository> readingsFor(Profile profile) async => _readings
      .putIfAbsent(profile.id!, () => DemoReadingRepository(seed: profile.id!));

  @override
  Future<void> deleteProfile(Profile profile) async {
    await super.deleteProfile(profile);
    _readings.remove(profile.id);
  }
}

class MemoryProfileRepository extends ProfileRepository {
  int _nextId = 1;

  @override
  Future<Profile> insert(Profile profile) async {
    final saved = profile.withId(_nextId++);
    profiles.value = [...profiles.value, saved];
    return saved;
  }

  @override
  Future<void> replace(Profile profile) async {
    profiles.value = [
      for (final p in profiles.value) p.id == profile.id ? profile : p,
    ];
  }

  @override
  Future<void> remove(Profile profile) async {
    profiles.value = [
      for (final p in profiles.value)
        if (p.id != profile.id) p,
    ];
  }
}

class DemoReadingRepository extends ReadingRepository {
  DemoReadingRepository({int seed = 7}) {
    final rng = Random(seed);
    final now = DateTime.now();
    var id = 0;
    for (var day = 60; day >= 0; day--) {
      // Morning reading most days, evening reading some days.
      for (final hour in [8, 20]) {
        if (hour == 20 && rng.nextInt(3) != 0) continue;
        if (rng.nextInt(6) == 0) continue;
        // Gentle improvement over the two months.
        final trend = day / 60;
        _items.add(
          Reading(
            id: ++id,
            timestamp: DateTime(
              now.year,
              now.month,
              now.day - day,
              hour,
              rng.nextInt(50),
            ),
            systolic: (124 + 14 * trend + rng.nextInt(11) - 5).round(),
            diastolic: (80 + 8 * trend + rng.nextInt(7) - 3).round(),
            pulse: 62 + rng.nextInt(16),
          ),
        );
      }
    }
    _publish();
  }

  final List<Reading> _items = [];

  void _publish() {
    _items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    readings.value = List.unmodifiable(_items);
  }

  @override
  bool isStoredPhoto(String path) => true;

  @override
  Future<String> storePhoto(String sourcePath) async => sourcePath;

  @override
  Future<void> save(Reading reading) async {
    if (reading.id == null) {
      final nextId = _items.fold(0, (m, r) => max(m, r.id ?? 0)) + 1;
      _items.add(reading.withId(nextId));
    } else {
      _items[_items.indexWhere((r) => r.id == reading.id)] = reading;
    }
    _publish();
  }

  @override
  Future<void> delete(Reading reading) async {
    _items.removeWhere((r) => r.id == reading.id);
    _publish();
  }

  @override
  Future<void> deleteAll() async {
    _items.clear();
    _publish();
  }
}
