"""52 mini bosses (chapters 4-16): 4 role templates (SLAM / GUN / BOMB / CMD) x 13 themes.
Build space ~metres, front +Z, right hand = -X, then fit(height). Every part touches the body."""
import math
import numpy as np
from glbkit import Model, shade

W = "#FFFFFF"
K = "#16121C"


def dk(c, f=0.7):
    return shade(c, f)


def lt(c, f=1.25):
    return shade(c, f)


# ------------------------------------------------------------------ face + hats
def face(m, cy, w, h, d, z0=0.0, eye="#FFE63B", brow=K, mouth="fangs", mc="#2A1010", n=2, angry=True, ey=0.12,
         eye_dark=None):
    fz = z0 + d / 2 + 0.01
    xs = (-1, 1) if n == 2 else (0,)
    for sx in xs:
        ex = sx * w * 0.22 if n == 2 else 0
        sz = (w * 0.17, h * 0.15) if n == 2 else (w * 0.3, h * 0.24)
        m.box((ex, cy + h * ey, fz), (sz[0], sz[1], 0.05), eye)
        if eye_dark:
            m.box((ex, cy + h * ey, fz + 0.02), (sz[0] * 0.4, sz[1] * 0.6, 0.04), eye_dark)
        if angry and n == 2:
            m.box((ex, cy + h * (ey + 0.17), fz - 0.01), (w * 0.22, h * 0.07, 0.06), brow, rot=(0, 0, -sx * 22))
    if mouth == "fangs":
        m.box((0, cy - h * 0.25, fz), (w * 0.5, h * 0.1, 0.05), mc)
        for sx in (-1, 1):
            m.pyramid((sx * w * 0.15, cy - h * 0.2, fz + 0.01), (w * 0.08, w * 0.08), h * 0.14, W, rot=(180, 0, 0))
    elif mouth == "grin":
        m.box((0, cy - h * 0.26, fz), (w * 0.62, h * 0.14, 0.05), mc)
        for i in range(5):
            m.box((-w * 0.24 + i * w * 0.12, cy - h * 0.23, fz + 0.02), (w * 0.07, h * 0.09, 0.04), W)
    elif mouth == "bar":
        m.box((0, cy - h * 0.25, fz), (w * 0.4, h * 0.07, 0.05), mc)


def hat(m, kind, cy, w, h, d, c1, c2=None, z0=0.0):
    top = cy + h / 2
    c2 = c2 or dk(c1)
    if kind == "witch":
        m.box((0, top, z0), (w + 0.7, 0.12, d + 0.7), c1, bevel=0.03)
        m.frustum((0, top, z0), (w * 0.8, d * 0.8), (w * 0.4, d * 0.4), 0.8, c1)
        m.frustum((0, top + 0.78, z0), (w * 0.4, d * 0.4), (w * 0.2, d * 0.2), 0.5, c1, top_off=(0.25, 0))
        m.box((0, top + 0.18, z0 + d * 0.4 + 0.02), (w * 0.8, 0.16, 0.06), c2)
        m.box((0, top + 0.18, z0 + d * 0.4 + 0.05), (0.2, 0.18, 0.04), "#F2C21A")
    elif kind == "tricorn":
        m.box((0, top, z0), (w + 0.7, 0.12, d + 0.6), c1, bevel=0.03)
        for sx in (-1, 1):
            m.box((sx * (w + 0.7) / 2, top + 0.12, z0), (0.3, 0.12, d + 0.6), c1, rot=(0, 0, -sx * 30))
        m.box((0, top + 0.14, z0 + d / 2 + 0.3), (w + 0.4, 0.12, 0.3), c1, rot=(-30, 0, 0))
        m.frustum((0, top, z0), (w * 0.9, d * 0.9), (w * 0.7, d * 0.7), 0.4, c1)
        m.box((0, top + 0.12, z0), (w * 0.92, 0.1, d * 0.92), c2)
    elif kind == "cap":
        m.box((0, top, z0), (w + 0.1, 0.18, d + 0.1), c2, bevel=0.03)
        m.frustum((0, top + 0.05, z0), (w * 0.95, d * 0.95), (w * 0.7, d * 0.7), 0.45, c1)
    elif kind == "peaked":
        m.frustum((0, top, z0), (w + 0.1, d + 0.1), (w * 0.9, d * 0.9), 0.5, c1)
        m.box((0, top + 0.05, z0 + d / 2 + 0.2), (w * 0.8, 0.1, 0.45), c2)
        m.box((0, top + 0.3, z0 + d / 2 + 0.05), (0.3, 0.3, 0.06), "#F2C21A")
    elif kind == "spikecrown":
        m.box((0, top + 0.05, z0), (w + 0.1, 0.35, d + 0.1), c1, bevel=0.03)
        for i, x in enumerate((-0.5, -0.25, 0, 0.25, 0.5)):
            m.pyramid((x * w, top + 0.2, z0), (0.28, 0.28), 0.5 + (0.3 if i == 2 else 0) + (0.1 if i % 2 == 0 else 0), c1)
    elif kind == "horns":
        for sx in (-1, 1):
            m.pyramid((sx * w * 0.38, top - 0.05, z0), (0.4, 0.4), 0.8, c1, rot=(0, 0, -sx * 26))
    elif kind == "ears":
        for sx in (-1, 1):
            m.pyramid((sx * w * 0.36, top - 0.05, z0), (0.45, 0.35), 1.0, c1, rot=(0, 0, -sx * 8))
    elif kind == "hardhat":
        m.frustum((0, top, z0), (w + 0.2, d + 0.2), (w * 0.8, d * 0.8), 0.5, c1)
        m.box((0, top, z0 + d / 2 + 0.15), (w + 0.2, 0.1, 0.4), c2)
        m.box((0, top + 0.5, z0), (0.2, 0.35, 0.6), "#FF3A2A")
        m.box((0, top + 0.28, z0), (0.1, 0.6, 0.2), c2)
    elif kind == "bicorne":
        m.box((0, top + 0.2, z0), (w * 1.5, 0.5, d * 0.6), c1, bevel=0.05)
        for sx in (-1, 1):
            m.pyramid((sx * w * 0.75, top + 0.2, z0), (0.4, d * 0.5), 0.45, c1, rot=(0, 0, -sx * 90))
        m.box((0, top + 0.2, z0 + d * 0.3 + 0.02), (w * 1.4, 0.1, 0.05), c2)
    elif kind == "headdress":  # nemes / striped pharaoh
        m.box((0, top - 0.1, z0), (w + 0.3, 0.35, d + 0.3), c1, bevel=0.05)
        for sx in (-1, 1):
            m.box((sx * (w / 2 + 0.2), cy - h * 0.1, z0 - 0.05), (0.3, h * 1.0, d * 0.9), c1)
            for k in range(3):
                m.box((sx * (w / 2 + 0.2), cy + h * 0.25 - k * 0.3, z0 + 0.1), (0.32, 0.12, d * 0.9), c2)
        m.box((0, cy, z0 - d / 2 - 0.15), (w + 0.5, h * 1.1, 0.3), c1)
    elif kind == "dcrown":  # double crown
        m.frustum((0, top, z0), (w * 0.7, d * 0.7), (w * 0.55, d * 0.55), 0.9, c1)
        m.frustum((0, top + 0.9, z0), (w * 0.55, d * 0.55), (w * 0.3, d * 0.3), 0.45, c1)
        m.ball((0, top + 1.45, z0), 0.2, c2, seg=5, rings=2)
        m.box((0, top, z0), (w * 0.92, 0.25, d * 0.92), c2)
    elif kind == "iron":
        m.frustum((0, top, z0), (w + 0.1, d + 0.1), (w * 0.9, d * 0.9), 0.3, c2)
        for i in (-2, -1, 0, 1, 2):
            m.pyramid((i * w * 0.2, top + 0.25, z0), (0.3, 0.3), 0.9 if i == 0 else 0.6, c1)
    elif kind == "cattail":
        pass


def pole_flag(m, base, top, flag_c, emblem=None, fw=1.7, fh=1.3, pc="#5A4630", out=-1, ec=None):
    """Pole from base to top; flag hangs below the top, streaming outward (out = -1 -> -X)."""
    m.limb(base, top, 0.22, pc)
    x, y, z = top
    m.ball((x, y + 0.12, z), 0.22, "#F2C21A", seg=6, rings=2)
    fx = x + out * (fw / 2 + 0.11)
    m.box((fx, y - fh / 2 - 0.1, z), (fw, fh, 0.1), flag_c)
    m.box((fx, y - 0.05, z), (fw, 0.1, 0.14), dk(flag_c, 0.7))
    if emblem:
        emblem(m, (fx, y - fh / 2 - 0.1, z + 0.07), fw, fh)


# emblems on flags / shields: drawn at c (front-facing plane)
def em_skull(m, c, w, h, col="#EFE6CF"):
    x, y, z = c
    m.box((x, y + h * 0.06, z), (w * 0.38, h * 0.32, 0.06), col)
    m.box((x, y - h * 0.16, z), (w * 0.24, h * 0.14, 0.06), col)
    for sx in (-1, 1):
        m.box((sx * w * 0.09 + x, y + h * 0.08, z + 0.03), (w * 0.09, h * 0.1, 0.05), "#16121C")


def em_star(m, c, w, h, col="#F2BF1A"):
    x, y, z = c
    m.box((x, y, z), (w * 0.4, h * 0.14, 0.06), col)
    m.box((x, y, z), (w * 0.14, h * 0.5, 0.06), col)
    m.box((x, y, z), (w * 0.34, h * 0.34, 0.06), col, rot=(0, 0, 45))


def em_anchor(m, c, w, h, col="#E8EDF5"):
    x, y, z = c
    m.box((x, y, z), (w * 0.1, h * 0.55, 0.06), col)
    m.box((x, y + h * 0.18, z), (w * 0.34, h * 0.09, 0.06), col)
    m.box((x, y - h * 0.22, z), (w * 0.42, h * 0.09, 0.06), col)


def em_flask(m, c, w, h, col="#E83DAE"):
    x, y, z = c
    m.box((x, y + h * 0.15, z), (w * 0.14, h * 0.3, 0.06), col)
    m.box((x, y - h * 0.12, z), (w * 0.4, h * 0.3, 0.06), col, rot=(0, 0, 0))


def em_leaf(m, c, w, h, col="#5CC24A"):
    x, y, z = c
    m.box((x, y, z), (w * 0.3, h * 0.55, 0.06), col, rot=(0, 0, 30))


def em_plain(m, c, w, h, col="#FFFFFF"):
    x, y, z = c
    m.box((x, y, z), (w * 0.3, h * 0.3, 0.06), col, rot=(0, 0, 45))


# ------------------------------------------------------------------ common limbs
def legs(m, x, col, boot, y_top=1.45, spread=0.7, wide=1.0):
    for sx in (-1, 1):
        m.box((sx * spread, 0.25, 0.25), (1.0 * wide, 0.5, 1.5), boot, bevel=0.08)
        m.box((sx * spread, 0.5 + (y_top - 0.5) / 2, 0.0), (0.95 * wide, y_top - 0.5, 0.95), col, bevel=0.06)


# ================================================================== SLAM
def slam(name, T):
    m = Model(name)
    m.optimize = True
    body, dark, skin = T["body"], T.get("dark", dk(T["body"])), T.get("skin", T["body"])
    legs(m, 0, T.get("legc", dark), T.get("boot", dk(dark, 0.8)), spread=0.65)
    m.box((0, 1.65, 0), (2.0, 0.5, 1.3), dark, bevel=0.06)
    m.box((0, 2.45, 0.05), (2.3, 1.4, 1.5), body, bevel=0.1)
    if T.get("belly"):
        m.box((0, 1.95, 0.76), (1.4, 0.4, 0.08), T["belly"])
        if T.get("belly_stripes"):
            for i in range(5):
                m.box((-0.5 + i * 0.25, 1.95, 0.8), (0.12, 0.42, 0.05), T["belly_stripes"], rot=(0, 0, 25))
    sh = T.get("shoulder", body)
    sd = T.get("side", -1)  # side of the weapon: -1 = right hand (-X)
    for sx in (-1, 1):
        m.ball((sx * 1.2, 3.0, 0), 0.62, sh, seg=8, rings=3)
    hc = T["head"]
    hy = 3.5
    HW, HH, HD = 1.9, 1.55, 1.6
    m.box((0, hy, 0.25), (HW, HH, HD), hc, bevel=0.1)
    if T.get("hat"):
        T["hat"](m, hy, HW, HH, HD, 0.25)
    if T.get("face_fn"):
        T["face_fn"](m, hy, HW, HH, HD, 0.25)
    else:
        face(m, hy, HW, HH, HD, z0=0.25, eye=T["eye"], brow=T.get("brow", K), mouth=T.get("mouth", "fangs"),
             mc=T.get("mc", "#2A1010"))
    # left (weapon-free) arm: giant fist hanging forward; right: raised, grips shaft
    fist = T.get("fist", skin)
    free = -sd
    m.limb((free * 1.35, 3.0, 0), (free * 1.5, 1.8, 0.7), 0.9, T.get("arm", body), bevel=0.08)
    if T.get("pincer"):
        T["pincer"](m, free, fist)
    else:
        m.box((free * 1.5, 1.25, 0.8), (1.25, 1.1, 1.2), fist, bevel=0.12)
    H = (sd * 1.55, 1.85, 0.6)
    top = (sd * 1.45, 4.1, -0.15)
    m.limb((sd * 1.35, 3.0, 0), H, 0.9, T.get("arm", body), bevel=0.08)
    w = T.get("wp")
    if T.get("pincer"):
        T["pincer"](m, sd, fist)
    elif w:
        if not T.get("ball"):
            m.box((H[0], H[1] - 0.1, H[2]), (1.2, 1.1, 1.2), fist, bevel=0.12)
            m.limb((H[0], H[1] + 0.2, H[2]), top, 0.26, T.get("shaft", "#5A4630"))
        sc = T.get("wscale", 1.35)
        with Model._Group(m, np.eye(3) * sc, top, False):
            w(m, top, H)
    if T.get("ext"):
        T["ext"](m)
    m.fit(height=4.2)
    return m


