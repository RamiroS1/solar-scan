/// Catalogo de equipos: inversores y baterias.
/// Punto unico para ampliar marcas/modelos sin tocar la UI.

class Inverter {
  final String id;
  final String brand;
  final String model;
  final double acKw;
  final int quantity;

  const Inverter({
    required this.id,
    required this.brand,
    required this.model,
    required this.acKw,
    this.quantity = 1,
  });

  String get name => '$brand $model';

  static const catalog = <Inverter>[
    Inverter(id: 'fronius5', brand: 'Fronius', model: 'Primo 5.0', acKw: 5.0),
    Inverter(id: 'fronius8', brand: 'Fronius', model: 'Primo 8.2', acKw: 8.2),
    Inverter(id: 'huawei10', brand: 'Huawei', model: 'SUN2000-10KTL', acKw: 10.0),
    Inverter(id: 'huawei15', brand: 'Huawei', model: 'SUN2000-15KTL', acKw: 15.0),
    Inverter(id: 'solaredge12', brand: 'SolarEdge', model: 'SE12.5K', acKw: 12.5),
    Inverter(id: 'solaredge20', brand: 'SolarEdge', model: 'SE20K', acKw: 20.0),
  ];

  /// Selecciona inversor con ~10 % de holgura sobre kWp DC.
  static Inverter selectForKwp(double kwp) {
    final target = kwp * 0.95;
    Inverter? best;
    for (final inv in catalog) {
      if (inv.acKw >= target) {
        if (best == null || inv.acKw < best.acKw) best = inv;
      }
    }
    return best ?? catalog.last;
  }
}

class BatteryPack {
  final String id;
  final String brand;
  final String model;
  final double capacityKwh;
  final double price;
  final int quantity;

  const BatteryPack({
    required this.id,
    required this.brand,
    required this.model,
    required this.capacityKwh,
    required this.price,
    this.quantity = 1,
  });

  String get name => '$brand $model';

  static const catalog = <BatteryPack>[
    BatteryPack(
      id: 'byd10',
      brand: 'BYD',
      model: 'Battery-Box Premium HVS 10.2',
      capacityKwh: 10.2,
      price: 4200000,
    ),
    BatteryPack(
      id: 'tesla13',
      brand: 'Tesla',
      model: 'Powerwall 2',
      capacityKwh: 13.5,
      price: 5800000,
    ),
    BatteryPack(
      id: 'lg16',
      brand: 'LG',
      model: 'RESU16H Prime',
      capacityKwh: 16.0,
      price: 6500000,
    ),
  ];
}
