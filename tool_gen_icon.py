# H-3 (2026-06-10) — 런처 아이콘 생성: 다크 bg(#0A0A0A) + Pretendard "F" + accent 포인트.
# NOBULL 모노 + CrossFit Red 포인트. flutter_launcher_icons 의존성 없이 PIL 직접 생성.
from PIL import Image, ImageDraw, ImageFont

FONT = r"C:\dev\apps\facing-app\assets\fonts\PretendardVariable.ttf"
OUT_BASE = r"C:\dev\apps\facing-app\android\app\src\main\res"
SIZE = 1024

img = Image.new("RGB", (SIZE, SIZE), "#0A0A0A")
d = ImageDraw.Draw(img)

# Variable font — 최대 weight 축 적용 시도 (실패 시 기본)
font = ImageFont.truetype(FONT, 660)
try:
    font.set_variation_by_axes([800])  # wght 800
except Exception:
    pass

# "F" 중앙 배치
bbox = d.textbbox((0, 0), "F", font=font)
w = bbox[2] - bbox[0]
h = bbox[3] - bbox[1]
x = (SIZE - w) / 2 - bbox[0]
y = (SIZE - h) / 2 - bbox[1]
d.text((x, y), "F", font=font, fill="#FFFFFF")

# 우하단 accent 사각 포인트 (CrossFit Red)
d.rectangle([SIZE - 300, SIZE - 184, SIZE - 184, SIZE - 68], fill="#EE2B2B")

img.save(r"C:\dev\apps\facing-app\tool_icon_master.png")

DENSITIES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
for folder, px in DENSITIES.items():
    icon = img.resize((px, px), Image.LANCZOS)
    icon.save(rf"{OUT_BASE}\{folder}\ic_launcher.png")
    print(folder, px, "ok")
