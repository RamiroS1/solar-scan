#!/usr/bin/env python3
"""
Convierte OBJ + MTL a .scn, un formato binario compacto que Flutter lee sin
dependencias. Ejecutar cada vez que se exporte un modelo nuevo:

    python3 tools/obj_to_scn.py modelos/*.obj -o assets/models

Formato .scn (little endian):
    magic       4 bytes  'SCN1'
    vertCount   uint32
    positions   float32 * vertCount * 3      (metros, Y arriba)
    partCount   uint32
    por parte:
        nameLen   uint16
        name      utf8
        r,g,b     uint8 * 3      color base lineal * 255
        flags     uint8          bit0 = panel, bit1 = entorno
        panelIdx  int16          -1 si no es panel
        triCount  uint32
        indices   uint32 * triCount * 3
"""
import struct, sys, os, argparse, re

# Un panel es cualquier pieza pv_*. El entorno es lo que se puede ocultar para
# que el cliente vea solo su instalacion.
ENV = re.compile(
    r'grass|asphalt|tree|foliage|bark|lane|street|sidewalk|ground|plot|'
    r'lot_surface|bay_line|aisle|car_|curb|shrub', re.I)

FALLBACK = {
    'ground_grass': (.159, .227, .117), 'stucco_warm': (.791, .760, .694),
    'roof_tile': (.445, .144, .068), 'aluminium': (.323, .366, .412),
    'panel_glass': (.008, .021, .050), 'window_glass': (.024, .042, .063),
    'trim_wood': (.144, .095, .063), 'accent_amber': (.888, .445, .045),
    'stucco_cool': (.485, .527, .552), 'concrete': (.468, .451, .402),
    'asphalt': (.045, .054, .067), 'steel_dark': (.105, .127, .153),
    'car_paint_slate': (.266, .318, .381), 'car_paint_cream': (.687, .644, .552),
    'rubber': (.017, .020, .024), 'bark': (.095, .065, .039),
    'foliage': (.072, .133, .051),
}


def read_mtl(path):
    mats, cur = {}, None
    if not os.path.exists(path):
        return mats
    for line in open(path, encoding='utf-8', errors='ignore'):
        p = line.split()
        if not p:
            continue
        if p[0] == 'newmtl':
            cur = p[1]
        elif p[0] == 'Kd' and cur:
            mats[cur] = (float(p[1]), float(p[2]), float(p[3]))
    return mats


def convert(obj_path, out_dir):
    mtl_path = os.path.splitext(obj_path)[0] + '.mtl'
    mats = read_mtl(mtl_path)

    verts = []
    parts = []
    cur = None
    mat = 'default'
    panel_idx = -1

    for line in open(obj_path, encoding='utf-8', errors='ignore'):
        if line.startswith('v '):
            _, x, y, z = line.split()[:4]
            verts.append((float(x), float(y), float(z)))
        elif line.startswith('o ') or line.startswith('g '):
            name = line[2:].strip()
            # cada pv_frame abre un modulo nuevo; pv_glass hereda su indice
            is_pv = name.startswith('pv_')
            if name in ('pv_frame', 'pv_module'):
                panel_idx += 1
            cur = {'name': name, 'mat': mat, 'tris': [],
                   'pv': is_pv, 'env': bool(ENV.search(name)),
                   'panel': panel_idx if is_pv else -1}
            parts.append(cur)
        elif line.startswith('usemtl'):
            mat = line[7:].strip()
            if cur:
                cur['mat'] = mat
        elif line.startswith('f ') and cur is not None:
            idx = []
            for tok in line.split()[1:]:
                i = int(tok.split('/')[0])
                idx.append(len(verts) + i if i < 0 else i - 1)
            # triangulacion en abanico: los OBJ traen quads
            for k in range(1, len(idx) - 1):
                cur['tris'].append((idx[0], idx[k], idx[k + 1]))

    parts = [p for p in parts if p['tris']]

    out = bytearray()
    out += b'SCN1'
    out += struct.pack('<I', len(verts))
    for v in verts:
        out += struct.pack('<fff', *v)
    out += struct.pack('<I', len(parts))
    for p in parts:
        nb = p['name'].encode('utf-8')
        out += struct.pack('<H', len(nb)) + nb
        c = mats.get(p['mat']) or FALLBACK.get(p['mat'], (.55, .57, .60))
        out += bytes(max(0, min(255, int(ch * 255))) for ch in c)
        out += struct.pack('<B', (1 if p['pv'] else 0) | (2 if p['env'] else 0))
        out += struct.pack('<h', p['panel'])
        out += struct.pack('<I', len(p['tris']))
        for t in p['tris']:
            out += struct.pack('<III', *t)

    os.makedirs(out_dir, exist_ok=True)
    name = os.path.splitext(os.path.basename(obj_path))[0] + '.scn'
    dst = os.path.join(out_dir, name)
    with open(dst, 'wb') as f:
        f.write(out)

    npanels = len({p['panel'] for p in parts if p['pv']} - {-1})
    ntris = sum(len(p['tris']) for p in parts)
    src = os.path.getsize(obj_path)
    print(f'{name:26} {len(out)/1024:7.0f} KB  '
          f'(obj {src/1024:.0f} KB, -{100 - len(out)*100/src:.0f}%)  '
          f'{len(verts)} vert  {ntris} tri  {len(parts)} partes  '
          f'{npanels} paneles')
    return dst


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('inputs', nargs='+')
    ap.add_argument('-o', '--out', default='assets/models')
    a = ap.parse_args()
    for f in a.inputs:
        convert(f, a.out)
