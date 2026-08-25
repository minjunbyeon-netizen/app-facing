import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../../widgets/hkit.dart';
import '../announcements/announcements_state.dart';
import '../../widgets/gym_info_card.dart';
import '../../widgets/inbox_bell.dart';
import 'gym_state.dart';
import 'week_board.dart';
import 'membership_status_view.dart';
import '../announcements/announcement_row.dart';

/// v1.15.3: WOD 탭 진입점. GymState 상태 따라 4분기 렌더.
class BoxWodScreen extends StatefulWidget {
  /// 코치 셸에 얹힐 때는 자기 AppBar 를 그리지 않는다 — 상단바는 셸이 하나만
  /// 갖는다 (v3.23). 회원 셸(MainShell)은 종전대로 각 탭이 제목을 갖는다.
  final bool embedded;

  const BoxWodScreen({super.key, this.embedded = false});

  @override
  State<BoxWodScreen> createState() => _BoxWodScreenState();
}

class _BoxWodScreenState extends State<BoxWodScreen> {
  // v2.9 (2026-08-14): 앱바 새로고침이 GymState.loadMine() 만 불러서 주간보드의
  // 수업(class_sessions)은 그대로였다 — PC 에서 코치가 수업을 등록해도 이 버튼으론
  // 안 보이는 버그. 당겨서 새로고침(_WodList._refresh)과 같은 일을 하도록
  // 리스트 상태에 키로 손을 뻗고, 리스트가 없는 분기(미가입·대기·거절)에서만
  // WOD 상태 재로드로 폴백한다.
  final GlobalKey<_WodListState> _listKey = GlobalKey<_WodListState>();

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();

    Widget body;
    if (gs.isLoading && !gs.hasGym) {
      body = const HkLoading();
    } else if (!gs.hasGym) {
      // v3.25: 미가입·대기·거절 화면은 MembershipStatusView 한 벌 (셸 게이트와 동일).
      body = const MembershipStatusView.none();
    } else if (gs.membership.isPending) {
      body = MembershipStatusView.pending(
        gymName: gs.membership.gym!.name,
        onRecheck: () {
          Haptic.light();
          gs.loadMine();
        },
      );
    } else if (gs.membership.isRejected) {
      body = MembershipStatusView.rejected(gymName: gs.membership.gym!.name);
    } else {
      // owner or approved member
      body = _WodList(key: _listKey, gymState: gs);
    }

    return Scaffold(
      // v3.23 (2026-08-25 사용자 지시 "상단화면 통일하라고 1개로"): 코치 셸에
      // 얹힐 때는 상단바를 그리지 않는다 — 셸이 하나만 갖는다. 회원 셸에서는
      // 종전 그대로 (제목 '수업' + 종 + 새로고침).
      appBar: widget.embedded
          ? null
          : HkAppBar(
              title: '수업',
              actions: [
                // v3.28: 코치 분기(배지·가입 신청 아이콘) 제거 — 회원 전용 화면.
                const InboxBellAction(),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    Haptic.light();
                    final list = _listKey.currentState;
                    if (list != null) {
                      list.refreshAll();
                    } else {
                      context.read<GymState>().loadMine();
                    }
                  },
                ),
              ],
            ),
      // v3.20 (2026-08-25 사용자 지시): '수업 내용 게시' FAB 삭제 —
      // 수업 내용은 PC 에서 쓴다. 폰의 이 탭은 코치에게도 **보는 화면**이다
      // (README §제거된 기능 대장 16). 삭제 아이콘도 같이 내렸다 — 폰에서
      // 지울 수는 있는데 다시 쓸 수는 없으면 그게 더 나쁜 상태다.
      body: SafeArea(child: body),
    );
  }
}

// (구 _NoGymEmpty·_PendingState·_RejectedState 는 v3.25 에서
//  gym/membership_status_view.dart 로 통합 — 셸 게이트와 같은 화면.)

/// v2.4 (2026-08-12 사용자 지시): 주간 아코디언 하나로 통일.
/// 오늘·예정·지난 3섹션 + 하단 수업 목록을 따로 쌓던 구조를 걷고, 그 주 월~일
/// 7줄 안에서 날짜를 눌러 그날 WOD·수업을 함께 본다 (week_board.dart).
class _WodList extends StatefulWidget {
  final GymState gymState;
  const _WodList({super.key, required this.gymState});

