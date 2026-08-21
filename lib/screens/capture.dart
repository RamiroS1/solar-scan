import 'package:flutter/material.dart';

import '../core.dart';
import '../models.dart';
import '../painters.dart';
import '../services.dart';
import 'design.dart';

/// Captura del faldon. El lienzo es una planta a escala: cada toque anade un
/// vertice en METROS reales, y el area se corrige por la inclinacion.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final List<Offset> _outline = [];
  final List<Obstacle> _obstacles = [];
  final List<Offset> _pending = [];
  bool _drawingObstacle = false;

  double _tilt = 20;
  double _azimuth = 180;
  double _pxPerM = 11;

  Size _canvasSize = Size.zero;
  Offset get _origin => Offset(_canvasSize.width / 2, _canvasSize.height / 2);

  Offset _toMeters(Offset local) => Offset(
        (local.dx - _origin.dx) / _pxPerM,
        (_origin.dy - local.dy) / _pxPerM,
      );

  double get _planArea => Geo.polygonArea(_outline);
  double get _realArea => Geo.slopedArea(_planArea, _tilt);
  double get _perimeter => Geo.perimeter(_outline);

  void _tap(Offset local) {
    setState(() {
      final m = _toMeters(local);
      if (_drawingObstacle) {
        _pending.add(m);
      } else {
        _outline.add(m);
      }
    });
  }

  void _undo() => setState(() {
        if (_drawingObstacle && _pending.isNotEmpty) {
          _pending.removeLast();
        } else if (_outline.isNotEmpty) {
          _outline.removeLast();
        }
      });

  void _closeObstacle() {
    if (_pending.length < 3) return;
    setState(() {
      _obstacles.add(Obstacle(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: 'Obstaculo ${_obstacles.length + 1}',
        outline: List.of(_pending),
        heightM: 1.0,
      ));
      _pending.clear();
      _drawingObstacle = false;
    });
  }

  void _preset() {
    setState(() {
      _outline
        ..clear()
        ..addAll(const [
          Offset(-6, -4.5),
          Offset(6, -4.5),
          Offset(6, 4.5),
          Offset(-6, 4.5),
        ]);
    });
  }

  String _compass(double az) {
    const names = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    return names[(((az + 22.5) % 360) ~/ 45) % 8];
  }

  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);
    final project = state.current;

    final facet = RoofFacet(
      id: 'preview',
      name: 'Faldon',
      outline: _outline,
      tiltDeg: _tilt,
      azimuthDeg: _azimuth,
      obstacles: [
        ..._obstacles,
        if (_pending.length >= 3)
          Obstacle(id: 'tmp', label: 'tmp', outline: _pending),
      ],
    );

    return Ambient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(project?.customer ?? 'Medicion'),
          actions: [
            IconButton(
                onPressed: _preset,
                icon: const Icon(Icons.crop_square, size: 20),
                tooltip: 'Rectangulo de ejemplo'),
            IconButton(onPressed: _undo, icon: const Icon(Icons.undo, size: 20)),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: Glass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Readout(_realArea.toStringAsFixed(1),
                          unit: 'm\u00B2 reales', size: 36),
                      const SizedBox(height: 6),
                      Text(
                        'planta ${_planArea.toStringAsFixed(1)} m\u00B2 · '
                        'perimetro ${_perimeter.toStringAsFixed(1)} m · '
                        '${_outline.length} vertices',
                        style: const TextStyle(
                            fontFamily: T.mono, fontSize: 10.5, color: T.ink45),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      color: Colors.white.withOpacity(.45),
                      child: LayoutBuilder(builder: (context, c) {
                        _canvasSize = Size(c.maxWidth, c.maxHeight);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (d) => _tap(d.localPosition),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: RoofPainter(
                              facet: facet,
                              panels: const [],
                              module: project?.module ??
                                  PanelModule.catalog.first,
                              pxPerM: _pxPerM,
                              origin: _origin,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(children: [
                  Chip2(_drawingObstacle ? 'Marcando obstaculo' : 'Marcando faldon',
                      color: _drawingObstacle ? T.clay : T.sun),
                  const Spacer(),
                  Text('${_obstacles.length} obstaculos',
                      style: const TextStyle(
                          fontFamily: T.mono, fontSize: 10, color: T.ink45)),
                ]),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Glass(
                  child: Column(
                    children: [
                      _slider('Inclinacion', '${_tilt.round()}\u00B0', _tilt, 0,
                          60, (v) => setState(() => _tilt = v)),
                      _slider('Orientacion', _compass(_azimuth), _azimuth, 0,
                          359, (v) => setState(() => _azimuth = v)),
                      _slider('Zoom', '${_pxPerM.round()} px/m', _pxPerM, 5, 26,
                          (v) => setState(() => _pxPerM = v)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(
                          child: Ghost(
                            label: _drawingObstacle
                                ? (_pending.length >= 3
                                    ? 'Cerrar obstaculo'
                                    : 'Cancelar')
                                : 'Obstaculo',
                            onTap: () {
                              if (_drawingObstacle) {
                                if (_pending.length >= 3) {
                                  _closeObstacle();
                                } else {
                                  setState(() {
                                    _pending.clear();
                                    _drawingObstacle = false;
                                  });
                                }
                              } else {
                                setState(() => _drawingObstacle = true);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Primary(
                            label: 'Disenar paneles',
                            onTap: (_outline.length >= 3 && project != null)
                                ? () {
                                    project.facets
                                      ..clear()
                                      ..add(RoofFacet(
                                        id: 'f1',
                                        name: 'Faldon principal',
                                        outline: List.of(_outline),
                                        tiltDeg: _tilt,
                                        azimuthDeg: _azimuth,
                                        obstacles: List.of(_obstacles),
                                      ));
                                    state.repack(const LayoutOptions());
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const DesignScreen()));
                                  }
                                : null,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, String value, double v, double min, double max,
      ValueChanged<double> onChanged) {
    return Row(children: [
      SizedBox(
          width: 78,
          child: Text(label,
              style: const TextStyle(fontSize: 11.5, color: T.ink45))),
      Expanded(
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            activeTrackColor: T.volt,
            inactiveTrackColor: T.ink.withOpacity(.12),
            thumbColor: Colors.white,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(value: v, min: min, max: max, onChanged: onChanged),
        ),
      ),
      SizedBox(
        width: 52,
        child: Text(value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontFamily: T.mono, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}
