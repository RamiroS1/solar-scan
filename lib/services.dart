import 'dart:math' as math;
import 'dart:ui';

import 'models.dart';

double _rad(double d) => d * math.pi / 180.0;
double _deg(double r) => r * 180.0 / math.pi;

// ===========================================================================
// GEOMETRIA
// ===========================================================================

class Geo {
  /// Area de un poligono plano (formula del zapatero), en m2.
  static double polygonArea(List<Offset> p) {
    if (p.length < 3) return 0;
    double s = 0;
    for (int i = 0; i < p.length; i++) {
      final a = p[i], b = p[(i + 1) % p.length];
      s += a.dx * b.dy - b.dx * a.dy;
    }
    return s.abs() / 2;
  }

  static double perimeter(List<Offset> p) {
    if (p.length < 2) return 0;
    double s = 0;
    for (int i = 0; i < p.length; i++) {
      s += (p[(i + 1) % p.length] - p[i]).distance;
    }
    return s;
  }

  /// El poligono capturado es la proyeccion en planta: el area REAL sobre la
  /// teja se obtiene dividiendo por el coseno de la inclinacion.
  static double slopedArea(double planArea, double tiltDeg) {
    final c = math.cos(_rad(tiltDeg));
    return c.abs() < 1e-6 ? planArea : planArea / c;
  }

  static double facetArea(RoofFacet f) =>
      slopedArea(polygonArea(f.outline), f.tiltDeg);

  static double usableArea(RoofFacet f) {
    double blocked = 0;
    for (final o in f.obstacles) {
      blocked += slopedArea(polygonArea(o.outline), f.tiltDeg) +
          perimeter(o.outline) * o.clearanceM;
    }
    return math.max(0, facetArea(f) - blocked);
  }

  static Offset centroid(List<Offset> p) {
    double x = 0, y = 0;
    for (final q in p) {
      x += q.dx;
      y += q.dy;
    }
    return Offset(x / p.length, y / p.length);
  }

  static (Offset, Offset) bounds(List<Offset> p) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final q in p) {
      minX = math.min(minX, q.dx);
      minY = math.min(minY, q.dy);
      maxX = math.max(maxX, q.dx);
      maxY = math.max(maxY, q.dy);
    }
    return (Offset(minX, minY), Offset(maxX, maxY));
  }

  static bool pointInPolygon(Offset p, List<Offset> poly) {
    bool inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final pi = poly[i], pj = poly[j];
      final hit = ((pi.dy > p.dy) != (pj.dy > p.dy)) &&
          (p.dx <
              (pj.dx - pi.dx) * (p.dy - pi.dy) / ((pj.dy - pi.dy) + 1e-12) +
                  pi.dx);
      if (hit) inside = !inside;
    }
    return inside;
  }

  static double _distToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 < 1e-12) return (p - a).distance;
    var t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2;
    t = t.clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }

  /// Distancia al borde, negativa fuera del poligono. Una sola comparacion
  /// `>= margen` valida contencion y retiro a la vez.
  static double signedDistanceToEdge(Offset p, List<Offset> poly) {
    double d = double.infinity;
    for (int i = 0; i < poly.length; i++) {
      d = math.min(d, _distToSegment(p, poly[i], poly[(i + 1) % poly.length]));
    }
    return pointInPolygon(p, poly) ? d : -d;
  }

  static bool _segIntersect(Offset p1, Offset p2, Offset q1, Offset q2) {
    double cross(Offset o, Offset a, Offset b) =>
        (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
    final d1 = cross(q1, q2, p1), d2 = cross(q1, q2, p2);
    final d3 = cross(p1, p2, q1), d4 = cross(p1, p2, q2);
    return ((d1 > 0) != (d2 > 0)) && ((d3 > 0) != (d4 > 0));
  }

  static bool polygonsOverlap(List<Offset> a, List<Offset> b) {
    for (final p in a) {
      if (pointInPolygon(p, b)) return true;
    }
    for (final p in b) {
      if (pointInPolygon(p, a)) return true;
    }
    for (int i = 0; i < a.length; i++) {
      for (int j = 0; j < b.length; j++) {
        if (_segIntersect(a[i], a[(i + 1) % a.length], b[j],
            b[(j + 1) % b.length])) {
          return true;
        }
      }
    }
    return false;
  }

  static List<Offset> inflate(List<Offset> poly, double m) {
    if (m <= 0 || poly.isEmpty) return poly;
    final c = centroid(poly);
    return poly.map((p) {
      final d = p - c;
      final l = d.distance;
      if (l < 1e-9) return p;
      return c + d * ((l + m) / l);
    }).toList();
  }

  // --- plano desdoblado del techo -----------------------------------------
  // El empaquetado NO se hace en planta: se rota el faldon para que la
  // pendiente caiga en el eje y, y ese eje se estira por 1/cos(tilt). Asi las
  // distancias son las reales sobre la teja. Empaquetar en planta pierde filas.

  static Offset toRoof(Offset p, double azDeg, double tiltDeg) {
    final a = _rad(azDeg);
    final dx = math.sin(a), dy = math.cos(a); // direccion cuesta abajo
    final u = -(p.dx * dx + p.dy * dy) / math.cos(_rad(tiltDeg));
    final v = -p.dx * dy + p.dy * dx;
    return Offset(v, u);
  }

  static Offset fromRoof(Offset r, double azDeg, double tiltDeg) {
    final a = _rad(azDeg);
    final dx = math.sin(a), dy = math.cos(a);
    final u = r.dy * math.cos(_rad(tiltDeg));
    final v = r.dx;
    return Offset(-u * dx - v * dy, -u * dy + v * dx);
  }

  static List<Offset> ringToRoof(List<Offset> ring, double az, double tilt) =>
      ring.map((p) => toRoof(p, az, tilt)).toList();
}

