"""Environment props. Each is ONE mesh, origin bottom-center, sized exactly via fit()."""
import math
import random

import numpy as np

from glbkit import Model, shade

WIN = "#3A3F4E"


def tree_a():
    m = Model("tree_a")
    m.box((0, 0.7, 0), (0.55, 1.4, 0.55), "#7A4A22")
    m.box((0, 2.2, 0), (2.4, 1.6, 2.4), "#3FA83A", bevel=0.2)
    m.box((0.1, 3.3, -0.05), (1.6, 1.0, 1.6), "#58C246", bevel=0.18)
    m.box((-0.95, 1.75, 0.95), (0.8, 0.7, 0.8), "#3FA83A", bevel=0.12)
    m.fit(size=(2.5, 3.5, 2.5), recenter_xz=True)
    return m


def tree_b():
    m = Model("tree_b")
    m.box((0, 0.5, 0), (0.45, 1.0, 0.45), "#7A4A22")
    m.box((0, 1.5, 0), (2.2, 1.2, 2.2), "#1F7A3C", bevel=0.15)
    m.box((0, 2.75, 0), (1.7, 1.2, 1.7), "#2A9448", bevel=0.14)
    m.box((0, 3.95, 0), (1.1, 1.1, 1.1), "#38AD55", bevel=0.12)
    m.pyramid((0, 4.4, 0), (0.7, 0.7), 0.6, "#4CC268")
    m.fit(size=(2.2, 4.5, 2.2), recenter_xz=True)
    return m


def rock_a():
    m = Model("rock_a")
    g, t = "#8C9099", "#BEC2CC"
    for (x, z, w, h, d, yaw) in ((0, 0, 0.9, 0.9, 0.8, 12), (0.55, 0.3, 0.6, 0.55, 0.6, -20), (-0.35, -0.4, 0.55, 0.45, 0.5, 35)):
        m.box((x, h / 2, z), (w, h, d), g, bevel=0.07, rot=(0, yaw, 0))
        m.box((x, h + 0.0, z), (w * 0.78, 0.06, d * 0.78), t, rot=(0, yaw, 0))
    m.fit(size=(1.4, 1.0, 1.2), recenter_xz=True)
    return m


def _boulder(r, seed, squash=0.8, seg=7, rings=3):
    rnd = random.Random(seed)
    pts = [(0, r * squash * 1.0, 0), (0, -r * squash * 0.5, 0)]
    for j in range(1, rings + 1):
        phi = math.pi * j / (rings + 1)
        for i in range(seg):
            a = 2 * math.pi * i / seg + rnd.uniform(-0.12, 0.12)
            k = rnd.uniform(0.82, 1.1)
            pts.append((r * k * math.sin(phi) * math.cos(a), r * squash * k * math.cos(phi),
                        r * k * math.sin(phi) * math.sin(a)))
    return np.array(pts)


def rock_b():
    m = Model("rock_b")
    p = _boulder(0.5, 7)
    p[:, 1] += 0.3
    m.hull(p, "#858992")
    top = _boulder(0.3, 3, squash=0.5, seg=6, rings=2)
    top[:, 1] += 0.52
    m.hull(top, "#BEC2CC")
    m.fit(size=(0.9, 0.7, 0.9), recenter_xz=True)
    return m


def _windows(m, face, cols, rows, x0, y0, sx, sy, w=0.55, h=0.7, depth=0.08, color=WIN):
    """face: ('z', +1/-1, offset) or ('x', +1/-1, offset)."""
    axis, sign, off = face
    for r in range(rows):
        for c in range(cols):
            a = x0 + c * sx
            y = y0 + r * sy
            if axis == "z":
                m.box((a, y, sign * off), (w, h, depth), color)
            else:
                m.box((sign * off, y, a), (depth, h, w), color)


