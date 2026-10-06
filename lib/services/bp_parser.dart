/// Extracts systolic / diastolic / pulse values from OCR output of a
/// blood-pressure monitor display.
///
/// Monitors almost always show SYS on top, DIA below it and PULSE last,
/// with SYS/DIA in the largest digits. The parser collects plausible
/// 2–3 digit numbers, orders them top-to-bottom, and picks the
/// combination that best fits those rules.
library;

class OcrToken {
  final String text;
  final double top;
  final double left;
  final double height;

  const OcrToken(this.text, {this.top = 0, this.left = 0, this.height = 1});
}

class ParsedReading {
  final int? systolic;
  final int? diastolic;
  final int? pulse;

  const ParsedReading({this.systolic, this.diastolic, this.pulse});

  bool get isComplete => systolic != null && diastolic != null;

  @override
  String toString() => 'ParsedReading($systolic/$diastolic, pulse $pulse)';
}

class _Candidate {
  final int value;
  final double top;
  final double left;
  final double height;

  _Candidate(this.value, this.top, this.left, this.height);
}

class BpParser {
  static const sysRange = (min: 70, max: 260);
  static const diaRange = (min: 35, max: 160);
  static const pulseRange = (min: 30, max: 220);

  static final _slashPair = RegExp(r'^(\d{2,3})\s*/\s*(\d{2,3})$');
  static final _number = RegExp(r'^\d{2,3}$');

  // Characters that seven-segment digits are commonly misread as.
  static const _lookalikes = {
    'O': '0',
    'o': '0',
    'D': '0',
    'Q': '0',
    'I': '1',
    'l': '1',
    '|': '1',
    'i': '1',
    '!': '1',
    'Z': '2',
    'z': '2',
    'S': '5',
    's': '5',
    'G': '6',
    'b': '6',
    'T': '7',
    'B': '8',
    'g': '9',
    'q': '9',
  };

  static ParsedReading parse(List<OcrToken> tokens) {
    final candidates = <_Candidate>[];
    final seen = <String>{};

    void add(int value, double top, double left, double height) {
      // The OCR service feeds both whole lines and their words; skip
      // numbers already collected at the same position.
      final key = '$value@${top.round()}';
      if (seen.add(key)) {
        candidates.add(_Candidate(value, top, left, height));
      }
    }

    for (final token in tokens) {
      final text = token.text.trim();

      // Some displays (or OCR merges) produce "120/80" directly.
      final pair = _slashPair.firstMatch(text);
      if (pair != null) {
        final sys = int.parse(pair.group(1)!);
        final dia = int.parse(pair.group(2)!);
        if (_isValidPair(sys, dia)) {
          add(sys, token.top, token.left, token.height);
          add(dia, token.top + 0.5, token.left + 1, token.height);
          continue;
        }
      }

      for (final part in text.split(RegExp(r'\s+'))) {
        // Times (12:34) and dates (06/10, 06-10) are not readings.
        if (part.contains(RegExp(r'[:/\-.,]'))) continue;
        final value = _toNumber(part);
        if (value != null) add(value, token.top, token.left, token.height);
      }
    }

    return _choose(candidates);
  }

  static int? _toNumber(String raw) {
    if (raw.isEmpty || raw.length > 3) return null;
    // Only apply look-alike substitution if the token already contains a
    // digit, otherwise words like "SYS" or "Dia" would become numbers.
    if (!raw.contains(RegExp(r'\d'))) return null;
    final normalized = raw.split('').map((c) => _lookalikes[c] ?? c).join();
    if (!_number.hasMatch(normalized)) return null;
    final value = int.parse(normalized);
    return value >= pulseRange.min && value <= sysRange.max ? value : null;
  }

  static bool _inRange(int v, ({int min, int max}) r) =>
      v >= r.min && v <= r.max;

  static bool _isValidPair(int sys, int dia) =>
      _inRange(sys, sysRange) &&
      _inRange(dia, diaRange) &&
      sys - dia >= 10 &&
      sys - dia <= 150;

  static ParsedReading _choose(List<_Candidate> all) {
    if (all.isEmpty) return const ParsedReading();

    // Keep the search small; the real values are nearly always among the
    // largest digits on screen.
    var c = all;
    if (c.length > 12) {
      c = ([
        ...c,
      ]..sort((a, b) => b.height.compareTo(a.height))).take(12).toList();
    }
    // Reading order: top to bottom, then left to right.
    c = [...c]
      ..sort((a, b) {
        final byTop = a.top.compareTo(b.top);
        return byTop != 0 ? byTop : a.left.compareTo(b.left);
      });

    final maxHeight = c.map((e) => e.height).reduce((a, b) => a > b ? a : b);
    double h(_Candidate x) => maxHeight > 0 ? x.height / maxHeight : 1;

    var bestScore = double.negativeInfinity;
    var best = const ParsedReading();

    for (var i = 0; i < c.length; i++) {
      for (var j = i + 1; j < c.length; j++) {
        final sys = c[i], dia = c[j];
        if (!_isValidPair(sys.value, dia.value)) continue;

        // Bigger digits and earlier position win.
        final pairScore = h(sys) + h(dia) - (i + j) * 0.01;

        if (pairScore > bestScore) {
          bestScore = pairScore;
          best = ParsedReading(systolic: sys.value, diastolic: dia.value);
        }

        for (var k = j + 1; k < c.length; k++) {
          final pul = c[k];
          if (!_inRange(pul.value, pulseRange)) continue;
          final score = pairScore + 0.5 * h(pul) + 0.25 - k * 0.01;
          if (score > bestScore) {
            bestScore = score;
            best = ParsedReading(
              systolic: sys.value,
              diastolic: dia.value,
              pulse: pul.value,
            );
          }
        }
      }
    }

    return best;
  }
}
