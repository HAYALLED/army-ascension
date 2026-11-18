"""Soldiers + enemies + boss. Soldier space: 1.3 m tall, front +Z, right hand = -X.
Every model ends with m.fit(height=H) so the final height is exact."""
from glbkit import Model, shade

SKIN = "#E8B98A"
DARK = "#23252E"
GUN = "#3A3D45"
WHITE = "#F4F4F4"
EYE = "#1B1B22"


# ----------------------------------------------------------------- shared bits
def legs(m, pants, boots, w=1.0, leg_h=0.30, spread=0.095, thick=0.13):
    for sx in (-1, 1):
        m.box((sx * spread * w, 0.05, 0.03), (0.15 * w, 0.10, 0.22), boots)
        m.box((sx * spread * w, 0.10 + (leg_h - 0.10) / 2, 0.0), (thick * w, leg_h - 0.10, 0.15), pants)


def torso(m, col, w=1.0, d=0.26, y0=0.30, y1=0.76, belt=DARK, bev=0.04):
    h = y1 - y0
    m.box((0, y0 + h / 2, 0), (0.38 * w, h, d), col, bevel=bev)
    if belt:
        m.box((0, y0 + 0.04, 0), (0.40 * w, 0.06, d + 0.02), belt)


def head(m, skin=SKIN, eyes=EYE, angry=False, brow=DARK, fangs=False, grin=False, eye_size=(0.06, 0.08),
         y=0.95, hw=0.5, hh=0.38, hd=0.46):
    m.box((0, y, 0), (hw, hh, hd), skin, bevel=0.05)
    ez = hd / 2 + 0.005
    for sx in (-1, 1):
        m.box((sx * 0.12, y + 0.03, ez), (eye_size[0], eye_size[1], 0.02), eyes)
        if angry:
            m.box((sx * 0.125, y + 0.115, ez), (0.12, 0.035, 0.025), brow, rot=(0, 0, -sx * 24))
    if fangs:
        m.box((0, y - 0.1, ez), (0.2, 0.04, 0.02), "#4A1F1F")
        for sx in (-1, 1):
            m.pyramid((sx * 0.065, y - 0.075, ez + 0.005), (0.045, 0.045), 0.055, "#FFFFFF", rot=(180, 0, 0))
    elif grin:
        m.box((0, y - 0.1, ez), (0.22, 0.035, 0.02), "#4A1F1F")
        for sx in (-1, 1):
            m.box((sx * 0.12, y - 0.082, ez), (0.035, 0.05, 0.02), "#4A1F1F", rot=(0, 0, -sx * 20))
    else:
        m.box((0, y - 0.09, ez), (0.1, 0.028, 0.02), "#7A3B2E")


def arm(m, side, a, b, col, hand=SKIN, w=0.10, hand_s=0.11):
    """side = -1 right (-X) / +1 left. a = shoulder, b = hand point."""
    m.limb(a, b, w, col)
    m.box(b, (hand_s, hand_s, hand_s), hand)


def helmet(m, col, y=1.20, w=0.56, d=0.52, h=0.20, brim=True):
    """Rim band + tapered dome (reads as a helmet, not a beret)."""
    base = y - h / 2
    m.box((0, base + 0.04, 0), (w, 0.08, d), shade(col, 0.82), bevel=0.02)
    m.frustum((0, base + 0.07, 0), (w - 0.02, d - 0.02), (w * 0.78, d * 0.76), h - 0.07 + 0.02, col)
    if brim:
        m.box((0, base + 0.02, d / 2 + 0.02), (w - 0.06, 0.04, 0.1), shade(col, 0.7))


def hood(m, col, tip=None):
    """Hood: top + sides + back, face stays open."""
    dark = shade(col, 0.75)
    m.box((0, 1.20, 0), (0.58, 0.20, 0.54), col, bevel=0.05)
    for sx in (-1, 1):
        m.box((sx * 0.275, 0.97, -0.02), (0.06, 0.40, 0.5), dark)
    m.box((0, 0.97, -0.25), (0.56, 0.40, 0.06), dark)
    if tip:
        m.pyramid((0, 1.29, -0.1), (0.28, 0.28), 0.14, tip, rot=(-35, 0, 0))