// ===========================================================================
// GEOMETRIA SOLAR
// ===========================================================================

class Solar {
  static const daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  static const repDay = [17, 47, 75, 105, 135, 162, 198, 228, 258, 288, 318, 344];

  /// Irradiancia global horizontal por defecto (kWh/m2/dia). Editable por el
  /// usuario; en produccion se reemplaza por PVGIS o NASA POWER.
  static const defaultGhi = [
    5.1, 5.6, 6.1, 5.8, 5.0, 4.6, 4.9, 4.9, 4.7, 4.6, 4.7, 4.9
  ];
  static const defaultTemp = [
    23.0, 23.5, 24.5, 25.0, 24.5, 24.0, 23.5, 23.5, 23.5, 23.0, 23.0, 23.0
  ];

  static double declination(int n) =>
      23.45 * math.sin(_rad(360 * (284 + n) / 365));

  static double equationOfTime(int n) {
    final b = _rad(360 * (n - 1) / 365);
    return 229.18 *
        (0.000075 +
            0.001868 * math.cos(b) -
            0.032077 * math.sin(b) -
            0.014615 * math.cos(2 * b) -
            0.040849 * math.sin(2 * b));
  }

  /// Altitud y azimut del sol. [hour] en horas solares locales aproximadas.
  static (double altitude, double azimuth) sunPosition(
      double lat, int day, double hour) {
    final decl = _rad(declination(day));
    final ha = _rad(15.0 * (hour - 12.0));
    final phi = _rad(lat);
    final sinAlt = math.sin(phi) * math.sin(decl) +
        math.cos(phi) * math.cos(decl) * math.cos(ha);
    final alt = math.asin(sinAlt.clamp(-1.0, 1.0));
    final az = math.atan2(math.sin(ha),
        math.cos(ha) * math.sin(phi) - math.tan(decl) * math.cos(phi));
    return (_deg(alt), (_deg(az) + 180) % 360);
  }

  /// Radiacion extraterrestre diaria sobre plano horizontal (kWh/m2/dia).
  static double extraterrestrialDaily(double lat, int day) {
    const gsc = 1.367;
    final x = -math.tan(_rad(lat)) * math.tan(_rad(declination(day)));
    final ws = math.acos(x.clamp(-1.0, 1.0));
    final decl = _rad(declination(day));
    final phi = _rad(lat);
    final e = 1 + 0.033 * math.cos(_rad(360 * day / 365));
    final h0 = (24 / math.pi) *
        gsc *
        e *
        (math.cos(phi) * math.cos(decl) * math.sin(ws) +
            ws * math.sin(phi) * math.sin(decl));
    return math.max(0, h0);
  }

