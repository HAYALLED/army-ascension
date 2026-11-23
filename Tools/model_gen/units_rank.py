"""Rare / Super Rare variants + new units (Mortar, Weakener, Drummer, Blinder, Shield Knight).
Same soldier space as units.py: 1.3 m tall, front +Z, right hand = -X.
Colors "G:#RRGGBB" = rank glow (emissive primitive); everything else is flat / matte."""
import math
import numpy as np
from glbkit import Model, shade
from units import SKIN, DARK, GUN, WHITE, EYE, legs, torso, head, arm, helmet, rifle

PUR = "#8A3FD1"
GPUR = "G:#B66BFF"
GPUR2 = "G:#D9B8FF"
BLU = "#2F7BFF"
GBLU = "G:#56A0FF"
GOLD = "#D9A62E"
BRASS = "#C99A3A"


def eyes_on(m, y=0.98, z=0.276):
    """Dark eyes drawn on top of a glowing lens so they stay readable."""
    for sx in (-1, 1):
        m.box((sx * 0.12, y, z), (0.06, 0.07, 0.015), EYE)


def lenses(m, glow, y=0.985, z=0.262, size=(0.12, 0.10, 0.02), frame="#1E2128", fw=0.48):
    m.box((0, y, z - 0.015), (fw, size[1] + 0.05, 0.035), frame)
    for sx in (-1, 1):
        m.box((sx * 0.12, y, z + 0.005), size, glow)
    eyes_on(m, y, z + 0.02)


def cuff(m, a, b, col, w=0.115):
    a, b = np.array(a, float), np.array(b, float)
    m.limb(a + (b - a) * 0.80, a + (b - a) * 0.96, w, col)


def along(a, b, t):
    return tuple(np.array(a, float) + (np.array(b, float) - np.array(a, float)) * t)


def tube(m, base, length, r, tilt, col, r_top=None, sides=8):
    """Tube leaning toward +Z by `tilt` degrees from vertical. Returns (center, top)."""
    d = np.array([0.0, math.cos(math.radians(tilt)), math.sin(math.radians(tilt))])
    base = np.array(base, float)
    m.cyl(tuple(base + d * length / 2), r, length, col, sides=sides, rot=(tilt, 0, 0), r_top=r_top)
    return tuple(base + d * length / 2), tuple(base + d * length), d


# ======================================================================== RARE / SUPER RARE
def rifleman_rare():
    m = Model("rifleman_rare")
    NAVY, MID, PLATE = "#24346E", "#1B2A5E", "#2A2F45"
    legs(m, "#1A1C2E", "#14151C")
    for sx in (-1, 1):  # knee pads with purple stripe
        m.box((sx * 0.095, 0.2, 0.088), (0.14, 0.07, 0.03), PLATE)
        m.box((sx * 0.095, 0.2, 0.105), (0.14, 0.03, 0.012), PUR)
    torso(m, NAVY, w=1.05)
    m.box((0, 0.55, 0.15), (0.34, 0.30, 0.04), PLATE, bevel=0.015)  # plate carrier
    m.box((0, 0.55, -0.15), (0.34, 0.30, 0.04), PLATE, bevel=0.015)
    m.box((0, 0.705, 0.155), (0.34, 0.03, 0.05), PUR)
    m.box((0, 0.395, 0.155), (0.34, 0.03, 0.05), PUR)
    for sx in (-1, 1):  # shoulder pads
        m.box((sx * 0.28, 0.74, 0), (0.15, 0.07, 0.22), PLATE, bevel=0.02)
        m.box((sx * 0.28, 0.78, 0), (0.15, 0.03, 0.22), PUR)
    m.box((0, 0.775, 0), (0.44, 0.07, 0.32), MID)  # scarf
    head(m)
    helmet(m, MID, y=1.22, w=0.58, d=0.54, h=0.24, brim=False)
    m.box((0, 1.355, 0), (0.07, 0.03, 0.4), PUR)  # center stripe
    m.box((0, 1.17, 0.275), (0.42, 0.08, 0.05), PLATE)  # goggles pushed up
    for sx in (-1, 1):
        m.box((sx * 0.1, 1.17, 0.305), (0.13, 0.06, 0.02), GPUR)
    m.box((0, 0.55, -0.23), (0.30, 0.30, 0.14), "#3A3F52", bevel=0.02)  # radio
    m.limb((0.1, 0.70, -0.24), (0.1, 1.27, -0.24), 0.035, PLATE)
    m.box((0.1, 1.30, -0.24), (0.07, 0.07, 0.07), GPUR)
    arm(m, -1, (-0.24, 0.70, 0.0), (-0.2, 0.57, 0.2), NAVY)
    arm(m, 1, (0.24, 0.70, 0.0), (0.285, 0.46, 0.06), NAVY)
    x, y = -0.2, 0.6  # bullpup
    m.box((x, y - 0.02, 0.02), (0.08, 0.14, 0.22), "#2E323F")
    m.box((x, y, 0.24), (0.085, 0.12, 0.38), "#2E323F")
    m.box((x, y + 0.005, 0.64), (0.05, 0.05, 0.34), "#1D2028")
    m.box((x, y + 0.095, 0.26), (0.065, 0.065, 0.22), "#14151A")  # scope
    m.box((x, y + 0.095, 0.375), (0.05, 0.05, 0.02), GPUR)
    m.box((x, y - 0.095, 0.32), (0.06, 0.10, 0.09), GPUR)  # glowing mag
    m.set_muzzle((x, y + 0.005, 0.83))
    m.fit(height=1.3)
    return m


