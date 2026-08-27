import 'package:flutter/material.dart';

import '../core.dart';
import '../domain/area_capture.dart';
import '../domain/sizing.dart';
import '../models.dart';
import '../painters.dart';
import '../services.dart';
import '../widgets/proposal_sections.dart';
import 'design.dart';

/// Captura del faldon. Soporta dibujo libre o rectangulo por dimensiones,
/// con retroalimentacion de area objetivo.
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
  RoofDrawMode _drawMode = RoofDrawMode.rectangle;

  final _widthCtrl = TextEditingController(text: '15');
  final _heightCtrl = TextEditingController(text: '12');
  final _targetCtrl = TextEditingController();

  Size _canvasSize = Size.zero;
  Offset get _origin => Offset(_canvasSize.width / 2, _canvasSize.height / 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapFromProject());
  }

  void _bootstrapFromProject() {
    final p = Store.of(context).current;
    if (p == null) return;

    _drawMode = p.drawMode;
    if (p.targetAreaM2 != null) {
      _targetCtrl.text = p.targetAreaM2!.round().toString();
    } else {
      final suggested = SizingHints.suggestedAreaForProject(p);
      if (suggested > 0) {
        _targetCtrl.text = suggested.round().toString();
        p.targetAreaM2 = suggested.roundToDouble();
      }
    }

    if (p.facets.isNotEmpty) {
      final f = p.facets.first;
      _outline.addAll(f.outline);
      _obstacles.addAll(f.obstacles);
      _tilt = f.tiltDeg;
      _azimuth = f.azimuthDeg;
      _syncRectangleFieldsFromOutline();
    } else if (_drawMode == RoofDrawMode.rectangle) {
      _applyRectangleFromFields();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Offset _toMeters(Offset local) => Offset(
        (local.dx - _origin.dx) / _pxPerM,
        (_origin.dy - local.dy) / _pxPerM,
      );

  double get _planArea => Geo.polygonArea(_outline);
  double get _realArea => Geo.slopedArea(_planArea, _tilt);
  double get _perimeter => Geo.perimeter(_outline);

  double? get _targetArea {
    final v = double.tryParse(_targetCtrl.text.replaceAll(',', '.'));
    return v != null && v > 0 ? v : null;
  }

  AreaTargetFeedback get _areaFeedback => AreaCapture.evaluate(
        currentSlopedM2: _realArea,
        targetSlopedM2: _targetArea,
      );

  void _syncRectangleFieldsFromOutline() {
    if (_outline.length != 4) return;
    final (minB, maxB) = Geo.bounds(_outline);
    _widthCtrl.text = (maxB.dx - minB.dx).abs().toStringAsFixed(1);
    _heightCtrl.text = (maxB.dy - minB.dy).abs().toStringAsFixed(1);
  }

  void _applyRectangleFromFields() {
    final w = double.tryParse(_widthCtrl.text.replaceAll(',', '.'));
    final h = double.tryParse(_heightCtrl.text.replaceAll(',', '.'));
    if (w == null || h == null || w <= 0 || h <= 0) return;
    setState(() {
      _outline
        ..clear()
        ..addAll(AreaCapture.rectangleOutline(widthM: w, heightM: h));
    });
  }

  void _applyTargetArea() {
    final target = _targetArea;
    if (target == null) return;
    final dims = AreaCapture.dimensionsForSlopedArea(
      targetSlopedM2: target,
      tiltDeg: _tilt,
    );
    _widthCtrl.text = dims.widthM.toStringAsFixed(1);
    _heightCtrl.text = dims.heightM.toStringAsFixed(1);
    _applyRectangleFromFields();
    final p = Store.of(context).current;
    if (p != null) p.targetAreaM2 = target;
  }

  void _tap(Offset local) {
    if (_drawMode == RoofDrawMode.rectangle && !_drawingObstacle) return;
    setState(() {
      final m = Geo.snap(_toMeters(local), step: 0.5);
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

    final consumptionHint =
        project != null ? SizingHints.consumptionHint(project) : '';

    return Ambient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(project?.customer ?? 'Medicion'),
          actions: [
            if (_drawMode == RoofDrawMode.freehand)
              IconButton(
                  onPressed: _undo,
                  icon: const Icon(Icons.undo, size: 20)),
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
                      if (_targetArea != null) ...[
                        const SizedBox(height: 8),
                        AreaTargetBanner(feedback: _areaFeedback),
                      ],
                      if (consumptionHint.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(consumptionHint,
                            style: const TextStyle(
                                fontSize: 10.5, color: T.ink70)),
                      ],
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
                      _modeSelector(),
                      const SizedBox(height: 10),
                      if (_drawMode == RoofDrawMode.rectangle) ...[
                        _dimField('Ancho (m)', _widthCtrl, _applyRectangleFromFields),
                        _dimField('Largo (m)', _heightCtrl, _applyRectangleFromFields),
                        _dimField('Area objetivo (m²)', _targetCtrl, () {
                          final v = _targetArea;
                          if (project != null) project.targetAreaM2 = v;
                          if (v != null) _applyTargetArea();
                          setState(() {});
                        }),
                        Row(children: [
                          Expanded(
                            child: Ghost(
                              label: 'Ajustar al objetivo',
                              onTap: _targetArea != null ? _applyTargetArea : null,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                      ],
                      _slider('Inclinacion', '${_tilt.round()}\u00B0', _tilt, 0,
                          60, (v) {
                        setState(() => _tilt = v);
                        if (_drawMode == RoofDrawMode.rectangle &&
                            _targetArea != null) {
                          _applyTargetArea();
                        }
                      }),
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
                                    project.drawMode = _drawMode;
                                    project.targetAreaM2 = _targetArea;
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

  Widget _modeSelector() {
    Widget seg(String label, RoofDrawMode mode) {
      final on = _drawMode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _drawMode = mode;
              if (mode == RoofDrawMode.rectangle) {
                _applyRectangleFromFields();
              }
            });
            Store.of(context).current?.drawMode = mode;
          },
          child: Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? Colors.white : T.ink.withOpacity(.06),
              borderRadius: BorderRadius.circular(11),
              boxShadow: on
                  ? [
                      BoxShadow(
                          color: T.ink.withOpacity(.10),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                  : null,
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: on ? T.ink : T.ink45)),
          ),
        ),
      );
    }

    return Row(children: [
      seg('Rectangulo', RoofDrawMode.rectangle),
      const SizedBox(width: 5),
      seg('Libre', RoofDrawMode.freehand),
    ]);
  }

  Widget _dimField(String label, TextEditingController c, VoidCallback onApply) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 11.5, color: T.ink45))),
        SizedBox(
          width: 88,
          child: TextField(
            controller: c,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontFamily: T.mono,
                fontSize: 13,
                fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: T.hair)),
            ),
            onSubmitted: (_) => onApply(),
            onEditingComplete: onApply,
          ),
        ),
      ]),
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
                fontFamily: T.mono,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}
