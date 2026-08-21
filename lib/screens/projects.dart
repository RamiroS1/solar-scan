import 'package:flutter/material.dart';

import '../core.dart';
import '../models.dart';
import '../painters.dart';
import 'capture.dart';

// ---------------------------------------------------------------------------
// Apertura
// ---------------------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProjectsScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Ambient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                height: 110,
                child: CustomPaint(painter: _LogoPainter()),
              ),
              const SizedBox(height: 26),
              const Text('SolarScan',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1)),
              const SizedBox(height: 8),
              const Label('medir · disenar · vender'),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 160;
    canvas.scale(s);
    final path = Path()
      ..moveTo(30, 18)
      ..lineTo(134, 34)
      ..lineTo(122, 88)
      ..lineTo(18, 72)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..shader = T.module.createShader(const Rect.fromLTWH(18, 18, 116, 70)));
    final line = Paint()
      ..color = Colors.white.withOpacity(.5)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(56, 22), const Offset(44, 76), line);
    canvas.drawLine(const Offset(82, 26), const Offset(70, 80), line);
    canvas.drawLine(const Offset(108, 30), const Offset(96, 84), line);
    canvas.drawLine(const Offset(26, 40), const Offset(131, 56), line);
    canvas.drawLine(const Offset(22, 58), const Offset(126, 74), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Cartera
// ---------------------------------------------------------------------------

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  Color _statusColor(ProjectStatus s) => switch (s) {
        ProjectStatus.draft => T.ink25,
        ProjectStatus.sent => T.sun,
        ProjectStatus.approved => T.go,
        ProjectStatus.installed => T.volt,
      };

  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);
    return Ambient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const H1('Proyectos'),
                        const SizedBox(height: 2),
                        Text('${state.projects.length} activos',
                            style: const TextStyle(fontSize: 12, color: T.ink45)),
                      ],
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                          gradient: T.gradient, shape: BoxShape.circle),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  itemCount: state.projects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = state.projects[i];
                    return Glass(
                      onTap: () {
                        state.current = p;
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const CaptureScreen()));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(p.customer,
                                    style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -.3)),
                              ),
                              Text(p.statusLabel,
                                  style: TextStyle(
                                      fontFamily: T.mono,
                                      fontSize: 9,
                                      color: _statusColor(p.status))),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                              p.address.isEmpty ? 'Sin direccion' : p.address,
                              style:
                                  const TextStyle(fontSize: 12, color: T.ink45)),
                          const SizedBox(height: 9),
                          Text(
                            p.facets.isEmpty
                                ? 'Sin medir'
                                : '${p.facets.length} agua(s) · ${p.panels.length} paneles · ${p.kwp.toStringAsFixed(2)} kWp',
                            style: const TextStyle(
                                fontFamily: T.mono,
                                fontSize: 11,
                                color: T.ink70),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Primary(
                  label: '+  Nuevo proyecto',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const NewProjectScreen())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alta de proyecto
// ---------------------------------------------------------------------------

class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key});
  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _customer = TextEditingController(text: 'Familia Retana');
  final _address = TextEditingController(text: 'Av. Escazu 340');
  final _phone = TextEditingController();
  final _consumption = TextEditingController(text: '18576');
  final _tariff = TextEditingController(text: '96.4');

  @override
  void dispose() {
    _customer.dispose();
    _address.dispose();
    _phone.dispose();
    _consumption.dispose();
    _tariff.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType? type, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: T.edge),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Label(label),
            TextField(
              controller: c,
              keyboardType: type,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: const TextStyle(color: T.ink25, fontSize: 14),
              ),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);
    return Ambient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Nuevo proyecto')),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                  children: [
                    const H1('Para quien es?'),
                    const SizedBox(height: 16),
                    _field('NOMBRE *', _customer),
                    _field('DIRECCION', _address),
                    _field('WHATSAPP', _phone,
                        type: TextInputType.phone, hint: 'opcional'),
                    const SizedBox(height: 12),
                    const Label('consumo y tarifa'),
                    const SizedBox(height: 8),
                    _field('CONSUMO ANUAL (kWh)', _consumption,
                        type: TextInputType.number),
                    _field('TARIFA (por kWh)', _tariff,
                        type: const TextInputType.numberWithOptions(
                            decimal: true)),
                    const SizedBox(height: 4),
                    Glass(
                      padding: const EdgeInsets.all(13),
                      child: Row(children: [
                        Container(
                            width: 5,
                            height: 30,
                            decoration: BoxDecoration(
                                color: T.volt,
                                borderRadius: BorderRadius.circular(9))),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Text(
                            'Los datos solares del sitio quedan disponibles sin conexion.',
                            style: TextStyle(fontSize: 11.5, color: T.ink70),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Primary(
                  label: 'Medir el techo',
                  onTap: () {
                    final p = Project(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      customer: _customer.text.trim().isEmpty
                          ? 'Cliente sin nombre'
                          : _customer.text.trim(),
                      address: _address.text.trim(),
                      phone: _phone.text.trim(),
                      annualConsumptionKwh:
                          double.tryParse(_consumption.text) ?? 18576,
                    );
                    p.finance.tariffPerKwh =
                        double.tryParse(_tariff.text.replaceAll(',', '.')) ??
                            96.4;
                    state.create(p);
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => const CaptureScreen()));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
