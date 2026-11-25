"""Common enemies for chapters 4-16 (families B-F x 13 roles). Palette driven: every color is one of the
6 family slots P[1..6] (+ pure black/white), so a recolor is the same geometry built with another palette.
Character space: nominal ~1.25 m, front +Z, right hand = -X, then fit(height)."""
from glbkit import Model
from units import arm

W, K = "#FFFFFF", "#000000"

PAL = {
    "B": {4: ["#EFE6CF", "#6B3FA0", "#36204F", "#7C7F88", "#C9A24A", "#7CFF4A"],
          5: ["#F0DFB0", "#1FA7A0", "#0E5A5C", "#B97A34", "#F2BF1A", "#FFC02E"],
          6: ["#D5E3B8", "#5E8A3C", "#2F4A25", "#6B4A2B", "#BFA94A", "#5CFFD1"]},
    "C": {7: ["#B8703E", "#7A8B5C", "#3E4638", "#8A8F99", "#F2C21A", "#FF5A1F"],
          8: ["#2B2F55", "#7B3FD0", "#14162E", "#AAB4D8", "#FF3DAE", "#3DF2FF"],
          9: ["#E8EDF5", "#3573E6", "#1F2A47", "#9AA6BA", "#F28C1F", "#7DFFB0"]},
    "D": {10: ["#7FBF3F", "#D9A81E", "#2E4A1E", "#E6E0C2", "#FF7A1A", "#FFF04A"],
          11: ["#9A5FD0", "#B6E03A", "#3A1E55", "#D8D2E8", "#FF4FA0", "#A6FF3A"],
          12: ["#3FBFC9", "#E070C8", "#1B3D57", "#EAF6FF", "#FFE066", "#B8FFF5"]},
    "E": {13: ["#E8B98A", "#2F5FA8", "#1B2D55", "#6B6F7A", "#F2BF1A", "#FFE63B"],
          14: ["#CFE8E4", "#2FA89A", "#14504F", "#9FB3B0", "#E8FFF5", "#8CFFE0"],
          15: ["#E08A5C", "#1F6FA8", "#0F3A5C", "#C9B27A", "#FF7A5C", "#FFF04A"]},
    "F": {16: ["#4A2D8A", "#1A1230", "#0E0A1A", "#B9B2D6", "#F2BF1A", "#FF3AE0"]},
}
FAM_OF_ROUND = {r: f for f, d in PAL.items() for r in d}

# slots: torso, arm, hand, leg, boot, under (belt / dark)
CFG = {
    "B": dict(torso=2, arm=1, hand=1, leg=1, boot=1, under=3, armw=0.07, legw=0.10),
    "C": dict(torso=1, arm=1, hand=4, leg=3, boot=4, under=3, armw=0.10, legw=0.13),
    "D": dict(torso=1, arm=1, hand=4, leg=1, boot=3, under=3, armw=0.09, legw=0.12),
    "E": dict(torso=2, arm=2, hand=1, leg=3, boot=4, under=3, armw=0.10, legw=0.13),
    "F": dict(torso=3, arm=1, hand=1, leg=3, boot=2, under=2, armw=0.09, legw=0.12),
}

ROLES = ["grunt", "scout", "brute", "gunner", "warlord", "kamikaze", "sniper_enemy", "medic_enemy",
         "mortar", "blinder", "weakener", "breacher", "shotgunner"]
HEIGHT = {"grunt": 1.5, "scout": 1.2, "brute": 2.2, "gunner": 1.6, "warlord": 3.6, "kamikaze": 1.3,
          "sniper_enemy": 1.7, "medic_enemy": 1.5, "mortar": 1.7, "blinder": 1.6, "weakener": 1.6,
          "breacher": 2.0, "shotgunner": 1.5}
MUZZLE_ROLES = {"gunner", "sniper_enemy", "mortar", "breacher", "shotgunner"}


# ------------------------------------------------------------------ helpers
def tube(m, c, r, h, col, rx=20, r_top=None, sides=8):
    """Cylinder tilted rx deg from vertical toward +Z. Returns the mouth point."""
    import math
    m.cyl(c, r, h, col, sides=sides, rot=(rx, 0, 0), r_top=r_top)
    a = math.radians(rx)
    return (c[0], c[1] + math.cos(a) * h / 2, c[2] + math.sin(a) * h / 2)


def body(m, P, F, w=1.0, d=0.26, y0=0.30, y1=0.76, leg_h=0.30, spread=0.095, bev=0.04, belt=True):
    c = CFG[F]
    for sx in (-1, 1):
        m.box((sx * spread * w, 0.05, 0.03), (0.15 * w, 0.10, 0.22), P[c["boot"]])
        m.box((sx * spread * w, 0.10 + (leg_h - 0.10) / 2, 0.0), (c["legw"] * w, leg_h - 0.10, 0.15), P[c["leg"]])
    h = y1 - y0
    m.box((0, y0 + h / 2, 0), (0.38 * w, h, d), P[c["torso"]], bevel=bev)
    if belt:
        m.box((0, y0 + 0.04, 0), (0.40 * w, 0.06, d + 0.02), P[c["under"]] if F != "F" else P[2])
    f, mid = d / 2 + 0.012, (y0 + y1) / 2
    if F == "B":
        for i, yy in enumerate((0.68, 0.60, 0.52)):
            m.box((0, yy * (h / 0.46) * 0 + yy - 0.0, f), (0.26 * w, 0.03, 0.02), P[1])
        m.box((0, 0.6, f), (0.04, 0.2, 0.02), P[1])
        for sx in (-1, 1):
            m.box((sx * 0.13 * w, 0.24, 0.08), (0.07, 0.12, 0.04), P[3])
    elif F == "C":
        m.box((0, mid, f), (0.28 * w, h * 0.6, 0.03), P[2])
        for sx in (-1, 1):
            m.box((sx * 0.11 * w, mid + 0.07, f + 0.015), (0.04, 0.04, 0.02), P[5])
    elif F == "D":
        m.box((0, mid, f), (0.28 * w, h * 0.72, 0.03), P[3])
        for sx in (-1, 1):
            m.box((sx * 0.1 * w, mid + 0.08, -d / 2 - 0.05), (0.12, 0.1, 0.1), P[2])
    elif F == "E":
        for sx in (-1, 1):
            m.box((sx * 0.14 * w, mid, f), (0.1, h * 0.9, 0.03), P[3])
            m.box((sx * 0.14 * w, mid + 0.06, f + 0.015), (0.04, 0.04, 0.02), P[5])
        for yy in (0.4, 0.5, 0.6):
            m.box((0, yy, f - 0.005), (0.18 * w, 0.03, 0.02), P[3])
    elif F == "F":
        m.box((0, mid, f), (0.26 * w, h * 0.55, 0.03), P[2])
        m.box((-0.1 * w, mid - 0.1, f + 0.01), (0.1, 0.1, 0.02), P[2])


def back(m, P, F, w=1.0, d=0.26):
    """Family back piece (cloth / pack / shell / tail)."""
    z = -d / 2
    if F == "B":
        m.box((0, 0.55, z - 0.03), (0.3 * w, 0.32, 0.06), P[3])
    elif F == "C":
        m.box((0, 0.58, z - 0.04), (0.26 * w, 0.28, 0.08), P[2], bevel=0.02)
        m.cyl((0.1, 0.8, z - 0.05), 0.03, 0.12, P[4])
    elif F == "D":
        m.box((0, 0.58, z - 0.05), (0.34 * w, 0.32, 0.1), P[2], bevel=0.04)
        for sx in (-1, 1):
            m.box((sx * 0.09, 0.62, z - 0.105), (0.06, 0.06, 0.02), P[5])
    elif F == "E":
        m.box((0, 0.55, z - 0.03), (0.3 * w, 0.3, 0.06), P[3])
    elif F == "F":
        m.pyramid((0, 0.36, z), (0.12, 0.12), 0.34, P[3], rot=(-90, 0, 0))
        m.pyramid((0, 0.36, z - 0.32), (0.1, 0.1), 0.1, P[4], rot=(-90, 0, 0))


