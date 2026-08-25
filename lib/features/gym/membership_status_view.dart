import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/hkit.dart';

/// 회원 자격 상태 화면 — 미가입 · 승인 대기 · 거절, 한 골격.
///
/// v3.25 (2026-08-25 사용자 지시 "따로 있는 것 전부 통일"): 셸 입구의 승인 대기
/// 게이트(`_PendingGate`)와 수업 탭 안의 미가입/대기/거절 3종(`_NoGymEmpty`·
/// `_PendingState`·`_RejectedState`)이 같은 상태를 두 모양으로 그렸다.
/// 문구·간격·버튼 규격은 여기 하나 — 부르는 쪽은 상태와 콜백만 준다.
enum MembershipStatusKind { none, pending, rejected }

class MembershipStatusView extends StatelessWidget {
  final MembershipStatusKind kind;
  final String? gymName;

  /// 승인 대기에서 "승인됐는지 확인". null 이면 버튼을 그리지 않는다.
  final VoidCallback? onRecheck;
  final bool checking;

  /// 셸 입구 게이트에서만 — 안 그러면 승인 전까지 앱에 갇힌다.
  final VoidCallback? onSignOut;

  const MembershipStatusView({
    super.key,
    required this.kind,
    this.gymName,
    this.onRecheck,
    this.checking = false,
    this.onSignOut,
  });

  const MembershipStatusView.none({super.key})
      : kind = MembershipStatusKind.none,
        gymName = null,
        onRecheck = null,
        checking = false,
        onSignOut = null;

  const MembershipStatusView.pending(
      {super.key,
      this.gymName,
      this.onRecheck,
      this.checking = false,
      this.onSignOut})
      : kind = MembershipStatusKind.pending;

  const MembershipStatusView.rejected({super.key, this.gymName})
      : kind = MembershipStatusKind.rejected,
        onRecheck = null,
        checking = false,
        onSignOut = null;

  String get _title => switch (kind) {
        MembershipStatusKind.none => '체육관 미가입',
        MembershipStatusKind.pending => '승인 대기중입니다',
        MembershipStatusKind.rejected => '가입이 승인되지 않았습니다',
      };

  String get _body {
    final g = (gymName ?? '').isNotEmpty ? '$gymName ' : '';
    return switch (kind) {
      // v2.6·v2.7: 가입은 로그인 화면의 '회원 가입 신청' 한 길뿐이다.
      MembershipStatusKind.none => '로그인 화면의 [회원 가입 신청] 으로 신청하면 '
          '코치가 승인한 뒤 이용할 수 있습니다.',
      MembershipStatusKind.pending => '$g가입 신청이 코치에게 전달됐습니다.\n'
          '코치가 승인하면 수업 내용·수업 예약이 열립니다.',
      // v2.6: 체육관이 하나뿐이라 "다른 체육관" 은 없다 — 코치에게 묻는 것이 유일한 다음 행동.
      MembershipStatusKind.rejected => '$g코치에게 문의해 주세요.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HyphenTokens.sp6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_title, style: HyphenTokens.h3, textAlign: TextAlign.center),
            const SizedBox(height: HyphenTokens.sp3),
            Text(_body,
                style: HyphenTokens.caption, textAlign: TextAlign.center),
            if (kind == MembershipStatusKind.pending && onRecheck != null) ...[
              const SizedBox(height: HyphenTokens.sp6),
              checking
                  ? const HkLoading()
                  : HkButton.primary('승인됐는지 확인', onPressed: onRecheck),
            ],
            if (onSignOut != null) ...[
              const SizedBox(height: HyphenTokens.sp3),
              HkButton.tertiary('로그아웃', neutral: true, onPressed: onSignOut),
            ],
          ],
        ),
      ),
    );
  }
}
