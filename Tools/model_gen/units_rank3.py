"""Rank ladder #3: Daredevil (stunt bomber, class explosive) + Cleric (class unique), Common / Rare / Super Rare / Legend.
Same soldier space as units.py: 1.3 m tall, front +Z, right hand = -X, feet at y=0.
Colors "G:#RRGGBB" = rank glow (emissive primitive); everything else is flat / matte.
New file only: nothing in the older generators is touched."""
import math
from glbkit import Model, shade
from units import SKIN, DARK, WHITE, EYE, legs, torso, head, arm, helmet
from units_rank import PUR, GPUR, BLU, GBLU, GOLD, cuff
from units_rank2 import IVORY, GOLD2, GWARM, NAVY, BLK, CH

LIME, FUSE_TIP, CREAM, CORD = "#C8E61E", "#E8832A", "#F6E7C8", "#4A4033"
RED, ORANGE = "#CC3330", "#FF8C1A"
ROSE, WOOD, STEEL, STEEL2, STEEL_D = "#D9588C", "#8A6A3C", "#9AA3AE", "#B9C0CA", "#6E7787"
GWARM_D = "G:#FFF3DC"


# ------------------------------------------------------------------ shared helpers
def bomb(m, c, r, col=CH, seg=8, rings=3):
    m.ball(c, r, col, seg=seg, rings=rings)


def fuse(m, c, r, tip=FUSE_TIP, h=0.07, tw=0.05):
    """Fuse cord + tip on top of a bomb centred at c with radius r."""
    x, y, z = c
    m.box((x, y + r + h / 2 - 0.012, z), (0.028, h, 0.028), CORD)
    m.box((x, y + r + h + 0.008, z), (tw, 0.04, tw), tip)


def arms2(m, col, right=(-0.2, 0.57, 0.2), left=(0.27, 0.46, 0.06), sh=0.23, w=0.10, trim=None):
    a1, a2 = (-sh, 0.70, 0.0), (sh, 0.70, 0.0)
    arm(m, -1, a1, right, col, w=w)
    arm(m, 1, a2, left, col, w=w)
    if trim:
        cuff(m, a1, right, trim, w=w + 0.015)
        cuff(m, a2, left, trim, w=w + 0.015)


def grin(m, y=0.855, z=0.243, w=0.22):
    m.box((0, y, z), (w, 0.07, 0.015), "#4A1F1F")
    m.box((0, y + 0.02, z + 0.006), (w - 0.04, 0.022, 0.012), WHITE)


def star(m, c, s, col, depth=0.02):
    """Flat 4-point star (two crossed bars + a turned square) on the +Z face."""
    x, y, z = c
    m.box((x, y, z), (s, s * 0.34, depth), col)
    m.box((x, y, z), (s * 0.34, s, depth), col)
    m.box((x, y, z), (s * 0.62, s * 0.62, depth), col, rot=(0, 0, 45))


def goggles(m, y=1.12, lens=CREAM, glow=False, strap=BLK):
    m.box((0, y - 0.015, 0), (0.60, 0.045, 0.55), strap)
    for sx in (-1, 1):
        m.box((sx * 0.12, y, 0.268), (0.17, 0.125, 0.03), "#2A2C33")
        m.box((sx * 0.12, y, 0.288), (0.13, 0.09, 0.02), lens)


# ================================================================================= DAREDEVIL
def daredevil_common():
    m = Model("daredevil_common")
    legs(m, LIME, BLK, w=0.82)
    torso(m, LIME, w=0.95, belt=BLK)
    m.box((0, 0.57, 0.137), (0.36, 0.07, 0.02), BLK)  # the one chest stripe
    m.box((0, 0.55, -0.145), (0.36, 0.05, 0.03), BLK)  # back strap
    bomb(m, (0, 0.55, -0.29), 0.17)
    fuse(m, (0, 0.55, -0.29), 0.17)
    head(m, grin=True)
    grin(m)
    helmet(m, BLK, y=1.2, w=0.58, d=0.54, h=0.22, brim=False)
    goggles(m)
    arms2(m, LIME)
    bomb(m, (-0.2, 0.6, 0.31), 0.105)
    fuse(m, (-0.2, 0.6, 0.31), 0.105)
    m.set_muzzle((-0.2, 0.6, 0.43))
    m.fit(height=1.3)
    return m


