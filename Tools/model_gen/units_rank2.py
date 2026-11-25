"""Rank ladder #2: the 20 missing player-unit models (9 units x Super Rare + Legend, medic Common + Legend).
Same soldier space as units.py / units_rank.py: 1.3 m tall, front +Z, right hand = -X, feet at y=0.
Colors "G:#RRGGBB" = rank glow (emissive primitive); everything else is flat / matte.
Existing files are never touched: every function here builds a NEW model."""
import math
import numpy as np
from glbkit import Model, shade
from units import SKIN, DARK, GUN, WHITE, EYE, legs, torso, head, arm, helmet
from units_rank import PUR, GPUR, BLU, GBLU, GOLD, BRASS, eyes_on, lenses, cuff, along, tube

IVORY = "#F2F0E6"
GOLD2 = "#E8B923"
GWARM = "G:#FFF3DC"
NAVY = "#1B2A5E"
BLK = "#1E1F25"
CH = "#2B2B33"


# ------------------------------------------------------------------------------ shared helpers
def arms(m, col, trim=None, right=(-0.2, 0.57, 0.2), left=(0.285, 0.46, 0.06), sh=0.24, w=0.10, hand=SKIN):
    a1, a2 = (-sh, 0.70, 0.0), (sh, 0.70, 0.0)
    arm(m, -1, a1, right, col, hand=hand, w=w)
    arm(m, 1, a2, left, col, hand=hand, w=w)
    if trim:
        cuff(m, a1, right, trim, w=w + 0.015)
        cuff(m, a2, left, trim, w=w + 0.015)


def gun(m, body, barrel, glow, x=-0.2, y=0.6, trim=None):
    """Scoped rifle with a glowing side cell and muzzle ring. Returns the muzzle point."""
    m.box((x, y - 0.02, 0.02), (0.08, 0.14, 0.2), shade(body, 0.8))
    m.box((x, y, 0.26), (0.09, 0.12, 0.40), body, bevel=0.012)
    m.box((x, y + 0.005, 0.64), (0.05, 0.05, 0.36), barrel)
    m.box((x, y + 0.095, 0.26), (0.065, 0.065, 0.22), barrel)
    m.box((x, y + 0.095, 0.375), (0.05, 0.05, 0.02), glow)
    m.box((x - 0.055, y, 0.2), (0.03, 0.09, 0.16), glow)
    m.box((x, y + 0.005, 0.82), (0.08, 0.08, 0.03), glow)
    if trim:
        m.box((x, y + 0.066, 0.33), (0.095, 0.014, 0.3), trim)
    return (x, y + 0.005, 0.85)


def fur(m, rs, c, size, n, pal, faces=("+x", "-x", "+z", "-z", "+y"), base=0.11, hgt=0.12, ymin=None, sink=0.012):
    """Chunky grass tufts (short fat pyramids) scattered on the faces of a box, drooping like shingles."""
    cx, cy, cz = c
    sx, sy, sz = size
    placed = 0
    while placed < n:
        f = faces[rs.randint(len(faces))]
        u, v = rs.uniform(-0.5, 0.5, 2)
        d = rs.uniform(100, 125)
        if f == "+y":
            p, rot = (cx + u * sx, cy + sy / 2, cz + v * sz), (rs.uniform(-25, 25), rs.uniform(0, 90), rs.uniform(-25, 25))
        elif f == "+z":
            p, rot = (cx + u * sx, cy + v * sy, cz + sz / 2), (d, 0, rs.uniform(-20, 20))
        elif f == "-z":
            p, rot = (cx + u * sx, cy + v * sy, cz - sz / 2), (-d, 0, rs.uniform(-20, 20))
        elif f == "+x":
            p, rot = (cx + sx / 2, cy + u * sy, cz + v * sz), (rs.uniform(-20, 20), 0, -d)
        else:
            p, rot = (cx - sx / 2, cy + u * sy, cz + v * sz), (rs.uniform(-20, 20), 0, d)
        if ymin is not None and f != "+y" and p[1] < ymin:
            continue
        nv = {"+y": (0, 1, 0), "+z": (0, 0, 1), "-z": (0, 0, -1), "+x": (1, 0, 0), "-x": (-1, 0, 0)}[f]
        p = tuple(p[i] - nv[i] * sink for i in range(3))  # sink the base into the surface so the tuft is welded to the body
        b = rs.uniform(base * 0.8, base * 1.25)
        h = rs.uniform(hgt * 0.8, hgt * 1.2)
        m.pyramid(p, (b, b), h, pal[rs.randint(len(pal))], rot=rot)
        placed += 1


# ========================================================================================= RIFLEMAN
def rifleman_super_rare():
    m = Model("rifleman_super_rare")
    ST, DK, PL, CAPE = "#3B5FA8", "#2A3F73", "#DDE3EE", NAVY
    legs(m, "#26386A", "#14151C")
    for sx in (-1, 1):
        m.box((sx * 0.095, 0.2, 0.088), (0.14, 0.07, 0.03), PL)
    torso(m, ST, w=1.1)
    m.box((0, 0.55, 0.15), (0.36, 0.32, 0.05), PL, bevel=0.015)  # white-silver chest plate
    m.box((0, 0.715, 0.155), (0.36, 0.03, 0.055), BLU)
    m.box((0, 0.385, 0.155), (0.36, 0.03, 0.055), BLU)
    m.box((0, 0.55, 0.178), (0.05, 0.28, 0.012), BLU)
    for sx in (-1, 1):  # chunky pauldrons, wider than the Rare
        m.box((sx * 0.3, 0.76, 0), (0.18, 0.10, 0.26), ST, bevel=0.025)
        m.box((sx * 0.3, 0.815, 0), (0.18, 0.03, 0.26), BLU)
    m.box((0.26, 0.52, -0.19), (0.21, 0.50, 0.05), CAPE)  # half-cape, LEFT shoulder only
    m.box((0.26, 0.27, -0.19), (0.22, 0.03, 0.06), BLU)
    m.box((0.36, 0.52, -0.19), (0.03, 0.50, 0.06), BLU)
    head(m)
    m.box((0, 1.03, 0), (0.60, 0.40, 0.54), DK, bevel=0.05)  # full-face helmet, tan chin stays visible
    m.box((0, 0.995, 0.272), (0.42, 0.075, 0.02), GBLU)  # glowing visor slit
    m.box((0, 0.995, 0.262), (0.50, 0.12, 0.012), "#14181F")
    m.box((0, 1.275, -0.02), (0.05, 0.13, 0.30), BLU)  # fin
    for sx in (-1, 1):
        m.box((sx * 0.305, 1.03, 0), (0.02, 0.14, 0.30), BLU)
    arms(m, ST, BLU)
    z = gun(m, "#2A2C33", "#1D2028", GBLU, trim=BLU)
    m.set_muzzle(z)
    m.fit(height=1.3)
    return m


def rifleman_legend():
    m = Model("rifleman_legend")
    legs(m, NAVY, IVORY)
    for sx in (-1, 1):
        m.box((sx * 0.095, 0.115, 0.0), (0.155, 0.03, 0.155), GOLD2)
    torso(m, NAVY, w=1.15, belt=GOLD2)
    m.box((0, 0.55, 0.15), (0.40, 0.34, 0.05), IVORY, bevel=0.02)  # ivory armor
    m.box((0, 0.727, 0.155), (0.40, 0.035, 0.06), GOLD2)
    m.box((0, 0.383, 0.155), (0.40, 0.035, 0.06), GOLD2)
    for sx in (-1, 1):
        m.box((sx * 0.17, 0.55, 0.178), (0.035, 0.30, 0.012), GOLD2)
        m.box((sx * 0.2, 0.55, 0.0), (0.03, 0.3, 0.3), GOLD2)
    m.box((0, 0.57, 0.18), (0.10, 0.10, 0.02), GWARM)  # chest gem
    m.box((0, 0.57, 0.172), (0.13, 0.13, 0.012), GOLD2)
    m.box((0, 0.34, 0.162), (0.08, 0.05, 0.03), GOLD2)
    for sx in (-1, 1):  # round gold pauldrons + small wing plates
        m.cyl((sx * 0.3, 0.76, 0), 0.15, 0.10, GOLD2, sides=8)
        m.box((sx * 0.42, 0.82, 0), (0.04, 0.15, 0.20), IVORY, rot=(0, 0, -sx * 25))
    m.box((0, 0.46, -0.19), (0.42, 0.62, 0.05), IVORY)  # long cape, gold border + emblem
    m.box((0, 0.17, -0.19), (0.44, 0.04, 0.06), GOLD2)
    for sx in (-1, 1):
        m.box((sx * 0.215, 0.46, -0.19), (0.03, 0.62, 0.06), GOLD2)
    m.box((0, 0.55, -0.222), (0.14, 0.14, 0.03), GOLD2)
    head(m, grin=True)
    helmet(m, IVORY, y=1.2, w=0.6, d=0.54, h=0.24, brim=False)  # tall peaked helmet
    m.box((0, 1.1, 0.28), (0.5, 0.04, 0.1), GOLD2)
    m.box((0, 1.12, 0), (0.62, 0.035, 0.56), GOLD2)
    m.box((0, 1.345, 0), (0.07, 0.15, 0.46), GOLD2)  # crest fin, front to back
    for sx in (-1, 1):
        m.box((sx * 0.335, 1.2, -0.02), (0.05, 0.14, 0.24), GOLD2, rot=(0, 0, -sx * 20))
        m.box((sx * 0.39, 1.27, -0.04), (0.04, 0.10, 0.18), GOLD2, rot=(0, 0, -sx * 35))
    arms(m, NAVY, GOLD2, sh=0.25)
    z = gun(m, IVORY, GOLD2, GWARM, trim=GOLD2)
    m.set_muzzle(z)
    m.fit(height=1.3)
    return m


