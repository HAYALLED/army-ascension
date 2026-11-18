"""Road, boss arena, buff gate pieces. One mesh each, origin bottom-center, front +Z.
Tileable pieces are built so that the z = -L/2 and z = +L/2 edges are identical."""
from glbkit import Model, shade

NAVY, NAVY_L, YEL, BLACK = "#1F2A47", "#34457A", "#F2BF1A", "#1A1A1F"
STEEL_D, STEEL_L, STEEL_M = "#262830", "#3B3E4A", "#454857"
RED = "#FF3A2A"


def para(m, plane, a, w, lo, hi, shear, d0, d1, color):
    """Parallelogram stripe prism. plane maps (P=stripe axis, A=along axis, D=depth axis):
    'xz': P=x A=z D=y | 'xy': P=x A=y D=z | 'zy': P=z A=y D=x."""
    pts = []
    for A, sh in ((lo, 0.0), (hi, shear)):
        for P in (a + sh, a + sh + w):
            for D in (d0, d1):
                pts.append({"xz": (P, D, A), "xy": (P, A, D), "zy": (D, A, P)}[plane])
    m.hull(pts, color)


def stripes(m, plane, start, n, pitch, w, lo, hi, shear, d0, d1, color):
    for i in range(n):
        para(m, plane, start + i * pitch, w, lo, hi, shear, d0, d1, color)


# ------------------------------------------------------------------ road
def road_tile():
    m = Model("road_tile")
    m.optimize = True
    W, L, g = 14.4, 10.0, 0.06
    m.box((0, 0.04, 0), (W, 0.08, L), "#8F7F5C")  # groove floor (darker)
    cols = 6
    pitch = W / cols
    shades = {0: ("#C7B58F", "#B9A67E"), 1: ("#C7B58F", "#B9A67E"), 2: ("#B3A17B", "#A89670"),
              3: ("#B3A17B", "#A89670"), 4: ("#C7B58F", "#B9A67E"), 5: ("#C7B58F", "#B9A67E")}  # middle = worn strip
    for c in range(cols):
        x = -W / 2 + pitch * (c + 0.5)
        bounds = [-5, -2.5, 0, 2.5, 5] if c % 2 == 0 else [-5, -3.75, -1.25, 1.25, 3.75, 5]  # brick bond
        for r in range(len(bounds) - 1):
            za, zb = bounds[r] + g / 2, bounds[r + 1] - g / 2
            w = pitch - g
            m.frustum((x, 0.0, (za + zb) / 2), (w, zb - za), (w - 0.05, zb - za - 0.05), 0.108,
                      shades[c][(r + c) % 2])
    for sx in (-1, 1):  # dashed lane lines, period 2.5 divides 10 -> seamless
        for k in range(4):
            m.box((sx * 6.3, 0.114, -3.75 + 2.5 * k), (0.16, 0.012, 1.5), "#F2F0E8")
    m.fit(size=(W, 0.12, L), recenter_xz=True)
    return m


# ----------------------------------------------------------- arena floor
def arena_floor_tile():
    m = Model("arena_floor_tile")
    m.optimize = True
    W, L = 14.4, 10.0
    m.box((0, 0.05, 0), (W, 0.1, L), "#23252F")
    # hazard bands on both edges (0.5 deep): identical at z=-5 and z=+5
    for z0, z1 in ((-5.0, -4.5), (5.0, 4.5)):  # z0 = outer edge -> identical edge profile on both sides
        m.box((0, 0.065, (z0 + z1) / 2), (W, 0.13, 0.5), BLACK)
        stripes(m, "xz", -7.075, 16, 0.88, 0.45, z0, z1, 0.5, 0.13, 0.14, "#F2BF1A")
    # steel plates 3 x 3 between the bands, red glow lines in the grooves
    xs, zs = (-4.8, 0.0, 4.8), (-3.0, 0.0, 3.0)
    for i, x in enumerate(xs):
        for j, z in enumerate(zs):
            col = "#3D4050" if (i + j) % 2 == 0 else "#464A5D"
            m.frustum((x, 0.0, z), (4.68, 2.88), (4.5, 2.7), 0.13, col)
            for sx in (-1, 1):
                for sz in (-1, 1):
                    m.box((x + sx * 2.0, 0.145, z + sz * 1.1), (0.14, 0.03, 0.14), "#5D6278")
    for x in (-2.4, 2.4):
        m.box((x, 0.105, 0), (0.06, 0.012, 9.0), "#E03A2C")
    for z in (-1.5, 1.5):
        m.box((0, 0.105, z), (14.4, 0.012, 0.06), "#E03A2C")
    m.fit(size=(W, 0.16, L), recenter_xz=True)
    return m