  /// Fraccion difusa diaria (correlacion de Erbs).
  static double diffuseFraction(double kt) {
    if (kt <= 0.22) return 1 - 0.09 * kt;
    if (kt <= 0.80) {
      return 0.9511 -
          0.1604 * kt +
          4.388 * math.pow(kt, 2) -
          16.638 * math.pow(kt, 3) +
          12.336 * math.pow(kt, 4);
    }
    return 0.165;
  }

  static double cosIncidence(
      double tilt, double surfAz, double sunAlt, double sunAz) {
    final b = _rad(tilt), g = _rad(surfAz), a = _rad(sunAlt), s = _rad(sunAz);
    return math.sin(a) * math.cos(b) +
        math.cos(a) * math.sin(b) * math.cos(s - g);
  }

  /// Factor Rb medio mensual por integracion horaria del dia representativo.
  static double meanRb(double lat, int m, double tilt, double az) {
    final day = repDay[m];
    double num = 0, den = 0;
    for (double h = 0; h < 24; h += 0.25) {
      final (alt, sunAz) = sunPosition(lat, day, h);
      if (alt <= 0) continue;
      final cosZ = math.sin(_rad(alt));
      if (cosZ < 0.05) continue;
      num += math.max(0, cosIncidence(tilt, az, alt, sunAz)) * 0.25;
      den += cosZ * 0.25;
    }
    return den <= 0 ? 0 : (num / den).clamp(0.0, 4.0);
  }

  /// Irradiacion diaria sobre el plano inclinado (Liu & Jordan isotropico).
  static double tiltedDaily({
    required double ghi,
    required double lat,
    required int month,
    required double tilt,
    required double azimuth,
    double albedo = 0.2,
  }) {
    final h0 = extraterrestrialDaily(lat, repDay[month]);
    if (h0 <= 0 || ghi <= 0) return 0;
    final kt = (ghi / h0).clamp(0.0, 1.0);
    final hd = ghi * diffuseFraction(kt);
    final hb = ghi - hd;
    final b = _rad(tilt);
    return hb * meanRb(lat, month, tilt, azimuth) +
        hd * (1 + math.cos(b)) / 2 +
        ghi * albedo * (1 - math.cos(b)) / 2;
  }

  static double optimalTilt(double lat) =>
      (lat.abs() * 0.76 + 3.1).clamp(0.0, 60.0);

  static double optimalAzimuth(double lat) => lat >= 0 ? 180 : 0;
}

// ===========================================================================
// PRODUCCION
// ===========================================================================

class Production {
  /// Perdidas estaticas combinadas (multiplicativas, no sumadas).
  static const staticLosses = 0.94 * 0.98 * 0.97 * 0.98 * 0.99 * 0.985;

  static ProductionResult estimate(Project p,
      {List<double>? ghi, List<double>? temp}) {
    final g = ghi ?? Solar.defaultGhi;
    final t = temp ?? Solar.defaultTemp;
    final monthly = List<double>.filled(12, 0);

    for (final f in p.facets) {
      final panels = p.panelsOf(f.id);
      if (panels.isEmpty) continue;
      final kwp = panels.length * p.module.wp / 1000.0;

      for (int m = 0; m < 12; m++) {
        final tilted = Solar.tiltedDaily(
          ghi: g[m],
          lat: p.latitude,
          month: m,
          tilt: f.tiltDeg,
          azimuth: f.azimuthDeg,
        );
        // derrateo termico simplificado via NOCT
        final cellTemp = t[m] + (45 - 20) / 0.8 * (tilted / 6.0).clamp(0.0, 1.5);
        final thermal =
            (1 + p.module.tempCoeff / 100 * (cellTemp - 25)).clamp(0.5, 1.1);
        monthly[m] +=
            kwp * tilted * Solar.daysInMonth[m] * staticLosses * thermal;
      }
    }

    final annual = monthly.fold(0.0, (a, b) => a + b);
    return ProductionResult(
        monthly, annual, p.kwp > 0 ? annual / p.kwp : 0);
  }
}

// ===========================================================================
// LAYOUT
// ===========================================================================

class LayoutOptions {
  final double edgeMargin;
  final double rowGap;
  final double colGap;
  final PanelOrientation? orientation;
  final int offsetSteps;
  const LayoutOptions({
    this.edgeMargin = 0.4,
    this.rowGap = 0.02,
    this.colGap = 0.02,
    this.orientation,
    this.offsetSteps = 4,
  });