# ------------------------------------------------------------------ heads
def head(m, P, F, y=0.98, hw=0.56, hh=0.46, hd=0.50, mood="angry"):
    ez = hd / 2 + 0.005
    ex = hw * 0.23
    if F == "B":
        m.box((0, y, 0), (hw, hh, hd), P[1], bevel=0.05)
        eyes = [0] if mood == "cyclops" else [-1, 1]
        for sx in eyes:
            m.box((sx * ex, y + 0.04, ez), (0.16, 0.15, 0.03), P[3])
            m.box((sx * ex, y + 0.035, ez + 0.012), (0.075, 0.075, 0.03), P[6])
            if mood == "angry":
                m.box((sx * ex, y + 0.15, ez), (0.17, 0.04, 0.03), P[3], rot=(0, 0, -sx * 22))
        m.box((0, y - 0.05, ez), (0.06, 0.07, 0.03), P[3])
        m.box((0, y - 0.15, ez), (0.34, 0.08, 0.03), P[3])
        for i in range(4):
            m.box((-0.12 + i * 0.08, y - 0.15, ez + 0.01), (0.04, 0.08, 0.03), P[1])
    elif F == "C":
        m.box((0, y, 0), (hw, hh, hd), P[3], bevel=0.05)
        m.box((0, y, ez), (hw * 0.84, hh * 0.78, 0.03), K)
        if mood == "cyclops":
            m.box((0, y + 0.02, ez + 0.012), (0.3, 0.14, 0.03), P[6])
            m.box((0, y + 0.02, ez + 0.03), (0.12, 0.08, 0.02), W)
        elif mood == "lamp":
            m.box((0, y, ez + 0.012), (hw * 0.74, hh * 0.62, 0.04), P[6])
        else:
            for sx in (-1, 1):
                if mood == "panic":
                    m.box((sx * ex, y + 0.06, ez + 0.012), (0.12, 0.12, 0.03), P[6])
                else:
                    m.box((sx * ex, y + 0.06, ez + 0.012), (0.15, 0.06, 0.03), P[6], rot=(0, 0, -sx * 14 if mood == "angry" else 0))
            for i in range(4):
                m.box((-0.12 + i * 0.08, y - 0.1 + (0.04 if i % 2 else 0), ez + 0.012), (0.09, 0.03, 0.03), P[6], rot=(0, 0, 35 if i % 2 else -35))
    elif F == "D":
        m.box((0, y, 0), (hw, hh, hd), P[1], bevel=0.05)
        eyes = [0] if mood == "cyclops" else [-1, 1]
        for sx in eyes:
            m.box((sx * ex, y + 0.05, ez), (0.17 if mood != "cyclops" else 0.24, 0.17, 0.03), P[6])
            m.box((sx * ex, y + 0.05, ez + 0.012), (0.06, 0.08, 0.03), P[3])
            if mood == "angry":
                m.box((sx * ex, y + 0.16, ez), (0.19, 0.04, 0.03), P[3], rot=(0, 0, -sx * 22))
        for sx in (-1, 1):
            m.box((sx * 0.1, y - 0.15, ez + 0.01), (0.06, 0.12, 0.04), P[4], rot=(0, 0, sx * 18))
        m.box((0, y - 0.14, ez), (0.12, 0.05, 0.03), P[3])
        for sx in (-1, 1):  # antennae
            m.limb((sx * 0.14, y + hh / 2 - 0.02, 0.0), (sx * 0.2, y + hh / 2 + 0.17, 0.08), 0.035, P[3])
            m.ball((sx * 0.2, y + hh / 2 + 0.19, 0.08), 0.04, P[5], seg=5, rings=2)
    elif F == "E":
        m.box((0, y, 0), (hw, hh, hd), P[1], bevel=0.05)
        eyes = [-1, 1]
        for sx in eyes:
            if mood == "spy" and sx == -1:
                m.box((sx * ex, y + 0.04, ez), (0.2, 0.2, 0.03), P[6])
                m.box((sx * ex, y + 0.04, ez + 0.02), (0.1, 0.1, 0.03), W)
                continue
            m.box((sx * ex, y + 0.04, ez), (0.11, 0.11, 0.03), W)
            m.box((sx * ex, y + 0.035, ez + 0.012), (0.06, 0.07, 0.03), P[3])
            if mood in ("angry", "panic"):
                m.box((sx * ex, y + 0.13, ez), (0.15, 0.04, 0.03), P[3], rot=(0, 0, -sx * (22 if mood == "angry" else -15)))
        if mood == "panic":
            m.box((0, y - 0.14, ez), (0.12, 0.12, 0.03), P[3])
        else:
            m.box((0, y - 0.14, ez), (0.26, 0.05, 0.03), P[3])
            for sx in (-1, 1):
                m.pyramid((sx * 0.07, y - 0.115, ez + 0.01), (0.05, 0.05), 0.06, W, rot=(180, 0, 0))
    elif F == "F":
        m.box((0, y, 0), (hw, hh, hd), P[1], bevel=0.05)
        eyes = [0] if mood == "cyclops" else [-1, 1]
        for sx in eyes:
            m.box((sx * ex, y + 0.05, ez), (0.2 if mood == "cyclops" else 0.16, 0.09 if mood != "cyclops" else 0.13, 0.03), P[6],
                  rot=(0, 0, -sx * 14 if mood == "angry" else 0))
        if mood == "panic":
            m.box((0, y - 0.14, ez), (0.14, 0.13, 0.03), P[3])
        else:
            m.box((0, y - 0.14, ez), (0.28, 0.05, 0.03), P[3])
            for sx in (-1, 1):
                m.pyramid((sx * 0.08, y - 0.115, ez + 0.01), (0.05, 0.05), 0.06, W, rot=(180, 0, 0))


def hat(m, P, kind, a, b, y=0.98, hw=0.56, hh=0.46, hd=0.50):
    top = y + hh / 2
    ca, cb = P[a], P[b]
    if kind == "cap":
        m.box((0, top - 0.02, 0), (hw + 0.03, 0.08, hd + 0.03), cb, bevel=0.02)
        m.frustum((0, top + 0.02, 0), (hw, hd), (hw * 0.72, hd * 0.72), 0.13, ca)
    elif kind in ("hood", "hoodtip"):
        m.box((0, top + 0.02, 0), (hw + 0.04, 0.2, hd + 0.04), ca, bevel=0.05)
        for sx in (-1, 1):
            m.box((sx * (hw / 2 + 0.015), y - 0.04, -0.02), (0.06, hh + 0.04, hd), cb)
        m.box((0, y - 0.04, -hd / 2 - 0.0), (hw + 0.04, hh + 0.04, 0.06), cb)
        if kind == "hoodtip":
            m.pyramid((0, top + 0.1, -0.1), (0.3, 0.3), 0.16, ca, rot=(-35, 0, 0))
    elif kind == "crown":
        m.box((0, top, 0), (hw + 0.02, 0.1, hd + 0.02), cb, bevel=0.02)
        for sx in (-1, 1):
            m.pyramid((sx * hw * 0.34, top + 0.04, 0), (0.16, 0.16), 0.26, ca, rot=(0, 0, -sx * 14))
    elif kind == "brim":
        m.box((0, top - 0.01, 0), (hw + 0.42, 0.04, hd + 0.42), ca, bevel=0.01)
        m.frustum((0, top, 0), (hw * 0.95, hd * 0.95), (hw * 0.7, hd * 0.7), 0.17, ca)
        m.box((0, top + 0.03, 0), (hw * 0.97, 0.05, hd * 0.97), cb)
    elif kind == "tricorn":
        m.box((0, top - 0.01, 0), (hw + 0.36, 0.05, hd + 0.3), ca, bevel=0.01)
        for sx in (-1, 1):
            m.box((sx * (hw + 0.36) / 2, top + 0.04, 0), (0.1, 0.05, hd + 0.3), ca, rot=(0, 0, -sx * 28))
        m.box((0, top + 0.05, hd / 2 + 0.12), (hw + 0.1, 0.05, 0.1), ca, rot=(-28, 0, 0))
        m.frustum((0, top, 0), (hw * 0.95, hd * 0.95), (hw * 0.75, hd * 0.75), 0.12, ca)
        m.box((0, top + 0.05, 0), (hw * 0.97, 0.04, hd * 0.97), cb)
    elif kind == "bandana":
        m.box((0, y + hh * 0.3, 0), (hw + 0.03, 0.1, hd + 0.03), ca)
        m.box((0, top - 0.03, 0), (hw + 0.02, 0.07, hd + 0.02), ca)
        for sx in (-1, 1):
            m.box((sx * 0.07, y + hh * 0.28 - 0.08, -hd / 2 - 0.05), (0.07, 0.22, 0.04), ca, rot=(0, 0, -sx * 14))
    elif kind == "horns":
        for sx in (-1, 1):
            m.pyramid((sx * hw * 0.38, top - 0.03, 0), (0.15, 0.15), 0.25, ca, rot=(0, 0, -sx * 28))
    elif kind == "antlers":
        for sx in (-1, 1):
            m.limb((sx * 0.14, top, 0), (sx * 0.3, top + 0.22, 0), 0.08, ca)
            m.pyramid((sx * 0.3, top + 0.2, 0), (0.1, 0.1), 0.16, ca, rot=(0, 0, -sx * 20))
    elif kind == "crest":
        m.box((0, top + 0.04, -0.02), (0.1, 0.1, hd * 0.7), ca)
    elif kind == "mushroom":
        m.frustum((0, top - 0.03, 0), (hw + 0.4, hd + 0.4), (hw * 0.6, hd * 0.6), 0.2, ca)
        for sx, sz in ((-1, 0.1), (1, -0.1), (0, 0.22)):
            m.box((sx * 0.18, top + 0.18, sz), (0.09, 0.03, 0.09), cb)
    elif kind == "skullmask":
        m.box((0, y + 0.04, 0.02), (hw + 0.08, hh * 0.8, hd + 0.06), ca, bevel=0.05)
        for sx in (-1, 1):
            m.pyramid((sx * hw * 0.42, top + 0.0, 0), (0.15, 0.15), 0.3, ca, rot=(0, 0, -sx * 30))
            m.limb((sx * 0.12, top + 0.02, -0.1), (sx * 0.2, top + 0.3, -0.12), 0.06, cb)
    elif kind == "pot":
        m.frustum((0, top - 0.04, 0), (hw + 0.03, hd + 0.03), (hw * 0.78, hd * 0.78), 0.16, ca)
        m.box((0, top - 0.04, 0), (hw + 0.05, 0.06, hd + 0.05), cb)
    elif kind == "scarf":
        m.box((0, y - hh / 2 - 0.02, 0), (hw * 0.82, 0.1, hd * 0.82), ca)


