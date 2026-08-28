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
import '../gym/gym_state.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HkAppBar(title: '개인정보처리방침'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HyphenTokens.sp4),
          children: [
            // 2026-08-28: 개인(변민준) 명의 출시 — 운영 주체·보호책임자를 본문에 명시.
            const Text(
              'HYPHEN 은 개인 운영자 변민준이 운영하는 서비스입니다. '
              '이 방침은 앱과 코치용 PC 웹 모두에 적용됩니다.',
              style: HyphenTokens.body,
            ),
            const SizedBox(height: HyphenTokens.sp4),
            const HkSectionLabel('저장하는 데이터'),
            const SizedBox(height: HyphenTokens.sp2),
            const _Bullet('기기 식별값 — 이 기기에서 만들고, 서버에는 알아볼 수 없게 바꾼 값만 보냅니다'),
            const _Bullet('이름·전화번호 — 회원 가입 신청 시 입력 (서버 보관, 체육관 코치에게 제공)'),
            // 2026-08-28: 소셜 로그인 플러그인 제거 — 로그인은 아이디·비밀번호뿐.
            const _Bullet('로그인 아이디·비밀번호 (서버 보관 — 비밀번호는 원문 대신 알아볼 수 없게 변환한 값만 저장)'),
            const _Bullet('전자계약: 계약 내용·서명 그림·서명 일시·접속 주소 (서버 보관)'),
            const _Bullet('출석 기록: 출석 일시·체육관 — 코치가 수업 명단에서 기록 (서버 보관)'),
            // v3.2 (2026-08-20): 체중·키·나이·1RM·벤치마크 입력 경로는 v2.3
            // 에서 소멸, gradeResult 산정도 중단 — 실수집 항목만 남긴다.
            const _Bullet('프로필: 생년월일·성별·운동 경력 (이 기기·서버 보관)'),
            const _Bullet('수업 기록: 결과·일시 (서버 보관)'),
            const _Bullet('체육관 정보: 가입한 체육관·회원 구분·포인트 (서버 보관)'),
            // v3.34 (2026-08-27): 목표 화면이 D66 에서 삭제돼 주간·월간·PR·시즌
            // 목표는 더 이상 수집하지 않는다. 같은 member_goals 에 남는 실수집
            // 항목은 착용 칭호 하나뿐이라 고지도 그것만 적는다 (§0-B).
            const _Bullet('착용 칭호: 내 정보에 표시할 칭호 선택값 (서버 보관)'),
            const SizedBox(height: HyphenTokens.sp4),

            const HkSectionLabel('수집하지 않는 것'),
            const SizedBox(height: HyphenTokens.sp2),
            const _Bullet('위치 정보 · 연락처 · 마이크'),
            const _Bullet('카메라 — 앱 권한 없음. 수집하지 않습니다'),
            const _Bullet('소셜 계정 정보 — 네이버·구글 등 소셜 로그인을 쓰지 않습니다'),
            const SizedBox(height: HyphenTokens.sp4),

            const HkSectionLabel('사용 목적'),
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

            const HkSectionLabel('보관 기간'),
            const SizedBox(height: HyphenTokens.sp2),
            const Text(
              '탈퇴 시 본인 기록은 일괄 삭제. 단, 서명 완료된 전자계약서는 '
              '계약 당사자(체육관) 보호를 위해 관계 법령상 보존 기간 동안 '
              '분리 보관될 수 있음.',
              style: HyphenTokens.body,
            ),
            const SizedBox(height: HyphenTokens.sp4),

            const HkSectionLabel('이용자 권리'),
            const SizedBox(height: HyphenTokens.sp2),
            // v3.34 (2026-08-27): '데이터 초기화' 버튼은 D66 에서 삭제됐다 —
            // 없는 버튼을 권리로 안내하면 고지가 거짓이 된다 (§0-B).
            const _Bullet('언제든 로그아웃 (내 정보 화면 — 계정 연결만 끊고 프로필은 남습니다)'),
            const _Bullet('계정 탈퇴 = 서버·로컬 모든 데이터 영구 삭제 (아래 버튼)'),
            const _Bullet('열람·정정·삭제 요청은 아래 문의처로 — 본인 확인 후 영업일 7일 이내 처리'),
            const SizedBox(height: HyphenTokens.sp4),

            const HkSectionLabel('개인정보 보호책임자 · 문의'),
            const SizedBox(height: HyphenTokens.sp2),
            const _Bullet('보호책임자: 변민준 (개인 운영자)'),
            const _Bullet('이메일: cheb2oy@naver.com'),
            const SizedBox(height: HyphenTokens.sp5),

            HkButton.secondary(
              '계정 삭제',
              danger: true,
              onPressed: () => _confirmDelete(context),
            ),
            const SizedBox(height: HyphenTokens.sp3),
            const Text(
              '탈퇴 시 서버에 저장된 내 기록 일괄 삭제. 복구 불가.',
              style: HyphenTokens.caption,
            ),
            const SizedBox(height: HyphenTokens.sp5),

            const HkSectionLabel('최종 갱신'),
            const SizedBox(height: HyphenTokens.sp2),
            // 본문을 고치면 이 날짜도 같은 커밋에서 함께 고친다 (§0-B).
            // 법적 고지의 갱신일이 실제 내용과 어긋나면 고지 자체가 신뢰를 잃는다.
            const Text(
              '2026-08-28 · 운영자(개인 변민준)·보호책임자·문의처 명시, '
              '소셜 로그인 항목 삭제(로그인은 아이디·비밀번호). 정식 출시 시 법무 검토.',
              style: HyphenTokens.caption,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await HkDialog.confirm(
      context,
      title: '계정 삭제',
      message:
          '서버·로컬 모든 데이터가 영구 삭제됩니다.\n'
          '복구 불가. 계속하시겠습니까?',
      confirmLabel: '삭제',
      danger: true,
    );
    if (!ok) return;
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
    context.read<GymState>().resetLocal();
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
          const Text('·  ', style: TextStyle(color: HyphenTokens.accent)),
          Expanded(child: Text(text, style: HyphenTokens.body)),
        ],
      ),
    );
  }
}
