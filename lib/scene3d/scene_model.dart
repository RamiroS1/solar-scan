import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

/// Una pieza de la escena: muro, teja, arbol o modulo fotovoltaico.
class ScenePart {
  final String name;
  final double r, g, b; // color base lineal 0-1
  final bool isPanel;
  final bool isEnv;
  final int panelIndex; // -1 si no es panel
  final bool isGlass;

  const ScenePart({
    required this.name,
    required this.r,
    required this.g,
    required this.b,
    required this.isPanel,
    required this.isEnv,
    required this.panelIndex,
    required this.isGlass,
  });
}

/// Escena 3D leida de un .scn. Todo se aplana en arreglos tipados para que el
/// pintado no genere basura en cada frame.
class SceneModel {
  final Float32List positions; // x,y,z por vertice
  final List<ScenePart> parts;

  final Int32List triA, triB, triC; // indices de vertice
  final Int32List triPart; // a que pieza pertenece cada triangulo
  final Float32List triCentroid; // x,y,z por triangulo

  final int panelCount;
  final double cx, cy, cz, size;

  SceneModel._({
    required this.positions,
    required this.parts,
    required this.triA,
    required this.triB,
    required this.triC,
    required this.triPart,
    required this.triCentroid,
    required this.panelCount,
    required this.cx,
    required this.cy,
    required this.cz,
    required this.size,
  });

  int get triangleCount => triA.length;

  static final Map<String, SceneModel> _cache = {};

  static Future<SceneModel> load(String asset) async {
    final cached = _cache[asset];
    if (cached != null) return cached;
    final data = await rootBundle.load(asset);
    final model = parse(data.buffer.asByteData(
        data.offsetInBytes, data.lengthInBytes));
    _cache[asset] = model;
    return model;
  }

  static SceneModel parse(ByteData d) {
    int o = 0;
    final magic = String.fromCharCodes(
        Uint8List.view(d.buffer, d.offsetInBytes, 4));
    if (magic != 'SCN1') {
      throw FormatException('Formato desconocido: $magic');
    }
    o = 4;

    final vertCount = d.getUint32(o, Endian.little);
    o += 4;
    final positions = Float32List(vertCount * 3);
    for (int i = 0; i < vertCount * 3; i++) {
      positions[i] = d.getFloat32(o, Endian.little);
      o += 4;
    }

    final partCount = d.getUint32(o, Endian.little);
    o += 4;

    final parts = <ScenePart>[];
    final a = <int>[], b = <int>[], c = <int>[], pi = <int>[];
    int panelMax = -1;

    for (int p = 0; p < partCount; p++) {
      final nameLen = d.getUint16(o, Endian.little);
      o += 2;
      final name = String.fromCharCodes(
          Uint8List.view(d.buffer, d.offsetInBytes + o, nameLen));
      o += nameLen;

      final r = d.getUint8(o) / 255.0;
      final g = d.getUint8(o + 1) / 255.0;
      final bl = d.getUint8(o + 2) / 255.0;
      o += 3;

      final flags = d.getUint8(o);
      o += 1;
      final panelIdx = d.getInt16(o, Endian.little);
      o += 2;
      final triCount = d.getUint32(o, Endian.little);
      o += 4;

      parts.add(ScenePart(
        name: name,
        r: r,
        g: g,
        b: bl,
        isPanel: (flags & 1) != 0,
        isEnv: (flags & 2) != 0,
        panelIndex: panelIdx,
        isGlass: name.contains('glass'),
      ));
      if (panelIdx > panelMax) panelMax = panelIdx;

      for (int t = 0; t < triCount; t++) {
        a.add(d.getUint32(o, Endian.little));
        b.add(d.getUint32(o + 4, Endian.little));
        c.add(d.getUint32(o + 8, Endian.little));
        pi.add(p);
        o += 12;
      }
    }

    // centroides y caja envolvente
    final n = a.length;
    final centroid = Float32List(n * 3);
    double minX = 1e9, minY = 1e9, minZ = 1e9;
    double maxX = -1e9, maxY = -1e9, maxZ = -1e9;

    for (int i = 0; i < n; i++) {
      final i0 = a[i] * 3, i1 = b[i] * 3, i2 = c[i] * 3;
      centroid[i * 3] = (positions[i0] + positions[i1] + positions[i2]) / 3;
      centroid[i * 3 + 1] =
          (positions[i0 + 1] + positions[i1 + 1] + positions[i2 + 1]) / 3;
      centroid[i * 3 + 2] =
          (positions[i0 + 2] + positions[i1 + 2] + positions[i2 + 2]) / 3;
    }
    for (int i = 0; i < vertCount; i++) {
      final x = positions[i * 3], y = positions[i * 3 + 1], z = positions[i * 3 + 2];
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (z < minZ) minZ = z;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
      if (z > maxZ) maxZ = z;
    }

    final sx = maxX - minX, sy = maxY - minY, sz = maxZ - minZ;
    final size = [sx, sz, sy * 1.6].reduce((p, q) => p > q ? p : q);

    return SceneModel._(
      positions: positions,
      parts: parts,
      triA: Int32List.fromList(a),
      triB: Int32List.fromList(b),
      triC: Int32List.fromList(c),
      triPart: Int32List.fromList(pi),
      triCentroid: centroid,
      panelCount: panelMax + 1,
      cx: (minX + maxX) / 2,
      cy: (minY + maxY) / 2,
      cz: (minZ + maxZ) / 2,
      size: size <= 0 ? 1 : size,
    );
  }
}

/// Los cuatro arquetipos disponibles.
enum Archetype { casa, edificio, parqueadero, barrio }

extension ArchetypeInfo on Archetype {
  String get asset => switch (this) {
        Archetype.casa => 'assets/models/casa-10-paneles.scn',
        Archetype.edificio => 'assets/models/edificio-solar.scn',
        Archetype.parqueadero => 'assets/models/parqueadero-solar.scn',
        Archetype.barrio => 'assets/models/barrio-solar.scn',
      };

  String get label => switch (this) {
        Archetype.casa => 'Casa',
        Archetype.edificio => 'Edificio',
        Archetype.parqueadero => 'Parqueadero',
        Archetype.barrio => 'Barrio',
      };

  /// Cuantos modulos trae el modelo. Si el diseno pide mas, hay que avisarlo:
  /// hasta que exista el clonado parametrico no se pueden mostrar todos.
  int get maxPanels => switch (this) {
        Archetype.casa => 10,
        Archetype.edificio => 36,
        Archetype.parqueadero => 48,
        Archetype.barrio => 35,
      };
}
