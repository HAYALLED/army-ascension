"""13 full bosses (chapters 4-16). Metres, front +Z, right hand = -X, fit(height) at the end (8 m, final 9 m)."""
import math
from glbkit import Model
from minis_r import face, hat, dk, lt, W, K


def new(name):
    m = Model(name)
    m.optimize = True
    return m


def chain(m, pts, w, col, bevel=0.05):
    for a, b in zip(pts, pts[1:]):
        m.limb(a, b, w, col, bevel=bevel)
        m.ball(b, w * 0.58, col, seg=6, rings=2)


def arm2(m, a, b, c, w, col, joint=None):
    m.limb(a, b, w, col, bevel=0.1)
    m.ball(b, w * 0.62, joint or col, seg=8, rings=3)
    m.limb(b, c, w * 1.05, col, bevel=0.1)


def eye_pair(m, cy, w, h, d, z0, col, brow, sz=(0.3, 0.17), ey=0.12):
    fz = z0 + d / 2 + 0.01
    for sx in (-1, 1):
        m.box((sx * w * 0.22, cy + h * ey, fz), (w * sz[0], h * sz[1], 0.1), col)
        m.box((sx * w * 0.22, cy + h * (ey + 0.2), fz - 0.02), (w * 0.34, h * 0.08, 0.12), brow, rot=(0, 0, -sx * 22))


def legs_std(m, sp, col, foot, top=3.0, w=1.2, fw=1.6):
    for sx in (-1, 1):
        m.box((sx * sp, 0.3, 0.35), (fw, 0.6, 2.2), foot, bevel=0.12)
        m.box((sx * sp, 0.6 + (top - 0.6) / 2, 0), (w, top - 0.6, w), col, bevel=0.1)


# ---------------------------------------------------------------- 4 Bone Reaper
def bone_reaper():
    m = new("r4_boss_bone_reaper")
    bone, blk, grn, iron, pur = "#EFE6CF", "#1C1626", "#7CFF4A", "#7C7F88", "#4B2E83"
    m.box((0, 0.2, 0), (6.2, 0.4, 3.6), "#4A4458", bevel=0.05)
    for x, z, h in ((-2.7, 1.1, 1.1), (2.8, 1.0, 0.9), (-2.0, -1.3, 1.0), (2.3, -1.2, 1.2), (0.0, 1.4, 0.7)):
        m.box((x, 0.4 + h / 2, z), (0.9, h, 0.45), "#8C8F99", bevel=0.05)
    legs_std(m, 1.3, bone, bone, top=3.0, w=1.1, fw=1.6)
    m.box((0, 3.1, 0), (3.8, 0.8, 1.8), bone, bevel=0.08)
    m.box((0, 4.5, 0), (3.2, 2.2, 1.8), "#2A2430", bevel=0.1)
    for y in (3.8, 4.35, 4.9, 5.4):
        m.box((0, y, 0.1), (3.5, 0.3, 2.1), bone, bevel=0.05)
    m.box((0, 4.6, -0.2), (0.4, 2.4, 1.6), bone)
    m.ball((0, 4.45, 1.1), 0.7, grn, seg=8, rings=3)
    m.box((0, 4.45, 1.0), (1.5, 1.5, 0.3), iron, bevel=0.05) if False else None
    m.set_muzzle((0, 4.45, 1.8))
    m.box((0, 5.75, -0.1), (6.2, 0.9, 2.6), blk, bevel=0.12)
    for sx in (-1, 1):
        m.ball((sx * 3.2, 5.7, 0), 1.0, blk, seg=8, rings=3)
    m.box((0, 4.0, -1.2), (4.6, 3.4, 0.4), pur, bevel=0.05)
    for i in range(6):
        m.box((-2.0 + i * 0.8, 2.0, -1.2), (0.6, 1.0 + (0.5 if i % 2 else 0), 0.3), pur)
    for i in range(7):
        m.box((-2.4 + i * 0.8, 3.95, 1.05), (0.6, 0.9 + (0.5 if i % 2 else 0), 0.2), blk)
    hy = 7.0
    m.box((0, hy, 0.1), (2.8, 2.4, 2.4), bone, bevel=0.15)
    face(m, hy, 2.8, 2.4, 2.4, z0=0.1, eye=grn, brow=K, mouth="grin", mc="#16121C")
    hat(m, "iron", hy, 2.8, 2.4, 2.4, iron, "#5A5C66", z0=0.1)
    arm2(m, (-3.2, 5.7, 0), (-3.7, 4.3, 0.4), (-3.6, 3.0, 1.0), 0.9, bone, blk)
    m.box((-3.6, 2.8, 1.0), (1.1, 1.0, 1.1), bone, bevel=0.1)
    m.limb((-3.6, 2.5, 0.9), (-2.4, 7.6, -0.2), 0.3, "#E4DCC4")
    m.limb((-2.4, 7.6, -0.2), (-4.6, 7.9, -0.2), 0.5, iron)
    m.pyramid((-5.0, 7.9, -0.2), (0.5, 0.35), 1.0, iron, rot=(0, 0, 90))
    m.box((-3.4, 7.6, -0.2), (1.8, 0.3, 0.4), iron)
    arm2(m, (3.2, 5.7, 0), (3.7, 4.2, 0.5), (3.6, 3.0, 1.2), 0.9, bone, blk)
    m.box((3.6, 2.8, 1.3), (1.5, 1.3, 1.5), bone, bevel=0.1)
    for dx in (-0.5, 0, 0.5):
        m.pyramid((3.6 + dx, 2.5, 2.2), (0.35, 0.35), 0.8, "#E4DCC4", rot=(90, 0, 0))
    m.fit(height=8.0)
    return m