# =================================================================================== MACHINE GUNNER
def machine_gunner_super_rare():
    m = Model("machine_gunner_super_rare")
    OR, BELT, BP = "#F28C1F", "#F2C21A", "#3A3A44"
    legs(m, CH, "#15161B", w=1.25)
    torso(m, OR, w=1.55, d=0.30)
    m.box((0, 0.55, 0.16), (0.46, 0.30, 0.05), CH, bevel=0.015)  # chest plate with blue edges
    m.box((0, 0.705, 0.165), (0.46, 0.03, 0.06), BLU)
    m.box((0, 0.395, 0.165), (0.46, 0.03, 0.06), BLU)
    for sx in (-1, 1):  # big square shoulder shield plates
        m.box((sx * 0.37, 0.76, 0), (0.20, 0.13, 0.32), CH, bevel=0.02)
        m.box((sx * 0.37, 0.83, 0), (0.20, 0.03, 0.32), BLU)
        m.box((sx * 0.47, 0.76, 0), (0.03, 0.13, 0.33), BLU)
        m.box((sx * 0.12, 0.2, 0.087), (0.17, 0.12, 0.03), CH)
    m.box((0, 0.55, -0.26), (0.42, 0.36, 0.2), BP, bevel=0.03)  # ammo-box backpack
    m.box((0, 0.55, -0.365), (0.44, 0.05, 0.02), BLU)
    m.box((0, 0.55, -0.365), (0.05, 0.3, 0.02), BLU)
    m.limb((-0.16, 0.74, -0.2), (-0.3, 0.84, 0.0), 0.06, BELT, d=0.04)  # belt over the shoulder into the gun
    m.limb((-0.3, 0.84, 0.0), (-0.3, 0.7, 0.2), 0.06, BELT, d=0.04)
    m.limb((-0.3, 0.7, 0.2), (-0.26, 0.62, 0.3), 0.06, BELT, d=0.04)
    head(m)
    helmet(m, CH, w=0.62, h=0.22, brim=False)
    m.box((0, 1.325, 0), (0.07, 0.03, 0.4), BLU)
    lenses(m, GBLU, y=0.985, z=0.262, frame=BLK, fw=0.52)
    m.box((0, 1.02, -0.265), (0.56, 0.22, 0.05), CH)
    arms(m, OR, None, right=(-0.22, 0.56, 0.22), left=(0.36, 0.46, 0.06), sh=0.3, w=0.13)
    x, y = -0.22, 0.60
    m.box((x, y, 0.28), (0.14, 0.15, 0.44), BLK, bevel=0.015)
    for sx in (-1, 1):  # twin barrels
        m.box((x + sx * 0.04, y + 0.01, 0.62), (0.055, 0.06, 0.32), "#111216")
    for z in (0.56, 0.74):  # glowing blue barrel rings
        m.box((x, y + 0.01, z), (0.15, 0.085, 0.025), GBLU)
    m.box((x + 0.12, y - 0.1, 0.24), (0.1, 0.14, 0.16), BELT, bevel=0.015)
    m.box((x, y - 0.03, 0.03), (0.09, 0.13, 0.14), "#2A2B33")
    m.set_muzzle((x, y + 0.01, 0.8))
    m.fit(height=1.3)
    return m


def machine_gunner_legend():
    m = Model("machine_gunner_legend")
    OR = "#F28C1F"
    legs(m, BLK, "#15161B", w=1.3)
    torso(m, OR, w=1.6, d=0.30, belt=GOLD)
    m.box((0, 0.55, 0.16), (0.50, 0.32, 0.05), BLK, bevel=0.02)
    m.box((0, 0.715, 0.165), (0.50, 0.035, 0.06), GOLD)
    m.box((0, 0.385, 0.165), (0.50, 0.035, 0.06), GOLD)
    for s in (-1, 1):  # crossed ammo belts
        m.limb((s * 0.2, 0.74, 0.2), (-s * 0.2, 0.38, 0.2), 0.065, GOLD, d=0.045)
        for t in (0.25, 0.5, 0.75):
            p = along((s * 0.2, 0.74, 0.225), (-s * 0.2, 0.38, 0.225), t)
            m.box(p, (0.04, 0.06, 0.02), BLK)
    for sx in (-1, 1):  # spiked gold pauldrons
        m.box((sx * 0.38, 0.76, 0), (0.2, 0.11, 0.32), BLK, bevel=0.02)
        for dz in (-0.07, 0.07):
            m.pyramid((sx * 0.38, 0.815, dz), (0.12, 0.12), 0.15, GOLD)
        m.box((sx * 0.48, 0.76, 0), (0.03, 0.11, 0.33), GOLD)
    m.cyl((0, 0.55, -0.28), 0.2, 0.24, GOLD, sides=8, rot=(90, 0, 0))  # studded ammo drum
    m.cyl((0, 0.55, -0.28), 0.17, 0.27, BLK, sides=8, rot=(90, 0, 0))
    for a in range(0, 360, 60):
        m.box((0.17 * math.cos(math.radians(a)), 0.55 + 0.17 * math.sin(math.radians(a)), -0.42), (0.05, 0.05, 0.03), GOLD)
    for sx in (-1, 1):
        m.box((sx * 0.1, 0.72, -0.2), (0.07, 0.08, 0.05), "#2A2B33")  # exhaust vents
        m.box((sx * 0.1, 0.40, -0.2), (0.07, 0.08, 0.05), "#2A2B33")
    head(m)
    helmet(m, BLK, w=0.62, h=0.22, brim=False)
    m.box((0, 0.955, 0.245), (0.5, 0.3, 0.03), BLK)  # face plate
    m.box((0, 1.0, 0.263), (0.38, 0.06, 0.02), GWARM)  # glowing visor slit
    for sx in (-1, 1):  # two short chunky horns
        m.pyramid((sx * 0.24, 1.25, 0), (0.13, 0.13), 0.22, GOLD, rot=(0, 0, -sx * 35))
    m.box((0, 1.325, 0), (0.07, 0.03, 0.4), GOLD)
    arms(m, OR, GOLD, right=(-0.22, 0.56, 0.22), left=(0.36, 0.46, 0.06), sh=0.31, w=0.13)
    x, y = -0.22, 0.62  # rotary gatling
    m.cyl((x, y, 0.3), 0.115, 0.36, BLK, sides=8, rot=(90, 0, 0))
    m.cyl((x, y, 0.2), 0.125, 0.05, GOLD, sides=8, rot=(90, 0, 0))
    m.cyl((x, y, 0.55), 0.03, 0.55, GOLD, sides=6, rot=(90, 0, 0))  # gold core
    for k in range(6):
        a = math.radians(k * 60)
        m.cyl((x + 0.065 * math.cos(a), y + 0.065 * math.sin(a), 0.62), 0.032, 0.5, "#111216", sides=6, rot=(90, 0, 0))
    m.cyl((x, y, 0.82), 0.1, 0.04, GWARM, sides=8, rot=(90, 0, 0))  # glowing barrel ring
    m.cyl((x, y, 0.46), 0.1, 0.04, GOLD, sides=8, rot=(90, 0, 0))
    m.box((x, y - 0.03, 0.03), (0.09, 0.13, 0.14), "#2A2B33")
    m.set_muzzle((x, y, 0.85))
    m.fit(height=1.3)
    return m


