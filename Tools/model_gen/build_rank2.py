"""Export + verify the 20 rank-ladder-#2 unit models and the 40 passive-area markers.

    python3 build_rank2.py <out_dir> [<existing Assets/Units dir for the contact sheets>]

Writes  <out_dir>/Assets/Units/<unit>_<rank>.glb (+ _palette.png)
        <out_dir>/Assets/Units/PassiveAreas/<unit>_<rank>_area.glb (+ _area_palette.png)
        <out_dir>/ContactSheets/*.png and <out_dir>/VALIDATION_REPORT.txt
Verification re-opens every written .glb with an independent parser (struct + json), it does not trust the builders."""
import io
import warnings
import json
import math
import os
import struct
import sys

warnings.filterwarnings('ignore')
import numpy as np
from PIL import Image, ImageDraw, ImageFont

import areas_rank2 as AR
import units_rank2 as UR

LIMIT = {"common": 600, "rare": 750, "super_rare": 900, "legend": 1100}
RANKS = ("common", "rare", "super_rare", "legend")
UNIT_NAMES = ["rifleman", "machine_gunner", "sniper", "rocket_soldier", "medic", "mortar", "weakener", "drummer", "blinder",
              "shield_knight"]
EXISTING = {  # (unit, rank) -> file stem that already exists in Assets/Units (never overwritten)
    ("rifleman", "common"): "rifleman", ("rifleman", "rare"): "rifleman_rare",
    ("machine_gunner", "common"): "machine_gunner", ("machine_gunner", "rare"): "machine_gunner_rare",
    ("sniper", "common"): "sniper", ("sniper", "rare"): "sniper_rare",
    ("rocket_soldier", "common"): "rocket_soldier", ("rocket_soldier", "rare"): "rocket_soldier_rare",
    ("medic", "rare"): "medic", ("medic", "super_rare"): "medic_super_rare",
}
for _u in ("mortar", "weakener", "drummer", "blinder", "shield_knight"):
    EXISTING[(_u, "common")] = f"{_u}_common"
    EXISTING[(_u, "rare")] = f"{_u}_rare"


def rank_of(name):
    for r in ("super_rare", "legend", "common", "rare"):
        if name.endswith("_" + r) or name.endswith("_" + r + "_area"):
            return r


# ======================================================================================= GLB reader
def read_glb(path):
    d = open(path, "rb").read()
    magic, ver, total = struct.unpack_from("<4sII", d, 0)
    assert magic == b"glTF" and ver == 2 and total == len(d), "bad glb header"
    off, js, binc = 12, None, b""
    while off < len(d):
        n, t = struct.unpack_from("<I4s", d, off)
        chunk = d[off + 8:off + 8 + n]
        if t == b"JSON":
            js = json.loads(chunk)
        elif t.startswith(b"BIN"):
            binc = chunk
        off += 8 + n
    return js, binc


def accessor(js, binc, i):
    a = js["accessors"][i]
    v = js["bufferViews"][a["bufferView"]]
    ncomp = {"SCALAR": 1, "VEC2": 2, "VEC3": 3}[a["type"]]
    dt = {5126: np.float32, 5123: np.uint16, 5125: np.uint32}[a["componentType"]]
    start = v.get("byteOffset", 0) + a.get("byteOffset", 0)
    arr = np.frombuffer(binc, dt, a["count"] * ncomp, start)
    return arr.reshape(-1, ncomp) if ncomp > 1 else arr


def palette_image(js, binc):
    v = js["bufferViews"][js["images"][0]["bufferView"]]
    raw = binc[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]]
    return raw, Image.open(io.BytesIO(raw))


