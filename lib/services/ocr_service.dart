import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import 'bp_parser.dart';
import 'seven_segment.dart';

/// Reads blood-pressure values from a photo of a monitor.
///
/// Combines ML Kit text recognition with [SevenSegmentReader], which
/// handles the segmented LCD digits that ML Kit often misses. ML Kit still
/// helps with monitors that print digits in a regular font.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Runs both readers at once: ML Kit natively, the seven-segment reader
  /// in a background isolate. ML Kit alone often drops a digit from LCD
  /// numbers ("23" for "123"), so its answer never short-circuits the
  /// segment reader; see [_combine].
  Future<ParsedReading> readMonitor(String imagePath) async {
    final results = await Future.wait([
      _readText(imagePath).catchError((Object e) {
        debugPrint('ML Kit failed: $e');
        return const ParsedReading();
      }),
      compute(_readSegments, imagePath).catchError((Object e) {
        debugPrint('Seven-segment reader failed: $e');
        return const ParsedReading();
      }),
    ]);
    return _combine(results[1], results[0]);
  }

  Future<ParsedReading> _readText(String imagePath) async {
    final result = await _recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );

    final tokens = <OcrToken>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        // Whole line first so "120/80" survives, then individual words.
        tokens.add(_token(line.text, line.boundingBox));
        if (line.elements.length > 1) {
          for (final element in line.elements) {
            tokens.add(_token(element.text, element.boundingBox));
          }
        }
      }
    }
    return BpParser.parse(tokens);
  }

  OcrToken _token(String text, Rect box) =>
      OcrToken(text, top: box.top, left: box.left, height: box.height);

  Future<void> dispose() => _recognizer.close();
}

/// Runs in a background isolate: decoding and scanning a photo takes a
/// moment and must not freeze the UI.
ParsedReading _readSegments(String imagePath) {
  final image = img.decodeImage(File(imagePath).readAsBytesSync());
  if (image == null) return const ParsedReading();
  return BpParser.parse(SevenSegmentReader.read(image));
}

/// Prefers the seven-segment result (built for LCD digits), borrowing the
/// pulse from the text result when both agree on the pressure values.
ParsedReading _combine(ParsedReading segments, ParsedReading text) {
  if (segments.isComplete) {
    final sameReading =
        segments.systolic == text.systolic &&
        segments.diastolic == text.diastolic;
    return ParsedReading(
      systolic: segments.systolic,
      diastolic: segments.diastolic,
      pulse: segments.pulse ?? (sameReading ? text.pulse : null),
    );
  }
  if (text.isComplete) return text;
  return ParsedReading(
    systolic: segments.systolic ?? text.systolic,
    diastolic: segments.diastolic ?? text.diastolic,
    pulse: segments.pulse ?? text.pulse,
  );
}
