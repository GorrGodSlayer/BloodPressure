import 'package:flutter_test/flutter_test.dart';
import 'package:pression_tracker/data/demo_store.dart';

void main() {
  group('ProfileRepository', () {
    test('creates a profile without PIN', () async {
      final repo = MemoryProfileRepository();
      final p = await repo.create(name: '  Anna ', birthYear: 1960);
      expect(p.id, isNotNull);
      expect(p.name, 'Anna');
      expect(p.hasPin, isFalse);
      expect(repo.profiles.value, hasLength(1));
    });

    test('stores only a salted hash and verifies the PIN', () async {
      final repo = MemoryProfileRepository();
      final p = await repo.create(name: 'Marco', pin: '1234');
      expect(p.hasPin, isTrue);
      expect(p.pinHash, isNot(contains('1234')));
      expect(repo.verifyPin(p, '1234'), isTrue);
      expect(repo.verifyPin(p, '4321'), isFalse);

      final other = await repo.create(name: 'Luca', pin: '1234');
      expect(other.pinHash, isNot(p.pinHash), reason: 'salt differs');
    });

    test('update keeps, changes or removes the PIN', () async {
      final repo = MemoryProfileRepository();
      final p = await repo.create(name: 'Sara', pin: '1111');

      final kept = await repo.update(p, name: 'Sara B');
      expect(repo.verifyPin(kept, '1111'), isTrue);
      expect(repo.byId(p.id!)!.name, 'Sara B');

      final changed = await repo.update(kept, name: 'Sara B', pin: '2222');
      expect(repo.verifyPin(changed, '2222'), isTrue);
      expect(repo.verifyPin(changed, '1111'), isFalse);

      final removed = await repo.update(changed, name: 'Sara B', pin: '');
      expect(removed.hasPin, isFalse);
    });
  });

  test('DemoAppStore deletes a profile with its readings', () async {
    final store = DemoAppStore();
    final p = await store.profiles.create(name: 'Demo');
    final readings = await store.readingsFor(p);
    expect(readings.readings.value, isNotEmpty);

    await store.deleteProfile(p);
    expect(store.profiles.profiles.value, isEmpty);
    expect(readings.readings.value, isEmpty);
  });
}
