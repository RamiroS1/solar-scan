import 'dart:ui';

import '../models.dart';
import 'geo.dart';

/// Sugerencias de dimensionamiento a partir del consumo declarado.
class SizingHints {
  static const defaultSpecificYield = 1500.0;
  static const defaultCoverage = 0.90;
  static const defaultUsableRatio = 0.85;

  /// kWp sugerido para cubrir [annualKwh] con [coverage] del consumo.
  static double suggestedKwp(
    double annualKwh, {
    double coverage = defaultCoverage,
    double specificYield = defaultSpecificYield,
  }) {
    if (annualKwh <= 0 || specificYield <= 0) return 0;
    return (annualKwh * coverage) / specificYield;
  }

  /// Area REAL inclinada aproximada para instalar [kwp] con [module].
  static double suggestedSlopedAreaM2(
    double kwp,
    PanelModule module, {
    double usableRatio = defaultUsableRatio,
  }) {
    if (kwp <= 0 || module.wp <= 0) return 0;
    final panelCount = (kwp * 1000 / module.wp).ceil();
    return panelCount * module.areaM2 / usableRatio;
  }

  /// Area REAL sugerida para un proyecto segun su consumo.
  static double suggestedAreaForProject(Project p) =>
      suggestedSlopedAreaM2(
        suggestedKwp(p.annualConsumptionKwh),
        p.module,
      );

  static String consumptionHint(Project p) {
    final kwp = suggestedKwp(p.annualConsumptionKwh);
    final area = suggestedSlopedAreaM2(kwp, p.module);
    if (p.annualConsumptionKwh <= 0) return '';
    return 'Consumo ${p.annualConsumptionKwh.round()} kWh/ano → '
        '~${kwp.toStringAsFixed(1)} kWp → ~${area.round()} m² de techo util';
  }
}

/// Potencia instantanea ilustrativa (no contractual).
class InstantPowerSimulation {
  static const peakFactor = 0.86;
  static const selfConsumptionShare = 0.37;

  static ({double peakKw, double toHomeKw, double toGridKw}) forKwp(double kwp) {
    final peak = kwp * peakFactor;
    final toHome = peak * selfConsumptionShare;
    return (peakKw: peak, toHomeKw: toHome, toGridKw: peak - toHome);
  }
}