# ========================================================================================== SNIPER
def sniper_super_rare():
    m = Model("sniper_super_rare")
    CL, DK = "#2C3544", "#1B2230"
    OLV, MOSS, STR = "#5B6B2E", "#3E5A2A", "#A8975A"
    rs = np.random.RandomState(11)
    legs(m, "#222A38", "#14151A", w=0.88)
    torso(m, CL, w=0.88, d=0.24)
    m.box((0, 0.23, 0), (0.37, 0.26, 0.28), CL)  # cloak skirt
    m.box((0, 0.105, 0), (0.385, 0.03, 0.295), BLU)
    m.box((0, 0.54, -0.17), (0.34, 0.42, 0.05), CL)
    m.box((0, 0.335, -0.17), (0.34, 0.03, 0.06), BLU)
    head(m, skin="#171B24", eyes=GBLU)  # face in shadow, small glowing eyes
    m.box((0, 1.20, 0), (0.58, 0.20, 0.54), CL, bevel=0.05)  # deep hood
    for sx in (-1, 1):
        m.box((sx * 0.275, 0.97, -0.02), (0.06, 0.40, 0.5), DK)
    m.box((0, 0.97, -0.25), (0.56, 0.40, 0.06), DK)
    m.box((0, 1.115, 0.275), (0.5, 0.04, 0.03), BLU)  # hood trim
    arms(m, CL, BLU, right=(-0.19, 0.58, 0.2), left=(0.26, 0.46, 0.06), sh=0.205, w=0.09, hand="#171B24")
    pal = (OLV, MOSS, STR)
    fur(m, rs, (0, 1.2, 0), (0.58, 0.2, 0.54), 7, pal, faces=("+y", "+y", "-z", "+x", "-x"), base=0.1, hgt=0.11)
    fur(m, rs, (0, 0.76, 0), (0.3, 0.0, 0.2), 4, pal, faces=("+y",), base=0.09, hgt=0.1, sink=0.0)
    x, y = -0.19, 0.62
    m.box((x, y - 0.03, 0.04), (0.07, 0.14, 0.2), "#1B1C21")
    m.box((x, y, 0.3), (0.065, 0.09, 0.44), "#2A2C33")
    m.box((x, y + 0.005, 0.72), (0.045, 0.045, 0.78), "#14151A")  # very long rifle
    m.cyl((x, y + 0.105, 0.34), 0.055, 0.3, "#14151A", sides=8, rot=(90, 0, 0))  # big round scope
    m.cyl((x, y + 0.105, 0.5), 0.047, 0.03, GBLU, sides=8, rot=(90, 0, 0))
    m.box((x, y + 0.055, 0.34), (0.03, 0.05, 0.05), "#14151A")
    m.limb((x, y - 0.03, 0.8), (x, y - 0.13, 0.95), 0.03, "#2A2C33")  # folded bipod
    fur(m, rs, (x, y + 0.01, 0.62), (0.065, 0.07, 0.3), 3, pal, faces=("+y", "+y", "-x"), base=0.07, hgt=0.08)
    m.set_muzzle((x, y + 0.005, 1.12))
    m.fit(height=1.3)
    return m


def sniper_legend():
    m = Model("sniper_legend")
    rs = np.random.RandomState(2026)
    MOSS, OLV, LEAF, STR, BRN = "#2F4A24", "#5B6B2E", "#7C9A3A", "#B3A25C", "#5A4630"
    pal = (MOSS, OLV, LEAF, STR, BRN)
    legs(m, MOSS, BRN, w=0.88)
    torso(m, MOSS, w=1.0, d=0.28, belt=BRN)
    head(m, skin="#3A2E20", eyes=EYE)
    for sx in (-1, 1):  # tiny glowing pupils peek out
        m.box((sx * 0.12, 0.98, 0.25), (0.03, 0.03, 0.012), GWARM)
    m.box((0, 1.1, -0.02), (0.62, 0.40, 0.58), MOSS, bevel=0.05)  # shaggy hood dome
    m.box((0, 0.95, -0.26), (0.6, 0.42, 0.08), MOSS)
    arms(m, MOSS, None, right=(-0.19, 0.58, 0.2), left=(0.26, 0.46, 0.06), sh=0.24, w=0.12, hand=BRN)
    x, y = -0.19, 0.62
    m.box((x, y - 0.03, 0.04), (0.08, 0.15, 0.22), "#6E5F44")  # burlap-wrapped rifle, 1.2 m
    m.box((x, y, 0.3), (0.075, 0.1, 0.44), "#7A6A4A")
    m.box((x, y + 0.005, 0.76), (0.05, 0.05, 0.86), "#5A4B33")
    m.box((x, y + 0.1, 0.32), (0.07, 0.07, 0.26), "#3E3626")
    m.box((x, y + 0.1, 0.46), (0.05, 0.05, 0.02), GWARM)  # the only shiny part
    m.box((0.19, 1.26, 0.12), (0.04, 0.05, 0.03), GOLD)  # tiny gold clip on the hood = rank hint
    # fur coat: everything covered in overlapping tufts
    for sx in (-1, 1):
        fur(m, rs, (sx * 0.0836, 0.2, 0), (0.114, 0.2, 0.15), 6, pal, faces=("+x" if sx > 0 else "-x", "+z", "-z"), base=0.09, hgt=0.11)
    fur(m, rs, (0, 0.53, 0), (0.38, 0.46, 0.28), 34, pal, faces=("+x", "-x", "+z", "-z", "+z", "-z"), base=0.12, hgt=0.13)
    fur(m, rs, (-0.215, 0.64, 0.1), (0.10, 0.14, 0.22), 7, pal, faces=("-x", "+y", "+z", "-z"), base=0.09, hgt=0.1)
    fur(m, rs, (0.255, 0.58, 0.03), (0.10, 0.26, 0.10), 6, pal, faces=("+x", "+z", "-z"), base=0.09, hgt=0.1)
    fur(m, rs, (0, 0.76, 0), (0.34, 0.0, 0.24), 6, pal, faces=("+y",), base=0.12, hgt=0.12, sink=0.0)
    fur(m, rs, (0, 1.1, -0.02), (0.62, 0.40, 0.58), 36, pal, faces=("+y", "+y", "+y", "+x", "-x", "-z", "+z"), base=0.13, hgt=0.14, ymin=1.13)
    for sx in (-0.2, -0.1, 0.1, 0.2):  # long fringe hanging over the forehead
        m.pyramid((sx, 1.12, 0.285), (0.11, 0.11), 0.13, pal[rs.randint(5)], rot=(180, 0, 0))
    fur(m, rs, (x, y + 0.005, 0.76), (0.05, 0.05, 0.86), 10, pal, faces=("+y", "-x", "+x"), base=0.08, hgt=0.09)
    m.set_muzzle((x, y + 0.005, 1.2))
    m.fit(height=1.3)
    return m


# ===================================================================================== ROCKET SOLDIER
def _launcher_pod(m):
    m.box((0, 0.58, -0.2), (0.30, 0.32, 0.14), CH)
    d = np.array([0.0, math.cos(math.radians(35)), -math.sin(math.radians(35))])
    for sx in (-1, 1):
        for dy in (-0.07, 0.07):
            b = np.array([sx * 0.065, 0.58 + dy, -0.27])
            m.cyl(tuple(b + d * 0.14), 0.045, 0.28, "#5F6B35", sides=6, rot=(-35, 0, 0))
            m.pyramid(tuple(b + d * 0.28), (0.1, 0.1), 0.09, "#FF8C1A", sides=6, rot=(-35, 0, 0))


def rocket_soldier_super_rare():
    m = Model("rocket_soldier_super_rare")
    RED, OLIVE = "#CC3330", "#3F4823"
    legs(m, "#5A1A1A", CH)
    torso(m, RED, w=1.15)
    m.box((0, 0.56, 0.15), (0.40, 0.30, 0.04), CH, bevel=0.015)
    m.box((0, 0.715, 0.155), (0.40, 0.03, 0.05), BLU)
    m.box((0, 0.405, 0.155), (0.40, 0.03, 0.05), BLU)
    for sx in (-1, 1):
        m.box((sx * 0.29, 0.74, 0), (0.15, 0.10, 0.26), CH, bevel=0.02)
        m.box((sx * 0.29, 0.795, 0), (0.15, 0.03, 0.26), BLU)
    m.limb((-0.17, 0.72, 0.18), (0.17, 0.4, 0.18), 0.05, "#3A3D45", d=0.04)  # mini-rocket bandolier
    for t in (0.15, 0.38, 0.62, 0.85):
        p = along((-0.17, 0.72, 0.2), (0.17, 0.4, 0.2), t)
        m.box(p, (0.045, 0.08, 0.04), "#8A3B1E")
        m.box((p[0], p[1] + 0.055, p[2]), (0.045, 0.035, 0.04), "#FF8C1A")
    _launcher_pod(m)
    for sx in (-1, 1):  # blue-edged winglets, new silhouette feature
        m.box((sx * 0.26, 0.6, -0.2), (0.22, 0.3, 0.05), CH, rot=(0, 0, -sx * 18))
        m.box((sx * 0.35, 0.68, -0.2), (0.04, 0.3, 0.06), BLU, rot=(0, 0, -sx * 18))
    for sx in (-1, 1):  # glowing blue thrusters
        m.box((sx * 0.065, 0.4, -0.25), (0.07, 0.06, 0.07), GBLU)
    head(m)
    helmet(m, "#3A1414", w=0.58, h=0.22)
    m.box((0, 1.325, 0), (0.07, 0.03, 0.4), BLU)
    lenses(m, GBLU, size=(0.13, 0.10, 0.02), frame=CH, fw=0.5)  # pilot goggles
    arms(m, RED, None, right=(-0.28, 0.60, 0.16), sh=0.24)
    tx, ty = -0.32, 0.79
    m.cyl((tx, ty, 0.12), 0.115, 0.95, OLIVE, sides=8, rot=(90, 0, 0))
    m.cyl((tx, ty, -0.34), 0.14, 0.08, CH, sides=8, rot=(90, 0, 0))
    m.cyl((tx, ty, 0.3), 0.13, 0.04, BLU, sides=8, rot=(90, 0, 0))
    m.cyl((tx, ty, 0.62), 0.145, 0.05, GBLU, sides=8, rot=(90, 0, 0))  # glowing muzzle ring
    m.pyramid((tx, ty, 0.5), (0.16, 0.16), 0.22, "#FF8C1A", rot=(90, 0, 0), sides=6)
    m.box((tx, ty - 0.15, 0.2), (0.05, 0.08, 0.1), "#2A2B33")
    m.set_muzzle((tx, ty, 0.8))
    m.fit(height=1.3)
    return m


