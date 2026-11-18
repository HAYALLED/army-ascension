"""Tiny procedural low-poly GLB toolkit.

Everything is built from convex hulls (boxes, bevel boxes, frustums, cylinders,
balls). All parts of a model are merged into ONE mesh with ONE material that
uses ONE small palette texture (flat colors, no baked lighting).

Conventions: Y up, 1 unit = 1 m, model front = +Z, character's right hand = -X.
"""
import json
import math
import struct
import zlib

import numpy as np
from scipy.spatial import ConvexHull

CELL = 16  # palette cell size in px
GRID = 16  # 16 x 16 cells -> 256 x 256 texture


def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def shade(h, f):
    r, g, b = hex2rgb(h)
    return "#%02X%02X%02X" % tuple(max(0, min(255, int(round(c * f)))) for c in (r, g, b))


def rot_matrix(rx=0.0, ry=0.0, rz=0.0):
    """Degrees. Applied X, then Y, then Z."""
    ax, ay, az = (math.radians(a) for a in (rx, ry, rz))
    cx, sx, cy, sy, cz, sz = math.cos(ax), math.sin(ax), math.cos(ay), math.sin(ay), math.cos(az), math.sin(az)
    mx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    my = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    mz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return mz @ my @ mx


class Model:
    def __init__(self, name):
        self.name = name
        self.parts = []  # (points Nx3, color hex)
        self.muzzle = None
        self.optimize = False  # cull buried / downward faces (units only)
        self._stack = []  # list of (R, pivot)

    # ---------------------------------------------------------------- groups
    class _Group:
        def __init__(self, model, R, pivot, mirror_x):
            self.m, self.R, self.pivot, self.mirror = model, R, np.array(pivot, float), mirror_x

        def __enter__(self):
            self.m._stack.append((self.R, self.pivot))
            return self

        def __exit__(self, *a):
            self.m._stack.pop()

    def group(self, rot=(0, 0, 0), pivot=(0, 0, 0)):
        """Rotate everything added inside the `with` block about `pivot`."""
        return Model._Group(self, rot_matrix(*rot), pivot, False)

    def _xf(self, pts):
        for R, pv in reversed(self._stack):
            pts = (pts - pv) @ R.T + pv
        return pts

    # ------------------------------------------------------------ primitives
    def hull(self, pts, color):
        pts = self._xf(np.asarray(pts, float))
        self.parts.append((pts, color))

    def box(self, c, s, color, bevel=0.0, rot=(0, 0, 0)):
        """Center c, size s. bevel > 0 -> chamfered box (44 tris), else 12 tris."""
        hx, hy, hz = (v / 2 for v in s)
        pts = []
        if bevel > 0:
            b = min(bevel, hx * 0.9, hy * 0.9, hz * 0.9)
            for sx in (-1, 1):
                for sy in (-1, 1):
                    for sz in (-1, 1):
                        pts.append((sx * hx, sy * (hy - b), sz * (hz - b)))
                        pts.append((sx * (hx - b), sy * hy, sz * (hz - b)))
                        pts.append((sx * (hx - b), sy * (hy - b), sz * hz))
        else:
            pts = [(sx * hx, sy * hy, sz * hz) for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
        pts = np.array(pts, float)
        if any(rot):
            pts = pts @ rot_matrix(*rot).T
        self.hull(pts + np.array(c, float), color)

    def frustum(self, c, bottom, top, h, color, rot=(0, 0, 0), top_off=(0, 0)):
        """Box that tapers. bottom/top = (w, d). c = center of the bottom face."""
        pts = []
        for sx in (-1, 1):
            for sz in (-1, 1):
                pts.append((sx * bottom[0] / 2, 0, sz * bottom[1] / 2))
                pts.append((sx * top[0] / 2 + top_off[0], h, sz * top[1] / 2 + top_off[1]))
        pts = np.array(pts, float)
        if any(rot):
            pts = pts @ rot_matrix(*rot).T
        self.hull(pts + np.array(c, float), color)

    def pyramid(self, c, base, h, color, rot=(0, 0, 0), sides=4):
        """c = center of base. Apex up (+Y)."""
        pts = [(0, h, 0)]
        for i in range(sides):
            a = 2 * math.pi * (i + 0.5) / sides
            pts.append((math.cos(a) * base[0] / 2, 0, math.sin(a) * base[1] / 2))
        pts = np.array(pts, float)
        if any(rot):
            pts = pts @ rot_matrix(*rot).T
        self.hull(pts + np.array(c, float), color)

    def cyl(self, c, r, h, color, sides=8, rot=(0, 0, 0), r_top=None, scale=(1, 1)):
        """Cylinder (Y axis) centered at c. r_top for a tapered cylinder."""
        rt = r if r_top is None else r_top
        pts = []
        for i in range(sides):
            a = 2 * math.pi * (i + 0.5) / sides
            pts.append((math.cos(a) * r * scale[0], -h / 2, math.sin(a) * r * scale[1]))
            pts.append((math.cos(a) * rt * scale[0], h / 2, math.sin(a) * rt * scale[1]))
        pts = np.array(pts, float)
        if any(rot):
            pts = pts @ rot_matrix(*rot).T
        self.hull(pts + np.array(c, float), color)

    def ball(self, c, r, color, seg=6, rings=3, scale=(1, 1, 1), rot=(0, 0, 0)):
        """Low-poly sphere / ellipsoid."""
        pts = [(0, r * scale[1], 0), (0, -r * scale[1], 0)]
        for j in range(1, rings + 1):
            phi = math.pi * j / (rings + 1)
            for i in range(seg):
                a = 2 * math.pi * i / seg
                pts.append((r * scale[0] * math.sin(phi) * math.cos(a), r * scale[1] * math.cos(phi),
                            r * scale[2] * math.sin(phi) * math.sin(a)))
        pts = np.array(pts, float)
        if any(rot):
            pts = pts @ rot_matrix(*rot).T
        self.hull(pts + np.array(c, float), color)

    def limb(self, a, b, w, color, d=None, bevel=0.0):
        """Box from point a to point b (cross-section w x d)."""
        a, b = np.array(a, float), np.array(b, float)
        v = b - a
        L = float(np.linalg.norm(v))
        d = w if d is None else d
        # build along +Y then rotate Y -> v
        y = v / L
        ref = np.array([0, 0, 1.0]) if abs(y[2]) < 0.95 else np.array([1.0, 0, 0])
        x = np.cross(ref, y)
        x /= np.linalg.norm(x)
        z = np.cross(x, y)
        R = np.stack([x, y, z], axis=1)
        mid = (a + b) / 2
        hx, hy, hz = w / 2, L / 2, d / 2
        if bevel > 0:
            bb = min(bevel, hx * 0.9, hy * 0.9, hz * 0.9)
            loc = []
            for sx in (-1, 1):
                for sy in (-1, 1):
                    for sz in (-1, 1):
                        loc.append((sx * hx, sy * (hy - bb), sz * (hz - bb)))
                        loc.append((sx * (hx - bb), sy * hy, sz * (hz - bb)))
                        loc.append((sx * (hx - bb), sy * (hy - bb), sz * hz))
        else:
            loc = [(sx * hx, sy * hy, sz * hz) for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
        pts = np.array(loc, float) @ R.T + mid
        self.hull(pts, color)

    def set_muzzle(self, p):
        self.muzzle = self._xf(np.array([p], float))[0]

    # --------------------------------------------------------------- queries
    def bounds(self):
        allp = np.vstack([p for p, _ in self.parts])
        return allp.min(axis=0), allp.max(axis=0)

    def fit(self, size=None, height=None, recenter_xz=False):
        """Scale to the exact final size (props: size=(w,h,d) non-uniform; characters: height=h uniform).
        Puts the bottom at y=0. Optionally centers x/z (props)."""
        lo, hi = self.bounds()
        ext = hi - lo
        if size is not None:
            s = np.array(size, float) / ext
        else:
            s = np.array([height / ext[1]] * 3)
        off = np.array([0.0, -lo[1], 0.0])
        cx = -(lo[0] + hi[0]) / 2 if recenter_xz else 0.0
        cz = -(lo[2] + hi[2]) / 2 if recenter_xz else 0.0

        def tf(p):
            q = p.copy()
            q[:, 0] = (q[:, 0] + cx) * s[0]
            q[:, 1] = (q[:, 1] + off[1]) * s[1]
            q[:, 2] = (q[:, 2] + cz) * s[2]
            return q

        self.parts = [(tf(p), c) for p, c in self.parts]
        if self.muzzle is not None:
            self.muzzle = tf(self.muzzle[None, :])[0]
        return s

    # ---------------------------------------------------------------- export
    def build_mesh(self, parts=None):
        parts = self.parts if parts is None else parts
        colors = []
        for _, c in parts:
            if c not in colors:
                colors.append(c)
        if len(colors) > GRID * GRID:
            raise ValueError("too many colors")
        hulls = []
        for pts, _ in parts:
            h = ConvexHull(pts, qhull_options="Qt")
            hulls.append((h, pts.min(axis=0) - 1e-3, pts.max(axis=0) + 1e-3))

        def buried(tri, pi):
            """True when the whole triangle lies inside ONE other part (convex => 3 corners suffice)."""
            for j, (h, lo, hi) in enumerate(hulls):
                if j == pi or any(np.any(q < lo) or np.any(q > hi) for q in tri):
                    continue
                if all(np.all(h.equations[:, :3] @ q + h.equations[:, 3] < -1e-4) for q in tri):
                    return True
            return False

        verts, vmap, idx = [], {}, []
        for pi, (pts, c) in enumerate(parts):
            ci = colors.index(c)
            u = ((ci % GRID) + 0.5) * CELL / (GRID * CELL)
            v = ((ci // GRID) + 0.5) * CELL / (GRID * CELL)
            center = pts.mean(axis=0)
            for simplex in hulls[pi][0].simplices:
                a, b, c3 = pts[simplex]
                n = np.cross(b - a, c3 - a)
                ln = np.linalg.norm(n)
                if ln < 1e-10:
                    continue
                n = n / ln
                if np.dot(n, a - center) < 0:  # make outward
                    b, c3 = c3, b
                    n = -n
                if self.optimize:
                    if n[1] < -0.7:  # underside: the game camera never sees it
                        continue
                    if buried([q + n * 0.003 for q in (a, b, c3)], pi):
                        continue
                tri = []
                for p in (a, b, c3):
                    key = (tuple(np.round(p, 5)), tuple(np.round(n, 4)), ci)
                    if key not in vmap:
                        vmap[key] = len(verts)
                        verts.append((p, n, (u, v)))
                    tri.append(vmap[key])
                idx.extend(tri)
        pos = np.array([x[0] for x in verts], np.float32)
        nor = np.array([x[1] for x in verts], np.float32)
        uv = np.array([x[2] for x in verts], np.float32)
        return pos, nor, uv, np.array(idx, np.uint32), colors

    def tri_count(self):
        return len(self.build_mesh()[3]) // 3

    def palette_png(self, colors):
        w = GRID * CELL
        raw = bytearray()
        for y in range(w):
            raw.append(0)
            row = y // CELL
            for x in range(w):
                ci = row * GRID + x // CELL
                rgb = hex2rgb(colors[ci]) if ci < len(colors) else (255, 0, 255)
                raw.extend(rgb)

        def chunk(t, d):
            c = struct.pack(">I", len(d)) + t + d
            return c + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

        return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, w, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))

    def write_glb(self, path, as_unit=True):
        """Parts colored "TINT" become a second primitive with a plain white, texture-less
        material named "Tint" (the game recolors it). Everything else = material "Frame"/"palette"."""
        main_parts = [p for p in self.parts if p[1] != "TINT"]
        tint_parts = [p for p in self.parts if p[1] == "TINT"]
        pos, nor, uv, idx, colors = self.build_mesh(main_parts)
        png = self.palette_png(colors)
        blob = bytearray()
        views, accs = [], []

        def add_view(data, target=None):
            while len(blob) % 4:
                blob.append(0)
            off = len(blob)
            blob.extend(data)
            v = {"buffer": 0, "byteOffset": off, "byteLength": len(data)}
            if target:
                v["target"] = target
            views.append(v)
            return len(views) - 1

        def add_prim(pos, nor, uv, idx, material):
            base = len(accs)
            vi = add_view(pos.tobytes(), 34962)
            accs.append({"bufferView": vi, "componentType": 5126, "count": len(pos), "type": "VEC3",
                         "min": [float(x) for x in pos.min(axis=0)], "max": [float(x) for x in pos.max(axis=0)]})
            vi = add_view(nor.tobytes(), 34962)
            accs.append({"bufferView": vi, "componentType": 5126, "count": len(nor), "type": "VEC3"})
            attrs = {"POSITION": base, "NORMAL": base + 1}
            if uv is not None:
                vi = add_view(uv.tobytes(), 34962)
                accs.append({"bufferView": vi, "componentType": 5126, "count": len(uv), "type": "VEC2"})
                attrs["TEXCOORD_0"] = base + 2
            ib, ct = (idx.astype(np.uint16).tobytes(), 5123) if len(pos) < 65536 else (idx.tobytes(), 5125)
            vi = add_view(ib, 34963)
            accs.append({"bufferView": vi, "componentType": ct, "count": len(idx), "type": "SCALAR"})
            return {"attributes": attrs, "indices": len(accs) - 1, "material": material}

        prims = [add_prim(pos, nor, uv, idx, 0)]
        total_tris = len(idx) // 3
        mat_name = "Frame" if tint_parts else "palette"
        materials = [{"name": mat_name, "pbrMetallicRoughness": {
            "baseColorTexture": {"index": 0}, "metallicFactor": 0.0, "roughnessFactor": 0.9}}]
        if tint_parts:
            tpos, tnor, _, tidx, _ = self.build_mesh(tint_parts)
            prims.append(add_prim(tpos, tnor, None, tidx, 1))
            total_tris += len(tidx) // 3
            materials.append({"name": "Tint", "pbrMetallicRoughness": {
                "baseColorFactor": [1.0, 1.0, 1.0, 1.0], "metallicFactor": 0.0, "roughnessFactor": 0.9}})
        img_view = add_view(png)

        gltf = {
            "asset": {"version": "2.0", "generator": "army-ascension glbkit"},
            "scene": 0,
            "scenes": [{"nodes": [0]}],
            "meshes": [{"name": self.name, "primitives": prims}],
            "materials": materials,
            "textures": [{"source": 0, "sampler": 0}],
            "samplers": [{"magFilter": 9728, "minFilter": 9728, "wrapS": 33071, "wrapT": 33071}],
            "images": [{"bufferView": img_view, "mimeType": "image/png", "name": "palette"}],
            "accessors": accs,
            "bufferViews": views,
            "buffers": [{"byteLength": len(blob)}],
        }
        if as_unit:
            nodes = [{"name": self.name, "children": [1]}, {"name": self.name + "_mesh", "mesh": 0}]
            if self.muzzle is not None:
                nodes.append({"name": "Muzzle", "translation": [float(x) for x in self.muzzle]})
                nodes[0]["children"].append(2)
        else:
            nodes = [{"name": self.name, "mesh": 0}]
        gltf["nodes"] = nodes

        js = json.dumps(gltf, separators=(",", ":")).encode()
        while len(js) % 4:
            js += b" "
        bb = bytes(blob)
        while len(bb) % 4:
            bb += b"\0"
        total = 12 + 8 + len(js) + 8 + len(bb)
        with open(path, "wb") as f:
            f.write(struct.pack("<4sII", b"glTF", 2, total))
            f.write(struct.pack("<I4s", len(js), b"JSON") + js)
            f.write(struct.pack("<I4s", len(bb), b"BIN\0") + bb)
        return {"tris": total_tris, "colors": len(colors), "bytes": total}