# ---------------------------------------------------------------- 5 Golden Sphinx
def golden_sphinx():
    m = new("r5_boss_golden_sphinx")
    gold, lap, stone, turq = "#E8B423", "#2B4DA8", "#B97A34", "#2FE0D0"
    m.box((0, 3.6, -0.8), (3.8, 2.8, 5.2), gold, bevel=0.25)
    for z, y in ((1.5, 0), (-2.9, 0)):
        for sx in (-1, 1):
            m.box((sx * 1.35, 1.6, z), (1.2, 3.0, 1.2), gold, bevel=0.1)
            m.box((sx * 1.35, 0.3, z + 0.4), (1.6, 0.6, 2.0), "#D49A10", bevel=0.1)
            for dx in (-0.4, 0, 0.4):
                m.pyramid((sx * 1.35 + dx, 0.3, z + 1.5), (0.35, 0.35), 0.5, "#F4EAD0", rot=(90, 0, 0))
    m.box((0, 5.0, 1.9), (3.0, 3.2, 1.8), gold, bevel=0.2)
    hy = 6.2
    m.box((0, hy, 2.6), (2.8, 2.5, 2.4), "#D9A32A", bevel=0.15)
    eye_pair(m, hy, 2.8, 2.5, 2.4, 2.6, turq, "#6A4A10")
    m.box((0, hy - 0.7, 3.82), (1.3, 0.2, 0.1), "#6A4A10")
    hat(m, "headdress", hy, 2.8, 2.5, 2.4, gold, lap, z0=2.6)
    for k in range(4):
        m.box((0, hy + 1.3, 2.6 - 0.3 + 0.0), (0.0, 0.0, 0.0), lap) if False else None
    m.box((0, hy + 1.4, 2.6), (3.1, 0.3, 2.7), lap)
    m.box((0, hy - 1.25, 3.7), (0.7, 1.2, 0.5), "#6A4A10")
    m.ball((0, hy + 0.85, 3.95), 0.5, turq, seg=8, rings=3, scale=(1, 1, 0.5))
    m.set_muzzle((0, hy + 0.85, 4.3))
    m.box((0, 5.8, 0.6), (5.0, 3.0, 0.5), stone, bevel=0.1)
    for dx in (-1.8, -0.9, 0.9, 1.8):
        m.box((dx, 5.8, 0.88), (0.35, 2.6, 0.1), lap)
    chain(m, [(0, 3.8, -3.3), (0, 2.8, -4.4), (0, 3.9, -5.4)], 0.7, gold)
    m.ball((0, 4.6, -5.6), 0.8, turq, seg=6, rings=3)
    for sx in (-1, 1):
        m.box((sx * 0.9, 4.5, -5.6), (0.8, 0.8, 0.2), gold, rot=(0, 0, sx * 30))
    m.fit(height=8.0)
    return m


# ---------------------------------------------------------------- 6 Bog Hydra
def bog_hydra():
    m = new("r6_boss_bog_hydra")
    olive, dkol, mud, yel = "#6E8F2E", "#3E5A1A", "#8A6A45", "#FFE63B"
    for sx in (-1, 1):
        for z in (1.8, -1.8):
            m.box((sx * 2.3, 1.2, z), (1.6, 2.4, 1.6), olive, bevel=0.15)
            m.box((sx * 2.3, 0.3, z + 0.4), (2.0, 0.6, 2.2), dkol, bevel=0.1)
    m.box((0, 3.6, 0), (5.6, 3.4, 5.4), olive, bevel=0.3)
    m.box((0, 2.2, 0.2), (4.8, 0.8, 4.8), mud, bevel=0.1)
    m.box((0, 5.3, -0.4), (5.0, 0.5, 4.2), "#4F7A24", bevel=0.1)
    for dx, dz, hh in ((-1.6, -1.6, 1.9), (-1.2, -1.8, 1.4), (1.5, -1.5, 1.7), (1.9, -1.2, 1.3), (0.3, -2.0, 1.6)):
        m.box((dx, 5.5 + hh / 2, dz), (0.2, hh, 0.2), "#6A4A2B")
        m.box((dx, 5.5 + hh * 0.85, dz), (0.35, 0.8, 0.35), "#8A5A2B")
    chain(m, [(0, 3.2, -2.6), (0, 2.4, -4.0), (0, 2.0, -5.2)], 1.5, olive)
    for x, sc, ys, nx in ((-3.0, 0.8, 6.3, -2.2), (0, 1.0, 7.5, 0), (3.0, 0.8, 6.3, 2.2)):
        m.limb((nx * 0.8, 4.6, 1.0), (x, ys - 0.5, 2.6), 1.5 * sc, olive, bevel=0.15)
        hw, hh, hd = 2.2 * sc + 0.3, 1.8 * sc + 0.2, 2.5 * sc + 0.3
        hz = 3.2
        m.box((x, ys, hz), (hw, hh, hd), olive, bevel=0.15)
        m.box((x, ys - hh * 0.35, hz + hd * 0.1), (hw * 0.9, hh * 0.3, hd * 1.05), dkol, bevel=0.05)
        eye_pair(m, ys, hw, hh, hd, hz, yel, "#1B2A0A", ey=0.2)
        for sx in (-1, 1):
            m.pyramid((x + sx * hw * 0.25, ys - hh * 0.18, hz + hd / 2 + 0.05), (0.25, 0.25), 0.35, W, rot=(180, 0, 0))
        if x == 0:
            for dx in (-0.7, 0, 0.7):
                m.pyramid((dx, ys + hh / 2, hz - 0.3), (0.5, 0.5), 0.9 if dx == 0 else 0.6, dkol)
    m.set_muzzle((0, 7.1, 4.6))
    m.fit(height=8.0)
    return m


