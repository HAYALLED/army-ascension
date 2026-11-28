"""Export + verify the 24 rank-ladder-#3 assets (Daredevil + Cleric): 8 unit glb, 8 passive-area glb, 8 card icons.

    python3 build_rank3.py <out_dir>

Writes  <out_dir>/Assets/Units/<unit>_<rank>.glb (+ _palette.png)
        <out_dir>/Assets/Units/PassiveAreas/<unit>_<rank>_area.glb (+ _area_palette.png)
        <out_dir>/Assets/UI/class_<unit>[_<rank>].png
        <out_dir>/ContactSheets/*.png and <out_dir>/VALIDATION_REPORT_10.txt
Every written file is re-opened with an independent parser (reuses the readers of build_rank2.py); builders are not trusted."""
import os
import sys
import warnings

warnings.filterwarnings("ignore")
import numpy as np
from PIL import Image, ImageDraw

import areas_rank3 as AR
import icons_rank3 as IC
import units_rank3 as UR
import build_rank2 as B

RANKS = B.RANKS
LINES = ("daredevil", "cleric")


def check_icon(path):
    prob = []
    im = Image.open(path)
    if im.size != (128, 128):
        prob.append(f"size {im.size}")
    if im.mode != "RGBA":
        prob.append(f"mode {im.mode}")
    a = np.array(im.convert("RGBA"))
    for x, y in ((0, 0), (127, 0), (0, 127), (127, 127)):
        if a[y, x, 3] != 0:
            prob.append("corner not transparent")
            break
    ys, xs = np.where(a[:, :, 3] > 40)
    pad = min(xs.min(), ys.min(), 127 - xs.max(), 127 - ys.max())
    if pad < 7:
        prob.append(f"padding {pad}px < 8")
    return {"pad": int(pad)}, prob