def daredevil_rare():
    m = Model("daredevil_rare")
    legs(m, LIME, BLK, w=0.98)
    for sx in (-1, 1):  # knee pads
        m.box((sx * 0.093, 0.2, 0.075), (0.145, 0.105, 0.05), BLK)
        m.box((sx * 0.093, 0.258, 0.078), (0.145, 0.02, 0.054), PUR)
    torso(m, LIME, w=1.1, belt=BLK)
    m.box((0, 0.55, 0.15), (0.38, 0.30, 0.05), BLK, bevel=0.02)  # chest pad with hazard stripes
    for k in (-1, 0, 1):
        m.box((k * 0.1, 0.55, 0.178), (0.045, 0.21, 0.012), LIME, rot=(0, 0, 30))
    m.box((0, 0.7, 0.155), (0.38, 0.025, 0.056), PUR)
    m.box((0, 0.4, 0.155), (0.38, 0.025, 0.056), PUR)
    for sx in (-1, 1):  # shoulder pads
        m.box((sx * 0.28, 0.76, 0), (0.15, 0.09, 0.24), BLK)
        m.box((sx * 0.28, 0.808, 0), (0.15, 0.02, 0.24), PUR)
    for x in (-0.12, 0.0, 0.12):  # waist belt of three bombs
        bomb(m, (x, 0.35, 0.185), 0.065, seg=6, rings=2)
    for x in (-0.12, 0.12):
        m.box((x, 0.35 + 0.065 + 0.03, 0.185), (0.032, 0.05, 0.032), GPUR)
    bomb(m, (0, 0.55, -0.30), 0.19)
    fuse(m, (0, 0.55, -0.30), 0.19)
    m.box((0, 0.55, -0.145), (0.40, 0.05, 0.03), BLK)
    head(m, grin=True)
    grin(m)
    helmet(m, BLK, y=1.2, w=0.6, d=0.56, h=0.22, brim=False)
    m.box((0, 1.335, 0.0), (0.05, 0.02, 0.42), PUR)
    m.box((0, 1.325, 0.22), (0.46, 0.03, 0.2), "#3A4050", rot=(-28, 0, 0))  # flipped-up visor
    m.box((0, 1.1, 0.0), (0.62, 0.03, 0.57), PUR)
    arm_r = ((-0.25, 0.70, 0.0), (-0.2, 0.57, 0.2))
    arms2(m, LIME, sh=0.25, trim=PUR)
    for a, b in (arm_r, ((0.25, 0.70, 0.0), (0.27, 0.46, 0.06))):  # elbow pads
        m.box(tuple((a[i] + b[i]) / 2 for i in range(3)), (0.13, 0.11, 0.13), BLK)
    for dx, dy in ((-0.042, -0.02), (0.042, -0.02), (0.0, 0.042)):  # dynamite bundle
        m.cyl((-0.2 + dx, 0.6 + dy, 0.34), 0.042, 0.34, RED, sides=6, rot=(90, 0, 0))
    m.box((-0.2, 0.6, 0.31), (0.14, 0.14, 0.045), BLK)
    m.box((-0.2, 0.6, 0.45), (0.14, 0.14, 0.03), BLK)
    m.box((-0.2, 0.655, 0.53), (0.028, 0.028, 0.06), CORD)
    m.set_muzzle((-0.2, 0.6, 0.54))
    m.fit(height=1.3)
    return m