  @override
  State<_WodList> createState() => _WodListState();
}

class _WodListState extends State<_WodList> {
  // 새로고침은 WOD(GymState) 와 수업(WeekBoard 내부 fetch) 둘 다 다시
  // 받아야 한다. key 를 갈아 WeekBoard 를 새로 만드는 것이 가장 단순한 배선.
  // v2.9: 앱바 새로고침 버튼도 이 메서드를 쓴다 (당겨서 새로고침과 동일 경로).
  int _tick = 0;

  Future<void> refreshAll() async {
    await context.read<GymState>().loadMine();
    if (mounted) setState(() => _tick++);
  }

  @override
  Widget build(BuildContext context) {
    final gym = widget.gymState.membership.gym!;
    return RefreshIndicator(
      onRefresh: refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(HyphenTokens.sp3),
        children: [
          // 불러오기가 실패한 날에도 요일 줄은 그려진다 — 그대로 두면 '게시된
          // WOD 없음' 으로 읽혀 코치가 안 올린 것처럼 보인다. 실패는 실패라고
          // 먼저 말한다 (2026-08-12).
          if (widget.gymState.error != null) ...[
            HkInlineError(widget.gymState.error!, onRetry: refreshAll),
            const SizedBox(height: HyphenTokens.sp2),
          ],
          WeekBoard(key: ValueKey('week-$_tick'), gymState: widget.gymState),
          // 박스 정보·공지는 맨 아래 (자주 보는 것이 아니다 — 접힌 줄로 유지).
          const SizedBox(height: HyphenTokens.sp3),
          const Divider(height: 1, color: HyphenTokens.border, thickness: 1),
          _GymInfoAccordion(gym: gym),
          const _AnnouncementsAccordion(),
        ],
      ),
    );
  }
}

/// v1.26 (2026-06-11): 박스 공지를 WOD 보드 상단으로 — Rehab 탭 전환에 따라
/// 공지 노출처를 WOD(여기) + Attend(MessagingFeed) 로 이원화.
/// 기본 접힘 — 최신 공지 1건 헤드라인. 펼치면 최신 3건 (pinned 우선).
class _AnnouncementsAccordion extends StatelessWidget {
  const _AnnouncementsAccordion();

  @override
  Widget build(BuildContext context) {
    final items = [...context.watch<AnnouncementsState>().items]
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    if (items.isEmpty) return const SizedBox.shrink();
    final top = items.take(3).toList();
    final latest = top.first;
    final preview = latest.title.isNotEmpty ? latest.title : latest.body;

    return HkCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(top: HyphenTokens.sp2),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: HyphenTokens.sp3,
            vertical: 2,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            HyphenTokens.sp3,
            0,
            HyphenTokens.sp3,
            HyphenTokens.sp3,
          ),
          collapsedIconColor: HyphenTokens.muted,
          iconColor: HyphenTokens.muted,
          title: const HkSectionLabel('공지'),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              preview,
              style: HyphenTokens.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          children: [for (final a in top) AnnouncementRow(item: a)],
        ),
      ),
    );
  }
}

/// v1.25 (2026-06-02): Notice 상단 박스 기본정보(GymInfoCard) → WOD 탭 최상단 아코디언.
/// (v1.26: Notice 탭은 Rehab 탭으로 전환 — 공지는 위 _AnnouncementsAccordion 참조.)
class _GymInfoAccordion extends StatelessWidget {
  final GymSummary gym;
  const _GymInfoAccordion({required this.gym});

  @override
  Widget build(BuildContext context) {
    final loc = gym.location.trim();
    final sub = loc.isNotEmpty ? '${gym.name} · $loc' : gym.name;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        childrenPadding: EdgeInsets.zero,
        collapsedIconColor: HyphenTokens.muted,
        iconColor: HyphenTokens.muted,
        title: const HkSectionLabel('체육관 정보'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            sub,
            style: HyphenTokens.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        children: [
          const SizedBox(height: HyphenTokens.sp2),
          GymInfoCard(gym: gym, margin: EdgeInsets.zero),
        ],
      ),
    );
  }
}