# ---------------------------------------------------------------- 7 Scrap Titan
def scrap_titan():
    m = new("r7_boss_scrap_titan")
    base, blue, red, yel, org = "#7A6B5F", "#3A6FB0", "#B8432C", "#E8B423", "#FF5A1F"
    for sx in (-1, 1):
        m.box((sx * 1.6, 0.4, 0.4), (2.2, 0.8, 2.6), "#4A4038", bevel=0.1)
        for k in range(3):
            m.cyl((sx * 1.6, 1.1 + k * 0.7, 0), 1.0 - k * 0.04, 0.65, "#2A2622", sides=8)
        m.cyl((sx * 1.6, 3.3, 0), 0.9, 0.4, "#5A5048", sides=8)
    m.box((0, 3.7, 0), (5.2, 0.8, 2.6), "#4A4038", bevel=0.1)
    for y, c, h in ((4.5, blue, 1.0), (5.5, red, 1.0), (6.5, yel, 0.9)):
        m.box((0, y, 0), (5.0, h, 2.8), base, bevel=0.1)
        m.box((-1.4, y, 1.42), (1.8, h * 0.8, 0.1), c)
        m.box((1.3, y, 1.42), (1.5, h * 0.7, 0.1), dk(c, 0.85))
    m.box((0, 5.4, 1.5), (2.2, 2.2, 0.3), "#3A322C", bevel=0.05)
    m.box((0, 5.4, 1.7), (1.5, 1.5, 0.25), org, bevel=0.05)
    m.box((0, 5.4, 1.85), (0.7, 0.7, 0.15), "#FFD27A")
    m.set_muzzle((0, 5.4, 2.1))
    for sx in (-1, 1):  # car-door shoulders
        m.box((sx * 3.1, 6.4, 0), (1.6, 1.6, 2.2), "#B8C4D0" if sx < 0 else "#C8503A", bevel=0.1)
        m.box((sx * 3.1, 6.4, 1.12), (1.2, 0.5, 0.1), "#5A6A78")
    for sx in (-1, 1):
        m.cyl((sx * 1.2, 7.6, -1.5), 0.3, 2.6, "#4A4038", sides=6)
        m.cyl((sx * 1.2, 8.8, -1.5), 0.42, 0.3, "#2A2622", sides=6)
    hy = 7.5
    m.box((0, hy, 0.2), (3.0, 2.2, 2.4), base, bevel=0.15)
    m.box((0, hy + 1.2, 0.5), (3.2, 0.3, 2.2), "#C8503A", bevel=0.05)  # hood
    for sx in (-1, 1):
        m.box((sx * 0.7, hy + 0.2, 1.42), (0.7, 0.35, 0.1), org)
        m.box((sx * 0.7, hy + 0.55, 1.42), (0.8, 0.14, 0.12), K, rot=(0, 0, -sx * 20))
    m.box((0, hy - 0.6, 1.42), (2.4, 0.5, 0.15), "#2A2622")
    for i in range(7):
        m.box((-1.0 + i * 0.33, hy - 0.6, 1.52), (0.2, 0.4, 0.06), "#D0D4DA")
    # claw crane (right)
    m.box((-3.3, 4.6, 0.2), (1.2, 1.4, 1.2), "#4A4038", bevel=0.1)
    m.limb((-3.3, 5.2, 0.2), (-3.9, 3.0, 1.6), 0.9, "#E8B423")
    m.limb((-3.9, 3.0, 1.6), (-3.9, 1.4, 2.4), 0.7, "#B8892A")
    for dx in (-0.5, 0.5):
        m.limb((-3.9 + dx, 1.5, 2.4), (-3.9 + dx * 1.4, 0.3, 2.8), 0.35, "#6E7480")
    m.limb((-3.9, 1.5, 2.0), (-3.9, 0.3, 2.0), 0.35, "#6E7480")
    # hydraulic fist (left)
    m.limb((3.3, 5.0, 0.2), (3.7, 2.6, 0.9), 1.1, "#5A5048")
    m.cyl((4.3, 3.8, 0.4), 0.2, 2.2, "#B0B4BC", sides=6, rot=(0, 0, -10))
    m.box((3.7, 1.9, 1.0), (2.0, 1.8, 2.0), "#6E7480", bevel=0.15)
    m.box((3.7, 2.3, 1.0), (2.1, 0.3, 2.1), yel)
    m.fit(height=8.0)
    return m


# ---------------------------------------------------------------- 8 Neon Shogun
def neon_shogun():
    m = new("r8_boss_neon_shogun")
    crim, blk, gold, cy, mg = "#C8203A", "#14162E", "#FFD23F", "#3DF2FF", "#FF3DAE"
    legs_std(m, 1.2, blk, "#0A0B1A", top=2.8, w=1.5, fw=1.9)
    for sx in (-1, 1):
        m.box((sx * 1.2, 1.7, 0.78), (0.1, 1.8, 0.06), cy)
    m.frustum((0, 2.6, 0), (4.6, 3.0), (3.6, 2.4), 1.2, crim)
    m.box((0, 3.8, 0), (3.8, 2.6, 2.4), blk, bevel=0.2)
    for y in (3.0, 4.6):
        m.box((0, y, 1.22), (3.6, 0.1, 0.06), cy)
    m.box((0, 3.8, 1.22), (0.1, 2.2, 0.06), mg)
    m.cyl((0, 4.0, 1.5), 0.75, 0.6, "#2A2E5A", sides=10, rot=(90, 0, 0))
    m.cyl((0, 4.0, 1.85), 0.5, 0.15, mg, sides=10, rot=(90, 0, 0))
    m.set_muzzle((0, 4.0, 2.0))
    for sx in (-1, 1):
        for k in range(3):
            m.box((sx * (3.0 + k * 0.15), 5.5 - k * 0.55, 0), (1.9 - k * 0.15, 0.7, 2.6 - k * 0.1), crim if k != 1 else dk(crim, 0.8), bevel=0.1)
    hy = 6.8
    m.box((0, hy, 0.1), (2.6, 2.2, 2.3), "#1E2140", bevel=0.12)
    m.box((0, hy + 0.5, 0.1), (3.4, 1.4, 2.8), crim, bevel=0.15)
    m.box((0, hy + 0.2, 1.45), (2.4, 0.2, 0.1), blk)
    for sx in (-1, 1):
        m.box((sx * 0.75, hy - 0.15, 1.28), (0.8, 0.3, 0.1), cy, rot=(0, 0, -sx * 14))
        m.limb((sx * 1.7, hy + 0.6, 0), (sx * 2.5, hy + 1.2, 0), 0.5, gold)
        m.limb((sx * 2.5, hy + 1.2, 0), (sx * 2.7, hy + 2.0, 0), 0.4, gold)
        m.pyramid((sx * 2.7, hy + 1.9, 0), (0.4, 0.4), 0.5, gold, rot=(0, 0, -sx * 15))
    m.box((0, hy - 0.8, 1.25), (1.2, 0.3, 0.1), "#2A2E5A")
    arm2(m, (-3.1, 5.2, 0), (-3.6, 3.8, 0.5), (-3.5, 2.7, 1.2), 1.0, blk, crim)
    m.box((-3.5, 2.5, 1.3), (1.2, 1.1, 1.2), crim, bevel=0.1)
    m.limb((-3.5, 2.3, 1.2), (-2.5, 7.4, -0.8), 0.35, "#2A2E5A")
    m.box((-2.9, 4.8, -0.5), (0.9, 0.3, 0.5), gold, rot=(0, 0, 10))
    m.limb((-2.5, 7.4, -0.8), (0.0, 9.0, -1.2), 0.5, cy) if False else None
    m.limb((-3.5, 2.3, 1.2), (-2.5, 7.4, -0.8), 0.7, cy)
    m.limb((-2.5, 7.4, -0.8), (-1.6, 9.4, -1.0), 0.5, cy)
    arm2(m, (3.1, 5.2, 0), (3.6, 3.8, 0.5), (3.5, 2.7, 1.2), 1.0, blk, crim)
    m.box((3.5, 2.5, 1.4), (1.6, 1.5, 1.6), blk, bevel=0.15)
    m.box((3.5, 2.9, 1.4), (1.7, 0.2, 1.7), cy)
    m.fit(height=8.0)
    return m