# ------------------------------------------------------------ arena wall
def arena_wall_side():
    """Inner (detailed) face = +X. Seamless along Z."""
    m = Model("arena_wall_side")
    m.optimize = True
    m.box((-0.03, 2.2, 0), (1.34, 4.4, 10.0), STEEL_D)  # body x -0.7 .. 0.64
    m.box((0, 4.5, 0), (1.4, 0.2, 10.0), STEEL_L)  # coping
    for k in range(8):  # battlements, pitch 1.25 -> seamless
        m.box((0, 4.8, -5 + 0.625 + 1.25 * k), (1.0, 0.4, 0.9), STEEL_L)
    # hazard band near the bottom (inner face)
    m.box((0.66, 0.5, 0), (0.04, 0.4, 10.0), BLACK)
    stripes(m, "zy", -4.95, 16, 0.625, 0.25, 0.3, 0.7, 0.3, 0.68, 0.70, YEL)
    # concrete block courses (inner face)
    for (y0, y1) in ((0.95, 1.75), (3.65, 4.4)):
        for k in range(8):
            za = -5 + 1.25 * k + 0.03
            m.box((0.66, (y0 + y1) / 2, za + 0.595), (0.04, y1 - y0, 1.19), STEEL_L)
    # glowing red slit windows every 2.5 m
    for k in range(4):
        z = -3.75 + 2.5 * k
        m.box((0.66, 2.7, z), (0.04, 1.7, 0.6), "#15161C")
        m.box((0.69, 2.7, z), (0.02, 1.4, 0.3), RED)
    m.fit(size=(1.4, 5.0, 10.0), recenter_xz=True)
    return m