def rocket_soldier_legend():
    m = Model("rocket_soldier_legend")
    CR = "#B31420"
    legs(m, "#7A0F18", IVORY)
    torso(m, CR, w=1.2, belt=GOLD)
    m.box((0, 0.56, 0.155), (0.42, 0.32, 0.045), IVORY, bevel=0.02)
    m.box((0, 0.725, 0.16), (0.42, 0.035, 0.055), GOLD)
    m.box((0, 0.395, 0.16), (0.42, 0.035, 0.055), GOLD)
    for sx in (-1, 1):
        m.box((sx * 0.3, 0.75, 0), (0.17, 0.11, 0.28), IVORY, bevel=0.02)
        m.box((sx * 0.3, 0.81, 0), (0.17, 0.035, 0.28), GOLD)
        m.pyramid((sx * 0.3, 0.825, 0), (0.1, 0.1), 0.1, GOLD)
    m.limb((-0.18, 0.72, 0.19), (0.18, 0.4, 0.19), 0.055, GOLD, d=0.04)  # bandolier of gold-tipped rockets
    for t in (0.12, 0.34, 0.56, 0.78):
        p = along((-0.18, 0.72, 0.21), (0.18, 0.4, 0.21), t)
        m.box(p, (0.05, 0.09, 0.045), IVORY)
        m.pyramid((p[0], p[1] + 0.045, p[2]), (0.05, 0.05), 0.05, GOLD, sides=6)
    m.box((0, 0.34, 0.172), (0.09, 0.09, 0.03), GOLD, rot=(0, 0, 45))  # blast-star buckle
    m.box((0, 0.34, 0.172), (0.12, 0.035, 0.03), GOLD)
    for sx in (-1, 1):  # short gold fin-wings
        m.box((sx * 0.21, 0.66, -0.2), (0.26, 0.06, 0.2), GOLD, rot=(0, 0, -sx * 25))
        m.box((sx * 0.31, 0.72, -0.2), (0.08, 0.05, 0.2), IVORY, rot=(0, 0, -sx * 25))
    m.box((0, 0.5, -0.2), (0.24, 0.3, 0.14), "#5A0A12")
    m.box((0, 0.42, -0.3), (0.14, 0.16, 0.06), GWARM)  # glowing thruster
    head(m, grin=True)
    helmet(m, CR, w=0.58, h=0.22)
    m.box((0, 1.12, 0.265), (0.3, 0.05, 0.03), GOLD)
    for i, (z, h) in enumerate(((0.12, 0.12), (-0.02, 0.2), (-0.16, 0.12))):  # flame crest, 3 stacked wedge blocks
        m.pyramid((0, 1.3, z), (0.13, 0.13), h, GOLD, rot=(0, 45, 0))
    arms(m, CR, GOLD, right=(-0.28, 0.60, 0.16), sh=0.25)
    tx, ty = -0.32, 0.8
    m.box((tx, ty, -0.05), (0.4, 0.28, 0.2), "#5A0A12")  # cluster housing
    for dx, dy in ((0.0, 0.075), (-0.085, -0.06), (0.085, -0.06)):
        cx, cy = tx + dx, ty + dy
        m.cyl((cx, cy, 0.14), 0.08, 0.95, IVORY, sides=8, rot=(90, 0, 0))
        m.cyl((cx, cy, 0.62), 0.095, 0.05, GOLD, sides=8, rot=(90, 0, 0))
        m.pyramid((cx, cy, 0.5), (0.15, 0.15), 0.2, GOLD, rot=(90, 0, 0), sides=6)
        m.pyramid((cx, cy, 0.68), (0.06, 0.06), 0.05, GWARM, rot=(90, 0, 0), sides=6)
    m.box((tx, ty - 0.2, 0.2), (0.05, 0.1, 0.1), "#2A2B33")
    m.set_muzzle((tx, ty - 0.015, 0.78))
    m.fit(height=1.3)
    return m


# ========================================================================================== MEDIC
def medic_common():
    m = Model("medic_common")
    BR, GR = "#8A6A3C", "#40B359"
    legs(m, "#BDBDC2", "#4A4A52", w=0.9)
    torso(m, "#F2F2F2", w=0.92, belt="#9A9AA2")
    m.limb((-0.15, 0.73, 0.14), (0.2, 0.40, 0.14), 0.04, BR, d=0.03)  # satchel strap
    m.box((0.255, 0.38, 0.04), (0.10, 0.14, 0.16), BR, bevel=0.015)  # first-aid satchel, left hip
    m.box((0.311, 0.38, 0.04), (0.012, 0.07, 0.02), WHITE)
    m.box((0.311, 0.38, 0.04), (0.012, 0.02, 0.07), WHITE)
    head(m, grin=True)
    m.box((0, 1.17, 0), (0.52, 0.12, 0.48), "#F2F2F2", bevel=0.03)  # soft square cap, no helmet
    m.box((0, 1.17, 0.245), (0.10, 0.03, 0.02), GR)
    m.box((0, 1.17, 0.245), (0.03, 0.10, 0.02), GR)
    a1, b1 = (-0.22, 0.70, 0.0), (-0.2, 0.57, 0.2)
    a2, b2 = (0.22, 0.70, 0.0), (0.285, 0.46, 0.06)
    arm(m, -1, a1, b1, "#F2F2F2", w=0.09)
    arm(m, 1, a2, b2, "#F2F2F2", w=0.09)
    m.limb(along(a2, b2, 0.15), along(a2, b2, 0.5), 0.105, GR)  # green armband, left arm
    m.box((-0.2, 0.6, 0.3), (0.06, 0.1, 0.2), "#2F3138")  # small black pistol
    m.box((-0.2, 0.66, 0.31), (0.05, 0.03, 0.18), "#2F3138")
    m.set_muzzle((-0.2, 0.66, 0.42))
    m.fit(height=1.3)
    return m


def medic_legend():
    m = Model("medic_legend")
    W = "#F4F4F4"
    legs(m, "#E6E6E6", GOLD2)
    torso(m, W, w=1.1, belt=GOLD)
    m.box((0, 0.23, 0), (0.44, 0.28, 0.3), W)  # long coat with wide gold trim
    m.box((0, 0.10, 0), (0.45, 0.045, 0.31), GOLD)
    m.box((0, 0.785, 0), (0.46, 0.07, 0.33), GOLD)
    m.box((0, 0.23, 0.155), (0.05, 0.28, 0.012), GOLD)
    m.box((0, 0.55, 0.15), (0.26, 0.08, 0.025), GWARM)  # big glowing cross
    m.box((0, 0.55, 0.15), (0.08, 0.26, 0.025), GWARM)
    m.box((0, 0.55, 0.138), (0.30, 0.12, 0.012), GOLD)
    m.box((0, 0.55, 0.138), (0.12, 0.30, 0.012), GOLD)
    # angular wings: 3 stacked rounded blocks per side, white with gold edges, <= 0.9 m total
    for sx in (-1, 1):
        for cx, cy, w in ((0.19, 0.85, 0.15), (0.265, 0.7, 0.2), (0.305, 0.55, 0.22)):
            m.box((sx * cx, cy, -0.17), (w, 0.17, 0.07), W, bevel=0.02, rot=(0, 0, -sx * 12))
            m.box((sx * (cx + w / 2 - 0.005), cy - 0.012, -0.17), (0.03, 0.175, 0.08), GOLD)
    head(m, grin=True)
    m.box((0, 1.16, -0.01), (0.54, 0.10, 0.5), GOLD2, bevel=0.03)  # short golden hair
    for k in range(8):  # chunky gold halo ring, floating above the head
        a = k * 45
        m.box((0.2 * math.cos(math.radians(a)), 1.285, -0.03 + 0.2 * math.sin(math.radians(a))), (0.17, 0.05, 0.055), GOLD2,
              rot=(0, -(a + 90), 0))
    m.box((0, 1.205, -0.225), (0.065, 0.16, 0.065), GOLD2)  # post to the back of the head
    arms(m, W, GOLD)
    x, y = -0.2, 0.6  # healing-syringe pistol
    m.box((x, y, 0.34), (0.065, 0.065, 0.32), W)
    m.box((x, y + 0.045, 0.34), (0.04, 0.02, 0.2), GOLD)
    m.box((x, y, 0.1), (0.05, 0.05, 0.12), GOLD)
    m.box((x, y, 0.03), (0.11, 0.04, 0.04), GOLD)
    m.box((x, y - 0.075, 0.2), (0.05, 0.1, 0.06), "#9A9AA2")
    m.cyl((x, y, 0.52), 0.05, 0.05, GOLD, sides=6, rot=(90, 0, 0))
    m.pyramid((x, y, 0.545), (0.07, 0.07), 0.12, GWARM, rot=(90, 0, 0), sides=6)
    m.set_muzzle((x, y, 0.67))
    m.fit(height=1.3)
    return m


