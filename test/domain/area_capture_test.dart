import 'package:flutter_test/flutter_test.dart';
import 'package:solarscan/domain/area_capture.dart';
import 'package:solarscan/services.dart';

void main() {
  group('AreaCapture', () {
    test('rectangleOutline produces expected plan area', () {
      final outline = AreaCapture.rectangleOutline(widthM: 10, heightM: 8);
      expect(Geo.polygonArea(outline), closeTo(80, 0.01));
    });

    test('dimensionsForSlopedArea respects tilt', () {
      final dims = AreaCapture.dimensionsForSlopedArea(
        targetSlopedM2: 180,
        tiltDeg: 20,
      );
      final sloped = Geo.slopedArea(dims.planAreaM2, 20);
      expect(sloped, closeTo(180, 0.5));
    });

    test('evaluate reports under target', () {
      final fb = AreaCapture.evaluate(
        currentSlopedM2: 170,
        targetSlopedM2: 180,
      );
      expect(fb.status, AreaTargetStatus.under);
      expect(fb.deltaM2, closeTo(-10, 0.01));
    });

    test('evaluate reports on target within tolerance', () {
      final fb = AreaCapture.evaluate(
        currentSlopedM2: 181,
        targetSlopedM2: 180,
        toleranceM2: 2,
      );
      expect(fb.status, AreaTargetStatus.onTarget);
    });
  });
}
