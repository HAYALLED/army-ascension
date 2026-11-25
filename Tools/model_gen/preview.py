"""Contact sheet: python3 preview.py out.png name1 name2 ...  (auto-framed, 4 views per model)"""
import numpy as np, sys
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
from render import tris_of

def view(ax, tris, az, el, lo, hi):
    a, e = np.radians(az), np.radians(el)
    cam = np.array([np.sin(a)*np.cos(e), np.sin(e), np.cos(a)*np.cos(e)])
    f = -cam; up = np.array([0, 1, 0.]); r = np.cross(f, up); r /= np.linalg.norm(r); u = np.cross(r, f)
    L = np.array([0.4, 0.8, 0.5]); L /= np.linalg.norm(L)
    polys, cols, dep = [], [], []
    for p, n, c, g in tris:
        if np.dot(n, cam) <= -0.02: continue
        polys.append(np.stack([p @ r, p @ u], 1)); dep.append((p @ cam).mean())
        k = 0.5 + 0.5*max(0, np.dot(n, L)); cols.append(np.clip(np.array(c)/255.*k, 0, 1))
    o = np.argsort(dep)
    ax.add_collection(PolyCollection([polys[i] for i in o], facecolors=[cols[i] for i in o], edgecolors=[cols[i] for i in o], linewidths=0.3))
    ctr = (lo + hi) / 2; H = (hi[1]-lo[1]) * 0.62
    cx, cy = ctr @ r, ctr @ u
    ax.set_xlim(cx-H, cx+H); ax.set_ylim(cy-H, cy+H); ax.set_aspect("equal"); ax.axis("off")

def sheet(models, path, views=((0, 8), (180, 30), (40, 22), (-50, 20))):
    n = len(models)
    fig, axs = plt.subplots(n, len(views), figsize=(3.6*len(views), 3.6*n), facecolor="#cfd4da", squeeze=False)
    for i, m in enumerate(models):
        t = tris_of(m); lo, hi = m.bounds()
        for j, (az, el) in enumerate(views):
            ax = axs[i][j]; ax.set_facecolor("#cfd4da"); view(ax, t, az, el, lo, hi)
            if j == 0: ax.set_title(f"{m.name} {m.tri_count()}t", loc="left", fontsize=9)
    plt.tight_layout(); fig.savefig(path, dpi=60); plt.close(fig)

def grid(models, path, ncol=5, az=32, el=18, cell=3.4):
    import math
    n = len(models); nr = math.ceil(n / ncol)
    fig, axs = plt.subplots(nr, ncol, figsize=(cell*ncol, cell*nr), facecolor="#cfd4da", squeeze=False)
    for ax in axs.flat: ax.axis("off")
    for i, m in enumerate(models):
        ax = axs[i // ncol][i % ncol]; lo, hi = m.bounds(); ax.set_facecolor("#cfd4da")
        view(ax, tris_of(m), az, el, lo, hi); ax.set_title(f"{m.name} {m.tri_count()}t", loc="left", fontsize=8)
    plt.tight_layout(); fig.savefig(path, dpi=55); plt.close(fig)
