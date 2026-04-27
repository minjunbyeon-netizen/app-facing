# HANDOFF - 2026-04-27 15:30 (v1.19 · QA 차수 1~5 완료)

## 완료 (이번 세션)

### 차수 5 (~30+ 건) — `d99559d`
- **R5 11**: signup/mypage/attendance/avatar/quote_card 하드코드 fontSize → FacingTokens 토큰 매핑
- **B-LG-2**: Tier Roadmap 카테고리 점수 0 표시 무력화 해소 (flat key → nested `g[cat][score]`)
- **Voice 7**: V8/V9 영-한 혼용 조사 결합 제거 (offline_banner, attendance, box_wod, wod_detail, compose, group_management, note_detail unit suffix)
- **MEDIUM 잔여**: 입력 검증(B-IN-1~6, 11), 상태업데이트(B-ST-3, 6, 9), 성능(B-PF-9, 12, 15)
- **LOW 잔여**: B-LW-7 season day, B-LW-9 ▲▼ V4 위반, B-LW-10 intro PopScope, B-LW-12 주간 시작 통일

### 직전 commit 흐름 (참조)
- `5d30d65` v1.19 정밀 검수 — 171개 버그
- `50c0b4d` 차수 1 — CRITICAL+V4+TZ+EX 38건
- `77d5ead` 차수 2 — HIGH 18건
- `730e897` 차수 3+4 — MEDIUM 9 + analyzer 32 + LOW 잡일
- `d99559d` 차수 5 — R5 11 + LG-2 + Voice 7 + MEDIUM/LOW 잔여 ← 본 세션

**총 누적**: 차수 1~5 약 **145+ 건 / 171건** 처리. flutter analyze: No issues found.

## 진행중
- (없음)

## 대기

### QA 잔여 ~25건 (영향 작음)
- B-LW-1 inbox `_agoLabel` MM/DD 표기에 연도 정보 없음
- B-LW-2 inbox group 이름 대신 ID 노출 (그룹 lookup 데이터 plumb 필요)
- B-LW-3 quotes seed.abs() % length int.minValue overflow (이론적)
- B-LW-4 level_system Lv20→Lv21 경계 단위 테스트 부재
- B-LW-5 theme Google Fonts 런타임 fetch 폴백 미보장
- B-LW-6 micro 토큰 크기 문서/코드 불일치 (코드 13sp · CLAUDE.md 11sp 표기)
- B-LW-8 onboarding _lbHintToKgHint replaceFirst 단일 숫자 가정
- B-LW-11 wod_draft _presetNameKo='' fallback 미적용
- B-LW-13 demoUnlockedCodes Phase 2 제거 필요
- B-LW-14 result_screen splits 1개 lastIndexOf -1 분기
- B-LW-15 mypage StatelessWidget context.mounted 무의미
- B-LW-16 connectivity init catch 로깅 부재
- B-LW-17 main.dart Provider .value dispose 책임 분산
- B-LW-18 api_client flushRetryQueue 실패 카운터 부재
- B-LW-19 inbox _isCoach 토글 PostFrameCallback 부재
- B-LW-20 Text overflow 처리 (long display_name)
- B-PF-1~3, 5~8, 10, 16~20 성능 최적화 (Opacity/Gradient 재생성, 더미 fallback 등)
- B-ST-1~14 상태 업데이트 잔여 (B-ST-3,6,9 외 11건)

### Phase 2 백로그 (HANDOFF-2026-04-25 인계)
- 게이미피케이션 확장 (Panel B 20-title, Streak Freeze, 시즌 배지, PR +250 XP, Level Decay, 잠금 해제 모먼트)
- FCM Push, SNS 공유 카드, 영상 폼 분석, Whoop/Garmin OAuth, Cloud 백업, Friends/Follow

## 결정사항 / 주의

### 1. 배포 금지 (CLAUDE.md 최상위)
사용자 명시 "배포해" 전까지 `git push`/Railway/store 금지. 본 세션 commit은 로컬만 (`d99559d` 미푸시).

### 2. R5 fontSize 강제규칙
인라인 `TextStyle(fontSize: N)` 금지. CustomPainter / 가변 사이즈는 `FacingTokens.body.copyWith(fontSize: N)` 패턴 (베이스 토큰 derive).

### 3. gradeResult 키 SSOT
- 백엔드 응답: `{overall_number, overall (label), power.score, olympic.score, ...}` nested
- 프론트엔드 SSOT: **`overall_number`** 키 사용. profile_state `hasGrade` 등 통일 (B-PF-12, B-LG-2 모두 같은 원인)
- mypage `_TierRoadmap` 처럼 nested `g[cat][score]` 추출 필요

### 4. Voice 영-한 혼용 패턴
- 한 문장 내 영문+한글 조사 결합 금지 (V9)
- 영문 헤딩 + 한글 캡션 수직 stack 권장 (V10): `'OFFLINE'` + 다음 줄 `'연결 시 동기화.'`
- 단어 1개 라벨 = 마침표 없음 / 1줄 선언 = 마침표 유지 (V1)

## 다음 세션 권장 첫 프롬프트
```
/resume HANDOFF 이어받아 — 게이미피케이션 칭호 업적 확장 작업 시작
```
혹은 QA 잔여 ~25건 (LOW 위주) 마저 처리 후 v1.20 마감.

## 관련 경로

| 역할 | 경로 |
|---|---|
| QA 보고서 (171건 마스터) | `docs/QA/QA-2026-04-27.md` |
| 디자인 토큰 SSOT | `lib/core/theme.dart` (FacingTokens) |
| Profile state | `lib/features/profile/profile_state.dart` |
| Tier Roadmap | `lib/features/mypage/mypage_screen.dart:1097+` |
| Inbox Compose | `lib/features/inbox/compose_note_screen.dart` |
| Group Management | `lib/features/inbox/group_management_screen.dart` |
| 게이미피케이션 코어 | `lib/core/level_system.dart` · `worn_title_store.dart` |
| 업적/칭호 시드 | `services/facing/data/seed_achievements.py` |

## 이전 HANDOFF
- `docs/archive/HANDOFF-2026-04-25.md` (v1.16 Sprint 10–17 완료 + 코칭/박스 소셜)
- `docs/archive/HANDOFF-2026-04-24-v1152.md` (v1.15.2 페르소나)
- `docs/archive/HANDOFF-2026-04-24.md` (v1.15 자산 연결)
