import '../models.dart';
import 'solar.dart';
import 'solar_site.dart';

/// Estimacion de produccion anual a partir del hardware y el sitio solar.
class Production {
  static const staticLosses = 0.94 * 0.98 * 0.97 * 0.98 * 0.99 * 0.985;

  static ProductionResult estimate(Project p,
      {List<double>? ghi, List<double>? temp}) {
    final site = p.solarSite ?? SolarSiteResolver.resolve(address: p.address);
    final g = ghi ?? site.ghi;
    final t = temp ?? site.temp;
    final lat = site.latitude;
    final monthly = List<double>.filled(12, 0);

    for (final f in p.facets) {
      final panels = p.panelsOf(f.id);
      if (panels.isEmpty) continue;
      final kwp = panels.length * p.module.wp / 1000.0;

      for (int m = 0; m < 12; m++) {
        final tilted = Solar.tiltedDaily(
          ghi: g[m],
          lat: lat,
          month: m,
          tilt: f.tiltDeg,
          azimuth: f.azimuthDeg,
        );
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
