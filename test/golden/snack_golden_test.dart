import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen_app/core/theme.dart';
import 'package:hyphen_app/features/auth/auth_state.dart';
import 'package:hyphen_app/features/profile/profile_state.dart';
import 'package:hyphen_app/features/classes/class_flows.dart';
import 'package:hyphen_app/features/gym/wod_result_sheet.dart';
import 'package:hyphen_app/widgets/hkit.dart';
import 'package:hyphen_app/widgets/mascot.dart';

import 'fakes.dart';
import 'harness.dart';

/// 스낵바 3종 골든 — 캐릭터가 성격별로 붙는 모습을 픽셀로 고정한다.
/// (2026-08-21 캐릭터 도입. 스낵바는 잠깐 떴다 사라져 다른 골든에 안 잡힌다.)
void main() {
  Future<void> shot(
    WidgetTester tester,
    String name,
    void Function(BuildContext) fire,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      harness(
        api: FakeApi(memberWorld()),
        auth: AuthState(),
        profile: ProfileState(),
        home: Scaffold(
          backgroundColor: HyphenTokens.bg,
          body: Builder(
            builder: (ctx) {
              // 첫 프레임 뒤 발사 — showSnackBar 는 Scaffold 가 붙은 뒤라야 뜬다.
              WidgetsBinding.instance.addPostFrameCallback((_) => fire(ctx));
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    await capture(tester, name);
  }

  testWidgets('snack: 완료 — 웃는 캐릭터', (tester) async {
    await shot(tester, 'snack_01_happy', (ctx) {
      HkSnack.show(ctx, '기록 저장. 출석 +1 · +100P', mood: MascotMood.happy);
    });
  });

  testWidgets('snack: 실패 — 우는 캐릭터', (tester) async {
    await shot(tester, 'snack_02_sad', (ctx) {
      HkSnack.error(ctx, '저장 실패. 다시 시도.');
    });
  });

  // D86 (2026-08-29) — 예약 완료: 굵은 제목 + 안내 두 줄 (문구 정본 = class_flows.dart).
  testWidgets('snack: 예약 완료 — 세 줄', (tester) async {
    await shot(tester, 'snack_04_reserved', (ctx) {
      HkSnack.show(
        ctx,
        kReservedTitle,
        detail: kReservedDetail,
        mood: MascotMood.happy,
      );
    });
  });

  // D100 (2026-08-30) — 늦은 취소: 서버 문장(달·몇 회째) 첫 줄이 제목, 나머지 줄 +
  // 차감 문구가 안내 줄. 우는 캐릭터. 렌더링 정본 = class_flows.showCancelResult.
  testWidgets('snack: 늦은 취소 — 서버 토스트', (tester) async {
    await shot(tester, 'snack_05_late_cancel_toast', (ctx) {
      showCancelResult(HkSnack.of(ctx), cancelLateResult());
    });
  });

  testWidgets('snack: 안내 — 담담한 캐릭터', (tester) async {
    await shot(tester, 'snack_03_neutral', (ctx) {
      HkSnack.show(ctx, '한 번 더 누르면 앱이 종료됩니다.', mood: MascotMood.neutral);
    });
  });

  // 2026-08-30 사용자 원문 "수업을 저장중이에요 로딩바 두두둥" — 굵은 제목 + 가로 로딩바,
  // 캐릭터 없음(아직 결과가 아니다). 문구 정본 = wod_result_sheet.dart.
  testWidgets('snack: 저장 중 — 로딩바', (tester) async {
    await shot(tester, 'snack_06_saving', (ctx) {
      HkSnack.of(ctx).progress(kWodSavingTitle);
    });
  });

  // 2026-08-30 사용자 원문 "하이피가 예____ 화이팅!!!!" — 웃는 캐릭터 + 응원 한 줄 +
  // 종전 고지 + 서버 비교 문구.
  testWidgets('snack: 저장 완료 — 하이피 응원', (tester) async {
    await shot(tester, 'snack_07_saved_fighting', (ctx) {
      HkSnack.show(
        ctx,
        kWodSavedCheer,
        detail: [kWodSavedBase, '지난 기록보다 42초 단축 — PR!'],
        mood: MascotMood.happy,
      );
    });
  });
}