def rifle(m, x=-0.2, y=0.6, z0=0.08, length=0.62, col=GUN):
    """Basic rifle along +Z held at x,y. Returns muzzle z."""
    m.box((x, y - 0.02, z0 + 0.04), (0.07, 0.13, 0.14), shade(col, 0.8))  # stock
    m.box((x, y, z0 + 0.25), (0.075, 0.10, 0.34), col)  # receiver
    m.box((x, y + 0.005, z0 + length - 0.1), (0.05, 0.05, 0.24), shade(col, 0.7))  # barrel
    m.box((x, y - 0.1, z0 + 0.25), (0.05, 0.12, 0.06), shade(col, 0.7))  # mag
    return z0 + length + 0.02


# ------------------------------------------------------------------- soldiers
def rifleman():
    m = Model("rifleman")
    legs(m, "#2B3F7A", "#6B4423")
    torso(m, "#3573E6")
    m.box((0, 0.55, -0.19), (0.28, 0.30, 0.12), "#7A5230", bevel=0.02)  # backpack
    m.box((0, 0.72, -0.19), (0.3, 0.05, 0.13), "#5B3E22")
    head(m)
    helmet(m, "#1F3380")
    arm(m, -1, (-0.24, 0.70, 0.0), (-0.2, 0.57, 0.2), "#3573E6")
    arm(m, 1, (0.24, 0.70, 0.0), (0.285, 0.46, 0.06), "#3573E6")
    z = rifle(m, length=0.66)
    m.set_muzzle((-0.2, 0.605, z + 0.02))
    m.fit(height=1.3)
    return m


def machine_gunner():
    m = Model("machine_gunner")
    legs(m, "#7A4A12", "#5A3A1A", w=1.15)
    torso(m, "#F28C1F", w=1.2, d=0.28)
    for s in (-1, 1):  # crossed ammo belt
        m.limb((s * 0.19, 0.72, 0.145), (-s * 0.19, 0.36, 0.145), 0.06, "#F2C21A", d=0.04)
    m.box((0, 0.55, -0.2), (0.3, 0.28, 0.12), "#73400D", bevel=0.02)
    head(m)
    helmet(m, "#73400D", w=0.58, h=0.21)
    m.box((0, 0.78, 0.235), (0.22, 0.04, 0.03), "#4D2A08")  # chin guard
    arm(m, -1, (-0.28, 0.70, 0.0), (-0.22, 0.56, 0.22), "#F28C1F", w=0.12, hand_s=0.12)
    arm(m, 1, (0.28, 0.70, 0.0), (0.33, 0.46, 0.06), "#F28C1F", w=0.12, hand_s=0.12)
    x, y = -0.22, 0.60
    m.box((x, y, 0.28), (0.11, 0.14, 0.42), "#1E1F25", bevel=0.015)  # receiver
    m.box((x, y + 0.01, 0.58), (0.085, 0.085, 0.26), "#111216")  # barrel
    m.box((x, y + 0.01, 0.74), (0.11, 0.11, 0.06), "#111216")  # muzzle brake
    m.box((x, y + 0.09, 0.2), (0.05, 0.05, 0.14), "#2A2B33")  # carry handle
    m.box((x, y - 0.03, 0.04), (0.08, 0.12, 0.12), "#2A2B33")  # stock
    m.box((x + 0.1, y - 0.1, 0.24), (0.1, 0.14, 0.16), "#F2C21A", bevel=0.015)  # ammo box
    m.set_muzzle((x, y + 0.01, 0.78))
    m.fit(height=1.3)
    return m