def arena_wall_back():
    """Layers on the +Z face: wall front 0.85, towers front 0.90, plates +0.05, stripes/rivets/emblem to 1.0."""
    m = Model("arena_wall_back")
    m.optimize = True
    m.box((0, 4.0, -0.075), (24.0, 8.0, 1.85), STEEL_D)  # main wall z -1.0 .. 0.85
    m.box((0, 8.1, 0), (24.0, 0.2, 2.0), STEEL_L)  # coping
    for k in range(13):
        m.box((-9.6 + 1.6 * k, 8.5, 0), (0.9, 0.6, 1.0), STEEL_L)
    for sx in (-1, 1):  # chunky end towers
        tx = sx * 10.4
        m.box((tx, 4.6, -0.05), (3.2, 9.2, 1.9), STEEL_D)  # z -1.0 .. 0.90
        m.box((tx, 9.3, 0), (3.4, 0.2, 2.2), STEEL_L)
        for dx in (-1.1, 0, 1.1):
            for dz in (-0.7, 0.7):
                m.box((tx + dx, 9.7, dz), (0.8, 0.6, 0.6), STEEL_L)
        m.box((tx, 0.7, 0.925), (3.2, 0.6, 0.05), BLACK)  # hazard band
        stripes(m, "xy", tx - 1.55, 8, 0.4, 0.2, 0.4, 1.0, 0.3, 0.95, 1.0, YEL)
        for y in (3.4, 5.6, 7.8):  # red slits
            m.box((tx, y, 0.94), (0.7, 1.7, 0.08), "#15161C")
            m.box((tx, y, 0.98), (0.3, 1.4, 0.04), RED)
        for y in (2.0, 9.0):
            for dx in (-1.3, 1.3):
                m.box((tx + dx, y, 0.95), (0.2, 0.2, 0.1), STEEL_M)
    m.box((0, 7.5, 0.875), (17.6, 0.7, 0.05), BLACK)  # warning stripes along the top
    stripes(m, "xy", -8.7, 21, 0.8, 0.4, 7.15, 7.85, 0.35, 0.9, 0.97, RED)
    m.box((0, 3.4, 0.885), (8.8, 6.8, 0.07), STEEL_M)  # door frame  (0.85 .. 0.92)
    for sx in (-1, 1):
        m.box((sx * 1.9, 3.2, 0.9), (3.6, 6.4, 0.05), "#1C1D25")  # door panel (0.875 .. 0.925)
        for r in range(5):
            for dx in (-1.35, 1.35):
                m.box((sx * 1.9 + dx, 0.7 + r * 1.2, 0.95), (0.2, 0.2, 0.1), STEEL_M)
    m.box((0, 3.2, 0.95), (0.14, 6.4, 0.06), "#0E0F14")  # door seam
    # angry robot face emblem across both doors
    m.box((0, 4.5, 0.955), (5.0, 3.3, 0.06), STEEL_M, bevel=0.04)  # head (0.925 .. 0.985)
    for sx in (-1, 1):
        m.box((sx * 1.15, 4.95, 0.99), (1.3, 0.34, 0.02), RED, rot=(0, 0, -sx * 16))
        m.pyramid((sx * 2.0, 6.0, 0.94), (0.7, 0.2), 1.4, STEEL_M, rot=(0, 0, -sx * 22))
    m.box((0, 3.45, 0.99), (2.3, 0.7, 0.02), "#15161C")
    for i in range(5):
        m.box((-0.86 + i * 0.43, 3.45, 1.0), (0.17, 0.56, 0.02), "#8D93A8")
    m.fit(size=(24, 10, 2), recenter_xz=True)
    return m


def arena_entrance():
    """Open underneath: nothing below y=5 between the towers (clear opening 14.4 x 5)."""
    m = Model("arena_entrance")
    for sx in (-1, 1):
        tx = sx * 7.85
        m.box((tx, 3.4, 0), (1.3, 6.8, 1.4), STEEL_D)  # z -0.7 .. 0.7
        m.box((tx, 6.9, 0), (1.3, 0.2, 1.5), STEEL_L)
        m.box((tx, 0.9, 0.715), (1.3, 1.0, 0.03), BLACK)  # hazard band (0.70 .. 0.73)
        stripes(m, "xy", tx - 0.63, 4, 0.3, 0.16, 0.4, 1.4, 0.2, 0.73, 0.75, YEL)
        for k, c in enumerate((RED, YEL)):  # warning light blocks on the tower corners
            for z in (0.35, -0.35):
                m.box((tx + (k * 2 - 1) * 0.35, 7.25, z), (0.4, 0.5, 0.4), c, bevel=0.04)
        for y in (2.5, 4.4):
            m.box((tx, y, 0.72), (0.5, 0.5, 0.04), "#15161C")
            m.box((tx, y, 0.735), (0.22, 0.3, 0.03), RED)
    m.box((0, 5.9, 0), (17.0, 1.8, 1.3), STEEL_D)  # beam: underside y = 5.0, z -0.65 .. 0.65
    m.box((0, 6.9, 0), (17.0, 0.2, 1.5), STEEL_L)
    for sx in (-1, 1):  # warning lights beside the emblem
        for k in range(3):
            m.box((sx * (4.2 + k * 1.3), 5.9, 0.685), (0.7, 0.7, 0.07), RED if k % 2 == 0 else YEL)
    m.box((0, 6.0, 0.685), (3.0, 1.3, 0.07), STEEL_M, bevel=0.03)  # robot skull (0.65 .. 0.72)
    m.box((0, 5.3, 0.685), (1.8, 0.4, 0.07), STEEL_M)
    for sx in (-1, 1):
        m.box((sx * 0.7, 6.15, 0.735), (0.8, 0.22, 0.03), RED, rot=(0, 0, -sx * 16))
        m.pyramid((sx * 1.5, 6.55, 0.67), (0.4, 0.14), 0.8, STEEL_M, rot=(0, 0, -sx * 24))
    for i in range(4):
        m.box((-0.45 + i * 0.3, 5.3, 0.735), (0.12, 0.3, 0.03), "#8D93A8")
    m.fit(size=(17, 7.5, 1.5), recenter_xz=True)
    return m


