# App Store 등록용 iPhone 스크린샷 생성 (2026-08-28 신설) — gen_store_shots.py(구글) 와 같은
# 골든 PNG(720x1560)·같은 카피를 쓰되 캔버스만 애플 규격으로 바꾼다.
#
# 규격 근거 (App Store Connect, 2025~): iPhone 6.9" 1320x2868 이 필수 슬롯,
# 6.5" 1284x2778 은 구형 기기 슬롯(6.9" 미제출 시 대체). 둘 다 만든다.
# 골든 비율(9:19.5)이 애플 캔버스 비율과 거의 같아 화면 이미지를 크게 쓸 수 있다.
#
# 실행: python tool/gen_store_shots_ios.py  ->  build/store/ios/{6.9,6.5}/NN_*.png

from pathlib import Path

from PIL import Image, ImageDraw

from gen_store_shots import (BG, FG, GOLDENS, MUTED, ROOT, SHOTS, draw_tracked, font,
                             rounded_shot, tracked_width)

OUT = ROOT / "build" / "store" / "ios"

# (슬롯 이름, 폭, 높이)
TARGETS = [
    ("6.9", 1320, 2868),
    ("6.5", 1284, 2778),
]


def build(target: str, W: int, H: int, index: int, name: str, title: str, sub: str) -> Path:
    src_path = GOLDENS / f"{name}.png"
    if not src_path.exists():
        raise SystemExit(f"골든 없음: {src_path}")

    k = W / 1080  # 구글 캔버스(1080) 대비 배율 — 글자·여백을 같은 비례로
    canvas = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(canvas)

    f_title = font(round(52 * k), "Bold")
    f_sub = font(round(30 * k), "Regular")
    tr_title = -52 * k * 0.02
    tr_sub = -30 * k * 0.015

    title_y = round(150 * k)
    sub_y = title_y + round(92 * k)

    tw = tracked_width(draw, title, f_title, tr_title)
    draw_tracked(draw, ((W - tw) / 2, title_y), title, f_title, FG, tr_title)
    sw = tracked_width(draw, sub, f_sub, tr_sub)
    draw_tracked(draw, ((W - sw) / 2, sub_y), sub, f_sub, MUTED, tr_sub)

    # 화면 이미지 — 캔버스 폭의 78%, 아래 여백은 위 문구 블록과 균형
    shot_w = round(W * 0.78)
    shot = rounded_shot(Image.open(src_path), shot_w, round(34 * k))
    top = sub_y + round(110 * k)
    max_h = H - top - round(40 * k)
    if shot.height > max_h:  # 캔버스가 더 납작한 슬롯이면 폭을 줄여 맞춘다
        shot_w = round(shot_w * max_h / shot.height)
        shot = rounded_shot(Image.open(src_path), shot_w, round(34 * k))
    canvas.paste(shot, ((W - shot.width) // 2, top), shot)

    dest_dir = OUT / target
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / f"{index:02d}_{name}.png"
    canvas.save(dest, "PNG")
    return dest


def main():
    for target, W, H in TARGETS:
        made = [build(target, W, H, i, *s) for i, s in enumerate(SHOTS, start=1)]
        for p in made:
            im = Image.open(p)
            print(f"{p.relative_to(ROOT)}  {im.width}x{im.height}  {p.stat().st_size // 1024}KB")
        print(f"{target}\" · {len(made)}장\n")


if __name__ == "__main__":
    main()
