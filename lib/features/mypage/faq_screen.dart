// P2-1 (2026-06-11): FAQ — 제품 실동작 기반 시드 10문답.
// 원칙: 추측 금지 — 코드로 검증된 동작만 기술. 실문의 누적 시 카카오톡 상담
// 빈도 상위 문답으로 교체·증보한다 (LAUNCH-CONTENT-TODO P2-1).

import 'package:flutter/material.dart';

import '../../core/theme.dart';

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem(this.q, this.a);
}

const List<_FaqItem> _kFaqs = [
  _FaqItem(
    '박스에 가입하려면 어떻게 하나요?',
    '로그인 화면의 "박스 가입 신청"에서 박스를 고르고 이름·전화번호를 입력하면 '
        '신청이 접수됩니다. 박스 운영자가 승인하면 수업 예약·출석·계약 기능이 열립니다.',
  ),
  _FaqItem(
    '가입 신청했는데 아직 "대기" 상태예요.',
    '승인은 박스 운영자가 직접 처리합니다. 오래 걸리면 박스에 직접 문의하는 게 '
        '가장 빠릅니다. 거절된 경우에도 같은 박스에 다시 신청할 수 있습니다.',
  ),
  _FaqItem(
    '수업 예약은 어디서 하나요?',
    'Profile 탭 → MY BOX → Classes 에서 날짜별 수업을 보고 Reserve 를 누르면 '
        '됩니다. 정원이 차면 자동으로 대기열에 등록되고, 자리가 나면 순서대로 승격됩니다.',
  ),
  _FaqItem(
    'QR 출석은 어떻게 하나요?',
    '박스 입구 화면의 QR 코드를 폰 기본 카메라로 스캔하면 출석 처리됩니다. '
        '앱 안에 별도 스캐너는 없습니다. QR 은 60초마다 바뀌고 1회만 사용됩니다.',
  ),
  _FaqItem(
    '전자계약서는 어디서 서명하나요?',
    '박스가 계약서를 발송하면 Profile → Contracts 에 나타납니다. 내용 확인 후 '
        '손가락으로 서명하면 완료 — 전자서명법 제3조에 따라 서면 서명과 같은 효력입니다.',
  ),
  _FaqItem(
    '포인트는 어떻게 쌓이나요?',
    '출석·결제 등 박스가 정한 기준에 따라 적립됩니다. 적립 기준과 사용처는 '
        '박스마다 다르니 박스에 확인하십시오. 잔액은 Profile 상단에 표시됩니다.',
  ),
  _FaqItem(
    'Tier·Engine 점수는 뭔가요?',
    '입력한 1RM·벤치마크 기록으로 6개 카테고리 점수를 계산해 Scaled–Games '
        'Tier 로 보여줍니다. 산출 방식은 Profile → Algorithm 에 공개돼 있습니다. '
        '기록을 갱신하면 언제든 다시 측정할 수 있습니다.',
  ),
  _FaqItem(
    '기기를 바꾸면 기록이 사라지나요?',
    '네이버·구글 로그인 계정이면 같은 계정으로 다시 로그인해 복구할 수 있습니다. '
        '기기 변경 전에 소셜 계정 연결을 확인하십시오.',
  ),
  _FaqItem(
    '탈퇴하면 데이터는 어떻게 되나요?',
    'Profile → Privacy Policy → Delete Account 로 탈퇴하면 서버의 내 기록이 '
        '일괄 삭제됩니다. 단, 서명 완료된 계약서는 법령상 보존 기간 동안 분리 보관됩니다.',
  ),
  _FaqItem(
    '문제가 생기면 어디에 물어보나요?',
    'Profile → 고객센터 (카카오톡) 버튼으로 1:1 상담을 보낼 수 있습니다. '
        '평일 10–18시에 답변합니다. 박스 운영 관련(회원권·환불)은 박스에 직접 문의가 빠릅니다.',
  ),
];

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          itemCount: _kFaqs.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: FacingTokens.border),
          itemBuilder: (_, i) {
            final item = _kFaqs[i];
            return Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
                childrenPadding: const EdgeInsets.only(
                    bottom: FacingTokens.sp3, right: FacingTokens.sp2),
                title: Text(item.q,
                    style: FacingTokens.body
                        .copyWith(fontWeight: FontWeight.w700)),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.a, style: FacingTokens.caption),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
