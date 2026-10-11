import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'bp_parser.dart';

/// Collects diagnostic messages from [SevenSegmentReader.read] (tooling only).
class SegmentDebug {
  final List<String> log = [];
  final List<(String, Uint8List, int, int)> masks = [];

  void call(String message) => log.add(message);

  void mask(String name, Uint8List mask, int w, int h) =>
      masks.add((name, mask, w, h));
}

/// Reads seven-segment LCD digits straight from the pixels.
///
/// General-purpose OCR often fails on segmented digits because the
/// segments are not connected. This reader:
///  1. evens out lighting (shadows) by comparing each pixel with a local
///     background estimate, for dark-on-light and light-on-dark displays,
///  2. finds digit-sized shapes, straightening tilted or italic digits
///     when a first attempt is incomplete,
///  3. decodes each one from the lengths of its horizontal and vertical
///     strokes, which works for any stroke thickness or digit size,
///  4. returns one [OcrToken] per row of digits, ready for [BpParser].
class SevenSegmentReader {
  static const _workWidth = 800;

  /// Segment bits: a=top, b=top-right, c=bottom-right, d=bottom,
  /// e=bottom-left, f=top-left, g=middle.
  static const _a = 1, _b = 2, _c = 4, _d = 8, _e = 16, _f = 32, _g = 64;

  static const _digits = <int, String>{
    _a | _b | _c | _d | _e | _f: '0',
    _b | _c: '1',
    _a | _b | _d | _e | _g: '2',
    _a | _b | _c | _d | _g: '3',
    _b | _c | _f | _g: '4',
    _a | _c | _d | _f | _g: '5',
    _a | _c | _d | _e | _f | _g: '6',
    _c | _d | _e | _f | _g: '6',
    _a | _b | _c: '7',
    _a | _b | _c | _f: '7',
    _a | _b | _c | _d | _e | _f | _g: '8',
    _a | _b | _c | _d | _f | _g: '9',
    _a | _b | _c | _f | _g: '9',
  };

  static List<OcrToken> read(img.Image source, {SegmentDebug? debug}) {
    final oriented = img.bakeOrientation(source);
    var full = _readFrame(oriented, _workWidth, debug);
    debug?.call('full frame: score ${full.score} ${full.tokens}');
    if (full.score == 3) return full.tokens;

    // Nothing found: the digits may be too small at this scale (monitor far
    // from the camera), so look again with more detail.
    if (full.box == null && oriented.width > _workWidth * 2) {
      full = _readFrame(oriented, _workWidth * 2, debug);
      debug?.call('detailed frame: score ${full.score} ${full.tokens}');
      if (full.score == 3) return full.tokens;
    }

    // Digits that are small in the frame (monitor photographed from afar):
    // zoom in on them and read again at full resolution.
    final box = full.box;
    if (box != null && box.height < full.height * 0.45) {
      final crop = _cropAround(oriented, box, full.scale);
      final zoomed = _readFrame(crop, _workWidth, debug);
      debug?.call('zoomed: score ${zoomed.score} ${zoomed.tokens}');
      if (zoomed.score >= full.score) return zoomed.tokens;
    }
    return full.tokens;
  }

  static img.Image _cropAround(img.Image image, _Blob box, double scale) {
    final mx = math.max(20, box.width * scale * 0.4).round();
    final my = math.max(20, box.height * scale * 0.4).round();
    final left = math.max(0, (box.left * scale).round() - mx);
    final top = math.max(0, (box.top * scale).round() - my);
    final right = math.min(image.width, (box.right * scale).round() + mx);
    final bottom = math.min(image.height, (box.bottom * scale).round() + my);
    return img.copyCrop(
      image,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );
  }

  static _Result _readFrame(
    img.Image source,
    int workWidth,
    SegmentDebug? debug,
  ) {
    var image = source;
    var scale = 1.0;
    if (image.width > workWidth) {
      image = img.copyResize(image, width: workWidth);
      scale = source.width / image.width;
    }
    final w = image.width;
    final h = image.height;

    var gray = Uint8List(w * h);
    for (final p in image) {
      gray[p.y * w + p.x] = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b)
          .round()
          .clamp(0, 255);
    }
    // Light denoise: sensor noise would otherwise fragment the strokes.
    final raw = gray;
    gray = _boxBlur3(raw, w, h);
    var noise = 0;
    for (var i = 0; i < gray.length; i++) {
      noise += (gray[i] - raw[i]).abs();
    }
    debug?.call('noise ${(noise / gray.length).toStringAsFixed(2)}');
    // Clean photos score about 1; grainy low-light shots need more smoothing.
    final grainy = noise / gray.length > 6;
    if (grainy) gray = _boxBlur3(_boxBlur3(gray, w, h), w, h);
    // The smallest readable digit has strokes of a few pixels and well over
    // 50 pixels in all; anything smaller is a speck.
    final minPixels = grainy ? 40 : 8;

