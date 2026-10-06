import 'package:shared_preferences/shared_preferences.dart';

/// Small app-wide preferences.
class Settings {
  Settings._(this._prefs);

  final SharedPreferences _prefs;

  static const _lastProfileKey = 'lastProfileId';
  static const _localeKey = 'localeCode';

  static Future<Settings> load() async =>
      Settings._(await SharedPreferences.getInstance());

  int? get lastProfileId => _prefs.getInt(_lastProfileKey);

  Future<void> setLastProfileId(int? id) => id == null
      ? _prefs.remove(_lastProfileKey)
      : _prefs.setInt(_lastProfileKey, id);

  /// Language code chosen in the app, or null to follow the system.
  String? get localeCode => _prefs.getString(_localeKey);

  Future<void> setLocaleCode(String? code) => code == null
      ? _prefs.remove(_localeKey)
      : _prefs.setString(_localeKey, code);
}