# ------------------------------------------------------------- buff gate
def gate_pillar():
    m = Model("gate_pillar")
    m.box((0, 0.15, 0), (0.5, 0.3, 0.5), "#16203A", bevel=0.04)  # slightly wider base
    m.box((0, 0.37, 0), (0.46, 0.14, 0.46), YEL)
    m.box((0, 1.8, 0), (0.36, 2.72, 0.36), NAVY, bevel=0.03)
    m.box((0, 3.23, 0), (0.46, 0.14, 0.46), YEL)
    m.box((0, 3.45, 0), (0.42, 0.3, 0.42), "#16203A", bevel=0.04)
    for y in (0.9, 2.7):  # small square bolts on the shaft
        for sx in (-1, 1):
            m.box((sx * 0.1, y, 0.19), (0.07, 0.07, 0.03), NAVY_L)
            m.box((sx * 0.1, y, -0.19), (0.07, 0.07, 0.03), NAVY_L)
    m.fit(size=(0.5, 3.6, 0.5), recenter_xz=True)
    return m


def gate_beam():
    m = Model("gate_beam")
    m.box((0, 0.25, 0), (14.4, 0.3, 0.46), NAVY)  # main beam y 0.1 .. 0.4
    for sx in (-1, 1):  # hazard-striped end caps
        cx = sx * 6.6
        m.box((cx, 0.25, 0), (1.2, 0.3, 0.48), BLACK)
        stripes(m, "xy", cx - 0.48, 4, 0.24, 0.12, 0.1, 0.4, 0.12, 0.24, 0.25, YEL)
        stripes(m, "xy", cx - 0.48, 4, 0.24, 0.12, 0.1, 0.4, 0.12, -0.25, -0.24, YEL)
    for x in (-6, -3, 0, 3, 6):  # mounting hooks underneath every 3 m
        m.box((x, 0.05, 0), (0.16, 0.1, 0.16), NAVY_L)
    m.fit(size=(14.4, 0.4, 0.5), recenter_xz=True)
    return m


def gate_panel():
    """Frame (palette material 'Frame') + flat white 'Tint' screen (own material). Bottom edge = 0."""
    m = Model("gate_panel")
    W, H = 6.2, 1.4
    m.box((0, 0.11, 0), (W, 0.22, 0.2), NAVY, bevel=0.03)  # bottom bar
    m.box((0, H - 0.11, 0), (W, 0.22, 0.2), NAVY, bevel=0.03)  # top bar
    for sx in (-1, 1):
        m.box((sx * (W / 2 - 0.15), H / 2, 0), (0.3, H - 0.4, 0.2), NAVY)  # side bars
        for sy in (0.16, H - 0.16):  # yellow square corner bolts, both faces
            m.box((sx * (W / 2 - 0.2), sy, 0.11), (0.18, 0.18, 0.03), YEL)
            m.box((sx * (W / 2 - 0.2), sy, -0.11), (0.18, 0.18, 0.03), YEL)
        for k in range(2):  # two short chain links on top
            m.box((sx * 2.3, H + 0.08 + k * 0.14, 0), (0.14 if k == 0 else 0.1, 0.14, 0.1 if k == 0 else 0.14), "#AEB6C8")
    # flat white screen, recessed 0.02 inside the frame on both sides
    m.hull([(x, y, z) for x in (-2.8, 2.8) for y in (0.22, H - 0.22) for z in (-0.08, 0.08)], "TINT")
    m.fit(size=(6.2, 1.7, 0.25), recenter_xz=True)
    return m


ENV = {f.__name__: f for f in (road_tile, arena_floor_tile, arena_wall_side, arena_wall_back, arena_entrance,
                               gate_pillar, gate_beam, gate_panel)}
