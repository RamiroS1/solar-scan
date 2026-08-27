import 'dart:math' as math;
import 'dart:ui';

import '../models.dart';

double rad(double d) => d * math.pi / 180.0;

/// Geometria de techos y poligonos en metros.
class Geo {
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

  static double slopedArea(double planArea, double tiltDeg) {
    final c = math.cos(rad(tiltDeg));
    return c.abs() < 1e-6 ? planArea : planArea / c;
  }

  static double planAreaFromSloped(double slopedArea, double tiltDeg) {
    final c = math.cos(rad(tiltDeg));
    return slopedArea * c;
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

  static Offset toRoof(Offset p, double azDeg, double tiltDeg) {
    final a = rad(azDeg);
    final dx = math.sin(a), dy = math.cos(a);
    final u = -(p.dx * dx + p.dy * dy) / math.cos(rad(tiltDeg));
    final v = -p.dx * dy + p.dy * dx;
    return Offset(v, u);
  }

  static Offset fromRoof(Offset r, double azDeg, double tiltDeg) {
    final a = rad(azDeg);
    final dx = math.sin(a), dy = math.cos(a);
    final u = r.dy * math.cos(rad(tiltDeg));
    final v = r.dx;
    return Offset(-u * dx - v * dy, -u * dy + v * dx);
  }

  static List<Offset> ringToRoof(List<Offset> ring, double az, double tilt) =>
      ring.map((p) => toRoof(p, az, tilt)).toList();

  /// Redondea a la cuadricula mas cercana (ej. 0.5 m).
  static Offset snap(Offset p, {double step = 0.5}) =>
      Offset((p.dx / step).round() * step, (p.dy / step).round() * step);
}
