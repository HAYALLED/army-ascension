"""8 card icons (128x128 RGBA, transparent) for Daredevil + Cleric, 4 ranks each.
Drawn at 4x and downsampled. Every shape gets a thick dark-navy outline (same family as the class_*.png set)."""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import distance_transform_edt

S = 4
N = 128 * S
NAVY = (27, 42, 94)


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lighter(c, f=0.35):
    return tuple(int(v + (255 - v) * f) for v in c)


class Icon:
    def __init__(self):
        self.img = Image.new("RGBA", (N, N), (0, 0, 0, 0))

    def _mask(self, fn):
        m = Image.new("L", (N, N), 0)
        fn(ImageDraw.Draw(m), 255)
        return m

    def shape(self, fn, fill, ow=3.0, shine=False):
        """fn(draw, color) draws the shape; ow = outline width in 128-px units."""
        m = self._mask(fn)
        a = np.array(m) > 127
        if ow > 0:
            d = distance_transform_edt(~a)
            out = Image.fromarray(((d <= ow * S) * 255).astype(np.uint8))
            self.img.paste(Image.new("RGBA", (N, N), NAVY + (255,)), (0, 0), out)
        self.img.paste(Image.new("RGBA", (N, N), rgb(fill) + (255,) if isinstance(fill, str) else fill + (255,)), (0, 0), m)
        if shine:  # soft light stripe along the upper-left inside edge
            d = distance_transform_edt(a)
            band = (d > 2.2 * S) & (d < 4.2 * S)
            ys, xs = np.mgrid[0:N, 0:N]
            band &= (xs + ys) < (np.where(a)[1].mean() + np.where(a)[0].mean())
            col = lighter(rgb(fill) if isinstance(fill, str) else fill, 0.45)
            self.img.paste(Image.new("RGBA", (N, N), col + (255,)), (0, 0), Image.fromarray((band * 255).astype(np.uint8)))

    # primitives (coordinates in 128-px units)
    def circ(self, c, r, fill, ow=3.0, shine=False):
        self.shape(lambda d, k: d.ellipse([(c[0] - r) * S, (c[1] - r) * S, (c[0] + r) * S, (c[1] + r) * S], fill=k), fill, ow, shine)

    def poly(self, pts, fill, ow=3.0, shine=False):
        self.shape(lambda d, k: d.polygon([(x * S, y * S) for x, y in pts], fill=k), fill, ow, shine)

    def line(self, p, q, w, fill, ow=3.0):
        dx, dy = q[0] - p[0], q[1] - p[1]
        L = math.hypot(dx, dy)
        nx, ny = -dy / L * w / 2, dx / L * w / 2
        self.poly([(p[0] + nx, p[1] + ny), (q[0] + nx, q[1] + ny), (q[0] - nx, q[1] - ny), (p[0] - nx, p[1] - ny)], fill, ow)

    def rrect(self, box, r, fill, ow=3.0, shine=False):
        self.shape(lambda d, k: d.rounded_rectangle([v * S for v in box], r * S, fill=k), fill, ow, shine)

    def star(self, c, r, fill, ow=1.6, pts=4, inner=0.38, rot=0):
        P = []
        for i in range(pts * 2):
            rr = r if i % 2 == 0 else r * inner
            ang = math.radians(rot - 90 + i * 180 / pts)
            P.append((c[0] + rr * math.cos(ang), c[1] + rr * math.sin(ang)))
        self.poly(P, fill, ow)

    def rays(self, c, r0, r1, n, fill, w=7, ow=0, rot=0):
        for i in range(n):
            a = math.radians(rot + i * 360 / n)
            p = (c[0] + r0 * math.cos(a), c[1] + r0 * math.sin(a))
            q = (c[0] + r1 * math.cos(a), c[1] + r1 * math.sin(a))
            self.line(p, q, w, fill, ow)

    def glow(self, c, r, col, alpha=150):
        g = Image.new("RGBA", (N, N), (0, 0, 0, 0))
        ImageDraw.Draw(g).ellipse([(c[0] - r) * S, (c[1] - r) * S, (c[0] + r) * S, (c[1] + r) * S], fill=rgb(col) + (alpha,))
        g = g.filter(ImageFilter.GaussianBlur(r * S * 0.35))
        self.img = Image.alpha_composite(self.img, g)

    def save(self, path):
        """Fit the artwork into the central 112 px (8 px padding on every side), then downsample to 128."""
        al = np.array(self.img)[:, :, 3]
        ys, xs = np.where(al > 40)
        crop = self.img.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
        k = min(112 * S / crop.width, 112 * S / crop.height)
        crop = crop.resize((max(1, round(crop.width * k)), max(1, round(crop.height * k))), Image.LANCZOS)
        canvas = Image.new("RGBA", (N, N), (0, 0, 0, 0))
        canvas.paste(crop, ((N - crop.width) // 2, (N - crop.height) // 2))
        im = canvas.resize((128, 128), Image.LANCZOS)
        a = np.array(im)
        a[a[:, :, 3] < 8] = 0
        Image.fromarray(a, "RGBA").save(path)


LIME, BLACK, CH = "#C8E61E", "#2B2B33", "#2B2B33"
PUR, GPUR, BLU, GBLU, GOLD, WARM = "#8A3FD1", "#B66BFF", "#2F7BFF", "#56A0FF", "#D9A62E", "#FFF3DC"
ROSE, CREAM, WOOD, STEEL, STEEL2, ORG, ORG2 = "#D9588C", "#F6E7C8", "#9A7440", "#9AA3AE", "#C5CCD6", "#FF8C1A", "#E8832A"


def bomb(ic, c, r, band=None, hl=True):
    ic.circ(c, r, BLACK, shine=False)
    if hl:
        ic.circ((c[0] - r * 0.4, c[1] - r * 0.4), r * 0.2, "#5A6070", ow=0)


def fuse(ic, c, r, tip, spark=ORG):
    x0, y0 = c[0] + r * 0.15, c[1] - r * 0.9
    ic.line((x0, y0 + 3), (x0 + 6, y0 - 8), 5, "#6B5A44", ow=2)
    ic.star((x0 + 9, y0 - 12), 8.5, tip, ow=1.6, pts=4, inner=0.4)


def daredevil(rank):
    ic = Icon()
    if rank == "common":
        ic.circ((64, 64), 53, LIME, shine=True)
        bomb(ic, (64, 74), 28)
        fuse(ic, (64, 74), 28, ORG)
    elif rank == "rare":
        ic.circ((64, 64), 53, LIME, shine=True)
        ic.circ((64, 64), 47, PUR, ow=0)
        ic.circ((64, 64), 43, LIME, ow=0)
        bomb(ic, (64, 74), 28)
        ic.shape(lambda d, k: d.polygon([(S * x, S * y) for x, y in ((37, 70), (91, 70), (93, 82), (35, 82))], fill=k), LIME, ow=2)
        for x in range(40, 96, 12):  # hazard stripes
            ic.poly([(x, 70), (x + 6, 70), (x + 2, 82), (x - 4, 82)], BLACK, ow=0)
        fuse(ic, (64, 74), 28, ORG)
        ic.star((26, 36), 8, GPUR, ow=1.6)
        ic.star((102, 30), 6.5, PUR, ow=1.4)
    elif rank == "super_rare":
        ic.glow((64, 70), 40, GBLU, 90)
        ic.poly([(88, 66), (122, 56), (120, 74), (96, 92), (110, 100), (84, 100)], LIME, ow=2.6)  # scarf
        ic.poly([(100, 63), (113, 59), (112, 70), (104, 75)], BLU, ow=0)
        for sx in (-1, 1):  # side rocket boosters
            cx = 64 + sx * 36
            ic.rrect((cx - 8, 60, cx + 8, 92), 3, "#6E7787", shine=True)
            ic.poly([(cx - 7, 92), (cx + 7, 92), (cx, 112)], GBLU, ow=2.4)
            ic.rrect((cx - 9, 66, cx + 9, 72), 1.5, BLU, ow=2)
        bomb(ic, (64, 76), 30)
        ic.rrect((40, 70, 88, 78), 2, BLU, ow=2)
        ic.line((66, 49), (75, 38), 5, "#6B5A44", ow=2)
        ic.star((79, 31), 11, GBLU, ow=1.8, inner=0.4)
        ic.star((22, 36), 6, GBLU, ow=1.4)
    else:
        ic.glow((64, 60), 56, "#FFD76A", 140)
        ic.rays((64, 64), 40, 62, 12, "#FFD76A", w=6, ow=0, rot=15)
        for p, r in (((18, 26), 8), ((112, 30), 6), ((106, 98), 7), ((20, 96), 5)):
            ic.star(p, r, "#FFD76A", ow=1.4)
        ic.circ((64, 80), 31, "#2B2B33", ow=3)
        ic.rrect((33, 76, 95, 86), 2, GOLD, ow=2.2)  # gold band
        ic.rrect((50, 46, 78, 54), 2, GOLD, ow=2.2)  # gold cap collar
        ic.star((64, 81), 17, WARM, ow=2.0, pts=4, inner=0.42)  # warm star core
        ic.circ((64, 81), 5, "#FFFFFF", ow=0)
        ic.poly([(52, 48), (56, 22), (60, 34), (64, 10), (68, 34), (72, 22), (76, 48)], ORG, ow=2.6)  # flame crest
        ic.poly([(58, 48), (61, 30), (64, 38), (67, 30), (70, 48)], GOLD, ow=0)
        ic.star((94, 66), 5, WARM, ow=1.2)
    return ic


def mace(ic, p0, p1, shaft_col, head_col, head_r, flanged=False, rays=False, ray_col=GOLD):
    ic.line(p0, p1, 8, shaft_col, ow=3)
    if rays:
        ic.rays(p1, head_r + 1, head_r + 9, 8, ray_col, w=7, ow=2.2)
    ic.circ(p1, head_r, head_col, ow=3, shine=not rays)
    if flanged:
        for k in range(4):
            a = math.radians(45 + k * 90)
            ic.poly([(p1[0] + (head_r - 2) * math.cos(a - 0.4), p1[1] + (head_r - 2) * math.sin(a - 0.4)),
                     (p1[0] + (head_r + 8) * math.cos(a), p1[1] + (head_r + 8) * math.sin(a)),
                     (p1[0] + (head_r - 2) * math.cos(a + 0.4), p1[1] + (head_r - 2) * math.sin(a + 0.4))], STEEL, ow=2)


def cleric(rank):
    ic = Icon()
    if rank == "common":
        ic.circ((64, 64), 53, ROSE, shine=True)
        ic.circ((50, 76), 27, CREAM)
        ic.line((38, 76), (62, 76), 8, ROSE, ow=0)
        ic.line((50, 64), (50, 88), 8, ROSE, ow=0)
        mace(ic, (40, 106), (94, 32), WOOD, "#B98A4E", 12)
    elif rank == "rare":
        ic.circ((64, 64), 53, ROSE, shine=True)
        ic.circ((64, 64), 47, PUR, ow=0)
        ic.circ((64, 64), 43, ROSE, ow=0)
        ic.circ((50, 76), 27, CREAM)
        ic.line((38, 76), (62, 76), 8, PUR, ow=0)
        ic.line((50, 64), (50, 88), 8, PUR, ow=0)
        ic.circ((50, 76), 6, GPUR, ow=2)
        mace(ic, (40, 106), (94, 32), "#6E7787", STEEL2, 12, flanged=True)
        ic.star((24, 34), 7.5, GPUR, ow=1.4)
    elif rank == "super_rare":
        ic.glow((64, 62), 46, GBLU, 80)
        for k in range(8):  # sunburst collar
            a = math.radians(k * 45 + 22.5)
            c = (60 + 33 * math.cos(a), 70 + 33 * math.sin(a))
            ic.poly([(60 + 20 * math.cos(a - 0.3), 70 + 20 * math.sin(a - 0.3)), (60 + 44 * math.cos(a), 70 + 44 * math.sin(a)),
                     (60 + 20 * math.cos(a + 0.3), 70 + 20 * math.sin(a + 0.3))], CREAM, ow=2.4)
        ic.circ((60, 70), 19, ROSE)
        ic.rrect((42, 66, 78, 74), 2, BLU, ow=2)
        ic.line((36, 104), (84, 40), 8, STEEL, ow=3)
        ic.rays((84, 40), 12, 22, 8, GBLU, w=7, ow=2.2)
        ic.circ((84, 40), 13, GBLU, ow=3)
        ic.circ((84, 40), 6, "#E2F0FF", ow=0)
        ic.star((20, 30), 6.5, GBLU, ow=1.4)
        ic.star((106, 96), 6, GBLU, ow=1.4)
    else:
        ic.glow((64, 66), 58, "#FFD76A", 140)
        ic.rays((64, 70), 38, 62, 12, "#FFD76A", w=6, ow=0, rot=15)
        # bishop mitre above
        ic.poly([(44, 36), (64, 4), (84, 36)], "#D9588C", ow=2.8)
        ic.rrect((42, 32, 86, 40), 2, GOLD, ow=2.4)
        ic.line((64, 12), (64, 30), 5, GOLD, ow=1.6)
        ic.line((57, 19), (71, 19), 5, GOLD, ow=1.6)
        ic.line((36, 112), (82, 60), 8, GOLD, ow=3)
        ic.rays((82, 60), 14, 24, 8, GOLD, w=8, ow=2.4)
        ic.circ((82, 60), 14, WARM, ow=3)
        ic.circ((82, 60), 6, "#FFFFFF", ow=0)
        ic.star((24, 58), 6, "#FFD76A", ow=1.3)
        ic.star((108, 98), 6, "#FFD76A", ow=1.3)
    return ic


ICONS = {
    "class_daredevil": ("daredevil", "common"), "class_daredevil_rare": ("daredevil", "rare"),
    "class_daredevil_super_rare": ("daredevil", "super_rare"), "class_daredevil_legend": ("daredevil", "legend"),
    "class_cleric": ("cleric", "common"), "class_cleric_rare": ("cleric", "rare"),
    "class_cleric_super_rare": ("cleric", "super_rare"), "class_cleric_legend": ("cleric", "legend"),
}


def build(name):
    unit, rank = ICONS[name]
    return (daredevil if unit == "daredevil" else cleric)(rank)
