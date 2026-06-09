# HANDOFF - 2026-06-09 14:31

## 완료 (이번 세션 — 전부 배포·푸시까지 끝남)
- [x] 코치→회원 3채널(공지·와드·쪽지) 전달 검증 — 코드추적 + 실물 API 왕복 + 에뮬레이터 3중
- [x] 메시지 유실 버그 수정 — 코치 'Send Message' 버튼을 GymMessage(MessagesScreen) → GymCoachNote(ChatThreadScreen)로 재연결
- [x] 레거시 GymMessage 시스템 완전 삭제 — 앱(MessagesScreen·GymMessageItem·repo 메서드) + 백엔드(모델·`/gyms/<id>/messages` 라우트)
- [x] 탭 도움말 문구 정정 — Attend = "월별 출석 캘린더·코치 쪽지·박스 공지", Notice = "재활 가이드" (v1.24 피드 이동 반영)
- [x] 백엔드 Railway 배포 — `railway up --service service-facing`, prod 라이브 확인(제거 라우트 404·산 채널 200)
- [x] 릴리즈 APK 배포 — `--dart-define=API_BASE_URL=https://service-facing-production.up.railway.app`로 재빌드, 에뮬레이터 설치 검증(prod 데이터 표시), 폰 전송
- [x] CLAUDE.md 빌드 명령에 `--dart-define=API_BASE_URL` 명시 (localhost 박힘 방지)

## 진행중
- 없음

## 대기 (선택)
- [ ] 갤럭시 S22 실기기에 전송한 APK 설치 후 코치→회원 메시지 최종 확인

## 결정사항 / 주의
- 쪽지는 **GymCoachNote 단일 시스템** (`api/coach_note.py`). GymMessage 폐기.
- 릴리즈 빌드는 **반드시** `--dart-define=API_BASE_URL=<prod>` 주입. 누락 시 `api_client.dart` 기본값 `10.0.2.2:5060`(로컬)로 박힘.
- `gym_messages` 테이블은 DB에 **보존**(코드만 제거, 데이터 유실 방지).
- 회원 메시지 피드 위치 = **Attend 탭 캘린더 아래** (Notice 아님, v1.24 이동).
- 로컬 백엔드(services/facing)가 5060에 떠 있는 상태로 둠. 자동저장 메커니즘이 `.shots` 캡처를 커밋했던 건 gitignore 처리 완료.

## 커밋 (이번 세션, 양쪽 repo origin/master 푸시 완료)
- app-facing: 코치 reroute → GymMessage 제거 → 탭 도움말 정정 → .shots 정리 → CLAUDE.md 빌드 명령
- service-facing: GymMessage 모델·라우트 제거 (Railway 배포됨)

## 다음 세션 권장 첫 프롬프트
`/resume`