def machine_gunner_rare():
    m = Model("machine_gunner_rare")
    BLK, CH = "#1E1F25", "#2B2B33"
    legs(m, CH, "#15161B", w=1.25)
    torso(m, "#F28C1F", w=1.5, d=0.30)
    for sx in (-1, 1):
        m.box((sx * 0.35, 0.73, 0), (0.17, 0.10, 0.27), BLK, bevel=0.02)  # shoulder plates
        m.box((sx * 0.35, 0.785, 0), (0.17, 0.03, 0.27), PUR)
        m.box((sx * 0.265, 0.5, 0.165), (0.11, 0.30, 0.04), BLK)  # chest side plates
        m.box((sx * 0.265, 0.665, 0.17), (0.11, 0.03, 0.05), PUR)
        m.box((sx * 0.12, 0.2, 0.087), (0.17, 0.12, 0.03), BLK)  # thigh plates
    m.limb((0.2, 0.72, 0.19), (-0.2, 0.38, 0.19), 0.06, "#F2C21A", d=0.04)  # bullet belt
    m.box((0, 0.55, -0.26), (0.42, 0.34, 0.20), CH, bevel=0.04)  # drum backpack
    m.cyl((0, 0.55, -0.37), 0.16, 0.08, BLK, sides=8, rot=(90, 0, 0))
    m.box((0, 0.55, -0.32), (0.44, 0.05, 0.1), PUR)
    m.limb((-0.26, 0.45, -0.2), (-0.32, 0.48, 0.2), 0.05, "#F2C21A", d=0.04)  # belt feed
    head(m)
    helmet(m, CH, w=0.62, h=0.22, brim=False)
    m.box((0, 1.325, 0), (0.07, 0.03, 0.4), "#F28C1F")
    m.box((0, 1.02, -0.265), (0.56, 0.22, 0.05), CH)  # neck guard
    m.box((0, 0.88, 0.24), (0.46, 0.12, 0.03), BLK)  # bandana mask
    arm(m, -1, (-0.3, 0.70, 0.0), (-0.22, 0.56, 0.22), "#F28C1F", w=0.13, hand_s=0.12)
    arm(m, 1, (0.3, 0.70, 0.0), (0.36, 0.46, 0.06), "#F28C1F", w=0.13, hand_s=0.12)
    x, y = -0.22, 0.60
    m.box((x, y, 0.28), (0.12, 0.15, 0.44), BLK, bevel=0.015)
    m.box((x, y + 0.01, 0.62), (0.105, 0.105, 0.30), CH)  # barrel shroud
    m.box((x, y + 0.01, 0.82), (0.05, 0.05, 0.12), "#111216")
    for z in (0.53, 0.62, 0.71):  # glowing heat vents
        m.box((x, y + 0.06, z), (0.05, 0.03, 0.045), GPUR)
    m.cyl((x + 0.13, y - 0.1, 0.26), 0.09, 0.11, "#3A3D45", sides=8, rot=(0, 0, 90))  # side drum
    m.box((x + 0.13, y - 0.1, 0.26), (0.13, 0.05, 0.13), "#F2C21A")
    m.box((x, y - 0.03, 0.03), (0.09, 0.13, 0.14), "#2A2B33")
    m.set_muzzle((x, y + 0.01, 0.9))
    m.fit(height=1.3)
    return m


def sniper_rare():
    m = Model("sniper_rare")
    TEAL, DK = "#1F3A3F", "#14202A"
    legs(m, "#162A2E", "#14151A", w=0.88)
    torso(m, TEAL, w=0.88, d=0.24)
    m.box((0, 0.23, 0), (0.37, 0.26, 0.28), TEAL)  # long coat skirt
    m.box((0, 0.13, 0), (0.385, 0.04, 0.295), PUR)  # hem trim
    m.box((0, 0.23, -0.142), (0.07, 0.26, 0.012), "#0F1F22")  # back split
    m.limb((-0.17, 0.72, 0.14), (0.17, 0.38, 0.14), 0.05, "#6B4423", d=0.04)  # bandolier
    for t in (0.2, 0.4, 0.6, 0.8):
        p = along((-0.17, 0.72, 0.17), (0.17, 0.38, 0.17), t)
        m.box(p, (0.04, 0.06, 0.03), BRASS)
    m.box((0, 0.50, -0.25), (0.22, 0.18, 0.10), "#2E3A3F")  # ammo case
    m.box((0, 0.54, -0.17), (0.34, 0.40, 0.04), TEAL)  # cape panel
    m.box((0, 0.345, -0.17), (0.34, 0.035, 0.05), PUR)
    head(m)
    m.box((0, 1.15, 0), (0.80, 0.04, 0.76), TEAL, bevel=0.01)  # wide brim
    m.box((0, 1.25, 0), (0.50, 0.16, 0.46), TEAL, bevel=0.03)
    m.box((0, 1.195, 0), (0.52, 0.05, 0.48), PUR)
    m.box((0, 0.88, 0.24), (0.46, 0.14, 0.03), DK)  # mask
    m.box((0, 0.88, 0.256), (0.30, 0.03, 0.012), PUR)
    ez = 0.255  # glowing monocle ring around the right eye (eye stays visible inside)
    m.box((-0.12, 1.045, ez), (0.13, 0.03, 0.03), GPUR)
    m.box((-0.12, 0.925, ez), (0.13, 0.03, 0.03), GPUR)
    m.box((-0.185, 0.985, ez), (0.03, 0.12, 0.03), GPUR)
    m.box((-0.055, 0.985, ez), (0.03, 0.12, 0.03), GPUR)
    m.box((-0.26, 0.985, 0.13), (0.06, 0.04, 0.26), "#2E3A3F")  # side arm of the scope
    arm(m, -1, (-0.22, 0.70, 0.0), (-0.19, 0.58, 0.2), TEAL, w=0.09, hand_s=0.1)
    arm(m, 1, (0.22, 0.70, 0.0), (0.26, 0.46, 0.06), TEAL, w=0.09, hand_s=0.1)
    x, y = -0.19, 0.62
    m.box((x, y - 0.03, 0.06), (0.07, 0.14, 0.2), "#1B1C21")
    m.box((x, y, 0.34), (0.065, 0.09, 0.44), "#2A2C33")
    m.box((x, y + 0.005, 0.82), (0.045, 0.045, 0.60), "#14151A")
    m.box((x, y + 0.10, 0.36), (0.09, 0.09, 0.30), "#14151A")  # big box scope
    m.box((x, y + 0.10, 0.52), (0.07, 0.07, 0.02), GPUR)
    m.box((x, y + 0.01, 0.95), (0.08, 0.08, 0.05), PUR)  # barrel ring
    m.limb((x, y - 0.03, 0.78), (x, y - 0.12, 0.92), 0.03, "#2A2C33")  # folded bipod
    m.set_muzzle((x, y + 0.005, 1.14))
    m.fit(height=1.3)
    return m