def wp_slab(col, line, cross=True):
    def f(m, t, h):
        x, y, z = t
        m.box((x, y, z), (1.7, 1.4, 0.5), col, bevel=0.08)
        if cross:
            m.box((x, y, z + 0.27), (0.12, 0.9, 0.05), line)
            m.box((x, y + 0.15, z + 0.27), (0.6, 0.12, 0.05), line)
            m.box((x + 0.35, y - 0.35, z + 0.27), (0.4, 0.07, 0.05), line, rot=(0, 0, 40))
    return f


def wp_lid(col, trim):
    def f(m, t, h):
        x, y, z = t
        m.frustum((x, y - 0.8, z), (1.0, 0.5), (1.3, 0.55), 1.9, col)
        m.box((x, y + 0.95, z), (1.3, 0.15, 0.6), trim)
        m.box((x, y + 0.2, z + 0.3), (0.5, 0.5, 0.06), trim)
        m.box((x, y - 0.5, z + 0.3), (0.6, 0.1, 0.06), trim)
        m.box((x, y - 0.8, z + 0.3), (0.8, 0.1, 0.06), trim)
    return f


def wp_log(col, moss):
    def f(m, t, h):
        x, y, z = t
        m.frustum((x, y - 0.9, z), (0.45, 0.45), (1.3, 1.3), 2.0, col, top_off=(0, 0))
        for dx, dy, dz in ((0.7, 0.2, 0), (-0.7, -0.2, 0.1), (0.1, 0.4, 0.7), (0, -0.3, -0.7)):
            m.box((x + dx, y + dy, z + dz), (0.35, 0.35, 0.35), dk(col, 0.8))
        m.box((x, y + 0.2, z), (1.35, 0.3, 1.35), moss)
    return f


def wp_baton(col, core):
    def f(m, t, h):
        x, y, z = t
        m.cyl((x, y - 0.1, z), 0.38, 2.4, col, sides=8)
        m.cyl((x, y - 0.1, z), 0.25, 2.5, core, sides=8)
        for yy in (-1.1, 1.0):
            m.cyl((x, y + yy, z), 0.46, 0.25, dk(col, 0.6), sides=8)
    return f


def wp_wrench(col, stripe):
    def f(m, t, h):
        x, y, z = t
        m.box((x, y, z), (1.3, 1.2, 0.55), col, bevel=0.06)
        m.box((x, y + 0.3, z + 0.01), (0.55, 0.65, 0.6), "#3A3A44")
        m.box((x, y - 0.4, z + 0.3), (1.3, 0.2, 0.06), stripe)
        m.box((x, y - 0.1, z + 0.3), (1.3, 0.2, 0.06), stripe)
    return f


def wp_barrels(col, band, glow):
    def f(m, t, h):
        x, y, z = t
        for sx in (-1, 1):
            m.cyl((x + sx * 0.62, y, z), 0.55, 1.2, col, sides=8, rot=(0, 0, 0))
            m.cyl((x + sx * 0.62, y + 0.35, z), 0.57, 0.14, band, sides=8)
            m.cyl((x + sx * 0.62, y - 0.35, z), 0.57, 0.14, band, sides=8)
            m.box((x + sx * 0.62, y + 0.62, z), (0.5, 0.06, 0.5), glow)
        m.box((x, y, z), (1.3, 0.3, 0.3), "#44464E")
    return f


def wp_crystal(col, club):
    def f(m, t, h):
        x, y, z = t
        m.frustum((x, y - 0.9, z), (0.45, 0.45), (1.3, 1.3), 1.8, club)
        for dx, dz, hh in ((0, 0, 1.3), (0.5, 0.3, 0.9), (-0.5, -0.3, 0.9), (0.4, -0.45, 0.7), (-0.4, 0.45, 0.7)):
            m.pyramid((x + dx, y + 0.8, z + dz), (0.45, 0.45), hh, col)
    return f


def wp_anchor(col, chain):
    def f(m, t, h):
        x, y, z = t
        m.box((x, y - 0.7, z), (0.35, 1.7, 0.35), col)
        m.box((x, y + 0.1, z), (1.6, 0.3, 0.3), col)  # stock
        for sx in (-1, 1):
            m.box((x + sx * 0.6, y - 1.5, z), (0.55, 0.3, 0.3), col, rot=(0, 0, -sx * 35))
            m.pyramid((x + sx * 0.95, y - 1.3, z), (0.5, 0.35), 0.5, col, rot=(0, 0, -sx * 45))
        m.ball((x, y + 0.5, z), 0.3, chain, seg=5, rings=2)
    return f


def wp_obsidian(col, glow):
    def f(m, t, h):
        x, y, z = t
        m.box((x, y, z), (1.7, 1.2, 1.0), col, bevel=0.05)
        for dx in (-0.6, 0, 0.6):
            m.pyramid((x + dx, y + 0.6, z), (0.5, 0.5), 0.6, col)
        m.box((x, y, z + 0.51), (1.2, 0.08, 0.05), glow, rot=(0, 0, 14))
        m.box((x, y - 0.1, z + 0.51), (0.08, 0.7, 0.05), glow)
    return f


def wp_jaws(col):
    return None


def wp_ball(col, chain):
    def f(m, t, h):
        # wrecking ball hangs from the raised-free right hand and rests on the ground
        bx, by, bz = h[0] * 1.15, 0.9, 1.5
        m.ball((bx, by, bz), 0.9, col, seg=8, rings=3)
        m.box((bx, by + 0.95, bz), (0.5, 0.3, 0.5), dk(col, 0.7))
        m.limb((h[0], h[1], h[2]), (bx, by + 1.05, bz), 0.22, chain)
        m.box((h[0], h[1] - 0.1, h[2]), (1.2, 1.1, 1.2), dk(col, 1.0))
    return f


def S(body, head, eye, **kw):
    return dict(body=body, head=head, eye=eye, **kw)


# ------------------------------------------------------------------ SLAM themes
def th_gravedigger():
    def ext(m):
        m.limb((0.6, 1.5, -0.8), (0.9, 4.2, -1.0), 0.18, "#5A4630")
        m.box((0.9, 4.35, -1.0), (0.7, 0.7, 0.1), "#8C8F99")
        m.box((0, 2.9, -0.85), (1.6, 1.2, 0.2), "#6A4A2A")
        m.box((0, 3.05, 0.2), (1.9, 0.35, 1.7), "#6B3FA0")  # scarf
        m.box((0.7, 2.45, 0.85), (0.35, 1.2, 0.1), "#6B3FA0")
    return S("#8A6A45", "#B9C79A", "#2A1B10", wp=wp_slab("#8C8F99", "#5B5E68"), fist="#B9C79A", ext=ext,
             boot="#3A2A1B", belly="#6A4F32", arm="#8A6A45", brow="#3A3A2A")


def th_sarcophagus():
    def hat_(m, hy, w, h, d, z0):
        hat(m, "headdress", hy, w, h, d, "#E8B423", "#1FA7A0", z0=z0)
    def ext(m):
        for y in (2.0, 3.0):
            m.box((0, y, 0.05), (2.4, 0.2, 1.55), "#1FA7A0")
    return S("#D8B777", "#D8B777", "#FFC02E", wp=wp_lid("#B97A34", "#E8B423"), hat=hat_, ext=ext, mouth="bar",
             belly="#E8B423", brow="#8A5A20", dark="#B99A5A")


def th_bog():
    def ext(m):
        for sx in (-1, 1):
            for dx, hh in ((-0.3, 1.1), (0.2, 0.8), (0.4, 1.0)):
                m.box((sx * 1.2 + dx, 3.75 + hh / 2 - 0.1, -0.2), (0.14, hh, 0.14), "#6B4A2B")
                m.box((sx * 1.2 + dx, 3.75 + hh - 0.15, -0.2), (0.22, 0.5, 0.22), "#8A5A2B")
            m.box((sx * 1.2, 3.65, 0.1), (1.0, 0.25, 1.0), "#3F6B2A")
        m.box((0, 2.9, -0.9), (1.8, 1.2, 0.3), "#3F6B2A")
    return S("#5E8A3C", "#5E8A3C", "#5CFFD1", wp=wp_log("#6B4A2B", "#4A7A2A"), arm="#6B4A2B", fist="#6B4A2B", ext=ext,
             brow="#2A3F1A", dark="#3F6B2A", shaft="#6B4A2B")


def th_wrecker():
    def face_(m, hy, w, h, d, z0):
        m.box((0, hy, z0 + d / 2 + 0.02), (w * 0.9, h * 0.35, 0.1), "#2A2A30")
        for sx in (-1, 1):
            m.box((sx * w * 0.24, hy + 0.05, z0 + d / 2 + 0.08), (w * 0.2, h * 0.16, 0.05), "#FF5A1F")
        m.box((0.2, hy + 0.05, z0 + d / 2 + 0.11), (0.06, 0.5, 0.04), "#16121C", rot=(0, 0, 30))
        m.box((0, hy - h * 0.3, z0 + d / 2 + 0.02), (w * 0.5, h * 0.12, 0.05), "#16121C")
    def ext(m):
        for sx in (-1, 1):
            m.cyl((sx * 0.7, 3.1, -1.0), 0.18, 1.8, "#3E3A38", sides=6)
            m.cyl((sx * 0.7, 4.0, -1.0), 0.24, 0.2, "#16121C", sides=6)
    return S("#A8432C", "#A8432C", "#FF5A1F", wp=wp_ball("#6E7480", "#3E3A38"), ball=True, wscale=1.0, dark="#3E3A38", belly="#F2C21A",
             belly_stripes="#16121C", face_fn=face_, ext=ext, fist="#6E7480", arm="#A8432C")


def th_enforcer():
    def face_(m, hy, w, h, d, z0):
        m.box((0, hy + 0.05, z0 + d / 2 + 0.02), (w * 0.85, h * 0.2, 0.06), "#3DF2FF")
    def ext(m):
        m.box((0, 3.45, -0.55), (2.0, 1.0, 0.3), "#16162A")  # tall collar
        for sx in (-1, 1):
            m.box((sx * 1.15, 3.6, 0.0), (0.15, 0.7, 1.1), "#16162A")
        for y in (2.2, 2.6):
            m.box((0, y, 0.78), (1.6, 0.06, 0.05), "#3DF2FF")
        for sx in (-1, 1):
            m.box((sx * 0.5, 1.05, 0.5), (0.08, 1.0, 0.05), "#3DF2FF")
    return S("#1B1B2E", "#1B1B2E", "#3DF2FF", wp=wp_baton("#26263E", "#3DF2FF"), face_fn=face_, ext=ext, fist="#26263E",
             dark="#101020")


def th_airlock():
    def face_(m, hy, w, h, d, z0):
        m.box((0, hy, z0 + d / 2 + 0.02), (w * 0.8, h * 0.62, 0.08), "#2A3550")
        m.box((0, hy, z0 + d / 2 + 0.07), (w * 0.7, h * 0.52, 0.05), "#7DFFB0")
    def ext(m):
        m.box((0, 2.5, -1.0), (1.3, 1.6, 0.7), "#B0B8C8", bevel=0.1)
        for sx in (-1, 1):
            m.cyl((sx * 0.35, 2.5, -1.4), 0.32, 1.5, "#9AA6BA", sides=8)
    return S("#F0F2F7", "#F0F2F7", "#7DFFB0", wp=wp_wrench("#9AA6BA", "#F28C1F"), face_fn=face_, ext=ext, belly="#F28C1F",
             fist="#F0F2F7", dark="#C8CEDA", shaft="#9AA6BA")


def th_mandible():
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        for sx in (-1, 1):
            m.box((sx * w * 0.22, hy + 0.1, fz + 0.01), (w * 0.2, h * 0.17, 0.05), "#FFF04A")
            m.limb((sx * 0.35, hy - 0.3, fz), (sx * 0.9, hy - 0.45, fz + 0.9), 0.4, "#D9A81E")
            m.pyramid((sx * 0.9, hy - 0.45, fz + 0.9), (0.4, 0.4), 0.7, "#D9A81E", rot=(90, 0, sx * -25))
    def ext(m):
        m.box((0, 2.9, -0.85), (2.2, 1.6, 0.9), "#5A3A22", bevel=0.2)
        for i in (-2, 0, 2):
            m.box((i * 0.45, 3.0, -1.32), (0.25, 1.3, 0.1), "#D9A81E")
    return S("#5A3A22", "#5A3A22", "#FFF04A", wp=None, face_fn=face_, ext=ext, fist="#5A3A22",
             pincer=lambda m, s, f: m.box((s * 1.5, 1.25, 0.8), (1.35, 1.2, 1.3), "#4A2E1A", bevel=0.12), shoulder="#D9A81E",
             dark="#3F2815")


def th_sludge():
    def ext(m):
        for sx in (-1, 1):
            m.box((sx * 1.2, 3.65, 0.0), (1.2, 0.5, 1.1), "#B6E03A")
            for dx in (-0.3, 0.3):
                m.box((sx * 1.2 + dx, 3.2, 0.5), (0.2, 0.7, 0.2), "#B6E03A")
        m.box((0, 2.4, 0.78), (0.5, 0.6, 0.05), "#B6E03A")
    return S("#7A5C99", "#7A5C99", "#A6FF3A", wp=wp_barrels("#8A4B2A", "#44464E", "#A6FF3A"), side=1, ext=ext,
             fist="#7A5C99", brow="#2A1B3A", shaft="#6A6C74", dark="#5A4570")