def daredevil_super_rare():
    m = Model("daredevil_super_rare")
    legs(m, LIME, BLK, w=0.98)
    for sx in (-1, 1):  # rocket-boot boosters on the calves
        m.cyl((sx * 0.093, 0.2, -0.045), 0.062, 0.2, BLK, sides=8)
        m.box((sx * 0.093, 0.3, -0.045), (0.13, 0.02, 0.13), BLU)
        m.box((sx * 0.093, 0.12, -0.115), (0.09, 0.08, 0.035), GBLU)  # nozzle at the heel
        m.box((sx * 0.093, 0.21, 0.078), (0.15, 0.07, 0.04), BLK, bevel=0.012)
    torso(m, LIME, w=1.1, belt=BLK)
    m.box((0, 0.55, 0.15), (0.40, 0.32, 0.05), BLK, bevel=0.02)
    m.box((0, 0.715, 0.155), (0.40, 0.03, 0.056), BLU)
    for k in (-1, 0, 1):
        m.box((k * 0.11, 0.55, 0.178), (0.045, 0.22, 0.012), LIME, rot=(0, 0, 30))
    for i in range(4):  # bandolier of four bombs, glowing blue fuse tips
        t = i / 3
        x, y = 0.15 - 0.3 * t, 0.72 - 0.34 * t
        bomb(m, (x, y, 0.205), 0.062, seg=6, rings=2)
        m.box((x, y + 0.085, 0.205), (0.032, 0.04, 0.032), GBLU)
    m.limb((0.2, 0.74, 0.15), (-0.2, 0.38, 0.15), 0.035, BLK, d=0.04)
    for sx in (-1, 1):  # shoulder bomb pods
        m.box((sx * 0.3, 0.78, 0.0), (0.16, 0.12, 0.24), BLK, bevel=0.025)
        m.box((sx * 0.3, 0.845, 0.0), (0.1, 0.03, 0.1), BLU)
    bomb(m, (0, 0.55, -0.31), 0.19)
    m.cyl((0, 0.55, -0.31), 0.215, 0.03, GBLU, sides=10, rot=(90, 0, 0))  # glowing ring
    fuse(m, (0, 0.55, -0.31), 0.19, tip=BLU)
    m.box((0, 0.55, -0.145), (0.40, 0.05, 0.03), BLK)
    # scarf: 3 stacked wedge blocks streaming backwards
    for i, (c, col) in enumerate((((0, 0.84, -0.2), LIME), ((0, 0.8, -0.35), BLU), ((0, 0.74, -0.5), LIME))):
        m.box(c, (0.2, 0.09, 0.17), col, rot=(18 + 8 * i, 0, 0))
    head(m, grin=True)
    m.box((0, 1.03, 0.0), (0.58, 0.40, 0.52), BLK, bevel=0.05)  # full-face helmet
    m.box((0, 1.2, 0.0), (0.56, 0.1, 0.5), BLK, bevel=0.03)
    m.box((0, 1.005, 0.262), (0.42, 0.11, 0.03), GBLU)  # glowing visor
    m.box((0, 0.93, 0.262), (0.42, 0.045, 0.03), BLU)
    m.box((0, 1.31, -0.02), (0.05, 0.16, 0.34), BLU)  # fin
    m.box((0, 1.1, 0.0), (0.6, 0.03, 0.55), BLU)
    arms2(m, LIME, sh=0.26, trim=BLU)
    bomb(m, (-0.2, 0.6, 0.31), 0.105)
    fuse(m, (-0.2, 0.6, 0.31), 0.105, tip=GBLU)
    m.set_muzzle((-0.2, 0.6, 0.43))
    m.fit(height=1.3)
    return m


