import 'package:flutter/material.dart';

import '../core.dart';
import '../models.dart';
import '../painters.dart';
import '../services.dart';
import '../widgets/proposal_sections.dart';
import 'proposal.dart';

class NumbersScreen extends StatefulWidget {
  const NumbersScreen({super.key});
  @override
  State<NumbersScreen> createState() => _NumbersScreenState();
}

class _NumbersScreenState extends State<NumbersScreen> {
  final _tariff = TextEditingController();
  final _cost = TextEditingController();
  final _esc = TextEditingController();
  bool _loaded = false;

  // No se puede llamar a Store.of(context) desde initState: depender de un
  // InheritedWidget solo es valido a partir de didChangeDependencies.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final f = Store.of(context).current?.finance ?? FinancialInputs();
    _tariff.text = f.tariffPerKwh.toString();
    _cost.text = f.costPerWp.toString();
    _esc.text = (f.escalation * 100).toStringAsFixed(1);
  }

  @override
  void dispose() {
    _tariff.dispose();
    _cost.dispose();
    _esc.dispose();
    super.dispose();
  }

  double _num(TextEditingController c, double fallback) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? fallback;

  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);
    final p = state.current;
    if (p == null) return const Scaffold(body: SizedBox());

    final prod = Production.estimate(p);
    final fin = Finance.analyze(
        annualKwh: prod.annual, kwp: p.kwp, i: p.finance, project: p);
    final cur = p.finance.currency;
    final monthlyConsumption = p.annualConsumptionKwh / 12;
    final breakdown = fin.breakdown ?? SystemQuote.buildBreakdown(p);

    return Ambient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Numeros')),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  children: [
                    Row(children: [
                      Expanded(
                        child: Glass(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Label('anual'),
                              const SizedBox(height: 6),
                              Readout(prod.annual.round().toString(),
                                  unit: 'kWh', size: 21),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Glass(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Label('rendimiento'),
                              const SizedBox(height: 6),
                              Readout(prod.specificYield.round().toString(),
                                  unit: 'kWh/kWp', size: 21),
                            ],
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Glass(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Label('produccion mensual vs consumo'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: BarsPainter(prod.monthly,
                                  reference: monthlyConsumption),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.annualConsumptionKwh > 0
                                ? 'Cubre el ${(prod.annual / p.annualConsumptionKwh * 100).round()} % del consumo anual declarado.'
                                : 'Sin consumo declarado.',
                            style: const TextStyle(
                                fontSize: 11.5, color: T.ink70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Glass(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Label('supuestos · editables'),
                          const SizedBox(height: 8),
                          _numField('Tarifa por kWh', _tariff, (v) {
                            p.finance.tariffPerKwh = v;
                            state.touch();
                          }),
                          _numField('Costo por Wp', _cost, (v) {
                            p.finance.costPerWp = v;
                            state.touch();
                          }),
                          _numField('Alza anual %', _esc, (v) {
                            p.finance.escalation = v / 100;
                            state.touch();
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    CalculationAssumptionsSection(project: p),
                    const SizedBox(height: 10),
                    InvestmentBreakdownSection(
                      breakdown: breakdown,
                      currency: cur,
                    ),
                    const SizedBox(height: 10),
                    Glass(
                      child: Column(
                        children: [
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Label('retorno')),
                          const SizedBox(height: 10),
                          Center(
                            child: Readout(
                              fin.payback >= 0
                                  ? fin.payback.toStringAsFixed(1)
                                  : '--',
                              unit: 'anos',
                              size: 44,
                              color: T.volt,
                            ),
                          ),
                          const SizedBox(height: 14),
                          KV('Inversion', '$cur${money(fin.capex)}'),
                          KV('Ahorro primer ano',
                              '$cur${money(fin.firstYear)}'),
                          KV('Ahorro a ${p.finance.horizonYears} anos',
                              '$cur${money(fin.cumulative)}',
                              color: T.go),
                          KV('VPN', '$cur${money(fin.npv)}'),
                          KV(
                              'TIR',
                              fin.irr != null
                                  ? '${(fin.irr! * 100).toStringAsFixed(1)} %'
                                  : 'n/d'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Primary(
                  label: 'Armar propuesta',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ProposalScreen())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numField(
      String label, TextEditingController c, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
            child:
                Text(label, style: const TextStyle(fontSize: 12.5, color: T.ink45))),
        SizedBox(
          width: 96,
          child: TextField(
            controller: c,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontFamily: T.mono,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: T.sun),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: T.hair)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: T.sun)),
            ),
            onChanged: (s) {
              final v = double.tryParse(s.replaceAll(',', '.'));
              if (v != null) onChanged(v);
            },
          ),
        ),
      ]),
    );
  }
}