def th_geode():
    def ext(m):
        for dx, dy, dz, hh, c in ((-0.8, 3.7, -0.6, 1.6, "#8E4FD0"), (0.2, 3.8, -0.7, 1.9, "#B070F0"), (0.9, 3.6, -0.5, 1.4, "#8E4FD0"),
                                 (-1.4, 3.7, 0.0, 1.3, "#B070F0"), (1.4, 3.7, 0.0, 1.2, "#8E4FD0")):
            m.pyramid((dx, dy, dz), (0.6, 0.6), hh, c, rot=(0, 0, dx * 4))
        m.box((0, 2.6, 0.78), (0.1, 1.0, 0.05), "#3A2D3F", rot=(0, 0, 20))
    return S("#6F6272", "#6B5B6E", "#FF7AD9", wp=wp_crystal("#8E4FD0", "#6F6272"), ext=ext, fist="#6B5B6E", dark="#4A3F4D",
             brow="#2A2030")


def th_anchor():
    def ext(m):
        for y in (2.1, 2.5, 2.9):
            m.box((0, y, 0.78), (2.2, 0.12, 0.05), "#F4F4F4")
        m.box((0, 2.0, 0.0), (2.1, 0.55, 1.35), "#1B2D55")
        m.box((0, 1.8, 0.7), (2.0, 0.15, 0.2), "#C9A24A")
        m.box((0, 3.95, 0.25), (1.7, 0.4, 1.5), "#D13833")  # bandana
        m.box((0.3, 3.7, -0.5), (0.4, 0.6, 0.1), "#D13833", rot=(0, 0, 15))
    return S("#2F5FA8", "#E8B98A", "#1B1B22", wp=wp_anchor("#6B6F7A", "#6B6F7A"), ext=ext, fist="#E8B98A", dark="#1B2D55",
             brow="#4A2A1A", mc="#6A2A2A")


def th_barnacle():
    def ext(m):
        for dx, dy, dz in ((-1.0, 3.2, 0.3), (0.8, 3.5, 0.5), (-0.6, 2.4, 0.78), (0.7, 2.2, 0.78), (1.1, 3.3, -0.4), (-1.3, 3.5, -0.2)):
            for k in range(3):
                m.pyramid((dx + k * 0.2, dy - k * 0.1, dz), (0.3, 0.3), 0.35, "#E8FFF5")
        for sx in (-1, 1):
            m.box((sx * 0.6, 2.9, 0.82), (0.2, 0.9, 0.1), "#2F6B5A", rot=(0, 0, sx * 10))
        m.box((0.4, 4.2, 0.3), (0.2, 0.8, 0.2), "#2F6B5A")
    return S("#7FC9BF", "#7FC9BF", "#E8FFF5", wp=wp_anchor("#9FB3B0", "#9FB3B0"), ext=ext, fist="#7FC9BF", dark="#5BA397",
             brow="#2F6B5A")


def th_crab():
    def pincer(m, s, f):
        m.box((s * 1.55, 1.2, 0.9), (1.2, 1.0, 1.4), "#C23F2A", bevel=0.1)
        m.box((s * 1.2, 1.2, 1.7), (0.55, 0.7, 1.0), "#C23F2A")
        m.box((s * 1.9, 1.2, 1.7), (0.55, 0.7, 1.0), "#C23F2A")
        m.pyramid((s * 1.2, 1.2, 2.2), (0.5, 0.6), 0.5, "#F4EAD0", rot=(90, 0, 0))
        m.pyramid((s * 1.9, 1.2, 2.2), (0.5, 0.6), 0.5, "#F4EAD0", rot=(90, 0, 0))
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        for sx in (-1, 1):
            m.limb((sx * 0.45, hy + 0.55, z0 + 0.2), (sx * 0.5, hy + 1.0, z0 + 0.3), 0.18, "#C23F2A")
            m.box((sx * 0.5, hy + 1.1, z0 + 0.3), (0.4, 0.4, 0.4), "#FFE63B")
            m.box((sx * 0.5, hy + 1.1, z0 + 0.52), (0.18, 0.18, 0.04), "#16121C")
            m.box((sx * w * 0.24, hy + 0.2, fz + 0.04), (0.2, 0.06, 0.06), "#16121C", rot=(0, 0, -sx * 22))
        m.box((0, hy - 0.3, fz + 0.02), (0.8, 0.14, 0.05), "#2A1010")
    def ext(m):
        for sx in (-1, 1):
            for z in (-0.4, 0.2):
                m.limb((sx * 1.0, 1.9, z), (sx * 1.7, 0.4, z + 0.1), 0.3, "#C23F2A")
        for dx, dy in ((-0.5, 2.8), (0.6, 2.2), (0.0, 3.0)):
            m.box((dx, dy, 0.8), (0.3, 0.3, 0.05), "#F4EAD0")
    return S("#E0553A", "#E0553A", "#FFE63B", wp=None, pincer=pincer, face_fn=face_, ext=ext, dark="#B8402A", arm="#E0553A",
             shoulder="#C23F2A")


def th_obsidian():
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        for sx in (-1, 1):
            m.box((sx * w * 0.22, hy + 0.1, fz + 0.02), (w * 0.18, h * 0.14, 0.05), "#B96CFF")
            m.box((sx * w * 0.22, hy + 0.3, fz + 0.02), (w * 0.22, h * 0.07, 0.06), "#0A0710", rot=(0, 0, -sx * 22))
        m.box((0, hy - 0.3, fz + 0.02), (w * 0.4, h * 0.08, 0.05), "#B96CFF")
    def ext(m):
        for sx in (-1, 1):
            for k, (dz, hh) in enumerate(((0.3, 0.9), (-0.3, 0.7))):
                m.pyramid((sx * 1.2, 3.5, dz), (0.45, 0.45), hh, "#17121F", rot=(0, 0, -sx * 25))
        for dx, dy in ((-0.6, 2.7), (0.5, 2.2), (0.0, 1.9)):
            m.box((dx, dy, 0.78), (0.06, 0.6, 0.05), "#B96CFF", rot=(0, 0, 30))
    return S("#17121F", "#17121F", "#B96CFF", wp=wp_obsidian("#17121F", "#B96CFF"), face_fn=face_, ext=ext, fist="#221B30",
             dark="#0E0A14", arm="#17121F")


SLAMS = {
    4: ("gravedigger", th_gravedigger), 5: ("sarcophagus_smasher", th_sarcophagus), 6: ("bog_brute", th_bog),
    7: ("wrecker", th_wrecker), 8: ("neon_enforcer", th_enforcer), 9: ("airlock_crusher", th_airlock),
    10: ("mandible_crusher", th_mandible), 11: ("sludge_smasher", th_sludge), 12: ("geode_crusher", th_geode),
    13: ("anchor_smasher", th_anchor), 14: ("barnacle_crusher", th_barnacle), 15: ("crab_crusher", th_crab),
    16: ("obsidian_crusher", th_obsidian),
}


# ================================================================== GUN
CX, CY = -1.25, 2.2


def ring_barrels(m, cx, cy, z0, L, n, rad, r, col, ring=None):
    for i in range(n):
        a = 2 * math.pi * i / n
        m.cyl((cx + math.cos(a) * rad, cy + math.sin(a) * rad, z0 + L / 2), r, L, col, sides=6, rot=(90, 0, 0))
    m.cyl((cx, cy, z0 + L / 2), rad * 0.85, L, dk(col, 0.7), sides=6, rot=(90, 0, 0))
    if ring:
        for z in (z0 + 0.3, z0 + L * 0.6, z0 + L - 0.1):
            m.cyl((cx, cy, z), rad + r + 0.06, 0.16, ring, sides=8, rot=(90, 0, 0))
    return (cx, cy, z0 + L)


def gun(name, T):
    m = Model(name)
    m.optimize = True
    b = T["body"]
    d = T.get("dark", dk(b))
    legs(m, 0, T.get("legc", d), T.get("boot", dk(d, 0.8)), y_top=1.25, spread=0.55, wide=0.9)
    if T.get("body_fn"):
        T["body_fn"](m)
    else:
        m.ball((0, 1.95, 0), 1.3, b, seg=8, rings=3, scale=(1.0, 0.95, 0.95))
        m.box((0, 2.5, 0), (2.0, 0.9, 1.3), b, bevel=0.1)
    hy = 3.0
    HW, HH, HD = 1.9, 1.5, 1.5
    m.box((0, hy, 0.1), (HW, HH, HD), T["head"], bevel=0.1)
    if T.get("hat"):
        T["hat"](m, hy, HW, HH, HD, 0.1)
    if T.get("face_fn"):
        T["face_fn"](m, hy, HW, HH, HD, 0.1)
    else:
        face(m, hy, HW, HH, HD, z0=0.1, eye=T["eye"], brow=T.get("brow", K), mouth=T.get("mouth", "fangs"), mc=T.get("mc", "#2A1010"))
    sh = T.get("shoulder", b)
    m.ball((-1.1, 2.65, 0), 0.55, sh, seg=8, rings=3)
    m.limb((-1.1, 2.65, 0), (CX, CY, 0.5), 0.8, T.get("arm", b), bevel=0.08)
    m.ball((1.1, 2.65, 0), 0.5, sh, seg=8, rings=3)
    m.limb((1.1, 2.65, 0), (1.45, 2.0, 0.4), 0.6, T.get("arm", b), bevel=0.08)
    if T.get("shield"):
        T["shield"](m)
    else:
        m.box((1.65, 2.0, 0.5), (0.3, 1.4, 1.3), T.get("shc", d), bevel=0.06)
    mz = T["cn"](m)
    m.set_muzzle(mz)
    if T.get("ext"):
        T["ext"](m)
    m.fit(height=3.8)
    return m


def g_coffin():
    def body_fn(m):
        m.frustum((0, 1.1, 0), (1.9, 1.2), (2.5, 1.5), 1.4, "#2A2430", bevel=0) if False else m.frustum((0, 1.1, 0), (1.9, 1.2), (2.5, 1.5), 1.4, "#2A2430")
        m.frustum((0, 2.5, 0), (2.5, 1.5), (1.9, 1.2), 0.9, "#2A2430")
        for y in (1.5, 2.3):
            m.box((0, y, 0.0), (2.55, 0.14, 1.55), "#7B3FA0")
        m.box((0, 2.0, 0.78), (0.12, 1.4, 0.05), "#7B3FA0")
    def hat_(m, hy, w, h, d, z0):
        m.box((0, hy + 0.1, z0 - d / 2 - 0.1), (w + 0.5, h + 1.0, 0.3), "#2A2430", bevel=0.05)
        m.box((0, hy + h / 2 + 0.15, z0), (w + 0.2, 0.3, d + 0.2), "#7B3FA0")
    def cn(m):
        mz = ring_barrels(m, CX, CY, 0.6, 2.0, 5, 0.3, 0.2, "#E9E2CD", ring="#7B3FA0")
        m.box((CX, CY, 0.6), (1.0, 1.0, 0.5), "#7B3FA0", bevel=0.05)
        return mz
    def ext(m):
        for sx in (-1, 1):
            m.cyl((sx * 1.2, 3.05, -0.1), 0.2, 0.6, "#F4EAD0", sides=6)
            m.box((sx * 1.2, 3.5, -0.1), (0.16, 0.3, 0.16), "#FFD23F")
            m.box((sx * 1.2, 2.85, -0.1), (0.7, 0.2, 0.7), "#2A2430")
    return dict(body="#2A2430", head="#EFE6CF", eye="#7CFF4A", body_fn=body_fn, hat=hat_, cn=cn, ext=ext, shc="#7B3FA0",
                brow="#16121C", mouth="grin", shoulder="#E9E2CD", arm="#E9E2CD")


def g_anubis():
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        m.box((0, hy - 0.25, fz + 0.3), (0.9, 0.6, 0.8), "#1E1E26", bevel=0.05)
        m.box((0, hy - 0.05, fz + 0.72), (0.4, 0.2, 0.1), "#0A0A10")
        for sx in (-1, 1):
            m.box((sx * w * 0.24, hy + 0.2, fz + 0.04), (0.3, 0.16, 0.05), "#F2BF1A")
            m.box((sx * w * 0.24, hy + 0.4, fz + 0.04), (0.35, 0.08, 0.05), "#0A0A10", rot=(0, 0, -sx * 20))
        for sx in (-1, 1):
            m.pyramid((sx * w * 0.36, hy + h / 2 - 0.05, z0), (0.5, 0.4), 1.2, "#1E1E26", rot=(0, 0, -sx * 6))
    def cn(m):
        m.cyl((CX, CY, 1.5), 0.28, 2.0, "#F2BF1A", sides=8, rot=(90, 0, 0))
        m.cyl((CX, CY, 0.7), 0.42, 0.3, "#C99A10", sides=8, rot=(90, 0, 0))
        m.cyl((CX, CY, 2.3), 0.42, 0.2, "#C99A10", sides=8, rot=(90, 0, 0))
        m.ball((CX, CY, 2.55), 0.4, "#FFC02E", seg=7, rings=3)
        return (CX, CY, 2.8)
    def ext(m):
        m.box((0, 3.65 - 0.9, 0.0), (2.3, 0.4, 1.7), "#F2BF1A")  # collar
        m.limb((-0.9, 2.9, 0.65), (0.9, 1.6, 0.7), 0.35, "#F2BF1A", d=0.1)
        for sx in (-1, 1):
            m.box((sx * 1.15, 3.0, 0.0), (0.8, 0.25, 1.0), "#F2BF1A")
    return dict(body="#1E1E26", head="#1E1E26", eye="#F2BF1A", face_fn=face_, cn=cn, ext=ext, shc="#F2BF1A", shoulder="#F2BF1A",
                legc="#1E1E26")


