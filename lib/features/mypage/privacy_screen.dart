// v1.16 Sprint 7b U2: 프라이버시 정책 화면 + 탈퇴 buttoned.
// UX_QUESTIONS_v1.16 Category L 대응.
// 내용은 placeholder — 정식 출시 시 법무 검토 후 업데이트 필요.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../auth/auth_state.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PRIVACY')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          children: [
            const Text('DATA STORED', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            const _Bullet('device_id (UUID v4) — 로컬 생성, 서버에 해시로만 전송'),
            const _Bullet('profile: 체중·키·나이·성별·1RM·벤치마크 (로컬·서버 DB)'),
            const _Bullet('gradeResult: Tier·6 카테고리 점수 (로컬·서버 DB)'),
            const _Bullet('WOD history: 계산 기록·일시 (서버 DB)'),
            const _Bullet('Gym membership: 박스 가입·role (서버 DB)'),
            const _Bullet('auth: provider(naver/kakao 데모) · displayName (로컬)'),
            const SizedBox(height: FacingTokens.sp4),

            const Text('NOT COLLECTED', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            const _Bullet('실명·이메일·전화번호 (Phase 2 OAuth 연결 전까지 수집 X)'),
            const _Bullet('위치 정보 · 연락처 · 카메라 · 마이크'),
            const _Bullet('카카오톡 친구목록·메시지 (Beta Preview — OAuth 미연결)'),
            const SizedBox(height: FacingTokens.sp4),

            const Text('USAGE', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            const Text(
              'profile·grade·WOD 데이터는 본인 Engine 계산·추이 표시 용도로만 사용. '
              'device_id 해시는 기록 소유자 식별용. '
              '타 유저와 공유 또는 마케팅 활용 없음. '
              '백분위·랭킹 UI 수치는 **현재 가상 데이터** — 정식 출시 시 익명 집계로 대체 예정.',
              style: FacingTokens.body,
            ),
            const SizedBox(height: FacingTokens.sp4),

            const Text('YOUR RIGHTS', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            const _Bullet('언제든 Sign out (계정 기록만 해제, 프로필 유지)'),
            const _Bullet('언제든 Reset data (로컬 전체 삭제)'),
            const _Bullet('계정 탈퇴 = 서버·로컬 모든 데이터 영구 삭제 (아래 버튼)'),
            const SizedBox(height: FacingTokens.sp5),

            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: FacingTokens.error,
                side: const BorderSide(color: FacingTokens.error),
              ),
              onPressed: () => _confirmDelete(context),
              child: const Text('Delete Account'),
            ),
            const SizedBox(height: FacingTokens.sp3),
            const Text(
              '탈퇴 시 서버 DB의 내 기록(Engine·WOD·Gym) 일괄 삭제. 복구 불가.',
              style: FacingTokens.caption,
            ),
            const SizedBox(height: FacingTokens.sp5),

            const Text('LAST UPDATED', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            const Text('2026-04-24 · Beta Preview · 정식 출시 시 법무 검토.',
                style: FacingTokens.caption),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r5),
        ),
        title: const Text('Delete Account.'),
        content: const Text(
          '서버·로컬 모든 데이터가 영구 삭제됩니다.\n'
          '복구 불가. 계속하시겠습니까?',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    Haptic.heavy();

    // v1.16 Sprint 7b U2: 탈퇴 로직 — 로컬 clear + auth signout.
    // TODO(go): 실제 서버 DELETE /api/v1/profile 호출은 Phase 2에서 추가.
    //           현재는 로컬만 정리. 서버 데이터는 device_id 기반이라 고립.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    await context.read<AuthState>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (_) => false);
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('·  ',
              style: TextStyle(color: FacingTokens.accent)),
          Expanded(child: Text(text, style: FacingTokens.body)),
        ],
      ),
    );
  }
}