HAT = {
    "B": {"scout": ("hoodtip", 2, 3), "gunner": ("cap", 4, 3), "warlord": ("crown", 5, 5), "sniper_enemy": ("hoodtip", 2, 3),
          "mortar": ("cap", 1, 4), "blinder": ("hood", 2, 3), "weakener": ("skullmask", 1, 5), "shotgunner": ("brim", 2, 3)},
    "C": {"scout": None, "warlord": ("crest", 5, 5), "sniper_enemy": None},
    "D": {"warlord": ("antlers", 4, 4), "weakener": ("mushroom", 2, 5)},
    "E": {"grunt": ("bandana", 5, 5), "scout": ("bandana", 5, 5), "gunner": ("tricorn", 3, 5), "warlord": ("tricorn", 3, 5),
          "kamikaze": ("bandana", 5, 5), "sniper_enemy": ("tricorn", 2, 5), "mortar": ("bandana", 5, 5),
          "blinder": ("hood", 2, 3), "weakener": ("bandana", 5, 5), "shotgunner": ("brim", 3, 5)},
    "F": {"grunt": ("horns", 4, 4), "scout": ("horns", 4, 4), "gunner": ("horns", 4, 4), "warlord": ("horns", 4, 4),
          "kamikaze": ("horns", 4, 4), "sniper_enemy": ("hood", 2, 3), "medic_enemy": ("horns", 4, 4), "mortar": ("horns", 4, 4),
          "blinder": ("hood", 2, 3), "weakener": ("hood", 2, 3), "shotgunner": ("horns", 4, 4)},
}


def hat_for(m, P, F, role, **kw):
    h = HAT[F].get(role)
    if h:
        hat(m, P, h[0], h[1], h[2], **kw)


def arms_fwd(m, P, F, z=0.42, y=0.60):
    c = CFG[F]
    for sx in (-1, 1):
        arm(m, sx, (sx * 0.24, 0.68, 0.0), (sx * 0.2, y, z), P[c["arm"]], hand=P[c["hand"]], w=c["armw"], hand_s=0.13)


def hold_pose(m, P, F, left=(0.285, 0.46, 0.06), right=(-0.2, 0.57, 0.22), w=None):
    c = CFG[F]
    w = w or c["armw"]
    arm(m, -1, (-0.24, 0.70, 0.0), right, P[c["arm"]], hand=P[c["hand"]], w=w, hand_s=0.11)
    arm(m, 1, (0.24, 0.70, 0.0), left, P[c["arm"]], hand=P[c["hand"]], w=w, hand_s=0.11)


def symbol(m, P, F, y, z, c):
    """Medic emblem on the chest (z>0) or back (z<0); thin, glow colour."""
    s = 1 if z > 0 else -1
    col = P[6]
    if F == "B":  # ribcage heart
        m.box((0, y, z), (0.12, 0.12, 0.02), col, rot=(0, 0, 45))
        m.box((-0.045, y + 0.06, z), (0.07, 0.07, 0.02), col, rot=(0, 0, 45))
        m.box((0.045, y + 0.06, z), (0.07, 0.07, 0.02), col, rot=(0, 0, 45))
    elif F == "C":  # gear
        m.box((0, y, z), (0.12, 0.12, 0.02), col)
        m.box((0, y, z), (0.12, 0.12, 0.02), col, rot=(0, 0, 45))
    elif F == "D":  # spore
        m.ball((0, y, z), 0.07, col, seg=6, rings=2, scale=(1, 1, 0.3))
        for sx, sy in ((-1, 1), (1, 1), (0, -1.3)):
            m.ball((sx * 0.08, y + sy * 0.07, z), 0.035, col, seg=5, rings=2, scale=(1, 1, 0.4))
    elif F == "E":  # starfish: 5 arms
        for k in range(5):
            import math
            a = math.radians(90 + k * 72)
            m.limb((0, y, z), (math.cos(a) * 0.09, y + math.sin(a) * 0.09, z), 0.04, col, d=0.02)
    else:  # rune
        m.box((0, y, z), (0.04, 0.16, 0.02), col)
        m.box((0, y + 0.02, z), (0.14, 0.04, 0.02), col)
        m.box((0.05, y - 0.05, z), (0.07, 0.03, 0.02), col, rot=(0, 0, 35))


# ------------------------------------------------------------------ roles
def new(F, P):
    m = Model("tmp")
    m.optimize = True
    return m


def r_grunt(P, F):
    m = new(F, P)
    body(m, P, F)
    back(m, P, F)
    head(m, P, F)
    hat_for(m, P, F, "grunt")
    if F == "E":
        m.box((-0.13, 1.02, 0.255), (0.15, 0.15, 0.02), P[3])  # eye patch
        m.limb((-0.13, 1.1, 0.256), (0.1, 1.0, 0.256), 0.025, P[3], d=0.01)
    if F == "F":
        m.box((0.0, 0.3, 0.05), (0.04, 0.04, 0.04), P[4])
    arms_fwd(m, P, F)
    m.fit(height=1.5)
    return m