# ========================================================================================= MORTAR
def _mortar2(name, legend):
    m = Model(name)
    if legend:
        UNI, PLATE, TR, GLOW = "#4A5160", IVORY, GOLD, GWARM
    else:
        UNI, PLATE, TR, GLOW = "#4A5160", "#2A2F3A", BLU, GBLU
    SH = "#2A2D36"
    legs(m, "#3A4150", GOLD2 if legend else "#262A33", w=1.1)
    torso(m, UNI, w=1.2, belt=TR if legend else "#2A2F3A")
    m.box((0, 0.52, 0.155), (0.42, 0.40, 0.04), PLATE, bevel=0.01)
    m.box((0, 0.725, 0.16), (0.42, 0.03, 0.05), TR)
    m.box((0, 0.325, 0.16), (0.42, 0.03, 0.05), TR)
    for sx in (-1, 1):
        m.box((sx * 0.3, 0.75, 0), (0.16, 0.10, 0.27), PLATE, bevel=0.02)
        m.box((sx * 0.3, 0.805, 0), (0.16, 0.03, 0.27), TR)
    head(m)
    if legend:
        m.box((0, 1.17, 0), (0.6, 0.28, 0.55), "#4A5160", bevel=0.04)  # war helmet
        m.box((0, 1.1, 0.28), (0.24, 0.16, 0.03), GOLD)  # gold front plate
        m.box((0, 1.0, 0.255), (0.05, 0.2, 0.03), GOLD)
        m.frustum((0, 1.26, -0.12), (0.18, 0.12), (0.10, 0.34), 0.2, GOLD, rot=(0, 0, 0))  # chunky cloth plume
        m.box((0, 1.31, -0.28), (0.16, 0.14, 0.18), GOLD)
        for sx in (-1, 1):
            m.box((sx * 0.32, 0.97, 0), (0.10, 0.18, 0.2), "#1E2128", bevel=0.015)
        lenses(m, GLOW, y=0.985, z=0.262, frame="#1E2128", fw=0.52)
    else:
        m.box((0, 1.17, 0), (0.6, 0.28, 0.55), "#2A2F3A", bevel=0.04)
        m.box((0, 1.05, -0.26), (0.58, 0.1, 0.04), "#2A2F3A")
        for sx in (-1, 1):  # big ear protectors
            m.box((sx * 0.33, 0.97, 0), (0.13, 0.22, 0.24), "#1E2128", bevel=0.02)
            m.box((sx * 0.33, 1.1, 0), (0.07, 0.06, 0.12), BLU)
        lenses(m, GBLU, y=0.985, z=0.262, frame="#1E2128", fw=0.54)
    # shell rack on the back
    m.box((0, 0.52, -0.2), (0.36, 0.30, 0.12), PLATE if not legend else "#2A2F3A")
    if not legend:
        for x in (-0.11, 0.0, 0.11):
            m.cyl((x, 0.80, -0.25), 0.055, 0.32, SH, sides=6)
            m.pyramid((x, 0.96, -0.25), (0.11, 0.11), 0.09, GBLU, sides=6)
    else:
        m.box((-0.3, 0.77, 0.0), (0.12, 0.05, 0.16), "#2A2F3A")  # cannon emblem plate on the shoulder
        m.limb((-0.34, 0.80, -0.04), (-0.27, 0.80, 0.04), 0.04, GOLD, d=0.02)
    # mortar
    if legend:
        base1, base2 = (-0.155, 0.06, 0.36), (-0.005, 0.06, 0.36)
        m.box((-0.08, 0.03, 0.36), (0.5, 0.06, 0.46), GOLD, bevel=0.012)  # broad gold base plate
        tops = []
        for b in (base1, base2):
            c, top, d = tube(m, b, 0.55, 0.085, 20, GOLD, r_top=0.095)
            m.cyl(tuple(np.array(b) + d * 0.22), 0.1, 0.04, IVORY, sides=8, rot=(20, 0, 0))
            m.cyl(top, 0.105, 0.04, GWARM, sides=8, rot=(20, 0, 0))
            tops.append(np.array(top))
        top = tuple((tops[0] + tops[1]) / 2)
        for sx in (-1, 1):
            m.limb(tuple(np.array(base1) + d * 0.3 + np.array([0.07, 0, 0]) * (1 if sx > 0 else 0)),
                   (-0.08 + sx * 0.25, 0.04, 0.56), 0.04, GOLD)
        # chest bandolier of four big shells
        m.limb((-0.19, 0.73, 0.2), (0.19, 0.38, 0.2), 0.045, "#3A2E20", d=0.03)
        for t in (0.1, 0.35, 0.6, 0.85):
            p = along((-0.19, 0.73, 0.23), (0.19, 0.38, 0.23), t)
            m.cyl((p[0], p[1] - 0.01, p[2]), 0.045, 0.13, GOLD, sides=6)
            m.pyramid((p[0], p[1] + 0.055, p[2]), (0.09, 0.09), 0.06, GWARM, sides=6)
    else:
        base = (-0.08, 0.06, 0.36)
        m.box((base[0], 0.03, base[2]), (0.42, 0.06, 0.42), "#4A5263", bevel=0.01)
        c, top, d = tube(m, base, 0.55, 0.11, 20, "#5A6377")
        m.cyl(top, 0.13, 0.04, GBLU, sides=8, rot=(20, 0, 0))  # glowing mouth ring
        for t in (0.25, 0.45):
            m.cyl(tuple(np.array(base) + d * 0.55 * t), 0.122, 0.035, BLU, sides=8, rot=(20, 0, 0))
        for sx in (-1, 1):
            m.limb(tuple(np.array(base) + d * 0.3), (base[0] + sx * 0.2, 0.04, 0.56), 0.04, "#4A5263")
    hand = (top[0], top[1] + 0.05, top[2])
    sh = (-0.24, 0.70, 0.0)
    m.limb(sh, (-0.22, 0.57, 0.16), 0.10, UNI)
    m.limb((-0.22, 0.57, 0.16), hand, 0.10, UNI)
    m.box(hand, (0.11, 0.11, 0.11), SKIN)
    if legend:
        arm(m, 1, (0.24, 0.70, 0.0), (0.285, 0.46, 0.06), UNI)
    else:
        arm(m, 1, (0.24, 0.70, 0.0), (0.2, 0.50, 0.2), UNI)  # holds a glowing blue-tipped shell
        m.cyl((0.2, 0.57, 0.23), 0.055, 0.2, SH, sides=6)
        m.pyramid((0.2, 0.67, 0.23), (0.11, 0.11), 0.07, GBLU, sides=6)
    m.set_muzzle(top)
    m.fit(height=1.3)
    return m


def mortar_super_rare():
    return _mortar2("mortar_super_rare", False)


def mortar_legend():
    return _mortar2("mortar_legend", True)


# ======================================================================================= WEAKENER
def weakener_super_rare():
    m = Model("weakener_super_rare")
    CT, LEA, HAT = "#12363F", "#3A2E2A", "#1B1F2A"
    legs(m, "#0C2830", "#2A2D36")
    torso(m, CT, w=1.05, belt="#0B2028")
    m.box((0, 0.20, 0), (0.42, 0.34, 0.30), CT)  # long coat
    for i, x in enumerate((-0.15, -0.05, 0.05, 0.15)):
        m.box((x, 0.03 + (0.03 if i % 2 else 0.0), 0), (0.10, 0.06, 0.30), CT)
    m.box((0, 0.20, 0.155), (0.06, 0.30, 0.015), BLU)
    m.box((0, 0.775, 0), (0.44, 0.07, 0.32), BLU)
    for sx in (-1, 1):  # vial belt
        pass
    for k, x in enumerate((-0.15, -0.075, 0.0, 0.075, 0.15)):
        m.cyl((x, 0.36, 0.165), 0.028, 0.07, GBLU, sides=6)
    # backpack with two glowing flasks
    m.box((0, 0.56, -0.2), (0.36, 0.34, 0.1), "#2A3A40")
    for sx in (-1, 1):
        m.cyl((sx * 0.1, 0.56, -0.3), 0.095, 0.26, GBLU, sides=8)
        m.cyl((sx * 0.1, 0.71, -0.3), 0.1, 0.04, LEA, sides=8)
        m.cyl((sx * 0.1, 0.41, -0.3), 0.1, 0.04, LEA, sides=8)
    m.limb((0.0, 0.7, -0.3), (-0.22, 0.74, -0.04), 0.04, "#0B2028")  # pipe to the wand
    m.limb((-0.22, 0.74, -0.04), (-0.24, 0.62, 0.2), 0.04, "#0B2028")
    head(m)
    m.box((0, 1.14, 0), (0.8, 0.04, 0.74), HAT)  # wide brim
    m.box((0, 1.25, 0), (0.5, 0.2, 0.46), HAT, bevel=0.03)
    m.box((0, 1.17, 0), (0.52, 0.06, 0.48), BLU)
    m.box((0, 0.885, 0.255), (0.36, 0.19, 0.06), LEA)  # beak mask
    m.frustum((0, 0.90, 0.28), (0.17, 0.15), (0.06, 0.05), 0.24, LEA, rot=(90, 0, 0))
    for sx in (-1, 1):
        m.box((sx * 0.12, 0.985, 0.262), (0.12, 0.11, 0.02), GBLU)
    eyes_on(m, 0.985, 0.282)
    arms(m, CT, BLU, right=(-0.22, 0.58, 0.28), left=(0.285, 0.46, 0.06), sh=0.24)
    x = -0.22  # spray wand
    m.box((x, 0.6, 0.4), (0.06, 0.06, 0.34), "#3A3F4A")
    m.box((x, 0.6, 0.28), (0.09, 0.09, 0.08), LEA)
    m.box((x, 0.6, 0.6), (0.08, 0.08, 0.06), GBLU)  # glowing nozzle
    m.set_muzzle((x, 0.6, 0.64))
    m.fit(height=1.3)
    return m


