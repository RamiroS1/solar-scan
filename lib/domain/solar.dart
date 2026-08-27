import 'dart:math' as math;

import 'geo.dart';

/// Posicion solar e irradiancia. Los perfiles regionales viven en [SolarSiteResolver].
class Solar {
  static const daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  static const repDay = [17, 47, 75, 105, 135, 162, 198, 228, 258, 288, 318, 344];

  static const defaultGhi = [
    5.1, 5.6, 6.1, 5.8, 5.0, 4.6, 4.9, 4.9, 4.7, 4.6, 4.7, 4.9
  ];
  static const defaultTemp = [
    23.0, 23.5, 24.5, 25.0, 24.5, 24.0, 23.5, 23.5, 23.5, 23.0, 23.0, 23.0
  ];

  static double declination(int n) =>
      23.45 * math.sin(rad(360 * (284 + n) / 365));

  static double equationOfTime(int n) {
    final b = rad(360 * (n - 1) / 365);
    return 229.18 *
        (0.000075 +
            0.001868 * math.cos(b) -
            0.032077 * math.sin(b) -
            0.014615 * math.cos(2 * b) -
            0.040849 * math.sin(2 * b));
  }

  static (double altitude, double azimuth) sunPosition(
      double lat, int day, double hour) {
    final decl = rad(declination(day));
    final ha = rad(15.0 * (hour - 12.0));
    final phi = rad(lat);
    final sinAlt = math.sin(phi) * math.sin(decl) +
        math.cos(phi) * math.cos(decl) * math.cos(ha);
    final alt = math.asin(sinAlt.clamp(-1.0, 1.0));
    final az = math.atan2(math.sin(ha),
        math.cos(ha) * math.sin(phi) - math.tan(decl) * math.cos(phi));
    return (alt * 180 / math.pi, (az * 180 / math.pi + 180) % 360);
  }

  static double extraterrestrialDaily(double lat, int day) {
    const gsc = 1.367;
    final x = -math.tan(rad(lat)) * math.tan(rad(declination(day)));
    final ws = math.acos(x.clamp(-1.0, 1.0));
    final decl = rad(declination(day));
    final phi = rad(lat);
    final e = 1 + 0.033 * math.cos(rad(360 * day / 365));
    final h0 = (24 / math.pi) *
        gsc *
        e *
        (math.cos(phi) * math.cos(decl) * math.sin(ws) +
            ws * math.sin(phi) * math.sin(decl));
    return math.max(0, h0);
  }

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
    final b = rad(tilt), g = rad(surfAz), a = rad(sunAlt), s = rad(sunAz);
    return math.sin(a) * math.cos(b) +
        math.cos(a) * math.sin(b) * math.cos(s - g);
  }

  static double meanRb(double lat, int m, double tilt, double az) {
    final day = repDay[m];
    double num = 0, den = 0;
    for (double h = 0; h < 24; h += 0.25) {
      final (alt, sunAz) = sunPosition(lat, day, h);
      if (alt <= 0) continue;
      final cosZ = math.sin(rad(alt));
      if (cosZ < 0.05) continue;
      num += math.max(0, cosIncidence(tilt, az, alt, sunAz)) * 0.25;
      den += cosZ * 0.25;
    }
    return den <= 0 ? 0 : (num / den).clamp(0.0, 4.0);
  }

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
    final b = rad(tilt);
    return hb * meanRb(lat, month, tilt, azimuth) +
        hd * (1 + math.cos(b)) / 2 +
        ghi * albedo * (1 - math.cos(b)) / 2;
  }

  static double optimalTilt(double lat) =>
      (lat.abs() * 0.76 + 3.1).clamp(0.0, 60.0);

  static double optimalAzimuth(double lat) => lat >= 0 ? 180 : 0;
}
