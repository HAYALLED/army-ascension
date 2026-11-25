"""40 passive-area floor markers (10 units x 4 ranks). Round, radius exactly 1.0 m, height <= 0.06 m, <= 400 tris.
Rings are not convex, so these use a small flat-mesh builder (own triangles, same palette/glow GLB layout as glbkit:
one palette texture, material 0 = matte, material 1 = emissive "G:#RRGGBB" parts). Y up, bottom at y=0, +Z = forward.
Small details are drawn as flat top faces floating 1.2 cm over the field (the camera never sees under them)."""
import json
import math
import struct

import numpy as np

from glbkit import Model, rot_matrix, GRID

FIELD, FIELD_LIGHT, GRAY = "#2A2F39", "#D6DAE2", "#8C919C"
PURP, GPURP = "#8A3FD1", "G:#B66BFF"
BLUA, GBLUA = "#2F7BFF", "G:#56A0FF"
GOLDA, GWARMA = "#D9A62E", "G:#FFF3DC"
WHITE = "#F2F2F2"

# unit -> (base color, accent color, field color)
UNITS = {
    "medic": ("#40B359", "#F2F2F2", FIELD),
    "drummer": ("#E8B423", "#F6E7B4", FIELD),
    "weakener": ("#0F5F5C", "#8FD14F", FIELD_LIGHT),
    "blinder": ("#A68A5B", "#FFE45C", FIELD),
    "shield_knight": ("#A9B1BD", "#6E7787", FIELD),
    "rifleman": ("#3573E6", "#F2F2F2", FIELD),
    "machine_gunner": ("#F28C1F", "#F2C21A", FIELD),
    "sniper": ("#386638", "#B3A25C", FIELD),
    "rocket_soldier": ("#CC3330", "#FF8C1A", FIELD),
    "mortar": ("#4A5160", "#C9A94A", FIELD_LIGHT),
}
RANKS = ("common", "rare", "super_rare", "legend")

# heights
Y_FIELD, Y_RING, Y_ICON = 0.02, 0.032, 0.034


