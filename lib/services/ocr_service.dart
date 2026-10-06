import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'bp_parser.dart';

/// Runs on-device ML Kit text recognition on a photo of a monitor.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<ParsedReading> readMonitor(String imagePath) async {
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