def building_a():
    m = Model("building_a")
    wall, roof, dark = "#E3CFA0", "#C0583A", "#2E3140"
    m.box((0, 2.3, 0), (5.6, 4.6, 5.6), wall)
    m.box((0, 0.12, 0), (5.8, 0.24, 5.8), "#A8987A")  # foundation
    # gable wall triangle (full depth)
    m.hull([(-2.8, 4.6, -2.8), (2.8, 4.6, -2.8), (0, 6.0, -2.8), (-2.8, 4.6, 2.8), (2.8, 4.6, 2.8), (0, 6.0, 2.8)], wall)
    # roof: left slope intact, right slope torn open at the front
    m.limb((-3.05, 4.55, 0), (0.0, 6.15, 0), 0.22, roof, d=6.2)
    m.limb((3.05, 4.55, -1.4), (0.0, 6.15, -1.4), 0.22, roof, d=3.4)
    m.box((1.4, 4.7, 2.1), (1.2, 0.25, 0.9), "#7A3A26", rot=(0, 20, 20))  # fallen tile chunk
    m.box((1.7, 5.25, 1.9), (0.18, 1.5, 0.18), "#5A3C24", rot=(0, 0, 38))  # broken rafter
    m.box((-1.7, 6.5, -1.7), (0.7, 1.4, 0.7), "#B5A27E")  # chimney
    m.box((-1.7, 7.2, -1.7), (0.85, 0.15, 0.85), "#8A7A5A")
    # door + windows + dark broken hole
    m.box((0, 1.0, 2.82), (1.1, 2.0, 0.1), "#6B4423")
    _windows(m, ("z", 1, 2.82), 2, 1, -1.9, 2.8, 3.8, 0, w=0.9, h=0.9)
    _windows(m, ("z", -1, 2.82), 3, 1, -1.9, 2.4, 1.9, 0, w=0.9, h=0.9)
    _windows(m, ("x", 1, 2.82), 2, 1, -1.2, 2.4, 2.4, 0, w=0.9, h=0.9)
    _windows(m, ("x", -1, 2.82), 2, 1, -1.2, 2.4, 2.4, 0, w=0.9, h=0.9)
    m.box((2.2, 3.6, 2.82), (1.3, 1.5, 0.1), dark)  # wall breach at roof corner
    m.box((3.3, 0.35, 3.4), (1.0, 0.7, 0.9), "#A8987A", rot=(0, 25, 0), bevel=0.05)  # rubble
    m.box((-3.4, 0.25, 3.0), (0.6, 0.5, 0.6), "#B5A27E", rot=(0, -15, 0), bevel=0.04)
    m.fit(size=(6, 7, 6), recenter_xz=True)
    return m


def building_b():
    m = Model("building_b")
    wall, band, dark = "#8A7F78", "#6B625C", "#2E3140"
    m.box((0, 0.2, 0), (5.0, 0.4, 5.0), "#5E5651")
    m.box((0, 4.4, 0), (4.6, 8.0, 4.6), wall)  # main block to y=8.4
    for fy in (2.6, 4.8, 7.0):
        m.box((0, fy, 0), (4.8, 0.18, 4.8), band)
    cols, rows = 3, 4
    off = 2.3
    for face, axis in (("z", 1), ("z", -1), ("x", 1), ("x", -1)):
        _windows(m, (face, axis, off), cols, rows, -1.3, 1.6, 1.3, 1.9, w=0.7, h=0.95, depth=0.1)
    # top storey with the north-east corner missing
    for (qx, qz) in ((-1.15, -1.15), (-1.15, 1.15), (1.15, -1.15)):
        m.box((qx, 9.7, qz), (2.3, 2.6, 2.3), wall)
    m.box((1.2, 8.7, 1.2), (1.5, 0.7, 1.4), "#5E5651", rot=(0, 25, 8))  # stump / rubble on the edge
    m.box((1.55, 9.2, 1.55), (0.14, 1.8, 0.14), "#4A3A30", rot=(10, 0, -20))  # exposed beam
    for sgn in (1, -1):
        m.box((-1.15 * sgn, 9.7, 2.3 * 1.0 if sgn == 1 else -2.3), (0.8, 0.9, 0.1), dark)
    m.box((-2.3, 9.7, 1.15), (0.1, 0.9, 0.8), dark)
    m.box((-1.15, 11.05, -1.15), (2.5, 0.2, 2.5), band)  # parapet
    m.box((-1.15, 11.05, 1.15), (2.5, 0.2, 2.5), band)
    m.box((1.15, 11.05, -1.15), (2.5, 0.2, 2.5), band)
    m.fit(size=(5, 11, 5), recenter_xz=True)
    return m


