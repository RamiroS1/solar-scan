import '../catalog/equipment.dart';
import '../models.dart';

/// Cotizacion del sistema: BOM, inversor y desglose de precios.
class SystemQuote {
  static Inverter resolveInverter(Project p) {
    if (p.system.inverterId != null) {
      return Inverter.catalog.firstWhere(
        (i) => i.id == p.system.inverterId,
        orElse: () => Inverter.selectForKwp(p.kwp),
      );
    }
    return Inverter.selectForKwp(p.kwp);
  }

  static List<BomLineItem> buildBom(Project p) {
    final inv = resolveInverter(p);
    final lines = <BomLineItem>[
      BomLineItem(
        category: 'Modulos PV',
        description: '${p.module.brand} ${p.module.model} (${p.module.wp.round()} Wp)',
        quantity: '${p.panels.length} uds',
      ),
      BomLineItem(
        category: 'Inversor',
        description: '${inv.brand} ${inv.model} (${inv.acKw.toStringAsFixed(1)} kW AC)',
        quantity: '${inv.quantity} uds',
      ),
      BomLineItem(
        category: 'Estructura',
        description: 'Riel de montaje, anclajes y hardware',
        quantity: '${p.panels.length} modulos',
      ),
      BomLineItem(
        category: 'Protecciones',
        description: 'Breaker, SPD, desconectores y cableado DC/AC',
        quantity: '1 lote',
      ),
      BomLineItem(
        category: 'Monitoreo',
        description: 'Plataforma de seguimiento de produccion',
        quantity: '1 sistema',
      ),
      BomLineItem(
        category: 'Interconexion',
        description: 'Tramites y conexion a red (estimado)',
        quantity: '1 lote',
      ),
    ];

    if (p.system.includeBattery) {
      final bat = p.system.battery ?? BatteryPack.catalog.first;
      lines.add(BomLineItem(
        category: 'Bateria',
        description: '${bat.brand} ${bat.model} (${bat.capacityKwh.toStringAsFixed(1)} kWh)',
        quantity: '${bat.quantity} uds',
      ));
    } else {
      lines.add(const BomLineItem(
        category: 'Bateria',
        description: 'No incluida en esta propuesta',
        quantity: '—',
        included: false,
      ));
    }

    return lines;
  }

  static QuoteBreakdown buildBreakdown(Project p) {
    final base = p.finance.costPerWp * p.kwp * 1000;
    final cfg = p.system.pricing;
    final lines = <QuoteLine>[
      QuoteLine('Modulos fotovoltaicos', base * cfg.panelShare,
          detail: '${p.panels.length} x ${p.module.name}'),
      QuoteLine('Inversor(es)', base * cfg.inverterShare,
          detail: resolveInverter(p).name),
      QuoteLine('Estructura y montaje', base * cfg.mountingShare),
      QuoteLine('Instalacion electrica', base * cfg.laborShare),
      QuoteLine('Tramites e interconexion', base * cfg.permitsShare),
      QuoteLine('Monitoreo', base * cfg.monitoringShare),
    ];

    var total = lines.fold(0.0, (s, l) => s + l.amount);
    if (p.system.includeBattery) {
      final bat = p.system.battery ?? BatteryPack.catalog.first;
      lines.add(QuoteLine('Almacenamiento (bateria)', bat.price * bat.quantity,
          detail: bat.name));
      total += bat.price * bat.quantity;
    }

    return QuoteBreakdown(lines: lines, total: total);
  }
}
