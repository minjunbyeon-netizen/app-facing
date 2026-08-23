// v1.16 Sprint 7b U2: 프라이버시 정책 화면 + 탈퇴 buttoned.
// 2026-06-10 P0: 본문 현행화(전화번호·전자계약·소셜) + 탈퇴 서버 삭제 배선.
// 정식 출시 시 법무 검토 권장 (베타 고지 유지).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/hkit.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../auth/auth_state.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개인정보처리방침')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HyphenTokens.sp4),
          children: [
            const Text('저장하는 데이터', style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp2),
            const _Bullet('기기 식별값 — 이 기기에서 만들고, 서버에는 알아볼 수 없게 바꾼 값만 보냅니다'),
            const _Bullet('이름·전화번호 — 회원 가입 신청 시 입력 (서버 보관, 체육관 코치에게 제공)'),
            const _Bullet('소셜 로그인: 네이버·구글 계정 식별값·표시 이름 (서버 보관)'),
            const _Bullet('전자계약: 계약 내용·서명 그림·서명 일시·접속 주소 (서버 보관)'),
            const _Bullet('출석 기록: 출석 일시·체육관 — 코치가 수업 명단에서 기록 (서버 보관)'),
            // v3.2 (2026-08-20): 체중·키·나이·1RM·벤치마크 입력 경로는 v2.3
            // 에서 소멸, gradeResult 산정도 중단 — 실수집 항목만 남긴다.
            const _Bullet('프로필: 생년월일·성별·운동 경력 (이 기기·서버 보관)'),
            const _Bullet('수업 기록: 결과·일시 (서버 보관)'),
            const _Bullet('체육관 정보: 가입한 체육관·회원 구분·포인트 (서버 보관)'),
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
              '프로필·수업 기록은 본인 변화를 보여 주는 용도로만 씁니다. '
              '기기 식별값은 이 기록이 누구 것인지 알아보는 데만 씁니다. '
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
            // v3.11 (2026-08-23): 'Sign out'·'Reset data' 는 앱 어디에도 없는
            // 이름이었다 — 실물 버튼은 내 정보의 '로그아웃'·'데이터 초기화' 다.
            // 읽는 사람이 찾아갈 수 있게 화면 위치까지 적는다 (§0-B).
            const _Bullet('언제든 로그아웃 (내 정보 화면 — 계정 연결만 끊고 프로필은 남습니다)'),
            const _Bullet("언제든 '데이터 초기화' (내 정보 맨 아래 — 이 기기에 저장된 것만 삭제)"),
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
            const Text('2026-08-20 · 수집 항목 현행화 (신체·벤치마크 수집 종료). 정식 출시 시 법무 검토.',
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
      HkSnack.error(context, '서버 삭제 실패. 연결 확인 후 다시 시도.');
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