def r_scout(P, F):
    m = new(F, P)
    c = CFG[F]
    if F == "C":  # one chunky wheel
        m.cyl((0, 0.2, 0.0), 0.22, 0.2, P[3], sides=10, rot=(0, 0, 90))
        m.cyl((0, 0.2, 0.0), 0.12, 0.24, P[4], sides=8, rot=(0, 0, 90))
        m.box((0, 0.42, 0), (0.16, 0.18, 0.2), P[2])
    else:
        for sx, ang in ((-1, 28), (1, -28)):
            with m.group(rot=(ang, 0, 0), pivot=(0, 0.50, 0)):
                m.box((sx * 0.08, 0.05, 0.03), (0.13, 0.10, 0.2), P[c["boot"]] if F != "B" else P[5])
                m.box((sx * 0.08, 0.30, 0.0), (0.09, 0.40, 0.11), P[c["leg"]])
    with m.group(rot=(22, 0, 0), pivot=(0, 0.5, 0)):
        m.box((0, 0.70, 0), (0.30, 0.36, 0.22), P[c["torso"]], bevel=0.035)
        if F == "B":
            for yy in (0.8, 0.72, 0.64):
                m.box((0, yy, 0.115), (0.22, 0.03, 0.02), P[1])
            m.box((0, 0.84, -0.2), (0.4, 0.36, 0.06), P[2], rot=(-18, 0, 0))
            m.box((0, 0.84, -0.17), (0.34, 0.3, 0.03), P[3], rot=(-18, 0, 0))
        elif F == "C":
            m.box((0, 0.75, -0.22), (0.2, 0.2, 0.22), P[2])
            m.box((0, 0.9, -0.34), (0.05, 0.22, 0.18), P[2])
            m.box((0, 0.72, 0.115), (0.08, 0.3, 0.02), P[5])
        elif F == "D":
            m.box((0, 0.8, -0.1), (0.36, 0.3, 0.2), P[2], bevel=0.05, rot=(-12, 0, 0))
            for sx in (-1, 1):
                m.box((sx * 0.1, 0.9, -0.18), (0.1, 0.08, 0.1), P[5])
            m.box((0, 0.8, -0.1), (0.04, 0.3, 0.205), P[3])
        elif F == "E":
            m.box((0, 0.7, 0.115), (0.3, 0.1, 0.02), P[3])
        else:
            m.pyramid((0, 0.62, -0.1), (0.1, 0.1), 0.46, P[2], rot=(-90, 0, 0))
        head(m, P, F, y=1.03, hw=0.5, hh=0.40, hd=0.44)
        hat_for(m, P, F, "scout", y=1.03, hw=0.5, hh=0.40, hd=0.44)
        for sx in (-1, 1):
            with m.group(rot=(sx * 50, 0, 0), pivot=(sx * 0.2, 0.84, 0)):
                m.limb((sx * 0.2, 0.84, 0), (sx * 0.2, 0.52, 0.04), 0.08, P[c["arm"]])
                m.box((sx * 0.2, 0.5, 0.04), (0.1, 0.1, 0.1), P[c["hand"]])
    m.fit(height=1.2)
    return m


def r_brute(P, F):
    m = new(F, P)
    c = CFG[F]
    for sx in (-1, 1):
        m.box((sx * 0.15, 0.05, 0.03), (0.22, 0.10, 0.24), P[c["boot"]])
        m.box((sx * 0.15, 0.2, 0.0), (0.2, 0.18, 0.18), P[c["leg"]])
    body_col = {"B": 3, "C": 1, "D": 3, "E": 3, "F": 3}[F]
    m.box((0, 0.52, 0), (0.62, 0.52, 0.36), P[body_col], bevel=0.05)
    m.box((0, 0.30, 0), (0.64, 0.06, 0.38), P[3] if F in "CD" else P[4] if F == "E" else P[2])
    sh = {"B": 4, "C": 2, "D": 2, "E": 4, "F": 2}[F]
    for sx in (-1, 1):
        m.ball((sx * 0.4, 0.75, 0), 0.19, P[sh], seg=8, rings=3)
        m.limb((sx * 0.4, 0.72, 0), (sx * 0.4, 0.46, 0.12), 0.14, P[c["arm"]])
    # head
    if F == "B":
        m.box((0, 0.97, 0), (0.6, 0.46, 0.56), P[4], bevel=0.06)
        m.box((0, 0.98, 0.285), (0.46, 0.11, 0.03), K)
        for sx in (-1, 1):
            m.box((sx * 0.13, 0.98, 0.3), (0.08, 0.06, 0.02), P[6])
    elif F == "C":
        m.box((0, 0.97, 0), (0.6, 0.4, 0.56), P[3], bevel=0.05)
        m.box((0, 0.98, 0.285), (0.44, 0.075, 0.03), P[6])
    elif F == "D":
        m.box((0, 0.97, 0), (0.6, 0.42, 0.56), P[1], bevel=0.05)
        for sx in (-1, 1):
            m.box((sx * 0.15, 1.0, 0.285), (0.14, 0.12, 0.03), P[6])
        m.limb((0, 1.1, 0.25), (0, 1.35, 0.4), 0.14, P[4], d=0.14)
        m.pyramid((0, 1.35, 0.4), (0.14, 0.14), 0.2, P[4], rot=(70, 0, 0))
    elif F == "E":
        m.box((0, 0.97, 0), (0.58, 0.44, 0.54), P[1], bevel=0.05)
        m.frustum((0, 1.17, 0), (0.6, 0.56), (0.46, 0.42), 0.14, P[4])
        for sx in (-1, 1):
            m.box((sx * 0.14, 0.99, 0.275), (0.1, 0.1, 0.03), W)
            m.box((sx * 0.14, 0.99, 0.29), (0.05, 0.06, 0.03), P[3])
            m.box((sx * 0.14, 1.07, 0.275), (0.16, 0.04, 0.03), P[3], rot=(0, 0, -sx * 22))
    else:
        m.box((0, 0.97, 0), (0.6, 0.4, 0.56), P[3], bevel=0.05)
        m.box((0, 0.98, 0.285), (0.46, 0.08, 0.03), P[6])
        for sx in (-1, 1):
            m.box((sx * 0.38, 0.55, 0.0), (0.05, 0.3, 0.05), P[6])
    # shield
    sc = {"B": 2, "C": 4, "D": 2, "E": 2, "F": 2}[F]
    if F == "D":  # domed shell
        m.frustum((0, 0.2, 0.36), (0.9, 0.2), (0.6, 0.2), 0.8, P[2], rot=(0, 0, 0))
        for i, (x, y) in enumerate(((-0.2, 0.4), (0.2, 0.6), (-0.1, 0.8))):
            m.box((x, y, 0.47), (0.1, 0.1, 0.03), P[5])
        m.box((0, 0.6, 0.41), (0.86, 0.08, 0.03), P[3])
    else:
        m.box((0, 0.58, 0.42), (0.86, 0.78, 0.09), P[sc], bevel=0.03)
        trim = {"B": 5, "C": 5, "E": 5, "F": 5}[F]
        if F == "B":
            m.box((0, 0.58, 0.47), (0.08, 0.6, 0.03), P[5])
            m.box((0, 0.68, 0.47), (0.4, 0.08, 0.03), P[5])
        elif F == "E":
            for yy in (0.32, 0.84):
                m.box((0, yy, 0.47), (0.88, 0.08, 0.03), P[trim])
        else:
            m.box((0, 0.58, 0.47), (0.88, 0.14, 0.03), P[trim])
        if F == "C":
            for sx in (-1, 1):
                for sy in (-1, 1):
                    m.box((sx * 0.36, 0.58 + sy * 0.3, 0.47), (0.06, 0.06, 0.03), P[3])
    m.fit(height=2.2)
    return m


def w_gunner(m, P, F):
    x, y = -0.2, 0.6
    if F == "B":  # crossbow
        m.box((x, y, 0.3), (0.07, 0.09, 0.5), P[4])
        for sx in (-1, 1):
            m.limb((x, y + 0.01, 0.5), (x + sx * 0.28, y + 0.01, 0.4), 0.05, P[5])
        m.box((x, y + 0.06, 0.45), (0.035, 0.035, 0.46), P[4])
        m.pyramid((x, y + 0.06, 0.66), (0.08, 0.08), 0.1, P[6], rot=(90, 0, 0))
        mz = 0.78
    elif F == "C":
        m.box((x, y, 0.32), (0.14, 0.16, 0.5), P[4], bevel=0.02)
        m.box((x, y, 0.6), (0.1, 0.1, 0.06), P[6])
        for z in (0.2, 0.4):
            m.box((x, y, z), (0.15, 0.17, 0.05), P[5])
        mz = 0.64
    elif F == "D":
        m.box((x, y, 0.3), (0.13, 0.14, 0.42), P[3], bevel=0.02)
        m.ball((x, y, 0.2), 0.1, P[5], seg=6, rings=2)
        for z in (0.3, 0.42):
            m.box((x + 0.07, y + 0.03, z), (0.03, 0.04, 0.04), P[5])
        m.box((x, y, 0.55), (0.09, 0.09, 0.06), P[6])
        mz = 0.6
    elif F == "E":  # flintlock pistol
        m.box((x, y - 0.07, 0.1), (0.06, 0.13, 0.08), P[3], rot=(-15, 0, 0))
        m.box((x, y, 0.28), (0.07, 0.08, 0.38), P[4])
        m.box((x, y + 0.05, 0.12), (0.04, 0.06, 0.07), P[5])
        m.box((x, y, 0.5), (0.06, 0.06, 0.05), P[6])
        mz = 0.54
    else:
        m.box((x, y, 0.28), (0.1, 0.12, 0.4), P[4], bevel=0.02)
        m.box((x, y, 0.28), (0.11, 0.04, 0.12), P[5])
        m.ball((x, y, 0.52), 0.09, P[6], seg=6, rings=3)
        mz = 0.6
    m.set_muzzle((x, y, mz))