def daredevil_legend():
    m = Model("daredevil_legend")
    legs(m, LIME, GOLD2, w=1.0)
    for sx in (-1, 1):
        m.box((sx * 0.093, 0.2, 0.075), (0.15, 0.1, 0.05), BLK, bevel=0.015)
        m.box((sx * 0.093, 0.258, 0.078), (0.15, 0.022, 0.054), GOLD)
        m.cyl((sx * 0.093, 0.18, -0.05), 0.06, 0.16, GOLD2, sides=6)
        m.box((sx * 0.093, 0.1, -0.12), (0.08, 0.07, 0.03), GWARM)
    torso(m, LIME, w=1.15, belt=GOLD2)
    m.box((0, 0.55, 0.15), (0.40, 0.33, 0.05), IVORY, bevel=0.02)  # ivory chest plate
    m.box((0, 0.72, 0.155), (0.40, 0.035, 0.058), GOLD)
    m.box((0, 0.385, 0.155), (0.40, 0.035, 0.058), GOLD)
    for sx in (-1, 1):
        m.box((sx * 0.19, 0.55, 0.178), (0.03, 0.3, 0.012), GOLD)
    star(m, (0, 0.55, 0.18), 0.2, GOLD2, 0.012)
    star(m, (0, 0.55, 0.192), 0.15, GWARM, 0.012)  # glowing star gem
    for sx in (-1, 1):  # round gold shoulder cones
        m.cyl((sx * 0.3, 0.77, 0), 0.14, 0.09, GOLD2, sides=8)
        m.pyramid((sx * 0.3, 0.815, 0), (0.18, 0.18), 0.13, GOLD, sides=8)
    # HUGE mega-bomb with gold bands, star emblem, warm core, flanked by 2 thruster pods
    bomb(m, (0, 0.56, -0.36), 0.25, seg=10, rings=4)
    m.cyl((0, 0.56, -0.36), 0.268, 0.04, GOLD2, sides=10, rot=(90, 0, 0))
    m.cyl((0, 0.56, -0.36), 0.255, 0.035, GOLD2, sides=10, rot=(0, 0, 0), scale=(1, 1))
    star(m, (0, 0.56, -0.612), 0.2, GOLD2, 0.012)
    m.box((0, 0.56, -0.62), (0.08, 0.08, 0.015), GWARM)
    fuse(m, (0, 0.56, -0.36), 0.25, tip=GWARM_D, h=0.08, tw=0.06)
    m.box((0, 0.55, -0.145), (0.42, 0.05, 0.03), GOLD)
    for sx in (-1, 1):
        m.cyl((sx * 0.36, 0.5, -0.24), 0.07, 0.24, GOLD2, sides=6)
        m.box((sx * 0.36, 0.37, -0.24), (0.09, 0.03, 0.09), GWARM)
    # long flame scarf: 4 stacked wedge blocks
    for i, (c, col) in enumerate((((0, 0.86, -0.2), ORANGE), ((0, 0.82, -0.34), GOLD2), ((0, 0.77, -0.47), IVORY),
                                  ((0, 0.7, -0.6), ORANGE))):
        m.box(c, (0.22, 0.09, 0.17), col, rot=(16 + 8 * i, 0, 0))
    head(m, grin=True)
    grin(m)
    m.box((0, 1.2, 0.0), (0.6, 0.2, 0.56), GOLD2, bevel=0.04)  # golden crash helmet
    m.box((0, 1.1, 0.0), (0.62, 0.035, 0.58), GOLD)
    for sx in (-1, 1):  # star goggle lenses with a warm glow
        m.box((sx * 0.13, 1.1, 0.29), (0.17, 0.13, 0.03), "#2A2C33")
        star(m, (sx * 0.13, 1.1, 0.3), 0.15, GWARM, 0.02)
    for i, (w, h, y, col) in enumerate(((0.36, 0.11, 1.34, GOLD2), (0.27, 0.11, 1.44, ORANGE), (0.17, 0.11, 1.54, GOLD2))):
        m.box((0, y, -0.03 - 0.03 * i), (0.15 - 0.02 * i, h, w), col)  # flame crest, 3 stacked wedge blocks
    arms2(m, LIME, sh=0.27, trim=GOLD2)
    bomb(m, (-0.2, 0.6, 0.32), 0.125, seg=8, rings=3)
    m.cyl((-0.2, 0.6, 0.32), 0.135, 0.03, GOLD2, sides=8, rot=(90, 0, 0))
    fuse(m, (-0.2, 0.6, 0.32), 0.125, tip=GWARM_D, tw=0.055)
    m.set_muzzle((-0.2, 0.6, 0.46))
    m.fit(height=1.3)
    return m


# ===================================================================================== CLERIC
def _robe_base(m, col, w, hem_trim=None, tall=0.32):
    legs(m, CREAM, WOOD, w=w)
    m.frustum((0, 0.12, 0), (0.43 * w, 0.31), (0.38 * w, 0.27), tall, col)  # skirt to the knees
    torso(m, col, w=w, belt=None)
    if hem_trim:
        m.box((0, 0.125, 0), (0.435 * w, 0.03, 0.315), hem_trim)


def cleric_common():
    m = Model("cleric_common")
    _robe_base(m, ROSE, 1.18)
    m.box((0, 0.36, 0), (0.46, 0.05, 0.28), CREAM)  # rope belt
    m.box((0.1, 0.30, 0.145), (0.03, 0.12, 0.02), CREAM)
    m.box((0, 0.58, 0.137), (0.12, 0.12, 0.015), CREAM, rot=(0, 0, 45))  # sun badge (plain, flat)
    head(m)
    m.box((0, 1.2, 0), (0.60, 0.2, 0.54), CREAM, bevel=0.05)  # cream hood
    for sx in (-1, 1):
        m.box((sx * 0.285, 0.97, -0.02), (0.06, 0.4, 0.5), shade(CREAM, 0.85))
    m.box((0, 0.97, -0.25), (0.58, 0.4, 0.06), shade(CREAM, 0.85))
    arms2(m, ROSE, sh=0.26, w=0.115)
    m.box((-0.2, 0.6, 0.3), (0.05, 0.05, 0.44), WOOD)  # simple wooden mace
    m.ball((-0.2, 0.6, 0.6), 0.095, WOOD, seg=8, rings=3)
    m.set_muzzle((-0.2, 0.6, 0.7))
    m.fit(height=1.3)
    return m


