/// Draws blood-pressure monitor displays with seven-segment digits, and
/// distorts images the way phone photos are distorted, for OCR tests.
library;

import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _segments = {
  '0': 'abcdef',
  '1': 'bc',
  '2': 'abdeg',
  '3': 'abcdg',
  '4': 'bcfg',
  '5': 'acdfg',
  '6': 'acdefg',
  '7': 'abc',
  '8': 'abcdefg',
  '9': 'abcdfg',
};

final darkBackground = img.ColorRgb8(20, 30, 60);
final lightInk = img.ColorRgb8(230, 240, 255);

/// Draws [text] as segmented LCD digits, segments separated by small gaps.
void drawDigits(
  img.Image image,
  String text,
  int x,
  int y,
  int height, {
  int? stroke,
  img.Color? ink,
  int gap = 3,
  double widthRatio = 0.5,
}) {
  final w = (height * widthRatio).round(),
      t = stroke ?? height ~/ 9,
      half = height ~/ 2;
  final color = ink ?? img.ColorRgb8(40, 45, 40);
  for (final ch in text.split('')) {
    void rect(int x0, int y0, int x1, int y1) =>
        img.fillRect(image, x1: x0, y1: y0, x2: x1, y2: y1, color: color);
    if (ch == ' ') {
      x += w + height ~/ 4;
      continue;
    }
    // Horizontal segments reach the middle of the vertical strokes, as the
    // chamfered ends of real displays do.
    for (final s in _segments[ch]!.split('')) {
      switch (s) {
        case 'a':
          rect(x + gap + t ~/ 2, y, x + w - gap - t ~/ 2, y + t);
        case 'b':
          rect(x + w - t, y + gap + t, x + w, y + half - gap);
        case 'c':
          rect(x + w - t, y + half + gap, x + w, y + height - gap - t);
        case 'd':
          rect(
            x + gap + t ~/ 2,
            y + height - t,
            x + w - gap - t ~/ 2,
            y + height,
          );
        case 'e':
          rect(x, y + half + gap, x + t, y + height - gap - t);
        case 'f':
          rect(x, y + gap + t, x + t, y + half - gap);
        case 'g':
          rect(
            x + gap + t ~/ 2,
            y + half - t ~/ 2,
            x + w - gap - t ~/ 2,
            y + half + t ~/ 2,
          );
      }
    }
    x += w + height ~/ 4;
  }
}

/// A monitor display showing [rows] (SYS, DIA, PULSE), right-aligned.
///
/// With [clutter], the date, time and a memory number appear in small
/// digits, plus a heart and a solid icon, as on real monitors.
img.Image display(
  List<String> rows, {
  int? stroke,
  img.Color? bg,
  img.Color? ink,
  bool clutter = false,
  int gap = 3,
  double widthRatio = 0.5,
  int digitHeight = 120,
}) {
  final image = img.Image(width: 700, height: 520);
  img.fill(image, color: bg ?? img.ColorRgb8(190, 198, 186));
  final inkColor = ink ?? img.ColorRgb8(40, 45, 40);
  var y = 20;
  for (final row in rows) {
    final width =
        row.length * (digitHeight * widthRatio + digitHeight / 4).round();
    drawDigits(
      image,
      row,
      520 - width,
      y,
      digitHeight,
      stroke: stroke,
      ink: ink,
      gap: gap,
      widthRatio: widthRatio,
    );
    y += digitHeight + 30;
  }
  if (clutter) {
    drawDigits(image, '06 10', 40, 475, 30, stroke: 4, ink: ink);
    drawDigits(image, '12 34', 250, 475, 30, stroke: 4, ink: ink);
    drawDigits(image, '12', 560, 475, 30, stroke: 4, ink: ink);
    img.fillCircle(image, x: 60, y: 60, radius: 14, color: inkColor);
    img.fillRect(image, x1: 40, y1: 100, x2: 110, y2: 160, color: inkColor);
  }
  return image;
}

/// Maps the output rectangle onto [quad] in the source (keystone effect).
img.Image perspective(img.Image src, List<math.Point<double>> quad) {
  final w = src.width, h = src.height;
  final out = img.Image(width: w, height: h);
  img.fill(out, color: img.ColorRgb8(0, 0, 0));
  for (var y = 0; y < h; y++) {
    final v = y / (h - 1);
    for (var x = 0; x < w; x++) {
      final u = x / (w - 1);
      final top = quad[0] + (quad[1] - quad[0]) * u;
      final bottom = quad[3] + (quad[2] - quad[3]) * u;
      final p = top + (bottom - top) * v;
      final sx = p.x.round(), sy = p.y.round();
      if (sx < 0 || sy < 0 || sx >= w || sy >= h) continue;
      out.setPixel(x, y, src.getPixel(sx, sy));
    }
  }
  return out;
}

/// Italic digits: shifts rows above the centre to the right.
img.Image italic(img.Image src, double shear) {
  final out = img.Image(width: src.width, height: src.height);
  img.fill(out, color: src.getPixel(0, 0));
  final cy = src.height / 2;
  for (var y = 0; y < src.height; y++) {
    final shift = (shear * (cy - y)).round();
    for (var x = 0; x < src.width; x++) {
      final sx = x - shift;
      if (sx < 0 || sx >= src.width) continue;
      out.setPixel(x, y, src.getPixel(sx, y));
    }
  }
  return out;
}

/// A phone photo where the display fills only a quarter of the frame.
img.Image farAway(img.Image display, {int frame = 3000}) {
  final out = img.Image(width: frame, height: frame * 3 ~/ 4);
  img.fill(out, color: img.ColorRgb8(120, 110, 100));
  final small = img.copyResize(display, width: frame ~/ 4);
  img.compositeImage(out, small, dstX: frame ~/ 2, dstY: frame ~/ 5);
  return out;
}

/// Adds uniform sensor noise of up to ±[amount] to every channel.
img.Image noisy(img.Image src, int amount) {
  final random = math.Random(1);
  final out = src.clone();
  for (final p in out) {
    final n = random.nextInt(amount * 2 + 1) - amount;
    p.r = (p.r + n).clamp(0, 255);
    p.g = (p.g + n).clamp(0, 255);
    p.b = (p.b + n).clamp(0, 255);
  }
  return out;
}

/// Darkens the left side, like a shadow across the display.
img.Image shadowGradient(img.Image src) {
  final out = src.clone();
  for (final p in out) {
    final f = 0.35 + 0.65 * (p.x / out.width);
    p.r = (p.r * f).round();
    p.g = (p.g * f).round();
    p.b = (p.b * f).round();
  }
  return out;
}