# ---------------------------------------------------------------- 9 Orbital Guardian
def orbital_guardian():
    m = new("r9_boss_orbital_guardian")
    wh, nv, cy, org = "#E8EDF5", "#1F2A47", "#7DFFF0", "#F28C1F"
    legs_std(m, 1.3, wh, nv, top=3.0, w=1.5, fw=2.0)
    for sx in (-1, 1):
        m.box((sx * 1.3, 0.9, 0.78), (1.2, 0.3, 0.06), org)
        m.box((sx * 1.3, 1.3, 0.78), (1.2, 0.3, 0.06), nv)
    m.box((0, 3.3, 0), (4.0, 0.9, 2.4), nv, bevel=0.1)
    m.box((0, 4.9, 0), (4.0, 2.6, 2.6), wh, bevel=0.2)
    m.box((0, 4.9, 1.32), (2.2, 2.0, 0.2), nv, bevel=0.05)
    m.box((0, 4.9, 1.5), (1.4, 1.4, 0.2), cy, bevel=0.05)
    for sx in (-1, 1):
        m.box((sx * 1.3, 4.0, 1.4), (0.5, 0.3, 0.1), org)
        m.box((sx * 3.2, 5.9, 0), (2.4, 1.8, 3.0), wh, bevel=0.2)
        m.box((sx * 3.2, 5.9, 1.52), (1.6, 1.0, 0.1), nv)
        m.box((sx * 3.2, 6.8, 0.6), (2.0, 0.2, 1.4), org)
    hy = 7.2
    m.box((0, hy, 0.1), (2.6, 2.3, 2.4), wh, bevel=0.15)
    m.box((0, hy + 0.05, 1.3), (2.2, 0.7, 0.12), cy)
    m.box((0, hy - 0.65, 1.3), (1.0, 0.15, 0.1), nv)
    m.limb((0, hy + 1.1, 0.1), (0, hy + 1.9, -0.1), 0.35, wh)
    m.box((0, hy + 2.0, -0.1), (0.5, 0.5, 0.5), cy)
    n = 14
    for i in range(n):
        a = 2 * math.pi * i / n
        x, y = math.cos(a) * 2.7, hy + math.sin(a) * 2.7
        m.box((x, y, -1.9), (1.0, 0.7, 0.45), cy, rot=(0, 0, math.degrees(a) + 90))
    m.box((0, hy - 1.2, -1.2), (0.8, 1.4, 1.4), nv)
    m.limb((0, hy - 1.0, -0.9), (0, hy - 2.2, -1.9), 0.5, nv)
    arm2(m, (-3.3, 5.6, 0), (-3.9, 4.2, 0.4), (-3.8, 3.2, 1.2), 1.1, wh, nv)
    m.box((-3.8, 3.1, 2.0), (1.5, 1.5, 3.0), nv, bevel=0.15)
    m.box((-3.8, 3.1, 3.7), (1.1, 1.1, 1.0), "#5A6A8A")
    m.box((-3.8, 3.1, 4.3), (0.8, 0.8, 0.3), cy)
    m.box((-3.8, 4.0, 2.0), (1.6, 0.2, 2.0), org)
    m.set_muzzle((-3.8, 3.1, 4.55))
    arm2(m, (3.3, 5.6, 0), (3.9, 4.2, 0.4), (3.8, 3.0, 1.2), 1.1, wh, nv)
    m.box((3.8, 2.6, 1.3), (1.8, 1.6, 1.8), wh, bevel=0.15)
    m.box((3.8, 2.6, 2.22), (1.2, 0.8, 0.1), nv)
    m.fit(height=8.0)
    return m


# ---------------------------------------------------------------- 10 Hive Queen
def hive_queen():
    m = new("r10_boss_hive_queen")
    lime, amb, pink, yel = "#7FBF3F", "#E0A020", "#F08AC0", "#FFF04A"
    legs_std(m, 1.2, amb, "#8A5A10", top=2.8, w=1.3, fw=1.7)
    m.box((0, 3.3, 0), (3.6, 1.2, 2.6), "#2E4A1E", bevel=0.1)
    m.box((0, 4.9, 0), (3.6, 2.6, 2.8), amb, bevel=0.3)
    for dx, dy in ((-1.0, 5.4), (0.9, 4.3), (0.2, 5.8), (-0.6, 4.0)):
        m.box((dx, dy, 1.42), (0.5, 0.5, 0.1), lime)
    hy = 7.0
    m.box((0, hy, 0.2), (3.0, 2.4, 2.6), lime, bevel=0.2)
    eye_pair(m, hy, 3.0, 2.4, 2.6, 0.2, yel, "#2E4A1E", sz=(0.28, 0.22))
    for sx in (-1, 1):
        m.limb((sx * 0.5, hy - 0.8, 1.5), (sx * 1.0, hy - 1.2, 2.2), 0.55, "#E6E0C2")
        m.pyramid((sx * 1.0, hy - 1.2, 2.2), (0.55, 0.5), 0.8, "#E6E0C2", rot=(90, 0, sx * -30))
    m.box((0, hy - 0.8, 1.52), (1.2, 0.4, 0.1), "#2E4A1E")
    hat(m, "spikecrown", hy, 3.0, 2.4, 2.6, amb, z0=0.2)
    for sx in (-1, 1):
        arm2(m, (sx * 2.0, 5.8, 0), (sx * 3.0, 4.6, 0.6), (sx * 2.9, 3.5, 1.5), 0.9, lime, amb)
        m.box((sx * 2.9, 3.3, 1.7), (1.1, 0.9, 1.1), amb, bevel=0.1)
        for dx in (-0.3, 0.3):
            m.pyramid((sx * 2.9 + dx, 3.1, 2.5), (0.3, 0.3), 0.9, "#E6E0C2", rot=(90, 0, 0))
    for sx, c, y in ((-1, "#F2D060", 6.4), (1, "#F2D060", 6.4), (-1, "#B6E03A", 5.0), (1, "#B6E03A", 5.0)):
        m.box((sx * 2.6, y, -1.6), (2.6, 1.6 if y > 6 else 1.3, 0.15), c, rot=(0, 0, sx * (-25 if y > 6 else 25)))
    m.limb((0, 4.9, -1.2), (0, 5.4, -2.6), 1.1, amb)
    m.ball((0, 5.6, -3.7), 2.3, pink, seg=8, rings=4, scale=(1, 1.05, 1.1))
    for dx, dy, dz in ((-1.2, 6.6, -3.5), (1.1, 5.4, -4.6), (0, 7.2, -3.4), (-1.5, 4.9, -3.4), (1.5, 6.4, -3.3)):
        m.box((dx, dy, dz), (0.7, 0.7, 0.4), "#FFF0DC")
    m.set_muzzle((0, hy - 0.8, 1.8))
    m.fit(height=8.0)
    return m


