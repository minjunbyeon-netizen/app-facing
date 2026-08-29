# HANDOFF - 2026-08-29 21:08

> 이 세션 주제: **왕복 점검 결함 24건 전부 수정 → 회원 쪽지함 '코치/활동' 분리 → PC 홈 정비 →
> 앱 수업 탭·공지·내 정보 정비.** 하루 종일 한 세션(09:12 ~ 21:08). 브리프 **D70 ~ D81**.
> 3 repo(app-hyphen · service-hyphen · web-hyphen-admin) 전부 커밋·푸시·배포 완료, 워킹트리 깨끗(실측 dirty 0·0·0).
> ⚠ app 저장소는 **공개(public)** — 자격증명·비밀번호 금지 (§2-A-1).

## 한 줄 요약

`pytest tests/` **xfail 0** (504 passed). 앱 `flutter test` **243** · 골든 71장. 빌드 **3019** 폰·에뮬 설치됨.
사용자 결정 대기 **1건**: 회원용 '수업 안내(수업 종류)' 를 어디에 둘지 (아래 §대기 첫 줄).

---

## 완료 (D 번호 순 — 상세는 `docs/ARCHITECTURE_BRIEF.md`)

| D | 내용 | 면 |
|---|---|---|
| D70 | 돈 결함 6건 — **취소 원장 `class_reservation_cancels`** 신설(재예약이 늦은 취소 무료 1회를 되채우던 뿌리) · 미수금 환불 차단 · 가격 수정→결제이력 동기화 · 겹친 회원권 가장 엄한 한도 · 선결제 매출 이중 기준 | 서버·PC |
| D71 | 코치 숫자 4건 — 만료 임박·대기 인원·오늘 예약·수강 이력 총계, 전부 `_metrics.py` 정본으로. **이원화 기준선 3종 0** | 서버 |
| D72 | 회원 쪽지함 **'코치 / 활동'** 두 칸 · 자동 통보 4종 신설(booking·promotion·signup·achievement) · 공지 알림 토글 소비처 복구. 구 D60 개정(채널은 여전히 하나) | 앱·서버 |
| D73 | 나머지 결함 10건 — 공지 원문 보존(저장 escape 제거, PC 렌더 esc) · 페어링 코치 공지 · 회원↔회원 쪽지 차단 · 상태 역행 금지 · 회원권 없으면 수업 내용 잠금 · 회원 출석 `source='self'` · 리워드 스윕 · 탈퇴자 재신청 | 서버·PC |
| D74 | **칭호(Panel B) 일체 제거** — 채울 수 없는 값을 읽어 영영 안 풀리던 기능. 업적으로 통일. 서버 `worn_title` 은 키 있을 때만 갱신 (README 대장 37) | 앱·서버 |
| D75 | PC 홈 **날짜 화살표** (`?date=`, ±365일 밖·잘못된 값은 오늘) | 서버·PC |
| D76 | PC 홈 수업 일정 **시간표 순 아코디언** + 예약자 이름 → 회원 상세 링크 (`reserved_members [{id,name}]`) · PC 토스트 2배 | 서버·PC |
| D77 | 앱 수업 탭 칸 순서 **프로그램 · 수업 시간**, 프로그램이 기본 진입 · 갈 때 오늘 펼침 | 앱 |
| D78 | 프로그램 칸 **첫 수업 시각 순 · 같은 종류 한 번만 · 전부 펼침**, 제목 `AWAKE · FOR TIME` (서버 `first_class_at`·`template_name`) | 앱·서버 |
| D79 | **수업 안내** 회원 노출(체육관 정보 카드 — ⚠ D81 에서 자리 소멸) · **공지 실시간 갱신**(`GymState.announcementsChanged` → `AnnouncementsState.refresh`; 서버 수정·삭제도 SSE). 공지 안 보이던 진짜 원인 = 앱이 첫 응답을 굳힘, 서버 필터는 정상 | 앱·서버 |
| D80 | `HkMarquee` 한 줄 전광판 — 넘칠 때만 흐름 (세 자리 공용, 접근성 존중) | 앱 |
| D81 | 홈 공지 **검정 전광판** `HkMarquee(fill: true)`(짧은 글도 채워 항상 흐름) · 공지는 홈에서만 · 수업 탭 하단 체육관 정보·공지 삭제 · 내 정보 주소·체육관 기록·내 체육관 삭제 (README 대장 38) | 앱 |