def w_sniper(m, P, F):
    x, y = -0.17, 0.72
    m.box((x, y - 0.03, 0.06), (0.07, 0.14, 0.2), P[3] if F != "B" else P[1])
    m.box((x, y, 0.34), (0.07, 0.1, 0.44), P[3] if F in "BF" else P[2] if F == "C" else P[3])
    if F == "D":
        m.cyl((x, y + 0.005, 0.8), 0.055, 0.8, P[4], sides=8, rot=(90, 0, 0))
        m.cyl((x, y + 0.005, 1.2), 0.07, 0.06, P[6], sides=8, rot=(90, 0, 0))
    else:
        m.box((x, y + 0.005, 0.8), (0.05, 0.05, 0.62), P[4])
        m.box((x, y + 0.005, 1.12), (0.07, 0.07, 0.04), P[6] if F in "CF" else P[5])
    if F in "BCF":  # scope with glowing lens
        m.cyl((x, y + 0.095, 0.34), 0.045, 0.28, P[4], sides=8, rot=(90, 0, 0))
        m.cyl((x, y + 0.095, 0.5), 0.055, 0.03, P[6], sides=8, rot=(90, 0, 0))
    if F == "E":
        for z in (0.6, 0.9):
            m.box((x, y + 0.005, z), (0.07, 0.07, 0.05), P[5])
    m.set_muzzle((x, y + 0.005, 1.17))


def r_gunner(P, F):
    m = new(F, P)
    body(m, P, F)
    back(m, P, F)
    head(m, P, F, mood="angry")
    hat_for(m, P, F, "gunner")
    if F == "E":
        hold_pose(m, P, F, left=(0.3, 0.5, 0.06))
    elif F == "B":
        hold_pose(m, P, F, left=(-0.05, 0.57, 0.3))
    else:
        hold_pose(m, P, F)
    w_gunner(m, P, F)
    m.fit(height=1.6)
    return m


def r_warlord(P, F):
    m = new(F, P)
    c = CFG[F]
    body(m, P, F, w=1.45, d=0.32, y0=0.28, leg_h=0.28, spread=0.1, bev=0.04)
    if F in "BF":
        m.box((0, 0.55, -0.19), (0.5, 0.36, 0.08), P[2] if F == "B" else P[2])
    pc = {"B": 3, "C": 2, "D": 2, "E": 4, "F": 3}[F]
    for sx in (-1, 1):
        m.ball((sx * 0.4, 0.78, 0), 0.19, P[pc], seg=8, rings=3)
        if F in "BF":
            for k, (dx, dz) in enumerate(((0, 0), (0.07, 0.1), (0.07, -0.1))):
                m.pyramid((sx * (0.4 + dx), 0.93 - 0.03 * k, dz), (0.08, 0.08), 0.13, P[5], rot=(0, 0, -sx * (12 + 22 * (k > 0))))
        elif F == "E":
            m.box((sx * 0.4, 0.97, 0), (0.2, 0.05, 0.2), P[5])
            for k in range(3):
                m.ball((sx * 0.4 + sx * 0.06 * k, 0.88 - 0.05 * k, 0.15), 0.03, P[5], seg=5, rings=2)
    head(m, P, F, hw=0.58, hh=0.46, hd=0.52)
    hat_for(m, P, F, "warlord", hw=0.58, hh=0.46, hd=0.52)
    if F == "F":
        m.box((0, 1.22, 0), (0.6, 0.18, 0.54), P[2], bevel=0.04)
        for sx in (-1, 1):
            m.limb((sx * 0.3, 1.22, 0), (sx * 0.5, 1.5, 0), 0.1, P[4])
            m.pyramid((sx * 0.5, 1.48, 0), (0.1, 0.1), 0.2, P[4], rot=(0, 0, -sx * 22))
    if F == "C":
        for sx in (-1, 1):
            m.cyl((sx * 0.1, 0.9, -0.28), 0.05, 0.4, P[4], sides=6)
    # arms + weapon
    if F == "D":  # twin blade-claws
        for sx in (-1, 1):
            arm(m, sx, (sx * 0.4, 0.70, 0.0), (sx * 0.36, 0.52, 0.22), P[2], hand=P[2], w=0.14, hand_s=0.14)
            m.frustum((sx * 0.36, 0.52, 0.28), (0.14, 0.06), (0.02, 0.02), 0.7, P[4], rot=(90, 0, 0))
            m.frustum((sx * 0.36, 0.52, 0.28), (0.1, 0.1), (0.1, 0.1), 0.05, P[5], rot=(90, 0, 0))
    else:
        arm(m, 1, (0.4, 0.70, 0.0), (0.45, 0.42, 0.1), P[c["arm"]], hand=P[c["hand"]], w=0.14, hand_s=0.14)
        arm(m, -1, (-0.4, 0.70, 0.0), (-0.34, 0.54, 0.24), P[c["arm"]], hand=P[c["hand"]], w=0.14, hand_s=0.14)
        cx = -0.34
        if F == "B":  # bone-handled cleaver
            m.limb((cx, 0.36, 0.24), (cx, 0.68, 0.24), 0.07, P[1])
            m.box((cx, 0.69, 0.24), (0.1, 0.05, 0.1), P[5])
            m.box((cx, 0.98, 0.25), (0.08, 0.5, 0.32), P[4], bevel=0.015)
            m.box((cx, 0.98, 0.09), (0.1, 0.5, 0.05), P[3])
            m.box((cx, 1.255, 0.25), (0.08, 0.04, 0.3), W)
        elif F == "C":  # spinning saw
            m.limb((-0.34, 0.54, 0.24), (-0.5, 0.6, 0.34), 0.1, P[4])
            m.cyl((-0.56, 0.68, 0.38), 0.42, 0.07, P[4], sides=12, rot=(0, 0, 90))
            m.cyl((-0.56, 0.68, 0.38), 0.12, 0.14, P[5], sides=8, rot=(0, 0, 90))
            import math
            for k in range(8):
                a = math.radians(k * 45 + 22)
                m.box((-0.56, 0.68 + math.sin(a) * 0.44, 0.38 + math.cos(a) * 0.44), (0.07, 0.1, 0.1), P[4], rot=(math.degrees(a) * -1, 0, 0))
        elif F == "E":  # anchor cleaver
            m.limb((cx, 0.34, 0.24), (cx, 0.9, 0.24), 0.07, P[3])
            m.box((cx, 1.0, 0.24), (0.07, 0.4, 0.07), P[4])
            m.box((cx, 1.2, 0.24), (0.07, 0.07, 0.42), P[4])
            for sz in (-1, 1):
                m.limb((cx, 0.82, 0.24), (cx, 0.98, 0.24 + sz * 0.26), 0.08, P[4])
                m.pyramid((cx, 0.98, 0.24 + sz * 0.28), (0.12, 0.12), 0.22, P[4], rot=(sz * 60, 0, 0))
        else:  # jagged greatsword
            m.limb((cx, 0.36, 0.24), (cx, 0.66, 0.24), 0.07, P[3])
            m.box((cx, 0.67, 0.24), (0.1, 0.05, 0.3), P[5])
            m.box((cx, 1.0, 0.25), (0.06, 0.62, 0.22), P[4], bevel=0.01)
            m.box((cx, 1.0, 0.26), (0.07, 0.56, 0.03), P[6])
            for k in range(4):
                m.pyramid((cx, 0.8 + 0.14 * k, 0.37 + 0.0), (0.06, 0.08), 0.1, P[4], rot=(90, 0, 0))
            m.pyramid((cx, 1.35, 0.25), (0.06, 0.22), 0.14, P[4])
    m.fit(height=3.6)
    return m