# ---------------------------------------------------------------- 11 Mutant Behemoth
def mutant_behemoth():
    m = new("r11_boss_mutant_behemoth")
    gr, pu, gl = "#7FBF3F", "#6B2F9A", "#A6FF3A"
    for sx in (-1, 1):
        m.box((sx * 1.8, 0.4, 0.5), (2.4, 0.8, 2.8), pu, bevel=0.1)
        m.box((sx * 1.8, 1.7, 0.0), (2.0, 2.0, 2.0), gr, bevel=0.15)
    m.box((0, 3.9, -0.4), (6.0, 4.0, 4.6), gr, bevel=0.4)
    for dx, dy, dz in ((-2.0, 4.8, 1.4), (1.8, 3.4, 1.5), (0.4, 5.4, -0.5), (-1.8, 3.0, -1.5)):
        m.box((dx, dy, dz), (1.4, 1.1, 1.0), pu, bevel=0.2)
    m.box((0, 3.4, 1.9), (2.0, 2.0, 0.3), "#4A8A20", bevel=0.05)
    m.box((0, 3.4, 2.1), (1.3, 1.3, 0.2), gl, bevel=0.05)
    for sx in (-1, 1):
        m.cyl((sx * 1.4, 6.0, -2.0), 0.9, 2.0, "#6A6E78", sides=8, rot=(0, 0, sx * 12))
        m.cyl((sx * 1.4, 6.8, -2.0), 0.7, 0.3, gl, sides=8)
        m.box((sx * 1.4, 5.0, -1.1), (0.4, 1.6, 0.2), gl)
    hy, hz = 6.2, 1.8
    m.box((0, hy, hz), (5.4, 2.6, 3.2), gr, bevel=0.3)
    m.box((0, hy - 0.5, hz + 1.55), (4.6, 1.2, 0.2), "#16121C")
    for i in range(7):
        m.box((-1.8 + i * 0.6, hy - 0.2, hz + 1.66), (0.3, 0.4, 0.1), W)
    for dx, dy, sc in ((-1.9, 1.7, 1.0), (1.9, 1.7, 1.0), (0, 1.9, 1.2)):
        m.ball((dx, hy + dy, hz + 0.2), 0.55 * sc, gr, seg=6, rings=2)
        m.box((dx, hy + dy, hz + 0.65), (0.5 * sc, 0.5 * sc, 0.2), gl)
    m.set_muzzle((0, hy - 0.5, hz + 1.9))
    m.limb((-2.8, 4.8, 0.5), (-4.2, 3.0, 1.3), 1.6, gr, bevel=0.2)
    m.frustum((-4.2, 1.3, 1.3), (1.3, 1.3), (2.4, 2.4), 3.0, pu)
    for dx, dy in ((-0.9, 3.4), (0.9, 2.4), (0, 1.7)):
        m.box((-4.2 + dx, dy, 1.3 + 1.2), (0.4, 0.4, 0.4), "#4A1F6A")
    m.limb((2.8, 4.8, 0.5), (4.0, 3.0, 1.3), 1.5, gr, bevel=0.2)
    m.box((4.0, 2.4, 1.6), (1.6, 1.4, 1.6), gr, bevel=0.2)
    for dx in (-0.6, 0, 0.6):
        m.pyramid((4.0 + dx, 2.0, 2.5), (0.5, 0.5), 1.3, pu, rot=(90, 0, 0))
    m.fit(height=8.0)
    return m