class Area:
    def __init__(self, name):
        self.name = name
        self.tris = []  # (a, b, c, color)

    # ------------------------------------------------------------------ low level
    def _poly(self, pts, col, hint):
        pts = [np.asarray(p, float) for p in pts]
        nrm = np.cross(pts[1] - pts[0], pts[2] - pts[0])
        if np.dot(nrm, hint) < 0:
            pts = pts[::-1]
        for i in range(1, len(pts) - 1):
            a, b, c = pts[0], pts[i], pts[i + 1]
            if np.linalg.norm(np.cross(b - a, c - a)) > 1e-10:
                self.tris.append((a, b, c, col))

    @staticmethod
    def loc(cx, cz, ry, lx, lz):
        r = math.radians(ry)
        return (cx + math.cos(r) * lx + math.sin(r) * lz, cz - math.sin(r) * lx + math.cos(r) * lz)

    def _flat(self, pts_xz, y, col):
        self._poly([(x, y, z) for x, z in pts_xz], col, (0, 1, 0))

    # ------------------------------------------------------------------ flat (top-only) shapes
    def bar(self, cx, cz, length, width, ry, y, col):
        pts = [self.loc(cx, cz, ry, sx * width / 2, sz * length / 2) for sx, sz in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        self._flat(pts, y, col)

    def tri_f(self, cx, cz, w, l, ry, y, col):
        pts = [self.loc(cx, cz, ry, -w / 2, -l / 2), self.loc(cx, cz, ry, w / 2, -l / 2), self.loc(cx, cz, ry, 0, l / 2)]
        self._flat(pts, y, col)

    def diam(self, cx, cz, w, l, ry, y, col):
        pts = [self.loc(cx, cz, ry, 0, -l / 2), self.loc(cx, cz, ry, w / 2, 0), self.loc(cx, cz, ry, 0, l / 2),
               self.loc(cx, cz, ry, -w / 2, 0)]
        self._flat(pts, y, col)

    def ngon(self, cx, cz, r, n, y, col, a0=0.0):
        self._flat([(cx + r * math.cos(math.radians(a0 + 360 * i / n)), cz + r * math.sin(math.radians(a0 + 360 * i / n)))
                    for i in range(n)], y, col)

    def ring(self, r0, r1, y, col, n=24, segs=None, y0=None):
        """Flat annulus (top face). With y0: also an outer wall from y0 up to y (and inner wall if inner=...)."""
        segs = range(n) if segs is None else segs
        for i in segs:
            a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
            o0 = (r1 * math.cos(a0), y, r1 * math.sin(a0))
            o1 = (r1 * math.cos(a1), y, r1 * math.sin(a1))
            i0 = (r0 * math.cos(a0), y, r0 * math.sin(a0))
            i1 = (r0 * math.cos(a1), y, r0 * math.sin(a1))
            self._poly([o0, o1, i1, i0], col, (0, 1, 0))
            if y0 is not None:
                am = (a0 + a1) / 2
                self._poly([(o0[0], y0, o0[2]), (o1[0], y0, o1[2]), o1, o0], col, (math.cos(am), 0, math.sin(am)))

    # ------------------------------------------------------------------ solid shapes (with walls, no bottom)
    def disc(self, cx, cz, r, n, y1, col, y0=None, a0=0.0):
        pts = [(cx + r * math.cos(math.radians(a0 + 360 * i / n)), cz + r * math.sin(math.radians(a0 + 360 * i / n)))
               for i in range(n)]
        self._flat(pts, y1, col)
        if y0 is not None:
            for i in range(n):
                p, q = pts[i], pts[(i + 1) % n]
                mid = ((p[0] + q[0]) / 2 - cx, (p[1] + q[1]) / 2 - cz)
                self._poly([(p[0], y0, p[1]), (q[0], y0, q[1]), (q[0], y1, q[1]), (p[0], y1, p[1])], col, (mid[0], 0, mid[1]))

    def box(self, cx, cz, w, l, ry, y0, y1, col):
        """Box with walls, local +Z = length direction."""
        c = [self.loc(cx, cz, ry, sx * w / 2, sz * l / 2) for sx, sz in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        self._flat(c, y1, col)
        for i in range(4):
            p, q = c[i], c[(i + 1) % 4]
            mid = ((p[0] + q[0]) / 2 - cx, (p[1] + q[1]) / 2 - cz)
            self._poly([(p[0], y0, p[1]), (q[0], y0, q[1]), (q[0], y1, q[1]), (p[0], y1, p[1])], col, (mid[0], 0, mid[1]))

    def tri_p(self, cx, cz, w, l, ry, y0, y1, col):
        """Triangular prism, apex toward local +Z."""
        c = [self.loc(cx, cz, ry, -w / 2, -l / 2), self.loc(cx, cz, ry, w / 2, -l / 2), self.loc(cx, cz, ry, 0, l / 2)]
        self._flat(c, y1, col)
        gx, gz = sum(p[0] for p in c) / 3, sum(p[1] for p in c) / 3
        for i in range(3):
            p, q = c[i], c[(i + 1) % 3]
            mid = ((p[0] + q[0]) / 2 - gx, (p[1] + q[1]) / 2 - gz)
            self._poly([(p[0], y0, p[1]), (q[0], y0, q[1]), (q[0], y1, q[1]), (p[0], y1, p[1])], col, (mid[0], 0, mid[1]))

    def pyr(self, cx, cz, y0, b, h, col, ry=0.0):
        c = [self.loc(cx, cz, ry, sx * b / 2, sz * b / 2) for sx, sz in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        apex = (cx, y0 + h, cz)
        for i in range(4):
            p, q = c[i], c[(i + 1) % 4]
            self._poly([(p[0], y0, p[1]), (q[0], y0, q[1]), apex], col,
                       ((p[0] + q[0]) / 2 - cx, 0.3, (p[1] + q[1]) / 2 - cz))

    # ------------------------------------------------------------------ export
    def tri_count(self):
        return len(self.tris)

    def write_glb(self, path):
        order = []
        groups = {0: [], 1: []}
        for a, b, c, col in self.tris:
            glow = col.startswith("G:")
            hx = (col[2:] if glow else col).upper()
            if hx not in order:
                order.append(hx)
            groups[1 if glow else 0].append((a, b, c, order.index(hx)))
        if len(order) > GRID * GRID:
            raise ValueError("too many colors")
        png = Model.palette_png(None, order)
        blob, views, accs, prims, mats = bytearray(), [], [], [], []

        def add_view(data, target=None):
            while len(blob) % 4:
                blob.append(0)
            v = {"buffer": 0, "byteOffset": len(blob), "byteLength": len(data)}
            blob.extend(data)
            if target:
                v["target"] = target
            views.append(v)
            return len(views) - 1

        for gi in (0, 1):
            tris = groups[gi]
            if not tris:
                continue
            pos, nor, uv = [], [], []
            for a, b, c, ci in tris:
                n = np.cross(b - a, c - a)
                n = n / np.linalg.norm(n)
                u = ((ci % GRID) + 0.5) / GRID
                v = ((ci // GRID) + 0.5) / GRID
                for p in (a, b, c):
                    pos.append(p)
                    nor.append(n)
                    uv.append((u, v))
            pos, nor, uv = (np.array(x, np.float32) for x in (pos, nor, uv))
            idx = np.arange(len(pos), dtype=np.uint16)
            base = len(accs)
            accs.append({"bufferView": add_view(pos.tobytes(), 34962), "componentType": 5126, "count": len(pos), "type": "VEC3",
                         "min": [float(x) for x in pos.min(axis=0)], "max": [float(x) for x in pos.max(axis=0)]})
            accs.append({"bufferView": add_view(nor.tobytes(), 34962), "componentType": 5126, "count": len(nor), "type": "VEC3"})
            accs.append({"bufferView": add_view(uv.tobytes(), 34962), "componentType": 5126, "count": len(uv), "type": "VEC2"})
            accs.append({"bufferView": add_view(idx.tobytes(), 34963), "componentType": 5123, "count": len(idx), "type": "SCALAR"})
            m = {"name": "palette" if gi == 0 else "Glow",
                 "pbrMetallicRoughness": {"baseColorTexture": {"index": 0}, "metallicFactor": 0.0, "roughnessFactor": 0.9}}
            if gi == 1:
                m["emissiveTexture"] = {"index": 0}
                m["emissiveFactor"] = [1.0, 1.0, 1.0]
            mats.append(m)
            prims.append({"attributes": {"POSITION": base, "NORMAL": base + 1, "TEXCOORD_0": base + 2},
                          "indices": base + 3, "material": len(mats) - 1})
        img = add_view(png)
        gltf = {"asset": {"version": "2.0", "generator": "army-ascension glbkit areas"}, "scene": 0,
                "scenes": [{"nodes": [0]}], "nodes": [{"name": self.name, "mesh": 0}],
                "meshes": [{"name": self.name, "primitives": prims}], "materials": mats,
                "textures": [{"source": 0, "sampler": 0}],
                "samplers": [{"magFilter": 9728, "minFilter": 9728, "wrapS": 33071, "wrapT": 33071}],
                "images": [{"bufferView": img, "mimeType": "image/png", "name": "palette"}],
                "accessors": accs, "bufferViews": views, "buffers": [{"byteLength": len(blob)}]}
        js = json.dumps(gltf, separators=(",", ":")).encode()
        while len(js) % 4:
            js += b" "
        bb = bytes(blob)
        while len(bb) % 4:
            bb += b"\0"
        with open(path, "wb") as f:
            f.write(struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(js) + 8 + len(bb)))
            f.write(struct.pack("<I4s", len(js), b"JSON") + js)
            f.write(struct.pack("<I4s", len(bb), b"BIN\0") + bb)
        return {"tris": len(self.tris), "colors": len(order)}


# ====================================================================================== motifs
def _pt(r, phi):
    p = math.radians(phi)
    return r * math.sin(p), r * math.cos(p)


def center_icon(a, unit, y0, d1, d2, base, alt):
    """Big center icon. y0 = surface it stands on, main layer at y0+d1, detail layer at main+d2."""
    ym, yd = y0 + d1, y0 + d1 + d2
    e = 0.002 if d2 > 0.005 else 0.0004  # tiny z-offsets between overlapping detail layers
    if unit == "medic":
        a.box(0, 0, 0.18, 0.58, 0, y0, ym, base)
        a.box(0, 0, 0.58, 0.18, 0, y0, ym, base)
        a.bar(0, 0, 0.40, 0.08, 0, yd, alt)
        a.bar(0, 0, 0.08, 0.40, 0, yd, alt)
    elif unit == "drummer":
        a.disc(0, 0, 0.30, 12, ym, base, y0=y0)
        a.disc(0, 0, 0.22, 12, yd, alt)
        a.bar(0, 0, 0.56, 0.05, 40, yd + 1.5 * e, "#8A5A12")
        a.bar(0, 0, 0.56, 0.05, -40, yd + 1.5 * e, "#8A5A12")
    elif unit == "weakener":
        a.disc(0, 0, 0.32, 12, ym, base, y0=y0)
        a.box(0, 0.08, 0.22, 0.16, 0, ym, yd, "#EFE9D8")  # skull
        a.box(0, 0.0, 0.14, 0.07, 0, ym, yd, "#EFE9D8")  # jaw
        for sx in (-1, 1):
            a.bar(sx * 0.05, 0.1, 0.05, 0.05, 0, yd + e / 2, "#14201F")
        a.bar(0, -0.15, 0.1, 0.05, 0, yd, alt)  # down arrow (toward -Z)
        a.tri_f(0, -0.23, 0.17, 0.1, 180, yd, alt)
    elif unit == "blinder":
        a.disc(0, 0, 0.30, 12, ym, base, y0=y0)
        for k in range(4):  # 8-ray starburst
            a.bar(0, 0, 0.6, 0.05, k * 45, yd, alt)
        a.ngon(0, 0, 0.15, 6, yd + e, "#F2EBD8", a0=0)
        a.ngon(0, 0, 0.06, 4, yd + 1.5 * e, "#2A2F39")
        a.bar(0, 0, 0.5, 0.045, 45, yd + 2 * e, "#CC3330")  # cross-out slash
    elif unit == "shield_knight":
        a.box(0, 0.09, 0.4, 0.26, 0, y0, ym, base)
        a.tri_p(0, -0.13, 0.4, 0.26, 180, y0, ym, base)
        a.bar(0, 0.0, 0.36, 0.06, 0, yd, alt)
        a.bar(0, 0.0, 0.06, 0.4, 0, yd, alt)
    elif unit == "rifleman":
        a.ring(0.18, 0.25, ym, base, n=16, y0=y0)
        for k in range(4):
            a.bar(*_pt(0.3, k * 90), 0.16, 0.045, k * 90, ym, base)
        a.bar(0, 0, 0.1, 0.1, 0, yd, alt)
    elif unit == "machine_gunner":
        for ry in (-26, 0, 26):
            cx, cz = _pt(0.07, ry)
            a.box(cx, cz - 0.02, 0.1, 0.26, ry, y0, ym, base)
            tx, tz = a.loc(cx, cz - 0.02, ry, 0, 0.13)
            a.tri_p(tx, tz + 0.0, 0.1, 0.12, ry, y0, ym, alt)
            a.bar(cx, cz - 0.1, 0.04, 0.1, ry, yd, alt)
    elif unit == "sniper":
        a.ring(0.2, 0.27, ym, base, n=16, y0=y0)
        a.bar(0, 0, 0.7, 0.04, 0, ym, base)
        a.bar(0, 0, 0.04, 0.7, 0, ym, base)
        a.bar(0, 0, 0.09, 0.09, 45, yd, alt)
    elif unit == "rocket_soldier":
        for k in range(4):  # explosion starburst behind the rocket
            a.bar(0, 0, 0.7, 0.07, k * 45, y0 + 0.004, alt)
        a.box(0, -0.02, 0.12, 0.3, 0, y0, ym, base)
        a.tri_p(0, 0.25, 0.12, 0.18, 0, y0, ym, base)
        for sx in (-1, 1):
            a.tri_p(sx * 0.09, -0.15, 0.1, 0.13, 180 + sx * 20, y0, ym, "#8A1F1F")
        a.bar(0, 0.0, 0.12, 0.03, 0, yd, WHITE)
    elif unit == "mortar":
        a.disc(0, 0, 0.32, 12, ym, base, y0=y0)
        a.disc(0, 0, 0.21, 12, yd, alt)
        a.disc(0, 0, 0.1, 8, yd + e, base)
        a.box(0, 0.02, 0.09, 0.3, 0, ym, yd + 1.5 * e, "#2A2F39")  # falling shell
        a.tri_p(0, 0.19, 0.09, 0.1, 0, ym, yd + 1.5 * e, "#2A2F39")


def small_icon(a, unit, r, phi, y, base, alt, idx):
    cx, cz = _pt(r, phi)
    ry = phi
    if unit == "medic":
        if idx % 2 == 0:
            a.bar(cx, cz, 0.13, 0.045, ry, y, base)
            a.bar(cx, cz, 0.045, 0.13, ry, y, base)
        else:  # soft heart = diamond + two bumps
            a.diam(cx, cz, 0.11, 0.11, ry, y, alt)
            for sx in (-1, 1):
                x2, z2 = a.loc(cx, cz, ry, sx * 0.03, 0.035)
                a.ngon(x2, z2, 0.032, 4, y, alt, a0=45)
    elif unit == "drummer":
        a.bar(cx, cz, 0.06, 0.06, ry, y, base)
        sx_, sz_ = a.loc(cx, cz, ry, 0.03, 0.06)
        a.bar(sx_, sz_, 0.13, 0.025, ry, y, base)
    elif unit == "weakener":
        a.bar(cx, cz, 0.12, 0.035, ry, y, alt)
        hx, hz = a.loc(cx, cz, ry, 0.04, 0.06)
        a.bar(hx, hz, 0.035, 0.1, ry, y, alt)
    elif unit == "blinder":
        a.tri_f(cx, cz, 0.06, 0.16, ry, y, alt)
    elif unit == "shield_knight":
        a.bar(cx, cz + 0, 0.07, 0.09, ry, y, base)
        tx, tz = a.loc(cx, cz, ry, 0, -0.06)
        a.tri_f(tx, tz, 0.09, 0.06, ry + 180, y, base)
    elif unit == "rifleman":
        for s in (-1, 1):
            bx, bz = a.loc(cx, cz, ry, s * 0.032, 0)
            a.bar(bx, bz, 0.1, 0.035, ry + s * 40, y, base)
    elif unit == "machine_gunner":
        if idx % 2 == 0:
            a.bar(cx, cz, 0.1, 0.045, ry, y, base)
            tx, tz = a.loc(cx, cz, ry, 0, 0.075)
            a.tri_f(tx, tz, 0.045, 0.05, ry, y, alt)
        else:
            for s in (-1, 1):
                bx, bz = a.loc(cx, cz, ry, s * 0.032, 0)
                a.bar(bx, bz, 0.1, 0.035, ry - s * 40, y, base)
    elif unit == "sniper":
        a.bar(cx, cz, 0.2, 0.035, ry, y, base)
    elif unit == "rocket_soldier":
        a.diam(cx, cz, 0.07, 0.2, ry, y, alt)
    elif unit == "mortar":
        a.ngon(cx, cz, 0.055, 6, y, base)
        a.diam(cx, cz, 0.05, 0.05, ry, y + 0.002, alt)


# ====================================================================================== ranks
def build_area(unit, rank):
    base, alt, field = UNITS[unit]
    a = Area(f"{unit}_{rank}_area")
    if unit == "sniper" and rank == "legend":
        return _sniper_grass(a, base, alt)
    if rank == "legend":
        return _legend(a, unit, base, alt, field)
    # ---- common core: rim, field, thin ring, center icon
    if rank == "super_rare":  # notched / segmented border
        a.ring(0.92, 1.0, 0.045, "#5A6478", n=24, segs=range(0, 24, 2), y0=0.0)
        for i in range(0, 24, 2):
            a.ring(0.94, 0.985, 0.0455, BLUA, n=24, segs=[i])
    else:
        a.ring(0.92, 1.0, 0.045, GRAY, n=24, y0=0.0)
    a.disc(0, 0, 0.92, 24, Y_FIELD, field)
    a.ring(0.82, 0.88, Y_RING, base, n=24)
    center_icon(a, unit, Y_FIELD, 0.014, 0.012, base, alt)
    if rank == "rare":
        a.ring(0.71, 0.76, Y_RING, PURP, n=24)
        for k in range(4):  # purple glow dots between the rings
            x, z = _pt(0.79, 45 + k * 90)
            a.bar(x, z, 0.05, 0.05, 45 + k * 90, Y_RING + 0.002, GPURP)
        for k in range(4):
            small_icon(a, unit, 0.52, k * 90, Y_ICON, base, alt, k)
    elif rank == "super_rare":
        a.ring(0.70, 0.75, Y_RING + 0.001, GBLUA, n=16)
        for k in range(6):
            x, z = _pt(0.79, 30 + k * 60)
            a.bar(x, z, 0.05, 0.05, 30 + k * 60, Y_RING + 0.002, BLUA)
            small_icon(a, unit, 0.52, k * 60, Y_ICON, base, alt, k)
    return a


def _legend(a, unit, base, alt, field):
    # outer gold border (raised, walls) + inner gold thin ring = double border
    a.ring(0.90, 1.0, 0.05, GOLDA, n=24, y0=0.0)
    a.disc(0, 0, 0.90, 24, Y_FIELD, field)
    a.ring(0.81, 0.86, 0.04, GOLDA, n=24)
    for k in range(8):  # 8 chunky gold spikes
        x, z = _pt(0.74, k * 45)
        a.pyr(x, z, Y_FIELD, 0.075, 0.04, GOLDA, ry=k * 45)
    a.ring(0.62, 0.67, 0.034, GWARMA, n=16)  # glowing warm ring
    a.disc(0, 0, 0.56, 12, 0.032, base, y0=Y_FIELD)  # level 2
    a.disc(0, 0, 0.38, 12, 0.044, field if field == FIELD else "#3A4150", y0=0.032, a0=15)  # level 3
    a.ring(0.30, 0.345, 0.0455, GOLDA, n=12)
    center_icon(a, unit, 0.044, 0.012, 0.003, base, alt)  # emblem raised one extra step (+0.012)
    return a


def _sniper_grass(a, base, alt):
    rs = np.random.RandomState(386638)
    DARK, LEAF, STRAW, MID = "#27471F", "#7C9A3A", "#B3A25C", base
    a.disc(0, 0, 1.0, 24, Y_FIELD, DARK, y0=0.0)  # grass bed (radius exactly 1.0)
    cols = (LEAF, STRAW, MID, LEAF, "#4C8A3A")
    placed = 0
    tries = 0
    pts = []
    while placed < 62 and tries < 4000:
        tries += 1
        r = math.sqrt(rs.uniform(0.42 ** 2, 0.86 ** 2))
        phi = rs.uniform(0, 360)
        x, z = _pt(r, phi)
        if any((x - px) ** 2 + (z - pz) ** 2 < 0.115 ** 2 for px, pz in pts):
            continue
        pts.append((x, z))
        b = rs.uniform(0.11, 0.16)
        h = rs.uniform(0.026, 0.04)
        a.pyr(x, z, Y_FIELD, b, h, cols[rs.randint(len(cols))], ry=rs.uniform(0, 90))
        placed += 1
    a.ring(0.2, 0.27, 0.034, base, n=16)  # scope reticle in a clearing
    a.bar(0, 0, 0.7, 0.04, 0, 0.034, base)
    a.bar(0, 0, 0.04, 0.7, 0, 0.034, base)
    a.bar(0, 0, 0.09, 0.09, 45, 0.046, GWARMA)  # warm center dot: one of the few gold/warm details
    for k in range(3):  # tiny gold details
        x, z = _pt(0.35, 60 + k * 120)
        a.bar(x, z, 0.035, 0.035, 45, 0.036, GOLDA)
    return a


ALL = [(u, r) for u in UNITS for r in RANKS]