def r_kamikaze(P, F):
    m = new(F, P)
    c = CFG[F]
    for sx in (-1, 1):
        m.box((sx * 0.08, 0.05, 0.05), (0.12, 0.10, 0.2), P[c["boot"]] if F != "B" else P[3])
        m.box((sx * 0.08, 0.17, 0.0), (0.1, 0.16, 0.12), P[c["leg"]])
    head_y = 0.95
    if F == "C":  # the body is the bomb
        m.ball((0, 0.5, 0), 0.36, P[3], seg=8, rings=3)
        m.box((0, 0.9, 0.0), (0.16, 0.12, 0.16), P[5])
        for sx in (-1, 1):
            m.cyl((sx * 0.34, 0.5, 0.0), 0.08, 0.34, P[2], sides=6)
        head_y = 0.55
        m.box((0, 0.55, 0.3), (0.5, 0.4, 0.06), K)
        for sx in (-1, 1):
            m.box((sx * 0.12, 0.6, 0.335), (0.12, 0.12, 0.03), P[6])
        m.box((0, 0.46, 0.335), (0.16, 0.12, 0.03), P[6])
        for sx in (-1, 1):
            m.limb((sx * 0.38, 0.62, 0.0), (sx * 0.34, 0.95, 0.0), 0.08, P[1])
            m.box((sx * 0.34, 1.0, 0.0), (0.1, 0.1, 0.1), P[4])
    elif F == "D":  # puffy pod
        m.ball((0, 0.52, 0), 0.38, P[2], seg=8, rings=3)
        import math
        for k in range(8):
            a = math.radians(k * 45 + 10)
            m.ball((math.cos(a) * 0.34, 0.52 + (0.18 if k % 2 else -0.08), math.sin(a) * 0.3), 0.07, P[6], seg=5, rings=2)
        m.limb((0, 0.88, 0), (0, 1.08, 0.0), 0.05, P[3])
        m.ball((0, 1.13, 0), 0.08, P[5], seg=5, rings=2)
        m.box((0, 0.58, 0.35), (0.32, 0.26, 0.06), P[1])
        for sx in (-1, 1):
            m.box((sx * 0.08, 0.63, 0.385), (0.09, 0.1, 0.03), W)
            m.box((sx * 0.08, 0.63, 0.40), (0.04, 0.05, 0.03), P[3])
        m.box((0, 0.5, 0.385), (0.1, 0.1, 0.03), P[3])
        for sx in (-1, 1):
            m.limb((sx * 0.34, 0.6, 0.05), (sx * 0.3, 0.98, 0.05), 0.08, P[1])
            m.box((sx * 0.3, 1.03, 0.05), (0.1, 0.1, 0.1), P[4])
        head_y = None
    else:
        m.box((0, 0.5, 0), (0.3, 0.3, 0.22), P[c["torso"]], bevel=0.03)
        bomb = {"B": 3, "E": 3, "F": 3}[F]
        m.ball((0, 0.55, 0.28), 0.3, P[bomb], seg=8, rings=3)
        if F == "E":
            for yy in (0.42, 0.68):
                m.box((0, yy, 0.28), (0.5, 0.05, 0.5), P[4], bevel=0.02)
        if F == "F":
            m.box((0, 0.55, 0.52), (0.4, 0.4, 0.03), P[6], rot=(0, 0, 45))
            m.box((0, 0.55, 0.535), (0.28, 0.28, 0.03), P[3], rot=(0, 0, 45))
        m.limb((0, 0.84, 0.28), (0.04, 1.0, 0.28), 0.04, P[4])
        m.box((0.05, 1.04, 0.28), (0.07, 0.07, 0.07), P[6])
        for sx in (-1, 1):
            arm(m, sx, (sx * 0.2, 0.62, 0.0), (sx * 0.34, 0.9, 0.26), P[c["arm"]], hand=P[c["hand"]], w=0.08, hand_s=0.1)
        head_y = 1.0
    if head_y is not None and F != "C":
        head(m, P, F, y=1.02, hw=0.5, hh=0.42, hd=0.46, mood="panic")
        hat_for(m, P, F, "kamikaze", y=1.02, hw=0.5, hh=0.42, hd=0.46)
        if F == "B":
            m.box((0, 0.8, 0.0), (0.4, 0.08, 0.3), P[2])
    m.fit(height=1.3)
    return m


def r_sniper(P, F):
    m = new(F, P)
    c = CFG[F]
    # tall and thin: long legs, slim torso
    for sx in (-1, 1):
        m.box((sx * 0.08, 0.05, 0.03), (0.12, 0.10, 0.2), P[c["boot"]])
        m.box((sx * 0.08, 0.28, 0.0), (0.09, 0.38, 0.12), P[c["leg"]])
    if F in "BF":  # long robe
        m.frustum((0, 0.12, 0), (0.42, 0.3), (0.32, 0.22), 0.8, P[3])
        m.box((0, 0.86, 0), (0.34, 0.2, 0.24), P[3])
    else:
        m.box((0, 0.66, 0), (0.28, 0.46, 0.2), P[c["torso"]], bevel=0.03)
        m.box((0, 0.66, 0.105), (0.2, 0.3, 0.02), P[2] if F in "CD" else P[3])
    if F == "E":
        m.frustum((0, 0.3, 0), (0.38, 0.28), (0.3, 0.22), 0.6, P[3])
    if F == "D":
        for sx in (-1, 1):
            m.box((sx * 0.1, 0.8, -0.16), (0.1, 0.3, 0.06), P[2])
    if F == "C":
        m.box((0, 0.7, -0.16), (0.2, 0.3, 0.1), P[2])
    y = 1.18
    mood = {"B": "cyclops", "C": "cyclops", "D": "cyclops", "E": "spy", "F": "cyclops"}[F]
    head(m, P, F, y=y, hw=0.42, hh=0.36, hd=0.38, mood=mood)
    hat_for(m, P, F, "sniper_enemy", y=y, hw=0.42, hh=0.36, hd=0.38)
    for sx in (-1, 1):
        a = (sx * 0.2, 0.86, 0.0)
        b = (-0.17, 0.74, 0.22) if sx == -1 else (-0.15, 0.7, 0.4)
        arm(m, sx, a, b, P[c["arm"]] if F not in "BF" else P[3], hand=P[c["hand"]], w=0.07, hand_s=0.09)
    w_sniper(m, P, F)
    m.fit(height=1.7)
    return m


def r_medic(P, F):
    m = new(F, P)
    c = CFG[F]
    body(m, P, F, w=1.05, d=0.28)
    # chest emblem + back emblem + tank
    m.box((0, 0.57, 0.15), (0.3, 0.3, 0.03), P[3] if F != "F" else P[2])
    symbol(m, P, F, 0.57, 0.168, c)
    m.box((0, 0.55, -0.22), (0.34, 0.42, 0.16), P[4], bevel=0.02)
    m.box((0, 0.55, -0.3), (0.26, 0.34, 0.03), P[6])
    symbol(m, P, F, 0.55, -0.3 - 0.02, c)
    head(m, P, F, y=0.96, mood="calm")
    hat_for(m, P, F, "medic_enemy", y=0.96)
    if F == "D":  # moth wings, antennae already
        for sx in (-1, 1):
            m.box((sx * 0.22, 0.75, -0.3), (0.2, 0.36, 0.05), P[2], rot=(0, 0, sx * 15))
            m.box((sx * 0.22, 0.75, -0.33), (0.1, 0.1, 0.02), P[6])
    if F == "E":
        for sx in (-1, 1):  # goggles
            m.box((sx * 0.13, 1.0, 0.262), (0.15, 0.15, 0.03), P[4])
            m.box((sx * 0.13, 1.0, 0.285), (0.1, 0.1, 0.02), P[6])
        m.box((0, 1.0, 0.262), (0.12, 0.04, 0.03), P[4])
    hold_pose(m, P, F, left=(0.28, 0.45, 0.1), right=(-0.2, 0.62, 0.26))
    m.box((-0.2, 0.66, 0.34), (0.04, 0.04, 0.2), P[4])  # wand
    m.ball((-0.2, 0.66, 0.5), 0.07, P[6], seg=6, rings=2)
    m.fit(height=1.5)
    return m


