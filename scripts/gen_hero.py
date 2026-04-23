"""Generate placeholder hero background images for facing-app (v1.15).

Black/white gradient + noise + vignette. 1080x1920 (9:16).
Five variants seeded differently so each screen feels distinct.
Drop-in replacement for Unsplash CC0 photos; real photos can overwrite later.
"""
from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "images"
OUT.mkdir(parents=True, exist_ok=True)

W, H = 1080, 1920


def radial_gradient(center_x: int, center_y: int, inner: int, outer: int,
                     inner_val: int, outer_val: int) -> Image.Image:
    """Create a grayscale radial gradient L image."""
    img = Image.new("L", (W, H), outer_val)
    px = img.load()
    max_d = outer - inner
    for y in range(H):
        for x in range(W):
            dx = x - center_x
            dy = y - center_y
            d = (dx * dx + dy * dy) ** 0.5
            if d <= inner:
                px[x, y] = inner_val
            elif d >= outer:
                px[x, y] = outer_val
            else:
                t = (d - inner) / max_d
                px[x, y] = int(inner_val + (outer_val - inner_val) * t)
    return img


def add_noise(img: Image.Image, seed: int, strength: int = 18) -> Image.Image:
    rnd = random.Random(seed)
    out = img.copy()
    px = out.load()
    for y in range(H):
        for x in range(W):
            v = px[x, y]
            n = rnd.randint(-strength, strength)
            nv = max(0, min(255, v + n))
            px[x, y] = nv
    return out


def to_rgb(img_l: Image.Image) -> Image.Image:
    return Image.merge("RGB", (img_l, img_l, img_l))


def vignette(img: Image.Image, strength: float = 0.55) -> Image.Image:
    """Darken edges."""
    mask = Image.new("L", (W, H), 0)
    draw = ImageDraw.Draw(mask)
    # bright center ellipse
    draw.ellipse([W * 0.1, H * 0.1, W * 0.9, H * 0.9], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(220))
    black = Image.new("RGB", (W, H), (0, 0, 0))
    return Image.composite(img, black, mask.point(lambda v: int(v * (1 - strength) + 255 * strength)))


def build(seed: int, center: tuple[int, int], inner_val: int, outer_val: int,
          highlight_y: int | None = None) -> Image.Image:
    """Compose a hero: gradient + optional highlight stripe + noise + vignette."""
    grad = radial_gradient(center[0], center[1],
                           inner=int(W * 0.05), outer=int(W * 0.9),
                           inner_val=inner_val, outer_val=outer_val)
    if highlight_y is not None:
        # horizontal soft highlight band (rim light feel)
        band = Image.new("L", (W, H), 0)
        bd = ImageDraw.Draw(band)
        bd.rectangle([0, highlight_y - 40, W, highlight_y + 40], fill=110)
        band = band.filter(ImageFilter.GaussianBlur(60))
        grad = Image.eval(grad, lambda v: v)
        grad = Image.merge("L", (Image.blend(grad, band, 0.25),))
    noised = add_noise(grad, seed=seed, strength=14)
    rgb = to_rgb(noised)
    return vignette(rgb, strength=0.45)


def main() -> None:
    specs = [
        ("hero_splash.jpg",   101, (W // 2, int(H * 0.35)),  60, 6, int(H * 0.30)),
        ("hero_intro_1.jpg",  202, (int(W * 0.65), int(H * 0.25)), 45, 4, int(H * 0.22)),
        ("hero_intro_2.jpg",  303, (int(W * 0.35), int(H * 0.5)),  55, 8, int(H * 0.55)),
        ("hero_intro_3.jpg",  404, (int(W * 0.5), int(H * 0.75)),  38, 3, None),
        ("hero_grade.jpg",    505, (int(W * 0.5), int(H * 0.4)),   50, 5, int(H * 0.40)),
    ]
    for name, seed, center, inner_v, outer_v, hl in specs:
        img = build(seed=seed, center=center, inner_val=inner_v, outer_val=outer_v,
                    highlight_y=hl)
        img.save(OUT / name, "JPEG", quality=82, optimize=True)
        print(f"wrote {OUT / name} ({img.size})")


if __name__ == "__main__":
    main()
