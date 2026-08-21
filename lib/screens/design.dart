import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core.dart';
import '../models.dart';
import '../painters.dart';
import '../services.dart';
import 'numbers.dart';

class DesignScreen extends StatefulWidget {
  const DesignScreen({super.key});
  @override
  State<DesignScreen> createState() => _DesignScreenState();
}

class _DesignScreenState extends State<DesignScreen> {
  double _margin = 0.4;
  PanelOrientation? _orientation;

  LayoutOptions get _opts =>
      LayoutOptions(edgeMargin: _margin, orientation: _orientation);

  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);
    final p = state.current;
    if (p == null || p.facets.isEmpty) {
      return const Scaffold(body: Center(child: Text('Sin faldon medido')));
    }
    final facet = p.facets.first;
    final gross = Geo.facetArea(facet);
    final usable = Geo.usableArea(facet);
    final used = p.panels.length * p.module.areaM2;

    return Ambient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Distribucion')),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      color: Colors.white.withOpacity(.45),
                      child: LayoutBuilder(builder: (context, c) {
                        // encuadra el faldon en el lienzo
                        final (minB, maxB) = Geo.bounds(facet.outline);
                        final w = (maxB.dx - minB.dx).abs();
                        final h = (maxB.dy - minB.dy).abs();
                        // encaja el faldon en el lienzo con 18% de aire
                        final scale = (w > 0.1 && h > 0.1)
                            ? (math.min(c.maxWidth / w, c.maxHeight / h) * 0.82)
                                .clamp(4.0, 60.0)
                            : 11.0;
                        final center = Geo.centroid(facet.outline);
                        return CustomPaint(
                          size: Size.infinite,
                          painter: RoofPainter(
                            facet: facet,
                            panels: p.panels,
                            module: p.module,
                            pxPerM: scale,
                            origin: Offset(
                              c.maxWidth / 2 - center.dx * scale,
                              c.maxHeight / 2 + center.dy * scale,
                            ),
                            showGrid: false,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(children: [
                  _tile('${p.panels.length}', 'paneles'),
                  const SizedBox(width: 7),
                  _tile(p.kwp.toStringAsFixed(2), 'kWp'),
                  const SizedBox(width: 7),
                  _tile(
                      usable > 0
                          ? '${(used / usable * 100).round()}%'
                          : '0%',
                      'del area util'),
                ]),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Glass(
                  child: Column(
                    children: [
                      Row(children: [
                        const Expanded(child: Label('modulo')),
                        DropdownButton<PanelModule>(
                          value: p.module,
                          underline: const SizedBox(),
                          isDense: true,
                          items: PanelModule.catalog
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m.name,
                                        style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (m) {
                            if (m == null) return;
                            p.module = m;
                            state.repack(_opts);
                          },
                        ),
                      ]),
                      const Divider(color: T.hair, height: 14),
                      Row(children: [
                        SizedBox(
                            width: 78,
                            child: Text('Retiro',
                                style: const TextStyle(
                                    fontSize: 11.5, color: T.ink45))),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              activeTrackColor: T.volt,
                              inactiveTrackColor: T.ink.withOpacity(.12),
                              thumbColor: Colors.white,
                              overlayShape: SliderComponentShape.noOverlay,
                            ),
                            child: Slider(
                              value: _margin,
                              min: 0,
                              max: 1.2,
                              onChanged: (v) => setState(() => _margin = v),
                              onChangeEnd: (v) => state.repack(_opts),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text('${(_margin * 100).round()} cm',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontFamily: T.mono,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: _segment('Auto', _orientation == null, () {
                            setState(() => _orientation = null);
                            state.repack(_opts);
                          }),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: _segment('Retrato',
                              _orientation == PanelOrientation.portrait, () {
                            setState(
                                () => _orientation = PanelOrientation.portrait);
                            state.repack(_opts);
                          }),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: _segment('Paisaje',
                              _orientation == PanelOrientation.landscape, () {
                            setState(() =>
                                _orientation = PanelOrientation.landscape);
                            state.repack(_opts);
                          }),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      KV('Area bruta', '${gross.toStringAsFixed(1)} m\u00B2'),
                      KV('Area util', '${usable.toStringAsFixed(1)} m\u00B2',
                          color: T.volt),
                      const SizedBox(height: 12),
                      Primary(
                        label: 'Ver produccion',
                        onTap: p.panels.isEmpty
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const NumbersScreen())),
                      ),
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

  Widget _tile(String v, String k) => Expanded(
        child: Glass(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Column(children: [
            Text(v,
                style: const TextStyle(
                    fontFamily: T.mono,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(k, style: const TextStyle(fontSize: 9.5, color: T.ink45)),
          ]),
        ),
      );

  Widget _segment(String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
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
      );
}
