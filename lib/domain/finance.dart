import 'dart:math' as math;

import '../models.dart';
import 'system_quote.dart';

/// Analisis financiero del proyecto.
class Finance {
  static FinancialResult analyze({
    required double annualKwh,
    required double kwp,
    required FinancialInputs i,
    Project? project,
  }) {
    final breakdown = project != null
        ? SystemQuote.buildBreakdown(project)
        : null;
    final capex = breakdown?.total ??
        i.costPerWp * kwp * 1000 + (project?.system.includeBattery == true
            ? (project?.system.battery?.price ?? 0)
            : 0);
    final flow = <double>[-capex];
    final cum = <double>[-capex];

    for (int y = 1; y <= i.horizonYears; y++) {
      final prod = annualKwh * math.pow(1 - i.degradation, y - 1);
      final tariff = i.tariffPerKwh * math.pow(1 + i.escalation, y - 1);
      final savings = prod * i.selfConsumption * tariff;
      flow.add(savings);
      cum.add(cum.last + savings);
    }

    return FinancialResult(
      capex: capex,
      firstYear: flow.length > 1 ? flow[1] : 0,
      payback: _payback(cum),
      cumulative: cum.last + capex,
      npv: _npv(flow, i.discountRate),
      irr: _irr(flow),
      cumulativeFlow: cum,
      breakdown: breakdown,
    );
  }

  static double _payback(List<double> cum) {
    for (int i = 1; i < cum.length; i++) {
      if (cum[i] >= 0) {
        final prev = cum[i - 1];
        final d = cum[i] - prev;
        if (d.abs() < 1e-9) return i.toDouble();
        return (i - 1) + (-prev / d);
      }
    }
    return -1;
  }

  static double _npv(List<double> f, double r) {
    double v = 0;
    for (int t = 0; t < f.length; t++) {
      v += f[t] / math.pow(1 + r, t);
    }
    return v;
  }

  static double? _irr(List<double> f) {
    double fn(double r) => _npv(f, r);
    double lo = -0.9, hi = 2.0;
    if (fn(lo).sign == fn(hi).sign) return null;
    for (int i = 0; i < 160; i++) {
      final mid = (lo + hi) / 2;
      if (fn(lo).sign == fn(mid).sign) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }
}

String money(double v) {
  final s = v.round().abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return (v < 0 ? '-' : '') + b.toString();
}
