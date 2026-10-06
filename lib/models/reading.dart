/// A single blood-pressure measurement.
class Reading {
  final int? id;
  final DateTime timestamp;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final String? imagePath;
  final String? note;

  const Reading({
    this.id,
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    this.imagePath,
    this.note,
  });

  Reading withId(int newId) => Reading(
    id: newId,
    timestamp: timestamp,
    systolic: systolic,
    diastolic: diastolic,
    pulse: pulse,
    imagePath: imagePath,
    note: note,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'systolic': systolic,
    'diastolic': diastolic,
    'pulse': pulse,
    'image_path': imagePath,
    'note': note,
  };

  factory Reading.fromMap(Map<String, Object?> map) => Reading(
    id: map['id'] as int?,
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    systolic: map['systolic'] as int,
    diastolic: map['diastolic'] as int,
    pulse: map['pulse'] as int?,
    imagePath: map['image_path'] as String?,
    note: map['note'] as String?,
  );
}