def load_tris(path):
    """-> positions (T,3,3), rgb (T,3), glow flag (T,), face normals (T,3)"""
    js, binc = read_glb(path)
    _, img = palette_image(js, binc)
    img = img.convert("RGB")
    P, C, G = [], [], []
    for prim in js["meshes"][0]["primitives"]:
        pos = accessor(js, binc, prim["attributes"]["POSITION"])
        uv = accessor(js, binc, prim["attributes"]["TEXCOORD_0"])
        idx = accessor(js, binc, prim["indices"]).astype(int).reshape(-1, 3)
        glow = "emissiveFactor" in js["materials"][prim["material"]]
        w, h = img.size
        for t in idx:
            P.append(pos[t])
            u, v = uv[t[0]]
            C.append(img.getpixel((min(w - 1, int(u * w)), min(h - 1, int(v * h)))))
            G.append(glow)
    P = np.array(P, float)
    N = np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0])
    N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-12)
    return P, np.array(C, float), np.array(G, bool), N


# ================================================================================== validation
def validate(path, kind):
    """kind = 'unit' or 'area'. Returns (stats dict, list of problems)."""
    prob = []
    js, binc = read_glb(path)
    name = os.path.splitext(os.path.basename(path))[0]
    rank = rank_of(name)
    if len(js["meshes"]) != 1:
        prob.append("meshes != 1")
    if len(js["materials"]) > 2:
        prob.append("materials > 2")
    if len(js.get("images", [])) != 1:
        prob.append("images != 1")
    for m in js["materials"]:
        if m.get("alphaMode", "OPAQUE") != "OPAQUE":
            prob.append("transparency")
    raw, img = palette_image(js, binc)
    if img.size[0] > 256 or img.size[1] > 256:
        prob.append("palette > 256")
    if img.mode not in ("RGB", "P"):
        prob.append(f"palette mode {img.mode} (alpha?)")
    pos_all, tris = [], 0
    for prim in js["meshes"][0]["primitives"]:
        pos_all.append(accessor(js, binc, prim["attributes"]["POSITION"]))
        tris += js["accessors"][prim["indices"]]["count"] // 3
    P = np.vstack(pos_all)
    lo, hi = P.min(axis=0), P.max(axis=0)
    ext = hi - lo
    st = {"tris": tris, "colors": len(set(img.convert("RGB").getdata())) - 1, "size": tuple(round(float(x), 3) for x in ext)}
    names = [n["name"] for n in js["nodes"]]
    if abs(lo[1]) > 1e-4:
        prob.append(f"bottom y={lo[1]:.4f}")
    for n in js["nodes"]:
        if any(k in n for k in ("rotation", "scale", "matrix")) or "camera" in n:
            prob.append("non-applied transform / camera")
    Pt, C, G, N = load_tris(path)
    area = 0.5 * np.linalg.norm(np.cross(Pt[:, 1] - Pt[:, 0], Pt[:, 2] - Pt[:, 0]), axis=1)
    st["glow%"] = round(100 * float(area[G].sum() / area.sum()), 1)
    if kind == "unit":
        if abs(ext[1] - 1.30) > 0.01:
            prob.append(f"height {ext[1]:.3f}")
        if tris > LIMIT[rank]:
            prob.append(f"tris {tris}>{LIMIT[rank]}")
        if "Muzzle" not in names:
            prob.append("no Muzzle")
        else:
            mz = js["nodes"][names.index("Muzzle")]["translation"]
            st["muzzle"] = tuple(round(x, 2) for x in mz)
            if mz[2] < 0.2:
                prob.append("Muzzle not in front (+Z)")
        if ext[0] > 0.95:
            prob.append(f"width {ext[0]:.2f}")
        if ext[2] > 1.55:
            prob.append(f"depth {ext[2]:.2f}")
        if st["glow%"] > 25:
            prob.append(f"glow {st['glow%']}%>25")
        # outward winding sanity: signed volume of the (open, bottomless) mesh should be positive
        if min(np.sign(np.einsum("ij,ij->i", Pt[:, 0], np.cross(Pt[:, 1], Pt[:, 2])).sum()), 1) < 0:
            prob.append("winding looks inverted")
    else:
        rad = float(np.sqrt(P[:, 0] ** 2 + P[:, 2] ** 2).max())
        st["radius"] = round(rad, 5)
        st["height"] = round(float(hi[1]), 4)
        if abs(rad - 1.0) > 1e-3:
            prob.append(f"radius {rad:.4f}")
        if hi[1] > 0.0601:
            prob.append(f"height {hi[1]:.3f}")
        if tris > 400:
            prob.append(f"tris {tris}>400")
        if len(js["nodes"]) != 1 or "Muzzle" in names:
            prob.append("extra nodes / Muzzle")
        if (N[:, 1] < -0.5).any():
            prob.append("downward faces present")
        if abs((lo[0] + hi[0]) / 2) > 0.01 or abs((lo[2] + hi[2]) / 2) > 0.01:
            prob.append("not centered")
    return st, prob