def rocket_soldier_rare():
    m = Model("rocket_soldier_rare")
    CHAR, OLIVE = "#26262E", "#3F4823"
    legs(m, "#5A1A1A", CHAR)
    torso(m, "#CC3330", w=1.15)
    m.box((0, 0.56, 0.15), (0.40, 0.30, 0.04), CHAR, bevel=0.015)  # blast armor
    m.box((0, 0.715, 0.155), (0.40, 0.03, 0.05), PUR)
    for sx in (-1, 1):
        m.box((sx * 0.29, 0.74, 0), (0.15, 0.10, 0.26), CHAR, bevel=0.02)
        m.box((sx * 0.29, 0.795, 0), (0.15, 0.03, 0.26), PUR)
        m.box((sx * 0.1, 0.34, 0.145), (0.07, 0.05, 0.02), "#F2C21A")  # hazard belt marks
    m.box((0, 0.56, -0.15), (0.34, 0.30, 0.10), CHAR)  # rocket rack frame
    for x in (-0.1, 0.0, 0.1):
        m.cyl((x, 0.82, -0.25), 0.05, 0.40, "#5F6B35", sides=6)
        m.pyramid((x, 1.02, -0.25), (0.11, 0.11), 0.11, GPUR, sides=6)
    m.box((0, 0.40, -0.27), (0.22, 0.14, 0.09), "#8A3B1E")  # fuel tank
    head(m)
    helmet(m, "#3A1414", w=0.58, h=0.22)
    m.box((0, 1.22, 0.275), (0.34, 0.14, 0.03), CHAR)  # blast plate
    lenses(m, GPUR, size=(0.12, 0.09, 0.02), frame=CHAR, fw=0.46)
    m.box((0, 0.87, 0.255), (0.30, 0.16, 0.07), CHAR)  # respirator
    for sx in (-1, 1):
        m.box((sx * 0.17, 0.86, 0.22), (0.08, 0.10, 0.10), "#3A3D45")
    arm(m, -1, (-0.24, 0.70, 0.0), (-0.28, 0.60, 0.16), "#CC3330")
    arm(m, 1, (0.24, 0.70, 0.0), (0.285, 0.46, 0.06), "#CC3330")
    tx, ty = -0.32, 0.79
    m.cyl((tx, ty, 0.12), 0.12, 0.95, OLIVE, sides=8, rot=(90, 0, 0))
    m.cyl((tx, ty, 0.62), 0.145, 0.08, CHAR, sides=8, rot=(90, 0, 0))
    m.cyl((tx, ty, -0.34), 0.145, 0.08, CHAR, sides=8, rot=(90, 0, 0))
    m.cyl((tx, ty, 0.30), 0.13, 0.04, PUR, sides=8, rot=(90, 0, 0))
    m.pyramid((tx, ty, 0.52), (0.17, 0.17), 0.24, GPUR, rot=(90, 0, 0), sides=6)  # warhead
    m.box((tx, ty - 0.15, 0.2), (0.05, 0.08, 0.1), "#2A2B33")
    m.set_muzzle((tx, ty, 0.8))
    m.fit(height=1.3)
    return m


def medic_super_rare():
    m = Model("medic_super_rare")
    W = "#F4F4F4"
    legs(m, "#CFCFCF", "#4A4A52")
    torso(m, "#F2F2F2", w=1.05, belt="#2F3138")
    m.box((0, 0.34, 0.15), (0.05, 0.05, 0.02), "#40B359")  # tiny green buckle
    m.box((0, 0.23, 0), (0.42, 0.28, 0.29), W)  # long coat
    m.box((0, 0.10, 0), (0.43, 0.04, 0.30), BLU)
    m.box((0, 0.775, 0), (0.44, 0.06, 0.31), BLU)  # collar
    m.box((0, 0.55, 0.15), (0.26, 0.08, 0.02), BLU)  # chest cross
    m.box((0, 0.55, 0.15), (0.08, 0.26, 0.02), BLU)
    m.box((0, 0.56, -0.21), (0.30, 0.34, 0.14), W, bevel=0.03)  # tank
    m.box((0, 0.745, -0.21), (0.16, 0.03, 0.10), GBLU)
    for sx in (-1, 1):
        m.box((sx * 0.152, 0.56, -0.21), (0.02, 0.22, 0.08), GBLU)  # glowing liquid windows
        m.limb((sx * 0.1, 0.72, -0.22), (sx * 0.2, 0.75, -0.02), 0.035, "#6E7787")  # hoses
    m.box((0, 0.56, -0.292), (0.36, 0.09, 0.02), BLU)  # huge back cross
    m.box((0, 0.56, -0.292), (0.09, 0.36, 0.02), BLU)
    head(m)
    helmet(m, W)
    m.box((0, 1.21, 0.265), (0.12, 0.04, 0.02), BLU)
    m.box((0, 1.21, 0.265), (0.04, 0.12, 0.02), BLU)
    m.box((0, 1.135, 0.255), (0.42, 0.035, 0.03), BLU)  # visor strip
    m.cyl((0, 1.095, 0.275), 0.05, 0.02, "#C9CDD6", sides=8, rot=(90, 0, 0))  # head mirror
    m.box((0, 0.885, 0.24), (0.42, 0.13, 0.03), BLU)  # mask
    a1, b1 = (-0.24, 0.70, 0.0), (-0.2, 0.57, 0.2)
    arm(m, -1, a1, b1, "#F2F2F2")
    cuff(m, a1, b1, BLU)
    arm(m, 1, (0.24, 0.70, 0.0), (0.285, 0.46, 0.06), "#F2F2F2")
    m.limb((-0.31, 0.76, -0.02), (-0.31, 1.23, -0.02), 0.035, "#9AA1B3")  # beacon pole
    m.box((-0.31, 1.27, -0.02), (0.15, 0.05, 0.05), GBLU)
    m.box((-0.31, 1.27, -0.02), (0.05, 0.15, 0.05), GBLU)
    x, y = -0.2, 0.62  # syringe gun
    m.box((x, y, 0.34), (0.075, 0.075, 0.34), "#E8E8E8")
    m.box((x, y + 0.045, 0.34), (0.04, 0.02, 0.2), GBLU)
    m.box((x, y, 0.1), (0.05, 0.05, 0.14), "#9AA1B3")
    m.box((x, y, 0.03), (0.11, 0.04, 0.04), "#9AA1B3")
    m.box((x, y - 0.075, 0.2), (0.05, 0.1, 0.06), "#2F3138")
    m.pyramid((x, y, 0.51), (0.08, 0.08), 0.13, GBLU, rot=(90, 0, 0), sides=6)
    m.set_muzzle((x, y, 0.66))
    m.fit(height=1.3)
    return m