def g_witch():
    def hat_(m, hy, w, h, d, z0):
        hat(m, "witch", hy, w, h, d, "#6A2C70", "#3A1A40", z0=z0)
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        for sx in (-1, 1):
            m.box((sx * w * 0.22, hy + 0.15, fz + 0.03), (0.3, 0.2, 0.05), "#FFFFFF")
            m.box((sx * w * 0.22, hy + 0.15, fz + 0.06), (0.14, 0.14, 0.05), "#2A1B10")
            m.box((sx * w * 0.22, hy + 0.4, fz + 0.04), (0.4, 0.08, 0.05), "#3A1A40", rot=(0, 0, -sx * 16))
        m.box((0, hy - 0.1, fz + 0.2), (0.4, 0.5, 0.4), "#9FC080")  # wart nose
        m.box((0.12, hy - 0.05, fz + 0.42), (0.1, 0.1, 0.1), "#5E7A3C")
        m.box((0, hy - 0.5, fz + 0.02), (0.8, 0.1, 0.05), "#2A1010")
    def cn(m):
        m.cyl((CX, CY, 1.0), 0.85, 1.1, "#3A3A44", sides=8, rot=(90, 0, 0), r_top=0.95)
        m.cyl((CX, CY, 1.6), 0.95, 0.2, "#26262E", sides=8, rot=(90, 0, 0))
        m.cyl((CX, CY, 1.66), 0.75, 0.1, "#8BE04A", sides=8, rot=(90, 0, 0))
        for dx, dy in ((-0.3, 0.3), (0.35, -0.2), (0.0, 0.0)):
            m.ball((CX + dx, CY + dy, 1.8), 0.2, "#8BE04A", seg=5, rings=2)
        for sx in (-1, 1):
            m.box((CX + sx * 0.85, CY - 0.4, 0.9), (0.25, 0.3, 0.4), "#26262E")
        return (CX, CY, 1.95)
    def ext(m):
        m.limb((0.6, 1.2, -0.9), (-0.4, 4.0, -1.0), 0.18, "#7A5A30")
        m.frustum((-0.4, 3.9, -1.0), (0.3, 0.3), (0.9, 0.5), 0.6, "#C9A24A")
    return dict(body="#6A2C70", head="#BFD8A0", eye="#FFFFFF", hat=hat_, face_fn=face_, cn=cn, ext=ext, shc="#3A1A40", dark="#4A1C50")


def g_turbine():
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        m.box((0, hy + 0.1, fz + 0.04), (w * 0.9, h * 0.35, 0.12), "#2A3A3A")
        for sx in (-1, 1):
            m.box((sx * w * 0.22, hy + 0.1, fz + 0.12), (0.4, 0.22, 0.05), "#FF5A1F")
        m.box((0, hy - 0.4, fz + 0.02), (0.9, 0.12, 0.05), "#16121C")
    def cn(m):
        m.box((CX, CY, 0.7), (1.2, 1.2, 0.9), "#3A5A5A", bevel=0.08)
        mz = ring_barrels(m, CX, CY, 1.0, 1.5, 6, 0.38, 0.16, "#2A2A32", ring="#E0A020")
        m.cyl((CX, CY, 1.0), 0.78, 0.3, "#6E8F8F", sides=8, rot=(90, 0, 0))
        return mz
    def ext(m):
        m.cyl((0, 2.2, -1.1), 0.7, 1.6, "#B8432C", sides=8)
        m.cyl((0, 3.05, -1.1), 0.72, 0.15, "#7A2A1A", sides=8)
    return dict(body="#4E8F8F", head="#4E8F8F", eye="#FF5A1F", face_fn=face_, cn=cn, ext=ext, dark="#3A6A6A", shc="#7A8B5C")


def g_dj():
    def body_fn(m):
        for y, c in ((1.5, "#E83DAE"), (2.5, "#C0258E")):
            m.box((0, y, 0), (2.3, 1.0, 1.4), c, bevel=0.1)
            for sx in (-1, 1):
                m.cyl((sx * 0.55, y, 0.72), 0.38, 0.12, "#14162E", sides=8, rot=(90, 0, 0))
                m.cyl((sx * 0.55, y, 0.8), 0.15, 0.1, "#FF9AD5", sides=8, rot=(90, 0, 0))
    def hat_(m, hy, w, h, d, z0):
        m.box((0, hy + h / 2 + 0.05, z0), (w + 0.2, 0.2, 0.35), "#14162E")
        for sx in (-1, 1):
            m.cyl((sx * (w / 2 + 0.2), hy, z0), 0.55, 0.4, "#14162E", sides=8, rot=(0, 0, 90))
            m.cyl((sx * (w / 2 + 0.42), hy, z0), 0.35, 0.1, "#FF3DAE", sides=8, rot=(0, 0, 90))
    def face_(m, hy, w, h, d, z0):
        m.box((0, hy + 0.05, z0 + d / 2 + 0.03), (w * 0.8, h * 0.28, 0.08), "#FF3DAE")
        m.box((0, hy - 0.35, z0 + d / 2 + 0.03), (w * 0.4, h * 0.1, 0.05), "#14162E")
    def cn(m):
        m.box((CX, CY, 0.8), (1.2, 1.2, 1.0), "#14162E", bevel=0.06)
        mz = ring_barrels(m, CX, CY, 1.2, 1.2, 4, 0.34, 0.2, "#FF3DAE", ring="#14162E")
        return mz
    def ext(m):
        m.cyl((0, 2.4, -0.95), 0.95, 0.2, "#14162E", sides=10, rot=(90, 0, 0))
        m.cyl((0, 2.4, -1.07), 0.35, 0.1, "#FF3DAE", sides=8, rot=(90, 0, 0))
    return dict(body="#E83DAE", head="#2A2A44", eye="#FF3DAE", body_fn=body_fn, hat=hat_, face_fn=face_, cn=cn, ext=ext,
                dark="#14162E", shc="#14162E", shoulder="#14162E", arm="#E83DAE")


def g_satellite():
    def face_(m, hy, w, h, d, z0):
        m.box((0, hy + 0.05, z0 + d / 2 + 0.03), (w * 0.82, h * 0.4, 0.1), "#7DFFB0")
        m.box((0, hy - 0.4, z0 + d / 2 + 0.02), (w * 0.4, h * 0.08, 0.05), "#16121C")
    def cn(m):
        m.box((CX, CY, 0.7), (0.9, 0.9, 0.8), "#7A8497", bevel=0.05)
        m.frustum((CX, CY, 1.0), (0.5, 0.5), (1.9, 1.9), 1.1, "#9AA6BA", rot=(90, 0, 0))
        m.ball((CX, CY, 1.45), 0.4, "#7DFFB0", seg=6, rings=3)
        return (CX, CY, 1.7)
    def ext(m):
        for sx in (-1, 1):
            m.limb((0, 2.4, -0.7), (sx * 1.7, 2.9, -1.0), 0.2, "#7A8497")
            m.box((sx * 2.2, 2.9, -1.05), (1.8, 1.7, 0.12), "#2F5FD0")
            m.box((sx * 2.2, 2.9, -1.0), (1.85, 0.08, 0.08), "#9AA6BA")
            m.box((sx * 2.2, 2.9, -1.0), (0.08, 1.75, 0.08), "#9AA6BA")
        m.limb((0, 3.7, 0.0), (0.3, 4.4, 0.0), 0.12, "#7A8497")
        m.ball((0.3, 4.45, 0.0), 0.16, "#7DFFB0", seg=5, rings=2)
    return dict(body="#B5BECC", head="#B5BECC", eye="#7DFFB0", face_fn=face_, cn=cn, ext=ext, dark="#8A94A6", shc="#9AA6BA")


def g_wasp():
    def body_fn(m):
        m.ball((0, 1.95, 0), 1.3, "#F2C21A", seg=8, rings=3, scale=(1.0, 0.95, 0.95))
        m.box((0, 2.5, 0), (2.0, 0.9, 1.3), "#F2C21A", bevel=0.1)
        for y, w in ((1.55, 2.2), (2.1, 2.5), (1.0, 1.6)):
            m.box((0, y, 0.05), (w, 0.28, 1.65 if y > 1.2 else 1.3), "#2A2B33", bevel=0.05)
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        for sx in (-1, 1):
            m.box((sx * w * 0.24, hy + 0.1, fz + 0.03), (w * 0.28, h * 0.4, 0.1), "#2A2B33", bevel=0.03)
            m.box((sx * w * 0.24 - sx * 0.1, hy + 0.25, fz + 0.1), (0.15, 0.15, 0.05), "#8A8C99")
            m.limb((sx * 0.3, hy + h / 2, z0), (sx * 0.6, hy + h / 2 + 0.7, z0 + 0.3), 0.1, "#2A2B33")
            m.ball((sx * 0.6, hy + h / 2 + 0.75, z0 + 0.3), 0.13, "#2A2B33", seg=5, rings=2)
        m.box((0, hy - 0.35, fz + 0.02), (0.6, 0.1, 0.05), "#16121C")
    def cn(m):
        m.frustum((CX, CY, 0.6), (1.0, 1.0), (0.7, 0.7), 1.2, "#2A2B33", rot=(90, 0, 0))
        m.frustum((CX, CY, 1.8), (0.7, 0.7), (0.25, 0.25), 0.9, "#2A2B33", rot=(90, 0, 0))
        m.pyramid((CX, CY, 2.7), (0.3, 0.3), 0.7, "#FF7A1A", rot=(90, 0, 0))
        m.box((CX, CY, 1.2), (1.1, 1.1, 0.14), "#F2C21A")
        return (CX, CY, 3.35)
    def ext(m):
        for sx in (-1, 1):
            m.box((sx * 0.7, 3.0, -1.05), (0.9, 1.6, 0.1), "#D8E6F0", rot=(0, 0, sx * -12))
            m.limb((sx * 0.4, 2.5, -0.65), (sx * 0.7, 3.0, -1.0), 0.15, "#2A2B33")
    return dict(body="#F2C21A", head="#F2C21A", eye="#2A2B33", body_fn=body_fn, face_fn=face_, cn=cn, ext=ext, dark="#2A2B33",
                shc="#D8A010", legc="#2A2B33")


def g_hazmat():
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        m.cyl((0, hy, fz + 0.1), 0.78, 0.25, "#3A3A44", sides=10, rot=(90, 0, 0))
        m.cyl((0, hy, fz + 0.24), 0.62, 0.1, "#A6FF3A", sides=10, rot=(90, 0, 0))
        m.box((0.25, hy + 0.2, fz + 0.32), (0.25, 0.1, 0.04), "#E8FFC0")
    def cn(m):
        m.box((CX, CY, 0.8), (1.1, 1.1, 0.9), "#3A1E55", bevel=0.06)
        for dx, dy in ((-0.3, 0.0), (0.3, 0.0), (0.0, 0.35)):
            m.cyl((CX + dx, CY + dy, 1.7), 0.2, 1.5, "#3A1E55", sides=6, rot=(90, 0, 0))
            m.cyl((CX + dx, CY + dy, 2.5), 0.24, 0.2, "#A6FF3A", sides=6, rot=(90, 0, 0))
        return (CX, CY + 0.12, 2.6)
    def ext(m):
        for sx in (-1, 1):
            m.cyl((sx * 0.45, 2.3, -1.0), 0.4, 1.7, "#7A8090", sides=8)
            m.cyl((sx * 0.45, 3.2, -1.0), 0.28, 0.2, "#3A1E55", sides=8)
        m.box((0, 2.1, 0.0), (2.1, 0.22, 1.4), "#B0B4BC")
    return dict(body="#F28C1F", head="#F28C1F", eye="#A6FF3A", face_fn=face_, cn=cn, ext=ext, dark="#C06A10", shc="#8A8F99")


def g_prism():
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        for sx in (-1, 1):
            m.box((sx * w * 0.22, hy + 0.1, fz + 0.03), (0.35, 0.22, 0.05), "#FFFFFF")
            m.box((sx * w * 0.22, hy + 0.35, fz + 0.03), (0.4, 0.08, 0.05), "#1B3D57", rot=(0, 0, -sx * 22))
        m.box((0, hy - 0.4, fz + 0.02), (0.7, 0.1, 0.05), "#1B3D57")
    def cn(m):
        m.box((CX, CY, 0.7), (1.0, 1.0, 0.8), "#1B3D57", bevel=0.05)
        m.frustum((CX, CY, 1.0), (1.0, 1.0), (0.45, 0.45), 1.6, "#3FD0E0", rot=(90, 0, 0))
        m.ball((CX, CY, 2.7), 0.3, "#FFFFFF", seg=5, rings=2)
        m.pyramid((CX, CY, 2.6), (0.5, 0.5), 0.6, "#BFF4FA", rot=(90, 0, 0))
        return (CX, CY, 3.2)
    def ext(m):
        for dx, dz, hh, c in ((-0.6, -0.9, 1.5, "#3FD0E0"), (0.3, -1.0, 1.9, "#9AF0F8"), (0.9, -0.8, 1.3, "#3FD0E0"), (-1.2, -0.5, 1.1, "#9AF0F8")):
            m.pyramid((dx, 2.5, dz), (0.6, 0.6), hh, c, rot=(0, 0, dx * 6))
        for sx in (-1, 1):
            m.pyramid((sx * 1.15, 3.2, 0.0), (0.5, 0.5), 0.8, "#9AF0F8")
    return dict(body="#1B3D57", head="#3FD0E0", eye="#FFFFFF", face_fn=face_, cn=cn, ext=ext, dark="#12293C", shc="#3FD0E0",
                shoulder="#3FD0E0", belly="#3FD0E0")


def g_broadside():
    def hat_(m, hy, w, h, d, z0):
        hat(m, "tricorn", hy, w, h, d, "#16121C", "#C9A24A", z0=z0)
    def cn(m):
        m.box((CX, CY + 0.1, 0.6), (1.6, 1.4, 0.7), "#6A4A2A", bevel=0.06)
        for dx, dy, L in ((-0.5, -0.3, 1.9), (0.5, -0.3, 1.9), (0.0, 0.3, 2.3)):
            m.cyl((CX + dx, CY + dy, 0.9 + L / 2), 0.32, L, "#C9A24A", sides=8, rot=(90, 0, 0), r_top=0.27)
            m.cyl((CX + dx, CY + dy, 0.9 + L), 0.37, 0.15, "#A0802F", sides=8, rot=(90, 0, 0))
        return (CX, CY + 0.3, 3.25)
    def ext(m):
        m.cyl((0, 2.3, -1.05), 0.7, 1.2, "#6A4A2A", sides=8)
        for y in (1.85, 2.75):
            m.cyl((0, y, -1.05), 0.74, 0.12, "#3A3A44", sides=8)
        for y in (1.6, 2.1, 2.6):
            m.ball((0.0, y, 0.7), 0.12, "#C9A24A", seg=5, rings=2) if y > 0 else None
        m.box((0, 2.6, 0.0), (0.0, 0.0, 0.0), "#16121C") if False else None
    def shield(m):
        m.cyl((1.7, 2.0, 0.5), 0.8, 0.3, "#8A5A30", sides=10, rot=(0, 0, 90))
        m.cyl((1.88, 2.0, 0.5), 0.22, 0.14, "#6B6F7A", sides=8, rot=(0, 0, 90))
    return dict(body="#8E1F2A", head="#E8B98A", eye="#1B1B22", hat=hat_, cn=cn, ext=ext, shield=shield, dark="#5E1018",
                mouth="grin", brow="#3A1A1A", shoulder="#C9A24A")