def r_mortar(P, F):
    m = new(F, P)
    c = CFG[F]
    body(m, P, F, w=1.1, d=0.28)
    back(m, P, F, w=1.1)
    head(m, P, F, y=0.98, mood="angry")
    hat_for(m, P, F, "mortar")
    shell_col = P[1] if F == "B" else P[3] if F == "E" else P[6]
    if F == "C":  # shoulder tube + drum
        mz = tube(m, (-0.34, 0.95, 0.22), 0.13, 0.55, P[4], rx=20, r_top=0.15)
        m.box((-0.34, 0.8, 0.12), (0.12, 0.1, 0.2), P[4])
        m.cyl((0, 0.58, -0.3), 0.18, 0.3, P[2], sides=8, rot=(90, 0, 0))
        for yy in (0.2, 0.34):
            m.cyl((-0.34, 0.95 + (yy - 0.27) * 0.9, 0.22 + (yy - 0.27) * 0.34), 0.145, 0.05, P[5], sides=8, rot=(20, 0, 0))
        hold_pose(m, P, F, left=(0.25, 0.5, 0.1), right=(-0.3, 0.72, 0.14))
    elif F == "D":  # cannon grows out of the rear, bent forward over the back
        m.box((0, 0.5, -0.22), (0.3, 0.26, 0.2), P[2], bevel=0.04)
        m.limb((0, 0.5, -0.25), (0, 1.0, -0.3), 0.2, P[4])
        mz = tube(m, (0, 1.2, -0.12), 0.13, 0.5, P[4], rx=-5 + 25, r_top=0.15)
        for k in range(2):
            m.box((0.0 + (-0.2 if k else 0.2), 0.76, -0.25), (0.1, 0.1, 0.1), P[5])
        hold_pose(m, P, F, left=(0.28, 0.46, 0.1), right=(-0.25, 0.5, 0.15))
    else:
        mz = tube(m, (0, 0.6, 0.36), 0.14, 0.44, P[4], rx=20, r_top=0.15)
        m.ball((0.0, mz[1] + 0.03, mz[2] + 0.03), 0.13, shell_col, seg=7, rings=3)
        if F == "B":
            for sx in (-1, 1):
                m.box((sx * 0.05, mz[1] + 0.06, mz[2] + 0.15), (0.045, 0.045, 0.03), P[6])
        if F == "F":
            m.cyl((0, 0.5, 0.33), 0.155, 0.05, P[5], sides=8, rot=(20, 0, 0))
        if F == "E":
            m.cyl((0, 0.5, 0.33), 0.155, 0.05, P[5], sides=8, rot=(20, 0, 0))
        hold_pose(m, P, F, left=(0.14, 0.55, 0.4), right=(-0.14, 0.55, 0.4))
    m.set_muzzle(tuple(mz))
    m.fit(height=1.7)
    return m


def r_blinder(P, F):
    m = new(F, P)
    c = CFG[F]
    body(m, P, F, w=1.0, d=0.27)
    if F == "C":  # the head is a big lamp
        m.box((0, 1.0, 0), (0.6, 0.5, 0.52), P[3], bevel=0.06)
        m.box((0, 1.0, 0.27), (0.5, 0.4, 0.05), P[6])
        for sx in (-1, 1):
            m.box((sx * 0.34, 1.0, 0.0), (0.08, 0.2, 0.2), P[5])
        m.box((0, 1.3, 0), (0.18, 0.1, 0.18), P[5])
        for sx in (-1, 1):
            arm(m, sx, (sx * 0.24, 0.68, 0.0), (sx * 0.3, 0.95, 0.3), P[c["arm"]], hand=P[c["hand"]], w=0.1, hand_s=0.12)
        m.set_muzzle((0, 1.0, 0.36))
        for sx in (-1, 1):
            m.box((sx * 0.14, 0.45, 0.155), (0.08, 0.2, 0.02), P[5], rot=(0, 0, sx * 25))
    else:
        back(m, P, F)
        head(m, P, F, y=0.9, hw=0.52, hh=0.42, hd=0.48, mood="squint")
        hat_for(m, P, F, "blinder", y=0.9, hw=0.52, hh=0.42, hd=0.48)
        if F == "D":  # firefly: glowing abdomen bulb in front, wings
            m.box((0, 0.55, 0.3), (0.36, 0.36, 0.3), P[6], bevel=0.05)
            for sx in (-1, 1):
                m.box((sx * 0.25, 0.8, -0.25), (0.1, 0.4, 0.05), P[2], rot=(0, 0, sx * 18))
            m.set_muzzle((0, 0.55, 0.46))
            for sx in (-1, 1):
                arm(m, sx, (sx * 0.24, 0.68, 0.0), (sx * 0.3, 0.95, 0.3), P[c["arm"]], hand=P[c["hand"]], w=0.09, hand_s=0.1)
        else:
            arm(m, -1, (-0.24, 0.70, 0.0), (-0.3, 1.2, 0.2), P[c["arm"]], hand=P[c["hand"]], w=0.1, hand_s=0.12)
            m.box((-0.3, 1.4, 0.22), (0.34, 0.36, 0.34), P[4], bevel=0.02)
            m.box((-0.3, 1.4, 0.4), (0.26, 0.28, 0.04), P[6])
            m.box((-0.3, 1.4, 0.2), (0.28, 0.3, 0.3), P[6])
            m.box((-0.3, 1.6, 0.22), (0.3, 0.06, 0.3), P[4])
            m.set_muzzle((-0.3, 1.4, 0.44))
            arm(m, 1, (0.24, 0.70, 0.0), (0.12, 1.0, 0.3), P[c["arm"]], hand=P[c["hand"]], w=0.1, hand_s=0.11)
    m.fit(height=1.6)
    return m


def r_weakener(P, F):
    m = new(F, P)
    c = CFG[F]
    body(m, P, F, w=1.0, d=0.27)
    back(m, P, F)
    head(m, P, F, y=0.97, mood="angry")
    hat_for(m, P, F, "weakener", y=0.97)
    if F == "B":  # bead strands
        for sx in (-1, 1):
            for k in range(3):
                m.ball((sx * 0.1, 0.68 - k * 0.09, 0.15), 0.035, P[5], seg=5, rings=2)
    if F == "E":
        m.box((0, 1.19, 0.255), (0.12, 0.1, 0.03), W)
    if F == "C":  # antenna array + dish on back
        m.cyl((0, 0.9, -0.3), 0.2, 0.06, P[4], sides=8, rot=(70, 0, 0))
        m.limb((0, 0.7, -0.17), (0, 0.9, -0.3), 0.05, P[4])
        for sx in (-1, 1):
            m.limb((sx * 0.15, 0.78, -0.17), (sx * 0.2, 1.3, -0.2), 0.04, P[4])
            m.ball((sx * 0.2, 1.32, -0.2), 0.04, P[5], seg=5, rings=2)
        for k in range(3):  # signal-wave emblem arcs
            m.box((0, 0.5 + k * 0.07, 0.162), (0.1 + k * 0.07, 0.03, 0.02), P[5])
    hold_pose(m, P, F, left=(0.285, 0.46, 0.06), right=(-0.22, 0.62, 0.2))
    x = -0.22
    if F == "C":  # short jammer rod
        m.box((x, 0.8, 0.2), (0.05, 0.4, 0.05), P[4])
        top = 1.05
    else:
        m.limb((x, 0.4, 0.2), (x, 1.25, 0.2), 0.055, P[4])
        top = 1.34
    m.box((x, top, 0.2), (0.2, 0.18, 0.2), P[4])
    m.ball((x, top, 0.2), 0.085, P[6], seg=6, rings=3)
    for sx in (-1, 1):
        m.box((x + sx * 0.1, top, 0.2), (0.02, 0.22, 0.22), P[4])
    if F in "BF":  # charms attached by short sticks
        for sx in (-1, 1):
            m.limb((x, top - 0.1, 0.2), (x + sx * 0.18, top - 0.2, 0.2), 0.025, P[5])
            m.box((x + sx * 0.2, top - 0.22, 0.2), (0.07, 0.07, 0.07), P[4] if F == "F" else P[1])
    if F == "E":
        for sx in (-1, 1):
            m.box((x + sx * 0.08, top - 0.14, 0.2), (0.04, 0.12, 0.04), P[2])
    m.set_muzzle((x, top, 0.3))
    m.fit(height=1.6)
    return m


