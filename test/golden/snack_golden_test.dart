import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen_app/core/theme.dart';
import 'package:hyphen_app/features/auth/auth_state.dart';
import 'package:hyphen_app/features/profile/profile_state.dart';
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

  testWidgets('snack: 안내 — 담담한 캐릭터', (tester) async {
    await shot(tester, 'snack_03_neutral', (ctx) {
      HkSnack.show(ctx, '한 번 더 누르면 앱이 종료됩니다.', mood: MascotMood.neutral);
    });
  });
}
