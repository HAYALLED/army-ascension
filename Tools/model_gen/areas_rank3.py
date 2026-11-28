"""8 passive-area floor markers for Daredevil (blast radius) and Cleric (heal zone), 4 ranks each.
Round, radius exactly 1.0 m, height <= 0.06 m, <= 400 tris. Reuses the flat-mesh Area builder of areas_rank2.py
(new file, nothing old is edited)."""
import math
from areas_rank2 import (Area, _pt, GRAY, PURP, GPURP, BLUA, GBLUA, GOLDA, GWARMA, Y_FIELD, Y_RING, Y_ICON)

RANKS = ("common", "rare", "super_rare", "legend")
BLACK, LIME, LIME_L, ORG = "#1E1F25", "#C8E61E", "#E6F77A", "#E8832A"
ROSE, ROSE_L, CREAM, WOOD = "#D9588C", "#E77BA6", "#F6E7C8", "#8A6A3C"
RIM_SR = "#5A6478"
# unit -> (base, alt, field)
UNITS = {"daredevil": (BLACK, LIME_L, LIME), "cleric": (CREAM, WOOD, ROSE)}


def center_icon(a, unit, y0, d1, d2, base, alt):
    ym, yd = y0 + d1, y0 + d1 + d2
    e = 0.002 if d2 > 0.005 else 0.0004
    if unit == "daredevil":
        for k in range(8):  # 8-ray explosion starburst (long rays N/E/S/W, short on the diagonals)
            ln = 0.50 if k % 2 == 0 else 0.40
            a.tri_p(*_pt(0.24 + ln / 2 - 0.02, k * 45), 0.13, ln - 0.1, k * 45, y0, ym, base)
        a.disc(0, 0, 0.27, 12, ym, alt, y0=y0)  # pale plate behind the bomb
        a.disc(0, 0, 0.19, 10, yd, base)  # the round bomb
        a.bar(-0.07, 0.07, 0.09, 0.05, 45, yd + e, "#4A5160")  # highlight
        a.bar(0.1, 0.2, 0.13, 0.04, 40, yd + e, ORG)  # lit fuse
        a.ngon(0.16, 0.26, 0.04, 4, yd + 1.5 * e, "#FF5A1F", a0=45)
    else:  # cleric: sun disc + cut-out plus-cross, mace crossed behind
        a.bar(0, 0, 0.78, 0.07, 40, y0 + 0.004, alt)
        mx, mz = a.loc(0, 0, 40, 0, 0.39)
        a.ngon(mx, mz, 0.075, 8, y0 + 0.006, alt)
        a.disc(0, 0, 0.29, 12, ym, base, y0=y0)
        a.bar(0, 0, 0.30, 0.07, 0, yd, ROSE)
        a.bar(0, 0, 0.07, 0.30, 0, yd, ROSE)


def small_icon(a, unit, r, phi, y, base, alt, idx):
    cx, cz = _pt(r, phi)
    if unit == "daredevil":
        a.ngon(cx, cz, 0.062, 6, y, base)
        fx, fz = a.loc(cx, cz, phi, 0.0, 0.085)
        a.bar(fx, fz, 0.05, 0.03, phi + 40, y + 0.001, ORG)
    else:
        if idx % 2 == 0:  # small mace head: hex + short handle toward the center
            a.ngon(cx, cz, 0.058, 6, y, base)
            hx, hz = a.loc(cx, cz, phi, 0, -0.1)
            a.bar(hx, hz, 0.075, 0.03, phi, y, alt)
        else:  # short sun ray
            a.tri_f(cx, cz, 0.08, 0.16, phi, y, base)


def build_area(unit, rank):
    base, alt, field = UNITS[unit]
    ring = base if unit == "daredevil" else CREAM
    a = Area(f"{unit}_{rank}_area")
    if rank == "legend":
        return _legend(a, unit, base, alt, field, ring)
    if rank == "super_rare":
        a.ring(0.92, 1.0, 0.045, RIM_SR, n=24, segs=range(0, 24, 2), y0=0.0)
        for i in range(0, 24, 2):
            a.ring(0.94, 0.985, 0.0455, BLUA, n=24, segs=[i])
    else:
        a.ring(0.92, 1.0, 0.045, GRAY, n=24, y0=0.0)
    a.disc(0, 0, 0.92, 24, Y_FIELD, field)
    a.ring(0.82, 0.88, Y_RING, ring, n=24)
    center_icon(a, unit, Y_FIELD, 0.014, 0.012, base, alt)
    if rank == "rare":
        a.ring(0.71, 0.76, Y_RING, PURP, n=24)
        for k in range(4):
            x, z = _pt(0.79, 45 + k * 90)
            a.bar(x, z, 0.05, 0.05, 45 + k * 90, Y_RING + 0.002, GPURP)
        for k in range(4):
            small_icon(a, unit, 0.58, k * 90, Y_ICON, base, alt, k * 2 if unit == "cleric" else k)
    elif rank == "super_rare":
        a.ring(0.70, 0.75, Y_RING + 0.001, GBLUA, n=16)
        for k in range(6):
            x, z = _pt(0.79, 30 + k * 60)
            if unit == "daredevil":  # zig-zag shockwave edge
                a.tri_f(x, z, 0.1, 0.075, 30 + k * 60, Y_RING + 0.002, BLUA)
            else:
                a.bar(x, z, 0.05, 0.05, 30 + k * 60, Y_RING + 0.002, BLUA)
            small_icon(a, unit, 0.58, k * 60, Y_ICON, base, alt, k)
    return a


def _legend(a, unit, base, alt, field, ring):
    a.ring(0.90, 1.0, 0.05, GOLDA, n=24, y0=0.0)
    a.disc(0, 0, 0.90, 24, Y_FIELD, field)
    a.ring(0.81, 0.86, 0.04, GOLDA, n=24)
    for k in range(8):
        x, z = _pt(0.74, k * 45)
        a.pyr(x, z, Y_FIELD, 0.075, 0.04, GOLDA, ry=k * 45)
    a.ring(0.62, 0.67, 0.034, GWARMA, n=16)
    lvl2 = "#2A2F39" if unit == "daredevil" else "#B8456F"
    lvl3 = "#E4F56A" if unit == "daredevil" else "#E77BA6"
    a.disc(0, 0, 0.56, 12, 0.032, lvl2, y0=Y_FIELD)
    a.disc(0, 0, 0.40, 12, 0.044, lvl3, y0=0.032, a0=15)
    a.ring(0.31, 0.355, 0.0455, GOLDA, n=12)
    if unit == "daredevil":  # large raised star-shaped bomb emblem
        for k in range(4):
            a.bar(0, 0, 0.62, 0.11, k * 45, 0.0475, GOLDA)
        a.disc(0, 0, 0.17, 10, 0.0535, BLACK, y0=0.0475)
        a.bar(-0.06, 0.06, 0.08, 0.04, 45, 0.0545, "#4A5160")
        a.bar(0.09, 0.18, 0.12, 0.04, 40, 0.0545, ORG)
        a.ngon(0.15, 0.24, 0.04, 4, 0.0555, GWARMA, a0=45)
    else:  # large raised sun-cross emblem
        for k in range(4):
            a.bar(0, 0, 0.62, 0.075, k * 45, 0.0475, GOLDA)
        a.disc(0, 0, 0.22, 12, 0.0535, CREAM, y0=0.0475)
        a.bar(0, 0, 0.30, 0.07, 0, 0.0545, GWARMA)
        a.bar(0, 0, 0.07, 0.30, 0, 0.0545, GWARMA)
    return a


ALL = [(u, r) for u in UNITS for r in RANKS]
