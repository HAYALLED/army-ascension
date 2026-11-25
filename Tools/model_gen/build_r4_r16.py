"""Chapters 4-16 assets: python3 build_r4_r16.py <project_root>
Writes Assets/Enemy/<role>_rN.glb(+_palette.png) (65 new + 104 recolors) and Assets/Enemy/Bosses/rN_{mini,boss}_*.glb(+_palette.png)."""
import os
import sys
import numpy as np
from glbkit import Model
import enemies_r as E
import minis_r as M
import bosses_r as B

root = sys.argv[1]
ed, bd = f"{root}/Assets/Enemy", f"{root}/Assets/Enemy/Bosses"
os.makedirs(ed, exist_ok=True)
os.makedirs(bd, exist_ok=True)
problems, count = [], 0


def palette_colors(m):
    cols = []
    for _, c in m.parts:
        if c not in cols:
            cols.append(c)
    return cols


def recenter_feet(m):
    allp = np.vstack([p for p, _ in m.parts])
    low = allp[allp[:, 1] < 0.8]
    cx, cz = (low[:, 0].min() + low[:, 0].max()) / 2, (low[:, 2].min() + low[:, 2].max()) / 2
    d = np.array([cx, 0, cz])
    m.parts = [(p - d, c) for p, c in m.parts]
    if m.muzzle is not None:
        m.muzzle = m.muzzle - d


def emit(m, folder, height, tri_cap, need_muzzle):
    global count
    lo, hi = m.bounds()
    info = m.write_glb(f"{folder}/{m.name}.glb")
    with open(f"{folder}/{m.name}_palette.png", "wb") as f:
        f.write(m.palette_png(palette_colors(m)))
    ext = hi - lo
    p = []
    if info["tris"] > tri_cap: p.append(f"tris {info['tris']}>{tri_cap}")
    if abs(lo[1]) > 1e-4: p.append("origin y")
    if abs(ext[1] - height) > 0.01: p.append(f"height {ext[1]:.2f}!={height}")
    if info["colors"] > 256: p.append("colors")
    if need_muzzle and m.muzzle is None: p.append("no Muzzle")
    if p: problems.append((m.name, p))
    count += 1
    return info["tris"]


# enemies: every round (base + recolors share the same builders)
for rnd in sorted(E.FAM_OF_ROUND):
    for role in E.ROLES:
        m = E.make(role, rnd)
        emit(m, ed, E.HEIGHT[role], 2000, role in E.MUZZLE_ROLES)
# minis
for rnd, kind, m in M.make_all():
    recenter_feet(m)
    emit(m, bd, M.TEMPLATES[kind][2], 4000, kind == "gun")
# bosses
for rnd, fn in B.BOSSES:
    m = fn()
    recenter_feet(m)
    emit(m, bd, 9.0 if rnd == 16 else 8.0, 8000, True)
print("files", count, "problems", problems if problems else "none")
