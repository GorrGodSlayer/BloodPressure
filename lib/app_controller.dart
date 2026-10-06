import 'package:flutter/material.dart';

import 'data/app_store.dart';
import 'data/reading_repository.dart';
import 'data/settings.dart';
import 'models/profile.dart';

/// Holds the signed-in profile and the chosen language.
class AppController extends ChangeNotifier {
  AppController(this.store, this.settings);

  final AppStore store;
  final Settings settings;

  Profile? _profile;
  ReadingRepository? _readings;

  Profile? get profile => _profile;

  /// Readings of the signed-in profile.
  ReadingRepository? get readings => _readings;

  Locale? get locale {
    final code = settings.localeCode;
    return code == null ? null : Locale(code);
  }

  /// Re-opens the last used profile unless it is protected by a PIN.
  Future<void> restoreSession() async {
    final id = settings.lastProfileId;
    final profile = id == null ? null : store.profiles.byId(id);
    if (profile != null && !profile.hasPin) await signIn(profile);
  }

  Future<void> signIn(Profile profile) async {
    _readings = await store.readingsFor(profile);
    _profile = profile;
    await settings.setLastProfileId(profile.id);
    notifyListeners();
  }

  void signOut() {
    _profile = null;
    _readings = null;
    notifyListeners();
  }

  void profileUpdated(Profile profile) {
    if (profile.id == _profile?.id) {
      _profile = profile;
      notifyListeners();
    }
  }

  Future<void> deleteProfile(Profile profile) async {
    await store.deleteProfile(profile);
    if (profile.id == _profile?.id) {
      await settings.setLastProfileId(null);
      signOut();
    }
  }

  Future<void> setLocale(String? code) async {
    await settings.setLocaleCode(code);
    notifyListeners();
  }
}