def r_breacher(P, F):
    m = new(F, P)
    c = CFG[F]
    for sx in (-1, 1):
        m.box((sx * 0.14, 0.05, 0.03), (0.2, 0.10, 0.24), P[c["boot"]])
        m.box((sx * 0.14, 0.2, 0.0), (0.17, 0.2, 0.17), P[c["leg"]])
    bc = {"B": 3, "C": 1, "D": 2, "E": 3, "F": 3}[F]
    pl = {"B": 4, "C": 2, "D": 3, "E": 2, "F": 2}[F]
    m.box((0, 0.52, 0), (0.6, 0.5, 0.36), P[bc], bevel=0.05)
    m.box((0, 0.56, 0.19), (0.46, 0.34, 0.03), P[pl])
    m.box((0, 0.3, 0), (0.62, 0.06, 0.38), P[3] if bc != 3 else P[pl])
    for sx in (-1, 1):
        m.ball((sx * 0.38, 0.75, 0), 0.17, P[pl], seg=8, rings=3)
    if F == "B":
        m.box((0, 0.97, 0), (0.54, 0.44, 0.5), P[3], bevel=0.05)
        m.box((0, 0.98, 0.255), (0.4, 0.09, 0.03), K)
        for sx in (-1, 1):
            m.box((sx * 0.1, 0.98, 0.27), (0.07, 0.06, 0.02), P[6])
        for sx in (-1, 1):
            m.box((sx * 0.12, 0.3, 0.2), (0.12, 0.2, 0.03), P[2])
    elif F == "C":
        m.box((0, 0.95, 0), (0.54, 0.38, 0.5), P[3], bevel=0.05)
        m.box((0, 0.97, 0.255), (0.4, 0.07, 0.03), P[6])
    elif F == "D":
        head(m, P, F, y=0.97, hw=0.54, hh=0.44, hd=0.5, mood="angry")
        for sx in (-1, 1):
            m.limb((sx * 0.2, 0.9, 0.2), (sx * 0.3, 0.78, 0.5), 0.1, P[4])
            m.pyramid((sx * 0.3, 0.78, 0.5), (0.1, 0.1), 0.2, P[4], rot=(90, 0, 0))
    elif F == "E":
        head(m, P, F, y=0.97, hw=0.54, hh=0.44, hd=0.5, mood="angry")
        hat(m, P, "pot", 4, 4, y=0.97, hw=0.54, hh=0.44, hd=0.5)
    else:
        head(m, P, F, y=0.97, hw=0.54, hh=0.44, hd=0.5, mood="angry")
        for sx in (-1, 1):
            m.pyramid((sx * 0.22, 1.18, 0), (0.14, 0.14), 0.24, P[4], rot=(0, 0, -sx * 20))
    arm(m, 1, (0.38, 0.70, 0.0), (0.42, 0.45, 0.14), P[c["arm"]], hand=P[c["hand"]], w=0.13, hand_s=0.13)
    x, y = -0.36, 0.6
    m.limb((-0.38, 0.72, 0.0), (x, y, 0.1), 0.15, P[c["arm"]])
    if F == "B":  # coffin cannon
        m.frustum((x, y, 0.05), (0.3, 0.22), (0.18, 0.14), 0.75, P[4], rot=(90, 0, 0))
        for z in (0.2, 0.45, 0.7):
            m.frustum((x, y, z - 0.02), (0.3 - z * 0.15 + 0.02, 0.22 - z * 0.1 + 0.02), (0.3 - z * 0.15 + 0.02, 0.22 - z * 0.1 + 0.02), 0.06, P[5], rot=(90, 0, 0))
    elif F == "D":  # horn cannon
        m.frustum((x, y, 0.05), (0.3, 0.26), (0.14, 0.14), 0.75, P[4], rot=(90, 0, 0))
        for z in (0.25, 0.5):
            m.box((x, y, z), (0.3 - z * 0.2, 0.26 - z * 0.15, 0.05), P[5])
    elif F == "E":  # ship cannon
        m.cyl((x, y, 0.45), 0.15, 0.8, P[4], sides=8, rot=(90, 0, 0), r_top=0.12)
        for z in (0.2, 0.45, 0.7):
            m.cyl((x, y, z), 0.165, 0.05, P[5], sides=8, rot=(90, 0, 0))
    else:
        m.box((x, y, 0.4), (0.26, 0.26, 0.7), P[4], bevel=0.03)
        for z in (0.2, 0.5):
            m.box((x, y, z), (0.28, 0.28, 0.05), P[5])
        if F == "F":
            m.box((x, y, 0.74), (0.34, 0.34, 0.04), P[6])
    mzz = 0.82
    if F == "F":
        mzz = 0.78
    m.set_muzzle((x, y, mzz))
    m.fit(height=2.0)
    return m


def r_shotgunner(P, F):
    m = new(F, P)
    body(m, P, F)
    back(m, P, F)
    head(m, P, F, mood="angry")
    hat_for(m, P, F, "shotgunner")
    if F == "B":
        m.box((0, 0.78, 0.0), (0.44, 0.09, 0.3), P[3])  # scarf
    if F == "E":
        m.box((0, 0.8, 0.0), (0.44, 0.09, 0.3), P[5])  # scarf
    x, y = -0.2, 0.6
    hold_pose(m, P, F, left=(-0.05, 0.54, 0.34))
    m.box((x, y - 0.06, 0.1), (0.07, 0.15, 0.1), P[3], rot=(-15, 0, 0))
    if F == "C":  # twin barrels
        for sx in (-1, 1):
            m.box((x + sx * 0.05, y, 0.3), (0.07, 0.08, 0.4), P[4])
        m.frustum((x, y, 0.45), (0.2, 0.1), (0.3, 0.16), 0.22, P[4], rot=(90, 0, 0))
        for z in (0.2, 0.4):
            m.box((x, y, z), (0.2, 0.1, 0.04), P[5])
        mz = 0.67
    else:
        m.box((x, y, 0.22), (0.08, 0.1, 0.3), P[4] if F != "D" else P[3])
        m.frustum((x, y, 0.35), (0.07, 0.07), (0.26, 0.26), 0.3, P[4] if F != "D" else P[3], rot=(90, 0, 0))
        for z in (0.2, 0.36):
            m.box((x, y, z), (0.1, 0.12, 0.04), P[5])
        if F == "D":
            for k in range(5):
                import math
                a = math.radians(k * 72)
                m.pyramid((x + math.cos(a) * 0.12, y + math.sin(a) * 0.12, 0.6), (0.05, 0.05), 0.1, P[5], rot=(90, 0, 0))
        if F == "F":
            m.box((x, y, 0.64), (0.22, 0.22, 0.04), P[6])
        mz = 0.67
    m.set_muzzle((x, y, mz))
    m.fit(height=1.5)
    return m


BUILDERS = {"grunt": r_grunt, "scout": r_scout, "brute": r_brute, "gunner": r_gunner, "warlord": r_warlord,
            "kamikaze": r_kamikaze, "sniper_enemy": r_sniper, "medic_enemy": r_medic, "mortar": r_mortar,
            "blinder": r_blinder, "weakener": r_weakener, "breacher": r_breacher, "shotgunner": r_shotgunner}


def make(role, rnd):
    F = FAM_OF_ROUND[rnd]
    P = ["#000000"] + PAL[F][rnd]
    m = BUILDERS[role](P, F)
    m.name = f"{role}_r{rnd}"
    return m
