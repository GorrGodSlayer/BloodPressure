// Stress-tests SevenSegmentReader on many image variants and prints a
// pass/fail table. Run with: dart run tool/ocr_probe.dart [filter] [v]
// With a second argument, logs the reader's decisions and writes the
// foreground masks as PNGs to $PROBE_OUT (default: current directory).
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:pression_tracker/services/bp_parser.dart';
import 'package:pression_tracker/services/seven_segment.dart';

import '../test/support/synthetic_display.dart';

img.Image photo() => img.decodeImage(
  File('test/fixtures/monitor_123_70_60.jpg').readAsBytesSync(),
)!;

bool verbose = false;

List<int?> read(img.Image image) {
  final debug = SegmentDebug();
  final r = BpParser.parse(SevenSegmentReader.read(image, debug: debug));
  if (verbose) {
    debug.log.forEach(print);
    var n = 0;
    for (final (name, mask, w, h) in debug.masks) {
      final out = img.Image(width: w, height: h);
      for (var i = 0; i < mask.length; i++) {
        final v = mask[i] == 1 ? 0 : 255;
        out.setPixelRgb(i % w, i ~/ w, v, v, v);
      }
      final path = '${Platform.environment['PROBE_OUT'] ?? '.'}/mask_${n++}_$name.png';
      File(path).writeAsBytesSync(img.encodePng(out));
      print('wrote $path');
    }
  }
  return [r.systolic, r.diastolic, r.pulse];
}

void main(List<String> args) {
  final filter = args.isEmpty ? '' : args.first;
  verbose = args.length > 1;
  final cases = <String, (img.Image Function(), List<int?>)>{};
  const real = [123, 70, 60];
  // Several image operations work in place, so every case gets a fresh copy.
  final original = photo();
  img.Image p() => original.clone();
  cases['real as taken'] = (() => p(), real);
  for (final a in [-10, -6, 6, 10]) {
    cases['real rotate $a'] = (() => img.copyRotate(p(), angle: a), real);
  }
  for (final wdt in [300, 420, 1600, 3000]) {
    cases['real width $wdt'] = (() => img.copyResize(p(), width: wdt), real);
  }
  cases['real bright 0.5'] = (() => img.adjustColor(p(), brightness: 0.5), real);
  cases['real bright 1.4'] = (() => img.adjustColor(p(), brightness: 1.4), real);
  cases['real contrast 0.6'] = (() => img.adjustColor(p(), contrast: 0.6), real);
  cases['real blur 2'] = (() => img.gaussianBlur(p(), radius: 2), real);
  cases['real blur 4'] = (() => img.gaussianBlur(p(), radius: 4), real);
  cases['real noise 20'] = (() => noisy(p(), 20), real);
  cases['real noise 40'] = (() => noisy(p(), 40), real);
  cases['real shadow gradient'] = (() => shadowGradient(p()), real);
  final w = original.width.toDouble(), h = original.height.toDouble();
  cases['real perspective 1'] = (
    () => perspective(p(), [
      const math.Point(0, 0),
      math.Point(w, h * 0.12),
      math.Point(w, h * 0.88),
      math.Point(0, h),
    ]),
    real,
  );
  cases['real perspective 2'] = (
    () => perspective(p(), [
      math.Point(w * 0.1, 0),
      math.Point(w * 0.95, 0),
      math.Point(w, h),
      math.Point(0, h),
    ]),
    real,
  );
  cases['real crop tight'] = (
    () => img.copyCrop(p(), x: 400, y: 50, width: 260, height: 460),
    real,
  );
  cases['real grayscale'] = (() => img.grayscale(p()), real);

  final synth = [
    ['141', '93', '75'],
    ['118', '76', '62'],
    ['205', '134', '88'],
    ['96', '58', '49'],
    ['100', '60', '100'],
    ['177', '111', '71'],
  ];
  final darkBg = img.ColorRgb8(20, 30, 60);
  final lightInk = img.ColorRgb8(230, 240, 255);
  for (final rows in synth) {
    final exp = rows.map(int.parse).toList();
    final name = rows.join('/');
    cases['synth $name'] = (() => display(rows), exp);
    cases['synth $name thin'] = (() => display(rows, stroke: 7), exp);
    cases['synth $name thick'] = (() => display(rows, stroke: 16), exp);
    cases['synth $name wide'] = (() => display(rows, widthRatio: 0.7), exp);
    cases['synth $name narrow'] = (() => display(rows, widthRatio: 0.38), exp);
    cases['synth $name clutter'] = (() => display(rows, clutter: true), exp);
    cases['synth $name inverted'] = (
      () => display(rows, bg: darkBg, ink: lightInk),
      exp,
    );
    cases['synth $name inverted clutter'] = (
      () => display(rows, bg: darkBg, ink: lightInk, clutter: true),
      exp,
    );
    cases['synth $name lowcontrast'] = (
      () => display(
        rows,
        bg: img.ColorRgb8(150, 160, 150),
        ink: img.ColorRgb8(90, 95, 90),
      ),
      exp,
    );
    cases['synth $name biggap'] = (() => display(rows, gap: 8), exp);
    cases['synth $name rot8'] = (
      () => img.copyRotate(display(rows), angle: 8),
      exp,
    );
    cases['synth $name blur3'] = (
      () => img.gaussianBlur(display(rows), radius: 3),
      exp,
    );
    cases['synth $name small'] = (() => display(rows, digitHeight: 60), exp);
    cases['synth $name huge'] = (
      () => img.copyResize(display(rows, clutter: true), width: 3000),
      exp,
    );
    cases['synth $name italic'] = (() => italic(display(rows), 0.15), exp);
    cases['synth $name italic clutter'] = (
      () => italic(display(rows, clutter: true), 0.22),
      exp,
    );
    cases['synth $name far away'] = (
      () => farAway(display(rows, clutter: true)),
      exp,
    );
    cases['synth $name far away inverted'] = (
      () => farAway(display(rows, bg: darkBg, ink: lightInk)),
      exp,
    );
    cases['synth $name shadow'] = (
      () => shadowGradient(display(rows, clutter: true)),
      exp,
    );
  }

  var pass = 0, fail = 0;
  final failures = <String>[];
  for (final e in cases.entries) {
    if (!e.key.contains(filter)) continue;
    final sw = Stopwatch()..start();
    List<int?> got;
    try {
      got = read(e.value.$1());
    } catch (err) {
      failures.add('${e.key}: THREW $err');
      fail++;
      continue;
    }
    final ok = got.toString() == e.value.$2.toString();
    if (ok) {
      pass++;
    } else {
      fail++;
      failures.add(
        '${e.key}: got $got want ${e.value.$2} (${sw.elapsedMilliseconds}ms)',
      );
    }
  }
  print('PASS $pass  FAIL $fail');
  failures.forEach(print);
}