def main(out):
    unit_dir, area_dir, ui_dir, sheet_dir = (f"{out}/Assets/Units", f"{out}/Assets/Units/PassiveAreas",
                                             f"{out}/Assets/UI", f"{out}/ContactSheets")
    for d in (unit_dir, area_dir, ui_dir, sheet_dir):
        os.makedirs(d, exist_ok=True)
    lines, ok = [], True

    def save_palette(glb, png):
        js, binc = B.read_glb(glb)
        raw, _ = B.palette_image(js, binc)
        open(png, "wb").write(raw)

    lines.append("UNITS (limits: common 600 / rare 750 / super_rare 900 / legend 1100 tris; height 1.30 +-0.01; <= 2 materials; Muzzle in front)")
    for fn in UR.RANK3_UNITS:
        m = fn()
        m.optimize = True
        path = f"{unit_dir}/{m.name}.glb"
        m.write_glb(path, as_unit=True)
        save_palette(path, f"{unit_dir}/{m.name}_palette.png")
        st, prob = B.validate(path, "unit")
        ok &= not prob
        lines.append(f"  {m.name:24s} tris={st['tris']:4d}/{B.LIMIT[B.rank_of(m.name)]:4d} size={st['size']} glow={st['glow%']:4.1f}% "
                     f"colors={st['colors']:3d} muzzle={st.get('muzzle')} {'OK' if not prob else 'PROBLEMS: ' + ', '.join(prob)}")
    lines += ["", "AREAS (radius 1.0, height <= 0.06, <= 400 tris, bottom y=0, 1 mesh, no extra nodes, no downward faces, centered)"]
    for unit, rank in AR.ALL:
        a = AR.build_area(unit, rank)
        path = f"{area_dir}/{a.name}.glb"
        a.write_glb(path)
        save_palette(path, f"{area_dir}/{a.name}_palette.png")
        st, prob = B.validate(path, "area")
        ok &= not prob
        lines.append(f"  {a.name:26s} tris={st['tris']:3d}/400 radius={st['radius']:.4f} height={st['height']:.3f} "
                     f"glow={st['glow%']:4.1f}% colors={st['colors']:2d} {'OK' if not prob else 'PROBLEMS: ' + ', '.join(prob)}")
    lines += ["", "ICONS (128x128 RGBA, transparent corners, >= 8 px padding)"]
    for name in IC.ICONS:
        path = f"{ui_dir}/{name}.png"
        IC.build(name).save(path)
        st, prob = check_icon(path)
        ok &= not prob
        lines.append(f"  {name:30s} padding={st['pad']}px {'OK' if not prob else 'PROBLEMS: ' + ', '.join(prob)}")

    # ---- contact sheets: per line, 4 ranks (color / game-camera silhouette / 64 px thumb) + discs + icons
    F, FS = B.font(16), B.font(12)
    lines += ["", "SILHOUETTE TEST (pixel overlap of flat-black silhouettes from the game camera; < 0.93 = clearly different)"]
    W = 256
    for unit in LINES:
        sheet = Image.new("RGB", (W * 4, 24 + 2 * W + 64 + 20 + 150 + 128 + 24), (236, 238, 242))
        dr = ImageDraw.Draw(sheet)
        masks = []
        for i, rank in enumerate(RANKS):
            p = f"{unit_dir}/{unit}_{rank}.glb"
            dr.text((i * W + 8, 4), f"{unit} / {rank}", fill=(20, 20, 30), font=F)
            sheet.paste(B.render(p, W), (i * W, 24))
            sheet.paste(B.render(p, W, sil=True), (i * W, 24 + W))
            sheet.paste(B.render(p, 64), (i * W + 96, 24 + 2 * W + 8))
            masks.append(B.sil_mask(p))
            sheet.paste(B.render(f"{area_dir}/{unit}_{rank}_area.glb", 140, el=60, scale=140 / 2.15, cy=0.0,
                                 bg=(120, 126, 136), area=True), (i * W + 58, 24 + 2 * W + 76))
            nm = f"class_{unit}" + ("" if rank == "common" else f"_{rank}")
            ic = Image.open(f"{ui_dir}/{nm}.png").convert("RGBA")
            tile = Image.new("RGBA", (128, 128), (200, 204, 214, 255))
            tile.alpha_composite(ic)
            sheet.paste(tile.convert("RGB"), (i * W + 64, 24 + 2 * W + 76 + 150))
        res = [f"{RANKS[i]}->{RANKS[i + 1]} {(masks[i] & masks[i + 1]).sum() / max(1, (masks[i] | masks[i + 1]).sum()):.2f}" for i in range(3)]
        dr.text((8, 24 + 2 * W + 74 - 4 - 0), "silhouette overlap: " + " | ".join(res), fill=(20, 20, 30), font=FS)
        sheet.save(f"{sheet_dir}/unit_{unit}.png")
        lines.append(f"  {unit:10s} " + " | ".join(res))
    C = 210
    big = Image.new("RGB", (C * 4, (C + 22) * 2 + 28), (236, 238, 242))
    dr = ImageDraw.Draw(big)
    for ri, unit in enumerate(LINES):
        for ci, rank in enumerate(RANKS):
            im = B.render(f"{area_dir}/{unit}_{rank}_area.glb", C, el=60, scale=C / 2.15, cy=0.0, bg=(120, 126, 136), area=True)
            big.paste(im, (ci * C, 28 + ri * (C + 22) + 20))
            dr.text((ci * C + 6, 28 + ri * (C + 22) + 3), f"{unit}_{rank}_area", fill=(20, 20, 30), font=FS)
    big.save(f"{sheet_dir}/areas_rank3.png")
    ic_sheet = Image.new("RGBA", (4 * 140, 2 * 140), (200, 204, 214, 255))
    for i, name in enumerate(IC.ICONS):
        ic_sheet.alpha_composite(Image.open(f"{ui_dir}/{name}.png").convert("RGBA"), ((i % 4) * 140 + 6, (i // 4) * 140 + 6))
    ic_sheet.convert("RGB").save(f"{sheet_dir}/icons_rank3.png")
    lines += ["", "ALL OK" if ok else "SOME PROBLEMS"]
    open(f"{out}/VALIDATION_REPORT_10.txt", "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))
    return ok


if __name__ == "__main__":
    main(sys.argv[1])
