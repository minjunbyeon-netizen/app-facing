# 테스터 답변 반영 체크리스트 — 2026-08-28

> 테스터 답 9건 중 **이번 차례 = 7 · 9 · 6** (쉽고 꼭 필요).
> 미룸: 1(취소 승인 — 무거움) · 3(4번에 딸림) · 4(FCM) · 5(동작 라이브러리) — 사용자 지시.
> 2(1시간 전 리마인더)는 이미 `reminderLeadMinutes = 60` 으로 되어 있어 할 일 없음.

## 7. 회원권 해지 — 즉시 해지하면 목록에서 사라진다

테스터 원문: "해지 예정이 아닌 해지를 눌렀을 때 목록에서 아예 사라지길 원합니다."

- [x] 해지 모달의 두 갈래를 화면에서 분명히 가른다
      (`templates/member_detail.html` `#cancelModal` — 지금은 select 안에
       '기간 만료 시 해지(추천)' / '즉시 해지' 가 섞여 있어 무엇을 누른 건지
       모른 채 닫힌다)
- [x] **즉시 해지**(`status='cancelled'`) 회원권을 회원권 표 기본 목록에서 제외
- [x] 제외한 것은 '지난 회원권 보기' 접기 안에만 남긴다 (**데이터 삭제 금지**)
- [x] 회원 목록(`templates/members.html`) 회원권 열도 같은 규칙
- [x] 서버 목록 API 가 해지분을 어떻게 내려주는지 확인 —
      선택 규칙은 `api/_membership.py governing_membership` 한 곳만 쓴다
- [x] '해지 예정'(`status='active'` + `cancelled_at`)은 **그대로 남긴다** — 아직 이용 중
- [x] 회귀 테스트: 즉시 해지 후 목록에서 빠지고 지난 회원권에는 남는지

좌표: `services/hyphen/api/admin.py:2925 admin_cancel_membership` ·
`web/facing-admin/templates/member_detail.html:265,796~847` · `members.html:132`

## 9. 전화번호를 눌러 바로 전화

테스터 원문: "전화번호를 눌러서 바로 걸리게 하는 것도 좋은 방법인 것 같습니다."

- [x] 앱 체육관 정보 카드의 전화번호를 탭하면 전화 앱으로
      (`lib/features/gym/box_profile_screen.dart:62~68` — 이미 통화 아이콘이 있다)
- [x] `url_launcher`(설치 완료) `tel:` — 번호에서 숫자 외 문자 제거 후 호출
- [x] 안드로이드 매니페스트 `<queries>` 에 `tel` 인텐트 선언
- [x] 통화 앱이 없는 기기(태블릿 등)에서는 실패 → **번호 복사**로 떨어뜨리고 안내
- [x] 코치가 보는 회원 전화번호도 같은 규칙
      (`lib/features/gym/member_approvals_screen.dart:158`)
- [x] 골든: 표시가 바뀌면 해당 캡처 재생성

## 6. 무슨 수업인지만 보이면 충분

테스터 원문: "무슨 수업인지만 보이면 충분합니다."

- [x] 확인 완료 — **오늘 예약 한 줄**(`today_reservations.dart:112`)과
      **1시간 전 알림**(`notification_service.dart:273`)은 이미 `시각 + 수업 이름` 뿐
- [x] 회원이 보는 수업 줄(`class_line.dart:100~104`)의 곁줄에서 **룸 이름 제거**
- [x] **정원·대기 수는 남긴다** — 자리가 찼는지는 예약을 누를지 정하는 정보다
- [x] 골든 재생성 + 갤러리 등재

## 회귀 검증 (전부 통과해야 끝)

- [x] 서버 `pytest tests/` (경로 명시 필수)
- [x] 앱 `flutter test` · `flutter analyze`
- [x] 골든 `flutter test test/golden` (갱신분은 갱신 후 재실행)
- [x] 관리자 웹 `python design/lint.py` baseline 유지 + Jinja 전 템플릿 컴파일
- [x] 새 테스트는 **옛 코드로 되돌리면 실패하는지** 확인

## 끝나고 할 것

- [x] 3 repo 커밋
- [x] 남은 목록(1·3·4·5) 다시 정리해 제안

---

## 집행 결과 (2026-08-28 19:50)

전부 통과했습니다.

| 검증 | 결과 |
|---|---|
| 서버 `pytest tests/` | 323 passed · 1 skipped (신규 회귀 4건 포함) |
| 앱 `flutter test` | 226 passed |
| 앱 `flutter analyze` | No issues found |
| 관리자 웹 `design/lint.py` | baseline 유지 (exit 0) · 새 CSS 클래스 0개 |
| 골든 | 9장 재생성 · 장수 65장 그대로 |

새 회귀 테스트는 **옛 코드로 되돌리면 2건이 실제로 실패**함을 확인했습니다
(`test_immediate_cancel_disappears_from_list` · `test_cancel_target_matches_the_membership_the_list_shows`).

커밋: app `73680c5` · hyphen `01f948f` · admin `1c203e2` — 3 repo 워킹트리 깨끗.

### 이번에 드러난 것 (요청 밖 · 기록만)
- `lib/features/gym/box_profile_screen.dart` 는 **호출처 0건**입니다. 테스터가 본
  체육관 정보 카드는 `lib/widgets/gym_info_card.dart` 쪽입니다. 도달 불가 화면은
  코드까지 지운다는 정책(v3.2)의 잔여분으로 보이나, 이번엔 지우지 않고 같이
  배선만 해 뒀습니다.
- 전화번호 줄의 터치 높이가 48 에 못 미칩니다(글자 높이 약 22). 인라인 링크로
  판단해 폭만 줄 전체로 넓혔습니다.

### 남은 것
1. 취소 승인 주 1회 (새 표 + API 2개 + 양쪽 화면)
3. 알림 종류별 스위치 — 4번에 딸림
4. FCM (앱 종료 상태 알림)
5. 동작 영상 라이브러리
- 배포: 백엔드·관리자 웹 `railway up` · 앱 APK 3010 빌드