def weakener_legend():
    m = Model("weakener_legend")
    RB, BONE = "#241631", "#EFE9D8"
    legs(m, "#180E22", "#2A2D36")
    torso(m, RB, w=1.1, belt=GOLD)
    m.box((0, 0.20, 0), (0.46, 0.36, 0.32), RB)  # long robe
    for i, x in enumerate((-0.16, -0.05, 0.05, 0.16)):
        m.box((x, 0.03 + (0.03 if i % 2 else 0.0), 0), (0.10, 0.06, 0.32), RB)
    m.box((0, 0.045, 0.0), (0.47, 0.025, 0.33), GOLD)
    m.box((0, 0.20, 0.165), (0.06, 0.32, 0.015), GOLD)
    m.box((0, 0.785, 0), (0.46, 0.07, 0.33), GOLD)
    m.box((0, 0.5, -0.19), (0.40, 0.30, 0.04), RB)  # short cape, gold border
    m.box((0, 0.345, -0.19), (0.42, 0.03, 0.05), GOLD)
    for sx in (-1, 1):
        m.box((sx * 0.205, 0.5, -0.19), (0.03, 0.3, 0.05), GOLD)
    # three big flasks on the back
    for x, y, glow in ((-0.17, 0.6, False), (0.0, 0.5, True), (0.17, 0.6, False)):
        m.cyl((x, y, -0.3), 0.1, 0.26, "#8FD14F", sides=8)
        m.cyl((x, y + 0.15, -0.3), 0.105, 0.04, GOLD, sides=8)
        m.cyl((x, y - 0.15, -0.3), 0.105, 0.04, GOLD, sides=8)
        if glow:
            m.cyl((x, y, -0.3), 0.055, 0.3, GWARM, sides=6)
    m.limb((0.1, 0.76, -0.3), (-0.22, 0.76, -0.04), 0.04, "#3A2E4A")
    m.limb((-0.22, 0.76, -0.04), (-0.24, 0.62, 0.2), 0.04, "#3A2E4A")
    head(m)
    m.box((0, 1.14, 0), (0.7, 0.04, 0.64), RB)  # hat brim
    m.frustum((0, 1.16, 0), (0.46, 0.44), (0.14, 0.14), 0.26, RB)  # tall pointed top hat
    m.box((0, 1.2, 0), (0.48, 0.06, 0.46), GOLD)
    m.box((0, 1.27, 0.222), (0.11, 0.11, 0.03), GOLD)  # little gold skull block
    for sx in (-1, 1):
        m.box((sx * 0.025, 1.285, 0.24), (0.025, 0.025, 0.012), RB)
    m.box((0, 0.885, 0.255), (0.36, 0.19, 0.06), BONE)  # bone-white beak mask with gold edges
    m.frustum((0, 0.90, 0.28), (0.17, 0.15), (0.06, 0.05), 0.24, BONE, rot=(90, 0, 0))
    m.box((0, 0.785, 0.255), (0.38, 0.025, 0.065), GOLD)
    for sx in (-1, 1):
        m.box((sx * 0.12, 0.985, 0.262), (0.12, 0.11, 0.02), GWARM)
    eyes_on(m, 0.985, 0.282)
    arms(m, RB, GOLD, right=(-0.22, 0.58, 0.28), left=(0.285, 0.46, 0.06), sh=0.25)
    sx_, sz = -0.22, 0.28  # hex-staff / wand
    m.limb((sx_, 0.0, sz), (sx_, 1.05, sz), 0.045, GOLD)
    for cx in (-1, 1):
        for cz in (-1, 1):
            m.box((sx_ + cx * 0.065, 1.14, sz + cz * 0.065), (0.03, 0.15, 0.03), GOLD)
    m.box((sx_, 1.14, sz), (0.11, 0.11, 0.11), GWARM)
    m.set_muzzle((sx_, 1.14, sz))
    m.fit(height=1.3)
    return m


# ======================================================================================== DRUMMER
def drummer_super_rare():
    m = Model("drummer_super_rare")
    RB = "#2A4FA8"
    legs(m, "#1B2A5E", "#14151C")
    torso(m, RB, w=1.05, belt=WHITE)
    for s in (-1, 1):  # white crossed straps
        m.limb((s * 0.16, 0.74, 0.145), (-s * 0.16, 0.36, 0.145), 0.05, WHITE, d=0.03)
    for yy in (0.46, 0.62, 0.72):
        m.box((0.0, yy, 0.14), (0.04, 0.04, 0.02), GOLD)
    m.box((0, 0.775, 0), (0.42, 0.06, 0.3), BLU)  # collar
    for sx in (-1, 1):
        m.box((sx * 0.27, 0.745, 0), (0.12, 0.07, 0.22), BLU, bevel=0.015)
    # big bass drum on the chest, glowing rim + star
    m.cyl((0, 0.48, 0.29), 0.22, 0.16, WHITE, sides=8)
    m.cyl((0, 0.575, 0.29), 0.232, 0.03, GBLU, sides=8)
    m.cyl((0, 0.39, 0.29), 0.232, 0.03, BLU, sides=8)
    m.cyl((0, 0.59, 0.29), 0.2, 0.02, "#DCE6F8", sides=8)
    for a in (0, 60, 120):
        m.box((0, 0.61, 0.29), (0.15, 0.012, 0.035), GOLD, rot=(0, a, 0))
    # banner pole on the back
    m.limb((0.12, 0.45, -0.18), (0.12, 1.3, -0.18), 0.035, "#6E7787")
    m.box((0.23, 1.2, -0.18), (0.2, 0.2, 0.04), BLU)
    m.box((0.23, 1.2, -0.17), (0.08, 0.08, 0.03), WHITE)
    head(m)
    m.frustum((0, 1.14, 0), (0.52, 0.48), (0.46, 0.42), 0.2, NAVY)  # shako
    m.box((0, 1.15, 0), (0.54, 0.04, 0.5), BLU)
    m.box((0, 1.14, 0.255), (0.4, 0.03, 0.08), "#14151C")
    m.box((0, 1.3, 0.0), (0.12, 0.05, 0.12), GOLD)
    for i in range(3):  # 3-block plume
        m.box((0, 1.35 + i * 0.045, -0.02 - i * 0.02), (0.1 - i * 0.015, 0.05, 0.12 - i * 0.02), BLU)
    arms(m, RB, BLU, right=(-0.2, 0.57, 0.2))
    m.limb((-0.2, 0.57, 0.2), (-0.2, 0.66, 0.5), 0.035, WHITE)  # drum stick
    m.box((-0.2, 0.665, 0.52), (0.07, 0.07, 0.07), GBLU)
    m.set_muzzle((-0.2, 0.665, 0.56))
    m.fit(height=1.3)
    return m


