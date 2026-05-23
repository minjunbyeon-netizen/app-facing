# facing_app

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