# ===================================================================================== MORTAR
def _mortar(name, rare):
    m = Model(name)
    if rare:
        UNI, STEEL, LEA, SH = "#2F3440", "#2F3440", "#4A3320", "#2A2D36"
        legs(m, "#262A33", LEA, w=1.05)
        torso(m, UNI, w=1.1, belt=LEA)
        m.box((0, 0.50, 0.155), (0.34, 0.42, 0.04), LEA, bevel=0.01)  # apron
        m.box((0, 0.715, 0.16), (0.34, 0.03, 0.05), PUR)
        m.limb((-0.19, 0.72, 0.19), (0.19, 0.38, 0.19), 0.05, LEA, d=0.04)  # bandolier
        for t in (0.1, 0.3, 0.5, 0.7, 0.9):
            p = along((-0.19, 0.72, 0.21), (0.19, 0.38, 0.21), t)
            m.box(p, (0.055, 0.09, 0.05), SH)
            m.box((p[0], p[1] + 0.06, p[2]), (0.055, 0.035, 0.05), BRASS)
        head(m)
        m.box((0, 1.17, 0), (0.58, 0.26, 0.54), STEEL, bevel=0.04)  # full helmet
        m.box((0, 1.05, -0.26), (0.56, 0.1, 0.04), STEEL)
        for sx in (-1, 1):
            m.box((sx * 0.32, 0.97, 0), (0.10, 0.18, 0.20), "#1E2128", bevel=0.015)  # ear defenders
            m.box((sx * 0.30, 1.1, 0), (0.06, 0.08, 0.1), PUR)
        lenses(m, GPUR, y=0.985, z=0.262, frame="#1E2128", fw=0.52)
        base = (-0.08, 0.06, 0.36)
        m.box((base[0], 0.03, base[2]), (0.42, 0.06, 0.42), "#4A5263", bevel=0.01)  # heavy base plate
        c, top, d = tube(m, base, 0.55, 0.095, 20, "#5A6377")
        for t in (0.22, 0.42):
            m.cyl(tuple(np.array(base) + d * 0.5 * t * 2), 0.108, 0.04, GPUR, sides=8, rot=(20, 0, 0))
        m.cyl(top, 0.115, 0.04, "#3A4050", sides=8, rot=(20, 0, 0))
        for sx in (-1, 1):  # sturdier bipod
            m.limb(tuple(np.array(base) + d * 0.3), (base[0] + sx * 0.2, 0.04, 0.56), 0.04, "#4A5263")
        m.box((0, 0.52, -0.2), (0.34, 0.30, 0.12), STEEL)  # shell rack
        for x in (-0.11, 0.0, 0.11):
            m.cyl((x, 0.80, -0.25), 0.055, 0.32, SH, sides=6)
            m.pyramid((x, 0.96, -0.25), (0.11, 0.11), 0.09, GPUR, sides=6)
        hand = (top[0] + 0.0, top[1] + 0.05, top[2])
        sh_tip = GPUR
    else:
        UNI, LEA, SH = "#5B6575", "#6B4423", "#2A2D36"
        legs(m, "#454E5C", LEA)
        torso(m, UNI, belt=LEA)
        m.limb((-0.19, 0.72, 0.14), (0.19, 0.38, 0.14), 0.05, LEA, d=0.04)
        head(m)
        m.cyl((0, 1.22, 0), 0.30, 0.16, "#3E4553", sides=8, r_top=0.24)  # pot helmet
        m.cyl((0, 1.14, 0), 0.33, 0.05, "#2E3541", sides=8)
        base = (-0.08, 0.04, 0.34)
        m.box((base[0], 0.02, base[2]), (0.3, 0.04, 0.3), "#555D6D", bevel=0.01)
        c, top, d = tube(m, base, 0.50, 0.08, 20, "#6A7385", r_top=0.09)
        m.cyl(top, 0.105, 0.04, "#454C5A", sides=8, rot=(20, 0, 0))
        for sx in (-1, 1):
            m.limb(tuple(np.array(base) + d * 0.28), (base[0] + sx * 0.16, 0.03, 0.5), 0.035, "#555D6D")
        m.box((0, 0.52, -0.2), (0.30, 0.28, 0.14), "#7A7355", bevel=0.02)  # canvas bag
        for x in (-0.06, 0.06):
            m.cyl((x, 0.72, -0.2), 0.045, 0.12, SH, sides=6)
            m.pyramid((x, 0.78, -0.2), (0.09, 0.09), 0.06, BRASS, sides=6)
        hand = (top[0], top[1] + 0.03, top[2])
        sh_tip = BRASS
    # right hand rests on the tube, left hand holds a shell
    sh = (-0.24, 0.70, 0.0)
    m.limb(sh, (-0.22, 0.57, 0.16), 0.10, UNI)
    m.limb((-0.22, 0.57, 0.16), hand, 0.10, UNI)
    m.box(hand, (0.11, 0.11, 0.11), SKIN)
    arm(m, 1, (0.24, 0.70, 0.0), (0.2, 0.50, 0.2), UNI)
    m.cyl((0.2, 0.57, 0.23), 0.055, 0.2, SH, sides=6)
    m.pyramid((0.2, 0.67, 0.23), (0.11, 0.11), 0.07, sh_tip, sides=6)
    m.set_muzzle(top)
    m.fit(height=1.3)
    return m