def drummer_legend():
    m = Model("drummer_legend")
    RD = "#8E1B24"
    legs(m, RD, "#3A2020")
    torso(m, RD, w=1.15, belt=GOLD2)
    for s in (-1, 1):
        m.limb((s * 0.17, 0.74, 0.15), (-s * 0.17, 0.36, 0.15), 0.055, IVORY, d=0.03)
    m.box((0, 0.785, 0), (0.46, 0.07, 0.33), GOLD2)
    for sx in (-1, 1):  # spiked gold epaulettes
        m.box((sx * 0.29, 0.76, 0), (0.17, 0.08, 0.25), GOLD2, bevel=0.015)
        for dz in (-0.07, 0.07):
            m.pyramid((sx * 0.29, 0.8, dz), (0.1, 0.1), 0.14, GOLD2)
    m.box((0, 0.48, -0.2), (0.42, 0.62, 0.04), RD)  # long cape, gold border
    m.box((0, 0.17, -0.2), (0.44, 0.04, 0.05), GOLD2)
    for sx in (-1, 1):
        m.box((sx * 0.215, 0.48, -0.2), (0.03, 0.62, 0.05), GOLD2)
    # huge taiko war drum on the chest
    m.cyl((0, 0.47, 0.31), 0.27, 0.2, RD, sides=8)
    m.cyl((0, 0.585, 0.31), 0.285, 0.03, GOLD2, sides=8)
    m.cyl((0, 0.355, 0.31), 0.285, 0.03, GOLD2, sides=8)
    m.cyl((0, 0.605, 0.31), 0.25, 0.02, GWARM, sides=8)  # glowing warm rim
    m.cyl((0, 0.612, 0.31), 0.19, 0.02, IVORY, sides=8)
    for a in range(0, 360, 60):
        m.box((0.24 * math.cos(math.radians(a)), 0.62, 0.31 + 0.24 * math.sin(math.radians(a))), (0.045, 0.04, 0.045), GOLD2)
    # second war drum on the back
    m.cyl((0, 0.56, -0.34), 0.22, 0.2, GOLD2, sides=8, rot=(90, 0, 0))
    m.cyl((0, 0.56, -0.34), 0.19, 0.24, RD, sides=8, rot=(90, 0, 0))
    for a in range(0, 360, 90):
        m.box((0.2 * math.cos(math.radians(a)), 0.56 + 0.2 * math.sin(math.radians(a)), -0.46), (0.05, 0.05, 0.03), GOLD2)
    head(m, grin=True)
    m.box((0, 0.86, 0.236), (0.14, 0.07, 0.02), "#4A1F1F")  # shouting mouth
    m.frustum((0, 1.14, 0), (0.54, 0.5), (0.5, 0.46), 0.14, GOLD2)  # crown helmet
    for dx, dz, h in ((-0.2, 0.17, 0.12), (0.2, 0.17, 0.12), (-0.2, -0.17, 0.12), (0.2, -0.17, 0.12), (0.0, 0.0, 0.18)):
        m.pyramid((dx, 1.28, dz), (0.11, 0.11), h, GOLD2)
    m.box((0, 1.34, -0.1), (0.12, 0.12, 0.26), RD)  # chunky red plume
    arms(m, RD, GOLD2, right=(-0.2, 0.57, 0.2), left=(0.3, 0.58, 0.18), sh=0.26)
    m.limb((-0.2, 0.57, 0.2), (-0.2, 0.7, 0.5), 0.04, IVORY)  # right stick raised forward
    m.box((-0.2, 0.705, 0.53), (0.08, 0.08, 0.08), GWARM)
    m.limb((0.3, 0.58, 0.18), (0.3, 0.52, 0.45), 0.04, IVORY)
    m.box((0.3, 0.515, 0.48), (0.07, 0.07, 0.07), GOLD2)
    m.set_muzzle((-0.2, 0.705, 0.58))
    m.fit(height=1.3)
    return m


# ======================================================================================== BLINDER
def blinder_super_rare():
    m = Model("blinder_super_rare")
    UN, TAN = "#3A3F4A", "#A68A5B"
    legs(m, "#2E323C", "#1E2128")
    torso(m, UN, w=1.1, belt=TAN)
    m.box((0, 0.55, 0.15), (0.40, 0.30, 0.04), TAN, bevel=0.012)  # tan webbing vest
    m.box((0, 0.705, 0.155), (0.40, 0.03, 0.05), BLU)
    m.box((0, 0.395, 0.155), (0.40, 0.03, 0.05), BLU)
    m.cyl((0, 0.57, 0.19), 0.115, 0.06, "#C9CDD6", sides=8, rot=(90, 0, 0))  # chest spotlight
    m.cyl((0, 0.57, 0.225), 0.085, 0.02, GBLU, sides=8, rot=(90, 0, 0))
    for x in (-0.15, -0.075, 0.075, 0.15):  # belt of flashbangs
        m.cyl((x, 0.335, 0.17), 0.035, 0.07, "#5A606E", sides=6)
        m.box((x, 0.375, 0.17), (0.03, 0.015, 0.03), BLU)
    m.box((0.29, 0.8, -0.02), (0.12, 0.09, 0.28), "#2E323C", bevel=0.015)  # shoulder flare rack
    for dz in (-0.09, 0.0, 0.09):
        m.cyl((0.29, 0.92, dz - 0.02), 0.033, 0.16, "#C8402F", sides=6)
        m.pyramid((0.29, 1.0, dz - 0.02), (0.066, 0.066), 0.06, GBLU, sides=6)
    m.box((0, 0.55, -0.18), (0.30, 0.28, 0.1), "#2E323C")
    head(m)
    helmet(m, "#2F333D", w=0.6, h=0.22)
    m.box((0, 1.325, 0), (0.07, 0.03, 0.4), BLU)
    m.box((0, 0.995, 0.25), (0.54, 0.2, 0.04), "#1E2128")  # visor frame
    m.box((0, 0.995, 0.275), (0.46, 0.13, 0.02), GBLU)  # big glowing visor
    eyes_on(m, 0.995, 0.292)
    arms(m, UN, BLU, right=(-0.2, 0.57, 0.2), left=(0.285, 0.46, 0.06), sh=0.26)
    x, y = -0.2, 0.6  # flare gun
    m.box((x, y, 0.3), (0.08, 0.12, 0.2), "#3A3D45")
    m.cyl((x, y + 0.03, 0.46), 0.055, 0.16, "#2A2D36", sides=8, rot=(90, 0, 0))
    m.cyl((x, y + 0.03, 0.55), 0.06, 0.04, GBLU, sides=8, rot=(90, 0, 0))
    m.box((x, y - 0.08, 0.26), (0.05, 0.1, 0.06), "#2A2D36")
    m.set_muzzle((x, y + 0.03, 0.58))
    m.fit(height=1.3)
    return m


def blinder_legend():
    m = Model("blinder_legend")
    legs(m, IVORY, GOLD2)
    torso(m, IVORY, w=1.15, belt=GOLD2)
    m.box((0, 0.55, 0.155), (0.42, 0.32, 0.045), GOLD2, bevel=0.015)
    m.box((0, 0.725, 0.16), (0.42, 0.03, 0.05), IVORY)
    m.cyl((0, 0.57, 0.2), 0.14, 0.06, GOLD2, sides=8, rot=(90, 0, 0))  # gold-ringed mirror lens
    m.cyl((0, 0.57, 0.232), 0.105, 0.02, GWARM, sides=8, rot=(90, 0, 0))
    for sx in (-1, 1):
        m.cyl((sx * 0.3, 0.76, 0), 0.13, 0.09, GOLD2, sides=8)
        m.box((sx * 0.3, 0.74, 0.0), (0.16, 0.05, 0.22), IVORY)
    # sun-disc plate with 8 chunky ray blocks, <= 0.9 m wide
    m.cyl((0, 0.64, -0.2), 0.2, 0.06, GOLD2, sides=8, rot=(90, 0, 0))
    m.box((0, 0.64, -0.15), (0.2, 0.2, 0.04), IVORY)
    m.cyl((0, 0.64, -0.24), 0.12, 0.03, IVORY, sides=8, rot=(90, 0, 0))
    for k in range(8):
        a = math.radians(k * 45)
        m.pyramid((0.17 * math.cos(a), 0.64 + 0.17 * math.sin(a), -0.2), (0.1, 0.06), 0.19, GOLD2, rot=(0, 0, k * 45 - 90))
    m.box((0, 0.3, -0.15), (0.38, 0.3, 0.04), IVORY)  # short cape, gold border
    m.box((0, 0.145, -0.15), (0.4, 0.03, 0.05), GOLD2)
    for sx in (-1, 1):
        m.box((sx * 0.195, 0.3, -0.15), (0.03, 0.3, 0.05), GOLD2)
    head(m)
    m.box((0, 1.03, 0), (0.6, 0.42, 0.54), IVORY, bevel=0.05)  # full-face white helmet
    m.box((0, 1.02, 0.262), (0.5, 0.2, 0.012), GOLD2)
    m.box((0, 1.0, 0.272), (0.42, 0.075, 0.02), GWARM)  # glowing warm visor slit
    m.box((0, 1.24, 0), (0.62, 0.04, 0.56), GOLD2)
    for k in range(7):  # sun-crown of 7 chunky wedge rays
        a = math.radians(-60 + k * 20)
        m.pyramid((0.14 * math.sin(a), 1.225 + 0.14 * math.cos(a) - 0.02, 0.0), (0.09, 0.09), 0.1, GOLD2, rot=(0, 0, -(-60 + k * 20)))
    arms(m, IVORY, GOLD2, sh=0.26)
    x, y = -0.2, 0.6  # gold flare cannon
    m.box((x, y, 0.28), (0.09, 0.13, 0.22), IVORY)
    m.cyl((x, y + 0.02, 0.5), 0.065, 0.3, GOLD2, sides=8, rot=(90, 0, 0))
    m.cyl((x, y + 0.02, 0.38), 0.075, 0.04, IVORY, sides=8, rot=(90, 0, 0))
    m.cyl((x, y + 0.02, 0.66), 0.08, 0.05, GWARM, sides=8, rot=(90, 0, 0))
    m.box((x, y - 0.08, 0.26), (0.05, 0.1, 0.06), "#2A2D36")
    m.set_muzzle((x, y + 0.02, 0.7))
    m.fit(height=1.3)
    return m