# ====================================================================================== renderer
def render(path, size=256, el=48, scale=None, cy=0.65, sil=False, area=False, bg=(214, 219, 226)):
    P, C, G, N = load_tris(path)
    e = math.radians(el)
    f = np.array([0.0, -math.sin(e), math.cos(e)])  # camera sits high and BEHIND (-Z), looks toward +Z
    r = np.cross(f, [0, 1, 0])
    r /= np.linalg.norm(r)
    u = np.cross(r, f)
    S = 2
    scale = scale or size / 1.95
    X, Y, D = P @ r, P @ u, P @ f
    ctr_y = np.array([0, cy, 0]) @ u
    img = Image.new("RGB", (size * S, size * S), bg)
    dr = ImageDraw.Draw(img)
    L = np.array([-0.4, 0.8, -0.5])
    L /= np.linalg.norm(L)
    vis = (N @ f) < 0.02
    if area:  # flat decals: painter order by height first (large coplanar fans break pure depth sorting)
        order = np.lexsort((-D.mean(axis=1), np.round(P[:, :, 1].mean(axis=1) * 2000)))
    else:
        order = np.argsort(-D.mean(axis=1))
    for i in order:
        if not vis[i]:
            continue
        pts = [((size / 2 + X[i, k] * scale) * S, (size * 0.5 - (Y[i, k] - ctr_y) * scale) * S) for k in range(3)]
        if sil:
            col = (15, 15, 20)
        else:
            k = 1.0 if G[i] else 0.5 + 0.5 * max(0.0, float(N[i] @ L))
            c = np.clip(C[i] * k + (40 if G[i] else 0), 0, 255)
            col = tuple(int(x) for x in c)
        dr.polygon(pts, fill=col)
    return img.resize((size, size), Image.LANCZOS)


def sil_mask(path):
    im = np.array(render(path, 128, sil=True).convert("L"))
    return im < 60


def font(sz):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