def mortar_common():
    return _mortar("mortar_common", False)


def mortar_rare():
    return _mortar("mortar_rare", True)


# =================================================================================== WEAKENER
def weakener_common():
    m = Model("weakener_common")
    TEAL, DT, CREAM, YG = "#1FA5A0", "#0F5F5C", "#EFE9D8", "#B8D435"
    legs(m, DT, "#2A2D36")
    torso(m, TEAL, belt=DT)
    head(m)
    m.box((0, 1.19, 0), (0.56, 0.16, 0.52), DT, bevel=0.05)  # soft cap
    m.box((0, 1.12, 0.27), (0.4, 0.03, 0.08), shade(DT, 0.8))
    m.box((0, 0.88, 0.25), (0.34, 0.14, 0.07), CREAM)  # respirator
    for sx in (-1, 1):
        m.cyl((sx * 0.12, 0.86, 0.3), 0.05, 0.06, DT, sides=6, rot=(90, 0, 0))
    m.box((0, 0.56, -0.23), (0.30, 0.36, 0.16), DT, bevel=0.04)  # tank
    m.box((0, 0.755, -0.23), (0.10, 0.05, 0.10), CREAM)
    m.box((0, 0.57, -0.312), (0.22, 0.30, 0.012), YG)  # liquid window
    m.limb((-0.07, 0.69, -0.322), (0.0, 0.62, -0.322), 0.04, CREAM, d=0.012)  # broken sword
    m.limb((0.03, 0.60, -0.322), (0.075, 0.555, -0.322), 0.04, CREAM, d=0.012)
    m.box((0, 0.50, -0.322), (0.04, 0.07, 0.012), CREAM)  # down arrow
    m.pyramid((0, 0.465, -0.322), (0.11, 0.11), 0.05, CREAM, rot=(180, 0, 0))
    m.limb((-0.15, 0.5, -0.22), (-0.29, 0.52, -0.02), 0.04, DT)  # hose
    m.limb((-0.29, 0.52, -0.02), (-0.22, 0.58, 0.12), 0.04, DT)
    arm(m, -1, (-0.24, 0.70, 0.0), (-0.2, 0.57, 0.2), TEAL)
    arm(m, 1, (0.24, 0.70, 0.0), (0.285, 0.46, 0.06), TEAL)
    x = -0.2
    m.box((x, 0.60, 0.28), (0.09, 0.10, 0.26), "#2A2D36")
    m.box((x, 0.605, 0.46), (0.07, 0.07, 0.10), "#2A2D36")
    m.box((x, 0.605, 0.535), (0.08, 0.08, 0.05), YG)
    m.set_muzzle((x, 0.605, 0.58))
    m.fit(height=1.3)
    return m


def weakener_rare():
    m = Model("weakener_rare")
    DT, CREAM = "#0F5F5C", "#EFE9D8"
    legs(m, "#0B4543", "#2A2D36")
    torso(m, DT, w=1.05, belt="#0B3F3D")
    m.box((0, 0.20, 0), (0.42, 0.34, 0.30), DT)  # long coat
    for i, x in enumerate((-0.15, -0.05, 0.05, 0.15)):  # jagged hem
        m.box((x, 0.03 + (0.03 if i % 2 else 0.0), 0), (0.10, 0.06, 0.30), DT)
    m.box((0, 0.20, 0.155), (0.06, 0.30, 0.015), PUR)
    m.box((0, 0.775, 0), (0.44, 0.07, 0.32), CREAM)
    m.box((-0.28, 0.76, 0), (0.16, 0.09, 0.26), DT, bevel=0.02)  # pauldron + badge
    m.box((-0.28, 0.81, 0), (0.12, 0.03, 0.14), CREAM)
    m.box((-0.28, 0.835, 0), (0.05, 0.03, 0.10), PUR)
    m.cyl((0, 0.56, -0.26), 0.17, 0.36, "#3E5058", sides=8)  # round-box tank
    m.box((0, 0.56, -0.425), (0.16, 0.26, 0.03), GPUR)
    for p in ((-0.04, 0.64), (0.04, 0.54), (-0.02, 0.47)):
        m.box((p[0], p[1], -0.445), (0.05, 0.05, 0.03), GPUR2)  # cube bubbles
    for sx in (-1, 1):
        m.limb((sx * 0.1, 0.70, -0.30), (sx * 0.22, 0.74, -0.04), 0.04, "#0B3F3D")
    head(m)
    m.box((0, 1.14, 0), (0.64, 0.04, 0.58), DT)  # hat brim
    m.box((0, 1.28, 0), (0.46, 0.26, 0.44), DT, bevel=0.03)  # tall top hat
    m.box((0, 1.19, 0), (0.48, 0.07, 0.46), PUR)
    m.box((0, 0.885, 0.255), (0.34, 0.19, 0.06), CREAM)  # mask
    m.frustum((0, 0.90, 0.28), (0.16, 0.14), (0.06, 0.05), 0.22, CREAM, rot=(90, 0, 0))  # beak
    for sx in (-1, 1):
        m.box((sx * 0.12, 0.985, 0.262), (0.11, 0.10, 0.02), GPUR)
    eyes_on(m, 0.985, 0.282)
    a1, b1 = (-0.24, 0.70, 0.0), (-0.22, 0.58, 0.28)
    arm(m, -1, a1, b1, DT)
    arm(m, 1, (0.24, 0.70, 0.0), (0.285, 0.46, 0.06), DT)
    sx_, sz = -0.22, 0.28  # hex staff
    m.limb((sx_, 0.0, sz), (sx_, 1.10, sz), 0.045, "#4A4F5C")
    for cx in (-1, 1):
        for cz in (-1, 1):
            m.box((sx_ + cx * 0.06, 1.18, sz + cz * 0.06), (0.03, 0.15, 0.03), "#4A4F5C")
    m.box((sx_, 1.18, sz), (0.10, 0.10, 0.10), GPUR)
    m.set_muzzle((sx_, 1.18, sz))
    m.fit(height=1.3)
    return m


