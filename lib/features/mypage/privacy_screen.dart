// v1.16 Sprint 7b U2: 프라이버시 정책 화면 + 탈퇴 buttoned.
// 2026-06-10 P0: 본문 현행화(전화번호·전자계약·소셜) + 탈퇴 서버 삭제 배선.
// 정식 출시 시 법무 검토 권장 (베타 고지 유지).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../auth/auth_state.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개인정보')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HyphenTokens.sp4),
          children: [
            const Text('저장하는 데이터', style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp2),
            const _Bullet('device_id (UUID v4) — 로컬 생성, 서버에 해시로만 전송'),
            const _Bullet('이름·전화번호 — 회원 가입 신청 시 입력 (서버 DB, 체육관 코치에게 제공)'),
            const _Bullet('소셜 로그인: 네이버·구글 계정 식별자·표시명 (서버 DB)'),
            const _Bullet('전자계약: 계약 내용·서명 이미지·서명 일시·IP (서버 DB)'),
            const _Bullet('출석 기록: 출석 일시·체육관 — 코치가 수업 명단에서 기록 (서버 DB)'),
            const _Bullet('profile: 체중·키·나이·성별·1RM·벤치마크 (로컬·서버 DB)'),
            const _Bullet('gradeResult: Tier·6 카테고리 점수 (로컬·서버 DB)'),
            const _Bullet('수업 기록: 결과·일시 (서버 DB)'),
            const _Bullet('Gym membership: 체육관 가입·role·포인트 (서버 DB)'),
            const SizedBox(height: HyphenTokens.sp4),

            const Text('수집하지 않는 것', style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp2),
            const _Bullet('위치 정보 · 연락처 · 마이크'),
            const _Bullet('카메라 — 앱 권한 없음. 수집하지 않습니다'),
            const _Bullet('소셜 계정의 친구목록·메시지 (프로필 식별자만 수신)'),
            const SizedBox(height: HyphenTokens.sp4),

            const Text('사용 목적', style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp2),
            const Text(
              'profile·grade·수업 기록은 본인 추이 표시 용도로만 사용. '
              'device_id 해시는 기록 소유자 식별용. '
              '이름·전화번호·출석·계약 데이터는 가입한 체육관의 운영(회원 관리·계약 증빙) 용도로 '
              '해당 체육관 코치에게 제공. '
              '서명 이미지는 전자서명법에 따른 계약 증빙 용도로만 보관. '
              '타 유저와 공유 또는 마케팅 활용 없음.',
              style: HyphenTokens.body,
            ),
            const SizedBox(height: HyphenTokens.sp4),

            const Text('보관 기간', style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp2),
            const Text(
              '탈퇴 시 본인 기록은 일괄 삭제. 단, 서명 완료된 전자계약서는 '
              '계약 당사자(체육관) 보호를 위해 관계 법령상 보존 기간 동안 '
              '분리 보관될 수 있음.',
              style: HyphenTokens.body,
            ),
            const SizedBox(height: HyphenTokens.sp4),

            const Text('이용자 권리', style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp2),
            const _Bullet('언제든 Sign out (계정 기록만 해제, 프로필 유지)'),
            const _Bullet('언제든 Reset data (로컬 전체 삭제)'),
            const _Bullet('계정 탈퇴 = 서버·로컬 모든 데이터 영구 삭제 (아래 버튼)'),
            const SizedBox(height: HyphenTokens.sp5),

            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: HyphenTokens.error,
                side: const BorderSide(color: HyphenTokens.error),
              ),
              onPressed: () => _confirmDelete(context),
              child: const Text('계정 삭제'),
            ),
            const SizedBox(height: HyphenTokens.sp3),
            const Text(
              '탈퇴 시 서버에 저장된 내 기록 일괄 삭제. 복구 불가.',
              style: HyphenTokens.caption,
            ),
            const SizedBox(height: HyphenTokens.sp5),

            const Text('최종 갱신', style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp2),
            const Text('2026-06-10 · 전화번호 수집·전자계약·소셜 로그인 반영. 정식 출시 시 법무 검토.',
                style: HyphenTokens.caption),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HyphenTokens.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HyphenTokens.r5),
        ),
        title: const Text('계정 삭제'),
        content: const Text(
          '서버·로컬 모든 데이터가 영구 삭제됩니다.\n'
          '복구 불가. 계속하시겠습니까?',
          style: HyphenTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: HyphenTokens.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    Haptic.heavy();

    // P0-2 (2026-06-10): 서버 삭제 먼저 — 실패 시 로컬도 지우지 않고 중단
    // (고지 "서버·로컬 영구 삭제" 와 동작 일치. 계약서·결제는 법정 보존 — 방침 RETENTION).
    final api = context.read<ApiClient>();
    try {
      await api.delete('/api/v1/member/me');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('서버 삭제 실패. 연결 확인 후 다시 시도.'),
        duration: Duration(seconds: 3),
      ));
      return;
    }
    if (!context.mounted) return;
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
      padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('·  ',
              style: TextStyle(color: HyphenTokens.accent)),
          Expanded(child: Text(text, style: HyphenTokens.body)),
        ],
      ),
    );
  }
}