  LayoutOptions copyWith({double? edgeMargin, PanelOrientation? orientation}) =>
      LayoutOptions(
        edgeMargin: edgeMargin ?? this.edgeMargin,
        rowGap: rowGap,
        colGap: colGap,
        orientation: orientation ?? this.orientation,
        offsetSteps: offsetSteps,
      );
}

class PanelLayout {
  /// Empaqueta el maximo de modulos sobre el plano REAL del faldon.
  static List<PanelPlacement> pack(
    RoofFacet facet,
    PanelModule module, [
    LayoutOptions opts = const LayoutOptions(),
  ]) {
    if (facet.outline.length < 3) return const [];

    final poly = Geo.ringToRoof(facet.outline, facet.azimuthDeg, facet.tiltDeg);
    final exclusions = facet.obstacles
        .map((o) => Geo.inflate(
            Geo.ringToRoof(o.outline, facet.azimuthDeg, facet.tiltDeg),
            o.clearanceM))
        .toList();

    final orientations = opts.orientation != null
        ? [opts.orientation!]
        : [PanelOrientation.portrait, PanelOrientation.landscape];

    List<PanelPlacement> best = const [];

    for (final o in orientations) {
      final w = o == PanelOrientation.portrait ? module.widthM : module.heightM;
      final h = o == PanelOrientation.portrait ? module.heightM : module.widthM;
      final stepX = w + opts.colGap;
      final stepY = h + opts.rowGap;

      for (int ox = 0; ox < opts.offsetSteps; ox++) {
        for (int oy = 0; oy < opts.offsetSteps; oy++) {
          final cand = _grid(
            poly: poly,
            exclusions: exclusions,
            facetId: facet.id,
            orientation: o,
            w: w,
            h: h,
            stepX: stepX,
            stepY: stepY,
            offX: stepX * ox / opts.offsetSteps,
            offY: stepY * oy / opts.offsetSteps,
            margin: opts.edgeMargin,
          );
          if (cand.length > best.length) best = cand;
        }
      }
    }
    return best;
  }

  static List<PanelPlacement> _grid({
    required List<Offset> poly,
    required List<List<Offset>> exclusions,
    required String facetId,
    required PanelOrientation orientation,
    required double w,
    required double h,
    required double stepX,
    required double stepY,
    required double offX,
    required double offY,
    required double margin,
  }) {
    final (minB, maxB) = Geo.bounds(poly);
    final out = <PanelPlacement>[];
    double y = minB.dy + offY;
    while (y + h <= maxB.dy + stepY) {
      double x = minB.dx + offX;
      while (x + w <= maxB.dx + stepX) {
        final corners = [
          Offset(x, y),
          Offset(x + w, y),
          Offset(x + w, y + h),
          Offset(x, y + h),
        ];
        if (_fits(corners, poly, exclusions, margin)) {
          out.add(PanelPlacement(
              facetId, Offset(x + w / 2, y + h / 2), orientation));
        }
        x += stepX;
      }
      y += stepY;
    }
    return out;
  }

  static bool _fits(List<Offset> corners, List<Offset> poly,
      List<List<Offset>> exclusions, double margin) {
    for (final c in corners) {
      if (Geo.signedDistanceToEdge(c, poly) < margin) return false;
    }
    for (final ex in exclusions) {
      if (Geo.polygonsOverlap(corners, ex)) return false;
    }
    return true;
  }

  /// Cuatro esquinas de un panel en el plano del techo.
  static List<Offset> cornersOf(
      PanelPlacement p, PanelModule module) {
    final w = p.orientation == PanelOrientation.portrait
        ? module.widthM
        : module.heightM;
    final h = p.orientation == PanelOrientation.portrait
        ? module.heightM
        : module.widthM;
    final c = p.centerRoof;
    return [
      Offset(c.dx - w / 2, c.dy - h / 2),
      Offset(c.dx + w / 2, c.dy - h / 2),
      Offset(c.dx + w / 2, c.dy + h / 2),
      Offset(c.dx - w / 2, c.dy + h / 2),
    ];
  }
}

// ===========================================================================
// FINANZAS
// ===========================================================================

class Finance {
  static FinancialResult analyze({
    required double annualKwh,
    required double kwp,
    required FinancialInputs i,
  }) {
    final capex = i.costPerWp * kwp * 1000;
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

/// Formato de miles con separador, sin dependencias de intl.
String money(double v) {
  final s = v.round().abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return (v < 0 ? '-' : '') + b.toString();
}