### 검증·배포
- 서버 `pytest tests/` **504 passed · 1 skipped · 0 xfailed** (세션 시작 477·24)
- 앱 `flutter test` **243** · `analyze` 0 · 골든 **71장** · PC `design/lint.py` baseline 유지
- 배포: 백엔드·관리자 웹 `railway up` 전부 SUCCESS (마지막 백엔드 20:32 핫픽스)
- 에뮬레이터 실기 회귀 15/15 (로컬 서버, 파괴적 조작 포함) · 갤S22 실기 확인(수업 탭 2칸·쪽지함 2칸·회원권 잠금·프로그램 정렬) · 프로드 읽기 전용 확인 다수
- 실기 SSE = 로컬 서버로 posted/updated/deleted 3종 도착 확인
- 테스터 배포 = `github.com/minjunbyeon-netizen/app-hyphen/releases` — **3014 → 3019** (최신 3019)
- **D81 실화면 캡처는 못 했다** — 폰이 PIN 잠금(Bouncer). APK 는 설치돼 있어 잠금 풀면 홈에서 바로 보인다.

### 20:16 프로드 500 사고 (같은 날 20:32 핫픽스)
- 증상: 폰 "서버 오류" — 수업 탭 열 때마다 `GET /gyms/2/wods` 500. 원인 = D78 코드가 `kst_wall` 을 **import 없이** 씀. **내 실수.**
- 검사 503건이 못 잡은 이유: 그 분기는 `template_id` 있는 글에서만 도는데 검사 데이터엔 없었다.
- 조치: `kst_date` 로 교체 · **그 분기를 반드시 타는 회귀 검사** 추가(옛 코드에서 정확히 그 NameError 로 실패 확인) · 서버 전체 `pyflakes` undefined name 0 · 재발 0.
- **교훈 (다음 세션 강제)**: 서버에 새 분기를 넣으면 그 분기를 타는 데이터로 검사를 같이 넣는다. "전부 초록" 은 그 분기를 한 번도 안 돌렸다는 뜻일 수 있다. 값싼 사전 게이트 = 배포 전 `pyflakes`.

## 진행중

- [ ] 없음. 3 repo 워킹트리 깨끗 (실측: dirty=0 · 0 · 0).

## 대기 (사용자 결정 / 다음 세션)

- [ ] **⚠ 회원용 '수업 안내(수업 종류)' 노출 자리** — D79 에서 체육관 정보 카드에 붙였는데 D81 에서
      그 카드(수업 탭 하단)를 지시로 지우며 **유일한 노출 자리가 사라졌다.** `lib/widgets/gym_info_card.dart`
      (`GymInfoCard` + `_ClassTypesSection`)·모델 `class_template.dart`·저장소 `listClassTemplates`·
      `GymState.classTemplates`·골든 `member_25_gym_info` 는 **전부 보존** — 호출처만 0곳.
      두 지시가 충돌한 자리라 임의로 옮기지 않았다.
      선택지(마지막 응답에서 제시): 내 정보 '메뉴' 안 한 줄(권함) / 홈 전광판 아래 접힌 카드 / 폐기.
- [ ] **미수금 환불 차단만 프로드 미검증** (결제 행이 필요해서. 로컬 실서버·pytest 통과).
- [ ] **매출 결제 축 노출 여부** — 코치가 보는 '이번 달 매출'은 정가 축 하나. D70 에서 합친 결제 축
      두 API(`this_month_revenue`·`net_revenue`)는 어느 화면도 안 쓴다("일단 추후"). 합치는 것은 답이 아님(다른 사실).
- [ ] **짧은 공지 주목** — 사용자 질문에 3안 답한 뒤 D81 '꽉 채워 흐름' 채택. 긴급 폰 알림·PC '긴급/고정' 스위치는 미착수(제안만).
- [ ] 프로드 데이터 2건(이민지(회원 7) 결제 기록 부족·겹친 회원권) · 스토어(개발자 인증 메일·클로즈드 테스터 12명) ·
      공수체크 PC 디자인(별건, `C:\dev\services\workcheck\docs\TODO-PC-DESIGN.md`).

## 결정사항 / 주의

- **오늘 세 번 반복된 결함 유형**: 서버·데이터는 있는데 **화면 경로가 끊김** (칭호 벤치마크 · 결제축 매출 · 수업 안내).
  값싼 신호 = "서버가 주는데 아무도 안 읽는 응답 키" 정규식 스캔(112종 후보 → 진짜 1건). 다음 왕복 점검 갈래 후보.
- **게이트 사각 1종 추가 관측** — 검사가 화면과 **똑같이 틀린 정의**를 쓰면 초록(`test_dashboard_roster` 헬퍼가
  제품 경로로 안 생기는 가짜 상태를 직접 넣고 있었다). 테스트 디렉터리는 린트 밖 — 실질 방어는 제품 창구끼리 값을 맞대는 왕복 검사.
