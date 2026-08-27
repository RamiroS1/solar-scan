import 'dart:ui';

import '../models.dart';
import 'geo.dart';

class LayoutOptions {
  final double edgeMargin;
  final double rowGap;
  final double colGap;
  final PanelOrientation? orientation;
  final int offsetSteps;
  const LayoutOptions({
    this.edgeMargin = 0.4,
    this.rowGap = 0.02,
    this.colGap = 0.02,
    this.orientation,
    this.offsetSteps = 4,
  });

  LayoutOptions copyWith({double? edgeMargin, PanelOrientation? orientation}) =>
      LayoutOptions(
        edgeMargin: edgeMargin ?? this.edgeMargin,
        rowGap: rowGap,
        colGap: colGap,
        orientation: orientation ?? this.orientation,
        offsetSteps: offsetSteps,
      );
}

class PanelLayout {
  static List<PanelPlacement> pack(
    RoofFacet facet,
    PanelModule module, [
    LayoutOptions opts = const LayoutOptions(),
  ]) {
    if (facet.outline.length < 3) return const [];

    final poly = Geo.ringToRoof(facet.outline, facet.azimuthDeg, facet.tiltDeg);
    final exclusions = facet.obstacles
        .map((o) => Geo.inflate(
            Geo.ringToRoof(o.outline, facet.azimuthDeg, facet.tiltDeg),
            o.clearanceM))
        .toList();

    final orientations = opts.orientation != null
        ? [opts.orientation!]
        : [PanelOrientation.portrait, PanelOrientation.landscape];

    List<PanelPlacement> best = const [];

    for (final o in orientations) {
      final w = o == PanelOrientation.portrait ? module.widthM : module.heightM;
      final h = o == PanelOrientation.portrait ? module.heightM : module.widthM;
      final stepX = w + opts.colGap;
      final stepY = h + opts.rowGap;

      for (int ox = 0; ox < opts.offsetSteps; ox++) {
        for (int oy = 0; oy < opts.offsetSteps; oy++) {
          final cand = _grid(
            poly: poly,
            exclusions: exclusions,
            facetId: facet.id,
            orientation: o,
            w: w,
            h: h,
            stepX: stepX,
            stepY: stepY,
            offX: stepX * ox / opts.offsetSteps,
            offY: stepY * oy / opts.offsetSteps,
            margin: opts.edgeMargin,
          );
          if (cand.length > best.length) best = cand;
        }
      }
    }
    return best;
  }

  static List<PanelPlacement> _grid({
    required List<Offset> poly,
    required List<List<Offset>> exclusions,
    required String facetId,
    required PanelOrientation orientation,
    required double w,
    required double h,
    required double stepX,
    required double stepY,
    required double offX,
    required double offY,
    required double margin,
  }) {
    final (minB, maxB) = Geo.bounds(poly);
    final out = <PanelPlacement>[];
    double y = minB.dy + offY;
    while (y + h <= maxB.dy + stepY) {
      double x = minB.dx + offX;
      while (x + w <= maxB.dx + stepX) {
        final corners = [
          Offset(x, y),
          Offset(x + w, y),
          Offset(x + w, y + h),
          Offset(x, y + h),
        ];
        if (_fits(corners, poly, exclusions, margin)) {
          out.add(PanelPlacement(
              facetId, Offset(x + w / 2, y + h / 2), orientation));
        }
        x += stepX;
      }
      y += stepY;
    }
    return out;
  }

  static bool _fits(List<Offset> corners, List<Offset> poly,
      List<List<Offset>> exclusions, double margin) {
    for (final c in corners) {
      if (Geo.signedDistanceToEdge(c, poly) < margin) return false;
    }
    for (final ex in exclusions) {
      if (Geo.polygonsOverlap(corners, ex)) return false;
    }
    return true;
  }

  static List<Offset> cornersOf(PanelPlacement p, PanelModule module) {
    final w = p.orientation == PanelOrientation.portrait
        ? module.widthM
        : module.heightM;
    final h = p.orientation == PanelOrientation.portrait
        ? module.heightM
        : module.widthM;
    final c = p.centerRoof;
    return [
      Offset(c.dx - w / 2, c.dy - h / 2),
      Offset(c.dx + w / 2, c.dy - h / 2),
      Offset(c.dx + w / 2, c.dy + h / 2),
      Offset(c.dx - w / 2, c.dy + h / 2),
    ];
  }
}