def cleric_rare():
    m = Model("cleric_rare")
    _robe_base(m, ROSE, 1.25, hem_trim=PUR)
    m.box((0, 0.3, 0.145), (0.2, 0.42, 0.03), CREAM)  # tabard
    m.box((0, 0.54, 0.155), (0.38, 0.30, 0.05), STEEL, bevel=0.02)  # steel chest plate
    m.box((0, 0.395, 0.158), (0.38, 0.025, 0.056), PUR)
    m.box((0, 0.695, 0.158), (0.38, 0.025, 0.056), PUR)
    m.cyl((0, 0.55, 0.18), 0.085, 0.02, CREAM, sides=8, rot=(90, 0, 0))  # sun medallion
    m.box((0, 0.55, 0.192), (0.05, 0.05, 0.015), GPUR)
    for sx in (-1, 1):
        m.box((sx * 0.3, 0.76, 0), (0.17, 0.10, 0.26), STEEL, bevel=0.025)
        m.box((sx * 0.3, 0.812, 0), (0.17, 0.022, 0.26), PUR)
        m.box((sx * 0.1, 0.17, 0.12), (0.15, 0.09, 0.05), STEEL, bevel=0.015)  # knee plates
    head(m)
    m.box((0, 1.18, 0), (0.58, 0.2, 0.52), STEEL, bevel=0.05)  # rounded steel cap
    m.box((0, 1.085, 0), (0.6, 0.035, 0.54), PUR)
    for sx in (-1, 1):  # cream coif around the face
        m.box((sx * 0.265, 0.95, 0.0), (0.07, 0.36, 0.46), CREAM)
    m.box((0, 0.76, 0.0), (0.46, 0.05, 0.3), CREAM)
    arms2(m, ROSE, sh=0.28, w=0.12, trim=PUR)
    m.box((-0.2, 0.6, 0.3), (0.055, 0.055, 0.42), STEEL_D)  # flanged steel mace
    m.ball((-0.2, 0.6, 0.62), 0.085, STEEL2, seg=8, rings=3)
    for rz in (0, 45, 90, 135):
        m.box((-0.2, 0.6, 0.62), (0.2, 0.04, 0.05), STEEL, rot=(0, 0, rz))
    m.cyl((-0.2, 0.6, 0.62), 0.135, 0.03, GPUR, sides=10, rot=(90, 0, 0))  # glowing purple ring
    m.set_muzzle((-0.2, 0.6, 0.72))
    m.fit(height=1.3)
    return m


def cleric_super_rare():
    m = Model("cleric_super_rare")
    _robe_base(m, ROSE, 1.3, hem_trim=BLU, tall=0.34)
    m.box((0, 0.4, 0.152), (0.18, 0.56, 0.03), CREAM)  # long stole down the front
    m.box((0, 0.135, 0.158), (0.2, 0.03, 0.036), BLU)
    for sx in (-1, 1):
        m.box((sx * 0.1, 0.4, 0.152), (0.03, 0.56, 0.032), BLU)
    m.box((0, 0.58, 0.178), (0.2, 0.06, 0.02), GBLU)  # glowing sun-cross gem
    m.box((0, 0.58, 0.178), (0.06, 0.2, 0.02), GBLU)
    m.box((0, 0.58, 0.172), (0.12, 0.12, 0.012), BLU, rot=(0, 0, 45))
    m.box((0, 0.46, -0.19), (0.34, 0.66, 0.05), ROSE)  # short cape
    m.box((0, 0.13, -0.19), (0.36, 0.03, 0.06), BLU)
    for k in range(8):  # sunburst collar: 8 cream wedges
        with m.group(rot=(0, k * 45, 0)):
            m.box((0, 0.835, 0.22), (0.11, 0.045, 0.15), CREAM, rot=(28, 0, 0))
    for sx in (-1, 1):
        m.cyl((sx * 0.31, 0.77, 0), 0.13, 0.09, STEEL, sides=8)
        m.cyl((sx * 0.31, 0.82, 0), 0.135, 0.02, BLU, sides=8)
    head(m)
    m.box((0, 1.18, 0), (0.58, 0.2, 0.52), STEEL2, bevel=0.05)  # open steel helmet
    for sx in (-1, 1):
        m.box((sx * 0.275, 0.99, 0.0), (0.05, 0.3, 0.44), STEEL2)
    m.box((0, 1.085, 0), (0.6, 0.03, 0.54), BLU)
    m.box((0, 1.33, -0.02), (0.05, 0.17, 0.34), BLU)  # crest fin
    m.box((0, 1.125, 0.268), (0.1, 0.09, 0.03), GBLU)  # circlet gem
    arms2(m, ROSE, sh=0.3, w=0.12, trim=BLU)
    m.box((-0.2, 0.6, 0.3), (0.06, 0.06, 0.42), STEEL)  # chunky steel mace, glowing sun head
    m.ball((-0.2, 0.6, 0.63), 0.1, GBLU, seg=8, rings=3)
    for k in range(8):
        with m.group(rot=(0, 0, k * 45), pivot=(-0.2, 0.6, 0.63)):
            m.box((-0.2, 0.6 + 0.145, 0.63), (0.06, 0.08, 0.06), GBLU)
    m.set_muzzle((-0.2, 0.6, 0.78))
    m.fit(height=1.3)
    return m


