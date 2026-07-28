# HYPHEN 런처 아이콘 생성기 — BrandLogo(lib/widgets/brand_logo.dart)와 같은 기하로
# mipmap-*/ic_launcher.png 5종을 다시 그린다 (v1.28 리브랜딩, 2026-07-28).
# 사용: python tool/gen_launcher_icon.py
# 원본 로고 사진: docs/brand/hyphen-logo-source.png (사진 목업 — 아이콘엔 벡터 재현 사용)
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android" / "app" / "src" / "main" / "res"
FONT = ROOT / "assets" / "fonts" / "PretendardVariable.ttf"

SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

BG = (250, 250, 250, 255)   # FacingTokens.bg (appkit 뉴트럴)
INK = (24, 24, 27, 255)     # 잉크 블랙

# BrandLogo _MotifPainter 와 동일 비율
FRACS = [0.0, 0.035, 0.07, 0.105]
HEIGHTS = [0.38, 1.0, 0.62, 0.30]


def draw_icon(size: int) -> Image.Image:
    # 4x 슈퍼샘플 → 다운스케일 (앤티앨리어싱)
    s = size * 4
    img = Image.new("RGBA", (s, s), BG)
    d = ImageDraw.Draw(img)

    # 런처 원형 마스크 안전영역(중앙 66%)에 맞춤
    motif_w = s * 0.62
    motif_h = s * 0.20
    t = max(int(s * 0.013), 4)  # BrandLogo 와 동일한 상대 두께 — 바 간격보다 얇게
    x0 = (s - motif_w) / 2
    # 모티프+텍스트 묶음을 수직 중앙 정렬
    text_h = s * 0.115
    gap = s * 0.055
    block_h = motif_h + gap + text_h
    top = (s - block_h) / 2
    baseline = top + motif_h

    # 수평 라인
    d.rectangle([x0, baseline - t, x0 + motif_w, baseline], fill=INK)
    # 바 클러스터 (좌우 대칭)
    for f, hr in zip(FRACS, HEIGHTS):
        bh = (motif_h - t) * hr
        lx = x0 + motif_w * f
        rx = x0 + motif_w - motif_w * f - t
        d.rectangle([lx, baseline - t - bh, lx + t, baseline - t], fill=INK)
        d.rectangle([rx, baseline - t - bh, rx + t, baseline - t], fill=INK)

    # HYPHEN 워드마크
    font = ImageFont.truetype(str(FONT), int(text_h))
    try:
        font.set_variation_by_axes([800])  # Variable ttf — w800
    except Exception:
        pass
    text = "HYPHEN"
    # 자간: 글자별로 그려 tracking 부여
    tracking = int(s * 0.018)
    widths = [d.textlength(c, font=font) for c in text]
    total = sum(widths) + tracking * (len(text) - 1)
    tx = (s - total) / 2
    ty = baseline + gap
    for c, w in zip(text, widths):
        d.text((tx, ty), c, font=font, fill=INK)
        tx += w + tracking

    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    for folder, size in SIZES.items():
        out = RES / folder / "ic_launcher.png"
        draw_icon(size).save(out)
        print(f"OK: {out.relative_to(ROOT)} ({size}px)")


if __name__ == "__main__":
    main()