    // Background = morphological closing (max then min) with a kernel
    // wider than a segment stroke: removes dark digits, keeps shadows.
    // The opening (min then max) does the same for light digits.
    final k = math.max(15, (math.min(w, h) / 10).round()) | 1;
    final closing = _minFilter(_maxFilter(gray, w, h, k), w, h, k);
    final opening = _maxFilter(_minFilter(gray, w, h, k), w, h, k);

    // Strict contrast first; a looser pass rescues faint segments (LCD seen
    // at an angle, or highlights clipped by overexposure).
    var best = _Result(const [], -1, null, w, h, scale);
    for (final (ratio, floor) in const [(0.8, 18), (0.9, 12)]) {
      // Hysteresis: a stroke must have pixels clearly darker than the
      // background, but then keeps its fainter pixels too.
      final dark = _hysteresis(
        w,
        h,
        (i) => closing[i] > 0 && gray[i] < closing[i] * ratio &&
            closing[i] - gray[i] > floor,
        (i) => closing[i] > 0 && gray[i] < closing[i] * (ratio + 0.08) &&
            closing[i] - gray[i] > floor * 0.7,
        minPixels,
      );
      debug?.mask('dark$ratio', dark, w, h);
      var r = _readMask(dark, w, h, debug);
      debug?.call('dark-on-light $ratio: score ${r.score} ${r.tokens}');
      if (r.score > best.score) best = r;
      if (best.score == 3) break;

      final light = _hysteresis(
        w,
        h,
        (i) => gray[i] * ratio > opening[i] && gray[i] - opening[i] > floor,
        (i) => gray[i] * (ratio + 0.08) > opening[i] &&
            gray[i] - opening[i] > floor * 0.7,
        minPixels,
      );
      debug?.mask('light$ratio', light, w, h);
      r = _readMask(light, w, h, debug);
      debug?.call('light-on-dark $ratio: score ${r.score} ${r.tokens}');
      if (r.score > best.score) best = r;
      if (best.score == 3) break;
    }
    return _Result(best.tokens, best.score, best.box, w, h, scale);
  }

  /// Reads one foreground mask, straightening it if the digits are
  /// tilted or italic and the first attempt is incomplete.
  static _Result _readMask(Uint8List mask, int w, int h, SegmentDebug? debug) {
    var best = _tryGaps(mask, w, h, debug);
    // Nothing digit-like at all: this is the wrong polarity or threshold,
    // so straightening would be wasted work.
    if (best.tokens.isEmpty) return best;

    // A clear tilt distorts the digits enough to misread some (a "7" can
    // pass for a "9"), so a straightened reading wins even when the tilted
    // one looked complete.
    var straight = mask;
    final angle = best.angle;
    final degrees = angle.abs() * 180 / math.pi;
    if (degrees >= 5 || (best.score < 3 && degrees >= 2)) {
      straight = _rotate(mask, w, h, angle);
      debug?.mask('deskewed', straight, w, h);
      final r = _tryGaps(straight, w, h, debug);
      debug?.call(
        'deskew ${(angle * 180 / math.pi).toStringAsFixed(1)}°: '
        'score ${r.score} ${r.tokens}',
      );
      if (r.score >= best.score) best = r;
    }
    if (best.score == 3) return best;

    // Italic seven-segment fonts lean right; try straightening them.
    for (final shear in const [0.12, 0.24]) {
      final r = _tryGaps(_shear(straight, w, h, shear), w, h, debug);
      debug?.call('shear $shear: score ${r.score} ${r.tokens}');
      if (r.score > best.score) best = r;
      if (best.score == 3) return best;
    }
    return best;
  }

  /// Joins the segments of each digit. Gap sizes differ between displays
  /// (and with distance), so try a few and keep the most complete reading.
  static _Result _tryGaps(Uint8List mask, int w, int h, SegmentDebug? debug) {
    var best = _Result(const [], -1, null, w, h, 1);
    for (final divisor in const [40, 70, 25, 150]) {
      final gap = math.max(3, (math.min(w, h) / divisor).round()) | 1;
      final r = _readRows(mask, w, h, gap, debug);
      if (r.score > best.score) best = r;
      if (best.score == 3) break;
    }
    return best;
  }

  static _Result _readRows(
    Uint8List mask,
    int w,
    int h,
    int gap,
    SegmentDebug? debug,
  ) {
    // Grow the pixels so a digit's segments touch, but measure each blob
    // from the original pixels so its box stays tight.
    final grown = _maxFilter(mask, w, h, gap);
    final blobs = _components(
      grown,
      mask,
      w,
      h,
    ).where((b) => _isDigitShape(b, mask, w, h)).toList();
    if (blobs.isEmpty) return _Result(const [], 0, null, w, h, 1);

    // Labels like "SYS" or "mmHg" are much smaller than the readings, while
    // bezel edges can be taller. Digits come in groups, so the reference
    // height comes from a group that holds a decoded digit other than "1"
    // (any narrow bar passes as a "1").
    final decoded = {for (final b in blobs) b: _decode(b, mask, w)};
    bool real(_Blob b) => decoded[b] != null && decoded[b] != '1';
    debug?.call(
      '  gap $gap blobs ${blobs.map((b) => '${b.left},${b.top} '
          '${b.width}x${b.height}=${decoded[b] ?? '?'}'
          '(${_segmentNames(_segments(b, mask, w))})').join(' | ')}',
    );
    final groups = _groupLines(blobs, decoded);
    var candidates = groups
        .where((g) => g.length >= 2 && g.any(real))
        .expand((g) => g);
    if (candidates.isEmpty) candidates = blobs.where(real);
    if (candidates.isEmpty) candidates = blobs;
    final reference = candidates.map((b) => b.height).reduce(math.max);
    blobs.retainWhere((b) => b.height >= reference * 0.4);

    final lines = _groupLines(blobs, decoded);
    final tokens = <OcrToken>[];
    final read = <_Blob>[];
    for (var row in lines.expand(_splitRow)) {
      // Icons beside a number (a heart, an "OK" badge) are shorter than
      // its digits and never decode; ignore them at either end.
      final tallest = row.map((b) => b.height).reduce(math.max);
      bool icon(_Blob b) => decoded[b] == null && b.height < tallest * 0.8;
      while (row.length > 1 && icon(row.first)) {
        row = row.sublist(1);
      }
      while (row.length > 1 && icon(row.last)) {
        row = row.sublist(0, row.length - 1);
      }
      final text = StringBuffer();
      var complete = true;
      for (final blob in row) {
        final digit = decoded[blob];
        if (digit == null) complete = false;
        text.write(digit ?? '?');
      }
      debug?.call(
        '  gap $gap row ${row.map((b) => '${b.left},${b.top} '
            '${b.width}x${b.height}').join(' | ')} -> $text',
      );
      if (!complete) continue;
      final top = row.map((b) => b.top).reduce(math.min);
      final bottom = row.map((b) => b.bottom).reduce(math.max);
      read.addAll(row);
      tokens.add(
        OcrToken(
          text.toString(),
          top: top.toDouble(),
          left: row.first.left.toDouble(),
          height: (bottom - top).toDouble(),
        ),
      );
    }

    final parsed = BpParser.parse(tokens);
    final score = (parsed.isComplete ? 2 : 0) + (parsed.pulse != null ? 1 : 0);
    return _Result(
      tokens,
      score,
      read.isEmpty ? null : _union(read),
      w,
      h,
      1,
      angle: _estimateAngle(lines),
    );
  }

  static bool _isDigitShape(_Blob b, Uint8List mask, int w, int h) {
    if (b.height < math.max(10, h * 0.03) || b.height > h * 0.95) return false;
    if (b.width < 2) return false;
    // Shapes cut off by the frame edge are bezels, shadows or unreadable.
    if (b.left == 0 || b.top == 0 || b.right == w || b.bottom == h) {
      return false;
    }
    final aspect = b.width / b.height;
    if (aspect < 0.04 || aspect > 1.2) return false;
    var on = 0;
    for (var y = b.top; y < b.bottom; y++) {
      for (var x = b.left; x < b.right; x++) {
        on += mask[y * w + x];
      }
    }
    final fill = on / (b.width * b.height);
    // Digits are thin strokes; solid shapes and specks are not digits.
    return aspect < 0.35 ? fill > 0.3 : fill > 0.1 && fill < 0.75;
  }

  /// Groups blobs that sit on the same line, left to right.
  ///
  /// Readable digits seed the lines, so that a stray shape cannot start a
  /// line and capture half a number.
  static List<List<_Blob>> _groupLines(
    List<_Blob> blobs,
    Map<_Blob, String?> decoded,
  ) {
    int rank(_Blob b) => decoded[b] == null ? 2 : (decoded[b] == '1' ? 1 : 0);
    final sorted = [...blobs]
      ..sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0 ? byRank : a.top.compareTo(b.top);
      });
    final lines = <List<_Blob>>[];
    for (final blob in sorted) {
      final line = lines.where((l) => _sameLine(l.first, blob)).firstOrNull;
      line == null ? lines.add([blob]) : line.add(blob);
    }
    for (final line in lines) {
      line.sort((a, b) => a.left.compareTo(b.left));
    }
    return lines;
  }

  /// Splits a line at wide gaps: "12 34" is two numbers, not one.
  ///
  /// A "1" sits at the right of its cell, so the gap before it can be
  /// almost a full cell; only gaps wider than that split the line. Runs of
  /// more than three digits are then split at their widest gap.
  static List<List<_Blob>> _splitRow(List<_Blob> line) {
    final height = line.map((b) => b.height).reduce(math.max);
    final result = <List<_Blob>>[];
    var current = <_Blob>[line.first];
    for (final blob in line.skip(1)) {
      final gap = blob.left - current.last.right;
      if (gap > height * 1.2) {
        result.add(current);
        current = [blob];
      } else {
        current.add(blob);
      }
    }
    result.add(current);
    return result.expand(_splitLong).toList();
  }

  static List<List<_Blob>> _splitLong(List<_Blob> row) {
    if (row.length <= 3) return [row];
    var widest = 1;
    for (var i = 2; i < row.length; i++) {
      if (row[i].left - row[i - 1].right >
          row[widest].left - row[widest - 1].right) {
        widest = i;
      }
    }
    return [
      ..._splitLong(row.sublist(0, widest)),
      ..._splitLong(row.sublist(widest)),
    ];
  }

  /// Digits on one line overlap vertically and have similar heights
  /// (a "1" is a little shorter, having no top or bottom segment).
  static bool _sameLine(_Blob a, _Blob b) {
    final overlap = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
    final shorter = math.min(a.height, b.height);
    final taller = math.max(a.height, b.height);
    final centres = ((a.top + a.bottom) - (b.top + b.bottom)).abs() / 2;
    return overlap > shorter * 0.6 &&
        shorter > taller * 0.65 &&
        centres < taller * 0.3;
  }

  /// Tilt of the photo, from the slope of each line of digits.
  static double _estimateAngle(List<List<_Blob>> lines) {
    final angles = <double>[];
    for (final line in lines) {
      if (line.length < 2) continue;
      var sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0;
      for (final b in line) {
        final x = (b.left + b.right) / 2, y = (b.top + b.bottom) / 2;
        sx += x;
        sy += y;
        sxx += x * x;
        sxy += x * y;
      }
      final n = line.length;
      final denominator = n * sxx - sx * sx;
      if (denominator.abs() < 1e-6) continue;
      angles.add(math.atan((n * sxy - sx * sy) / denominator));
    }
    if (angles.isEmpty) return 0;
    angles.sort();
    return angles[angles.length ~/ 2];
  }

  /// Decodes a digit from its strokes: a horizontal segment shows up as a
  /// long run of pixels in a row, a vertical one as a long run in a column
  /// of the top or bottom half. Thresholds scale with the stroke thickness.
  static String? _decode(_Blob b, Uint8List mask, int w) {
    final bits = _segments(b, mask, w);
    if (bits == _one) return '1';
    if (bits < 0) return null;
    final exact = _digits[bits];
    if (exact != null) return exact;

    // Tolerate one misread segment if only one digit is that close.
    final close = _digits.entries
        .where((e) => _bitCount(e.key ^ bits) == 1)
        .map((e) => e.value)
        .toSet();
    return close.length == 1 ? close.first : null;
  }

  static const _one = 1 << 7;

  static String _segmentNames(int bits) {
    if (bits == _one) return '1';
    if (bits < 0) return '-';
    const names = 'abcdefg';
    return [
      for (var i = 0; i < 7; i++)
        if (bits & (1 << i) != 0) names[i],
    ].join();
  }

  /// Lit segments of a blob as a bit set, [_one] for a bare "1" shape, or
  /// -1 for a shape that cannot be a digit.
  ///
  /// A horizontal segment is a long run of pixels through the centre
  /// column; a vertical one is a long run through the quarter-height row of
  /// the top or bottom half, on the left or right side. Measuring through
  /// those points ignores specks and shadow fragments stuck to the digit.
  static int _segments(_Blob b, Uint8List mask, int w) {
    final bw = b.width, bh = b.height;

    final runs = <int>[];
    for (var y = 0; y < bh; y++) {
      var longest = 0, run = 0;
      final offset = (b.top + y) * w + b.left;
      for (var x = 0; x < bw; x++) {
        if (mask[offset + x] == 1) {
          run++;
          if (run > longest) longest = run;
        } else {
          run = 0;
        }
      }
      if (longest > 0) runs.add(longest);
    }
    if (runs.isEmpty) return -1;
    runs.sort();
    // Most rows cut across a vertical stroke, so the median run is the
    // stroke thickness.
    final t = runs[runs.length ~/ 2];
    // A tall shape no wider than a stroke is a "1".
    if (bw <= t * 2.2) return bw < bh * 0.5 ? _one : -1;

    // A real segment is centred: it must reach past both ends of the
    // middle fifth of the digit (horizontal) or of its half (vertical).
    final centre = b.left + bw ~/ 2;
    final hFrom = b.left + (bw * 0.4).floor(), hTo = b.left + (bw * 0.6).ceil();
    final rowRun = Int32List(bh);
    for (var y = 0; y < bh; y++) {
      rowRun[y] = _runThrough(
        mask,
        w,
        centre,
        b.top + y,
        b.left,
        b.right,
        hFrom,
        hTo,
        1,
        0,
      );
    }
    final half = bh ~/ 2;
    final upper = b.top + bh ~/ 4, lower = b.top + half + bh ~/ 4;
    final colTop = Int32List(bw), colBottom = Int32List(bw);
    for (var x = 0; x < bw; x++) {
      colTop[x] = _runThrough(
        mask,
        w,
        b.left + x,
        upper,
        b.top,
        b.top + half,
        b.top + (bh * 0.25).floor(),
        b.top + (bh * 0.32).ceil(),
        0,
        1,
      );
      colBottom[x] = _runThrough(
        mask,
        w,
        b.left + x,
        lower,
        b.top + half,
        b.bottom,
        b.top + (bh * 0.68).floor(),
        b.top + (bh * 0.75).ceil(),
        0,
        1,
      );
    }

    final hThreshold = math.max(1.25 * t, 0.5 * (bw - 2 * t));
    final vThreshold = math.max(1.3 * t, 0.5 * (half - 1.5 * t));
    bool horizontal(double y0, double y1) =>
        _maxIn(rowRun, (bh * y0).floor(), (bh * y1).ceil()) >= hThreshold;
    final leftEnd = (bw * 0.45).round(), rightStart = (bw * 0.55).round();
    bool vertical(Int32List runs, int from, int to) =>
        _maxIn(runs, from, to) >= vThreshold;

    var bits = 0;
    if (horizontal(0, 0.3)) bits |= _a;
    if (horizontal(0.35, 0.65)) bits |= _g;
    if (horizontal(0.7, 1.0)) bits |= _d;
    if (vertical(colTop, 0, leftEnd)) bits |= _f;
    if (vertical(colTop, rightStart, bw)) bits |= _b;
    if (vertical(colBottom, 0, leftEnd)) bits |= _e;
    if (vertical(colBottom, rightStart, bw)) bits |= _c;

    // The regions of unlit segments must be mostly empty, otherwise this
    // is a cluster of noise or an icon that happens to contain strokes.
    double fill(int x0, int y0, int x1, int y1) {
      var on = 0, total = 0;
      for (var y = math.max(y0, 0); y < math.min(y1, bh); y++) {
        for (var x = math.max(x0, 0); x < math.min(x1, bw); x++) {
          on += mask[(b.top + y) * w + b.left + x];
          total++;
        }
      }
      return total == 0 ? 0 : on / total;
    }

    final mid = half - t ~/ 2;
    final regions = <int, double Function()>{
      _a: () => fill(t, 0, bw - t, t),
      _b: () => fill(bw - t, t, bw, mid),
      _c: () => fill(bw - t, mid + t, bw, bh - t),
      _d: () => fill(t, bh - t, bw - t, bh),
      _e: () => fill(0, mid + t, t, bh - t),
      _f: () => fill(0, t, t, mid),
      _g: () => fill(t, mid, bw - t, mid + t),
    };
    for (final entry in regions.entries) {
      if (bits & entry.key == 0 && entry.value() > 0.6) return -1;
    }
    return bits;
  }

  /// Length of the run of set pixels through ([x], [y]) along direction
  /// ([dx], [dy]), limited to [from, to) on that axis. Returns 0 if the
  /// pixel is off or the run does not cover [coverFrom, coverTo].
  static int _runThrough(
    Uint8List mask,
    int w,
    int x,
    int y,
    int from,
    int to,
    int coverFrom,
    int coverTo,
    int dx,
    int dy,
  ) {
    if (mask[y * w + x] != 1) return 0;
    var end = dx != 0 ? x : y;
    for (var i = 1;; i++) {
      final px = x + dx * i, py = y + dy * i;
      final along = dx != 0 ? px : py;
      if (along >= to || mask[py * w + px] != 1) break;
      end = along;
    }
    var start = dx != 0 ? x : y;
    for (var i = 1;; i++) {
      final px = x - dx * i, py = y - dy * i;
      final along = dx != 0 ? px : py;
      if (along < from || mask[py * w + px] != 1) break;
      start = along;
    }
    if (start > coverFrom || end < coverTo - 1) return 0;
    return end - start + 1;
  }

  static int _maxIn(Int32List values, int from, int to) {
    var m = 0;
    for (var i = math.max(0, from); i < math.min(values.length, to); i++) {
      if (values[i] > m) m = values[i];
    }
    return m;
  }

  static int _bitCount(int v) {
    var count = 0;
    for (; v != 0; v &= v - 1) {
      count++;
    }
    return count;
  }

  static _Blob _union(List<_Blob> blobs) => _Blob(
    blobs.map((b) => b.left).reduce(math.min),
    blobs.map((b) => b.top).reduce(math.min),
    blobs.map((b) => b.right).reduce(math.max),
    blobs.map((b) => b.bottom).reduce(math.max),
  );

  // --- Image helpers -------------------------------------------------------

  /// Pixels passing [weak] that are connected to a pixel passing [strong].
  /// Shapes smaller than [minPixels] are specks (noise) and dropped.
  static Uint8List _hysteresis(
    int w,
    int h,
    bool Function(int) strong,
    bool Function(int) weak,
    int minPixels,
  ) {
    final out = Uint8List(w * h);
    final stack = <int>[];
    final shape = <int>[];
    for (var start = 0; start < out.length; start++) {
      if (out[start] == 1 || !strong(start)) continue;
      out[start] = 1;
      stack.add(start);
      shape.clear();
      while (stack.isNotEmpty) {
        final i = stack.removeLast();
        shape.add(i);
        final x = i % w, y = i ~/ w;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final nx = x + dx, ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
            final n = ny * w + nx;
            if (out[n] == 0 && weak(n)) {
              out[n] = 1;
              stack.add(n);
            }
          }
        }
      }
      if (shape.length < minPixels) {
        for (final i in shape) {
          out[i] = 2; // visited, but not foreground
        }
      }
    }
    for (var i = 0; i < out.length; i++) {
      if (out[i] == 2) out[i] = 0;
    }
    return out;
  }

  static Uint8List _boxBlur3(Uint8List src, int w, int h) {
    final tmp = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      final row = y * w;
      for (var x = 0; x < w; x++) {
        final l = x > 0 ? src[row + x - 1] : src[row + x];
        final r = x < w - 1 ? src[row + x + 1] : src[row + x];
        tmp[row + x] = (l + src[row + x] + r) ~/ 3;
      }
    }
    final out = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      final up = y > 0 ? y - 1 : y, down = y < h - 1 ? y + 1 : y;
      for (var x = 0; x < w; x++) {
        out[y * w + x] =
            (tmp[up * w + x] + tmp[y * w + x] + tmp[down * w + x]) ~/ 3;
      }
    }
    return out;
  }

  /// Straightens lines tilted by [angle] radians (nearest pixel): each
  /// output pixel samples the source rotated by [angle] about the centre.
  static Uint8List _rotate(Uint8List mask, int w, int h, double angle) {
    final out = Uint8List(w * h);
    final cos = math.cos(angle), sin = math.sin(angle);
    final cx = w / 2, cy = h / 2;
    for (var y = 0; y < h; y++) {
      final dy = y - cy;
      for (var x = 0; x < w; x++) {
        final dx = x - cx;
        final sx = (cx + dx * cos - dy * sin).round();
        final sy = (cy + dx * sin + dy * cos).round();
        if (sx < 0 || sy < 0 || sx >= w || sy >= h) continue;
        out[y * w + x] = mask[sy * w + sx];
      }
    }
    return out;
  }

  /// Straightens right-leaning digits: shifts rows above the centre left.
  static Uint8List _shear(Uint8List mask, int w, int h, double shear) {
    final out = Uint8List(w * h);
    final cy = h / 2;
    for (var y = 0; y < h; y++) {
      final shift = (shear * (cy - y)).round();
      for (var x = 0; x < w; x++) {
        final sx = x + shift;
        if (sx < 0 || sx >= w) continue;
        out[y * w + x] = mask[y * w + sx];
      }
    }
    return out;
  }

  static Uint8List _maxFilter(Uint8List src, int w, int h, int k) => _slide(
    _slide(src, w, h, k, horizontal: true, max: true),
    w,
    h,
    k,
    horizontal: false,
    max: true,
  );

  static Uint8List _minFilter(Uint8List src, int w, int h, int k) => _slide(
    _slide(src, w, h, k, horizontal: true, max: false),
    w,
    h,
    k,
    horizontal: false,
    max: false,
  );

  /// Sliding-window max/min along rows or columns (monotonic deque, O(n)).
  static Uint8List _slide(
    Uint8List src,
    int w,
    int h,
    int k, {
    required bool horizontal,
    required bool max,
  }) {
    final out = Uint8List(w * h);
    final lines = horizontal ? h : w;
    final length = horizontal ? w : h;
    final r = k ~/ 2;
    final deque = Int32List(length);
    for (var line = 0; line < lines; line++) {
      int at(int i) => horizontal ? line * w + i : i * w + line;
      var head = 0, tail = 0, next = 0;
      for (var i = 0; i < length; i++) {
        final end = math.min(length - 1, i + r);
        while (next <= end) {
          final v = src[at(next)];
          while (tail > head) {
            final last = src[at(deque[tail - 1])];
            if (max ? last > v : last < v) break;
            tail--;
          }
          deque[tail++] = next++;
        }
        while (deque[head] < i - r) {
          head++;
        }
        out[at(i)] = src[at(deque[head])];
      }
    }
    return out;
  }

  /// Connected regions of [mask]; boxes cover only pixels set in [raw].
  static List<_Blob> _components(Uint8List mask, Uint8List raw, int w, int h) {
    final seen = Uint8List(w * h);
    final blobs = <_Blob>[];
    final stack = <int>[];
    for (var start = 0; start < mask.length; start++) {
      if (mask[start] == 0 || seen[start] == 1) continue;
      var left = w, right = 0, top = h, bottom = 0;
      stack.add(start);
      seen[start] = 1;
      while (stack.isNotEmpty) {
        final i = stack.removeLast();
        final x = i % w, y = i ~/ w;
        if (raw[i] == 1) {
          left = math.min(left, x);
          right = math.max(right, x);
          top = math.min(top, y);
          bottom = math.max(bottom, y);
        }
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final nx = x + dx, ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
            final n = ny * w + nx;
            if (mask[n] == 1 && seen[n] == 0) {
              seen[n] = 1;
              stack.add(n);
            }
          }
        }
      }
      if (right >= left) blobs.add(_Blob(left, top, right + 1, bottom + 1));
    }
    return blobs;
  }
}

class _Result {
  final List<OcrToken> tokens;
  final int score;
  final _Blob? box;
  final int width, height;
  final double scale;
  final double angle;

  _Result(
    this.tokens,
    this.score,
    this.box,
    this.width,
    this.height,
    this.scale, {
    this.angle = 0,
  });
}

class _Blob {
  final int left, top, right, bottom;

  _Blob(this.left, this.top, this.right, this.bottom);

  int get width => right - left;
  int get height => bottom - top;
}