# =================================================================================== DRUMMER
def _drum_front(m, rare):
    if rare:
        shell, hoop, head_c = "#2B2330", GOLD, GPUR
        r = 0.21
    else:
        shell, hoop, head_c = "#C99A3A", "#C93A3A", WHITE
        r = 0.19
    m.cyl((0, 0.48, 0.29), r, 0.16, shell, sides=8)
    m.cyl((0, 0.57, 0.29), r + 0.012, 0.035, hoop, sides=8)
    m.cyl((0, 0.395, 0.29), r + 0.012, 0.035, hoop, sides=8)
    m.cyl((0, 0.59, 0.29), r - 0.02, 0.02, head_c, sides=8)


def drummer_common():
    m = Model("drummer_common")
    Y, BR = "#E8B423", "#5B3E22"
    legs(m, WHITE, BR)
    torso(m, Y, belt=WHITE)
    for s in (-1, 1):  # white cross straps
        m.limb((s * 0.16, 0.74, 0.145), (-s * 0.16, 0.36, 0.145), 0.05, WHITE, d=0.03)
    for yy in (0.46, 0.62, 0.72):
        m.box((0.0, yy, 0.16), (0.04, 0.04, 0.02), BRASS)
    m.box((0, 0.54, -0.19), (0.34, 0.14, 0.13), "#6B4F2E", bevel=0.02)  # bedroll
    for sx in (-1, 1):
        m.box((sx * 0.1, 0.54, -0.19), (0.04, 0.16, 0.14), WHITE)
    _drum_front(m, False)
    head(m)
    m.box((0, 1.24, 0), (0.46, 0.22, 0.44), Y, bevel=0.03)  # shako
    m.box((0, 1.165, 0), (0.48, 0.04, 0.46), BRASS)
    m.box((0, 1.15, 0.26), (0.40, 0.03, 0.08), BR)
    m.cyl((0, 1.40, 0), 0.045, 0.12, WHITE, sides=6)
    a1, b1 = (-0.24, 0.70, 0.0), (-0.13, 0.66, 0.28)
    arm(m, -1, a1, b1, Y)
    arm(m, 1, (0.24, 0.70, 0.0), (0.13, 0.66, 0.28), Y)
    for sx in (-1, 1):  # drumsticks with ball tips
        m.limb((sx * 0.13, 0.66, 0.24), (sx * 0.13, 0.71, 0.44), 0.04, WHITE)
        m.ball((sx * 0.13, 0.715, 0.46), 0.035, WHITE)
    m.set_muzzle((-0.13, 0.715, 0.47))
    m.fit(height=1.3)
    return m


def drummer_rare():
    m = Model("drummer_rare")
    Y, DK, CAPE = "#E8B423", "#2B2330", "#2A1840"
    legs(m, WHITE, DK)
    torso(m, Y, w=1.05, belt=GOLD)
    for s in (-1, 1):
        m.limb((s * 0.16, 0.74, 0.145), (-s * 0.16, 0.36, 0.145), 0.05, WHITE, d=0.03)
    for sx in (-1, 1):
        for yy in (0.42, 0.52, 0.62, 0.72):
            m.box((sx * 0.075, yy, 0.16), (0.04, 0.04, 0.02), BRASS)
        m.box((sx * 0.29, 0.765, 0), (0.17, 0.05, 0.23), GOLD)  # epaulettes
        for z in (-0.07, 0.0, 0.07):
            m.box((sx * 0.35, 0.715, z), (0.04, 0.06, 0.04), GOLD)
    m.box((0, 0.775, 0), (0.44, 0.06, 0.30), PUR)  # collar
    m.box((0, 0.515, -0.17), (0.38, 0.46, 0.04), CAPE)  # cape
    m.box((0, 0.28, -0.17), (0.38, 0.035, 0.05), GOLD)
    for sx in (-1, 1):
        m.box((sx * 0.19, 0.515, -0.17), (0.035, 0.46, 0.05), GOLD)
    m.cyl((0, 0.52, -0.26), 0.14, 0.12, DK, sides=8, rot=(90, 0, 0))  # back bass drum
    m.cyl((0, 0.52, -0.325), 0.115, 0.03, GPUR, sides=8, rot=(90, 0, 0))
    for x, h in ((-0.05, 0.05), (0.0, 0.10), (0.05, 0.05)):  # sound-wave symbol
        m.box((x, 0.52, -0.345), (0.03, h, 0.012), DK)
    _drum_front(m, True)
    for k, (zc, hw) in enumerate(((0.54, 0.09), (0.64, 0.17))):  # sound-wave arcs on the rim
        m.box((0, 0.48, zc + 0.03), (0.10, 0.14, 0.03), GPUR)
        for sx in (-1, 1):
            m.box((sx * (hw + 0.04), 0.48, zc), (0.10, 0.14, 0.03), GPUR, rot=(0, sx * 35, 0))
    m.box((0, 0.48, 0.49), (0.05, 0.05, 0.06), GOLD)  # connector to the rim
    head(m)
    m.frustum((0, 1.12, 0), (0.50, 0.46), (0.44, 0.40), 0.26, DK)  # bearskin
    m.box((0, 1.17, 0), (0.52, 0.05, 0.48), GOLD)
    m.cyl((0, 1.43, 0), 0.06, 0.18, PUR, sides=6, r_top=0.035)  # plume
    a1, b1 = (-0.24, 0.70, 0.0), (-0.13, 0.66, 0.28)
    arm(m, -1, a1, b1, Y)
    cuff(m, a1, b1, PUR)
    arm(m, 1, (0.24, 0.70, 0.0), (0.13, 0.66, 0.28), Y)
    cuff(m, (0.24, 0.70, 0.0), (0.13, 0.66, 0.28), PUR)
    for sx in (-1, 1):
        m.limb((sx * 0.13, 0.66, 0.22), (sx * 0.13, 0.74, 0.5), 0.04, WHITE)
        m.ball((sx * 0.13, 0.745, 0.52), 0.04, GPUR)
    m.set_muzzle((-0.13, 0.745, 0.53))
    m.fit(height=1.3)
    return m


