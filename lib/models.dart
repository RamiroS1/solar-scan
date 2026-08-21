import 'dart:ui';

enum ProjectStatus { draft, sent, approved, installed }

enum PanelOrientation { portrait, landscape }

enum CaptureMode { lidar, photogrammetry, satellite }

class PanelModule {
  final String id;
  final String brand;
  final String model;
  final double widthM;
  final double heightM;
  final double wp;
  final double tempCoeff; // %/C

  const PanelModule({
    required this.id,
    required this.brand,
    required this.model,
    required this.widthM,
    required this.heightM,
    required this.wp,
    this.tempCoeff = -0.35,
  });

  double get areaM2 => widthM * heightM;
  String get name => '$brand $model';

  /// Referencia con nombre: los valores por defecto de un constructor deben
  /// ser constantes, y `catalog[0]` no lo es (indexar no es const).
  static const trina450 = PanelModule(
      id: 'trina450',
      brand: 'Trina',
      model: 'Vertex S 450W',
      widthM: 1.096,
      heightM: 1.762,
      wp: 450);

  static const catalog = <PanelModule>[
    trina450,
    PanelModule(
        id: 'jinko580',
        brand: 'Jinko',
        model: 'Tiger Neo 580W',
        widthM: 1.134,
        heightM: 2.278,
        wp: 580),
    PanelModule(
        id: 'longi590',
        brand: 'LONGi',
        model: 'Hi-MO 6 590W',
        widthM: 1.134,
        heightM: 2.278,
        wp: 590),
    PanelModule(
        id: 'canadian550',
        brand: 'Canadian',
        model: 'HiKu6 550W',
        widthM: 1.134,
        heightM: 2.278,
        wp: 550),
  ];
}

/// Zona de exclusion sobre el techo. Coordenadas en metros, plano horizontal.
class Obstacle {
  final String id;
  final String label;
  final List<Offset> outline;
  final double heightM;
  final double clearanceM;

  const Obstacle({
    required this.id,
    required this.label,
    required this.outline,
    this.heightM = 0.8,
    this.clearanceM = 0.3,
  });
}

/// Un agua del techo. `outline` va en METROS sobre la proyeccion horizontal,
/// con origen arbitrario; el area real se obtiene dividiendo por cos(tilt).
class RoofFacet {
  final String id;
  String name;
  List<Offset> outline;
  double tiltDeg;
  double azimuthDeg; // 0=N, 90=E, 180=S
  List<Obstacle> obstacles;
  CaptureMode mode;

  RoofFacet({
    required this.id,
    required this.name,
    required this.outline,
    this.tiltDeg = 20,
    this.azimuthDeg = 180,
    List<Obstacle>? obstacles,
    this.mode = CaptureMode.lidar,
  }) : obstacles = obstacles ?? [];
}

class PanelPlacement {
  final String facetId;
  final Offset centerRoof; // metros, en el plano desdoblado del techo
  final PanelOrientation orientation;
  const PanelPlacement(this.facetId, this.centerRoof, this.orientation);
}

class FinancialInputs {
  double costPerWp;
  double tariffPerKwh;
  double escalation;
  double discountRate;
  double degradation;
  double selfConsumption;
  int horizonYears;
  String currency;

  FinancialInputs({
    this.costPerWp = 840,
    this.tariffPerKwh = 96.4,
    this.escalation = .05,
    this.discountRate = .10,
    this.degradation = .005,
    this.selfConsumption = .75,
    this.horizonYears = 25,
    this.currency = '\u20A1',
  });
}

class ProductionResult {
  final List<double> monthly;
  final double annual;
  final double specificYield;
  const ProductionResult(this.monthly, this.annual, this.specificYield);
}

class FinancialResult {
  final double capex;
  final double firstYear;
  final double payback;
  final double cumulative;
  final double npv;
  final double? irr;
  final List<double> cumulativeFlow;
  const FinancialResult({
    required this.capex,
    required this.firstYear,
    required this.payback,
    required this.cumulative,
    required this.npv,
    required this.irr,
    required this.cumulativeFlow,
  });
}

class Project {
  final String id;
  String customer;
  String address;
  String phone;
  double latitude;
  double longitude;
  List<RoofFacet> facets;
  List<PanelPlacement> panels;
  PanelModule module;
  double annualConsumptionKwh;
  ProjectStatus status;
  FinancialInputs finance;
  DateTime createdAt;
  /// Escena 3D que se le muestra al cliente: casa, edificio, parqueadero o barrio.
  int archetypeIndex;

  Project({
    required this.id,
    required this.customer,
    this.address = '',
    this.phone = '',
    this.latitude = 9.93,
    this.longitude = -84.14,
    List<RoofFacet>? facets,
    List<PanelPlacement>? panels,
    this.module = PanelModule.trina450,
    this.annualConsumptionKwh = 18576,
    this.status = ProjectStatus.draft,
    FinancialInputs? finance,
    DateTime? createdAt,
    this.archetypeIndex = 0,
  })  : facets = facets ?? [],
        panels = panels ?? [],
        finance = finance ?? FinancialInputs(),
        createdAt = createdAt ?? DateTime.now();

  double get kwp => panels.length * module.wp / 1000.0;

  List<PanelPlacement> panelsOf(String facetId) =>
      panels.where((p) => p.facetId == facetId).toList();

  String get statusLabel => switch (status) {
        ProjectStatus.draft => 'BORRADOR',
        ProjectStatus.sent => 'ENVIADA',
        ProjectStatus.approved => 'APROBADO',
        ProjectStatus.installed => 'INSTALADO',
      };
}
