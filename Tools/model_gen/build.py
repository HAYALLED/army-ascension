"""Export all models: python3 build.py <out_dir>  (writes Assets/Units, Assets/Enemy, Assets/Ingame)"""
import os, sys, json
import numpy as np
from glbkit import Model
import units, units_rank, props, env

BUDGET = {"soldier": 900, "rank": 1100, "enemy": 2000, "boss": 8000, "prop": 1500}
HEIGHT = {**{f.__name__: 1.3 for f in units_rank.RANK_UNITS}, "rifleman": 1.3, "machine_gunner": 1.3, "sniper": 1.3, "rocket_soldier": 1.3, "medic": 1.3,
          "grunt": 1.5, "scout": 1.2, "brute": 2.2, "gunner": 1.6, "warlord": 3.6, "boss_colossus": 6.8}
SIZE = {"tree_a": (2.5, 3.5, 2.5), "tree_b": (2.2, 4.5, 2.2), "rock_a": (1.4, 1.0, 1.2), "rock_b": (0.9, 0.7, 0.9),
        "building_a": (6, 7, 6), "building_b": (5, 11, 5), "building_c": (9, 5, 6), "barrier_a": (0.7, 0.85, 2.0),
        "barrier_b": (0.8, 0.8, 2.0), "spike_wall": (3.5, 1.3, 0.9), "gate_pillar": (0.5, 3.6, 0.5),
        "road_tile": (14.4, 0.12, 10), "arena_floor_tile": (14.4, 0.16, 10), "arena_wall_side": (1.4, 5, 10),
        "arena_wall_back": (24, 10, 2), "arena_entrance": (17, 7.5, 1.5), "gate_beam": (14.4, 0.4, 0.5),
        "gate_panel": (6.2, 1.7, 0.25)}

out = sys.argv[1]
report = []
jobs = [("Units", f, "soldier") for f in units.SOLDIERS] + \
       [("Units", f, "rank") for f in units_rank.RANK_UNITS] + \
       [("Enemy", f, "boss" if f.__name__ == "boss_colossus" else "enemy") for f in units.ENEMIES] + \
       [("Ingame", f, "prop") for f in list(props.PROPS.values()) + list(env.ENV.values())]
ok = True
for folder, fn, kind in jobs:
    m = fn()
    m.optimize = m.optimize or folder in ("Units", "Enemy")
    os.makedirs(f"{out}/Assets/{folder}", exist_ok=True)
    path = f"{out}/Assets/{folder}/{m.name}.glb"
    info = m.write_glb(path, as_unit=(kind != "prop"))
    lo, hi = m.bounds()
    ext = hi - lo
    problems = []
    if info["tris"] > BUDGET[kind]: problems.append(f"tris {info['tris']}>{BUDGET[kind]}")
    if abs(lo[1]) > 1e-4: problems.append("origin y")
    tgt_h = HEIGHT.get(m.name) or SIZE[m.name][1]
    if abs(ext[1] - tgt_h) > 0.005: problems.append(f"height {ext[1]:.3f}!={tgt_h}")
    if m.name in SIZE:
        for a, b in zip(ext, SIZE[m.name]):
            if abs(a - b) > 0.01: problems.append(f"size {ext}")
    if m.name == "spike_wall" and abs(ext[0] - 3.5) > 1e-3: problems.append("tile width")
    if info["colors"] > 256: problems.append("colors")
    ok &= not problems
    print(f"{folder:7s} {m.name:15s} tris={info['tris']:5d} (<= {BUDGET[kind]}) colors={info['colors']:3d} "
          f"size=({ext[0]:.2f},{ext[1]:.2f},{ext[2]:.2f}) x-center={((lo[0]+hi[0])/2):+.2f} {info['bytes']//1024}KB "
          f"muzzle={'yes' if m.muzzle is not None else '-'} {'PROBLEMS: ' + ', '.join(problems) if problems else 'ok'}")
print("ALL OK" if ok else "SOME PROBLEMS")