def g_ghost():
    def hat_(m, hy, w, h, d, z0):
        hat(m, "tricorn", hy, w, h, d, "#2FA89A", "#8CFFE0", z0=z0)
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        for sx in (-1, 1):
            m.box((sx * w * 0.22, hy + 0.1, fz + 0.03), (0.35, 0.28, 0.05), "#8CFFE0")
            m.box((sx * w * 0.22, hy + 0.38, fz + 0.04), (0.4, 0.08, 0.05), "#2FA89A", rot=(0, 0, -sx * 20))
        m.box((0, hy - 0.35, fz + 0.02), (0.8, 0.14, 0.05), "#2FA89A")
    def cn(m):
        m.cyl((CX, CY, 1.55, ), 0.5, 2.0, "#9FB3B0", sides=8, rot=(90, 0, 0), r_top=0.42)
        m.cyl((CX, CY, 0.7), 0.6, 0.4, "#8AA09D", sides=8, rot=(90, 0, 0))
        m.cyl((CX, CY, 2.58), 0.55, 0.16, "#8CFFE0", sides=8, rot=(90, 0, 0))
        m.cyl((CX, CY, 2.55), 0.4, 0.2, "#DFFFF8", sides=8, rot=(90, 0, 0))
        return (CX, CY, 2.7)
    def ext(m):
        for i in range(7):  # tattered blocky hem
            m.box((-1.0 + i * 0.33, 1.05 - (0.25 if i % 2 else 0.0), 0.55 - (0.1 if i % 3 == 0 else 0.0)), (0.3, 0.55 + (0.2 if i % 2 else 0), 0.5), "#DFF3F0")
        for dx, dy, dz in ((-0.5, 2.4, -1.0), (0.5, 2.4, -1.0), (0.0, 3.2, -1.0)):
            m.ball((dx, dy, dz), 0.42, "#9FB3B0", seg=6, rings=2)
    return dict(body="#DFF3F0", head="#DFF3F0", eye="#8CFFE0", hat=hat_, face_fn=face_, cn=cn, ext=ext, dark="#B7D6D2", shc="#9FB3B0",
                legc="#B7D6D2")


def g_angler():
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        m.box((0, hy - 0.3, fz + 0.02), (w * 0.8, h * 0.3, 0.06), "#16121C")
        for i in range(6):
            m.box((-w * 0.32 + i * w * 0.13, hy - 0.22, fz + 0.05), (w * 0.08, h * 0.16, 0.05), "#FFFFFF")
        for sx in (-1, 1):
            m.box((sx * w * 0.3, hy + 0.25, fz + 0.03), (0.2, 0.2, 0.05), "#FFE63B")
    def cn(m):
        m.cyl((CX, CY, 1.4), 0.55, 1.8, "#C9B27A", sides=8, rot=(90, 0, 0), r_top=0.45)
        m.cyl((CX, CY, 2.35), 0.6, 0.2, "#A89050", sides=8, rot=(90, 0, 0))
        for dx, dy, z in ((0.45, 0.2, 1.0), (-0.4, 0.3, 1.6), (0.2, -0.45, 1.3), (-0.3, -0.4, 0.8)):
            m.pyramid((CX + dx, CY + dy, z), (0.25, 0.25), 0.28, "#EDE0B8", rot=(90, 0, 0))
        return (CX, CY, 2.5)
    def ext(m):
        m.limb((0, 3.7, 0.0), (0.0, 4.5, 0.6), 0.14, "#16121C")
        m.limb((0, 4.5, 0.6), (0.0, 4.3, 1.4), 0.14, "#16121C")
        m.ball((0, 4.2, 1.5), 0.3, "#FFE63B", seg=6, rings=3)
        for sx in (-1, 1):
            m.box((sx * 0.6, 3.3, -1.0), (0.2, 1.3, 0.9), "#2B63B0", rot=(0, 0, sx * 12))
        m.box((0, 2.5, -1.0), (0.2, 1.6, 0.8), "#2B63B0")
    def shield(m):
        m.frustum((1.5, 1.4, 0.45), (0.3, 0.2), (1.8, 0.35), 1.5, "#E8B8A0", rot=(0, 0, 0))
    return dict(body="#1F4E8C", head="#1F4E8C", eye="#FFE63B", face_fn=face_, cn=cn, ext=ext, shield=shield, dark="#143A6A",
                shoulder="#2B63B0")


def g_eclipse():
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        m.cyl((0, hy, fz + 0.08), 0.62, 0.2, "#0E0A1A", sides=12, rot=(90, 0, 0))
        for sx in (-1, 1):
            m.cyl((sx * 0.27, hy + 0.05, fz + 0.2), 0.2, 0.08, "#F2BF1A", sides=8, rot=(90, 0, 0))
            m.cyl((sx * 0.27, hy + 0.05, fz + 0.24), 0.09, 0.06, "#0E0A1A", sides=6, rot=(90, 0, 0))
        m.box((0, hy - 0.3, fz + 0.2), (0.5, 0.07, 0.05), "#F2BF1A")
    def cn(m):
        m.cyl((CX, CY, 0.9), 0.55, 0.9, "#1A1424", sides=8, rot=(90, 0, 0))
        m.cyl((CX, CY, 1.9), 0.9, 1.1, "#0E0A1A", sides=12, rot=(90, 0, 0))
        m.cyl((CX, CY, 2.5), 1.05, 0.14, "#F2BF1A", sides=12, rot=(90, 0, 0))
        m.cyl((CX, CY, 2.55), 0.5, 0.1, "#2A2040", sides=10, rot=(90, 0, 0))
        return (CX, CY, 2.6)
    def ext(m):
        for y in (1.7, 2.5):
            m.box((0, y, 0.7), (1.4, 0.1, 0.05), "#16121C")
    def shield(m):
        m.cyl((1.7, 2.0, 0.5), 0.75, 0.25, "#0E0A1A", sides=10, rot=(0, 0, 90))
        m.cyl((1.84, 2.0, 0.5), 0.5, 0.1, "#F2BF1A", sides=10, rot=(0, 0, 90))
    return dict(body="#E6E2F5", head="#E6E2F5", eye="#F2BF1A", face_fn=face_, cn=cn, ext=ext, shield=shield, dark="#B8B2D0",
                shoulder="#0E0A1A", belly="#0E0A1A")


GUNS = {4: ("coffin_cannon", g_coffin), 5: ("anubis_gunner", g_anubis), 6: ("cauldron_witch", g_witch), 7: ("turbine_gunner", g_turbine),
        8: ("laser_dj", g_dj), 9: ("satellite_gunner", g_satellite), 10: ("wasp_gunner", g_wasp), 11: ("hazmat_gunner", g_hazmat),
        12: ("prism_gunner", g_prism), 13: ("broadside_gunner", g_broadside), 14: ("ghost_gunner", g_ghost),
        15: ("angler_gunner", g_angler), 16: ("eclipse_gunner", g_eclipse)}


# ================================================================== BOMB
def fuse(m, c, r, glow="#FFD23F", col="#3A2A1A"):
    x, y, z = c
    m.limb((x, y + r * 0.8, z), (x + r * 0.2, y + r * 1.25, z), r * 0.18, col)
    m.box((x + r * 0.25, y + r * 1.35, z), (r * 0.3, r * 0.3, r * 0.3), glow)


def b_pumpkin(m, c, r):
    x, y, z = c
    m.ball(c, r, "#F28A1F", seg=8, rings=3, scale=(1.1, 0.9, 1))
    for dx in (-0.5, 0, 0.5):
        m.box((x + dx * r, y, z + r * 0.8), (r * 0.12, r * 1.4, r * 0.2), "#C86A10")
    m.box((x, y + r * 0.85, z), (r * 0.3, r * 0.3, r * 0.3), "#35502E")
    fuse(m, (x, y + r * 0.2, z), r)


def b_jar(m, c, r):
    x, y, z = c
    m.ball(c, r, "#B97A34", seg=8, rings=3)
    m.cyl((x, y + r * 0.95, z), r * 0.45, r * 0.5, "#9A6020", sides=8)
    m.cyl((x, y + r * 1.25, z), r * 0.55, r * 0.15, "#E8B423", sides=8)
    m.box((x, y + r * 0.1, z + r * 0.9), (r * 1.2, r * 0.18, r * 0.1), "#E8B423")
    fuse(m, (x, y + r * 0.5, z), r)


def b_spore(m, c, r):
    x, y, z = c
    m.ball(c, r, "#8A6A45", seg=8, rings=3)
    for dx, dy in ((-0.5, 0.3), (0.4, 0.5), (0.0, -0.3), (0.5, -0.2)):
        m.box((x + dx * r, y + dy * r, z + r * 0.85), (r * 0.35, r * 0.35, r * 0.15), "#F4EAD0")
    fuse(m, c, r, glow="#B6E03A")


def b_scrap(m, c, r):
    x, y, z = c
    m.ball(c, r, "#7A7F8A", seg=7, rings=3)
    m.box((x + r * 0.3, y, z + r * 0.7), (r * 0.7, r * 0.6, r * 0.3), "#B8432C")
    m.box((x - r * 0.4, y - r * 0.2, z + r * 0.7), (r * 0.5, r * 0.4, r * 0.3), "#F2C21A")
    fuse(m, c, r)


def b_drone(m, c, r):
    x, y, z = c
    m.ball(c, r, "#D9D4F5", seg=8, rings=3)
    m.box((x, y + r * 1.05, z), (r * 0.25, r * 0.25, r * 0.25), "#7B3FD0")
    m.box((x, y + r * 1.25, z), (r * 2.0, r * 0.08, r * 0.3), "#7B3FD0")
    m.box((x, y + r * 1.25, z), (r * 0.3, r * 0.08, r * 2.0), "#7B3FD0")
    m.box((x, y, z + r * 0.9), (r * 0.5, r * 0.3, r * 0.2), "#7B3FD0")


def b_mine(m, c, r):
    x, y, z = c
    m.ball(c, r, "#3B4558", seg=8, rings=3)
    for dx, dy, dz in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, 0, 1), (0, 0, -1), (0.7, 0.7, 0), (-0.7, 0.7, 0)):
        p = (x + dx * r, y + dy * r, z + dz * r)
        ax = dx or dy or dz
        rot = (90 * dz, 0, -90 * dx) if (dx or dz) and not dy else (0, 0, 0)
        if dx and dy:
            rot = (0, 0, -45 * (1 if dx > 0 else -1))
        m.pyramid(p, (r * 0.45, r * 0.45), r * 0.45, "#6A7488", rot=rot)
    m.box((x, y + r * 0.1, z + r * 0.95), (r * 0.3, r * 0.3, r * 0.2), "#FF3A2A")


def b_barrel(m, c, r):
    x, y, z = c
    m.cyl(c, r * 0.8, r * 1.8, "#8A8F99", sides=8)
    for dy in (-0.6, 0.6):
        m.cyl((x, y + dy * r, z), r * 0.84, r * 0.14, "#5A5E68", sides=8)
    m.box((x, y, z + r * 0.8), (r * 0.5, r * 0.9, r * 0.1), "#A6FF3A")
    fuse(m, (x, y + r * 0.4, z), r)


def b_acid(m, c, r):
    x, y, z = c
    m.ball(c, r, "#8BE04A", seg=8, rings=3)
    m.box((x, y + r * 0.95, z), (r * 0.3, r * 0.4, r * 0.3), "#3A6A20")
    m.box((x, y + r * 1.25, z), (r * 0.3, r * 0.3, r * 0.3), "#FFF04A")


def b_crystal(m, c, r):
    x, y, z = c
    m.ball(c, r, "#F08AC0", seg=4, rings=1, scale=(1, 1.3, 1))
    m.ball(c, r * 0.5, "#FFE0F0", seg=4, rings=1, scale=(1, 1.3, 1.1))


def b_keg(m, c, r):
    x, y, z = c
    m.cyl(c, r * 0.85, r * 1.6, "#6A4A2A", sides=8, scale=(1, 1))
    m.ball((x, y, z), r * 1.0, "#6A4A2A", seg=8, rings=2, scale=(1, 0.8, 1))
    for dy in (-0.55, 0.55):
        m.cyl((x, y + dy * r, z), r * 0.88, r * 0.12, "#2A2A30", sides=8)
    fuse(m, (x, y + r * 0.35, z), r)


def b_buoy(m, c, r):
    x, y, z = c
    m.ball(c, r, "#F4F4F4", seg=8, rings=3)
    for dy in (-0.5, 0.5):
        m.cyl((x, y + dy * r * 0.8, z), r * 0.93, r * 0.28, "#D13833", sides=8)
    fuse(m, (x, y + r * 0.3, z), r, glow="#8CFFE0")


def b_seamine(m, c, r):
    x, y, z = c
    m.ball(c, r, "#8A5A20", seg=8, rings=3)
    for dx, dy, dz in ((1, 0, 0), (-1, 0, 0), (0, 0, 1), (0, 0, -1), (0.7, 0.7, 0), (-0.7, 0.7, 0)):
        rot = (90 * dz, 0, -90 * dx) if not dy else (0, 0, -45 * (1 if dx > 0 else -1))
        m.pyramid((x + dx * r, y + dy * r, z + dz * r), (r * 0.4, r * 0.4), r * 0.45, "#C77A1E", rot=rot)
    fuse(m, (x, y + r * 0.5, z), r)


