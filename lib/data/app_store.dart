import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/profile.dart';
import '../models/reading.dart';
import 'demo_store.dart';
import 'profile_repository.dart';
import 'reading_repository.dart';

/// Entry point to all persisted data.
abstract class AppStore {
  /// SQLite on device; an in-memory demo store in the browser preview,
  /// where SQLite and file storage are unavailable.
  static Future<AppStore> open() async =>
      kIsWeb ? DemoAppStore() : await SqliteAppStore.open();

  ProfileRepository get profiles;

  Future<ReadingRepository> readingsFor(Profile profile);

  /// Deletes the profile together with all its readings and photos.
  Future<void> deleteProfile(Profile profile) async {
    await (await readingsFor(profile)).deleteAll();
    await profiles.remove(profile);
  }
}

class SqliteAppStore extends AppStore {
  SqliteAppStore._(this._db, this._photoDir, this.profiles);

  final Database _db;
  final Directory _photoDir;

  @override
  final SqliteProfileRepository profiles;

  static Future<SqliteAppStore> open() async {
    final db = await openDatabase(
      p.join(await getDatabasesPath(), 'pression_tracker.db'),
      version: 2,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            systolic INTEGER NOT NULL,
            diastolic INTEGER NOT NULL,
            pulse INTEGER,
            image_path TEXT,
            note TEXT,
            profile_id INTEGER
          )
        ''');
        await _createProfiles(db);
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE readings ADD COLUMN profile_id INTEGER',
          );
          await _createProfiles(db);
        }
      },
    );
    final docs = await getApplicationDocumentsDirectory();
    final photoDir = Directory(p.join(docs.path, 'photos'));
    await photoDir.create(recursive: true);

    final profiles = SqliteProfileRepository(db);
    await profiles.reload();
    return SqliteAppStore._(db, photoDir, profiles);
  }

  static Future<void> _createProfiles(Database db) async {
    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birth_year INTEGER,
        pin_hash TEXT,
        pin_salt TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX readings_profile_time ON readings (profile_id, timestamp)',
    );
  }

  @override
  Future<ReadingRepository> readingsFor(Profile profile) async {
    final repo = SqliteReadingRepository._(_db, _photoDir, profile.id!);
    await repo._reload();
    return repo;
  }
}

class SqliteProfileRepository extends ProfileRepository {
  SqliteProfileRepository(this._db);

  final Database _db;

  Future<void> reload() async {
    final rows = await _db.query('profiles', orderBy: 'created_at');
    profiles.value = rows.map(Profile.fromMap).toList(growable: false);
  }

  @override
  Future<Profile> insert(Profile profile) async {
    final id = await _db.insert('profiles', profile.toMap()..remove('id'));
    // Readings saved before profiles existed belong to the first profile.
    await _db.update('readings', {
      'profile_id': id,
    }, where: 'profile_id IS NULL');
    await reload();
    return profile.withId(id);
  }

  @override
  Future<void> replace(Profile profile) async {
    await _db.update(
      'profiles',
      profile.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
    await reload();
  }

  @override
  Future<void> remove(Profile profile) async {
    await _db.delete('profiles', where: 'id = ?', whereArgs: [profile.id]);
    await reload();
  }
}

/// Stores one profile's readings in SQLite and photos in app storage.
class SqliteReadingRepository extends ReadingRepository {
  SqliteReadingRepository._(this._db, this._photoDir, this._profileId);

  final Database _db;
  final Directory _photoDir;
  final int _profileId;

  Future<void> _reload() async {
    final rows = await _db.query(
      'readings',
      where: 'profile_id = ?',
      whereArgs: [_profileId],
      orderBy: 'timestamp DESC',
    );
    readings.value = rows.map(Reading.fromMap).toList(growable: false);
  }

  @override
  bool isStoredPhoto(String path) => p.isWithin(_photoDir.path, path);

  @override
  Future<String> storePhoto(String sourcePath) async {
    final name =
        '${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final copy = await File(sourcePath).copy(p.join(_photoDir.path, name));
    return copy.path;
  }

  @override
  Future<void> save(Reading reading) async {
    final map = reading.toMap()
      ..remove('id')
      ..['profile_id'] = _profileId;
    if (reading.id == null) {
      await _db.insert('readings', map);
    } else {
      await _db.update(
        'readings',
        map,
        where: 'id = ?',
        whereArgs: [reading.id],
      );
    }
    await _reload();
  }

  @override
  Future<void> delete(Reading reading) async {
    await _db.delete('readings', where: 'id = ?', whereArgs: [reading.id]);
    await _deletePhoto(reading.imagePath);
    await _reload();
  }

  @override
  Future<void> deleteAll() async {
    for (final reading in readings.value) {
      await _deletePhoto(reading.imagePath);
    }
    await _db.delete(
      'readings',
      where: 'profile_id = ?',
      whereArgs: [_profileId],
    );
    await _reload();
  }

  Future<void> _deletePhoto(String? path) async {
    if (path == null || !isStoredPhoto(path)) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
