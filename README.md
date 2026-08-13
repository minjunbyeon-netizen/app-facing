# hyphen_app

WOD pacing strategy app

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 추후 작업 (deferred to later)

- **W-prime (Critical Power) 페이싱 정밀화** — PHASE4 §2.1. Skiba 2012 모델 기반 회원별 CP·W' 추정 + WOD depletion 시뮬레이션 + split 추천. 한 번 구현·15 pytest 통과까지 갔으나 (`services/facing@4469bb4`) 통합 시점 보류로 revert (`cf06238`). 재시작 시 commit 4469bb4 의 6 파일 (`engine/wprime.py`·`api/wprime.py`·`models/member_wprime.py`·`tests/test_wprime.py` + register 2건) 복원 후 facing-app UI 통합.
- **전자계약서 서명 보내기 (회원 폰 ↔ PC 어드민 양방향 흐름)** — 사장이 PC 에서 계약서 발급 → 회원 폰 SMS·알림톡으로 서명 링크 → 회원 폰에서 서명 → 사장 PC SSE 알림 + signed PDF 자동 보관. 현재 사장 대리 서명 (`POST /api/v1/admin/contracts/<id>/proxy-sign`) 만 구현. 회원 self-sign endpoint (`POST /api/v1/member/contracts/<id>/sign`) 는 device_id 인증 기반으로 존재하지만, 회원 폰 ↔ 알림 전송 ↔ 사장 대시보드 연동 흐름이 빠짐. 작업 범위 크니 별도 phase 배정 권장 (1주+ plan).