def b_meteor(m, c, r):
    x, y, z = c
    m.ball(c, r, "#FF9A3A", seg=7, rings=3)
    m.box((x - r * 0.3, y + r * 0.3, z + r * 0.8), (r * 0.6, r * 0.5, r * 0.3), "#3A2A2A")
    m.box((x + r * 0.4, y - r * 0.3, z + r * 0.8), (r * 0.4, r * 0.4, r * 0.3), "#3A2A2A")
    m.pyramid((x, y + r * 0.4, z - r * 0.9), (r * 0.7, r * 0.7), r * 1.0, "#FF5A1F", rot=(-90, 0, 0))


def bomb(name, T):
    m = Model(name)
    m.optimize = True
    b = T["body"]
    d = T.get("dark", dk(b))
    for sx in (-1, 1):
        m.box((sx * 0.6, 0.2, 0.25), (0.9, 0.4, 1.0), T.get("boot", dk(d, 0.8)), bevel=0.06)
        m.box((sx * 0.6, 0.55, 0.0), (0.6, 0.4, 0.6), d)
    if T.get("body_fn"):
        T["body_fn"](m)
    else:
        m.ball((0, 1.65, 0), 1.3, b, seg=8, rings=3, scale=(1.05, 0.95, 1.0))
        if T.get("belly"):
            m.box((0, 1.5, 1.25), (1.2, 1.2, 0.1), T["belly"])
    hy = 3.15
    if T.get("head_fn"):
        T["head_fn"](m)
    else:
        HW, HH, HD = 1.9, 1.45, 1.5
        m.box((0, hy, 0.1), (HW, HH, HD), T["head"], bevel=0.1)
        if T.get("hat"):
            T["hat"](m, hy, HW, HH, HD, 0.1)
        if T.get("face_fn"):
            T["face_fn"](m, hy, HW, HH, HD, 0.1)
        else:
            face(m, hy, HW, HH, HD, z0=0.1, eye=T["eye"], brow=T.get("brow", K), mouth=T.get("mouth", "grin"), mc=T.get("mc", "#2A1010"))
    # gloves + arms
    for sx in (-1, 1):
        m.limb((sx * 1.15, 2.4, 0), (sx * 1.6, 1.5, 0.6), 0.6, b, bevel=0.06)
        m.ball((sx * 1.65, 1.35, 0.7), 0.55, T.get("glove", "#E8E4D8"), seg=7, rings=3)
    # bandolier across the chest + bombs
    m.limb((-0.95, 2.65, 0.85), (0.95, 0.95, 1.1), 0.4, T.get("band", "#4A3A28"), d=0.15)
    for i in range(5):
        t = (i + 0.5) / 5
        px, py, pz = -0.95 + 1.9 * t, 2.65 - 1.7 * t, 0.85 + 0.25 * t
        T["bomb"](m, (px, py, pz + 0.4), 0.38)
    # giant backpack bomb
    T["bomb"](m, (0, 2.0, -1.55), 0.95)
    m.box((0, 2.0, -0.95), (0.9, 0.9, 0.5), dk(b, 0.7), bevel=0.05)
    if T.get("ext"):
        T["ext"](m)
    m.fit(height=3.6)
    return m


def bm_pumpkin():
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        for sx in (-1, 1):
            m.pyramid((sx * w * 0.22, hy + 0.1, fz + 0.03), (0.4, 0.1), 0.35, "#FFD23F", rot=(90, 0, 0)) if False else m.box((sx * w * 0.22, hy + 0.15, fz + 0.03), (0.35, 0.3, 0.06), "#FFD23F", rot=(0, 0, sx * 20))
        m.box((0, hy - 0.3, fz + 0.03), (w * 0.7, 0.28, 0.06), "#FFD23F")
        for sx in (-1, 0, 1):
            m.box((sx * 0.3, hy - 0.3, fz + 0.06), (0.14, 0.3, 0.06), "#F28A1F")
    def ext(m):
        m.box((0, 4.0, 0.1), (0.4, 0.5, 0.4), "#35502E")
        for sx in (-1, 1):
            m.box((sx * 0.6, 2.7, 0.1), (0.4, 0.3, 0.3), "#E8C85A", rot=(0, 0, sx * 20))
        m.box((0, 2.75, 0.1), (1.6, 0.3, 1.3), "#E8C85A")
    return dict(body="#35502E", head="#F28A1F", eye="#FFD23F", bomb=b_pumpkin, face_fn=face_, ext=ext, glove="#6A4A2A")


def bm_scarab():
    def hat_(m, hy, w, h, d, z0):
        m.frustum((0, hy + h / 2 - 0.05, z0), (w * 0.95, d * 0.95), (w * 0.7, d * 0.7), 0.5, "#0E6A55")
        m.box((0, hy + h / 2 + 0.3, z0), (0.1, 0.5, d * 0.9), "#E8B423")
    def face_(m, hy, w, h, d, z0):
        face(m, hy, w, h, d, z0=z0, eye="#FFE66B", mouth="fangs")
        for sx in (-1, 1):
            m.box((sx * 0.4, hy - 0.5, z0 + d / 2 + 0.1), (0.2, 0.3, 0.1), "#E8B423", rot=(0, 0, sx * 14))
    return dict(body="#178F73", head="#178F73", eye="#FFE66B", hat=hat_, face_fn=face_, bomb=b_jar, belly="#E8B423", glove="#E8B423",
                boot="#8A5A20")


def bm_toadstool():
    def hat_(m, hy, w, h, d, z0):
        m.frustum((0, hy + h / 2 - 0.1, z0), (w + 0.8, d + 0.8), (w * 0.5, d * 0.5), 1.1, "#D13833")
        for dx, dz, dy in ((-0.5, 0.4, 0.8), (0.5, 0.2, 0.7), (0.0, -0.3, 1.0), (0.1, 0.7, 0.4)):
            m.box((dx, hy + h / 2 + dy, z0 + dz), (0.4, 0.2, 0.4), "#F4EAD0")
    return dict(body="#8A6A45", head="#F4EAD0", eye="#2A1B10", hat=hat_, bomb=b_spore, glove="#F4EAD0", brow="#6A4A2A", boot="#5A3A20")


def bm_dumpster():
    def body_fn(m):
        m.box((0, 1.75, 0), (2.7, 2.1, 2.2), "#3E8E4A", bevel=0.1)
        for z in (-1.15,):
            m.box((0, 2.0, z), (2.7, 1.6, 0.12), "#2E7038")
        m.box((0, 1.9, 1.12), (2.8, 0.15, 0.2), "#2E7038")
        for sx in (-1, 1):
            m.box((sx * 1.4, 1.6, 0.0), (0.2, 0.7, 2.0), "#2E7038")
    def head_fn(m):
        m.box((0, 3.1, 0.15), (2.8, 0.5, 2.3), "#2E7038", bevel=0.06)  # hinged lid
        m.box((0, 2.5, 1.12), (2.0, 0.9, 0.1), "#16121C")  # mouth
        for i in range(7):
            m.box((-0.9 + i * 0.3, 2.78, 1.18), (0.2, 0.3, 0.08), "#FFFFFF")
            m.box((-0.9 + i * 0.3, 2.25, 1.18), (0.2, 0.22, 0.08), "#FFFFFF")
        for sx in (-1, 1):
            m.box((sx * 0.7, 3.5, 0.5), (0.7, 0.6, 0.7), "#2E7038")
            m.box((sx * 0.7, 3.5, 0.87), (0.5, 0.4, 0.06), "#FFD23F")
    return dict(body="#3E8E4A", head="#3E8E4A", eye="#FFD23F", bomb=b_scrap, body_fn=body_fn, head_fn=head_fn, glove="#2A2A30", boot="#2A2A30")


def bm_drone():
    def hat_(m, hy, w, h, d, z0):
        pass
    def face_(m, hy, w, h, d, z0):
        m.box((0, hy + 0.05, z0 + d / 2 + 0.05), (w * 0.85, h * 0.4, 0.1), "#7B3FD0")
        m.box((0, hy - 0.4, z0 + d / 2 + 0.02), (w * 0.4, 0.1, 0.05), "#7B3FD0")
    def ext(m):
        m.box((0, 2.0, -1.0), (1.8, 1.5, 0.6), "#7B3FD0", bevel=0.05)
        for sx in (-1, 1):
            m.cyl((sx * 0.5, 2.5, -1.35), 0.3, 1.0, "#9A8FD0", sides=6, rot=(60, 0, 0))
    return dict(body="#D9D4F5", head="#D9D4F5", eye="#7B3FD0", face_fn=face_, bomb=b_drone, ext=ext, dark="#B5AEE0", glove="#7B3FD0", boot="#7B3FD0")


def bm_mine():
    def face_(m, hy, w, h, d, z0):
        m.box((0, hy + 0.05, z0 + d / 2 + 0.05), (w * 0.85, h * 0.4, 0.1), "#FF3A2A")
        m.box((0, hy - 0.4, z0 + d / 2 + 0.02), (w * 0.4, 0.1, 0.05), "#16121C")
    def ext(m):
        m.box((0, 2.0, -0.95), (1.9, 1.7, 0.5), "#2A3244", bevel=0.05)
        for sx in (-1, 1):
            m.cyl((sx * 0.6, 1.4, -1.0), 0.3, 0.9, "#6A7488", sides=6)
            m.pyramid((sx * 0.6, 0.95, -1.0), (0.5, 0.5), 0.5, "#FF7A1A", rot=(180, 0, 0))
    return dict(body="#3B4558", head="#3B4558", eye="#FF3A2A", face_fn=face_, bomb=b_mine, ext=ext, glove="#2A3244", dark="#2A3244")


def bm_ladybug():
    def body_fn(m):
        m.ball((0, 1.65, 0), 1.35, "#D13833", seg=8, rings=3, scale=(1.05, 0.95, 1.0))
        m.box((0, 1.65, 0.0), (0.12, 2.5, 2.7), "#2A2B33")
        for dx, dy, dz in ((-0.7, 2.0, 1.0), (0.7, 2.0, 1.0), (-0.9, 1.2, 0.9), (0.9, 1.2, 0.9), (0.0, 1.0, 1.25), (-0.7, 2.3, -0.8), (0.7, 2.3, -0.8)):
            m.box((dx, dy, dz), (0.5, 0.5, 0.2), "#2A2B33")
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        for sx in (-1, 1):
            m.box((sx * w * 0.22, hy + 0.1, fz + 0.03), (0.42, 0.32, 0.06), "#FFFFFF")
            m.box((sx * w * 0.22, hy + 0.1, fz + 0.07), (0.15, 0.15, 0.05), "#2A2B33")
        m.box((0, hy - 0.3, fz + 0.02), (0.9, 0.15, 0.05), "#FFFFFF")
        for sx in (-1, 1):
            m.limb((sx * 0.3, hy + h / 2, z0), (sx * 0.5, hy + h / 2 + 0.6, z0 + 0.3), 0.1, "#2A2B33")
    return dict(body="#D13833", head="#2A2B33", eye="#FFFFFF", body_fn=body_fn, face_fn=face_, bomb=b_acid, glove="#2A2B33", dark="#8A2020", boot="#2A2B33")


def bm_barrel():
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        m.box((0, hy + 0.15, fz + 0.03), (0.75, 0.6, 0.06), "#FFFFFF")
        m.box((0.05, hy + 0.15, fz + 0.07), (0.3, 0.3, 0.05), "#A6FF3A")
        m.box((0.05, hy + 0.15, fz + 0.1), (0.12, 0.12, 0.05), "#16121C")
        m.box((0, hy - 0.3, fz + 0.03), (w * 0.62, 0.18, 0.05), "#2A1010")
        for i in range(5):
            m.box((-0.5 + i * 0.25, hy - 0.26, fz + 0.06), (0.14, 0.12, 0.04), "#FFFFFF")
    return dict(body="#8BE03A", head="#8BE03A", eye="#A6FF3A", face_fn=face_, bomb=b_barrel, glove="#5A5E68", dark="#5CA020", boot="#5A5E68")


def bm_bat():
    def hat_(m, hy, w, h, d, z0):
        hat(m, "ears", hy, w, h, d, "#2D2A5E", z0=z0)
    def ext(m):
        for sx in (-1, 1):
            m.box((sx * 1.1, 2.2, -0.9), (1.2, 1.9, 0.12), "#3F3A80", rot=(0, 0, sx * 12))
    return dict(body="#2D2A5E", head="#2D2A5E", eye="#FF7AD9", hat=hat_, bomb=b_crystal, ext=ext, glove="#1E1C42", belly="#4A468C", brow="#FF7AD9",
                mouth="fangs")


def bm_keg():
    def hat_(m, hy, w, h, d, z0):
        m.box((0, hy + h / 2 - 0.05, z0), (w + 0.04, 0.4, d + 0.04), "#F4F4F4")
        for i in range(4):
            m.box((-0.65 + i * 0.43, hy + h / 2 - 0.05, z0), (0.2, 0.42, d + 0.06), "#1B2D55")
        m.box((0.3, hy + h / 2 - 0.25, z0 - d / 2 - 0.1), (0.3, 0.6, 0.1), "#F4F4F4", rot=(0, 0, 18))
    def face_(m, hy, w, h, d, z0):
        face(m, hy - 0.1, w, h, d, z0=z0, eye="#1B1B22", mouth="grin", mc="#3A1A1A")
        m.box((0.1, hy - 0.33, z0 + d / 2 + 0.07), (0.12, 0.14, 0.04), "#F2BF1A")
    return dict(body="#B98A4A", head="#E8B98A", eye="#1B1B22", hat=hat_, face_fn=face_, bomb=b_keg, glove="#2A2A30", dark="#8A6A30", boot="#2A2A30")


