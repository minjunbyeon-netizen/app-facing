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
    # 2026-08-21 — 캐릭터(마스코트) 3종 도입. 스낵바는 잠깐 떴다 사라져
    # 다른 캡처에 안 잡히므로 전용 골든으로 고정한다.
    ("업적 등급", "업적 — 등급 4단 · 판 3모양 · 해금 축하 (픽토그램 팩 v1.0)", [
        ("ach_01_rarities", "등급 4단 + 판 3모양 — 전설은 검은 판, 숨김은 자물쇠"),
        ("ach_02_unlock_toast", "해금 축하 — 컨페티 + 캐릭터 토스트 (전설 금색 테두리)"),
    ]),
    ("스낵바", "스낵바 3종 — 성격별 캐릭터 (HkSnack 단일 창구)", [
        ("snack_01_happy", "완료 — 웃는 얼굴 (저장·적립·예약 완료)"),
        ("snack_02_sad", "실패 — 우는 얼굴 (붉은 테두리)"),
        ("snack_03_neutral", "안내 — 담담한 얼굴 (상태 알림)"),
    ]),
    # v3.3 (2026-08-21): 인트로 2p 삭제 — 화면 코드째 제거 (README §제거된 기능 대장).
    # v3.31 (2026-08-27 사용자 지시): 진입 갈림길 화면 삭제 — 앱을 열면 곧바로
    # 로그인이고, 가입은 그 화면 아래 한 줄이다 (common_05_signup 폐기).
    ("공통", "공통 — 스플래시 · 로그인 (창구 하나)", [
        ("common_01_splash", "스플래시 — 연출 마무리 시점 (v3.8 C안)"),
        ("splash_c1_deck", "스플래시 C안 ① 카드만 — 로고 없이 캐릭터만 쌓인다"),
        ("splash_c2_suck", "스플래시 C안 ② 중앙으로 빨려듦"),
        ("splash_c3_logo", "스플래시 C안 ③ 로고만 — 그 자리에서 피어났다 사라진다"),
        ("common_06_self_signup", "가입 신청① — 이름 · 생년월일 · 성별 · 연락처"),
        ("common_07_self_signup_scrolled",
         "가입 신청② — 경력 3단 · 해온 종목 · 부상 이력 · 아이디 · 비밀번호"),
        ("common_08_login",
         "로그인 — 앱 첫 화면 · 창구 하나 (역할은 서버 판정) + 가입 신청 줄 · 약관"),
    ]),
    ("온보딩", "온보딩 — 프로필 수정 경로 (가입 신청서가 같은 값을 받는다)", [
        ("onb_01_basic", "기본 정보 — 성별 · 운동 경력 (레벨 기준)"),
    ]),
    ("회원 셸", "회원 셸 3탭 — 홈 · 수업 · 내 정보 (승인된 회원 · HYPHEN CrossFit 서면)", [
        ("member_27_shell_history", "히스토리 탭 (D85 · 2026-08-29 4탭) — 셸 상단바 하나 + 검색 칸 + 기록 목록(기본 world 는 0건)"),
        ("member_01_shell_wod", "수업 탭 (기본) — 그 주 월~일 아코디언 + 그날 수업 예약"),
        ("member_02_shell_home", "홈 탭 — 레벨 · 업적 · 마일스톤"),
        ("member_02b_home_notice",
         "홈 공지 아코디언 접힘 — 진짜 공지만 (R7 소스 교체) + 미읽음 점"),
        ("member_02c_home_notice_open",
         "홈 공지 아코디언 펼침 — 핀 고정 우선 + 최신순 3건"),
        ("member_03_shell_profile", "내 정보 탭 — 회원권 · 내 체육관 (v3.10 설정 아코디언 삭제)"),
        ("member_04_profile_menu", "프로필 하단 — 메뉴 표 항상 펼침 · 첫 줄 '체육관 정보' (D83, 2026-08-29)"),
        ("member_06_result_sheet", "수업 결과 입력 시트 — 완료 표시 탭 → 저장 (동작별 SCALED/RXD, v3.3 — ELITE 제거)"),
        ("member_06b_result_sheet_strength", "결과 시트 Strength 분기 — 최고 무게(kg)+reps 입력 (v3.4 발전 측정)"),
    ]),
    ("회원 심화", "회원 심화 — 셸에서 한 단계 더 (2026-08-19 전 화면 확장)", [
        ("member_07_classes",
         "수업 탭 '수업 시간' 칸 — 시간·정원·예약/대기/마감만 (v3.37 기본 진입)"),
        ("member_26_program",
         "수업 탭 '프로그램' 칸 — 그날 프로그램만 (수업 시간 줄 없음, v3.37 분리)"),
        ("member_08_classes_reserved", "수업 예약 — 예약 확정 상태 (취소 진입)"),
        ("member_09_wod_detail", "수업 상세 — RX·Scaled·Beginner 탭 + 라운드 + 내 이전 기록 (v3.4)"),
        ("member_10_coach_ask_sheet", "코치에게 질문 시트 — 오늘 행 '메시지'"),
        ("member_11_messaging", "쪽지 · 공지 피드 — 홈 '더 보기' · 수업 탭 종"),
        ("member_12_achievements_all", "업적 전체 — 분류별 목록 · 전체/진행 중/완료 3칸 · 확인 방식 태그 · 달성 도장 (v3.35 E 안)"),
        ("member_24_trophy_room", "트로피 룸 — 목록 행 탭 → 검은 진열대 + 같은 분류 3열 + 다른 분류 (v3.35)"),
        ("member_25_gym_info", "체육관 정보 화면 — 내 정보 → 메뉴 → 체육관 정보. 이름·주소·전화 · 코치 · 수업 종류(이름+설명, 이벤트 배지) · 수업 시간 · 모토 (D83, 2026-08-29)"),
        ("member_13_achievement_detail", "업적 상세 시트 — 홈 해금 카드 탭"),
        ("member_14_edit_profile", "프로필 수정 — 이름 줄 연필 아이콘"),
        ("member_15_contracts", "전자계약 목록 — SIGNED · WAITING (메뉴 '계약')"),
        # v3.31 (2026-08-27 사용자 지시): 내 정보 메뉴에서 목표·FAQ·고객지원·
        # 데이터 초기화 삭제 — 목표·FAQ 는 화면 코드까지 제거해 골든도 뺐다.
        ("member_18_terms", "이용약관"),
        ("member_19_privacy", "개인정보처리방침"),
        ("member_20_strength_board", "1RM 보드 — 리프트별 역대 최고 무게 (내 정보 메뉴 '최고 기록', v3.4)"),
        ("member_21_challenge_log_sheet", "도전 카드 인증 시트 — 홈 도전 [인증하기] (P3, 1일 1회)"),
        ("member_22_contract_detail",
         "전자계약 상세 — 항목 이름 한글 (서버 사전 variable_labels, 2026-08-25)"),
    ]),
    ("코치", "코치 — 예약 현황 · 명단 (v3.3 셸 2탭: 예약 현황 · 수업 — 수업 탭은 회원과 동일 화면)", [
        ("boss_02_dashboard", "예약 현황 — 오늘 예약·출석 수치 · 오늘 수업 목록 · '가입 신청' 버튼"),
        ("boss_03_class_roster", "수업 예약자 명단 — 카드 탭 시 (D29) · 출석/노쇼 체크만 (v3.21) · 시작 지난 수업"),
        ("coach_01_shell_reservations", "코치 셸 2탭① 예약 현황 — 오늘 수치 · 가입 신청 · 주간 수업/예약 (v3.28)"),
        ("coach_03_shell_messages", "코치 셸 2탭② 쪽지 — MessagingScreen 임베드 (v3.28: 그룹 버튼 삭제)"),
        ("coach_05_member_approvals",
         "가입 신청 — 신청자 연락처를 눌러 바로 전화 (터치 48 확보, 2026-08-28)"),
        ("coach_04_new_note_members", "새 쪽지 — 내 회원 목록에서 받을 사람 선택 → 대화 (v3.28)"),
    ]),
    ("상태 변형", "상태 변형 — 빈 · 에러 · 오프라인 · 미가입", [
        ("hist_01_empty", "히스토리 — 빈 상태 (신규 가입). 검색 칸은 빈 상태에도 서 있다 (D84)"),
        ("hist_02_list", "히스토리 — 기록 목록, 검색어 없음 = 최근순. 제목 = 수업 내용 첫 줄 · 아랫줄 종류·일시 (D84, 2026-08-29)"),
        ("hist_03_search", "히스토리 — 'squat' 검색: 연관도순, Back Squat(최근) · Front Squat 두 건만 (D84)"),
        ("state_01_wod_error", "수업 보드 로드 실패 — 네트워크 에러"),
        ("state_02_wod_nogym", "체육관 미가입 — 가입 직후 수업 탭"),
        ("state_03_home_offline", "Home — OFFLINE 배너"),
        ("state_04_history_error", "History 로드 실패 — Retry"),
        ("state_05_pending", "승인 대기 — 신청 후 코치 승인 전 (셸 전체 차단)"),
        ("state_07_class_ended",
         "종료 수업 카드 — 버튼 숨김 + '종료' 배지 (CLASS_ENDED 게이트 UX)"),
        ("state_08_waitlist_cancel_dialog",
         "대기 취소 다이얼로그 — 대기자 이탈 경로 (G30 픽스)"),
        ("state_09_login_remembered",
         "로그인 — 기억한 아이디 채워진 상태 ('아이디 기억하기 30일', 2026-08-25)"),
        ("state_10_roster_before_start",
         "수업 시작 전 명단 — 출석·노쇼 배지 잠금 + 안내 (S3 픽스, 2026-08-26)"),
        ("state_11_class_membership_required",
         "회원권 없음 — 예약 배지가 '회원권 필요' (S5 MEMBERSHIP_REQUIRED 게이트, 2026-08-26)"),
        ("state_12_coach_logout_dialog",
         "코치 로그아웃 확인 다이얼로그 — 회원 로그아웃과 같은 골격 (S10, 2026-08-26)"),
        ("state_13_signup_back_dialog",
         "가입 폼 뒤로가기 — 입력이 있으면 '작성을 그만둘까요?' (S6, 2026-08-26)"),
        ("state_14_mypage_session_pass",
         "횟수권 — 내 정보 회원권 카드 '2회 남음' · 노쇼/늦은 취소 면제 잔여 (D57, 2026-08-26)"),
        ("state_15_class_booking_not_open",
         "예약 오픈 전 — 모레 수업 '예약' 을 누르면 담담한 캐릭터 스낵바 '예약 가능한 시간이 아니에요' + 둘째 줄 'M/D 11:00 부터' (D58 전날 11시 오픈 · D82 버튼은 살려 두고 누르면 안내, 2026-08-29)"),
        ("state_16_coach_session_expired",
         "코치 세션 만료 — 401 수신 시 로그인 화면 자동 이동 + '로그인이 만료되었습니다' (D59, 2026-08-26)"),
        # v3.33 (2026-08-27) 로그인 고정 레이아웃 — 아래 석 장은 "상태가 달라도
        # 안 밀린다" 의 픽셀 증거다. 좌표 검사는 layout_stability_test.dart.
        ("state_17_login_error",
         "로그인 실패 — 예약된 안내 자리에 서버 문구 (D67 고정 레이아웃, 2026-08-27)"),
        ("state_18_login_validation",
         "빈 칸 제출 — 두 입력칸 검증 에러가 예약된 줄 안에서만 (D67, 2026-08-27)"),
        ("state_19_login_busy",
         "로그인 진행 중 — 버튼을 치우지 않고 그 자리에서 스피너만 (D67, 2026-08-27)"),
        ("state_20_inbox_threads",
         "쪽지함 '코치' 칸 — 사람이 쓴 대화만, 공지 슬롯 채움 (D72 자동 통보 분리, 2026-08-29 / 홈페이지·스토어 소스)"),
        ("state_21_achievements_loading",
         "업적 목록 로딩 — 요약 카드·3칸·분류 라벨·행 자리를 스켈레톤으로 예약, 완료와 y 동일 (v3.35, 2026-08-28)"),
        ("state_22_late_cancel_dialog",
         "늦은 취소 확인 — 시작 20분 전을 지난 취소는 막지 않고 '차감될 수 있음' 한 줄 (테스터 확정, 2026-08-28)"),
        ("state_23_cancel_dialog",
         "평상시 취소 확인 — 20분 전까지는 아무 문구도 붙지 않는다 (state_22 의 짝, 2026-08-28)"),
        ("state_24_notifications_on",
         "알림 받기 켜짐 — 내 정보 한 줄 토글, 종류별로 나누지 않는다 (2026-08-28 사용자 확정)"),
        ("state_26_inbox_activity",
         "쪽지함 '활동' 칸 — 예약·대기 승격·업적·결제·만료 자동 통보만 시간순 (D72, 2026-08-29)"),
        ("state_25_notifications_blocked",
         "폰 설정에서 알림 차단 — 스위치는 내 설정, 색·문구는 실제로 오고 있는지 (state_24 의 짝)"),
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

# 장수는 SECTIONS 에서 계산 — 숫자 하드코딩이 실제 장수와 어긋나던 것을 차단 (§0-B).
def _total_count() -> int:
    return sum(len(items) for _, _, items in SECTIONS)


NOTE = ("골든 테스트(flutter test --update-goldens test/golden) 산출물 — 실제 앱 위젯을 "
        "가짜 백엔드(test/golden/fakes.dart)로 렌더한 실물 픽셀입니다 (갤S22 급 360×780·2x). "
        "데이터는 샘플입니다. UI 를 바꾸면 --update-goldens 재실행 후 이 갤러리를 다시 생성하세요. "
        f"여기 실린 {_total_count()}장은 **지금 회원·코치가 실제로 도달할 수 있는 화면**만 "
        "남긴 것입니다 (2026-08-19 전 화면 확장 — 예약·상세·쪽지·업적·계약·목표·FAQ·약관·"
        "코치 셸 2탭·날짜 선택까지). 진입점이 사라진 화면은 갤러리에서 뺐습니다 — 페이싱 "
        "계산기, Benchmarks·Tier 결과, 인트로. 양식 정본 docs/DESIGN-SSOT.md.")

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