def building_c():
    m = Model("building_c")
    wall, roof = "#A39482", "#B5562A"
    m.box((0, 1.7, 0), (8.8, 3.4, 5.8), wall)
    m.box((0, 0.15, 0), (9.0, 0.3, 6.0), "#6E6455")
    # low gable roof
    m.hull([(-4.6, 3.35, -3.1), (4.6, 3.35, -3.1), (4.6, 3.35, 3.1), (-4.6, 3.35, 3.1),
            (-4.6, 4.55, 0), (4.6, 4.55, 0)], roof)
    m.box((0, 4.62, 0), (9.2, 0.14, 0.4), "#8A3E1C")  # ridge cap
    for x in (-2.8, -0.2, 2.4):  # rooftop vents
        m.box((x, 4.0, 1.4), (0.8, 0.5, 0.8), "#6E6455", bevel=0.05, rot=(0, 0, 0))
    m.box((1.7, 4.8, -1.2), (0.7, 0.7, 0.7), "#7A7064")
    # big door + windows
    m.box((-1.0, 1.35, 2.92), (3.0, 2.7, 0.14), "#3C3430")
    m.box((-1.0, 1.35, 2.99), (0.08, 2.7, 0.06), "#2A2420")
    for x in (2.2, 3.4, -4.1 + 0.0):
        m.box((x, 2.4, 2.92), (0.8, 0.6, 0.1), WIN)
    for x in (-3.2, -2.0, 0.0, 1.2):
        m.box((x, 2.9, -2.92), (0.8, 0.5, 0.1), WIN)
    for z in (-1.2, 1.2):
        m.box((4.42, 2.4, z), (0.1, 0.6, 0.8), WIN)
        m.box((-4.42, 2.4, z), (0.1, 0.6, 0.8), WIN)
    m.box((-4.0, 0.35, 3.6), (1.4, 0.7, 0.9), "#6E6455", rot=(0, 15, 0), bevel=0.05)  # crates
    m.box((-3.4, 0.9, 3.6), (0.8, 0.5, 0.8), "#8A6B3A", rot=(0, 30, 0), bevel=0.04)
    m.fit(size=(9, 5, 6), recenter_xz=True)
    return m


def barrier_a():
    m = Model("barrier_a")
    white, red = "#F2F2F2", "#D9382F"
    L = 2.0
    m.frustum((0, 0, 0), (0.7, L), (0.62, L), 0.28, white)
    m.frustum((0, 0.28, 0), (0.66, L + 0.02), (0.5, L + 0.02), 0.26, red)
    m.frustum((0, 0.54, 0), (0.5, L), (0.3, L), 0.31, white)
    m.box((0, 0.84, 0), (0.28, 0.04, L - 0.06), shade(white, 0.9))
    m.fit(size=(0.7, 0.85, 2.0), recenter_xz=True)
    return m


def barrier_b():
    m = Model("barrier_b")
    a, b = "#CDB17B", "#B89A62"
    h = 0.27
    for i, z in enumerate((-0.67, 0.0, 0.67)):
        m.box((0, h / 2, z), (0.8, h, 0.64), a if i % 2 == 0 else b, bevel=0.07)
    for i, z in enumerate((-0.33, 0.33)):
        m.box((0, h * 1.5, z), (0.74, h, 0.64), b if i % 2 == 0 else a, bevel=0.07)
    m.box((0, h * 2.5, 0), (0.68, h, 0.66), a, bevel=0.07)
    m.fit(size=(0.8, 0.8, 2.0), recenter_xz=True)
    return m


def spike_wall():
    m = Model("spike_wall")
    W = 3.5
    m.box((0, 0.15, 0), (W, 0.3, 0.9), "#1F1416")  # black lower base
    m.box((0, 0.45, 0), (W, 0.3, 0.9), "#B22A2A")  # red upper base
    m.box((0, 0.3, 0.451), (W, 0.12, 0.02), "#F2C21A")  # yellow warning stripe (front)
    m.box((0, 0.3, -0.451), (W, 0.12, 0.02), "#F2C21A")
    n = 6
    step = W / n
    for i in range(n):
        x = -W / 2 + step * (i + 0.5)
        m.pyramid((x, 0.6, 0), (0.44, 0.44), 0.7, "#C8CED9")
    # keep exact tile width: no overhang beyond +-W/2
    m.fit(size=(W, 1.3, 0.9), recenter_xz=True)
    return m


def gate_pillar():
    m = Model("gate_pillar")
    navy, dark, yel = "#27408B", "#1B2C63", "#F2C21A"
    m.box((0, 0.15, 0), (0.5, 0.3, 0.5), dark, bevel=0.04)
    m.box((0, 0.37, 0), (0.54, 0.14, 0.54), yel)
    m.box((0, 1.7, 0), (0.38, 2.52, 0.38), navy, bevel=0.03)
    m.box((0, 3.03, 0), (0.54, 0.14, 0.54), yel)
    m.box((0, 3.25, 0), (0.5, 0.3, 0.5), dark, bevel=0.04)
    m.fit(size=(0.5, 3.4, 0.5), recenter_xz=True)
    return m


PROPS = {
    "barrier_a": barrier_a, "barrier_b": barrier_b, "spike_wall": spike_wall,
}