def bm_buoy():
    def hat_(m, hy, w, h, d, z0):
        for sx in (-1, 0, 1):
            m.box((sx * 0.6, hy + h / 2 + 0.1, z0 - 0.1), (0.2, 0.7, 0.2), "#2F6B5A", rot=(0, 0, sx * 18))
        m.box((0, hy + h / 2, z0), (w + 0.02, 0.2, d + 0.02), "#2F6B5A")
    def ext(m):
        m.box((0, 1.5, 0.0), (2.8, 0.2, 2.2), "#C9B27A")  # rope belt
    return dict(body="#3FA58C", head="#9FD8C8", eye="#1B1B22", hat=hat_, bomb=b_buoy, ext=ext, glove="#2F6B5A", dark="#2F7A68", brow="#2F6B5A")


def bm_puffer():
    def body_fn(m):
        m.box((0, 1.8, 0), (3.0, 2.8, 2.6), "#F2B63B", bevel=0.5)
        for dx in (-1, 0, 1):
            for dy in (1.0, 2.0, 2.9):
                m.pyramid((dx * 1.0, dy, -1.3), (0.4, 0.4), 0.5, "#C77A1E", rot=(-90, 0, 0))
        for sx in (-1, 1):
            for dy in (0.9, 1.8, 2.7):
                m.pyramid((sx * 1.5, dy, 0.0), (0.4, 0.4), 0.5, "#C77A1E", rot=(0, 0, -sx * 90))
        for dx in (-1, 0, 1):
            m.pyramid((dx * 0.9, 3.2, 0.0), (0.4, 0.4), 0.55, "#C77A1E")
    def head_fn(m):
        fz = 1.31
        for sx in (-1, 1):
            m.box((sx * 0.6, 2.5, fz), (0.75, 0.75, 0.1), "#FFFFFF")
            m.box((sx * 0.6, 2.45, fz + 0.06), (0.35, 0.35, 0.06), "#16121C")
        m.box((0, 1.65, fz), (1.1, 0.45, 0.1), "#C77A1E")
        m.box((0, 1.65, fz + 0.04), (0.8, 0.2, 0.06), "#6A2A1A")
    return dict(body="#F2B63B", head="#F2B63B", eye="#FFFFFF", bomb=b_seamine, body_fn=body_fn, head_fn=head_fn, glove="#C77A1E", dark="#C99220", boot="#C77A1E")


def bm_meteor():
    def hat_(m, hy, w, h, d, z0):
        hat(m, "horns", hy, w, h, d, "#3A2A2A", z0=z0)
    def ext(m):
        for dx, dy in ((-0.7, 1.9), (0.8, 1.2), (0.1, 0.9)):
            m.box((dx, dy, 1.2), (0.6, 0.5, 0.3), "#3A2A2A")
    return dict(body="#E8531F", head="#E8531F", eye="#FFD23F", hat=hat_, bomb=b_meteor, ext=ext, glove="#3A2A2A", dark="#B03A10", boot="#3A2A2A",
                brow="#3A2A2A")


BOMBS = {4: ("pumpkin_bomber", bm_pumpkin), 5: ("scarab_bomber", bm_scarab), 6: ("toadstool_bomber", bm_toadstool), 7: ("dumpster_bomber", bm_dumpster),
         8: ("drone_carrier", bm_drone), 9: ("mine_bomber", bm_mine), 10: ("ladybug_bomber", bm_ladybug), 11: ("barrel_bomber", bm_barrel),
         12: ("bat_bomber", bm_bat), 13: ("powder_keg_bomber", bm_keg), 14: ("buoy_bomber", bm_buoy), 15: ("puffer_bomber", bm_puffer),
         16: ("meteor_bomber", bm_meteor)}


# ================================================================== CMD
def cmd(name, T):
    m = Model(name)
    m.optimize = True
    b = T["body"]
    d = T.get("dark", dk(b))
    legs(m, 0, T.get("legc", d), T.get("boot", dk(d, 0.8)), y_top=1.3, spread=0.55, wide=0.85)
    m.frustum((0, 1.2, 0), (2.5, 1.6), (1.9, 1.35), 2.0, b)
    m.box((0, 2.4, 0.0), (2.1, 1.4, 1.4), b, bevel=0.1)
    if T.get("front"):
        T["front"](m)
    sh = T.get("shoulder", d)
    for sx in (-1, 1):
        m.ball((sx * 1.2, 3.05, 0), 0.7, sh, seg=8, rings=3)
        m.box((sx * 1.2, 3.5, 0), (0.9, 0.2, 1.0), sh)
    hy = 3.9
    HW, HH, HD = 1.7, 1.4, 1.4
    m.box((0, hy, 0.05), (HW, HH, HD), T["head"], bevel=0.1)
    if T.get("hat"):
        T["hat"](m, hy, HW, HH, HD, 0.05)
    if T.get("face_fn"):
        T["face_fn"](m, hy, HW, HH, HD, 0.05)
    else:
        face(m, hy, HW, HH, HD, z0=0.05, eye=T["eye"], brow=T.get("brow", K), mouth=T.get("mouth", "bar"), mc=T.get("mc", "#2A1010"))
    # right arm holds the banner/staff, left arm behind the shield
    m.limb((-1.2, 3.0, 0), (-1.65, 2.0, 0.6), 0.7, b, bevel=0.06)
    m.box((-1.65, 1.95, 0.6), (0.8, 0.8, 0.8), T.get("hand", "#CCCCCC"), bevel=0.08)
    m.limb((1.2, 3.0, 0), (1.5, 2.1, 0.5), 0.7, b, bevel=0.06)
    if T.get("pole"):
        T["pole"](m)
    else:
        pole_flag(m, (-1.65, 0.1, 0.6), (-1.65, 4.6, 0.6), T["flag"], T.get("emblem"), out=-1)
    if T.get("shield"):
        T["shield"](m)
    if T.get("ext"):
        T["ext"](m)
    m.fit(height=4.6)
    return m


def sq_shield(col, edge, emblem=None, ec=None):
    def f(m):
        m.box((1.75, 2.3, 0.6), (0.3, 2.3, 1.9), edge, bevel=0.06)
        m.box((1.92, 2.3, 0.6), (0.14, 1.9, 1.5), col)
        if emblem:
            emblem(m, (1.99, 2.3, 0.6), 1.5, 1.9) if False else None
            x, y, z = 2.0, 2.3, 0.6
            for sub in (1,):
                pass
    return f


def shield_with(col, edge, draw):
    """Left shield (+X side). draw(m, x, y, z) paints the emblem on its outer face."""
    def f(m):
        m.box((1.75, 2.3, 0.6), (0.3, 2.4, 2.0), edge, bevel=0.06)
        m.box((1.93, 2.3, 0.6), (0.14, 2.0, 1.6), col)
        if draw:
            draw(m, 2.02, 2.3, 0.6)
    return f


def sk_draw(m, x, y, z, col="#EFE6CF"):
    m.box((x, y + 0.2, z), (0.08, 0.7, 0.6), col)
    m.box((x, y - 0.3, z), (0.08, 0.35, 0.4), col)
    for dz in (-0.12, 0.12):
        m.box((x + 0.04, y + 0.25, z + dz), (0.06, 0.15, 0.15), "#16121C")


def flag_skull(col):
    return lambda m, c, w, h: em_skull(m, c, w, h)


def c_lich():
    def hat_(m, hy, w, h, d, z0):
        hat(m, "iron", hy, w, h, d, "#7C7F88", "#5A5C66", z0=z0)
    return dict(body="#4B2E83", head="#EFE6CF", eye="#B96CFF", hat=hat_, shoulder="#EFE6CF", flag="#2A1740", emblem=em_skull,
                shield=shield_with("#2A1740", "#EFE6CF", lambda m, x, y, z: [m.box((x, y + 0.2, z), (0.08, 0.7, 0.6), "#EFE6CF"), m.box((x, y - 0.35, z), (0.08, 0.4, 0.4), "#EFE6CF")]),
                hand="#EFE6CF", mouth="grin", dark="#2A1740", brow="#16121C")


def c_pharaoh():
    def hat_(m, hy, w, h, d, z0):
        hat(m, "dcrown", hy, w, h, d, "#F4EAD0", "#8E1F2A", z0=z0)
    def pole(m):
        m.limb((-1.65, 0.1, 0.6), (-1.65, 3.6, 0.6), 0.22, "#E8B423")
        for dx, dy, w, h in ((0, 4.1, 1.0, 0.18), (-0.45, 4.35, 0.18, 0.8), (0.45, 4.35, 0.18, 0.8), (0, 4.75, 1.0, 0.18)):
            m.box((-1.65 + dx, dy, 0.6), (w, h, 0.2), "#E8B423")
    def front(m):
        m.box((0, 3.1, 0.0), (2.6, 0.5, 1.7), "#E8B423", bevel=0.08)  # collar
    def ext(m):
        m.box((0, 3.35, 0.78), (0.5, 0.9, 0.3), "#E8B423")  # beard
    return dict(body="#8E1F2A", head="#C99A5B", eye="#1B1B22", hat=hat_, pole=pole, front=front, ext=ext, shoulder="#E8B423", hand="#C99A5B",
                shield=shield_with("#8E1F2A", "#E8B423", lambda m, x, y, z: m.box((x, y, z), (0.08, 0.7, 0.7), "#E8B423", rot=(45, 0, 0))),
                dark="#5E1018", flag="#8E1F2A", mouth="bar")


def c_hag():
    def hat_(m, hy, w, h, d, z0):
        m.frustum((0, hy + h / 2 - 0.1, z0 - 0.1), (w + 0.3, d + 0.3), (w * 0.4, d * 0.4), 1.3, "#1F4A4A")
        m.frustum((0, hy + h / 2 + 1.2, z0 - 0.1), (w * 0.4, d * 0.4), (0.2, 0.2), 0.7, "#1F4A4A", top_off=(0.1, -0.2))
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        for sx in (-1, 1):
            m.box((sx * w * 0.22, hy + 0.1, fz + 0.03), (0.3, 0.25, 0.05), "#5CFFD1")
        m.box((0, hy - 0.55, fz + 0.15), (0.6, 0.5, 0.4), "#9FB58A")  # chin
        m.box((0, hy - 0.2, fz + 0.02), (0.5, 0.1, 0.05), "#2A3A2A")
    def pole(m):
        m.limb((-1.65, 0.1, 0.6), (-1.5, 3.5, 0.6), 0.22, "#4A3A2A")
        m.limb((-1.5, 3.5, 0.6), (-1.9, 4.5, 0.6), 0.2, "#4A3A2A")
        m.box((-1.9, 4.75, 0.6), (0.7, 0.5, 0.5), "#1B1B22")
        m.box((-1.75, 5.0, 0.6), (0.35, 0.35, 0.35), "#1B1B22")
        m.pyramid((-1.55, 5.0, 0.6), (0.2, 0.2), 0.35, "#F2BF1A", rot=(0, 0, -90))
    def shield(m):
        m.box((1.75, 2.3, 0.6), (0.3, 2.3, 1.9), "#16121C", bevel=0.06)
        m.box((1.95, 2.3, 0.6), (0.16, 1.6, 1.3), "#3A5A5A")
        m.ball((2.1, 2.3, 0.6), 0.45, "#5CFFD1", seg=6, rings=3, scale=(0.6, 1.2, 0.8))
    def ext(m):
        for sx in (-1, 1):
            m.box((sx * 1.2, 3.6, 0.0), (1.0, 0.35, 1.0), "#4A7A3A")
    return dict(body="#1F4A4A", head="#9FB58A", eye="#5CFFD1", hat=hat_, face_fn=face_, pole=pole, shield=shield, ext=ext, shoulder="#4A7A3A",
                hand="#9FB58A", flag="#1F4A4A", dark="#123030")


def c_foreman():
    def hat_(m, hy, w, h, d, z0):
        hat(m, "hardhat", hy, w, h, d, "#F2C21A", "#C99A10", z0=z0)
    def face_(m, hy, w, h, d, z0):
        m.box((0, hy + 0.05, z0 + d / 2 + 0.03), (w * 0.85, h * 0.3, 0.08), "#3DF2FF")
        m.box((0, hy - 0.4, z0 + d / 2 + 0.03), (w * 0.4, 0.1, 0.05), "#16121C")
    def front(m):
        m.box((0, 2.5, 0.72), (1.7, 1.4, 0.1), "#F28C1F")
        for sx in (-1, 1):
            m.box((sx * 0.5, 2.5, 0.78), (0.2, 1.4, 0.05), "#F4F4F4")
    def shield(m):
        m.box((1.8, 2.3, 0.6), (0.2, 2.0, 2.0), "#F2C21A", rot=(45, 0, 0))
        for k in (-0.5, 0, 0.5):
            m.box((1.93, 2.3 + k, 0.6), (0.1, 0.25, 2.0), "#16121C", rot=(45, 0, 0)) if False else m.box((1.93, 2.3, 0.6 + k), (0.1, 1.9, 0.2), "#16121C", rot=(45, 0, 0))
    return dict(body="#8A8F99", head="#B8BDC8", eye="#3DF2FF", hat=hat_, face_fn=face_, front=front, shield=shield, flag="#F4F4F4", emblem=em_plain,
                hand="#F2C21A", dark="#6A6F79", shoulder="#F28C1F")


