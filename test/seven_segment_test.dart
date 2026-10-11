import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pression_tracker/services/bp_parser.dart';
import 'package:pression_tracker/services/seven_segment.dart';

import 'support/synthetic_display.dart';

img.Image _photo() => img.decodeImage(
  File('test/fixtures/monitor_123_70_60.jpg').readAsBytesSync(),
)!;

List<int?> _read(img.Image image) {
  final r = BpParser.parse(SevenSegmentReader.read(image));
  return [r.systolic, r.diastolic, r.pulse];
}

void main() {
  group('real photo (123 / 70 / 60, with a hand shadow)', () {
    const want = [123, 70, 60];

    test('as taken', () => expect(_read(_photo()), want));

    for (final width in [300, 420, 1600, 3000]) {
      test('resized to $width px', () {
        expect(_read(img.copyResize(_photo(), width: width)), want);
      });
    }

    for (final angle in [-10, -6, 4, 6, 10]) {
      test('tilted by $angle°', () {
        expect(_read(img.copyRotate(_photo(), angle: angle)), want);
      });
    }

    test('under-exposed', () {
      expect(_read(img.adjustColor(_photo(), brightness: 0.5)), want);
    });

    test('over-exposed, highlights clipped', () {
      expect(_read(img.adjustColor(_photo(), brightness: 1.4)), want);
    });

    test('low contrast', () {
      expect(_read(img.adjustColor(_photo(), contrast: 0.6)), want);
    });

    test('slightly blurred', () {
      expect(_read(img.gaussianBlur(_photo(), radius: 3)), want);
    });

    test('grainy', () => expect(_read(noisy(_photo(), 20)), want));

    test('shadow across the display', () {
      expect(_read(shadowGradient(_photo())), want);
    });

    test('photographed from below (keystone)', () {
      final p = _photo();
      final w = p.width.toDouble(), h = p.height.toDouble();
      final skewed = perspective(p, [
        const math.Point(0, 0),
        math.Point(w, h * 0.12),
        math.Point(w, h * 0.88),
        math.Point(0, h),
      ]);
      expect(_read(skewed), want);
    });

    test('tight crop around the digits', () {
      final crop = img.copyCrop(
        _photo(),
        x: 400,
        y: 50,
        width: 260,
        height: 460,
      );
      expect(_read(crop), want);
    });

    test('grayscale', () => expect(_read(img.grayscale(_photo())), want));
  });

  group('synthetic displays', () {
    const readings = [
      ['141', '93', '75'],
      ['118', '76', '62'],
      ['205', '134', '88'],
      ['96', '58', '49'],
      ['100', '60', '100'],
      ['177', '111', '71'],
    ];

    for (final rows in readings) {
      final want = rows.map(int.parse).toList();
      final name = rows.join(' / ');

      test('$name plain', () => expect(_read(display(rows)), want));

      test('$name with date, time and icons', () {
        expect(_read(display(rows, clutter: true)), want);
      });

      test('$name thin strokes', () {
        expect(_read(display(rows, stroke: 7)), want);
      });

      test('$name thick strokes', () {
        expect(_read(display(rows, stroke: 16)), want);
      });

      test('$name wide digits', () {
        expect(_read(display(rows, widthRatio: 0.7)), want);
      });

      test('$name narrow digits', () {
        expect(_read(display(rows, widthRatio: 0.38)), want);
      });

      test('$name wide gaps between segments', () {
        expect(_read(display(rows, gap: 8)), want);
      });

      test('$name backlit (light digits on dark)', () {
        final lit = display(rows, bg: darkBackground, ink: lightInk);
        expect(_read(lit), want);
      });

      test('$name low contrast', () {
        final faint = display(
          rows,
          bg: img.ColorRgb8(150, 160, 150),
          ink: img.ColorRgb8(90, 95, 90),
        );
        expect(_read(faint), want);
      });

      test('$name italic', () {
        expect(_read(italic(display(rows, clutter: true), 0.22)), want);
      });

      test('$name tilted 8°', () {
        expect(_read(img.copyRotate(display(rows), angle: 8)), want);
      });

      test('$name small in a large photo', () {
        expect(_read(farAway(display(rows, clutter: true))), want);
      });

      test('$name backlit and small in a large photo', () {
        final lit = display(rows, bg: darkBackground, ink: lightInk);
        expect(_read(farAway(lit)), want);
      });
    }
  });
}
