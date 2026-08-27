import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../core.dart';
import '../domain/sizing.dart';
import '../domain/system_quote.dart';
import '../models.dart';
import '../painters.dart';
import '../proposal_pdf.dart';
import '../scene3d/scene_model.dart';
import '../scene3d/scene_view.dart';
import '../services.dart';
import '../widgets/proposal_sections.dart';

class ProposalScreen extends StatefulWidget {
  const ProposalScreen({super.key});
  @override
  State<ProposalScreen> createState() => _ProposalScreenState();
}

class _ProposalScreenState extends State<ProposalScreen> {
  bool _busy = false;
  double _sunHour = 13;
  bool _showEnv = true;

  Future<void> _share(Project p, ProductionResult prod, FinancialResult fin) async {
    setState(() => _busy = true);
    try {
      final bytes = await buildProposalPdf(
          project: p, production: prod, financial: fin);
      await Printing.sharePdf(
          bytes: bytes,
          filename:
              'propuesta_${p.customer.replaceAll(RegExp(r'\W+'), '_')}.pdf');
      p.status = ProjectStatus.sent;
      Store.of(context).touch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo compartir: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);
    final p = state.current;
    if (p == null) return const Scaffold(body: SizedBox());

    final prod = Production.estimate(p);
    final fin = Finance.analyze(
        annualKwh: prod.annual, kwp: p.kwp, i: p.finance, project: p);
    final cur = p.finance.currency;
    final breakdown = fin.breakdown ?? SystemQuote.buildBreakdown(p);
    final inv = SystemQuote.resolveInverter(p);
    final instant = InstantPowerSimulation.forKwp(p.kwp);

    final archetype =
        Archetype.values[p.archetypeIndex.clamp(0, Archetype.values.length - 1)];
    final shownPanels = p.panels.length.clamp(0, archetype.maxPanels);

    return Ambient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Propuesta')),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  children: [
                    Text(p.customer,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.6)),
                    Text(
                        '${p.kwp.toStringAsFixed(2)} kWp instalados · '
                        '${prod.annual.round()} kWh/ano estimados · '
                        '${p.panels.length} paneles',
                        style: const TextStyle(fontSize: 12, color: T.ink45)),
                    const SizedBox(height: 12),
                    SystemBomSection(project: p),
                    const SizedBox(height: 10),
                    BatteryOptionsSection(
                      project: p,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    InvestmentBreakdownSection(
                      breakdown: breakdown,
                      currency: cur,
                    ),
                    const SizedBox(height: 10),
                    CalculationAssumptionsSection(project: p),
                    const SizedBox(height: 10),
                    Glass(
                      padding: const EdgeInsets.all(8),
                      radius: 24,
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1.15,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFFF7F9FB), Color(0xFFE3E8EF)],
                                  ),
                                ),
                                child: SceneView(
                                  archetype: archetype,
                                  panels: shownPanels,
                                  sunHour: _sunHour,
                                  showEnv: _showEnv,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: Archetype.values.map((a) {
                              final on = a == archetype;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    p.archetypeIndex = a.index;
                                    state.touch();
                                  },
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(horizontal: 2),
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: on
                                          ? Colors.white
                                          : T.ink.withOpacity(.05),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: on
                                          ? [
                                              BoxShadow(
                                                  color: T.ink.withOpacity(.10),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2))
                                            ]
                                          : null,
                                    ),
                                    child: Text(a.label,
                                        style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: on ? T.ink : T.ink45)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.wb_sunny_outlined,
                                size: 15, color: T.sun),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 3,
                                  activeTrackColor: T.sun,
                                  inactiveTrackColor: T.ink.withOpacity(.12),
                                  thumbColor: Colors.white,
                                  overlayShape: SliderComponentShape.noOverlay,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 7),
                                ),
                                child: Slider(
                                  value: _sunHour,
                                  min: 6,
                                  max: 18,
                                  onChanged: (v) =>
                                      setState(() => _sunHour = v),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 42,
                              child: Text(
                                  '${_sunHour.floor()}:${_sunHour % 1 == 0 ? '00' : '30'}',
                                  style: const TextStyle(
                                      fontFamily: T.mono,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _showEnv = !_showEnv),
                              child: Icon(
                                  _showEnv
                                      ? Icons.park_outlined
                                      : Icons.park,
                                  size: 17,
                                  color: _showEnv ? T.go : T.ink25),
                            ),
                          ]),
                          if (p.panels.length > archetype.maxPanels)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'El modelo muestra ${archetype.maxPanels} de '
                                '${p.panels.length} modulos disenados.',
                                style: const TextStyle(
                                    fontSize: 10.5, color: T.clay),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Glass(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Label('ilustracion · no contractual'),
                          const SizedBox(height: 8),
                          Row(children: [
                            _tile(instant.peakKw.toStringAsFixed(1),
                                'kW pico simulado', T.sun),
                            const SizedBox(width: 7),
                            _tile(instant.toHomeKw.toStringAsFixed(1),
                                'a la casa', T.iris),
                            const SizedBox(width: 7),
                            _tile(instant.toGridKw.toStringAsFixed(1),
                                'a la red', T.volt),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            'Flujo instantaneo ilustrativo (~${(InstantPowerSimulation.peakFactor * 100).round()} % del kWp). '
                            'Inversor propuesto: ${inv.name} (${inv.acKw.toStringAsFixed(1)} kW AC).',
                            style: const TextStyle(
                                fontSize: 10.5, color: T.ink45, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Glass(
                      child: Column(children: [
                        KV('Potencia instalada (kWp)',
                            p.kwp.toStringAsFixed(2)),
                        KV('Produccion anual estimada',
                            '${money(prod.annual)} kWh'),
                        KV('Inversion total', '$cur${money(fin.capex)}'),
                        KV(
                            'Retorno',
                            fin.payback >= 0
                                ? '${fin.payback.toStringAsFixed(1)} anos'
                                : 'no retorna',
                            color: T.volt),
                        KV('Ahorro a 25 anos', '$cur${money(fin.cumulative)}',
                            color: T.go),
                      ]),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Row(children: [
                  Expanded(
                    child: Ghost(
                      label: 'Vista previa',
                      onTap: () => Printing.layoutPdf(
                          onLayout: (_) => buildProposalPdf(
                              project: p, production: prod, financial: fin)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Primary(
                      label: _busy ? 'Generando...' : 'Enviar PDF',
                      onTap: _busy ? null : () => _share(p, prod, fin),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String v, String k, Color c) => Expanded(
        child: Column(children: [
          Text(v,
              style: TextStyle(
                  fontFamily: T.mono,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c)),
          const SizedBox(height: 2),
          Text(k, style: const TextStyle(fontSize: 9, color: T.ink45)),
        ]),
      );
}
