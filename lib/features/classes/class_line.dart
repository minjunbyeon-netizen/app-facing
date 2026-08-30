import 'package:flutter/material.dart';

import '../../core/app_clock.dart';
import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../models/class_session.dart';
import '../../widgets/hkit.dart';

/// 수업 한 줄 — 시각 · 이름/부제 · 우측 슬롯.
///
/// v3.25 (2026-08-25 사용자 지시 "따로 있는 것 전부 통일"): 코치 예약 현황 탭의
/// 수업 카드(`_ClassCard`)와 회원 주간보드의 수업 줄(`_ClassLine`)이 같은 수업을
/// 다른 모양으로 그리던 것을 하나로. 골격은 같고 우측 슬롯만 시점에 따라 다르다:
/// - [ClassLine.coach] — 예약 인원 + 명단 진입 (탭 → 예약자 명단 시트)
/// - [ClassLine.member] — 예약/대기/취소/종료/마감/회원권 필요 배지 한 규격
class ClassLine extends StatelessWidget {
  final String timeLabel;
  final String title;
  final String subtitle;
  final Color? subtitleColor;

  /// 취소된 수업 등 — 시각·제목을 흐리게.
  final bool muted;
  final Widget trailing;
  final VoidCallback? onTap;

  const ClassLine({
    super.key,
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.subtitleColor,
    this.muted = false,
    this.onTap,
  });

  /// 코치 시점 — 예약 인원 + 명단 진입.
  factory ClassLine.coach({
    Key? key,
    required String timeLabel,
    required String title,
    required String subtitle,
    required int reserved,
    required int? capacity,
    bool muted = false,
    VoidCallback? onTap,
  }) {
    return ClassLine(
      key: key,
      timeLabel: timeLabel,
      title: title,
      subtitle: subtitle,
      muted: muted,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$reserved',
            style: HyphenTokens.h3.copyWith(
              color: HyphenTokens.fg,
              fontFeatures: HyphenTokens.tabular,
            ),
          ),
          Text(
            capacity != null ? ' / $capacity명' : '명',
            style: HyphenTokens.micro,
          ),
          const SizedBox(width: HyphenTokens.sp1),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: HyphenTokens.mutedStrong,
          ),
        ],
      ),
    );
  }

  /// 회원 시점 — 우측은 전부 **배지 한 규격**.
  /// v2.5 (2026-08-12 사용자 지시): 예약 버튼이 '예약됨' 배지보다 훨씬 커서 같은 줄
  /// 안에서 층이 졌다. HkBadge 는 onTap 을 주면 그대로 조작 컨트롤이 되고(터치 48
  /// 은 안쪽에서 확보), 표시·조작이 시각적으로 같은 크기가 된다.
  factory ClassLine.member({
    Key? key,
    required ClassSessionDto session,
    required bool isPastDay,
    required VoidCallback onReserve,
    required VoidCallback onCancel,
    bool membershipOk = true,
  }) {
    final l = session.startAt.toLocal();
    final isCancelled = session.isCancelled;
    final isFull = session.isFull;
    final isOver = l.isBefore(appClock.now());
    // '8/12' 가 날짜(8월 12일)로 읽혔다 — 앞에 '정원' 을 붙여 인원임을 못 박는다.
    // 2026-08-28 테스터 요청 6 ("무슨 수업인지만 보이면 충분") — 룸 이름을 뺀다.
    // 정원·대기는 남긴다: 자리가 찼는지가 예약을 누를지 정하는 값이라 곁줄이
    // 아니라 판단 근거다. 룸은 코치 줄(ClassLine.coach)에만 남는다.
    final subtitle = [
      '정원 ${session.reservedCount}/${session.capacity}',
      if (session.waitlistCount > 0) '대기 ${session.waitlistCount}',
    ].join(' · ');
    return ClassLine(
      key: key,
      timeLabel: hhmm(l),
      title: session.displayTitle, // D89 — 'AWAKE · A 세션' (서버 표시 제목)
      subtitle: subtitle,
      subtitleColor: isFull ? HyphenTokens.warning : null,
      muted: isCancelled,
      trailing: _memberAction(
        session,
        isPastDay: isPastDay,
        isOver: isOver,
        membershipOk: membershipOk,
        onReserve: onReserve,
        onCancel: onCancel,
      ),
    );
  }

  static Widget _memberAction(
    ClassSessionDto session, {
    required bool isPastDay,
    required bool isOver,
    required bool membershipOk,
    required VoidCallback onReserve,
    required VoidCallback onCancel,
  }) {
    if (session.isCancelled) {
      return const HkBadge('취소됨', color: HyphenTokens.muted);
    }
    if (session.isReserved || session.isWaitlisted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HkBadge(
            session.isWaitlisted ? '대기 ${session.myWaitlistPosition}' : '예약됨',
            color: session.isWaitlisted
                ? HyphenTokens.warning
                : HyphenTokens.success,
          ),
          if (!isOver) ...[
            const SizedBox(width: HyphenTokens.sp2),
            HkBadge('취소', color: HyphenTokens.muted, onTap: onCancel),
          ],
        ],
      );
    }
    if (isPastDay || isOver) {
      return const HkBadge('종료', color: HyphenTokens.muted);
    }
    // S5 (2026-08-26 사용자 결정 "회원권 없으면 예약·대기 당연히 안 된다"):
    // 그날 유효한 회원권이 없으면 예약·대기 대신 '회원권 필요'. 탭은 그대로
    // 서버로 보내 409 MEMBERSHIP_REQUIRED 문구를 스낵바로 받는다 — 정책 문구
    // 정본은 서버 하나 (앱에 같은 문장을 두 번 적지 않는다).
    if (!membershipOk) {
      return HkBadge('회원권 필요', color: HyphenTokens.muted, onTap: onReserve);
    }
    // D82 (2026-08-29 사용자 지시 "그 예약 버튼 누르고 싶은데, 아직 설정한 시간이
    // 아닐 때 누르면 스낵바로 '예약 가능한 시간이 아니에요' 캐릭터와 함께"):
    // 예약 오픈(전날 N시) 전이어도 '예약' 배지는 그대로 선다 — 여기서 잠그지 않는다.
    // 누르면 reserveClassFlow 가 캐릭터 스낵바로 알린다 (구 D58 '오픈 전' 배지 폐기).
    final blocked =
        session.isFull && session.waitlistCount >= session.waitlistCapacity;
    if (blocked) return const HkBadge('마감', color: HyphenTokens.muted);
    return HkBadge(
      session.isFull ? '대기' : '예약',
      color: session.isFull ? HyphenTokens.warning : HyphenTokens.accent,
      onTap: onReserve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = muted ? HyphenTokens.muted : HyphenTokens.fg;
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp2),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: HyphenTokens.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 46),
            child: Text(
              timeLabel,
              style: HyphenTokens.body.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: HyphenTokens.tabular,
                color: fg,
              ),
            ),
          ),
          const SizedBox(width: HyphenTokens.sp2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HyphenTokens.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: HyphenTokens.caption.copyWith(
                      color: subtitleColor ?? HyphenTokens.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: HyphenTokens.sp2),
          trailing,
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
