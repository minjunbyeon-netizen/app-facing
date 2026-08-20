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
    ("공통", "공통 — 진입 · 인트로 2p · 로그인", [
        ("common_01_splash", "스플래시 — HYPHEN 로고 · 자동 전환 대기"),
        ("common_02_intro_board", "인트로① 수업 보드 — 코치가 올린 수업 내용 + 체육관 공지"),
        ("common_03_intro_earn", "인트로② 레벨 · 업적 — 마지막 장, CTA '시작'"),
        ("common_05_signup", "로그인 — 아이디 · 회원 가입 신청 (소셜은 키 대기로 숨김)"),
        ("common_06_self_signup", "가입 신청① — 이름 · 생년월일 · 성별 · 연락처"),
        ("common_07_self_signup_scrolled",
         "가입 신청② — 경력 3단 · 해온 종목 · 부상 이력 · 아이디 · 비밀번호"),
        ("common_08_member_login", "회원 아이디 로그인 — 기기 바뀜 · 재설치 복귀 경로"),
    ]),
    ("온보딩", "온보딩 — 프로필 수정 경로 (가입 신청서가 같은 값을 받는다)", [
        ("onb_01_basic", "기본 정보 — 성별 · 운동 경력 (레벨 기준)"),
    ]),
    ("회원 셸", "회원 셸 3탭 — 홈 · 수업 · 내 정보 (승인된 회원 · HYPHEN CrossFit 서면)", [
        ("member_01_shell_wod", "수업 탭 (기본) — 그 주 월~일 아코디언 + 그날 수업 예약"),
        ("member_02_shell_home", "홈 탭 — 레벨 · 업적 · 마일스톤"),
        ("member_03_shell_profile", "내 정보 탭 — 회원권 · 내 체육관 · 신체 · 설정 (ENGINE 폐기)"),
        ("member_04_profile_menu", "프로필 하단 — 아코디언 접힘 상태"),
        ("member_05_profile_menu_open", "프로필 메뉴 펼침 — 계약~이용약관 (+최고 기록, v3.4)"),
        ("member_06_result_sheet", "수업 결과 입력 시트 — 완료 표시 탭 → 저장 (동작별 SCALED/RXD, v3.3 — ELITE 제거)"),
        ("member_06b_result_sheet_strength", "결과 시트 Strength 분기 — 최고 무게(kg)+reps 입력 (v3.4 발전 측정)"),
    ]),
    ("회원 심화", "회원 심화 — 셸에서 한 단계 더 (2026-08-19 전 화면 확장)", [
        ("member_07_classes", "수업 예약 — 예약 · 대기 신청 · 마감 (내 정보 '수업' 버튼)"),
        ("member_08_classes_reserved", "수업 예약 — 예약 확정 상태 (취소 진입)"),
        ("member_09_wod_detail", "수업 상세 — RX·Scaled·Beginner 탭 + 라운드 + 내 이전 기록 (v3.4)"),
        ("member_10_coach_ask_sheet", "코치에게 질문 시트 — 오늘 행 '메시지'"),
        ("member_11_messaging", "쪽지 · 공지 피드 — 홈 '더 보기' · 수업 탭 종"),
        ("member_12_achievements_all", "업적 전체 — 해금 · 미해금 카탈로그"),
        ("member_13_achievement_detail", "업적 상세 시트 — 홈 해금 카드 탭"),
        ("member_14_edit_profile", "프로필 수정 — 이름 줄 연필 아이콘"),
        ("member_15_contracts", "전자계약 목록 — SIGNED · WAITING (메뉴 '계약')"),
        ("member_16_goals", "목표 — 빈 상태 (메뉴 '목표')"),
        ("member_17_faq", "FAQ — 시드 10문답"),
        ("member_18_terms", "이용약관"),
        ("member_19_privacy", "개인정보처리방침"),
        ("member_20_strength_board", "1RM 보드 — 리프트별 역대 최고 무게 (내 정보 메뉴 '최고 기록', v3.4)"),
    ]),
    ("코치", "코치 — 로그인 · 대시보드 · 명단 (v3.3 셸 2탭: 예약 현황 · 수업 — 수업 탭은 회원과 동일 화면)", [
        ("boss_01_login", "코치 로그인 — PC 와 같은 아이디"),
        ("boss_02_dashboard", "대시보드(예약 현황 탭) — 오늘 예약·출석·만료 임박 · '회원 관리' → 승인 화면"),
        ("boss_03_class_roster", "수업 예약자 명단 — 카드 탭 시 (D29) · 하단 수업 취소 (G24)"),
        ("boss_04_class_compose", "수업 등록 시트 — '오늘 수업' 헤더 버튼 (G24)"),
        ("coach_01_shell_reservations", "코치 셸 2탭① 예약 현황 — 대시보드 임베드 (v3.3)"),
        ("coach_02_shell_board", "코치 셸 2탭② 수업 — 회원과 동일 보드 (v3.3)"),
        ("boss_05_roster_cancel", "명단 시트 하단 — 수업 취소 버튼 (G24, 폴드 아래)"),
        ("boss_06_compose_datepicker", "수업 등록 — 날짜 선택 다이얼로그 (appClock 고정)"),
        ("boss_07_class_edit", "수업 수정 시트 — 명단 시트 '수업 수정' (G24 2차, 프리필·일시 고정)"),
    ]),
    ("상태 변형", "상태 변형 — 빈 · 에러 · 오프라인 · 미가입", [
        ("hist_01_empty", "History — 빈 상태 (신규 가입)"),
        ("state_01_wod_error", "수업 보드 로드 실패 — 네트워크 에러"),
        ("state_02_wod_nogym", "체육관 미가입 — 가입 직후 수업 탭"),
        ("state_03_home_offline", "Home — OFFLINE 배너"),
        ("state_04_history_error", "History 로드 실패 — Retry"),
        ("state_05_pending", "승인 대기 — 신청 후 코치 승인 전 (셸 전체 차단)"),
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
        "여기 실린 41장은 **지금 회원·코치가 실제로 도달할 수 있는 화면**만 남긴 것입니다 "
        "(2026-08-19 전 화면 확장 — 예약·상세·쪽지·업적·계약·목표·FAQ·약관·코치 셸 2탭·"
        "날짜 선택까지). 진입점이 사라진 화면은 갤러리에서 뺐습니다 — 페이싱 계산기, "
        "Benchmarks·Tier 결과, 인트로 TIER 장. 양식 정본 docs/DESIGN-SSOT.md.")

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
