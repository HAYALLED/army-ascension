"""Quick software preview (no Godot here): python3 render.py -> /home/claude/prev/<name>.png"""
import numpy as np, sys, os
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
from glbkit import hex2rgb

def tris_of(m):
    main = [p for p in m.parts if p[1] != "TINT" and not p[1].startswith("G:")]
    glow = [(p, c[2:]) for p, c in m.parts if c.startswith("G:")]
    cols = []
    for _, c in main + glow:
        if c not in cols: cols.append(c)
    out = []
    for parts, g in ((main, False), (glow, True)):
        if not parts: continue
        pos, nor, uv, idx, colors = m.build_mesh(parts, cols)
        for t in range(0, len(idx), 3):
            ii = idx[t:t+3]
            ci = int(uv[ii[0]][0] * 16)  # u -> color column
            row = int(uv[ii[0]][1] * 16)
            c = colors[row*16+ci]
            out.append((pos[ii], nor[ii[0]], hex2rgb(c), g))
    return out

def view(ax, tris, az, el, extent):
    a, e = np.radians(az), np.radians(el)
    cam = np.array([np.sin(a)*np.cos(e), np.sin(e), np.cos(a)*np.cos(e)])
    f = -cam; up = np.array([0, 1, 0.])
    r = np.cross(f, up); r /= np.linalg.norm(r); u = np.cross(r, f)
    L = np.array([0.4, 0.8, 0.5]); L /= np.linalg.norm(L)
    polys, cols, dep = [], [], []
    for p, n, c, g in tris:
        if np.dot(n, cam) <= -0.02: continue
        x = p @ r; y = p @ u; z = p @ cam
        polys.append(np.stack([x, y], 1)); dep.append(z.mean())
        k = 1.0 if g else 0.5 + 0.5*max(0, np.dot(n, L))
        col = np.array(c)/255.
        col = np.clip(col*k + (0.25*(col) if g else 0), 0, 1)
        cols.append(col)
    o = np.argsort(dep)
    pc = PolyCollection([polys[i] for i in o], facecolors=[cols[i] for i in o],
                        edgecolors=[cols[i] for i in o], linewidths=0.3)
    ax.add_collection(pc); ax.set_aspect("equal")
    cx, cy = extent
    ax.set_xlim(cx-0.9, cx+0.9); ax.set_ylim(-0.05, 1.75); ax.axis("off")

def sheet(models, path, cols=3):
    n = len(models)
    fig, axs = plt.subplots(n, 4, figsize=(15, 4.2*n), facecolor="#d8d8d8", squeeze=False)
    for i, m in enumerate(models):
        t = tris_of(m)
        for j, (az, el) in enumerate(((0, 8), (180, 35), (40, 22), (200, 18))):
            ax = axs[i][j]; ax.set_facecolor("#d8d8d8")
            view(ax, t, az, el, (0, 0))
            if j == 0: ax.set_title(m.name, loc="left", fontsize=11)
    plt.tight_layout(); fig.savefig(path, dpi=70); plt.close(fig)

if __name__ == "__main__":
    import units
    os.makedirs("/home/claude/prev", exist_ok=True)
    sheet([units.rifleman(), units.sniper()], "/home/claude/prev/base.png")
