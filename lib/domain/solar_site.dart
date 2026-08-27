import 'solar.dart';

/// Perfil solar de un sitio: coordenadas + irradiancia regional.
class SolarSiteProfile {
  final double latitude;
  final double longitude;
  final String regionLabel;
  final List<double> ghi;
  final List<double> temp;
  final String source;

  const SolarSiteProfile({
    required this.latitude,
    required this.longitude,
    required this.regionLabel,
    required this.ghi,
    required this.temp,
    required this.source,
  });

  SolarSiteProfile copyWith({
    double? latitude,
    double? longitude,
    String? regionLabel,
    List<double>? ghi,
    List<double>? temp,
    String? source,
  }) =>
      SolarSiteProfile(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        regionLabel: regionLabel ?? this.regionLabel,
        ghi: ghi ?? this.ghi,
        temp: temp ?? this.temp,
        source: source ?? this.source,
      );
}

/// Resuelve perfil solar a partir de direccion o coordenadas.
/// Punto de extension para PVGIS / geocoding en el futuro.
class SolarSiteResolver {
  static const _regions = <_Region>[
    _Region(
      id: 'valle_central',
      label: 'Valle Central, Costa Rica',
      lat: 9.93,
      lon: -84.14,
      keywords: ['san jose', 'escazu', 'santa ana', 'cartago', 'heredia', 'alajuela'],
      ghi: Solar.defaultGhi,
      temp: Solar.defaultTemp,
    ),
    _Region(
      id: 'guanacaste',
      label: 'Guanacaste, Costa Rica',
      lat: 10.5,
      lon: -85.4,
      keywords: ['guanacaste', 'liberia', 'nicoya', 'samara', 'tamarindo'],
      ghi: [5.8, 6.2, 6.8, 6.5, 5.8, 5.2, 5.5, 5.6, 5.4, 5.3, 5.4, 5.6],
      temp: [26.0, 27.0, 28.5, 29.0, 28.5, 27.5, 27.0, 27.0, 27.0, 26.5, 26.0, 25.5],
    ),
    _Region(
      id: 'caribe',
      label: 'Limon / Caribe, Costa Rica',
      lat: 9.99,
      lon: -83.03,
      keywords: ['limon', 'caribe', 'puerto viejo', 'cahuita', 'guapiles'],
      ghi: [4.2, 4.5, 4.8, 4.6, 4.0, 3.8, 4.0, 4.2, 4.0, 3.9, 4.0, 4.1],
      temp: [24.0, 24.5, 25.0, 25.5, 25.5, 25.0, 24.5, 24.5, 24.5, 24.5, 24.0, 24.0],
    ),
    _Region(
      id: 'pacifico_sur',
      label: 'Pacifico Sur, Costa Rica',
      lat: 8.95,
      lon: -83.75,
      keywords: ['puntarenas', 'quepos', 'manuel antonio', 'dominical', 'osa'],
      ghi: [5.4, 5.8, 6.2, 5.9, 5.1, 4.7, 5.0, 5.0, 4.8, 4.7, 4.8, 5.0],
      temp: [25.0, 25.5, 26.0, 26.5, 26.0, 25.5, 25.0, 25.0, 25.0, 24.5, 24.5, 24.5],
    ),
  ];

  static SolarSiteProfile resolve({
    required String address,
    double? latitude,
    double? longitude,
  }) {
    final normalized = address.toLowerCase();
    for (final r in _regions) {
      if (r.keywords.any(normalized.contains)) {
        return SolarSiteProfile(
          latitude: latitude ?? r.lat,
          longitude: longitude ?? r.lon,
          regionLabel: r.label,
          ghi: r.ghi,
          temp: r.temp,
          source: 'Tabla regional (${r.label})',
        );
      }
    }
    final base = _regions.first;
    return SolarSiteProfile(
      latitude: latitude ?? base.lat,
      longitude: longitude ?? base.lon,
      regionLabel: base.label,
      ghi: base.ghi,
      temp: base.temp,
      source: 'Tabla regional por defecto',
    );
  }

  static List<String> assumptionLines(SolarSiteProfile site, ProjectFinanceHints hints) =>
      [
        'Ubicacion: ${site.regionLabel}',
        'Latitud: ${site.latitude.toStringAsFixed(2)}°',
        'Irradiancia: ${site.source}',
        'Autoconsumo: ${(hints.selfConsumption * 100).round()} %',
        'Degradacion anual: ${(hints.degradation * 100).toStringAsFixed(1)} %',
        'Perdidas del sistema: ~13.5 % combinadas',
      ];
}

/// Evita acoplar [SolarSiteResolver] a [FinancialInputs] del modelo completo.
class ProjectFinanceHints {
  final double selfConsumption;
  final double degradation;
  const ProjectFinanceHints({
    this.selfConsumption = 0.75,
    this.degradation = 0.005,
  });
}

class _Region {
  final String id;
  final String label;
  final double lat;
  final double lon;
  final List<String> keywords;
  final List<double> ghi;
  final List<double> temp;
  const _Region({
    required this.id,
    required this.label,
    required this.lat,
    required this.lon,
    required this.keywords,
    required this.ghi,
    required this.temp,
  });
}
