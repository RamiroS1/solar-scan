import 'package:flutter/material.dart';

import '../catalog/equipment.dart';
import '../core.dart';
import '../domain/area_capture.dart';
import '../models.dart';
import '../services.dart';

/// Banner de retroalimentacion area medida vs objetivo.
class AreaTargetBanner extends StatelessWidget {
  final AreaTargetFeedback feedback;
  const AreaTargetBanner({super.key, required this.feedback});

  Color get _color => switch (feedback.status) {
        AreaTargetStatus.onTarget => T.go,
        AreaTargetStatus.under => T.sun,
        AreaTargetStatus.over => T.clay,
        AreaTargetStatus.none => T.ink45,
      };

  @override
  Widget build(BuildContext context) {
    if (!feedback.hasTarget && feedback.status == AreaTargetStatus.none) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(.35)),
      ),
      child: Row(children: [
        Icon(
          feedback.status == AreaTargetStatus.onTarget
              ? Icons.check_circle_outline
              : Icons.straighten,
          size: 16,
          color: _color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(feedback.message,
              style: TextStyle(fontSize: 11.5, color: _color, height: 1.25)),
        ),
      ]),
    );
  }
}

/// Seccion BOM: que incluye el sistema contratado.
class SystemBomSection extends StatelessWidget {
  final Project project;
  const SystemBomSection({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final bom = SystemQuote.buildBom(project);
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Label('que incluye tu sistema'),
          const SizedBox(height: 10),
          ...bom.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.included
                          ? Icons.check_circle_outline
                          : Icons.remove_circle_outline,
                      size: 16,
                      color: item.included ? T.go : T.ink25,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.category,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: item.included ? T.ink : T.ink45)),
                          Text(item.description,
                              style: const TextStyle(
                                  fontSize: 11, color: T.ink70)),
                        ],
                      ),
                    ),
                    Text(item.quantity,
                        style: const TextStyle(
                            fontFamily: T.mono, fontSize: 10, color: T.ink45)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Desglose de la inversion por rubro.
class InvestmentBreakdownSection extends StatelessWidget {
  final QuoteBreakdown breakdown;
  final String currency;
  const InvestmentBreakdownSection({
    super.key,
    required this.breakdown,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Label('desglose de inversion'),
          const SizedBox(height: 8),
          ...breakdown.lines.map((line) => KV(
                line.detail != null ? '${line.label} · ${line.detail}' : line.label,
                '$currency${money(line.amount)}',
              )),
          KV('Total', '$currency${money(breakdown.total)}', color: T.volt),
        ],
      ),
    );
  }
}

/// Supuestos visibles del calculo de produccion y ROI.
class CalculationAssumptionsSection extends StatelessWidget {
  final Project project;
  const CalculationAssumptionsSection({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final site = project.solarSite ??
        SolarSiteResolver.resolve(address: project.address);
    final hints = ProjectFinanceHints(
      selfConsumption: project.finance.selfConsumption,
      degradation: project.finance.degradation,
    );
    final lines = SolarSiteResolver.assumptionLines(site, hints);

    return Glass(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Label('supuestos del calculo'),
          const SizedBox(height: 8),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('· $l',
                    style: const TextStyle(fontSize: 11, color: T.ink70)),
              )),
          const SizedBox(height: 6),
          const Text(
            'kWp = potencia del hardware instalado. kWh/ano = produccion estimada en tu zona.',
            style: TextStyle(fontSize: 10.5, color: T.ink45, height: 1.3),
          ),
        ],
      ),
    );
  }
}

/// Toggle bateria + selector de paquete.
class BatteryOptionsSection extends StatelessWidget {
  final Project project;
  final VoidCallback onChanged;
  const BatteryOptionsSection({
    super.key,
    required this.project,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Label('almacenamiento'),
              Switch(
                value: project.system.includeBattery,
                activeColor: T.volt,
                onChanged: (v) {
                  project.system.includeBattery = v;
                  onChanged();
                },
              ),
            ],
          ),
          if (project.system.includeBattery) ...[
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: project.system.batteryId ?? BatteryPack.catalog.first.id,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Paquete de bateria',
                border: OutlineInputBorder(),
              ),
              items: BatteryPack.catalog
                  .map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(
                            '${b.name} · ${b.capacityKwh} kWh · ${money(b.price)}'),
                      ))
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                project.system.batteryId = id;
                onChanged();
              },
            ),
          ] else
            const Text(
              'Sistema on-grid sin bateria. Solo generacion solar + red.',
              style: TextStyle(fontSize: 11, color: T.ink45),
            ),
        ],
      ),
    );
  }
}
