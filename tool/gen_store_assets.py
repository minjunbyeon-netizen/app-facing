# 스토어 등록 에셋 생성 — 앱 아이콘 512x512 + 피처 그래픽 1024x500 (2026-08-28 신설).
#
# 아이콘 기하는 런처 아이콘과 같은 원본을 쓴다 — `gen_launcher_icon.draw_icon` 을
# 그대로 import 해서 크기만 512 로 뽑는다 (사본 기하 금지, §0-B).
# 플레이 콘솔 규격: 아이콘 = 512x512 32bit PNG 투명도 없음 · 피처 그래픽 = 1024x500.
#
# 디자인 룰 (글로벌 design-block): 그라디언트 금지 · 다중 그림자 금지 · 이모지 금지 ·
# 모노스페이스 금지 · 한글 자간 음수.
#
# 실행: python tool/gen_store_assets.py  ->  build/store/icon_512.png, feature_1024x500.png

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))

from gen_launcher_icon import BG, FONT, INK, draw_icon  # noqa: E402

OUT = ROOT / "build" / "store"

FEAT_W, FEAT_H = 1024, 500
MUTED = (91, 101, 115, 255)   # 앱 muted
# 모티프 비율 — gen_launcher_icon 과 동일 원본
FRACS = [0.0, 0.035, 0.07, 0.105]
HEIGHTS = [0.38, 1.0, 0.62, 0.30]

TAGLINE = "공지사항 · 쪽지 · 수업 예약 · 수업 공개"


def font(size: int, weight: str):
    f = ImageFont.truetype(str(FONT), size)
    f.set_variation_by_name(weight)
    return f


def draw_tracked(d, xy, text, fnt, fill, tracking):
    x, y = xy
    for ch in text:
        d.text((x, y), ch, font=fnt, fill=fill)
        x += d.textlength(ch, font=fnt) + tracking


def tracked_width(d, text, fnt, tracking):
    if not text:
        return 0
    return sum(d.textlength(ch, font=fnt) for ch in text) + tracking * (len(text) - 1)


def store_icon() -> Path:
    # 플레이 콘솔 아이콘 규격 = 512x512 "32-bit PNG (with alpha)" 이므로 RGBA 를
    # 유지하되, 알파는 전부 255 로 채워 투명 픽셀이 남지 않게 한다 (모서리 잘림 방지).
    img = draw_icon(512).convert("RGBA")
    img.putalpha(255)
    dest = OUT / "icon_512.png"
    img.save(dest, "PNG")
    return dest


def feature_graphic() -> Path:
    # 4x 슈퍼샘플 후 다운스케일 (아이콘 생성기와 같은 앤티앨리어싱 방식)
    scale = 4
    w, h = FEAT_W * scale, FEAT_H * scale
    img = Image.new("RGB", (w, h), BG[:3])
    d = ImageDraw.Draw(img)

    # --- 모티프 (좌우 바 클러스터 + 수평선) ---
    motif_w = w * 0.30
    motif_h = h * 0.17
    t = max(int(h * 0.011), 4)
    x0 = (w - motif_w) / 2

    f_word = font(int(h * 0.145), "ExtraBold")
    f_tag = font(int(h * 0.052), "Regular")
    tr_word = -int(h * 0.145) * 0.03      # 영문 워드마크도 로고는 음수 트래킹
    tr_tag = -int(h * 0.052) * 0.02       # 한글 본문 자간 음수 (§2-B-자간)

    word_h = int(h * 0.145) * 1.2
    tag_h = int(h * 0.052) * 1.4
    gap1, gap2 = h * 0.055, h * 0.05
    block_h = motif_h + gap1 + word_h + gap2 + tag_h
    top = (h - block_h) / 2
    baseline = top + motif_h

    d.rectangle([x0, baseline - t, x0 + motif_w, baseline], fill=INK[:3])
    for f, hr in zip(FRACS, HEIGHTS):
        bh = motif_h * hr
        for bx in (x0 + motif_w * f, x0 + motif_w * (1 - f) - t):
            d.rectangle([bx, baseline - bh, bx + t, baseline], fill=INK[:3])

    y = baseline + gap1
    ww = tracked_width(d, "HYPHEN", f_word, tr_word)
    draw_tracked(d, ((w - ww) / 2, y), "HYPHEN", f_word, INK[:3], tr_word)

    y += word_h + gap2
    tw = tracked_width(d, TAGLINE, f_tag, tr_tag)
    draw_tracked(d, ((w - tw) / 2, y), TAGLINE, f_tag, MUTED[:3], tr_tag)

    img = img.resize((FEAT_W, FEAT_H), Image.LANCZOS)
    dest = OUT / "feature_1024x500.png"
    img.save(dest, "PNG")
    return dest


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for p in (store_icon(), feature_graphic()):
        im = Image.open(p)
        print(f"{p.relative_to(ROOT)}  {im.width}x{im.height}  {im.mode}  {p.stat().st_size // 1024}KB")


if __name__ == "__main__":
    main()
