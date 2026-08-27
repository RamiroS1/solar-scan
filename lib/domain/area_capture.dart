import 'dart:math' as math;
import 'dart:ui';

import '../models.dart';
import 'geo.dart';

enum AreaTargetStatus { none, onTarget, under, over }

/// Retroalimentacion al comparar area medida vs objetivo.
class AreaTargetFeedback {
  final double? targetM2;
  final double currentM2;
  final double deltaM2;
  final AreaTargetStatus status;
  final String message;

  const AreaTargetFeedback({
    required this.targetM2,
    required this.currentM2,
    required this.deltaM2,
    required this.status,
    required this.message,
  });

  bool get hasTarget => targetM2 != null && targetM2! > 0;
}

/// Utilidades para captura de area: rectangulos por dimensiones y objetivo.
class AreaCapture {
  static const defaultAspectRatio = 1.25;

  /// Rectangulo centrado en origen (ancho x largo en planta).
  static List<Offset> rectangleOutline({
    required double widthM,
    required double heightM,
  }) {
    final hw = widthM / 2, hh = heightM / 2;
    return [
      Offset(-hw, -hh),
      Offset(hw, -hh),
      Offset(hw, hh),
      Offset(-hw, hh),
    ];
  }

  /// Dimensiones de planta para alcanzar un area REAL inclinada objetivo.
  static ({double widthM, double heightM, double planAreaM2}) dimensionsForSlopedArea({
    required double targetSlopedM2,
    required double tiltDeg,
    double aspectRatio = defaultAspectRatio,
  }) {
    final plan = Geo.planAreaFromSloped(targetSlopedM2, tiltDeg);
    final h = math.sqrt(plan / aspectRatio);
    final w = h * aspectRatio;
    return (widthM: w, heightM: h, planAreaM2: plan);
  }

  static AreaTargetFeedback evaluate({
    required double currentSlopedM2,
    required double? targetSlopedM2,
    double toleranceM2 = 2.0,
  }) {
    if (targetSlopedM2 == null || targetSlopedM2 <= 0) {
      return AreaTargetFeedback(
        targetM2: null,
        currentM2: currentSlopedM2,
        deltaM2: 0,
        status: AreaTargetStatus.none,
        message: 'Sin area objetivo definida',
      );
    }
    final delta = currentSlopedM2 - targetSlopedM2;
    if (delta.abs() <= toleranceM2) {
      return AreaTargetFeedback(
        targetM2: targetSlopedM2,
        currentM2: currentSlopedM2,
        deltaM2: delta,
        status: AreaTargetStatus.onTarget,
        message:
            'Objetivo alcanzado (${currentSlopedM2.toStringAsFixed(1)} m²)',
      );
    }
    if (delta < 0) {
      return AreaTargetFeedback(
        targetM2: targetSlopedM2,
        currentM2: currentSlopedM2,
        deltaM2: delta,
        status: AreaTargetStatus.under,
        message:
            'Faltan ${(-delta).toStringAsFixed(1)} m² para ${targetSlopedM2.toStringAsFixed(0)} m²',
      );
    }
    return AreaTargetFeedback(
      targetM2: targetSlopedM2,
      currentM2: currentSlopedM2,
      deltaM2: delta,
      status: AreaTargetStatus.over,
      message:
          'Sobran ${delta.toStringAsFixed(1)} m² respecto a ${targetSlopedM2.toStringAsFixed(0)} m²',
    );
  }
}