# ===================================================================================== SHIELD KNIGHT
def _knight2(name, legend):
    m = Model(name)
    SIL, DK = "#A9B1BD", "#6E7787"
    BL = "#2F5FB8"
    if legend:
        MAIN, SEC, TR, GL, CAPE = GOLD2, IVORY, GOLD, GWARM, IVORY
    else:
        MAIN, SEC, TR, GL, CAPE = SIL, "#8F97A5", BLU, GBLU, BL
    legs(m, "#4A5060" if not legend else "#C9A94A", "#4A5060" if not legend else IVORY, w=1.25)
    torso(m, "#4A5060" if not legend else IVORY, w=1.4, belt=DK if not legend else GOLD)
    m.box((0, 0.55, 0.15), (0.38 * 1.4 - 0.02, 0.30, 0.045), MAIN if not legend else IVORY, bevel=0.02)
    m.box((0, 0.55, -0.15), (0.38 * 1.4 - 0.04, 0.28, 0.04), MAIN, bevel=0.02)
    m.box((0, 0.715, 0.155), (0.38 * 1.4 - 0.02, 0.03, 0.05), TR)
    m.box((0, 0.395, 0.155), (0.38 * 1.4 - 0.02, 0.03, 0.05), TR)
    if legend:
        m.box((0, 0.55, 0.18), (0.08, 0.26, 0.012), GOLD)
        m.box((0, 0.58, 0.18), (0.22, 0.07, 0.012), GOLD)
    else:
        m.box((0, 0.2, 0.14), (0.28, 0.26, 0.03), BL)  # short blue tabard
        m.box((0, 0.065, 0.14), (0.3, 0.03, 0.035), BLU)
    # cape
    if legend:
        m.box((0, 0.46, -0.2), (0.52, 0.64, 0.04), IVORY)
        m.box((0, 0.14, -0.2), (0.54, 0.04, 0.05), GOLD)
        for sx in (-1, 1):
            m.box((sx * 0.265, 0.46, -0.2), (0.035, 0.64, 0.05), GOLD)
    # pauldrons
    for sx in (-1, 1):
        px = sx * (0.3 if legend else 0.33)
        if legend:
            m.cyl((px, 0.76, 0), 0.15, 0.11, GOLD2, sides=8)
            m.cyl((px, 0.82, 0), 0.1, 0.04, IVORY, sides=8)
        else:
            m.box((px, 0.75, 0), (0.2, 0.10, 0.28), SIL, bevel=0.02)
            m.box((px, 0.8, 0.12), (0.2, 0.03, 0.03), BLU)
            for dz in (-0.06, 0.06):
                m.pyramid((px, 0.8, dz), (0.1, 0.1), 0.13, DK)
    head(m)
    if legend:  # winged great helm
        m.box((0, 1.03, 0), (0.6, 0.42, 0.54), IVORY, bevel=0.04)
        m.box((0, 1.0, 0.272), (0.42, 0.07, 0.02), GWARM)
        m.box((0, 0.99, 0.262), (0.5, 0.13, 0.012), GOLD)
        m.box((0, 1.26, 0), (0.62, 0.05, 0.56), GOLD2)
        for sx in (-1, 1):
            m.box((sx * 0.35, 1.18, -0.02), (0.1, 0.16, 0.3), IVORY, rot=(0, 0, -sx * 25))
            m.box((sx * 0.4, 1.27, -0.04), (0.08, 0.12, 0.22), IVORY, rot=(0, 0, -sx * 40))
        for k in range(8):  # gold halo ring behind the head (vertical)
            a = k * 45
            m.box((0.19 * math.cos(math.radians(a)), 1.1 + 0.19 * math.sin(math.radians(a)), -0.34), (0.16, 0.05, 0.06), GOLD2,
                  rot=(0, 0, a + 90))
        m.limb((0, 0.78, -0.17), (0, 0.94, -0.33), 0.06, GOLD2)  # post to the back plate
    else:
        m.box((0, 1.22, 0), (0.58, 0.12, 0.54), DK, bevel=0.03)
        m.box((0, 0.95, 0.262), (0.54, 0.38, 0.04), SIL, bevel=0.01)
        m.box((0, 0.995, 0.285), (0.42, 0.055, 0.02), GBLU)  # glowing visor slit
        for sx in (-1, 1):
            m.box((sx * 0.29, 0.95, 0), (0.06, 0.42, 0.5), DK)
            m.box((sx * 0.33, 1.25, 0), (0.10, 0.12, 0.12), SIL)
        m.box((0, 0.95, -0.26), (0.58, 0.42, 0.06), DK)
        for sx in (-1, 1):  # blue crest fins, widen the top silhouette
            m.box((sx * 0.315, 1.3, -0.02), (0.07, 0.24, 0.22), BL, rot=(0, 0, -sx * 22))
        m.box((0, 1.345, -0.02), (0.12, 0.14, 0.28), BL)  # chunky plume
        m.box((0, 1.42, -0.06), (0.1, 0.07, 0.2), BLU)
    # tower shield on the left arm
    sc, sy = ((0.2, 0.3) if legend else (0.22, 0.3)), 0.52
    sh_h, sw = (0.95, 0.5) if legend else (0.85, 0.46)
    m.box((sc[0], sy, sc[1]), (sw, sh_h, 0.06), IVORY if legend else "#8F97A5")
    rim = GOLD2 if legend else BLU
    m.box((sc[0], sy + sh_h / 2, sc[1]), (sw + 0.04, 0.05, 0.08), rim)
    m.box((sc[0], sy - sh_h / 2, sc[1]), (sw + 0.04, 0.05, 0.08), rim)
    for sx in (-1, 1):
        m.box((sc[0] + sx * sw / 2, sy, sc[1]), (0.05, sh_h, 0.08), rim)
    if legend:  # glowing sun-cross emblem
        m.box((sc[0], 0.58, sc[1] + 0.035), (0.34, 0.08, 0.02), GWARM)
        m.box((sc[0], 0.58, sc[1] + 0.035), (0.08, 0.34, 0.02), GWARM)
        m.box((sc[0], 0.58, sc[1] + 0.03), (0.2, 0.2, 0.012), GOLD2, rot=(0, 0, 45))
    else:
        m.box((sc[0], 0.58, sc[1] + 0.035), (0.22, 0.06, 0.02), BLU)
        m.box((sc[0], 0.58, sc[1] + 0.035), (0.06, 0.26, 0.02), BLU)
        for sx in (-1, 1):  # glowing rim lines
            m.box((sc[0] + sx * (sw / 2 - 0.03), sy, sc[1] + 0.035), (0.02, sh_h - 0.1, 0.014), GBLU)
        m.box((sc[0], sy + sh_h / 2 - 0.03, sc[1] + 0.035), (sw - 0.1, 0.02, 0.014), GBLU)
    arm(m, 1, (0.24, 0.70, 0.0), (0.22, 0.5, 0.2), DK)
    arm(m, -1, (-0.28, 0.70, 0.0), (-0.24, 0.58, 0.22), DK, w=0.12)
    mx, my = -0.24, 0.60
    if legend:  # golden warhammer
        m.box((mx, my, 0.36), (0.05, 0.05, 0.36), GOLD)
        m.box((mx, my, 0.58), (0.30, 0.2, 0.2), GOLD2, bevel=0.015)
        for sx in (-1, 1):
            m.box((mx + sx * 0.16, my, 0.58), (0.03, 0.14, 0.14), GWARM)
        m.box((mx, my + 0.11, 0.58), (0.2, 0.03, 0.12), IVORY)
        m.set_muzzle((mx, my, 0.7))
    else:  # flanged mace
        m.box((mx, my, 0.34), (0.05, 0.05, 0.30), "#4A5060")
        m.box((mx, my, 0.54), (0.13, 0.13, 0.13), GBLU)
        for rz in (0, 90):
            m.box((mx, my, 0.54), (0.22, 0.05, 0.05), SIL, rot=(0, 0, rz))
            m.box((mx, my, 0.54), (0.05, 0.05, 0.22), SIL, rot=(0, rz, 0))
        m.set_muzzle((mx, my, 0.62))
    m.fit(height=1.3)
    return m


def shield_knight_super_rare():
    return _knight2("shield_knight_super_rare", False)


def shield_knight_legend():
    return _knight2("shield_knight_legend", True)


RANK2_UNITS = [
    rifleman_super_rare, rifleman_legend,
    machine_gunner_super_rare, machine_gunner_legend,
    sniper_super_rare, sniper_legend,
    rocket_soldier_super_rare, rocket_soldier_legend,
    medic_common, medic_legend,
    mortar_super_rare, mortar_legend,
    weakener_super_rare, weakener_legend,
    drummer_super_rare, drummer_legend,
    blinder_super_rare, blinder_legend,
    shield_knight_super_rare, shield_knight_legend,
]
