# 골든 캡처 갤러리 생성기 — test/golden/goldens/*.png 를 단일 HTML 로 묶는다.
# 사용: python tool/golden_gallery.py [출력경로]   (기본 build/goldens_gallery.html)
# 갱신 순서: flutter test --update-goldens test/golden → python tool/golden_gallery.py
# 골든스탠다드(writeplz-app tool/golden_gallery.py) 패턴의 facing 판.
import base64
import html as html_mod
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GOLDENS = ROOT / "test" / "golden" / "goldens"

# (사이드패널 라벨, 섹션 제목, [(파일 stem, 캡션)])
SECTIONS = [
    ("공통", "공통 — 진입 · 인트로 · 로그인 (v1.29 한글 카피 + 로고 220 통일)", [
        ("common_01_splash", "스플래시 — HYPHEN 로고 · 자동 전환 대기"),
        ("common_02_intro_board", "인트로① WOD 보드 — 오늘의 WOD."),
        ("common_03_intro_earn", "인트로② 레벨·업적 — 기록이 레벨이 된다."),
        ("common_05_signup", "소셜 로그인 — 네이버 아이디 · 구글"),
        ("common_06_claim", "가입 코드 입력 — PC 선등록 회원 연결 (이음새 1)"),
    ]),
    ("온보딩", "온보딩 — 가입 직후 한 화면 (성별 · 경력)", [
        ("onb_01_basic", "기본 정보 — 성별 · CrossFit 경력 (레벨 기준)"),
    ]),
    ("회원 셸", "회원 셸 3탭 (v1.27 3기둥) — 승인된 회원 (HYPHEN CrossFit 서면)", [
        ("member_01_shell_wod", "WOD 탭 (기본) — 코치 오늘 WOD 보드"),
        ("member_02_shell_home", "Home 탭 — 레벨 · 업적 · Milestones"),
        ("member_03_shell_profile", "Profile 탭 — Tier · 바디 · 설정"),
        ("member_04_profile_menu", "Profile 하단 — 신체·설정·메뉴 접힘 (v1.31 아코디언)"),
        ("member_05_profile_menu_open", "Profile 메뉴 펼침 — 표 1개 (계약~이용약관)"),
    ]),
    ("사장", "사장 — 로그인 · 대시보드", [
        ("boss_01_login", "사장 로그인 — PC 계정"),
        ("boss_02_dashboard", "대시보드 — 오늘 예약·출석·만료 임박"),
        ("boss_03_class_roster", "수업 예약자 명단 — 카드 탭 시 (D29)"),
    ]),
    ("상태 변형", "상태 변형 — 빈 · 에러 · 오프라인 · 미가입", [
        ("hist_01_empty", "History — 빈 상태 (신규 가입)"),
        ("state_01_wod_error", "WOD 보드 로드 실패 — 네트워크 에러"),
        ("state_02_wod_nogym", "박스 미가입 — 가입 직후 WOD 탭"),
        ("state_03_home_offline", "Home — OFFLINE 배너"),
        ("state_04_history_error", "History 로드 실패 — Retry"),
    ]),
]

HEAD = """<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>HYPHEN 전 화면 골든 캡처</title>
<style>
  :root{
    --bg:#EFEFF1; --ink:#18181B; --sub:#52525B; --line:#E4E4E7;
    --card:#FFFFFF; --accent:#EE2B2B; --alt:#F5F5F5;
    --nav-active-bg:#FDECEC; --nav-active-ink:#C81E1E;
    --font:"Pretendard Variable",Pretendard,-apple-system,"Segoe UI","Apple SD Gothic Neo","Malgun Gothic",sans-serif;
  }
  @media (prefers-color-scheme: dark){
    :root{ --bg:#131316; --ink:#E4E4E7; --sub:#A1A1AA; --line:#3A3A40; --card:#1D1D21; --alt:#26262B;
           --nav-active-bg:#3A1414; --nav-active-ink:#F87171; }
  }
  *{margin:0;padding:0;box-sizing:border-box}
  body{font-family:var(--font);background:var(--bg);color:var(--ink);letter-spacing:-0.015em;display:flex;min-height:100vh}

  /* ── 좌측 사이드 패널 ── */
  aside{
    width:212px;flex:none;position:sticky;top:0;height:100vh;overflow-y:auto;
    background:var(--card);border-right:1px solid var(--line);padding:24px 14px;
  }
  aside .brand{font-size:17px;font-weight:800;letter-spacing:-0.02em;padding:0 10px 6px}
  aside .sub{font-size:12px;color:var(--sub);padding:0 10px 16px;line-height:1.5}
  aside nav button{
    display:flex;justify-content:space-between;align-items:center;width:100%;
    border:0;background:none;font-family:var(--font);cursor:pointer;text-align:left;
    padding:11px 12px;border-radius:8px;margin-bottom:2px;
    font-size:14px;font-weight:600;letter-spacing:-0.015em;color:var(--sub);
  }
  aside nav button .cnt{font-size:12px;font-weight:500;color:var(--sub);opacity:.7}
  aside nav button.on{background:var(--nav-active-bg);color:var(--nav-active-ink)}
  aside nav button.on .cnt{color:var(--nav-active-ink);opacity:.85}

  /* ── 본문 ── */
  main{flex:1;min-width:0;padding:36px 32px 64px}
  .note{font-size:13px;color:var(--sub);line-height:1.55;margin-bottom:8px;max-width:960px}
  h2{font-size:18px;font-weight:800;letter-spacing:-0.02em;margin:32px 0 16px;
     padding-left:12px;border-left:4px solid var(--accent)}
  .grid{display:flex;flex-wrap:wrap;gap:20px}
  figure{width:264px}
  figure img{width:100%;display:block;border:1px solid var(--line);border-radius:16px;background:#fff}
  figcaption{margin-top:8px;font-size:13px;color:var(--sub);text-align:center;letter-spacing:-0.015em}
  figcaption b{display:block;font-size:14px;color:var(--ink);font-weight:700}

  /* 좁은 화면 — 사이드 패널을 상단 가로 바로 */
  @media (max-width: 820px){
    body{display:block}
    aside{width:auto;height:auto;position:sticky;border-right:0;border-bottom:1px solid var(--line);padding:12px 16px}
    aside .brand,aside .sub{display:none}
    aside nav{display:flex;gap:4px;overflow-x:auto}
    aside nav button{width:auto;white-space:nowrap;margin-bottom:0}
    main{padding:24px 16px 48px}
  }
</style>
</head>
<body>
"""

