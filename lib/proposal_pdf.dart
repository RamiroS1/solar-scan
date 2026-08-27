import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'domain/solar_site.dart';
import 'domain/system_quote.dart';
import 'models.dart';
import 'services.dart';

const _months = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

Future<Uint8List> buildProposalPdf({
  required Project project,
  required ProductionResult production,
  required FinancialResult financial,
  String companyName = 'Volt CR',
  String companyContact = 'contacto@voltcr.com',
}) async {
  final doc = pw.Document();
  final primary = PdfColor.fromInt(0xFF2563EB);
  final accent = PdfColor.fromInt(0xFFFFA51F);
  final cur = project.finance.currency;
  final now = DateTime.now();
  final date = '${now.day.toString().padLeft(2, '0')}/'
      '${now.month.toString().padLeft(2, '0')}/${now.year}';

  final totalArea =
      project.facets.fold<double>(0, (a, f) => a + Geo.facetArea(f));
  final usedArea = project.panels.length * project.module.areaM2;
  final bom = SystemQuote.buildBom(project);
  final breakdown =
      financial.breakdown ?? SystemQuote.buildBreakdown(project);
  final inv = SystemQuote.resolveInverter(project);
  final site = project.solarSite ??
      SolarSiteResolver.resolve(address: project.address);
  final hints = ProjectFinanceHints(
    selfConsumption: project.finance.selfConsumption,
    degradation: project.finance.degradation,
  );
  final assumptions = SolarSiteResolver.assumptionLines(site, hints);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 40),
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        margin: const pw.EdgeInsets.only(bottom: 14),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: primary, width: 2)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(companyName,
                style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: primary)),
            pw.Text(date,
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
      ),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('$companyName  ·  $companyContact',
              style:
                  const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text('${ctx.pageNumber}/${ctx.pagesCount}',
              style:
                  const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
      build: (ctx) => [
        pw.Text('Propuesta de sistema fotovoltaico',
            style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('${project.customer}   ·   ${project.address}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
        if (project.phone.isNotEmpty)
          pw.Text('Tel: ${project.phone}',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 18),
        pw.Row(children: [
          _kpi('Potencia (kWp)', '${project.kwp.toStringAsFixed(2)} kWp', accent),
          _kpi('Produccion', '${production.annual.round()} kWh/ano', accent),
          _kpi('Paneles', '${project.panels.length}', accent),
          _kpi(
              'Retorno',
              financial.payback >= 0
                  ? '${financial.payback.toStringAsFixed(1)} anos'
                  : 'n/d',
              accent),
        ]),
        pw.SizedBox(height: 20),
        _title('Que incluye tu sistema', primary),
        _table(bom
            .map((b) => [
                  b.category,
                  b.included
                      ? '${b.description} (${b.quantity})'
                      : b.description,
                ])
            .toList()),
        pw.SizedBox(height: 18),
        _title('Resumen tecnico', primary),
        _table([
          ['Modulo', project.module.name],
          ['Potencia por modulo', '${project.module.wp.round()} Wp'],
          ['Cantidad de modulos', '${project.panels.length}'],
          ['Potencia instalada (kWp)', '${project.kwp.toStringAsFixed(2)} kWp'],
          [
            'Inversor propuesto',
            '${inv.name} (${inv.acKw.toStringAsFixed(1)} kW AC)',
          ],
          if (project.system.includeBattery)
            [
              'Bateria',
              project.system.battery?.name ?? 'Incluida',
            ],
          ['Superficies medidas', '${project.facets.length}'],
          ['Area de techo', '${totalArea.toStringAsFixed(1)} m2'],
          ['Area ocupada por modulos', '${usedArea.toStringAsFixed(1)} m2'],
          if (project.targetAreaM2 != null)
            ['Area objetivo', '${project.targetAreaM2!.toStringAsFixed(0)} m2'],
          [
            'Rendimiento especifico',
            '${production.specificYield.round()} kWh/kWp/ano'
          ],
          [
            'Distribucion',
            '${project.panels.length} modulos sobre ${usedArea.toStringAsFixed(1)} m2',
          ],
        ]),
        pw.SizedBox(height: 18),
        _title('Desglose de inversion', primary),
        _table([
          ...breakdown.lines.map((l) => [
                l.detail != null ? '${l.label} (${l.detail})' : l.label,
                '$cur${money(l.amount)}',
              ]),
          ['Total', '$cur${money(breakdown.total)}'],
        ]),
        pw.SizedBox(height: 18),
        _title('Supuestos del calculo', primary),
        _table(assumptions.map((a) {
          final parts = a.split(': ');
          return parts.length > 1 ? [parts.first, parts.sublist(1).join(': ')] : [a, ''];
        }).toList()),
        pw.SizedBox(height: 18),
        _title('Produccion estimada por mes', primary),
        _bars(production.monthly, primary),
        pw.SizedBox(height: 6),
        if (project.annualConsumptionKwh > 0)
          pw.Text(
            'Cubre aproximadamente el '
            '${(production.annual / project.annualConsumptionKwh * 100).round()} % '
            'del consumo anual declarado (${project.annualConsumptionKwh.round()} kWh).',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        pw.SizedBox(height: 18),
        _title('Analisis economico', primary),
        _table([
          ['Inversion total', '$cur${money(financial.capex)}'],
          [
            'Tarifa considerada',
            '$cur${project.finance.tariffPerKwh.toStringAsFixed(2)} / kWh'
          ],
          [
            'Alza tarifaria anual',
            '${(project.finance.escalation * 100).toStringAsFixed(1)} %'
          ],
          ['Ahorro primer ano', '$cur${money(financial.firstYear)}'],
          [
            'Retorno de inversion',
            financial.payback >= 0
                ? '${financial.payback.toStringAsFixed(1)} anos'
                : 'No retorna en el horizonte'
          ],
          [
            'Ahorro a ${project.finance.horizonYears} anos',
            '$cur${money(financial.cumulative)}'
          ],
          ['VPN', '$cur${money(financial.npv)}'],
          [
            'TIR',
            financial.irr != null
                ? '${(financial.irr! * 100).toStringAsFixed(1)} %'
                : 'n/d'
          ],
        ]),
        pw.SizedBox(height: 20),
        pw.Text(
          'kWp = potencia del hardware. kWh/ano = produccion estimada segun '
          'irradiancia regional. Estimacion basada en condiciones declaradas; '
          'la produccion real puede variar por clima, sombreado y habitos.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _title(String text, PdfColor color) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(text.toUpperCase(),
          style: pw.TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: pw.FontWeight.bold,
              color: color)),
    );

pw.Widget _kpi(String label, String value, PdfColor accent) => pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 8),
        padding: const pw.EdgeInsets.symmetric(vertical: 11, horizontal: 9),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border(left: pw.BorderSide(color: accent, width: 3)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 3),
            pw.Text(value,
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

pw.Widget _table(List<List<String>> rows) => pw.Table(
      border: pw.TableBorder.symmetric(
          inside: const pw.BorderSide(color: PdfColors.grey300, width: .5)),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(2),
      },
      children: rows
          .map((r) => pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Text(r[0],
                      style: const pw.TextStyle(
                          fontSize: 9.5, color: PdfColors.grey800)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Text(r[1],
                      style: pw.TextStyle(
                          fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                ),
              ]))
          .toList(),
    );

pw.Widget _bars(List<double> values, PdfColor color) {
  if (values.isEmpty) return pw.SizedBox();
  final maxV = values.reduce((a, b) => a > b ? a : b);
  return pw.SizedBox(
    height: 120,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        final h = maxV > 0 ? (values[i] / maxV) * 88 : 0.0;
        return pw.Expanded(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(values[i].round().toString(),
                  style: const pw.TextStyle(fontSize: 6)),
              pw.SizedBox(height: 2),
              pw.Container(
                height: h,
                margin: const pw.EdgeInsets.symmetric(horizontal: 2),
                color: color,
              ),
              pw.SizedBox(height: 3),
              pw.Text(_months[i], style: const pw.TextStyle(fontSize: 7)),
            ],
          ),
        );
      }),
    ),
  );
}