def sniper():
    m = Model("sniper")
    legs(m, "#2A4A2A", "#3B2D1A", w=0.88)
    torso(m, "#386638", w=0.88, d=0.24)
    m.box((0, 0.56, -0.17), (0.24, 0.3, 0.1), "#1E3D1E", bevel=0.02)
    head(m)
    hood(m, "#1E3D1E")
    arm(m, -1, (-0.22, 0.70, 0.0), (-0.19, 0.58, 0.2), "#386638", w=0.09, hand_s=0.1)
    arm(m, 1, (0.22, 0.70, 0.0), (0.26, 0.46, 0.06), "#386638", w=0.09, hand_s=0.1)
    x, y = -0.19, 0.62
    m.box((x, y - 0.03, 0.06), (0.07, 0.14, 0.2), "#1B1C21")  # stock
    m.box((x, y, 0.34), (0.065, 0.09, 0.44), "#2A2C33")  # receiver
    m.box((x, y + 0.005, 0.78), (0.045, 0.045, 0.52), "#14151A")  # long barrel
    m.cyl((x, y + 0.095, 0.32), 0.045, 0.26, "#14151A", sides=8, rot=(90, 0, 0))  # scope
    m.cyl((x, y + 0.095, 0.2), 0.058, 0.05, "#2E3A52", sides=8, rot=(90, 0, 0))
    m.cyl((x, y + 0.095, 0.45), 0.058, 0.05, "#2E3A52", sides=8, rot=(90, 0, 0))
    m.box((x, y + 0.045, 0.32), (0.03, 0.05, 0.05), "#14151A")  # scope mount
    m.set_muzzle((x, y + 0.005, 1.06))
    m.fit(height=1.3)
    return m


def rocket_soldier():
    m = Model("rocket_soldier")
    legs(m, "#7A1F1F", "#3A2222")
    torso(m, "#CC3330", w=1.05)
    m.box((0, 0.55, -0.19), (0.28, 0.3, 0.12), "#591414", bevel=0.02)
    head(m, eyes=EYE)
    m.box((0, 0.86, 0.235), (0.1, 0.04, 0.02), "#FFFFFF")  # excited open grin
    helmet(m, "#591414")
    arm(m, -1, (-0.24, 0.70, 0.0), (-0.28, 0.60, 0.16), "#CC3330")
    arm(m, 1, (0.24, 0.70, 0.0), (0.285, 0.46, 0.06), "#CC3330")
    tx, ty = -0.32, 0.79
    m.cyl((tx, ty, 0.12), 0.095, 0.95, "#5F6B35", sides=8, rot=(90, 0, 0))  # tube
    m.cyl((tx, ty, 0.62), 0.12, 0.08, "#3F4823", sides=8, rot=(90, 0, 0))  # front ring
    m.cyl((tx, ty, -0.34), 0.12, 0.08, "#3F4823", sides=8, rot=(90, 0, 0))  # rear ring
    m.pyramid((tx, ty, 0.5), (0.13, 0.13), 0.24, "#FF7A1A", rot=(90, 0, 0), sides=6)  # rocket tip
    m.box((tx, ty - 0.13, 0.2), (0.05, 0.07, 0.1), "#2A2B33")  # grip
    m.set_muzzle((tx, ty, 0.78))
    m.fit(height=1.3)
    return m


def medic():
    m = Model("medic")
    legs(m, "#CFCFCF", "#5A5A5A")
    torso(m, "#F2F2F2", belt="#40B359")
    red = "#E02A2A"
    m.box((0, 0.55, 0.135), (0.20, 0.07, 0.02), red)
    m.box((0, 0.55, 0.135), (0.07, 0.20, 0.02), red)
    m.box((0, 0.55, -0.19), (0.30, 0.32, 0.13), "#FFFFFF", bevel=0.02)
    m.box((0, 0.55, -0.26), (0.16, 0.05, 0.02), red)
    m.box((0, 0.55, -0.26), (0.05, 0.16, 0.02), red)
    head(m)
    helmet(m, "#40B359")
    m.box((0, 1.21, 0.265), (0.12, 0.04, 0.02), WHITE)
    m.box((0, 1.21, 0.265), (0.04, 0.12, 0.02), WHITE)
    arm(m, -1, (-0.24, 0.70, 0.0), (-0.2, 0.57, 0.2), "#F2F2F2")
    arm(m, 1, (0.24, 0.70, 0.0), (0.285, 0.46, 0.06), "#F2F2F2")
    m.box((-0.2, 0.6, 0.3), (0.06, 0.1, 0.2), "#2F3138")  # pistol
    m.box((-0.2, 0.66, 0.31), (0.05, 0.03, 0.18), "#2F3138")
    m.set_muzzle((-0.2, 0.66, 0.42))
    m.fit(height=1.3)
    return m