NOTE = ("골든 테스트(flutter test --update-goldens test/golden) 산출물 — 실제 앱 위젯을 "
        "가짜 백엔드(test/golden/fakes.dart)로 렌더한 실물 픽셀입니다 (갤S22 급 360×780·2x). "
        "데이터는 샘플입니다. UI 를 바꾸면 --update-goldens 재실행 후 이 갤러리를 다시 생성하세요. "
        "v1.29 (2026-07-28): 카피 한글 기본 전환 + 로그인·로딩 화면 통일(BrandLogo 220·FkLoadingScreen) "
        "— 양식 정본 docs/DESIGN-SSOT.md. v1.27 3기둥 집중(게이미피케이션·WOD 보드·프로필) 유지.")

SCRIPT = """<script>
  const btns = document.querySelectorAll('aside nav button');
  const secs = document.querySelectorAll('main section');
  btns.forEach(b => b.addEventListener('click', () => {
    btns.forEach(x => x.classList.toggle('on', x === b));
    secs.forEach(s => {
      s.style.display = (s.dataset.key === b.dataset.key || b.dataset.key === 'all') ? '' : 'none';
    });
    window.scrollTo({top: 0});
  }));
</script>
</body></html>"""


def main() -> None:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "build" / "goldens_gallery.html"
    out.parent.mkdir(parents=True, exist_ok=True)

    total = sum(len(items) for _, _, items in SECTIONS)
    nav = [f'<button class="on" data-key="all">전체 <span class="cnt">{total}</span></button>']
    for i, (label, _, items) in enumerate(SECTIONS):
        nav.append(f'<button data-key="{i}">{label} <span class="cnt">{len(items)}</span></button>')

    parts = [HEAD]
    parts.append('<aside><div class="brand">HYPHEN 화면</div>'
                 '<div class="sub">골든 캡처 갤러리 — 영역을 골라 보세요.</div>'
                 f'<nav>{"".join(nav)}</nav></aside>')
    parts.append(f'<main><p class="note">{NOTE}</p>')

    missing = []
    listed = {stem for _, _, items in SECTIONS for stem, _ in items}
    for i, (_, title, items) in enumerate(SECTIONS):
        parts.append(f'<section data-key="{i}"><h2>{html_mod.escape(title, quote=False)}</h2>\n<div class="grid">')
        for stem, caption in items:
            png = GOLDENS / f"{stem}.png"
            if not png.exists():
                missing.append(stem)
                continue
            b64 = base64.b64encode(png.read_bytes()).decode()
            cap = html_mod.escape(caption, quote=False)
            parts.append(
                f'<figure><img src="data:image/png;base64,{b64}" alt="{cap}">'
                f"<figcaption><b>{cap}</b>{stem}</figcaption></figure>"
            )
        parts.append("</div></section>")
    parts.append("</main>")
    parts.append(SCRIPT)

    out.write_text("\n".join(parts), encoding="utf-8")
    print(f"OK: {out} ({out.stat().st_size // 1024} KB, {total}장)")
    if missing:
        print(f"누락 {len(missing)}장: {', '.join(missing)} — 골든 먼저 갱신 필요")
    # 양방향 검출 — 갤러리 미등재 PNG (workcheck 패턴)
    unlisted = sorted(p.stem for p in GOLDENS.glob("*.png") if p.stem not in listed)
    if unlisted:
        print(f"갤러리 미등재 {len(unlisted)}장: {', '.join(unlisted)} — SECTIONS 에 추가 필요")


if __name__ == "__main__":
    main()