- **한 사실은 한 곳에서만 센다**(대전제 6) — 새로 세는 코드는 `test_ssot_metrics_lint.py` 가 막고, 새 창구는
  `test_ssot_agreement.py` `WINDOWS` 등재 필수. 매출 정가 축 2곳만 baseline 잔존.
- **코치 PC 쪽지함은 안 나눈다** ("할 필요없음"). **칭호 재도입 금지** (업적 하나로 통일).
- **회원 '알림 받기' 토글은 하나** — 쪽지·업적·리마인더 전부 `NotificationService` 관문. 꺼도 쪽지·활동은 조용히 쌓인다.
- **공지는 홈에서만**(D81). 쪽지함 핀 카드는 지시에 없어 그대로(넘침 모드 마키). 공지 0건이면 전광판은 흐르지 않는다(거짓 신호 금지).
- **공지 유효 기간** — PC 에서 기간을 안 넣으면 시작=오늘 00:00·끝=오늘 23:59 → **그날만** 보인다. "안 보인다" 보고가 오면 먼저 기간을 본다.
- **공지 이관은 한 번만 돈다** — 완료 표시 = `audit_logs.action='announcement.unescape_once'`. 두 번 돌면 코치가 진짜로 '&amp;' 라 적은 글이 깨진다.
- **갤S22 무선 adb 주소는 자주 바뀐다** — 하루에 `.41 → .50`. 정본 `tools/phone/last-addr.txt`(현재 `172.30.1.50:5555`).
  안 붙으면 `172.30.1.x` 를 5555 로 훑는다. PIN 잠금(Bouncer)은 adb 로 못 넘긴다 — `statusbar collapse`·BACK 으로 안 풀림.
- APK 는 **프로드 주소로 구워 둔 상태**. 로컬 검증용 `10.0.2.2:5060` 빌드를 쓴 적이 있으니 배포 전 `--dart-define=API_BASE_URL` 확인.
- 서버 pytest 는 `pytest tests/` 경로 명시. 프로드는 읽기 전용(불가피하면 코치 전용 + 즉시 삭제). DB 컬럼·사용자 데이터는 지우지 않는다.
- 앱 커밋 중 훅 auto-save 로 메시지가 `chore: auto-save` 인 것 1개(df46919) — 내용 정확, main 강제 푸시 없이 못 고쳐 그대로.

## 관련 파일

| 영역 | 경로 |
|---|---|
| 취소 원장 | `services/hyphen/models/class_reservation_cancel.py` · `api/_membership.py record_cancel` |
| 마이그레이션 | `services/hyphen/models/base.py _migrate_cancel_ledger · _migrate_unescape_announcements` |
| 세는 함수 정본 | `services/hyphen/api/_metrics.py` |
| 이원화 게이트 | `services/hyphen/tests/test_ssot_metrics_lint.py` · `test_ssot_agreement.py` |
| 왕복 검사 | `services/hyphen/tests/test_roundtrip_*.py` (xfail 0) — `test_roundtrip_program.py` 가 500 회귀 게이트 |
| 자동 통보 정본 | `services/hyphen/api/notifications/note.py` (NOTE_TEMPLATES 8종) |
| 활동/코치 판정 | `services/hyphen/api/coach_note.py _is_conversation · build_activity` |
| 프로그램 정렬 축 | `services/hyphen/api/gym.py list_wods` (`first_class_at`) · 앱 `lib/features/gym/week_board.dart visibleProgram` |
| 공지 갱신 | 앱 `lib/features/gym/gym_state.dart announcementsChanged` · `lib/features/announcements/announcements_state.dart bind(changed:)` |
| 전광판 | 앱 `lib/widgets/hkit.dart HkMarquee` (`fill`) · `test/marquee_test.dart` · 홈 `lib/features/home/home_screen.dart _NoticeAccordion` |
| 앱 쪽지함 2칸 | `apps/facing-app/lib/features/inbox/inbox_screen.dart MessagingFeed` |
| 보존 중(호출처 0) | 앱 `lib/widgets/gym_info_card.dart` · `lib/models/class_template.dart` |
| PC 홈 | `web/facing-admin/templates/dashboard.html` (날짜 화살표·시간표 순·회원 링크) |
| 제거 대장 | `apps/facing-app/README.md §제거된 기능 대장` (37 칭호 · 38 수업 탭 하단·내 정보) |
| 결정 이력 | `apps/facing-app/docs/ARCHITECTURE_BRIEF.md` (D70 ~ D81) |

## 다음 세션 권장 첫 프롬프트

`/resume` → **'수업 안내' 노출 자리 결정**(내 정보 메뉴 / 홈 카드 / 폐기) 후 집행 — 위젯·데이터가 보존돼 있어 붙이기만 하면 된다.
그다음 후보 = "서버가 주는데 아무도 안 읽는 키" 갈래로 왕복 점검 한 벌 더.
