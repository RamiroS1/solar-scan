import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'core.dart';
import 'models.dart';
import 'services.dart';

/// Estado de la aplicacion. Sin dependencias externas: un ChangeNotifier
/// expuesto por InheritedNotifier basta para el alcance de esta version.
class AppState extends ChangeNotifier {
  final List<Project> projects = [];
  Project? current;

  AppState() {
    projects.addAll([
      Project(
          id: 'p1',
          customer: 'Taller Mendoza',
          address: 'Zona Industrial',
          status: ProjectStatus.sent),
      Project(
          id: 'p2',
          customer: 'Casa Villalobos',
          address: 'Santa Ana',
          status: ProjectStatus.approved),
    ]);
  }

  void create(Project p) {
    projects.insert(0, p);
    current = p;
    notifyListeners();
  }

  void touch() => notifyListeners();

  /// Recalcula el layout de todos los faldones.
  void repack(LayoutOptions opts) {
    final p = current;
    if (p == null) return;
    p.panels
      ..clear()
      ..addAll(p.facets.expand((f) => PanelLayout.pack(f, p.module, opts)));
    notifyListeners();
  }
}

class Store extends InheritedNotifier<AppState> {
  const Store({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<Store>()!.notifier!;
}

// ===========================================================================
// PLANTA DEL TECHO + PANELES
// ===========================================================================

class RoofPainter extends CustomPainter {
  final RoofFacet facet;
  final List<PanelPlacement> panels;
  final PanelModule module;
  final double pxPerM;
  final Offset origin;
  final bool showGrid;

  RoofPainter({
    required this.facet,
    required this.panels,
    required this.module,
    required this.pxPerM,
    required this.origin,
    this.showGrid = true,
  });

  Offset _p(Offset m) => origin + Offset(m.dx * pxPerM, -m.dy * pxPerM);

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      final grid = Paint()
        ..color = T.ink.withOpacity(.07)
        ..strokeWidth = 1;
      for (double x = origin.dx % pxPerM; x < size.width; x += pxPerM) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (double y = origin.dy % pxPerM; y < size.height; y += pxPerM) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }

    if (facet.outline.length >= 3) {
      final path = Path()..moveTo(_p(facet.outline[0]).dx, _p(facet.outline[0]).dy);
      for (final v in facet.outline.skip(1)) {
        path.lineTo(_p(v).dx, _p(v).dy);
      }
      path.close();

      canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(colors: [
              T.volt.withOpacity(.22),
              T.iris.withOpacity(.18),
            ]).createShader(Offset.zero & size));
      canvas.drawPath(
          path,
          Paint()
            ..color = T.volt
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4);
    } else if (facet.outline.length == 2) {
      canvas.drawLine(
          _p(facet.outline[0]),
          _p(facet.outline[1]),
          Paint()
            ..color = T.volt
            ..strokeWidth = 2.4);
    }

