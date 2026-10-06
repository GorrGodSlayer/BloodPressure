/// A person whose readings are tracked on this device.
class Profile {
  final int? id;
  final String name;
  final int? birthYear;

  /// Salted SHA-256 of the PIN, or null when the profile is not locked.
  final String? pinHash;
  final String? pinSalt;
  final DateTime createdAt;

  const Profile({
    this.id,
    required this.name,
    this.birthYear,
    this.pinHash,
    this.pinSalt,
    required this.createdAt,
  });

  bool get hasPin => pinHash != null;

  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  Profile withId(int newId) => Profile(
    id: newId,
    name: name,
    birthYear: birthYear,
    pinHash: pinHash,
    pinSalt: pinSalt,
    createdAt: createdAt,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'birth_year': birthYear,
    'pin_hash': pinHash,
    'pin_salt': pinSalt,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Profile.fromMap(Map<String, Object?> map) => Profile(
    id: map['id'] as int?,
    name: map['name'] as String,
    birthYear: map['birth_year'] as int?,
    pinHash: map['pin_hash'] as String?,
    pinSalt: map['pin_salt'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}