def c_overlord():
    def hat_(m, hy, w, h, d, z0):
        m.box((0, hy + 0.1, z0 + d / 2 + 0.04), (w * 0.9, h * 0.3, 0.1), "#FFD23F")
        for i in (-2, -1, 0, 1, 2):
            m.pyramid((i * w * 0.2, hy + h * 0.28, z0 + d / 2 + 0.04), (0.3, 0.1), 0.45 if i % 2 == 0 else 0.3, "#FFD23F")
    def front(m):
        for sx in (-1, 1):
            m.box((sx * 0.4, 2.7, 0.74), (0.3, 1.2, 0.08), "#FFD23F", rot=(0, 0, sx * -12))
    def shield(m):
        m.box((1.75, 2.3, 0.6), (0.3, 2.4, 2.0), "#3DF2FF", bevel=0.05)
        m.box((1.93, 2.3, 0.6), (0.16, 2.0, 1.6), "#9AF8FF")
    return dict(body="#1B2A6B", head="#2A2A44", eye="#FFD23F", hat=hat_, front=front, shield=shield, shoulder="#FFD23F", flag="#FF3DAE",
                emblem=em_plain, hand="#FFD23F", dark="#101A48", mouth="none",
                face_fn=lambda m, hy, w, h, d, z0: (m.box((0, hy - 0.05, z0 + d / 2 + 0.04), (w * 0.85, h * 0.18, 0.08), "#FFD23F"),
                                                    m.box((0, hy - 0.4, z0 + d / 2 + 0.03), (w * 0.4, 0.1, 0.05), "#FFD23F")))


def c_station():
    def hat_(m, hy, w, h, d, z0):
        hat(m, "peaked", hy, w, h, d, "#F4F4F4", "#16121C", z0=z0)
    def front(m):
        m.box((0, 3.0, 0.5), (1.2, 0.4, 0.9), "#F4F4F4", bevel=0.05)
        for sx in (-1, 1):
            for k in range(3):
                m.box((sx * 1.2, 3.55 + k * 0.0, -0.3 + k * 0.4), (0.9, 0.1, 0.18), "#F2BF1A")
    def shield(m):
        m.box((1.75, 2.3, 0.6), (0.3, 2.4, 2.0), "#F4F4F4", bevel=0.05)
        m.box((1.93, 2.3, 0.6), (0.16, 2.0, 1.6), "#7DFFB0")
    return dict(body="#2B66D9", head="#E8B98A", eye="#7DFFB0", hat=hat_, front=front, shield=shield, shoulder="#F4F4F4", flag="#F4F4F4",
                emblem=em_plain, hand="#F4F4F4", dark="#1B46A0", mouth="bar", pc="#9AA6BA")


def c_mantis():
    def hat_(m, hy, w, h, d, z0):
        m.box((0, hy + h / 2, z0), (w * 0.7, 0.2, d * 0.7), "#E3B341")
        for i in (-1, 0, 1):
            m.pyramid((i * 0.4, hy + h / 2 + 0.1, z0), (0.3, 0.3), 0.5, "#E3B341")
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        for sx in (-1, 1):
            m.box((sx * w * 0.24, hy + 0.1, fz + 0.03), (w * 0.28, h * 0.45, 0.1), "#FFD23F", rot=(0, 0, -sx * 12))
            m.box((sx * w * 0.24, hy + 0.1, fz + 0.1), (0.14, 0.3, 0.05), "#16121C")
        m.box((0, hy - 0.4, fz + 0.03), (0.5, 0.1, 0.05), "#16121C")
    def front(m):
        for sx in (-1, 1):
            m.frustum((sx * 0.7, 2.0, 0.8), (0.4, 0.15), (0.05, 0.05), 1.4, "#E6E0C2", rot=(-30, 0, sx * 10))
            m.box((sx * 0.7, 2.0, 0.75), (0.5, 0.5, 0.5), "#5CC24A")
    def ext(m):
        m.cyl((0.0, 3.2, -1.0), 0.35, 1.2, "#E6E0C2", sides=6, rot=(60, 0, 0), r_top=0.6)
    return dict(body="#5CC24A", head="#5CC24A", eye="#FFD23F", hat=hat_, face_fn=face_, front=front, ext=ext, shoulder="#E3B341",
                flag="#5CC24A", emblem=em_leaf, hand="#E6E0C2", dark="#3F8A32",
                shield=lambda m: None)


def c_mutant():
    def hat_(m, hy, w, h, d, z0):
        m.ball((0, hy + h / 2 + 0.1, z0), 0.85, "#FF4FA0", seg=8, rings=3, scale=(1, 0.7, 1))
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        for sx in (-1, 1):
            m.cyl((sx * w * 0.22, hy + 0.1, fz + 0.1), 0.35, 0.2, "#3A3A44", sides=8, rot=(90, 0, 0))
            m.cyl((sx * w * 0.22, hy + 0.1, fz + 0.2), 0.25, 0.06, "#E8FFC0", sides=8, rot=(90, 0, 0))
        m.box((0, hy + 0.1, fz + 0.1), (0.2, 0.08, 0.08), "#3A3A44")
        m.box((0, hy - 0.4, fz + 0.03), (0.6, 0.1, 0.05), "#2A1010")
    def front(m):
        m.box((0, 2.0, 0.74), (0.3, 2.4, 0.06), "#F8FCF8")
        for dx, dy in ((-0.6, 2.5), (0.5, 1.8)):
            m.box((dx, dy, 0.76), (0.5, 0.5, 0.05), "#E83DAE")
    def shield(m):
        m.box((1.75, 2.3, 0.6), (0.3, 2.4, 2.0), "#8A8F99", bevel=0.05)
        for k in range(4):
            m.cyl((1.98, 2.3, -0.1 + k * 0.45), 0.17, 1.6, "#9AF0F8" if k % 2 else "#E83DAE", sides=6)
    return dict(body="#EAF0EA", head="#9A5FD0", eye="#A6FF3A", hat=hat_, face_fn=face_, front=front, shield=shield, flag="#F8FCF8", emblem=em_flask,
                hand="#9A5FD0", dark="#BFC8BF", shoulder="#EAF0EA")


def c_gem():
    def hat_(m, hy, w, h, d, z0):
        m.box((0, hy + h / 2, z0), (w + 0.1, 0.3, d + 0.1), "#E070C8", bevel=0.03)
        for i, x in enumerate((-0.6, -0.2, 0.2, 0.6)):
            m.pyramid((x * w, hy + h / 2 + 0.1, z0), (0.4, 0.4), 1.0 if i in (1, 2) else 0.65, "#F29AE0")
    def face_(m, hy, w, h, d, z0):
        fz = z0 + d / 2
        for sx in (-1, 1):
            m.box((sx * w * 0.22, hy + 0.1, fz + 0.03), (0.3, 0.22, 0.05), "#FFFFFF")
        m.box((0, hy - 0.4, fz + 0.03), (0.5, 0.1, 0.05), "#C050A8")
    def shield(m):
        m.box((1.8, 2.3, 0.6), (0.3, 2.2, 2.2), "#E070C8", rot=(45, 0, 0), bevel=0.04)
        m.box((1.98, 2.3, 0.6), (0.16, 1.2, 1.2), "#FBD0F0", rot=(45, 0, 0))
    return dict(body="#F4F4F4", head="#F4D6EE", eye="#FFFFFF", hat=hat_, face_fn=face_, shield=shield, shoulder="#E070C8", flag="#E070C8",
                emblem=em_plain, hand="#F4D6EE", dark="#E070C8", pc="#F29AE0")


def c_mate():
    def hat_(m, hy, w, h, d, z0):
        m.box((0, hy + h / 2 + 0.55, z0), (w * 1.55, 0.9, d * 0.7), "#16121C", bevel=0.06)
        for sx in (-1, 1):
            m.pyramid((sx * w * 0.8, hy + h / 2 + 0.55, z0), (0.6, d * 0.5), 0.5, "#16121C", rot=(0, 0, -sx * 90))
        em_skull(m, (0, hy + h / 2 + 0.55, z0 + d * 0.35 + 0.03), 1.4, 1.3)
    def front(m):
        m.limb((-1.0, 2.9, 0.72), (1.0, 1.6, 0.75), 0.4, "#D13833", d=0.12)
        m.box((0, 2.4, 0.72), (0.0, 0.0, 0.0), "#F4F4F4") if False else None
    def shield(m):
        m.cyl((1.75, 2.3, 0.6), 1.0, 0.3, "#8A5A30", sides=10, rot=(0, 0, 90))
        m.ball((1.95, 2.3, 0.6), 0.4, "#6B6F7A", seg=6, rings=3, scale=(0.5, 1, 1))
    return dict(body="#F4F4F4", head="#E8B98A", eye="#1B1B22", hat=hat_, front=front, shield=shield, shoulder="#C9A24A", flag="#16121C",
                emblem=em_skull, hand="#E8B98A", dark="#16121C", mouth="bar", legc="#16121C", brow="#4A2A1A")


def c_phantom():
    def hat_(m, hy, w, h, d, z0):
        hat(m, "bicorne", hy, w, h, d, "#274B6B", "#C9D8D8", z0=z0)
    def shield(m):
        m.cyl((1.75, 2.3, 0.6), 1.0, 0.25, "#9FB3B0", sides=10, rot=(0, 0, 90))
        m.cyl((1.9, 2.3, 0.6), 0.75, 0.14, "#274B6B", sides=10, rot=(0, 0, 90))
        for k in range(4):
            m.box((1.98, 2.3, 0.6), (0.08, 0.2, 2.0), "#9FB3B0", rot=(k * 45, 0, 0))
    def front(m):
        for k in range(4):
            m.box((0, 2.9 - k * 0.5, 0.72), (0.2, 0.2, 0.08), "#E8FFF5")
    return dict(body="#274B6B", head="#CFE8E4", eye="#8CFFE0", hat=hat_, shield=shield, front=front, shoulder="#C9D8D8", flag="#CFE8E4",
                emblem=em_anchor, hand="#CFE8E4", dark="#16304A", mouth="bar")


def c_triton():
    def hat_(m, hy, w, h, d, z0):
        m.box((0, hy + h / 2, z0), (w + 0.1, 0.3, d + 0.1), "#F2BF1A", bevel=0.03)
        for i, x in enumerate((-0.6, -0.2, 0.2, 0.6)):
            m.limb((x * w, hy + h / 2, z0), (x * w * 1.3, hy + h / 2 + 0.9, z0), 0.22, "#F2BF1A")
            m.ball((x * w * 1.3, hy + h / 2 + 1.0, z0), 0.2, "#FF7A5C", seg=5, rings=2)
    def pole(m):
        m.limb((-1.65, 0.1, 0.6), (-1.65, 4.3, 0.6), 0.22, "#F2BF1A")
        for dx in (-0.5, 0, 0.5):
            m.limb((-1.65 + dx, 4.3, 0.6), (-1.65 + dx, 4.9, 0.6), 0.16, "#F2BF1A")
            m.pyramid((-1.65 + dx, 4.85, 0.6), (0.3, 0.2), 0.4, "#F2BF1A")
        m.box((-1.65, 4.3, 0.6), (1.2, 0.2, 0.2), "#F2BF1A")
        m.box((-2.45, 3.6, 0.6), (1.4, 1.0, 0.1), "#1FA89A")
    def shield(m):
        m.frustum((1.75, 1.3, 0.6), (0.3, 0.3), (0.3, 2.2), 1.9, "#F4D6C0", rot=(0, 0, 0)) if False else None
        m.box((1.8, 2.3, 0.6), (0.3, 2.0, 2.0), "#F4D6C0", bevel=0.06)
        for k in (-0.6, -0.2, 0.2, 0.6):
            m.box((1.97, 2.3, 0.6 + k), (0.1, 1.9, 0.14), "#E8B8A0")
    def ext(m):
        m.ball((0.9, 1.6, 0.8), 0.35, "#F4EAD0", seg=6, rings=2, scale=(1, 0.8, 1.3))
    return dict(body="#1FA89A", head="#7FD8C8", eye="#1B4A44", hat=hat_, pole=pole, shield=shield, ext=ext, shoulder="#F2BF1A", hand="#7FD8C8",
                dark="#127068", flag="#1FA89A", mouth="bar", brow="#127068")


def c_herald():
    def hat_(m, hy, w, h, d, z0):
        m.box((0, hy + h / 2, z0), (w + 0.1, 0.3, d + 0.1), "#F2BF1A", bevel=0.03)
        for sx in (-1, 1):
            m.pyramid((sx * w * 0.35, hy + h / 2 + 0.1, z0), (0.4, 0.4), 1.0, "#F2BF1A", rot=(0, 0, -sx * 16))
        m.pyramid((0, hy + h / 2 + 0.1, z0), (0.4, 0.4), 0.7, "#F2BF1A")
    def shield(m):
        m.box((1.75, 2.3, 0.6), (0.3, 2.4, 2.0), "#F2BF1A", bevel=0.05)
        m.box((1.93, 2.3, 0.6), (0.14, 2.0, 1.6), "#2A1A5A")
        em_star(m, (2.02, 2.3, 0.6), 1.4, 1.6, "#FF3AE0")
    def front(m):
        m.box((0, 2.4, 0.74), (0.3, 1.4, 0.06), "#F2BF1A")
    return dict(body="#6A3FD0", head="#6A3FD0", eye="#FF3AE0", hat=hat_, shield=shield, front=front, shoulder="#F2BF1A", flag="#16121C",
                emblem=em_star, hand="#F2BF1A", dark="#4A2A98", mouth="bar", brow="#16121C")


CMDS = {4: ("lich_commander", c_lich), 5: ("pharaoh_commander", c_pharaoh), 6: ("hag_commander", c_hag), 7: ("foreman_commander", c_foreman),
        8: ("neon_overlord", c_overlord), 9: ("station_commander", c_station), 10: ("mantis_commander", c_mantis),
        11: ("mutant_commander", c_mutant), 12: ("gem_commander", c_gem), 13: ("first_mate", c_mate), 14: ("phantom_admiral", c_phantom),
        15: ("triton_commander", c_triton), 16: ("void_herald", c_herald)}

TEMPLATES = {"slam": (SLAMS, slam, 4.2), "gun": (GUNS, gun, 3.8), "bomb": (BOMBS, bomb, 3.6), "cmd": (CMDS, cmd, 4.6)}
ORDER = ["slam", "gun", "bomb", "cmd"]  # level 1..4 of the chapter


def make_all():
    out = []
    for r in range(4, 17):
        for k in ORDER:
            reg, fn, _ = TEMPLATES[k]
            n, th = reg[r]
            out.append((r, k, fn(f"r{r}_mini_{n}", th())))
    return out
