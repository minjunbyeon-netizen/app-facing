"""Generate halftone grain textures for facing-app (v1.15 VISUAL_CONCEPT).

- grain_subtle.png: 256x256, fine noise, low alpha (runtime opacity 0.04)
- grain_strong.png: 512x512, coarser halftone dots, alpha tuned for opacity 0.12

Both tileable, transparent background, white-ish dots only (monochrome).
"""
from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "textures"
OUT.mkdir(parents=True, exist_ok=True)


def gen_subtle(size: int = 256, seed: int = 1415) -> Image.Image:
    """Fine grain: random 1-2px dots at ~15% density, alpha 60-140."""
    rnd = random.Random(seed)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    total = size * size
    target = int(total * 0.15)
    for _ in range(target):
        x = rnd.randrange(size)
        y = rnd.randrange(size)
        a = rnd.randint(60, 140)
        px[x, y] = (245, 245, 245, a)
    return img


def gen_strong(size: int = 512, seed: int = 2718) -> Image.Image:
    """Coarser halftone-like: 2-3px dots at ~18% density, alpha 120-220 + dust streaks."""
    rnd = random.Random(seed)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    total = size * size
    target = int(total * 0.18)
    for _ in range(target // 4):
        x = rnd.randrange(size)
        y = rnd.randrange(size)
        r = rnd.choice([1, 1, 1, 2, 2, 3])
        a = rnd.randint(120, 220)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=(245, 245, 245, a))
    # a few dust streaks
    for _ in range(8):
        x0 = rnd.randrange(size)
        y0 = rnd.randrange(size)
        dx = rnd.randint(-20, 20)
        dy = rnd.randint(-20, 20)
        a = rnd.randint(60, 120)
        draw.line([x0, y0, x0 + dx, y0 + dy], fill=(245, 245, 245, a), width=1)
    return img


def main() -> None:
    subtle = gen_subtle()
    subtle.save(OUT / "grain_subtle.png", "PNG", optimize=True)
    print(f"wrote {OUT / 'grain_subtle.png'} ({subtle.size})")

    strong = gen_strong()
    strong.save(OUT / "grain_strong.png", "PNG", optimize=True)
    print(f"wrote {OUT / 'grain_strong.png'} ({strong.size})")


if __name__ == "__main__":
    main()