def cleric_legend():
    m = Model("cleric_legend")
    _robe_base(m, ROSE, 1.32, hem_trim=GOLD2, tall=0.36)
    m.box((0, 0.42, 0.158), (0.2, 0.6, 0.03), IVORY)  # long ornate stole
    for sx in (-1, 1):
        m.box((sx * 0.105, 0.42, 0.16), (0.025, 0.6, 0.034), GOLD2)
    m.box((0, 0.14, 0.164), (0.22, 0.04, 0.038), GOLD2)
    m.box((0, 0.16, 0.0), (0.46, 0.04, 0.3), GOLD)  # gold hem band
    m.box((0, 0.6, 0.18), (0.24, 0.07, 0.02), GWARM)  # big glowing sun-cross gem
    m.box((0, 0.6, 0.18), (0.07, 0.24, 0.02), GWARM)
    m.box((0, 0.6, 0.172), (0.15, 0.15, 0.012), GOLD2, rot=(0, 0, 45))
    m.box((0, 0.46, -0.2), (0.5, 0.68, 0.05), ROSE)  # wide cape, thick gold border
    m.box((0, 0.12, -0.2), (0.52, 0.045, 0.062), GOLD2)
    for sx in (-1, 1):
        m.box((sx * 0.255, 0.46, -0.2), (0.04, 0.68, 0.062), GOLD2)
    m.box((0, 0.46, -0.232), (0.16, 0.16, 0.02), IVORY, rot=(0, 0, 45))
    m.box((0, 0.775, 0), (0.46, 0.05, 0.32), GOLD2)  # gold collar
    for sx in (-1, 1):
        m.cyl((sx * 0.32, 0.77, 0), 0.15, 0.1, GOLD2, sides=8)
        m.cyl((sx * 0.32, 0.83, 0), 0.1, 0.03, IVORY, sides=8)
    head(m, grin=True)
    m.frustum((0, 1.12, 0), (0.54, 0.5), (0.4, 0.4), 0.3, ROSE)  # bishop mitre
    m.box((0, 1.13, 0), (0.58, 0.05, 0.52), GOLD2)
    m.box((0, 1.3, 0.2), (0.07, 0.3, 0.05), GOLD2)  # chunky gold cross fin on the front
    m.box((0, 1.34, 0.2), (0.2, 0.07, 0.05), GOLD2)
    m.box((0, 1.34, 0.232), (0.06, 0.06, 0.02), GWARM)
    arms2(m, ROSE, sh=0.3, w=0.125, trim=GOLD2)
    m.box((-0.2, 0.6, 0.3), (0.06, 0.06, 0.46), GOLD2)  # golden sun-mace
    m.ball((-0.2, 0.6, 0.66), 0.115, GWARM, seg=8, rings=3)
    for k in range(8):
        with m.group(rot=(0, 0, k * 45), pivot=(-0.2, 0.6, 0.66)):
            m.box((-0.2, 0.6 + 0.165, 0.66), (0.065, 0.09, 0.065), GOLD2)
    m.set_muzzle((-0.2, 0.6, 0.83))
    m.fit(height=1.3)
    return m


RANK3_UNITS = [
    daredevil_common, daredevil_rare, daredevil_super_rare, daredevil_legend,
    cleric_common, cleric_rare, cleric_super_rare, cleric_legend,
]
