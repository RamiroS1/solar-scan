import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core.dart';
import 'scene_model.dart';

/// Rasterizador por algoritmo del pintor, en Dart puro.
///
/// Por que no un plugin: `model_viewer_plus` mete un WebView entero (arranque
/// lento, memoria, y nada de control sobre el grafo de escena) y las
/// alternativas nativas pesan decenas de MB en el APK. Con 1000-4000 triangulos
/// y sin texturas, esto va sobrado y compila a la primera en cualquier telefono.
///
/// La clave del rendimiento es `drawVertices`: todos los triangulos ya
/// ordenados por profundidad salen en UNA sola llamada al canvas.
class ScenePainter extends CustomPainter {
  final SceneModel model;
  final double yaw; // grados
  final double pitch; // grados
  final double zoom;
  final double sunHour; // 6..18
  final int visiblePanels;
  final bool showEnv;
  final bool showStructure;

  ScenePainter({
    required this.model,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.sunHour,
    required this.visiblePanels,
    this.showEnv = true,
    this.showStructure = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final m = model;
    final n = m.triangleCount;
    if (n == 0) return;

    final cy = math.cos(yaw * math.pi / 180), sy = math.sin(yaw * math.pi / 180);
    final cp = math.cos(pitch * math.pi / 180),
        sp = math.sin(pitch * math.pi / 180);
    final scale = (math.min(size.width, size.height) / m.size) * 0.80 * zoom;
    final ox = size.width / 2, oy = size.height / 2 + size.height * 0.06;

    // 1) proyectar todos los vertices una sola vez
    final vc = m.positions.length ~/ 3;
    final sxArr = Float32List(vc), syArr = Float32List(vc);
    for (int i = 0; i < vc; i++) {
      final x = m.positions[i * 3] - m.cx;
      final y = m.positions[i * 3 + 1] - m.cy;
      final z = m.positions[i * 3 + 2] - m.cz;
      final rx = x * cy - z * sy;
      final rz = x * sy + z * cy;
      final ry = y * cp - rz * sp;
      sxArr[i] = ox + rx * scale;
      syArr[i] = oy - ry * scale;
    }

    // 2) filtrar, calcular profundidad y descartar caras traseras
    final order = Int32List(n);
    final depth = Float32List(n);
    int count = 0;

    for (int t = 0; t < n; t++) {
      final part = m.parts[m.triPart[t]];
      if (part.isPanel && part.panelIndex >= visiblePanels) continue;
      if (part.isEnv && !showEnv) continue;
      if (!part.isEnv && !part.isPanel && !showStructure) continue;

      final ia = m.triA[t], ib = m.triB[t], ic = m.triC[t];
      final ax = sxArr[ia], ay = syArr[ia];
      final area = (sxArr[ib] - ax) * (syArr[ic] - ay) -
          (sxArr[ic] - ax) * (syArr[ib] - ay);
      if (area > 0) continue; // cara trasera

      final y = m.triCentroid[t * 3 + 1] - m.cy;
      final z0 = m.triCentroid[t * 3 + 2] - m.cz;
      final x0 = m.triCentroid[t * 3] - m.cx;
      final rz = x0 * sy + z0 * cy;
      depth[t] = y * sp + rz * cp;
      order[count++] = t;
    }
    if (count == 0) return;

    // 3) ordenar de lejos a cerca
    final visible = Int32List.sublistView(order, 0, count);
    final sorted = visible.toList(growable: false)
      ..sort((a, b) => depth[a].compareTo(depth[b]));

    // 4) volcar a un solo lote de vertices con color plano por cara
    final pos = Float32List(count * 6);
    final col = Int32List(count * 3);
    final sun = _sunDirection();

    for (int k = 0; k < count; k++) {
      final t = sorted[k];
      final ia = m.triA[t], ib = m.triB[t], ic = m.triC[t];
      final p = k * 6;
      pos[p] = sxArr[ia];
      pos[p + 1] = syArr[ia];
      pos[p + 2] = sxArr[ib];
      pos[p + 3] = syArr[ib];
      pos[p + 4] = sxArr[ic];
      pos[p + 5] = syArr[ic];

      final part = m.parts[m.triPart[t]];
      final c = _shade(part, _normalDot(m, t, sun));
      col[k * 3] = c;
      col[k * 3 + 1] = c;
      col[k * 3 + 2] = c;
    }

    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      pos,
      colors: col,
    );
    canvas.drawVertices(vertices, BlendMode.srcOver, Paint());
  }

