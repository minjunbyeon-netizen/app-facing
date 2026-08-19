// P0-1 (2026-06-10): 이용약관 본문 화면 — privacy_screen 패턴.
// 베타 운영 기준 초안. 정식 출시 시 법무 검토 후 개정 (개정 시 LAST UPDATED 갱신).

import 'package:flutter/material.dart';

import '../../core/theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이용약관')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HyphenTokens.sp4),
          children: const [
            Text('1. 서비스', style: HyphenTokens.sectionLabel),
            SizedBox(height: HyphenTokens.sp2),
            Text(
              'HYPHEN 은 체육관 운영을 돕는 플랫폼입니다. '
              '회원에게는 수업 예약·QR 출석·전자계약·페이싱 계산 기능을, '
              '체육관 코치에게는 회원·수업·계약 관리 도구를 제공합니다.',
              style: HyphenTokens.body,
            ),
            SizedBox(height: HyphenTokens.sp4),

            Text('2. 계정·가입·탈퇴', style: HyphenTokens.sectionLabel),
            SizedBox(height: HyphenTokens.sp2),
            _Bullet('가입은 소셜 로그인(네이버·구글) 또는 회원 가입 신청으로 합니다.'),
            _Bullet('회원 가입 신청의 승인·거절 권한은 해당 체육관 코치에게 있습니다.'),
            _Bullet('탈퇴는 내 정보 → 개인정보처리방침 화면에서 언제든 가능합니다.'),
            _Bullet('타인 명의 도용, 허위 정보 가입 시 이용이 제한될 수 있습니다.'),
            SizedBox(height: HyphenTokens.sp4),

            Text('3. 체육관·회원·HYPHEN 의 관계', style: HyphenTokens.sectionLabel),
            SizedBox(height: HyphenTokens.sp2),
            Text(
              'HYPHEN 은 체육관과 회원을 연결하는 도구를 제공하는 플랫폼이며, '
              '회원권 판매·환불·수업 운영의 당사자는 각 체육관입니다. '
              '회원권 금액·기간·환불 조건은 체육관과 회원 간 계약(전자계약서 포함)을 따르며, '
              'HYPHEN 은 그 계약의 당사자가 아닙니다.',
              style: HyphenTokens.body,
            ),
            SizedBox(height: HyphenTokens.sp4),

            Text('4. 전자계약', style: HyphenTokens.sectionLabel),
            SizedBox(height: HyphenTokens.sp2),
            _Bullet('앱 내 서명은 전자서명법 제3조에 따라 서면 서명과 같은 효력을 가집니다.'),
            _Bullet('서명 완료된 계약서는 위·변조 방지를 위해 수정이 잠깁니다.'),
            _Bullet('서명 전 계약 내용(기간·금액·환불 조건)을 반드시 확인하십시오.'),
            SizedBox(height: HyphenTokens.sp4),

            Text('5. 포인트·기록', style: HyphenTokens.sectionLabel),
            SizedBox(height: HyphenTokens.sp2),
            _Bullet('포인트 적립·사용 기준은 각 체육관이 정하며 체육관별로 다를 수 있습니다.'),
            _Bullet('Engine 점수·Tier·페이싱 결과는 입력 기록 기반 추정치로, '
                '트레이닝 처방·의료 판단의 근거가 아닙니다.'),
            SizedBox(height: HyphenTokens.sp4),

            Text('6. 금지행위', style: HyphenTokens.sectionLabel),
            SizedBox(height: HyphenTokens.sp2),
            _Bullet('타인 계정 도용 (대리 출석 포함)'),
            _Bullet('서비스의 비정상적 이용 (자동화 도구, 취약점 악용)'),
            _Bullet('다른 회원·코치에 대한 욕설·괴롭힘 (쪽지·댓글 포함)'),
            SizedBox(height: HyphenTokens.sp4),

            Text('7. 책임의 한계', style: HyphenTokens.sectionLabel),
            SizedBox(height: HyphenTokens.sp2),
            Text(
              '트레이닝 중 발생한 부상, 체육관과 회원 간 분쟁, 체육관의 폐업·운영 중단에 대해 '
              'HYPHEN 은 책임을 지지 않습니다. 서비스는 베타 운영 중이며 '
              '기능은 사전 공지 후 변경될 수 있습니다. 천재지변·통신 장애 등 '
              '불가항력으로 인한 일시 중단에 대해 책임을 지지 않습니다.',
              style: HyphenTokens.body,
            ),
            SizedBox(height: HyphenTokens.sp4),

            Text('8. 분쟁·관할', style: HyphenTokens.sectionLabel),
            SizedBox(height: HyphenTokens.sp2),
            Text(
              '본 약관은 대한민국 법률을 따릅니다. 분쟁은 우선 고객센터(카카오톡 상담)를 '
              '통한 협의로 해결하며, 협의가 어려울 경우 민사소송법상 관할 법원에 제기합니다.',
              style: HyphenTokens.body,
            ),
            SizedBox(height: HyphenTokens.sp5),

            Text('최종 갱신', style: HyphenTokens.sectionLabel),
            SizedBox(height: HyphenTokens.sp2),
            Text('2026-06-10 · 베타 운영 기준. 개정 시 앱 내 공지.',
                style: HyphenTokens.caption),
          ],
        ),
      ),
    );
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