# -------------------------------------------------------------------- enemies
def grunt():
    m = Model("grunt")
    legs(m, "#7A1F25", "#2A1A1A")
    torso(m, "#D13833")
    m.box((0, 0.55, -0.15), (0.3, 0.3, 0.06), "#9E2A27")
    head(m, eyes="#FFE63B", angry=True, fangs=True, eye_size=(0.07, 0.07))
    helmet(m, "#731A1F")
    for sx in (-1, 1):  # both arms forward, reaching
        arm(m, sx, (sx * 0.24, 0.68, 0.0), (sx * 0.2, 0.60, 0.42), "#D13833", hand_s=0.13)
    m.fit(height=1.5)
    return m


def scout():
    m = Model("scout")
    # long thin running legs
    for sx, ang in ((-1, 28), (1, -28)):
        with m.group(rot=(ang, 0, 0), pivot=(0, 0.50, 0)):
            m.box((sx * 0.08, 0.05, 0.03), (0.12, 0.10, 0.2), "#4A2A12")
            m.box((sx * 0.08, 0.30, 0.0), (0.09, 0.40, 0.11), "#7A3E10")
    with m.group(rot=(22, 0, 0), pivot=(0, 0.5, 0)):  # lean forward into the sprint
        m.box((0, 0.70, 0), (0.30, 0.36, 0.22), "#FF9E1F", bevel=0.035)
        head(m, eyes="#FF3A2A", angry=True, fangs=True, y=1.03, hw=0.46, hh=0.36, hd=0.42,
             eye_size=(0.07, 0.07))
        m.box((0, 1.24, 0), (0.5, 0.16, 0.46), "#E07E10", bevel=0.04)
        for i, (z, h) in enumerate(((-0.12, 0.2), (0.02, 0.24), (0.16, 0.18))):  # back fin spikes
            m.pyramid((0, 1.31 if i else 1.31, z - 0.02), (0.1, 0.12), h, "#8C470D", rot=(0, 0, 0))
        m.pyramid((0, 0.76, -0.19), (0.14, 0.14), 0.2, "#8C470D", rot=(-90, 0, 0))
        for sx in (-1, 1):
            with m.group(rot=(sx * 50, 0, 0), pivot=(sx * 0.2, 0.84, 0)):
                m.limb((sx * 0.2, 0.84, 0), (sx * 0.2, 0.52, 0.04), 0.08, "#FF9E1F")
                m.box((sx * 0.2, 0.5, 0.04), (0.1, 0.1, 0.1), SKIN)
    m.fit(height=1.2)
    return m


def brute():
    m = Model("brute")
    legs(m, "#4A5060", "#2B2F3A", w=1.5, leg_h=0.26, spread=0.1, thick=0.14)
    m.box((0, 0.52, 0), (0.62, 0.52, 0.36), "#808799", bevel=0.05)  # wide body
    m.box((0, 0.30, 0), (0.64, 0.06, 0.38), "#383D47")
    m.box((0, 0.60, 0.19), (0.3, 0.2, 0.03), "#6B7287")
    for sx in (-1, 1):
        m.ball((sx * 0.4, 0.75, 0), 0.19, "#9AA1B3", seg=8, rings=3)
        m.limb((sx * 0.4, 0.72, 0), (sx * 0.4, 0.46, 0.12), 0.14, "#6B7287")
    m.box((0, 0.97, 0), (0.60, 0.46, 0.56), "#383D47", bevel=0.05)  # visored helmet
    m.box((0, 1.0, 0.285), (0.44, 0.075, 0.03), "#FF3A2A")  # glowing eye slit
    m.box((0, 0.85, 0.285), (0.3, 0.05, 0.02), "#23262E")
    m.box((0, 1.24, -0.02), (0.14, 0.09, 0.4), "#2A2D36")  # helmet crest
    # shield
    m.box((0, 0.58, 0.42), (0.86, 0.78, 0.09), "#4D618C", bevel=0.03)
    m.box((0, 0.58, 0.475), (0.88, 0.14, 0.03), "#F2C21A")
    for sx in (-1, 1):
        for sy in (-1, 1):
            m.box((sx * 0.36, 0.58 + sy * 0.3, 0.475), (0.06, 0.06, 0.03), "#2E3E63")
    m.fit(height=2.2)
    return m


