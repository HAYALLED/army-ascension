#!/usr/bin/env python3
"""Army Ascension - procedural environment decor generator (ASSET_PROMPTS_6_ENVIRONMENT).

Usage:  python3 Tools/model_gen/env_decor.py [out_root] [--preview sheet.png]
Default out_root = current dir; files land in Assets/Ingame/Env/<theme>/.
Pure python + numpy + Pillow. Output: .glb (glTF 2.0), Y-up, 1 mesh, 1 material,
palette texture 64x64, flat normals, origin bottom center, no emissive/alpha.
"""
import io
import json
import math
import os
import random
import struct
import sys

import numpy as np
from PIL import Image

# ----------------------------------------------------------------------------
# geometry core
# ----------------------------------------------------------------------------

def hexc(s):
    s = s.lstrip('#')
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def rotm(rot):
    rx, ry, rz = [math.radians(a) for a in rot]
    cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
    Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return Ry @ Rx @ Rz


def xf(pos, rot, v):
    return np.array(pos, float) + rotm(rot) @ np.array(v, float)


def rxz(ox, oz, yaw):
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    return ox * c + oz * s, -ox * s + oz * c


def newell(p):
    n = np.zeros(3)
    for i in range(len(p)):
        a, b = p[i], p[(i + 1) % len(p)]
        n[0] += (a[1] - b[1]) * (a[2] + b[2])
        n[1] += (a[2] - b[2]) * (a[0] + b[0])
        n[2] += (a[0] - b[0]) * (a[1] + b[1])
    return n


def rfr(wb, db, wt, dt, h):
    b = [(-wb / 2, 0, -db / 2), (wb / 2, 0, -db / 2), (wb / 2, 0, db / 2), (-wb / 2, 0, db / 2)]
    if wt <= 1e-9 and dt <= 1e-9:
        a = (0, h, 0)
        return [b] + [[b[i], b[(i + 1) % 4], a] for i in range(4)]
    t = [(-wt / 2, h, -dt / 2), (wt / 2, h, -dt / 2), (wt / 2, h, dt / 2), (-wt / 2, h, dt / 2)]
    return [b, t] + [[b[i], b[(i + 1) % 4], t[(i + 1) % 4], t[i]] for i in range(4)]


def prism_polys(n, rb, rt, h, a0=0.0):
    ang = [math.radians(a0) + 2 * math.pi * i / n for i in range(n)]
    B = [(rb * math.cos(a), 0, rb * math.sin(a)) for a in ang]
    if rt <= 1e-9:
        ap = (0, h, 0)
        return [B] + [[B[i], B[(i + 1) % n], ap] for i in range(n)]
    T = [(rt * math.cos(a), h, rt * math.sin(a)) for a in ang]
    return [B, T] + [[B[i], B[(i + 1) % n], T[(i + 1) % n], T[i]] for i in range(n)]


def tprism_polys(w, h, d):
    a = [(-w / 2, 0, -d / 2), (w / 2, 0, -d / 2), (0, h, -d / 2)]
    b = [(-w / 2, 0, d / 2), (w / 2, 0, d / 2), (0, h, d / 2)]
    return [a, b, [a[0], a[1], b[1], b[0]], [a[1], a[2], b[2], b[1]], [a[2], a[0], b[0], b[2]]]


def cbox_polys(w, h, d, b):
    b = min(b, 0.45 * min(w, h, d))
    if b <= 1e-6:
        return rfr(w, d, w, d, h)
    hh3 = (w / 2, h / 2, d / 2)

    def P(s, ax):
        return np.array([s[i] * hh3[i] if i == ax else s[i] * (hh3[i] - b) for i in range(3)])

    polys = []
    for ax in range(3):
        a1, a2 = [i for i in range(3) if i != ax]
        for sg in (-1, 1):
            quad = []
            for c1, c2 in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                s = [0, 0, 0]
                s[ax], s[a1], s[a2] = sg, c1, c2
                quad.append(P(s, ax))
            polys.append(quad)
    for ax3 in range(3):
        ax1, ax2 = [i for i in range(3) if i != ax3]
        for s1 in (-1, 1):
            for s2 in (-1, 1):
                def pt(s3, ax):
                    s = [0, 0, 0]
                    s[ax1], s[ax2], s[ax3] = s1, s2, s3
                    return P(s, ax)
                polys.append([pt(-1, ax1), pt(-1, ax2), pt(1, ax2), pt(1, ax1)])
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                polys.append([P((sx, sy, sz), 0), P((sx, sy, sz), 1), P((sx, sy, sz), 2)])
    return [[np.array(v) + np.array([0, h / 2, 0]) for v in p] for p in polys]


class Mesh:
    def __init__(self):
        self.T = []
        self.Ci = []
        self.cols = []

    def col(self, c):
        rgb = hexc(c)
        if rgb not in self.cols:
            self.cols.append(rgb)
        return self.cols.index(rgb)

    def add(self, polys, color, pos=(0, 0, 0), rot=(0, 0, 0), sc=(1, 1, 1), cy=False, M=None):
        P = [np.array(p, float) for p in polys]
        allv = np.vstack(P)
        if cy:
            off = (allv[:, 1].max() + allv[:, 1].min()) / 2
            P = [p - np.array([0, off, 0]) for p in P]
        R = rotm(rot) if M is None else M
        S = np.array(sc, float)
        pos = np.array(pos, float)
        P = [(p * S) @ R.T + pos for p in P]
        cen = np.vstack(P).mean(0)
        ci = self.col(color)
        for p in P:
            n = newell(p)
            if np.linalg.norm(n) < 1e-10:
                continue
            if np.dot(n, p.mean(0) - cen) < 0:
                p = p[::-1]
            for i in range(1, len(p) - 1):
                self.T.append((p[0], p[i], p[i + 1]))
                self.Ci.append(ci)

    def box(self, c, w, h, d, **k):
        self.add(rfr(w, d, w, d, h), c, **k)

    def cbox(self, c, w, h, d, b=0.06, **k):
        self.add(cbox_polys(w, h, d, b), c, **k)

    def fr(self, c, wb, db, wt, dt, h, **k):
        self.add(rfr(wb, db, wt, dt, h), c, **k)

    def pr(self, c, n, rb, rt, h, a0=0.0, **k):
        self.add(prism_polys(n, rb, rt, h, a0), c, **k)

    def tp(self, c, w, h, d, **k):
        self.add(tprism_polys(w, h, d), c, **k)

    def beam(self, c, p1, p2, tw, th):
        p1, p2 = np.array(p1, float), np.array(p2, float)
        d = p2 - p1
        L = np.linalg.norm(d)
        dn = d / L
        hint = np.array([0, 1, 0.]) if abs(dn[1]) < 0.95 else np.array([0, 0, 1.])
        side = np.cross(hint, dn)
        side /= np.linalg.norm(side)
        nrm = np.cross(dn, side)
        M = np.stack([dn, nrm, side], axis=1)
        self.add(rfr(L, tw, L, tw, th), c, pos=(p1 + p2) / 2, cy=True, M=M)