# ---------------------------------------------------------------- 12 Prism Guardian
def prism_guardian():
    m = new("r12_boss_prism_guardian")
    pc, bl = "#BDEFF5", "#2459C8"
    cols = ["#E070C8", "#FFE066", "#7FE0F0"]
    for sx in (-1, 1):
        m.box((sx * 1.3, 0.35, 0.3), (1.9, 0.7, 2.4), "#8ACBD6", bevel=0.1)
        m.box((sx * 1.3, 1.9, 0), (1.4, 3.1, 1.4), pc, bevel=0.15)
    m.box((0, 3.7, 0), (4.0, 0.9, 2.4), "#8ACBD6", rot=(0, 0, 0), bevel=0.1)
    m.box((0, 5.0, 0), (3.8, 2.6, 2.6), pc, bevel=0.2)
    m.box((0, 5.0, 0.0), (3.4, 2.6, 3.0), "#A9E0EA", rot=(0, 45, 0), bevel=0.1)
    m.ball((0, 5.0, 1.3), 0.8, bl, seg=6, rings=3, scale=(1, 1.2, 0.7))
    m.box((0, 5.0, 1.3), (0.7, 0.7, 0.3), "#5A8AF0", rot=(0, 0, 45))
    for sx in (-1, 1):
        m.box((sx * 2.8, 6.2, 0), (1.8, 1.4, 2.2), "#A9E0EA", bevel=0.15, rot=(0, 0, sx * 10))
    for dx, dz, hh, c, rz in ((-2.6, -0.5, 2.2, 0, 14), (-1.6, -1.1, 2.8, 1, 8), (-0.2, -1.4, 2.4, 2, 0), (1.4, -1.1, 3.0, 0, -8),
                              (2.6, -0.5, 2.0, 1, -14), (0.7, -1.6, 1.8, 2, -4)):
        m.pyramid((dx, 6.0, dz), (0.9, 0.9), hh, cols[c], rot=(0, 0, rz), sides=4)
    for sx in (-1, 1):
        m.pyramid((sx * 3.1, 6.9, 0.3), (0.8, 0.8), 1.5, cols[0 if sx < 0 else 1], rot=(0, 0, sx * -10))
    hy = 7.1
    m.box((0, hy, 0.1), (2.6, 2.3, 2.4), pc, bevel=0.1)
    m.box((0, hy, 0.1), (2.3, 2.3, 2.6), "#A9E0EA", rot=(0, 45, 0), bevel=0.05)
    eye_pair(m, hy, 2.6, 2.3, 2.4, 0.1, bl, "#5A8AA0")
    m.pyramid((0, hy + 1.1, 0), (0.7, 0.7), 1.0, "#E070C8")
    arm2(m, (-3.1, 5.5, 0), (-3.7, 4.2, 0.4), (-3.6, 3.2, 1.2), 1.1, pc, "#8ACBD6")
    m.box((-3.6, 3.1, 2.2), (1.4, 1.4, 3.2), "#8ACBD6", bevel=0.1, rot=(0, 0, 0))
    m.frustum((-3.6, 3.1, 3.7), (1.4, 1.4), (0.5, 0.5), 1.4, bl, rot=(90, 0, 0))
    m.pyramid((-3.6, 3.1, 5.0), (0.5, 0.5), 0.8, "#7FE0F0", rot=(90, 0, 0))
    m.set_muzzle((-3.6, 3.1, 5.8))
    arm2(m, (3.1, 5.5, 0), (3.7, 4.2, 0.4), (3.6, 3.0, 1.2), 1.1, pc, "#8ACBD6")
    m.box((3.6, 2.6, 1.4), (1.8, 1.7, 1.8), "#A9E0EA", bevel=0.1, rot=(0, 20, 0))
    m.fit(height=8.0)
    return m


# ---------------------------------------------------------------- 13 Iron Galleon
def iron_galleon():
    m = new("r13_boss_iron_galleon")
    wood, iron, sail, brass, gold = "#7A4A2A", "#6B6F7A", "#F4EAD0", "#C9A24A", "#E8B423"
    for sx in (-1, 1):
        for z in (2.6, -2.4):
            m.box((sx * 1.9, 1.6, z), (1.6, 3.2, 1.6), "#5A3A20", bevel=0.12)
            m.box((sx * 1.9, 0.3, z + 0.4), (2.0, 0.6, 2.4), iron, bevel=0.1)
    m.frustum((0, 3.2, -0.4), (4.2, 8.0), (6.0, 8.8), 2.6, wood)
    for y in (3.6, 4.6):
        m.box((0, y, -0.4), (6.1, 0.18, 8.9), iron) if False else None
    for sx in (-1, 1):
        m.box((sx * 2.75, 4.2, -0.4), (0.2, 0.3, 8.6), iron)
        m.box((sx * 2.85, 5.2, -0.4), (0.3, 0.3, 8.8), "#5A3A20")
    m.frustum((0, 3.4, 3.9), (3.2, 1.5), (4.6, 2.2), 2.2, wood, rot=(0, 0, 0)) if False else None
    m.box((0, 4.2, 4.3), (4.6, 2.4, 1.4), wood, bevel=0.15)
    m.box((0, 5.0, 5.0), (4.2, 0.3, 0.1), iron)
    fz = 5.06
    for sx in (-1, 1):
        m.box((sx * 1.2, 4.7, fz), (0.9, 0.7, 0.12), "#FFE63B")
        m.box((sx * 1.2, 5.2, fz), (1.2, 0.22, 0.14), "#16121C", rot=(0, 0, -sx * 20))
    m.cyl((0, 3.7, 5.1), 0.55, 1.5, brass, sides=8, rot=(90, 0, 0))
    m.cyl((0, 3.7, 5.85), 0.7, 0.2, "#A0802F", sides=8, rot=(90, 0, 0))
    m.set_muzzle((0, 3.7, 6.0))
    for i in range(6):
        m.box((-0.9 + i * 0.36, 3.2, fz), (0.2, 0.4, 0.08), W)
    # masts + sails
    for z, h, sw in ((1.4, 8.0, 4.6), (-2.4, 7.4, 4.2)):
        m.limb((0, 4.4, z), (0, h, z), 0.45, "#4A2E18")
        m.box((0, h - 1.0, z), (sw + 0.6, 0.25, 0.3), "#4A2E18")
        m.box((0, h - 2.4, z + 0.05), (sw, 2.8, 0.2), sail)
        m.box((0, h - 2.4, z + 0.2), (0.9, 0.8, 0.06), K)
        m.box((0, h - 2.8, z + 0.2), (0.5, 0.4, 0.06), K)
    # cannons right side
    for z in (-2.8, -1.0, 0.8, 2.6):
        m.cyl((-3.4, 4.2, z), 0.4, 1.0, brass, sides=8, rot=(0, 0, 90))
        m.cyl((-3.95, 4.2, z), 0.5, 0.15, "#A0802F", sides=8, rot=(0, 0, 90))
    # stern castle + flag
    m.box((0, 5.6, -3.7), (4.6, 2.2, 2.4), gold, bevel=0.15)
    m.box((0, 6.8, -3.7), (4.8, 0.3, 2.6), "#C99A10")
    m.limb((1.6, 6.8, -4.3), (1.6, 8.0, -4.3), 0.18, "#4A2E18")
    m.box((2.2, 7.7, -4.3), (1.1, 0.7, 0.08), K)
    # anchor claw arm (left)
    m.box((3.0, 4.2, 0.6), (1.0, 1.4, 1.4), iron, bevel=0.1)
    m.limb((3.2, 4.2, 0.6), (4.2, 3.0, 1.6), 0.8, iron)
    m.limb((4.2, 3.0, 1.6), (4.3, 1.4, 2.4), 0.6, iron)
    for dz in (-1.0, 1.0):
        m.limb((4.3, 1.4, 2.4), (4.3 + 0.2, 0.5, 2.4 + dz), 0.45, "#8A8F99")
        m.pyramid((4.5, 0.5, 2.4 + dz), (0.5, 0.4), 0.6, "#8A8F99", rot=(180, 0, 0))
    m.fit(height=8.0)
    return m


