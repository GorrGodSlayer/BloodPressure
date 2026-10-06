import 'package:flutter_test/flutter_test.dart';
import 'package:pression_tracker/services/bp_parser.dart';

void main() {
  group('BpParser', () {
    test('reads a typical SYS / DIA / PULSE layout', () {
      final r = BpParser.parse(const [
        OcrToken('SYS', top: 10, height: 12),
        OcrToken('mmHg', top: 12, left: 200, height: 10),
        OcrToken('128', top: 30, height: 80),
        OcrToken('DIA', top: 120, height: 12),
        OcrToken('82', top: 140, height: 80),
        OcrToken('PUL/min', top: 230, height: 10),
        OcrToken('67', top: 250, height: 40),
      ]);
      expect(r.systolic, 128);
      expect(r.diastolic, 82);
      expect(r.pulse, 67);
    });

    test('ignores date and time on the display', () {
      final r = BpParser.parse(const [
        OcrToken('10/06', top: 0, height: 15),
        OcrToken('08:45', top: 0, left: 100, height: 15),
        OcrToken('141', top: 30, height: 80),
        OcrToken('93', top: 120, height: 80),
        OcrToken('75', top: 210, height: 40),
      ]);
      expect([r.systolic, r.diastolic, r.pulse], [141, 93, 75]);
    });

    test('fixes common seven-segment misreads', () {
      final r = BpParser.parse(const [
        OcrToken('1l9', top: 0, height: 80),
        OcrToken('B0', top: 100, height: 80),
        OcrToken('7O', top: 200, height: 40),
      ]);
      expect([r.systolic, r.diastolic, r.pulse], [119, 80, 70]);
    });

    test('accepts a slash-separated reading', () {
      final r = BpParser.parse(const [
        OcrToken('135/88', top: 0, height: 50),
        OcrToken('72', top: 80, height: 30),
      ]);
      expect([r.systolic, r.diastolic, r.pulse], [135, 88, 72]);
    });

    test('prefers large digits over small memory numbers', () {
      final r = BpParser.parse(const [
        OcrToken('M', top: 0, height: 10),
        OcrToken('99', top: 0, left: 30, height: 10), // memory slot
        OcrToken('122', top: 20, height: 90),
        OcrToken('78', top: 120, height: 90),
        OcrToken('64', top: 220, height: 40),
      ]);
      expect([r.systolic, r.diastolic, r.pulse], [122, 78, 64]);
    });

    test('works without a pulse value', () {
      final r = BpParser.parse(const [
        OcrToken('118', top: 0, height: 80),
        OcrToken('76', top: 100, height: 80),
      ]);
      expect(r.isComplete, isTrue);
      expect(r.pulse, isNull);
    });

    test('returns empty result for unreadable text', () {
      final r = BpParser.parse(const [OcrToken('Err'), OcrToken('SYS')]);
      expect(r.isComplete, isFalse);
    });
  });
}
