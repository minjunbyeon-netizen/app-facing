// P2-1 (2026-06-11): FAQ — 제품 실동작 기반 시드 10문답.
// 원칙: 추측 금지 — 코드로 검증된 동작만 기술. 실문의 누적 시 카카오톡 상담
// 빈도 상위 문답으로 교체·증보한다 (LAUNCH-CONTENT-TODO P2-1).

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/hkit.dart';

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem(this.q, this.a);
}

const List<_FaqItem> _kFaqs = [
  _FaqItem(
    '체육관에 가입하려면 어떻게 하나요?',
    '로그인 화면의 "회원 가입 신청" 에서 이름·연락처와 쓸 아이디·비밀번호를 넣으면 '
        '신청이 접수됩니다. 코치가 승인하면 수업 예약·출석·계약이 열립니다.',
  ),
  _FaqItem(
    '가입 신청했는데 아직 "대기" 상태예요.',
    '승인은 체육관 코치가 직접 처리합니다. 오래 걸리면 체육관에 직접 문의하는 게 '
        '가장 빠릅니다. 거절된 경우에도 같은 체육관에 다시 신청할 수 있습니다.',
  ),
  _FaqItem(
    '수업 예약은 어디서 하나요?',
    '수업 탭에서 날짜를 고르면 그날 수업이 함께 뜹니다. 예약을 누르면 자리가 '
        '잡히고, 정원이 차면 대기로 등록돼 자리가 나는 대로 순서대로 올라갑니다.',
  ),
  _FaqItem(
    '출석은 어떻게 기록되나요?',
    '코치가 수업 명단에서 출석을 찍으면 기록됩니다. 회원이 따로 할 일은 없고, '
        '홈 탭의 출석 항목에 자동으로 쌓입니다.',
  ),
  _FaqItem(
    '전자계약서는 어디서 서명하나요?',
    '코치가 계약서를 보내면 프로필 → 계약에 나타납니다. 내용 확인 후 '
        '손가락으로 서명하면 완료 — 전자서명법 제3조에 따라 서면 서명과 같은 효력입니다.',
  ),
  _FaqItem(
    '포인트는 어떻게 쌓이나요?',
    '출석·결제 등 체육관이 정한 기준에 따라 적립됩니다. 적립 기준과 사용처는 '
        '체육관마다 다르니 코치에게 확인하십시오. 잔액은 프로필의 포인트 행에 표시됩니다.',
  ),
  // v2.6 (2026-08-13 사용자 지시): 구 'Tier·Engine 점수는 뭔가요?' 문답 폐기.
  // 6 카테고리 점수·Scaled–Games Tier·Algorithm 화면은 앱에서 다 내렸다 (D34).
  // 회원이 실제로 보는 등급은 경력 3단 하나뿐이라 그것만 설명한다 (D36).
  _FaqItem(
    // v3.2 (2026-08-20): 홈 탭의 XP 레벨 숫자와 헷갈리던 문답 — 어느 레벨
    // 얘기인지 질문에 명시하고, XP 레벨은 별개임을 한 줄로 갈라 둔다.
    'SCALED·RXD·ELITE 레벨은 어떻게 정해지나요?',
    '운동 경력 하나로 정해집니다. 1년 미만은 SCALED, 1~3년은 RXD, '
        '3년 이상은 ELITE 입니다. 경력은 프로필 수정에서 언제든 고칠 수 있습니다. '
        '홈 탭의 레벨 숫자는 별개로, 수업 기록·업적에서 쌓이는 XP 로 오릅니다.',
  ),
  _FaqItem(
    '기기를 바꾸면 기록이 사라지나요?',
    '네이버·구글 로그인 계정이면 같은 계정으로 다시 로그인해 복구할 수 있습니다. '
        '기기 변경 전에 소셜 계정 연결을 확인하십시오.',
  ),
  _FaqItem(
    '탈퇴하면 데이터는 어떻게 되나요?',
    '내 정보 → 개인정보처리방침 → 계정 삭제로 탈퇴하면 서버의 내 기록이 '
        '일괄 삭제됩니다. 단, 서명 완료된 계약서는 법령상 보존 기간 동안 분리 보관됩니다.',
  ),
  _FaqItem(
    '문제가 생기면 어디에 물어보나요?',
    '프로필 → 고객센터 (카카오톡) 버튼으로 1:1 상담을 보낼 수 있습니다. '
        '평일 10–18시에 답변합니다. 체육관 운영 관련(회원권·환불)은 체육관에 직접 문의가 빠릅니다.',
  ),
];

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HkAppBar(title: 'FAQ'),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(HyphenTokens.sp4),
          itemCount: _kFaqs.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: HyphenTokens.border),
          itemBuilder: (_, i) {
            final item = _kFaqs[i];
            return Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(vertical: HyphenTokens.sp1),
                childrenPadding: const EdgeInsets.only(
                    bottom: HyphenTokens.sp3, right: HyphenTokens.sp2),
                title: Text(item.q,
                    style: HyphenTokens.body
                        .copyWith(fontWeight: FontWeight.w700)),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.a, style: HyphenTokens.caption),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
