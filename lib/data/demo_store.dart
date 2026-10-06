import 'dart:math';

import '../models/profile.dart';
import '../models/reading.dart';
import 'app_store.dart';
import 'profile_repository.dart';
import 'reading_repository.dart';

/// In-memory store for the browser preview; nothing survives a page reload.
class DemoAppStore extends AppStore {
  @override
  final MemoryProfileRepository profiles = MemoryProfileRepository();

  final _readings = <int, DemoReadingRepository>{};

  @override
  Future<ReadingRepository> readingsFor(Profile profile) async =>
      _readings.putIfAbsent(profile.id!, DemoReadingRepository.new);

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