# ========================================================================================== main
def main(out, existing_dir=None):
    unit_dir = f"{out}/Assets/Units"
    area_dir = f"{unit_dir}/PassiveAreas"
    sheet_dir = f"{out}/ContactSheets"
    for d in (unit_dir, area_dir, sheet_dir):
        os.makedirs(d, exist_ok=True)
    lines, all_ok = [], True

    def save_palette(glb, png):
        js, binc = read_glb(glb)
        raw, _ = palette_image(js, binc)
        open(png, "wb").write(raw)

    # ---------------- units
    lines.append("UNITS (limits: common 600 / rare 750 / super_rare 900 / legend 1100 tris; height 1.30 +-0.01)")
    for fn in UR.RANK2_UNITS:
        m = fn()
        m.optimize = True
        path = f"{unit_dir}/{m.name}.glb"
        m.write_glb(path, as_unit=True)
        save_palette(path, f"{unit_dir}/{m.name}_palette.png")
        st, prob = validate(path, "unit")
        all_ok &= not prob
        lines.append(f"  {m.name:28s} tris={st['tris']:4d}/{LIMIT[rank_of(m.name)]:4d} size={st['size']} glow={st['glow%']:4.1f}% "
                     f"colors={st['colors']:3d} muzzle={st.get('muzzle')} {'OK' if not prob else 'PROBLEMS: ' + ', '.join(prob)}")
    # ---------------- areas
    lines.append("")
    lines.append("AREAS (radius 1.0, height <= 0.06, <= 400 tris, bottom y=0, 1 mesh, no extra nodes)")
    for unit, rank in AR.ALL:
        a = AR.build_area(unit, rank)
        path = f"{area_dir}/{a.name}.glb"
        a.write_glb(path)
        save_palette(path, f"{area_dir}/{a.name}_palette.png")
        st, prob = validate(path, "area")
        all_ok &= not prob
        lines.append(f"  {a.name:34s} tris={st['tris']:3d}/400 radius={st['radius']:.4f} height={st['height']:.3f} "
                     f"glow={st['glow%']:4.1f}% colors={st['colors']:2d} {'OK' if not prob else 'PROBLEMS: ' + ', '.join(prob)}")

    # ---------------- contact sheets: units (4 ranks in a row: color / silhouette / 64 px)
    F, FS = font(16), font(12)
    lines.append("")
    lines.append("SILHOUETTE TEST (pixel overlap of flat-black silhouettes, game camera; < 0.93 = clearly different)")
    for unit in UNIT_NAMES:
        paths, tag = [], []
        for rank in RANKS:
            new = f"{unit_dir}/{unit}_{rank}.glb"
            if os.path.exists(new):
                paths.append(new)
                tag.append("NEW")
            elif (unit, rank) in EXISTING and existing_dir and os.path.exists(f"{existing_dir}/{EXISTING[(unit, rank)]}.glb"):
                paths.append(f"{existing_dir}/{EXISTING[(unit, rank)]}.glb")
                tag.append("existing")
            else:
                paths.append(None)
                tag.append("missing")
        W = 256
        sheet = Image.new("RGB", (W * 4, 24 + W + W + 64 + 20), (236, 238, 242))
        dr = ImageDraw.Draw(sheet)
        masks = []
        for i, p in enumerate(paths):
            dr.text((i * W + 8, 4), f"{unit} / {RANKS[i]}  [{tag[i]}]", fill=(20, 20, 30), font=F)
            if p is None:
                masks.append(None)
                continue
            sheet.paste(render(p, W), (i * W, 24))
            sheet.paste(render(p, W, sil=True), (i * W, 24 + W))
            sheet.paste(render(p, 64), (i * W + 96, 24 + 2 * W + 8))
            masks.append(sil_mask(p))
        res = []
        for i in range(3):
            if masks[i] is not None and masks[i + 1] is not None:
                a, b = masks[i], masks[i + 1]
                res.append(f"{RANKS[i]}->{RANKS[i + 1]} {(a & b).sum() / max(1, (a | b).sum()):.2f}")
        dr.text((8, 24 + 2 * W + 74), "silhouette overlap: " + " | ".join(res), fill=(20, 20, 30), font=FS)
        sheet.save(f"{sheet_dir}/unit_{unit}.png")
        lines.append(f"  {unit:15s} " + " | ".join(res))
    # ---------------- contact sheet: areas (10 rows x 4 ranks)
    C = 210
    big = Image.new("RGB", (C * 4, (C + 22) * len(UNIT_NAMES) + 28), (236, 238, 242))
    dr = ImageDraw.Draw(big)
    for ri, unit in enumerate(UNIT_NAMES):
        for ci, rank in enumerate(RANKS):
            p = f"{area_dir}/{unit}_{rank}_area.glb"
            im = render(p, C, el=60, scale=C / 2.15, cy=0.0, bg=(120, 126, 136), area=True)
            big.paste(im, (ci * C, 28 + ri * (C + 22) + 20))
            dr.text((ci * C + 6, 28 + ri * (C + 22) + 3), f"{unit}_{rank}_area", fill=(20, 20, 30), font=FS)
    dr.text((8, 6), "passive areas: common | rare | super_rare | legend (game camera, mid-gray floor)", fill=(20, 20, 30), font=F)
    big.save(f"{sheet_dir}/areas_all.png")
    lines.append("")
    lines.append("ALL OK" if all_ok else "SOME PROBLEMS")
    open(f"{out}/VALIDATION_REPORT.txt", "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))
    return all_ok


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