def gunner():
    m = Model("gunner")
    legs(m, "#4A2670", "#241236")
    torso(m, "#8C47BF")
    m.box((0, 0.55, -0.18), (0.28, 0.3, 0.1), "#401A59", bevel=0.02)
    head(m, eyes="#FFE34D", grin=True, eye_size=(0.08, 0.05))
    for sx in (-1, 1):  # sneaky half-lidded brows
        m.box((sx * 0.12, 1.025, 0.235), (0.1, 0.03, 0.02), "#2A1038", rot=(0, 0, -sx * 12))
    hood(m, "#401A59")
    arm(m, -1, (-0.24, 0.70, 0.0), (-0.2, 0.57, 0.2), "#8C47BF")
    arm(m, 1, (0.24, 0.70, 0.0), (0.285, 0.46, 0.06), "#8C47BF")
    x, y = -0.2, 0.6
    m.box((x, y - 0.02, 0.1), (0.08, 0.14, 0.16), "#23242B")
    m.box((x, y, 0.35), (0.09, 0.12, 0.5), "#17181D")
    m.box((x, y + 0.005, 0.66), (0.055, 0.055, 0.2), "#2A2B33")
    m.box((x, y + 0.005, 0.79), (0.08, 0.08, 0.08), "#4DE6FF")  # glowing tip
    m.box((x, y - 0.08, 0.5), (0.04, 0.1, 0.05), "#17181D")
    m.set_muzzle((x, y + 0.005, 0.84))
    m.fit(height=1.6)
    return m


def warlord():
    m = Model("warlord")
    legs(m, "#4A0A10", "#1A1A1F", w=1.4, leg_h=0.28, spread=0.1, thick=0.14)
    torso(m, "#B31420", w=1.45, d=0.32, y0=0.28, belt="#E6B333")
    m.box((0, 0.55, 0.165), (0.3, 0.22, 0.03), "#E6B333")  # gold chest plate
    m.box((0, 0.55, 0.185), (0.12, 0.1, 0.02), "#7A0C14")
    m.box((0, 0.55, -0.19), (0.5, 0.36, 0.08), "#7A0C14")  # cape plate
    for sx in (-1, 1):
        m.ball((sx * 0.4, 0.78, 0), 0.19, "#E6B333", seg=8, rings=3)
        for k, (dx, dz) in enumerate(((0, 0), (0.07, 0.1), (0.07, -0.1))):  # spikes
            m.pyramid((sx * (0.4 + dx), 0.93 - 0.03 * k, dz), (0.08, 0.08), 0.13, "#15151A",
                      rot=(0, 0, -sx * (12 + 22 * (k > 0))))
    # head: black helmet + gold horns
    head(m, eyes="#FFE63B", angry=True, fangs=True, eye_size=(0.07, 0.07), hw=0.52, hh=0.38, hd=0.48)
    m.box((0, 1.2, 0), (0.58, 0.2, 0.54), "#17171C", bevel=0.045)
    m.box((0, 1.12, 0.265), (0.5, 0.035, 0.1), "#0E0E12")
    for sx in (-1, 1):
        m.pyramid((sx * 0.3, 1.2, 0), (0.15, 0.15), 0.24, "#E6B333", rot=(0, 0, -sx * 48))
        m.pyramid((sx * 0.43, 1.37, 0), (0.1, 0.1), 0.2, "#E6B333", rot=(0, 0, -sx * 18))
    # right arm: holds cleaver
    arm(m, -1, (-0.4, 0.70, 0.0), (-0.34, 0.54, 0.24), "#B31420", w=0.14, hand_s=0.14)
    arm(m, 1, (0.4, 0.70, 0.0), (0.45, 0.42, 0.1), "#B31420", w=0.14, hand_s=0.14)
    cx = -0.34
    m.limb((cx, 0.36, 0.24), (cx, 0.68, 0.24), 0.07, "#3A2412")  # handle
    m.box((cx, 0.69, 0.24), (0.1, 0.05, 0.1), "#E6B333")  # guard
    m.box((cx, 0.98, 0.25), (0.08, 0.5, 0.32), "#C5CBD6", bevel=0.015)  # blade
    m.box((cx, 0.98, 0.09), (0.1, 0.5, 0.05), "#8A93A3")  # spine
    m.box((cx, 1.255, 0.25), (0.08, 0.04, 0.3), "#E4E8EF")  # edge highlight
    m.fit(height=3.6)
    return m


