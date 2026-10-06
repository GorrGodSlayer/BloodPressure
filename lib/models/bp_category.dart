import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Blood-pressure categories per the 2017 ACC/AHA guideline.
/// Informational only, not a diagnosis.
enum BpCategory {
  normal(Color(0xFF2E7D32)),
  elevated(Color(0xFFF9A825)),
  stage1(Color(0xFFEF6C00)),
  stage2(Color(0xFFC62828)),
  crisis(Color(0xFF6A1B9A));

  final Color color;

  const BpCategory(this.color);

  static BpCategory of(int systolic, int diastolic) {
    if (systolic > 180 || diastolic > 120) return crisis;
    if (systolic >= 140 || diastolic >= 90) return stage2;
    if (systolic >= 130 || diastolic >= 80) return stage1;
    if (systolic >= 120) return elevated;
    return normal;
  }

  String label(AppLocalizations l) => switch (this) {
    normal => l.catNormal,
    elevated => l.catElevated,
    stage1 => l.catStage1,
    stage2 => l.catStage2,
    crisis => l.catCrisis,
  };

  /// Threshold description, e.g. "130–139 or 80–89".
  String range(AppLocalizations l) => switch (this) {
    normal => l.catNormalRange,
    elevated => l.catElevatedRange,
    stage1 => l.catStage1Range,
    stage2 => l.catStage2Range,
    crisis => l.catCrisisRange,
  };
}