# ---------------------------------------------------------------- 14 Spectral Admiral
def spectral_admiral():
    m = new("r14_boss_spectral_admiral")
    pale, navy, sil, teal = "#CFE8E4", "#274B6B", "#9FB3B0", "#8CFFE0"
    legs_std(m, 1.2, "#16304A", "#0E2236", top=2.6, w=1.4, fw=1.8)
    m.frustum((0, 1.8, 0), (4.8, 3.2), (3.8, 2.6), 3.2, navy)
    for i in range(9):
        m.box((-2.0 + i * 0.5, 1.5 - (0.3 if i % 2 else 0), 1.5 - (0.1 if i % 3 == 0 else 0)), (0.45, 0.9 + (0.4 if i % 2 else 0), 0.3), navy)
        m.box((-2.0 + i * 0.5, 1.4, -1.55), (0.45, 1.1 + (0.5 if i % 3 else 0), 0.3), navy)
    m.box((0, 4.5, 0), (3.9, 2.2, 2.7), navy, bevel=0.2)
    for k in range(5):
        m.box((-0.5, 5.2 - k * 0.55, 1.4), (0.22, 0.22, 0.1), sil)
        m.box((0.5, 5.2 - k * 0.55, 1.4), (0.22, 0.22, 0.1), sil)
    for sx in (-1, 1):
        m.box((sx * 3.0, 5.7, 0), (2.2, 0.5, 2.4), sil, bevel=0.08)
        for k in range(4):
            m.ball((sx * (2.3 + k * 0.35), 5.2 - k * 0.1, 1.0 - k * 0.0), 0.2, sil, seg=5, rings=2)
        m.ball((sx * 2.8, 5.2, 0), 1.0, navy, seg=8, rings=3)
    hy = 6.9
    m.box((0, hy, 0.1), (2.7, 2.3, 2.4), pale, bevel=0.15)
    eye_pair(m, hy, 2.7, 2.3, 2.4, 0.1, teal, "#274B6B")
    m.box((0, hy - 0.7, 1.32), (1.2, 0.2, 0.1), "#274B6B")
    hat(m, "bicorne", hy, 2.7, 2.3, 2.4, navy, sil, z0=0.1)
    m.box((0, hy + 1.6, 1.0), (0.8, 0.8, 0.15), pale)
    m.box((0, hy + 1.65, 1.1), (0.4, 0.25, 0.06), K)
    arm2(m, (-3.0, 5.2, 0), (-3.6, 3.9, 0.4), (-3.5, 3.0, 1.1), 1.0, navy, sil)
    m.box((-3.5, 2.9, 1.2), (1.1, 1.0, 1.1), pale, bevel=0.1)
    m.limb((-3.5, 2.6, 1.1), (-3.0, 7.6, -0.3), 0.4, sil)
    m.box((-3.0, 7.6, -0.3), (2.6, 0.35, 0.4), sil)
    for sx in (-1, 1):
        m.limb((-3.0 + sx * 1.2, 7.6, -0.3), (-3.0 + sx * 1.5, 6.6, -0.3), 0.4, sil)
        m.pyramid((-3.0 + sx * 1.5, 6.5, -0.3), (0.55, 0.4), 0.7, sil, rot=(180, 0, 0))
    m.limb((-3.0, 7.6, -0.3), (-3.0, 5.4, -0.3), 0.8, sil)
    arm2(m, (3.0, 5.2, 0), (3.6, 3.9, 0.4), (3.5, 2.8, 1.2), 1.0, navy, sil)
    m.box((3.5, 2.6, 1.4), (1.7, 1.6, 1.7), pale, bevel=0.12)
    m.cyl((0.0, 2.5, 1.7), 0.5, 0.9, "#6A7A78", sides=6)
    m.ball((0.0, 3.2, 1.7), 0.55, teal, seg=6, rings=3, scale=(1, 1.4, 1))
    m.set_muzzle((0.0, 3.4, 1.9))
    m.fit(height=8.0)
    return m


# ---------------------------------------------------------------- 15 Kraken
def kraken():
    m = new("r15_boss_kraken")
    bl, pk, yel = "#3A4EA8", "#F08AC0", "#FFF04A"
    m.ball((0, 4.4, 0), 3.2, bl, seg=10, rings=4, scale=(1.0, 0.95, 1.0))
    ang = [(-155, 3.6), (-115, 3.9), (-65, 3.9), (-25, 3.6), (155, 3.4), (115, 3.8)]
    for deg, r in ang:
        a = math.radians(deg)
        x0, z0 = math.cos(a) * 1.8, math.sin(a) * 1.8
        x1, z1 = math.cos(a) * r, math.sin(a) * r
        x2, z2 = math.cos(a) * (r + 1.2), math.sin(a) * (r + 1.2)
        chain(m, [(x0, 3.4, z0), (x1, 1.6, z1), (x2, 0.5, z2)], 1.5, bl)
        for k in range(3):
            m.box((x1 - math.cos(a) * 0.0, 0.5 + k * 0.4, z1), (0.4, 0.3, 0.4), pk)
    for sx in (-1, 1):
        chain(m, [(sx * 2.6, 4.6, 1.0), (sx * 3.9, 5.6, 2.8), (sx * 3.6, 7.0, 3.8)], 1.6, bl)
        m.ball((sx * 3.5, 7.6, 4.0), 1.2, bl, seg=7, rings=3)
        for k in range(3):
            m.box((sx * 3.0, 5.4 + k * 0.5, 3.4 - k * 0.0), (0.4, 0.3, 0.4), pk) if False else None
        for k in range(3):
            m.box((sx * 2.6, 5.3 + k * 0.45, 2.9 + k * 0.25), (0.4, 0.3, 0.4), pk)
    m.box((0, 5.2, 2.3), (3.8, 2.4, 1.7), bl, bevel=0.3)
    eye_pair(m, 5.5, 3.8, 2.4, 3.0, 1.4, yel, "#1B245A", sz=(0.26, 0.2))
    m.box((0, 4.5, 3.35), (1.4, 0.9, 0.5), "#2A2E6A", bevel=0.05)
    m.pyramid((0, 4.6, 3.5), (1.0, 0.8), 1.0, "#E8E0C8", rot=(105, 0, 0))
    m.set_muzzle((0, 4.4, 4.2))
    for dx, dy, dz in ((-1.4, 7.2, 0.5), (1.3, 7.4, 0.0), (0.0, 7.6, -0.8), (-0.4, 7.0, 1.4)):
        m.box((dx, dy, dz), (0.7, 0.7, 0.4), pk)
    m.limb((1.3, 7.3, -0.4), (2.6, 10.2, -0.8), 0.35, "#6A4A2A")
    m.box((2.0, 8.2, -0.6), (1.7, 1.0, 0.1), "#D8CCA8", rot=(0, 0, -10)) if False else None
    for dx, dy in ((-0.7, 7.3), (0.5, 7.0), (-1.7, 6.5)):
        m.pyramid((dx, dy, 1.0), (0.4, 0.4), 0.45, "#D8CCA8")
    m.fit(height=8.0)
    return m


