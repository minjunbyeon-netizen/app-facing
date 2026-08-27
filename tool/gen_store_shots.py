# 스토어 등록용 스크린샷 생성 (구글 플레이 · 2026-08-28 신설).
#
# 골든 PNG(720x1560, 실물 픽셀 렌더)를 그대로 소스로 써서 1080x1920 캔버스에
# 문구 한 줄 + 화면 이미지를 얹는다. 골든이 정본이므로 앱이 바뀌면
# `flutter test --update-goldens test/golden` 뒤 이 스크립트만 다시 돌리면 된다.
#
# 규격 근거: 플레이 콘솔 폰 스크린샷 = 320~3840px, 9:16 비율. 1080x1920 은
# 정확히 9:16 이라 비율 반려를 원천 차단한다 (갤S22 원본 1080x2340 은 9:19.5).
#
# 디자인 룰 (글로벌 design-block): 그라디언트 금지 · 다중 그림자 금지 ·
# 이모지 금지 · 모노스페이스 금지 · 한글 자간 항상 음수.
#
# 실행: python tool/gen_store_shots.py  ->  build/store/phone_NN_*.png

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
GOLDENS = ROOT / "test" / "golden" / "goldens"
OUT = ROOT / "build" / "store"
FONT = ROOT / "assets" / "fonts" / "PretendardVariable.ttf"

W, H = 1080, 1920
BG = "#FAFAFA"          # 앱 bg 와 동일
FG = "#111827"          # 앱 fg
MUTED = "#5B6573"       # 앱 muted
BORDER = "#E5E7EB"      # 앱 border

SHOT_W = 744            # 화면 이미지 폭 (720 원본 대비 살짝 확대)
SHOT_BOTTOM = 30        # 화면 이미지 아래 여백
TITLE_Y = 74
SUB_Y = 166
RADIUS = 26

# (골든 파일명, 제목, 부제)
# 카피 룰: 금지 용어(박스·크로스핏·WOD·헬스·다이어트·건강·쉬운·편리한·누구나·
# 당신·귀하) 금지 · 이모지 금지 · 명사형 간결체.
SHOTS = [
    ("member_02_shell_home", "출석이 쌓이면 등급이 오른다", "레벨·업적·포인트를 홈에서 바로"),
    ("member_01_shell_wod", "이번 주 수업을 한 화면에", "요일별 수업 내용과 시간"),
    ("member_08_classes_reserved", "예약은 폰에서 한 번에", "정원·대기·취소까지"),
    ("member_02b_home_notice", "공지는 홈 맨 위에", "체육관 소식을 놓치지 않게"),
    ("member_11_messaging", "코치와 바로 쪽지", "질문도 답도 앱 안에서"),
    ("member_12_achievements_all", "업적으로 남는 기록", "해금한 순간을 모아서"),
    ("member_03_shell_profile", "회원권과 포인트를 한 곳에", "남은 기간·잔여 횟수 확인"),
]


def font(size: int, weight: str):
    f = ImageFont.truetype(str(FONT), size)
    f.set_variation_by_name(weight)
    return f


def draw_tracked(draw, xy, text, fnt, fill, tracking):
    """자간을 음수로 주며 한 글자씩 그린다 (PIL 은 letter-spacing 이 없다)."""
    x, y = xy
    for ch in text:
        draw.text((x, y), ch, font=fnt, fill=fill)
        x += draw.textlength(ch, font=fnt) + tracking


def tracked_width(draw, text, fnt, tracking):
    if not text:
        return 0
    w = sum(draw.textlength(ch, font=fnt) for ch in text)
    return w + tracking * (len(text) - 1)


def rounded_shot(src: Image.Image, width: int, radius: int) -> Image.Image:
    ratio = width / src.width
    height = round(src.height * ratio)
    img = src.convert("RGB").resize((width, height), Image.LANCZOS)

    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, width - 1, height - 1), radius, fill=255)

    out = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    # 얇은 테두리 1겹 (그림자 금지 — 경계는 선으로만)
    ImageDraw.Draw(out).rounded_rectangle(
        (0, 0, width - 1, height - 1), radius, outline=BORDER, width=2
    )
    return out


def build(index: int, name: str, title: str, sub: str) -> Path:
    src_path = GOLDENS / f"{name}.png"
    if not src_path.exists():
        raise SystemExit(f"골든 없음: {src_path}")

    canvas = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(canvas)

    f_title = font(46, "Bold")
    f_sub = font(28, "Regular")
    # 한글 자간 음수 (글로벌 §2-B-자간): 제목 -0.02em, 본문 -0.015em
    tr_title = -46 * 0.02
    tr_sub = -28 * 0.015

    tw = tracked_width(draw, title, f_title, tr_title)
    draw_tracked(draw, ((W - tw) / 2, TITLE_Y), title, f_title, FG, tr_title)

    sw = tracked_width(draw, sub, f_sub, tr_sub)
    draw_tracked(draw, ((W - sw) / 2, SUB_Y), sub, f_sub, MUTED, tr_sub)

    shot = rounded_shot(Image.open(src_path), SHOT_W, RADIUS)
    y = H - shot.height - SHOT_BOTTOM
    canvas.paste(shot, ((W - SHOT_W) // 2, y), shot)

    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / f"phone_{index:02d}_{name}.png"
    canvas.save(dest, "PNG")
    return dest


def main():
    made = [build(i, *s) for i, s in enumerate(SHOTS, start=1)]
    for p in made:
        im = Image.open(p)
        print(f"{p.relative_to(ROOT)}  {im.width}x{im.height}  {p.stat().st_size // 1024}KB")
    print(f"\n{len(made)}장 · {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