  /// Direccion del sol segun la hora: este al amanecer, oeste al atardecer.
  List<double> _sunDirection() {
    final a = (sunHour - 12) / 6 * math.pi / 2;
    return [math.sin(a), math.cos(a) * 0.85 + 0.15, -0.35];
  }

  double _normalDot(SceneModel m, int t, List<double> s) {
    final ia = m.triA[t] * 3, ib = m.triB[t] * 3, ic = m.triC[t] * 3;
    final ux = m.positions[ib] - m.positions[ia];
    final uy = m.positions[ib + 1] - m.positions[ia + 1];
    final uz = m.positions[ib + 2] - m.positions[ia + 2];
    final wx = m.positions[ic] - m.positions[ia];
    final wy = m.positions[ic + 1] - m.positions[ia + 1];
    final wz = m.positions[ic + 2] - m.positions[ia + 2];
    final nx = uy * wz - uz * wy;
    final ny = uz * wx - ux * wz;
    final nz = ux * wy - uy * wx;
    final len = math.sqrt(nx * nx + ny * ny + nz * nz);
    if (len < 1e-9) return 0;
    final sl = math.sqrt(s[0] * s[0] + s[1] * s[1] + s[2] * s[2]);
    final d = (nx * s[0] + ny * s[1] + nz * s[2]) / (len * sl);
    return d < 0 ? -d : d; // iluminamos ambas caras: los modelos son simples
  }

  int _shade(ScenePart part, double d) {
    final k = 0.34 + 0.72 * d;
    double r = math.pow(math.min(1.0, part.r * k), 1 / 2.2).toDouble();
    double g = math.pow(math.min(1.0, part.g * k), 1 / 2.2).toDouble();
    double b = math.pow(math.min(1.0, part.b * k), 1 / 2.2).toDouble();

    // El vidrio del modulo necesita el brillo especular o se ve como asfalto.
    if (part.isGlass) {
      final s = math.pow(d, 6).toDouble() * 0.55;
      r = math.min(1.0, r + s * 0.35);
      g = math.min(1.0, g + s * 0.55);
      b = math.min(1.0, b + s * 0.90);
    }
    return 0xFF000000 |
        ((r * 255).round() << 16) |
        ((g * 255).round() << 8) |
        (b * 255).round();
  }

  @override
  bool shouldRepaint(covariant ScenePainter old) =>
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.zoom != zoom ||
      old.sunHour != sunHour ||
      old.visiblePanels != visiblePanels ||
      old.showEnv != showEnv ||
      old.showStructure != showStructure ||
      old.model != model;
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class SceneView extends StatefulWidget {
  final Archetype archetype;
  final int panels;
  final double sunHour;
  final bool showEnv;
  final bool interactive;

  const SceneView({
    super.key,
    required this.archetype,
    required this.panels,
    this.sunHour = 13,
    this.showEnv = true,
    this.interactive = true,
  });

  @override
  State<SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends State<SceneView> {
  SceneModel? _model;
  Object? _error;
  double _yaw = 38, _pitch = 28, _zoom = 1;
  double _zoomStart = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SceneView old) {
    super.didUpdateWidget(old);
    if (old.archetype != widget.archetype) _load();
  }

  Future<void> _load() async {
    try {
      final m = await SceneModel.load(widget.archetype.asset);
      if (mounted) setState(() => _model = m);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('No se pudo cargar el modelo.\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: T.ink45)),
        ),
      );
    }
    final m = _model;
    if (m == null) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: T.volt),
        ),
      );
    }

    final painter = CustomPaint(
      size: Size.infinite,
      painter: ScenePainter(
        model: m,
        yaw: _yaw,
        pitch: _pitch,
        zoom: _zoom,
        sunHour: widget.sunHour,
        visiblePanels: widget.panels,
        showEnv: widget.showEnv,
      ),
    );

    if (!widget.interactive) return painter;

    return GestureDetector(
      onScaleStart: (_) => _zoomStart = _zoom,
      onScaleUpdate: (d) {
        setState(() {
          if (d.pointerCount > 1) {
            _zoom = (_zoomStart * d.scale).clamp(0.4, 4.0);
          }
          _yaw = (_yaw - d.focalPointDelta.dx * 0.4) % 360;
          _pitch = (_pitch + d.focalPointDelta.dy * 0.28).clamp(5.0, 80.0);
        });
      },
      child: painter,
    );
  }
}