# ---------------------------------------------------------------- 16 Void Emperor (9 m)
def void_emperor():
    m = new("r16_boss_void_emperor")
    blk, gold, mg, pu, sw = "#0E0A1A", "#F2BF1A", "#FF3AE0", "#4A2D8A", "#B9B2D6"
    legs_std(m, 1.3, blk, "#1A1230", top=3.0, w=1.6, fw=2.0)
    for sx in (-1, 1):
        m.box((sx * 1.3, 1.9, 0.82), (0.2, 2.0, 0.06), mg)
        m.box((sx * 1.3, 3.0, 0.0), (1.8, 0.2, 1.8), gold)
    m.box((0, 3.4, 0), (4.0, 0.9, 2.4), "#1A1230", bevel=0.1)
    m.box((0, 5.0, 0), (4.0, 2.8, 2.7), blk, bevel=0.2)
    m.box((0, 4.9, 1.42), (2.0, 2.0, 0.2), gold, bevel=0.05)
    m.ball((0, 4.9, 1.6), 0.75, mg, seg=8, rings=3, scale=(1, 1, 0.6))
    m.set_muzzle((0, 4.9, 2.1))
    for y in (3.9, 6.0):
        m.box((0, y, 1.42), (3.8, 0.1, 0.06), mg)
    for sx in (-1, 1):
        for k in range(3):
            m.box((sx * (3.0 + k * 0.1), 6.3 - k * 0.6, 0), (2.2 - k * 0.2, 0.7, 2.8), "#1A1230" if k % 2 else blk, bevel=0.1)
            m.pyramid((sx * (3.0 + k * 0.4), 6.7 - k * 0.5, 0.8 - k * 0.5), (0.5, 0.5), 1.1 - k * 0.2, gold, rot=(0, 0, -sx * 20))
        m.box((sx * 3.2, 6.7, 0), (2.4, 0.15, 3.0), gold)
    hy = 7.6
    m.box((0, hy, 0.1), (2.8, 2.5, 2.6), blk, bevel=0.15)
    eye_pair(m, hy, 2.8, 2.5, 2.6, 0.1, mg, "#1A1230")
    m.box((0, hy - 0.7, 1.42), (1.4, 0.25, 0.1), "#1A1230")
    m.box((0, hy + 1.3, 0.1), (3.0, 0.4, 2.8), gold, bevel=0.05)
    for i, x in enumerate((-1.2, -0.6, 0, 0.6, 1.2)):
        m.pyramid((x, hy + 1.45, 0.1), (0.5, 0.5), 1.9 if i == 2 else (1.4 if i % 2 else 1.1), gold)
    m.box((0, 4.6, -1.5), (5.0, 5.0, 0.3), "#1A1230", bevel=0.05)
    m.box((0, 4.6, -1.7), (4.4, 4.4, 0.15), pu)
    for i in range(14):
        m.box((-1.9 + (i % 5) * 0.95, 6.1 - (i // 5) * 1.3 - (0.3 if i % 2 else 0), -1.8), (0.28, 0.28, 0.08), gold)
    for i in range(6):
        m.box((-2.1 + i * 0.84, 1.9, -1.55), (0.6, 1.1 + (0.5 if i % 2 else 0), 0.25), "#1A1230")
    arm2(m, (-3.3, 5.9, 0), (-3.9, 4.5, 0.4), (-3.8, 3.4, 1.2), 1.2, blk, gold)
    m.box((-3.8, 3.2, 1.3), (1.3, 1.2, 1.3), "#1A1230", bevel=0.1)
    m.limb((-3.8, 3.0, 1.3), (-2.6, 8.4, -0.6), 0.35, "#2A2040")
    m.box((-3.4, 4.8, 0.2), (1.2, 0.3, 0.5), gold, rot=(0, 0, 10))
    m.limb((-3.4, 4.6, 0.3), (-2.0, 10.3, -0.9), 0.75, sw)
    m.limb((-3.4, 4.6, 0.3), (-2.0, 10.3, -0.9), 0.2, mg)
    m.pyramid((-1.9, 10.2, -0.9), (0.75, 0.3), 0.9, sw, rot=(0, 0, 10))
    arm2(m, (3.3, 5.9, 0), (3.9, 4.5, 0.4), (3.8, 3.3, 1.3), 1.2, blk, gold)
    m.box((3.8, 3.0, 1.6), (1.7, 1.5, 1.7), blk, bevel=0.15)
    for dx in (-0.6, 0, 0.6):
        m.pyramid((3.8 + dx, 2.8, 2.5), (0.4, 0.4), 1.0, gold, rot=(90, 0, 0))
    m.fit(height=9.0)
    return m


BOSSES = [(4, bone_reaper), (5, golden_sphinx), (6, bog_hydra), (7, scrap_titan), (8, neon_shogun), (9, orbital_guardian),
          (10, hive_queen), (11, mutant_behemoth), (12, prism_guardian), (13, iron_galleon), (14, spectral_admiral), (15, kraken),
          (16, void_emperor)]