# =================================================================================== BLINDER
def _launcher(m, rare):
    x = -0.2
    col = "#4A3320"
    if rare:
        m.cyl((x, 0.6, 0.30), 0.09, 0.52, col, sides=8, rot=(90, 0, 0))
        m.cyl((x, 0.6, 0.55), 0.105, 0.05, GPUR, sides=8, rot=(90, 0, 0))
        z = 0.58
    else:
        m.cyl((x, 0.6, 0.30), 0.075, 0.5, col, sides=8, rot=(90, 0, 0))
        m.ball((x, 0.6, 0.55), 0.095, "#FFF3B0", seg=6, rings=3)
        z = 0.64
    m.box((x, 0.53, 0.22), (0.05, 0.1, 0.07), "#2A2B33")
    m.set_muzzle((x, 0.6, z))


def blinder_common():
    m = Model("blinder_common")
    SAND, BR, GREY, FLASH = "#D8B779", "#6B4423", "#C9CDD6", "#FFF3B0"
    legs(m, "#B99A5E", BR)
    torso(m, SAND, belt=BR)
    m.limb((-0.19, 0.72, 0.17), (0.19, 0.38, 0.17), 0.05, BR, d=0.04)
    for t in (0.12, 0.37, 0.62, 0.87):  # 4 flash grenades
        p = along((-0.19, 0.72, 0.21), (0.19, 0.38, 0.21), t)
        m.cyl(p, 0.045, 0.11, "#A7ABB5", sides=6)
        m.cyl((p[0], p[1] + 0.065, p[2]), 0.04, 0.03, FLASH, sides=6)
    m.box((0, 0.52, -0.2), (0.32, 0.30, 0.14), BR, bevel=0.02)
    for x in (-0.09, 0.0, 0.09):  # smoke canisters
        m.cyl((x, 0.74, -0.2), 0.045, 0.2, GREY, sides=6)
        m.cyl((x, 0.85, -0.2), 0.04, 0.03, "#4A5060", sides=6)
    head(m)
    helmet(m, SAND, brim=False)
    m.box((0, 0.985, 0.255), (0.50, 0.17, 0.04), BR)  # oversized goggles
    for sx in (-1, 1):
        m.box((sx * 0.12, 0.985, 0.282), (0.15, 0.13, 0.02), "#DDE6EA")
    eyes_on(m, 0.985, 0.298)
    arm(m, -1, (-0.24, 0.70, 0.0), (-0.2, 0.55, 0.22), SAND)
    arm(m, 1, (0.24, 0.70, 0.0), (0.285, 0.46, 0.06), SAND)
    _launcher(m, False)
    m.fit(height=1.3)
    return m


def blinder_rare():
    m = Model("blinder_rare")
    DS, BR, GREY = "#8C6F42", "#4A3320", "#C9CDD6"
    legs(m, "#6B5632", "#2A2D36", w=1.05)
    torso(m, "#A68A5B", w=1.05, belt=BR)
    m.box((0, 0.55, 0.15), (0.36, 0.30, 0.04), DS, bevel=0.015)  # vest
    m.box((0, 0.715, 0.155), (0.36, 0.03, 0.05), PUR)
    m.box((0, 0.58, 0.19), (0.18, 0.16, 0.05), BR)  # chest lamp
    m.box((0, 0.58, 0.22), (0.13, 0.11, 0.02), GPUR)
    m.box((0, 0.775, 0.02), (0.44, 0.07, 0.32), BR)  # scarf
    m.box((0.3, 0.84, 0.08), (0.08, 0.08, 0.26), BR)  # shoulder flare launcher
    m.box((0.3, 0.84, 0.23), (0.06, 0.06, 0.04), GPUR)
    m.box((0, 0.58, -0.21), (0.38, 0.36, 0.12), BR, bevel=0.02)  # lamp-array pack
    for p in ((-0.1, 0.67), (0.1, 0.67), (0.0, 0.50)):
        m.box((p[0], p[1], -0.275), (0.09, 0.09, 0.02), GPUR)
    for x in (-0.1, 0.1):
        m.cyl((x, 0.84, -0.21), 0.045, 0.16, GREY, sides=6)
    head(m)
    m.box((0, 1.22, 0), (0.60, 0.12, 0.56), DS, bevel=0.03)  # welding helmet
    for sx in (-1, 1):
        m.box((sx * 0.29, 0.95, 0), (0.06, 0.40, 0.5), DS)
        m.box((sx * 0.35, 1.02, 0.12), (0.08, 0.12, 0.14), GPUR)  # side lamps
    m.box((0, 0.95, -0.26), (0.6, 0.40, 0.06), DS)
    m.box((0, 1.11, 0.265), (0.6, 0.10, 0.05), DS)
    m.box((0, 0.85, 0.265), (0.6, 0.18, 0.05), DS)
    arm(m, -1, (-0.24, 0.70, 0.0), (-0.2, 0.55, 0.22), "#A68A5B")
    arm(m, 1, (0.24, 0.70, 0.0), (0.285, 0.46, 0.06), "#A68A5B")
    _launcher(m, True)
    m.fit(height=1.3)
    return m