def ring(m, color, rx, rz, n, w, h, y=0.0):
    pts = [(rx * math.cos(2 * math.pi * i / n), rz * math.sin(2 * math.pi * i / n)) for i in range(n)]
    for i in range(n):
        a, b = pts[i], pts[(i + 1) % n]
        L = math.hypot(b[0] - a[0], b[1] - a[1]) * 1.18
        yaw = math.degrees(math.atan2(-(b[1] - a[1]), b[0] - a[0]))
        m.box(color, L, h, w, pos=((a[0] + b[0]) / 2, y, (a[1] + b[1]) / 2), rot=(0, yaw, 0))


# ----------------------------------------------------------------------------
# GLB export
# ----------------------------------------------------------------------------

def save(m, path, target=None, axes='xyz', xrange=None):
    T = np.array(m.T, float)
    V = T.reshape(-1, 3)
    bmin, bmax = V.min(0), V.max(0)
    size = bmax - bmin
    s = np.ones(3)
    tgt = list(target) if target else [None] * 3
    if xrange:
        tgt[0] = xrange[1] - xrange[0]
    for i, ax in enumerate('xyz'):
        if ax in axes and tgt[i]:
            s[i] = tgt[i] / size[i]
    V = (V - bmin) * s
    new = size * s
    V[:, 0] -= new[0] / 2
    V[:, 2] -= new[2] / 2
    if xrange:
        V[:, 0] += (xrange[0] + xrange[1]) / 2
    tris = V.reshape(-1, 3, 3)
    nrm = np.cross(tris[:, 1] - tris[:, 0], tris[:, 2] - tris[:, 0])
    ln = np.linalg.norm(nrm, axis=1)
    keep = ln > 1e-12
    tris, nrm, ln = tris[keep], nrm[keep], ln[keep]
    ci = np.array(m.Ci)[keep]
    nrm = nrm / ln[:, None]
    n_t = len(tris)
    assert len(m.cols) <= 64, 'palette overflow'
    pos = tris.reshape(-1, 3).astype(np.float32)
    nor = np.repeat(nrm, 3, axis=0).astype(np.float32)
    uv = np.zeros((n_t * 3, 2), np.float32)
    for k in range(n_t):
        c = ci[k]
        u, v = ((c % 8) + 0.5) / 8, ((c // 8) + 0.5) / 8
        uv[k * 3:k * 3 + 3] = (u, v)
    assert n_t * 3 < 65535
    idx = np.arange(n_t * 3, dtype=np.uint16)
    img = Image.new('RGB', (64, 64), (128, 128, 128))
    px = img.load()
    for c, rgb in enumerate(m.cols):
        for yy in range(8):
            for xx in range(8):
                px[(c % 8) * 8 + xx, (c // 8) * 8 + yy] = rgb
    bio = io.BytesIO()
    img.save(bio, 'PNG')
    png = bio.getvalue()

    def pad(b):
        return b + b'\x00' * ((4 - len(b) % 4) % 4)

    chunks = [pad(pos.tobytes()), pad(nor.tobytes()), pad(uv.tobytes()), pad(idx.tobytes()), pad(png)]
    offs = np.cumsum([0] + [len(c) for c in chunks])
    binb = b''.join(chunks)
    pmin, pmax = pos.min(0).tolist(), pos.max(0).tolist()
    name = os.path.splitext(os.path.basename(path))[0]
    js = {
        'asset': {'version': '2.0', 'generator': 'army-ascension env_decor.py'},
        'scene': 0, 'scenes': [{'nodes': [0]}],
        'nodes': [{'mesh': 0, 'name': name}],
        'meshes': [{'name': name, 'primitives': [{'attributes': {'POSITION': 0, 'NORMAL': 1, 'TEXCOORD_0': 2}, 'indices': 3, 'material': 0}]}],
        'materials': [{'name': 'palette', 'pbrMetallicRoughness': {'baseColorTexture': {'index': 0}, 'metallicFactor': 0.0, 'roughnessFactor': 1.0}, 'doubleSided': False}],
        'textures': [{'source': 0, 'sampler': 0}],
        'samplers': [{'magFilter': 9728, 'minFilter': 9728, 'wrapS': 33071, 'wrapT': 33071}],
        'images': [{'bufferView': 4, 'mimeType': 'image/png'}],
        'accessors': [
            {'bufferView': 0, 'componentType': 5126, 'count': n_t * 3, 'type': 'VEC3', 'min': pmin, 'max': pmax},
            {'bufferView': 1, 'componentType': 5126, 'count': n_t * 3, 'type': 'VEC3'},
            {'bufferView': 2, 'componentType': 5126, 'count': n_t * 3, 'type': 'VEC2'},
            {'bufferView': 3, 'componentType': 5123, 'count': n_t * 3, 'type': 'SCALAR'}],
        'bufferViews': [
            {'buffer': 0, 'byteOffset': int(offs[0]), 'byteLength': pos.nbytes, 'target': 34962},
            {'buffer': 0, 'byteOffset': int(offs[1]), 'byteLength': nor.nbytes, 'target': 34962},
            {'buffer': 0, 'byteOffset': int(offs[2]), 'byteLength': uv.nbytes, 'target': 34962},
            {'buffer': 0, 'byteOffset': int(offs[3]), 'byteLength': idx.nbytes, 'target': 34963},
            {'buffer': 0, 'byteOffset': int(offs[4]), 'byteLength': len(png)}],
        'buffers': [{'byteLength': len(binb)}],
    }
    jb = json.dumps(js, separators=(',', ':')).encode()
    jb += b' ' * ((4 - len(jb) % 4) % 4)
    total = 12 + 8 + len(jb) + 8 + len(binb)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(struct.pack('<4sII', b'glTF', 2, total))
        f.write(struct.pack('<I4s', len(jb), b'JSON') + jb)
        f.write(struct.pack('<I4s', len(binb), b'BIN\x00') + binb)
    col = np.array([m.cols[c] for c in ci], float) / 255
    return {'tris': n_t, 'size': (pmax[0] - pmin[0], pmax[1] - pmin[1], pmax[2] - pmin[2]),
            'min': pmin, 'max': pmax, 'V': tris, 'N': nrm, 'C': col, 'bytes': total, 'colors': len(m.cols)}


# ----------------------------------------------------------------------------
# ROUND 1 - meadow
# ----------------------------------------------------------------------------

def r1_tree_round():
    m = Mesh()
    m.cbox('#7A5232', 0.75, 1.5, 0.75, 0.08)
    m.cbox('#4E8A3E', 3.1, 1.15, 3.1, 0.4, pos=(0, 1.1, 0))
    m.cbox('#6FB04F', 2.6, 1.15, 2.6, 0.4, pos=(0, 2.0, 0))
    m.cbox('#4E8A3E', 1.8, 1.1, 1.8, 0.35, pos=(0, 3.1, 0))
    return m


def r1_tree_pine():
    m = Mesh()
    m.cbox('#7A5232', 0.55, 1.3, 0.55, 0.06)
    for w, y, c in ((2.6, 0.9, '#3F7A39'), (2.1, 2.1, '#3F7A39'), (1.6, 3.3, '#5C9A47'), (1.1, 4.5, '#5C9A47')):
        m.fr(c, w, w, 0, 0, 1.5, pos=(0, y, 0))
    return m


def r1_bush():
    m = Mesh()
    m.cbox('#5E9C46', 1.0, 0.75, 1.0, 0.25, pos=(-0.2, 0, -0.1))
    m.cbox('#6FB04F', 0.95, 0.9, 0.95, 0.25, pos=(0.3, 0, 0.05))
    m.cbox('#5E9C46', 0.8, 0.6, 0.8, 0.2, pos=(0.0, 0, 0.45))
    m.box('#C8452E', 0.14, 0.14, 0.14, pos=(-0.2, 0.3, 0.86))
    m.box('#C8452E', 0.14, 0.14, 0.14, pos=(0.22, 0.4, 0.86))
    return m


def r1_rock_small():
    m = Mesh()
    m.cbox('#8E9097', 1.0, 0.6, 0.9, 0.15, pos=(-0.1, 0, 0), rot=(0, 10, 0))
    m.cbox('#8E9097', 0.7, 0.55, 0.7, 0.14, pos=(0.4, 0, 0.2), rot=(0, -20, 0))
    m.cbox('#A3A5AB', 0.7, 0.4, 0.6, 0.14, pos=(-0.05, 0.5, 0), rot=(0, 25, 0))
    return m


def r1_rock_cluster():
    m = Mesh()
    m.cbox('#8E9097', 1.6, 1.3, 1.4, 0.25, pos=(-0.6, 0, 0), rot=(0, 15, 0))
    m.cbox('#6FB04F', 0.95, 0.22, 0.85, 0.08, pos=(-0.6, 1.2, 0), rot=(0, 15, 0))
    m.cbox('#777A82', 1.1, 0.9, 1.0, 0.2, pos=(0.85, 0, 0.45), rot=(0, -25, 0))
    m.cbox('#8E9097', 0.95, 0.7, 0.85, 0.18, pos=(0.1, 0, -0.85), rot=(0, 30, 0))
    m.cbox('#777A82', 0.7, 0.5, 0.7, 0.14, pos=(0.35, 0, 1.0), rot=(0, 10, 0))
    return m


def r1_flower_patch():
    m = Mesh()
    m.box('#6FB04F', 2.0, 0.05, 2.0)
    spots = [(-0.7, -0.7), (0.1, -0.8), (0.75, -0.55), (-0.3, -0.2), (0.5, 0.0), (-0.8, 0.3), (0.0, 0.45), (0.8, 0.7), (-0.4, 0.85), (0.35, 0.95)]
    cols = ['#E9C44C', '#F6F2E8', '#E8A0B4']
    for i, (x, z) in enumerate(spots):
        h = 0.2 if i % 2 else 0.15
        m.box(cols[i % 3], 0.14, h, 0.14, pos=(x, 0.05, z))
    return m


def r1_hay_bale():
    m = Mesh()
    m.cbox('#D9B85A', 1.26, 1.2, 1.26, 0.12)
    for y in (0.28, 0.76):
        m.box('#8C6A2E', 1.3, 0.14, 1.3, pos=(0, y, 0))
    return m


def r1_fence():
    m = Mesh()
    for x in (-1.36, 1.36):
        m.cbox('#A9773F', 0.26, 0.9, 0.26, 0.04, pos=(x, 0, 0))
        m.box('#7A5232', 0.3, 0.1, 0.3, pos=(x, 0.9, 0))
    for y in (0.28, 0.6):
        m.box('#A9773F', 2.8, 0.18, 0.14, pos=(0, y, 0))
    return m


def r1_sandbag_wall():
    m = Mesh()
    rows = [(0.0, [-0.975, -0.325, 0.325, 0.975]), (0.31, [-0.65, 0.0, 0.65]), (0.62, [-0.325, 0.325])]
    for r, (y, xs) in enumerate(rows):
        for i, x in enumerate(xs):
            m.cbox('#C9B78A' if (i + r) % 2 == 0 else '#B39F72', 0.62, 0.32, 0.85, 0.1, pos=(x, y, 0))
    return m


def _crate(m, x, y, z, w, h, d, yaw, stripe=False):
    m.cbox('#8A6A3C', w, h, d, 0.05, pos=(x, y, z), rot=(0, yaw, 0))
    for sx in (-1, 1):
        for sz in (-1, 1):
            ox, oz = rxz(sx * (w / 2 - 0.02), sz * (d / 2 - 0.02), yaw)
            m.box('#4A4F57', 0.12, h, 0.12, pos=(x + ox, y, z + oz), rot=(0, yaw, 0))
    if stripe:
        m.box('#E9C44C', w + 0.04, 0.14, d + 0.04, pos=(x, y + h * 0.42, z), rot=(0, yaw, 0))


def r1_crate_stack():
    m = Mesh()
    _crate(m, -0.45, 0, 0, 0.9, 0.85, 1.3, 0)
    _crate(m, 0.45, 0, 0, 0.9, 0.85, 1.3, 0)
    _crate(m, 0, 0.85, 0, 1.0, 0.85, 1.0, 15, stripe=True)
    return m


def r1_army_tent():
    m = Mesh()
    m.cbox('#7C8B4A', 3.4, 0.9, 3.6, 0.05)
    m.tp('#8E9D58', 3.6, 1.7, 3.6, pos=(0, 0.9, 0))
    for z in (-1.75, 1.75):
        m.box('#7A5232', 0.16, 0.16, 0.5, pos=(0, 2.42, z))
    m.box('#2F3320', 1.0, 1.4, 0.08, pos=(0, 0, 1.82))
    return m


def r1_watchtower():
    m = Mesh()
    C = '#A9773F'
    for sx in (-1, 1):
        for sz in (-1, 1):
            m.fr(C, 0.38, 0.38, 0.28, 0.28, 4.05, pos=(sx * 0.9, 0, sz * 0.9))
    for y in (1.4, 2.8):
        for s in (-1, 1):
            m.beam(C, (-0.9, y, s * 0.9), (0.9, y, s * 0.9), 0.16, 0.16)
            m.beam(C, (s * 0.9, y, -0.9), (s * 0.9, y, 0.9), 0.16, 0.16)
    for s in (-1, 1):
        m.beam(C, (-0.9, 1.4, s * 0.9), (0.9, 2.8, s * 0.9), 0.14, 0.14)
        m.beam(C, (s * 0.9, 1.4, -0.9), (s * 0.9, 2.8, 0.9), 0.14, 0.14)
    m.cbox(C, 2.4, 0.25, 2.4, 0.04, pos=(0, 4.0, 0))
    for s in (-1, 1):
        m.box(C, 2.4, 0.35, 0.14, pos=(0, 4.25, s * 1.13))
        m.box(C, 0.14, 0.35, 2.12, pos=(s * 1.13, 4.25, 0))
    for sx in (-1, 1):
        for sz in (-1, 1):
            m.box(C, 0.16, 1.0, 0.16, pos=(sx * 1.05, 4.25, sz * 1.05))
    m.fr('#6B4A2B', 2.4, 2.4, 0, 0, 0.8, pos=(0, 5.25, 0))
    m.box('#7A5232', 0.1, 0.45, 0.1, pos=(0, 6.05, 0))
    m.box('#C8452E', 0.45, 0.22, 0.05, pos=(0.27, 6.28, 0))
    return m


def r1_windmill():
    m = Mesh()
    m.fr('#E3D9BC', 2.6, 2.6, 1.7, 1.7, 4.8)
    m.fr('#7A5232', 2.0, 2.0, 0, 0, 1.2, pos=(0, 4.8, 0))
    m.box('#6B4A2B', 0.7, 1.1, 0.1, pos=(0, 0, 1.31))
    m.box('#7A5232', 0.6, 0.6, 0.7, pos=(0, 5.175, 1.2))
    B = '#A9773F'
    m.box(B, 0.55, 1.5, 0.12, pos=(0, 6.0, 1.56))
    m.box(B, 0.55, 1.5, 0.12, pos=(0, 4.0, 1.56))
    m.box(B, 1.5, 0.55, 0.12, pos=(-1.0, 5.475, 1.56))
    m.box(B, 1.5, 0.55, 0.12, pos=(1.0, 5.475, 1.56))
    return m


# ----------------------------------------------------------------------------
# ROUND 2 - tundra
# ----------------------------------------------------------------------------

def _snow_pine(m, tiers, th, trunk_h):
    m.cbox('#6B4A33', 0.5, trunk_h, 0.5, 0.05)
    for w, y in tiers:
        m.fr('#3E6B5C', w, w, 0, 0, th, pos=(0, y, 0))
        m.fr('#F2F7FB', w * 0.55 * 1.07, w * 0.55 * 1.07, 0, 0, th * 0.55 + 0.06, pos=(0, y + th * 0.45, 0))


def r2_pine_snow_tall():
    m = Mesh()
    _snow_pine(m, [(2.8, 0.8), (2.3, 2.0), (1.8, 3.2), (1.3, 4.4)], 1.8, 1.2)
    return m


def r2_pine_snow_small():
    m = Mesh()
    _snow_pine(m, [(1.8, 0.5), (1.4, 1.35), (1.0, 2.2)], 1.3, 0.8)
    return m


def r2_dead_tree():
    m = Mesh()
    m.fr('#6B4A33', 0.7, 0.7, 0.4, 0.4, 3.4)
    for p1, p2 in (((0, 1.5, 0), (0.95, 2.5, 0.3)), ((0, 2.2, 0), (-0.95, 3.2, -0.2)), ((0, 2.8, 0), (0.3, 3.75, -0.5))):
        m.beam('#6B4A33', p1, p2, 0.26, 0.26)
        mid = [(a + b) / 2 for a, b in zip(p1, p2)]
        m.cbox('#F2F7FB', 0.42, 0.2, 0.42, 0.06, pos=(mid[0], mid[1] + 0.12, mid[2]))
    m.cbox('#F2F7FB', 0.5, 0.2, 0.5, 0.06, pos=(0, 3.35, 0))
    return m


def r2_snow_mound():
    m = Mesh()
    m.cbox('#F2F7FB', 1.6, 0.8, 1.5, 0.3, pos=(-0.4, 0, 0))
    m.cbox('#DCE9F3', 1.3, 0.7, 1.2, 0.28, pos=(0.7, 0, 0.35))
    m.cbox('#F2F7FB', 1.0, 0.5, 1.0, 0.2, pos=(0.1, 0, -0.7))
    m.cbox('#7C8A9A', 0.4, 0.35, 0.4, 0.08, pos=(-1.0, 0, 0.7), rot=(0, 20, 0))
    return m


def _crystal(m, body, tip, r, h, tipl, pos, rot=(0, 0, 0)):
    m.pr(body, 6, r, r, h, pos=pos, rot=rot)
    m.pr(tip, 6, r, 0, tipl, pos=xf(pos, rot, (0, h, 0)), rot=rot)


def r2_ice_crystal_cluster():
    m = Mesh()
    m.cbox('#F2F7FB', 1.9, 0.3, 1.9, 0.1)
    specs = [(0.0, 0.0, 0.5, 1.5, 0.7, '#6BB5DE', (0, 0, 0)), (0.65, 0.35, 0.36, 1.0, 0.5, '#3F86B8', (0, 0, -10)),
             (-0.6, 0.3, 0.38, 0.9, 0.5, '#6BB5DE', (0, 0, 12)), (-0.1, -0.65, 0.34, 0.8, 0.45, '#3F86B8', (-10, 0, 0)),
             (0.35, -0.55, 0.3, 0.6, 0.4, '#6BB5DE', (10, 0, 5))]
    for x, z, r, h, t, c, rot in specs:
        _crystal(m, c, '#9ED3EE', r, h, t, (x, 0.2, z), rot)
    return m


def r2_ice_boulder():
    m = Mesh()
    m.cbox('#7C8A9A', 1.5, 0.75, 1.3, 0.2, rot=(0, 8, 0))
    m.cbox('#9ED3EE', 1.3, 0.4, 1.1, 0.14, pos=(0, 0.6, 0), rot=(0, 8, 0))
    m.cbox('#F2F7FB', 0.9, 0.3, 0.8, 0.1, pos=(0, 0.95, 0), rot=(0, 8, 0))
    return m


def r2_icicle_rock_arch():
    m = Mesh()
    S = '#7C8A9A'
    for s in (-1, 1):
        m.cbox(S, 1.75, 3.8, 2.4, 0.3, pos=(s * 2.125, 0, 0))
    m.cbox(S, 6.0, 1.1, 2.4, 0.3, pos=(0, 3.6, 0))
    m.cbox('#F2F7FB', 5.4, 0.3, 2.0, 0.1, pos=(0, 4.7, 0))
    for i, x in enumerate((-1.0, -0.4, 0.15, 0.7, 1.1)):
        m.fr('#9ED3EE', 0.4, 0.4, 0, 0, 0.7 if i % 2 == 0 else 0.55, pos=(x, 3.7, 0.15 * (-1) ** i), rot=(180, 0, 0))
    return m


def r2_frozen_pond():
    m = Mesh()
    m.pr('#F2F7FB', 10, 1.0, 1.0, 0.05, a0=18, sc=(2.15, 1, 1.75))
    m.pr('#8CCBEA', 10, 1.0, 1.0, 0.06, a0=18, sc=(1.9, 1, 1.5))
    for x, z, w, yaw in ((-0.5, -0.2, 1.3, 20), (0.7, 0.3, 1.0, -35), (0.1, 0.8, 0.9, 70), (-0.9, 0.6, 0.7, -10)):
        m.box('#C9E8F6', w, 0.08, 0.12, pos=(x, 0.0, z), rot=(0, yaw, 0))
    return m


def r2_igloo():
    m = Mesh()
    R = [1.7, 1.55, 1.25, 0.85, 0.4]
    hs = 0.44
    for i in range(4):
        m.pr('#F2F7FB' if i % 2 == 0 else '#DCE9F3', 8, R[i], R[i + 1], hs, a0=22.5, pos=(0, hs * i, 0))
    m.pr('#F2F7FB', 8, 0.45, 0.3, 0.44, a0=22.5, pos=(0, hs * 4, 0))
    m.cbox('#DCE9F3', 1.2, 1.05, 0.9, 0.12, pos=(0, 0, 1.25))
    m.box('#2E4458', 0.65, 0.75, 0.06, pos=(0, 0, 1.7))
    return m


def r2_snowman():
    m = Mesh()
    m.cbox('#F2F7FB', 1.2, 0.7, 1.2, 0.3)
    m.cbox('#F2F7FB', 0.9, 0.55, 0.9, 0.22, pos=(0, 0.6, 0))
    m.cbox('#F2F7FB', 0.65, 0.5, 0.65, 0.18, pos=(0, 1.1, 0))
    m.box('#C8452E', 0.78, 0.12, 0.78, pos=(0, 1.04, 0))
    m.box('#C8452E', 0.16, 0.4, 0.1, pos=(0.2, 0.7, 0.4))
    m.box('#E8943A', 0.1, 0.1, 0.25, pos=(0, 1.32, 0.4))
    for y in (0.78, 0.55):
        m.box('#2B2F36', 0.08, 0.08, 0.06, pos=(0, y, 0.45))
    return m


def r2_log_cabin():
    m = Mesh()
    for i in range(5):
        c = '#6B4A33' if i % 2 == 0 else '#7E5A3E'
        if i % 2 == 0:
            m.cbox(c, 4.3, 0.34, 3.2, 0.06, pos=(0, i * 0.34, 0))
        else:
            m.cbox(c, 3.9, 0.34, 3.6, 0.06, pos=(0, i * 0.34, 0))
    m.tp('#6B4A33', 4.1, 1.7, 3.8, pos=(0, 1.7, 0))
    m.tp('#F2F7FB', 4.5, 1.9, 3.4, pos=(0, 1.72, 0))
    m.box('#7C8A9A', 0.6, 1.7, 0.6, pos=(1.2, 1.7, -0.7))
    m.box('#45301F', 0.8, 1.2, 0.08, pos=(0, 0, 1.82))
    for s in (-1, 1):
        m.box('#E8943A', 0.55, 0.5, 0.06, pos=(s * 1.3, 0.75, 1.82))
    return m


def r2_lamp_post():
    m = Mesh()
    m.cbox('#4A4F57', 0.6, 0.3, 0.6, 0.05)
    m.box('#4A4F57', 0.22, 2.3, 0.22, pos=(0, 0.3, 0))
    m.cbox('#F1C75B', 0.5, 0.5, 0.5, 0.05, pos=(0, 2.55, 0))
    m.box('#4A4F57', 0.56, 0.08, 0.56, pos=(0, 2.52, 0))
    m.cbox('#F2F7FB', 0.6, 0.15, 0.6, 0.04, pos=(0, 3.05, 0))
    return m


def r2_broken_sled():
    m = Mesh()
    W = '#8A6A3C'
    for z in (-0.35, 0.35):
        m.cbox(W, 1.7, 0.18, 0.16, 0.04, pos=(-0.15, 0, z))
        m.beam(W, (0.6, 0.09, z), (1.05, 0.4, z), 0.15, 0.15)
    for x in (-0.55, 0.1, 0.65):
        m.box(W, 0.45, 0.1, 1.0, pos=(x, 0.18, 0), rot=(0, 0, 0) if x < 0.5 else (0, 14, 6))
    m.box(W, 0.12, 0.62, 0.85, pos=(-0.95, 0.28, 0), rot=(0, 0, -10))
    m.cbox('#F2F7FB', 0.5, 0.14, 0.5, 0.05, pos=(-0.35, 0.28, 0.15))
    m.cbox('#F2F7FB', 0.4, 0.12, 0.45, 0.05, pos=(0.3, 0.28, -0.2))
    return m


# ----------------------------------------------------------------------------
# ROUND 3 - lava foundry
# ----------------------------------------------------------------------------

def r3_basalt_rock():
    m = Mesh()
    m.cbox('#4A3C45', 1.2, 1.1, 1.1, 0.2, pos=(-0.2, 0, 0), rot=(0, 12, 0))
    m.cbox('#2E252C', 0.9, 0.8, 0.9, 0.18, pos=(0.5, 0, 0.3), rot=(0, -20, 0))
    m.cbox('#4A3C45', 0.8, 0.6, 0.8, 0.15, pos=(0.1, 0.8, -0.1), rot=(0, 30, 0))
    m.box('#FF7A1E', 0.5, 0.1, 0.06, pos=(-0.25, 0.45, 0.6))
    return m


def r3_basalt_columns():
    m = Mesh()
    hs = [4.5, 3.4, 2.6, 3.8, 2.0, 3.0, 2.4]
    poss = [(0, 0)] + [(1.08 * math.cos(math.radians(30 + 60 * k)), 1.08 * math.sin(math.radians(30 + 60 * k))) for k in range(6)]
    for (x, z), h in zip(poss, hs):
        m.pr('#4A3C45', 6, 0.62, 0.62, h - 0.15, pos=(x, 0, z))
        m.pr('#6B5359', 6, 0.62, 0.62, 0.15, pos=(x, h - 0.15, z))
    return m


def r3_lava_pool():
    m = Mesh()
    m.pr('#FF7A1E', 12, 1, 1, 0.06, sc=(1.95, 1, 1.5))
    m.pr('#FFC83D', 8, 1, 1, 0.08, sc=(0.9, 1, 0.62), a0=22.5)
    ring(m, '#2E252C', 2.0, 1.55, 12, 0.45, 0.25)
    return m


def r3_lava_cracks():
    m = Mesh()
    m.box('#3B2F36', 3.0, 0.04, 3.0)
    paths = [[(-1.3, -1.3), (-0.6, -0.5), (-0.8, 0.3), (0.0, 0.9), (0.4, 1.4)],
             [(1.35, -1.2), (0.7, -0.6), (0.9, 0.1), (1.35, 0.7)],
             [(-1.4, 0.8), (-0.9, 1.1), (-0.7, 1.4)],
             [(0.2, -1.4), (0.1, -0.7), (-0.1, -0.2)],
             [(0.6, 0.6), (1.0, 1.0), (0.9, 1.4)]]
    for pth in paths:
        for a, b in zip(pth, pth[1:]):
            m.beam('#FF7A1E', (a[0], 0.03, a[1]), (b[0], 0.03, b[1]), 0.2, 0.06)
    return m


def r3_charred_tree():
    m = Mesh()
    C = '#2E252C'
    m.fr(C, 0.7, 0.7, 0.45, 0.45, 3.0)
    for p1, p2 in (((0, 1.3, 0), (0.8, 2.1, 0.2)), ((0, 2.0, 0), (-0.8, 2.8, -0.2)), ((0, 2.5, 0), (0.15, 3.3, -0.6))):
        m.beam(C, p1, p2, 0.24, 0.24)
        m.box('#C23B22', 0.16, 0.16, 0.16, pos=(p2[0], p2[1] - 0.06, p2[2]))
    m.box('#C23B22', 0.3, 0.16, 0.3, pos=(0, 3.0, 0))
    m.box('#8A8590', 0.34, 0.5, 0.06, pos=(0, 0.5, 0.33))
    m.box('#8A8590', 0.06, 0.4, 0.34, pos=(0.35, 1.3, 0))
    return m


def r3_ember_crystal():
    m = Mesh()
    m.cbox('#4A3C45', 1.5, 0.3, 1.5, 0.08)
    specs = [(0.0, 0.0, 0.34, 1.35, 0.5, (0, 0, 0)), (0.5, 0.3, 0.27, 0.95, 0.4, (0, 0, -10)),
             (-0.45, 0.25, 0.27, 0.8, 0.38, (0, 0, 12)), (0.0, -0.5, 0.24, 0.65, 0.35, (-12, 0, 0))]
    for x, z, r, h, t, rot in specs:
        _crystal(m, '#C23B22', '#FF7A1E', r, h, t, (x, 0.2, z), rot)
    return m


def r3_mini_volcano():
    m = Mesh()
    R = [4.9, 4.0, 3.1, 2.2, 1.5]
    th = 1.85
    for i in range(4):
        m.pr('#4A3C45' if i % 2 == 0 else '#3A2F38', 8, R[i], R[i + 1], th, a0=22.5, pos=(0, th * i, 0))
    top = th * 4
    for k in range(4):
        a = math.radians(22.5 + 90 * k)
        m.beam('#6B5359', (R[0] * math.cos(a), 0.1, R[0] * math.sin(a)), (R[4] * math.cos(a), top, R[4] * math.sin(a)), 0.45, 0.3)
    m.pr('#FF7A1E', 8, 1.25, 1.25, 0.12, a0=22.5, pos=(0, top, 0))
    ring(m, '#2E252C', 1.35, 1.35, 8, 0.4, 0.4, y=top)
    ap = math.cos(math.radians(22.5))
    for f, w, c, off in ((-0.25, 0.6, '#FF7A1E', 0.07), (0.22, 0.5, '#FF7A1E', 0.07), (0.22, 0.22, '#FFC83D', 0.12)):
        for i in range(4):
            m.beam(c, (f * R[i], th * i, R[i] * ap + off), (f * R[i + 1], th * (i + 1), R[i + 1] * ap + off), w, 0.14)
    return m


def r3_smokestack():
    m = Mesh()
    H = 7.4
    wb, wt = 2.4, 1.5

    def wid(y):
        return wb + (wt - wb) * y / H
    m.fr('#8A4B2F', wb, wb, wt, wt, H)
    for y in (2.2, 4.6):
        m.box('#5C6270', wid(y + 0.25) + 0.14, 0.5, wid(y + 0.25) + 0.14, pos=(0, y, 0))
    m.cbox('#2E252C', 2.0, 0.55, 2.0, 0.08, pos=(0, H, 0))
    for s in (-1, 1):
        m.box('#5C6270', 0.14, 6.0, 0.14, pos=(s * 0.28, 0.6, wid(3.0) / 2 + 0.08))
    for k in range(8):
        y = 0.8 + 0.75 * k
        m.box('#5C6270', 0.62, 0.13, 0.14, pos=(0, y, wid(y) / 2 + 0.08))
    return m


def r3_gear_large():
    m = Mesh()
    m.cbox('#3E434E', 1.5, 0.28, 0.8, 0.05)
    cy = 1.7
    m.pr('#5C6270', 16, 1.15, 1.15, 0.6, rot=(90, 0, 0), pos=(0, cy, 0), cy=True)
    for k in range(10):
        a = 2 * math.pi * k / 10
        m.box('#5C6270', 0.5, 0.42, 0.6, pos=(1.2 * math.cos(a), cy + 1.2 * math.sin(a), 0), rot=(0, 0, math.degrees(a)), cy=True)
    m.box('#3E434E', 0.7, 0.7, 0.8, pos=(0, cy, 0), cy=True)
    for x, y in ((0.7, 0.5), (-0.6, -0.55), (-0.25, 0.8), (0.4, -0.7)):
        m.box('#8A4B2F', 0.4, 0.3, 0.05, pos=(x, cy + y, 0.3), cy=True)
    return m


def r3_anvil():
    m = Mesh()
    m.cbox('#6B4A33', 0.7, 0.4, 0.6, 0.06)
    m.cbox('#3E434E', 0.5, 0.35, 0.5, 0.05, pos=(-0.1, 0.4, 0))
    m.cbox('#3E434E', 1.0, 0.32, 0.7, 0.06, pos=(-0.1, 0.75, 0))
    m.fr('#3E434E', 0.32, 0.7, 0.14, 0.25, 0.6, pos=(0.4, 0.91, 0), rot=(0, 0, -90), cy=True)
    m.box('#6B7280', 1.0, 0.06, 0.7, pos=(-0.1, 1.07, 0))
    return m


def r3_furnace():
    m = Mesh()
    m.cbox('#8A4B2F', 3.4, 2.6, 3.0, 0.1)
    for y in (0.15, 2.0):
        m.box('#5C6270', 3.5, 0.25, 3.1, pos=(0, y, 0))
    m.cbox('#8A4B2F', 1.0, 0.9, 1.0, 0.06, pos=(-0.8, 2.55, -0.5))
    m.box('#2E252C', 1.2, 0.2, 1.2, pos=(-0.8, 3.4, -0.5))
    m.box('#5C6270', 1.8, 1.25, 0.06, pos=(0, 0.5, 1.5))
    m.box('#FF7A1E', 1.5, 1.05, 0.06, pos=(0, 0.6, 1.56))
    m.box('#FFC83D', 0.8, 0.55, 0.06, pos=(0, 0.75, 1.62))
    return m


def r3_pipe_run():
    m = Mesh()
    S, RU = '#5C6270', '#8A4B2F'
    for z in (-0.2, 0.2):
        m.pr(S, 8, 0.22, 0.22, 3.6, rot=(0, 0, -90), pos=(-0.2, 0.28, z), cy=True)
        for x in (-1.7, 1.5):
            m.pr(RU, 8, 0.29, 0.29, 0.18, rot=(0, 0, -90), pos=(x, 0.28, z), cy=True)
    m.cbox(S, 0.5, 0.5, 0.5, 0.08, pos=(1.5, 0.0, -0.2))
    m.pr(S, 8, 0.22, 0.22, 0.9, pos=(1.5, 0.4, -0.2))
    m.pr(RU, 8, 0.29, 0.29, 0.15, pos=(1.5, 1.2, -0.2))
    m.box(S, 0.12, 0.3, 0.12, pos=(-0.3, 0.5, 0.2))
    m.pr('#C23B22', 8, 0.3, 0.3, 0.1, pos=(-0.3, 0.8, 0.2))
    return m


def r3_scrap_pile():
    m = Mesh()
    m.cbox('#5C6270', 2.2, 0.22, 1.7, 0.04, rot=(0, 10, 0))
    m.cbox('#8A4B2F', 1.8, 0.22, 1.5, 0.04, pos=(0, 0.22, 0), rot=(0, -20, 0))
    m.cbox('#3E434E', 1.4, 0.2, 1.2, 0.04, pos=(0, 0.44, 0), rot=(0, 35, 0))
    m.pr('#8A4B2F', 8, 0.4, 0.4, 0.9, pos=(0.85, 0.15, 0.45))
    m.pr('#3E434E', 8, 0.42, 0.42, 0.1, pos=(0.85, 1.05, 0.45))
    m.pr('#5C6270', 12, 0.45, 0.45, 0.16, pos=(-0.55, 0.62, 0.45), rot=(-35, 0, 0))
    for k in range(6):
        a = 2 * math.pi * k / 6
        m.box('#5C6270', 0.22, 0.16, 0.22, pos=xf((-0.55, 0.62, 0.45), (-35, 0, 0), (0.5 * math.cos(a), 0.08, 0.5 * math.sin(a))), rot=(-35, 0, 0))
    m.beam('#3E434E', (-1.1, 0.5, -0.6), (0.9, 1.3, 0.1), 0.26, 0.26)
    m.beam('#8A4B2F', (-0.9, 0.9, 0.5), (0.7, 0.55, -0.7), 0.24, 0.24)
    return m


# ----------------------------------------------------------------------------
# verges and backdrops
# ----------------------------------------------------------------------------

def _verge(slab, edge, details):
    m = Mesh()
    m.box(edge, 0.5, 0.14, 10.0, pos=(7.45, 0, 0))
    m.box(slab, 5.5, 0.14, 10.0, pos=(10.45, 0, 0))
    for c, x, z, w, h, d, yaw in details:
        m.box(c, w, h, d, pos=(x, 0.14, z), rot=(0, yaw, 0))
    return m


def verge_r1():
    det = []
    for i, (x, z) in enumerate([(8.4, -4.0), (9.6, -2.3), (11.2, -0.6), (8.8, 1.4), (12.2, 2.4), (10.0, 3.9), (12.6, -3.4), (8.3, 4.3)]):
        det.append(('#4E8A3E', x, z, 0.24, 0.06, 0.24, i * 17))
    for i, (x, z) in enumerate([(9.0, -3.3), (11.8, -1.8), (9.5, 0.2), (12.4, 0.9), (10.7, 2.5), (8.7, 3.0)]):
        det.append(('#8E9097', x, z, 0.2, 0.05, 0.16, i * 31))
    return _verge('#6FB04F', '#B39F72', det)


def verge_r2():
    det = []
    for i, (x, z, w) in enumerate([(8.5, -3.8, 0.9), (10.5, -1.6, 0.7), (12.2, 0.4, 1.0), (9.2, 2.2, 0.8), (11.3, 3.8, 0.7)]):
        det.append(('#DCE9F3', x, z, w, 0.06, w * 0.8, i * 23))
    return _verge('#F2F7FB', '#C9D6E2', det)


def verge_r3():
    det = []
    for i, (x, z) in enumerate([(8.6, -3.6), (10.2, -1.4), (11.9, 0.3), (9.4, 1.9), (12.3, 3.2), (10.6, -4.0)]):
        det.append(('#FF7A1E', x, z, 0.7, 0.05, 0.14, i * 41))
    return _verge('#3B2F36', '#8A8590', det)


def _mountains(kind):
    m = Mesh()
    rng = random.Random({'ice': 11, 'lava': 23}[kind])
    x = -125.0
    idx = 0
    while x < 125:
        w = rng.uniform(22, 36)
        h = rng.uniform(16, 38)
        d = rng.uniform(8, 11)
        cx = x + w / 2
        if kind == 'ice':
            body = ['#6BB5DE', '#9ED3EE'][idx % 2]
            mid = '#9ED3EE'
            cap = '#F2F7FB'
        else:
            body = ['#4A3C45', '#2E252C'][idx % 2]
            mid = '#4A3C45'
            cap = '#2E252C'
        h1, h2, h3 = h * 0.4, h * 0.35, h * 0.25
        m.fr(body, w, d, w * 0.7, d * 0.7, h1, pos=(cx, 0, 0))
        m.fr(mid, w * 0.7, d * 0.7, w * 0.42, d * 0.42, h2, pos=(cx, h1, 0))
        if kind == 'ice':
            m.fr(cap, w * 0.42, d * 0.42, 0, 0, h3, pos=(cx, h1 + h2, 0))
        else:
            m.fr(cap, w * 0.42, d * 0.42, w * 0.3, d * 0.3, h3, pos=(cx, h1 + h2, 0))
            if idx % 4 == 2:
                m.box('#FF7A1E', w * 0.26, 0.5, d * 0.26, pos=(cx, h1 + h2 + h3, 0))
                m.beam('#FF7A1E', (cx, h1 + h2 + h3, d * 0.2), (cx + 1.0, h1 * 0.6, d * 0.36 + 0.3), 1.2, 0.4)
        idx += 1
        x += w * rng.uniform(0.62, 0.8)
    if kind == 'ice':
        for _ in range(26):
            px = rng.uniform(-120, 120)
            pz = rng.uniform(3.0, 6.0)
            s = rng.uniform(2.0, 3.2)
            m.fr('#3E6B5C', s, s, 0, 0, s * 1.5, pos=(px, 0, pz))
            m.fr('#3E6B5C', s * 0.7, s * 0.7, 0, 0, s * 1.2, pos=(px, s * 0.9, pz))
    return m


# ----------------------------------------------------------------------------
# registry
# ----------------------------------------------------------------------------

R1 = 'Assets/Ingame/Env/r1_meadow'
R2 = 'Assets/Ingame/Env/r2_ice'
R3 = 'Assets/Ingame/Env/r3_lava'
ENV = 'Assets/Ingame/Env'

# (folder, file, builder, (W,H,D), fit axes, extra)
REG = [
    (R1, 'env_r1_tree_round', r1_tree_round, (3.2, 4.2, 3.2), 'xyz', {}),
    (R1, 'env_r1_tree_pine', r1_tree_pine, (2.6, 6.0, 2.6), 'xyz', {}),
    (R1, 'env_r1_bush', r1_bush, (1.4, 0.9, 1.4), 'xyz', {}),
    (R1, 'env_r1_rock_small', r1_rock_small, (1.3, 0.9, 1.1), 'xyz', {}),
    (R1, 'env_r1_rock_cluster', r1_rock_cluster, (3.2, 1.8, 2.6), 'xyz', {}),
    (R1, 'env_r1_flower_patch', r1_flower_patch, (2.0, 0.1, 2.0), 'xz', {}),
    (R1, 'env_r1_hay_bale', r1_hay_bale, (1.3, 1.2, 1.3), 'xyz', {}),
    (R1, 'env_r1_fence', r1_fence, (3.0, 1.0, 0.3), 'xyz', {}),
    (R1, 'env_r1_sandbag_wall', r1_sandbag_wall, (2.6, 1.0, 0.9), 'xyz', {}),
    (R1, 'env_r1_crate_stack', r1_crate_stack, (1.8, 1.7, 1.4), 'xyz', {}),
    (R1, 'env_r1_army_tent', r1_army_tent, (3.6, 2.6, 4.0), 'xyz', {}),
    (R1, 'env_r1_watchtower', r1_watchtower, (2.4, 6.5, 2.4), 'xyz', {}),
    (R1, 'env_r1_windmill', r1_windmill, (3.5, 7.5, 3.0), 'xyz', {}),
    (R2, 'env_r2_pine_snow_tall', r2_pine_snow_tall, (2.8, 6.5, 2.8), 'xyz', {}),
    (R2, 'env_r2_pine_snow_small', r2_pine_snow_small, (1.8, 3.2, 1.8), 'xyz', {}),
    (R2, 'env_r2_dead_tree', r2_dead_tree, (2.2, 3.8, 2.2), 'xyz', {}),
    (R2, 'env_r2_snow_mound', r2_snow_mound, (2.6, 1.0, 2.2), 'xyz', {}),
    (R2, 'env_r2_ice_crystal_cluster', r2_ice_crystal_cluster, (2.2, 2.6, 2.2), 'xyz', {}),
    (R2, 'env_r2_ice_boulder', r2_ice_boulder, (1.6, 1.3, 1.4), 'xyz', {}),
    (R2, 'env_r2_icicle_rock_arch', r2_icicle_rock_arch, (6.0, 5.0, 2.4), 'xyz', {}),
    (R2, 'env_r2_frozen_pond', r2_frozen_pond, (5.0, 0.08, 4.0), 'xz', {}),
    (R2, 'env_r2_igloo', r2_igloo, (3.4, 2.2, 3.4), 'xyz', {}),
    (R2, 'env_r2_snowman', r2_snowman, (1.2, 1.7, 1.2), 'xyz', {}),
    (R2, 'env_r2_log_cabin', r2_log_cabin, (4.5, 3.6, 3.8), 'xyz', {}),
    (R2, 'env_r2_lamp_post', r2_lamp_post, (0.6, 3.2, 0.6), 'xyz', {}),
    (R2, 'env_r2_broken_sled', r2_broken_sled, (2.2, 0.9, 1.0), 'xyz', {}),
    (R3, 'env_r3_basalt_rock', r3_basalt_rock, (1.8, 1.4, 1.6), 'xyz', {}),
    (R3, 'env_r3_basalt_columns', r3_basalt_columns, (3.6, 4.5, 3.2), 'xyz', {}),
    (R3, 'env_r3_lava_pool', r3_lava_pool, (4.5, 0.08, 3.6), 'xz', {}),
    (R3, 'env_r3_lava_cracks', r3_lava_cracks, (3.0, 0.06, 3.0), 'xz', {}),
    (R3, 'env_r3_charred_tree', r3_charred_tree, (2.0, 3.6, 2.0), 'xyz', {}),
    (R3, 'env_r3_ember_crystal', r3_ember_crystal, (1.6, 2.2, 1.6), 'xyz', {}),
    (R3, 'env_r3_mini_volcano', r3_mini_volcano, (9.0, 8.0, 9.0), 'xyz', {}),
    (R3, 'env_r3_smokestack', r3_smokestack, (2.4, 8.0, 2.4), 'xyz', {}),
    (R3, 'env_r3_gear_large', r3_gear_large, (3.2, 3.2, 0.8), 'xyz', {}),
    (R3, 'env_r3_anvil', r3_anvil, (1.4, 1.2, 0.8), 'xyz', {}),
    (R3, 'env_r3_furnace', r3_furnace, (3.4, 3.6, 3.0), 'xyz', {}),
    (R3, 'env_r3_pipe_run', r3_pipe_run, (4.0, 1.4, 0.8), 'xyz', {}),
    (R3, 'env_r3_scrap_pile', r3_scrap_pile, (2.6, 1.6, 2.2), 'xyz', {}),
    (R1, 'env_r1_verge', verge_r1, (6.0, 0.2, 10.0), 'xyz', {'xrange': (7.2, 13.2)}),
    (R2, 'env_r2_verge', verge_r2, (6.0, 0.2, 10.0), 'xyz', {'xrange': (7.2, 13.2)}),
    (R3, 'env_r3_verge', verge_r3, (6.0, 0.2, 10.0), 'xyz', {'xrange': (7.2, 13.2)}),
    (ENV, 'backdrop_ice', lambda: _mountains('ice'), (260.0, 40.0, 14.0), 'xyz', {}),
    (ENV, 'backdrop_lava', lambda: _mountains('lava'), (260.0, 40.0, 14.0), 'xyz', {}),
]

BIG = {'env_r1_watchtower', 'env_r1_windmill', 'env_r1_army_tent', 'env_r2_icicle_rock_arch', 'env_r2_log_cabin',
       'env_r3_mini_volcano', 'env_r3_smokestack', 'env_r3_furnace', 'env_r1_rock_cluster', 'env_r3_basalt_columns',
       'env_r2_frozen_pond', 'env_r3_gear_large', 'env_r3_scrap_pile', 'env_r2_pine_snow_tall'}


def preview(results, out):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from mpl_toolkits.mplot3d.art3d import Poly3DCollection
    items = [r for r in results if not r[0].startswith('backdrop')]
    cols = 7
    rows = math.ceil(len(items) / cols)
    fig = plt.figure(figsize=(cols * 3, rows * 3), dpi=70)
    light = np.array([0.4, 0.8, 0.5])
    light /= np.linalg.norm(light)
    for i, (name, info) in enumerate(items):
        ax = fig.add_subplot(rows, cols, i + 1, projection='3d')
        V, N, C = info['V'], info['N'], info['C']
        P = np.stack([V[..., 0], -V[..., 2], V[..., 1]], axis=-1)
        sh = np.clip(N @ light, 0, 1) * 0.5 + 0.5
        fc = np.clip(C * sh[:, None], 0, 1)
        ax.add_collection3d(Poly3DCollection(P, facecolors=fc, edgecolors='none'))
        mn, mx = P.reshape(-1, 3).min(0), P.reshape(-1, 3).max(0)
        c = (mn + mx) / 2
        r = (mx - mn).max() / 2
        ax.set_xlim(c[0] - r, c[0] + r)
        ax.set_ylim(c[1] - r, c[1] + r)
        ax.set_zlim(c[2] - r, c[2] + r)
        ax.set_box_aspect((1, 1, 1))
        ax.view_init(elev=28, azim=-62)
        ax.set_axis_off()
        ax.set_title(name.replace('env_', ''), fontsize=8)
    fig.tight_layout()
    fig.savefig(out)


def main():
    args = sys.argv[1:]
    prev = None
    if '--preview' in args:
        i = args.index('--preview')
        prev = args[i + 1]
        del args[i:i + 2]
    root = args[0] if args else '.'
    results = []
    bad = 0
    for folder, name, fn, tgt, axes, extra in REG:
        path = os.path.join(root, folder, name + '.glb')
        info = save(fn(), path, target=tgt, axes=axes, xrange=extra.get('xrange'))
        limit = 2500 if name in BIG or name.startswith('backdrop') else 1200
        ok = info['tris'] <= limit and abs(info['min'][1]) < 1e-5 and info['colors'] <= 64
        for a, t in zip(info['size'], tgt):
            if 'xyz' == axes and abs(a - t) > 0.01 * max(t, 1):
                ok = False
        bad += (not ok)
        print('%-30s tris=%4d size=%.2fx%.2fx%.2f cols=%2d %s' % (name, info['tris'], *info['size'], info['colors'], 'OK' if ok else 'CHECK'))
        results.append((name, info))
    print('files:', len(results), 'issues:', bad)
    if prev:
        preview(results, prev)


if __name__ == '__main__':
    main()
