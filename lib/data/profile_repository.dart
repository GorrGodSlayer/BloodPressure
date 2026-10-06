import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/profile.dart';

/// Stores the profiles (local accounts) on this device.
abstract class ProfileRepository {
  /// All profiles, oldest first.
  final ValueNotifier<List<Profile>> profiles = ValueNotifier(const []);

  Profile? byId(int id) => profiles.value.where((p) => p.id == id).firstOrNull;

  Future<Profile> create({required String name, int? birthYear, String? pin}) {
    final salt = pin == null ? null : _newSalt();
    return insert(
      Profile(
        name: name.trim(),
        birthYear: birthYear,
        pinSalt: salt,
        pinHash: pin == null ? null : hashPin(pin, salt!),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// [pin]: null keeps the current PIN, empty removes it, otherwise sets it.
  Future<Profile> update(
    Profile profile, {
    required String name,
    int? birthYear,
    String? pin,
  }) async {
    var salt = profile.pinSalt;
    var hash = profile.pinHash;
    if (pin != null) {
      salt = pin.isEmpty ? null : _newSalt();
      hash = pin.isEmpty ? null : hashPin(pin, salt!);
    }
    final updated = Profile(
      id: profile.id,
      name: name.trim(),
      birthYear: birthYear,
      pinSalt: salt,
      pinHash: hash,
      createdAt: profile.createdAt,
    );
    await replace(updated);
    return updated;
  }

  bool verifyPin(Profile profile, String pin) =>
      profile.hasPin && hashPin(pin, profile.pinSalt!) == profile.pinHash;

  @protected
  Future<Profile> insert(Profile profile);

  @protected
  Future<void> replace(Profile profile);

  Future<void> remove(Profile profile);
}

String hashPin(String pin, String salt) =>
    sha256.convert(utf8.encode('$salt:$pin')).toString();

String _newSalt() {
  final rng = Random.secure();
  return base64UrlEncode(List.generate(16, (_) => rng.nextInt(256)));
}