# ================================================================================ SHIELD KNIGHT
def _knight(name, rare):
    m = Model(name)
    SIL, DK, ST = "#A9B1BD", "#6E7787", "#C5CBD6"
    w = 1.35 if rare else 1.05
    legs(m, DK, "#4A5060", w=1.2 if rare else 1.0)
    torso(m, "#4A5060", w=w, belt=DK)
    m.box((0, 0.55, 0.145), (0.38 * w - 0.02, 0.30, 0.04), SIL, bevel=0.02)  # breastplate
    m.box((0, 0.55, -0.145), (0.38 * w - 0.04, 0.28, 0.04), SIL, bevel=0.02)  # back plate
    if rare:
        m.box((0, 0.715, 0.15), (0.38 * w - 0.02, 0.03, 0.05), PUR)
        m.box((0, 0.395, 0.15), (0.38 * w - 0.02, 0.03, 0.05), GOLD)
        m.box((0, 0.51, -0.175), (0.50, 0.56, 0.04), "#2A1840")  # cape
        m.box((0, 0.23, -0.175), (0.50, 0.035, 0.05), GOLD)
        for sx in (-1, 1):
            m.box((sx * 0.245, 0.51, -0.175), (0.035, 0.56, 0.05), GOLD)
    for sx in (-1, 1):
        px = sx * (0.31 if rare else 0.27)
        m.box((px, 0.74, 0), (0.18 if rare else 0.14, 0.09, 0.26 if rare else 0.22), SIL, bevel=0.02)
        if rare:
            m.pyramid((px, 0.785, 0), (0.08, 0.08), 0.09, DK)
            m.box((px, 0.745, 0.125), (0.18, 0.03, 0.03), PUR)
    head(m)
    if rare:  # closed great helm, T-shaped slit
        m.box((0, 1.22, 0), (0.58, 0.12, 0.54), DK, bevel=0.03)
        m.box((0, 1.10, 0.265), (0.58, 0.10, 0.05), DK)
        for sx in (-1, 1):
            m.box((sx * 0.17, 0.85, 0.265), (0.24, 0.18, 0.05), DK)
            m.box((sx * 0.29, 0.95, 0), (0.06, 0.42, 0.5), DK)
            m.box((sx * 0.33, 1.25, 0), (0.10, 0.12, 0.12), SIL)  # side crests
        m.box((0, 0.95, -0.26), (0.58, 0.42, 0.06), DK)
        m.box((0, 1.40, -0.04), (0.10, 0.16, 0.14), PUR)  # plume
    else:
        helmet(m, SIL, w=0.58, h=0.22, brim=False)
        m.box((0, 1.0, 0.255), (0.05, 0.16, 0.03), SIL)  # nose guard
        for sx in (-1, 1):
            m.box((sx * 0.27, 0.97, 0.0), (0.05, 0.2, 0.3), SIL)
        m.box((0, 1.35, 0), (0.07, 0.07, 0.32), WHITE)  # plume
    # tower / kite shield on the left arm
    if rare:
        sc, sy, sh_h, sw = (0.22, 0.28), 0.52, 0.85, 0.46
        m.box((sc[0], sy, sc[1]), (sw, sh_h, 0.06), "#8F97A5")
        m.box((sc[0], sy + sh_h / 2, sc[1]), (sw + 0.04, 0.05, 0.08), GOLD)
        m.box((sc[0], sy - sh_h / 2, sc[1]), (sw + 0.04, 0.05, 0.08), GOLD)
        for sx in (-1, 1):
            m.box((sc[0] + sx * sw / 2, sy, sc[1]), (0.05, sh_h, 0.08), GOLD)
        m.box((sc[0], 0.46, 0.32), (0.22, 0.06, 0.03), GPUR)  # crown crest
        for dx, hh in ((-0.08, 0.10), (0.0, 0.15), (0.08, 0.10)):
            m.box((sc[0] + dx, 0.52 + hh / 2, 0.32), (0.05, hh, 0.03), GPUR)
        m.box((sc[0], 0.36, 0.32), (0.10, 0.08, 0.03), GPUR)
        hand_l = (0.22, 0.5, 0.2)
    else:
        m.box((0.2, 0.65, 0.24), (0.40, 0.26, 0.05), "#8F97A5")
        m.frustum((0.2, 0.22, 0.24), (0.10, 0.05), (0.40, 0.05), 0.30, "#8F97A5")
        m.box((0.2, 0.79, 0.24), (0.44, 0.04, 0.07), GOLD)
        for sx in (-1, 1):
            m.box((0.2 + sx * 0.2, 0.65, 0.24), (0.04, 0.26, 0.07), GOLD)
        m.box((0.2, 0.60, 0.27), (0.20, 0.05, 0.02), GOLD)  # cross emblem
        m.box((0.2, 0.56, 0.27), (0.05, 0.24, 0.02), GOLD)
        hand_l = (0.22, 0.5, 0.2)
    arm(m, 1, (0.24, 0.70, 0.0), hand_l, DK)
    # right hand weapon
    if rare:
        a, b = (-0.26 if rare else -0.24, 0.70, 0.0), (-0.24, 0.58, 0.22)
        arm(m, -1, (-0.28, 0.70, 0.0), b, DK, w=0.12)
        m.box((-0.24, 0.60, 0.34), (0.05, 0.05, 0.30), "#4A5060")  # mace handle
        m.box((-0.24, 0.60, 0.52), (0.14, 0.14, 0.14), DK, bevel=0.015)
        m.box((-0.24, 0.60, 0.52), (0.19, 0.06, 0.06), GPUR)  # glowing core
        m.box((-0.24, 0.60, 0.52), (0.06, 0.19, 0.06), GPUR)
        m.set_muzzle((-0.24, 0.60, 0.6))
    else:
        arm(m, -1, (-0.24, 0.70, 0.0), (-0.2, 0.58, 0.2), DK)
        m.box((-0.2, 0.6, 0.18), (0.04, 0.04, 0.10), "#6B4423")  # grip
        m.box((-0.2, 0.6, 0.24), (0.18, 0.04, 0.04), GOLD)  # crossguard
        m.box((-0.2, 0.6, 0.46), (0.08, 0.05, 0.40), ST)  # broad blade
        m.set_muzzle((-0.2, 0.6, 0.67))
    m.fit(height=1.3)
    return m


def shield_knight_common():
    return _knight("shield_knight_common", False)


def shield_knight_rare():
    return _knight("shield_knight_rare", True)


RANK_UNITS = [rifleman_rare, machine_gunner_rare, sniper_rare, rocket_soldier_rare, medic_super_rare,
              mortar_common, mortar_rare, weakener_common, weakener_rare, drummer_common, drummer_rare,
              blinder_common, blinder_rare, shield_knight_common, shield_knight_rare]