    // obstaculos
    for (final o in facet.obstacles) {
      if (o.outline.length < 3) continue;
      final op = Path()..moveTo(_p(o.outline[0]).dx, _p(o.outline[0]).dy);
      for (final v in o.outline.skip(1)) {
        op.lineTo(_p(v).dx, _p(v).dy);
      }
      op.close();
      canvas.drawPath(op, Paint()..color = T.clay.withOpacity(.35));
      canvas.drawPath(
          op,
          Paint()
            ..color = T.clay
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    // paneles: del plano del techo de vuelta a la planta
    final fill = Paint()
      ..shader = T.module.createShader(Offset.zero & size);
    final stroke = Paint()
      ..color = Colors.white.withOpacity(.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final p in panels) {
      final corners = PanelLayout.cornersOf(p, module)
          .map((c) => Geo.fromRoof(c, facet.azimuthDeg, facet.tiltDeg))
          .map(_p)
          .toList();
      final path = Path()..moveTo(corners[0].dx, corners[0].dy);
      for (final c in corners.skip(1)) {
        path.lineTo(c.dx, c.dy);
      }
      path.close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }

    // vertices
    for (final v in facet.outline) {
      final c = _p(v);
      canvas.drawCircle(c, 7, Paint()..color = Colors.white);
      canvas.drawCircle(
          c,
          7,
          Paint()
            ..color = T.volt
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6);
    }

    // escala
    final bar = Paint()
      ..color = T.ink45
      ..strokeWidth = 2;
    final y = size.height - 22;
    canvas.drawLine(Offset(16, y), Offset(16 + pxPerM * 5, y), bar);
    canvas.drawLine(Offset(16, y - 4), Offset(16, y + 4), bar);
    canvas.drawLine(
        Offset(16 + pxPerM * 5, y - 4), Offset(16 + pxPerM * 5, y + 4), bar);
    final tp = TextPainter(
      text: const TextSpan(
          text: '5 m',
          style: TextStyle(fontSize: 10, color: T.ink45, fontFamily: T.mono)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(20 + pxPerM * 5, y - 7));
  }

  @override
  bool shouldRepaint(covariant RoofPainter old) => true;
}

// ===========================================================================
// CASA ISOMETRICA
// ===========================================================================

class HousePainter extends CustomPainter {
  final int panelCount;
  final double phase; // 0..1, anima el flujo de energia

  HousePainter({required this.panelCount, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 276.0;
    canvas.save();
    canvas.scale(s);

    Path poly(List<Offset> pts) {
      final p = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (final q in pts.skip(1)) {
        p.lineTo(q.dx, q.dy);
      }
      return p..close();
    }

    // sombra
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(146, 210), width: 200, height: 48),
        Paint()..color = T.ink.withOpacity(.07));

    // muros
    canvas.drawPath(
        poly(const [
          Offset(60, 150),
          Offset(150, 200),
          Offset(150, 148),
          Offset(60, 98)
        ]),
        Paint()..color = const Color(0xFFCBD3DE));
    canvas.drawPath(
        poly(const [
          Offset(150, 200),
          Offset(240, 150),
          Offset(240, 98),
          Offset(150, 148)
        ]),
        Paint()..color = const Color(0xFFEDF1F6));

    // ventanas
    final win = Paint()..color = const Color(0xFF7E8CA0).withOpacity(.5);
    canvas.drawPath(
        poly(const [
          Offset(84, 128),
          Offset(104, 139),
          Offset(104, 158),
          Offset(84, 147)
        ]),
        win);
    canvas.drawPath(
        poly(const [
          Offset(170, 160),
          Offset(192, 148),
          Offset(192, 167),
          Offset(170, 179)
        ]),
        win);

    // techo
    canvas.drawPath(
        poly(const [Offset(60, 98), Offset(150, 148), Offset(105, 93)]),
        Paint()..color = const Color(0xFF828E9C));
    canvas.drawPath(
        poly(const [
          Offset(60, 98),
          Offset(105, 93),
          Offset(195, 43),
          Offset(150, 48)
        ]),
        Paint()..color = const Color(0xFF6E7A88));
    canvas.drawPath(
        poly(const [
          Offset(150, 148),
          Offset(240, 98),
          Offset(195, 43),
          Offset(105, 93)
        ]),
        Paint()..color = const Color(0xFF8B96A5));

    // Paneles sobre el agua sur. `map` es la transformacion afin del plano
    // real del faldon: u recorre el alero, v sube hacia la cumbrera.
    final fill = Paint()
      ..shader = T.module.createShader(const Rect.fromLTWH(100, 40, 145, 115));

    Offset map(double u, double v) =>
        Offset(150 + 90 * u - 45 * v, 148 - 50 * u - 55 * v);

    final n = panelCount.clamp(0, 15);
    int drawn = 0;
    for (int row = 0; row < 3 && drawn < n; row++) {
      for (int col = 0; col < 5 && drawn < n; col++) {
        final u0 = .06 + col * .176, v0 = .08 + row * .28;
        final u1 = u0 + .16, v1 = v0 + .26;
        final path = poly([
          map(u0, v0),
          map(u1, v0),
          map(u1, v1),
          map(u0, v1),
        ]);
        canvas.drawPath(path, fill);
        canvas.drawPath(
            path,
            Paint()
              ..color = const Color(0xFFF4F7FB)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
        drawn++;
      }
    }

    // sol
    canvas.drawCircle(
        const Offset(42, 32), 13, Paint()..color = T.sun.withOpacity(.18));
    canvas.drawCircle(const Offset(42, 32), 8, Paint()..color = T.sun);

    // flujos animados
    _dashed(canvas, const [Offset(50, 44), Offset(84, 62), Offset(118, 82)],
        T.sun, phase);
    _dashed(canvas, const [Offset(186, 96), Offset(220, 130), Offset(236, 178)],
        T.volt, phase);
    _dashed(canvas, const [Offset(150, 176), Offset(110, 200), Offset(70, 210)],
        T.iris, phase * .6);

    // poste de red y bateria
    final wire = Paint()
      ..color = const Color(0xFF98A4B2)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(256, 186), const Offset(256, 218), wire);
    canvas.drawLine(const Offset(247, 190), const Offset(265, 190), wire);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(52, 196, 17, 26), const Radius.circular(3)),
        Paint()..color = const Color(0xFFE7ECF2));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(55, 210, 11, 9), const Radius.circular(2)),
        Paint()..color = T.go);

    canvas.restore();
  }

  void _dashed(Canvas c, List<Offset> pts, Color color, double phase) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    path.quadraticBezierTo(pts[1].dx, pts[1].dy, pts[2].dx, pts[2].dy);
    final metric = path.computeMetrics().first;
    const dash = 6.0, gap = 9.0;
    double d = -((phase * (dash + gap)) % (dash + gap));
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    while (d < metric.length) {
      final start = math.max(0.0, d);
      final end = math.min(metric.length, d + dash);
      if (end > start) c.drawPath(metric.extractPath(start, end), paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant HousePainter old) =>
      old.phase != phase || old.panelCount != panelCount;
}

// ===========================================================================
// GRAFICO DE BARRAS MENSUAL
// ===========================================================================

class BarsPainter extends CustomPainter {
  final List<double> values;
  final double? reference;
  BarsPainter(this.values, {this.reference});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = math.max(
        values.reduce(math.max), reference ?? 0);
    if (maxV <= 0) return;
    final w = size.width / values.length;
    final labels = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    final base = size.height - 16;

    for (int i = 0; i < values.length; i++) {
      final h = (values[i] / maxV) * (base - 6);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(i * w + 2, base - h, w - 4, h),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [T.iris.withOpacity(.45), T.volt],
            ).createShader(Rect.fromLTWH(0, base - h, size.width, h)));

      final tp = TextPainter(
        text: TextSpan(
            text: labels[i],
            style: const TextStyle(
                fontSize: 9, color: T.ink45, fontFamily: T.mono)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(i * w + (w - tp.width) / 2, base + 3));
    }

    if (reference != null && reference! > 0) {
      final y = base - (reference! / maxV) * (base - 6);
      final p = Paint()
        ..color = T.clay
        ..strokeWidth = 1.6;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(x + 5, y), p);
        x += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant BarsPainter old) => true;
}