def boss_colossus():
    m = Model("boss_colossus")
    steel, light, dark = "#454857", "#5E6277", "#2B2D38"
    core, eye = "#FF8C1A", "#FF4019"
    # legs + feet
    for sx in (-1, 1):
        m.box((sx * 0.95, 0.2, 0.25), (1.35, 0.4, 1.9), dark, bevel=0.1)
        m.box((sx * 0.95, 0.95, 0.0), (1.1, 1.3, 1.1), steel, bevel=0.1)
        m.box((sx * 0.95, 1.5, 0.0), (1.25, 0.2, 1.25), dark)
    # hips + torso
    m.box((0, 1.85, 0), (3.0, 0.7, 1.9), dark, bevel=0.1)
    m.box((0, 3.3, 0), (3.1, 2.4, 2.1), steel, bevel=0.15)
    m.box((0, 2.5, 1.0), (2.2, 0.5, 0.2), dark)  # abdomen band
    for i in range(5):
        m.box((-0.8 + i * 0.4, 2.5, 1.12), (0.18, 0.4, 0.05), light)
    m.box((0, 3.35, 1.03), (1.5, 1.5, 0.12), dark, bevel=0.04)  # core frame
    m.box((0, 3.35, 1.11), (1.05, 1.05, 0.12), core)  # energy core
    m.box((0, 3.35, 1.18), (0.45, 0.45, 0.06), "#FFD27A")
    m.box((0, 4.05, 1.06), (2.2, 0.2, 0.1), light)  # chest plate lip
    m.box((0, 4.65, 0), (1.0, 0.45, 1.0), dark)  # neck
    # shoulders, cones, cannons
    for sx in (-1, 1):
        m.box((sx * 1.95, 4.3, 0), (1.4, 1.0, 1.8), light, bevel=0.15)
        for dz in (-0.45, 0.45):
            m.pyramid((sx * 1.95, 4.8, dz), (0.55, 0.55), 0.55, dark, sides=4)
        m.cyl((sx * 1.95, 5.1, 0.95), 0.3, 1.9, "#1F2028", sides=8, rot=(90, 0, 0))
        m.cyl((sx * 1.95, 5.1, 1.95), 0.4, 0.3, dark, sides=8, rot=(90, 0, 0))
        m.cyl((sx * 1.95, 5.1, -0.1), 0.42, 0.5, dark, sides=8, rot=(90, 0, 0))
        # arms
        m.limb((sx * 2.0, 4.0, 0), (sx * 2.1, 2.75, 0.1), 0.95, steel, bevel=0.1)
        m.ball((sx * 2.1, 2.7, 0.1), 0.55, dark, seg=8, rings=3)
        m.limb((sx * 2.1, 2.7, 0.1), (sx * 2.15, 1.7, 0.2), 1.05, steel, d=1.05, bevel=0.1)
        m.ball((sx * 2.15, 1.05, 0.25), 0.7, light, seg=10, rings=4)
        m.box((sx * 2.15, 1.4, 0.2), (1.2, 0.18, 1.2), dark)  # wrist band
    # head
    m.box((0, 5.5, 0), (1.7, 1.25, 1.5), steel, bevel=0.12)
    m.box((0, 5.95, 0.0), (1.8, 0.3, 1.6), dark, bevel=0.06)
    for sx in (-1, 1):
        m.box((sx * 0.45, 5.62, 0.76), (0.55, 0.14, 0.06), eye)  # slit eyes
        m.box((sx * 0.45, 5.62, 0.8), (0.3, 0.06, 0.04), "#FFB09A")
    m.box((0, 5.05, 0.76), (0.9, 0.3, 0.06), dark)  # mouth grille
    for i in range(4):
        m.box((-0.3 + i * 0.2, 5.05, 0.8), (0.07, 0.22, 0.04), light)
    # curved horns
    for sx in (-1, 1):
        m.limb((sx * 0.75, 6.0, 0), (sx * 1.0, 6.4, 0), 0.34, "#B8BCCB", d=0.34)
        m.pyramid((sx * 1.0, 6.35, 0), (0.34, 0.34), 0.45, "#B8BCCB", rot=(0, 0, -sx * 22))
    m.fit(height=6.8)
    return m


SOLDIERS = [rifleman, machine_gunner, sniper, rocket_soldier, medic]
ENEMIES = [grunt, scout, brute, gunner, warlord, boss_colossus]
