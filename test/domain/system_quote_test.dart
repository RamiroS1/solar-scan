import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:solarscan/domain/system_quote.dart';
import 'package:solarscan/models.dart';

void main() {
  test('buildBom includes inverter and optional battery', () {
    final p = Project(id: 't', customer: 'Test');
    p.panels.addAll(List.generate(
        20,
        (i) => PanelPlacement('f1', Offset(i.toDouble(), 0),
            PanelOrientation.portrait)));
    p.facets.add(RoofFacet(
      id: 'f1',
      name: 'F',
      outline: const [],
    ));

    final bom = SystemQuote.buildBom(p);
    expect(bom.any((b) => b.category == 'Inversor'), isTrue);
    expect(bom.any((b) => b.category == 'Bateria' && !b.included), isTrue);

    p.system.includeBattery = true;
    final bomWithBat = SystemQuote.buildBom(p);
    expect(
        bomWithBat.any((b) => b.category == 'Bateria' && b.included), isTrue);
  });

  test('buildBreakdown sums to total with battery', () {
    final p = Project(id: 't', customer: 'Test');
    p.panels.addAll(List.generate(
        24,
        (i) => PanelPlacement('f1', Offset(i.toDouble(), 0),
            PanelOrientation.portrait)));

    p.system.includeBattery = true;
    final bd = SystemQuote.buildBreakdown(p);
    final sum = bd.lines.fold<double>(0, (s, l) => s + l.amount);
    expect(sum, closeTo(bd.total, 1));
  });
}
