import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/announcement.dart';
import '../../models/gym.dart';
import '../../widgets/coach_badge.dart';
import '../../widgets/hkit.dart';
import '../announcements/announcements_state.dart';
import '../../widgets/gym_info_card.dart';
import '../../widgets/inbox_bell.dart';
import 'coach_dashboard_screen.dart';
import 'gym_state.dart';
import 'week_board.dart';
import 'wod_post_screen.dart';

/// v1.15.3: WOD 탭 진입점. GymState 상태 따라 4분기 렌더.
class BoxWodScreen extends StatefulWidget {
  const BoxWodScreen({super.key});

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
      body = const _NoGymEmpty();
    } else if (gs.membership.isPending) {
      body = _PendingState(gym: gs.membership.gym!);
    } else if (gs.membership.isRejected) {
      body = _RejectedState(gym: gs.membership.gym!);
    } else {
      // owner or approved member
      body = _WodList(key: _listKey, gymState: gs);
    }

    // QA B-SEC-1: 박스명 'HYPHEN HQ' 스푸핑 가능. isOwner 단독 조건으로 강화.
    final canViewDashboard = gs.isOwner;
    return Scaffold(
      appBar: AppBar(
        // v3.0: 탭 표기 '수업' 과 화면 제목을 일치시킨다 (구 'WOD').
        title: const Text('수업'),
        // v1.22: AppBar 정리 — Messages/Announcements/Leaderboard 제거.
        //   Messages/Announcements → Inbox(NOTICE) 탭으로 통합 (Bell 단축).
        //   Leaderboard → Home Hero 영역(추후) 또는 Profile에서 진입.
        //   유지: CoachBadge(코치 표시) + Bell(공통) + Refresh + CoachDashboard(owner).
        actions: [
          if (canViewDashboard) const CoachBadgeAction(),
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
          if (canViewDashboard)
            IconButton(
              tooltip: 'Coach Dashboard',
              icon: const Icon(Icons.people_outline),
              onPressed: () {
                Haptic.light();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CoachDashboardScreen(),
                ));
              },
            ),
        ],
      ),
      body: SafeArea(child: body),
      floatingActionButton: gs.isOwner
          ? FloatingActionButton.extended(
              backgroundColor: HyphenTokens.accent,
              foregroundColor: HyphenTokens.fg,
              onPressed: () {
                Haptic.medium();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const WodPostScreen(),
                ));
              },
              icon: const Icon(Icons.add),
              label: const Text('수업 내용 게시'),
            )
          : null,
    );
  }
}

// _Centered 삭제 — HkLoading(widgets/hkit.dart)으로 대체 (v1.27 UI SSOT).

class _NoGymEmpty extends StatelessWidget {
  const _NoGymEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(HyphenTokens.sp5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // v2.2 (H4): 빈 상태 제목이 12px 회색 sectionLabel 이라 히스토리 쪽
          // 빈 상태(h3 굵게)와 규격이 달랐다 — 같은 앱에서 "없음" 화면이 두
          // 종류로 보였다 (링코 F7). HkEmptyState 와 같은 h3 + caption 으로 통일.
          const Text(
            '체육관 미가입',
            style: HyphenTokens.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: HyphenTokens.sp2),
          const Text(
            '가입 승인 시 수업 내용 공개.',
            style: HyphenTokens.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: HyphenTokens.sp5),
          // v2.6 (2026-08-13): '박스 찾기'·'박스 만들기(코치)' 삭제 — 1인 샵 전용이라
          // 찾을 목록도, 만들 두 번째 박스도 없다.
          // v2.7 (같은 날 사용자 지시): '가입 코드 입력' 도 삭제. 코드로 연결하면
          // 그 회원의 아이디·비밀번호를 언제 만드는지가 불분명했다. 가입은
          // **로그인 화면의 '회원 가입 신청' 한 길**뿐이다.
          const Text(
            '로그인 화면의 [회원 가입 신청] 으로 신청하면 '
            '코치가 승인한 뒤 이용할 수 있습니다.',
            style: HyphenTokens.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// v3.2 (2026-08-20 사용자 지시): 구 체육관 개설 시트(_showCreateGymSheet)
// 삭제 — 개설은 PC 웹 admin 전용 (README §제거된 기능 대장).

class _PendingState extends StatelessWidget {
  final GymSummary gym;
  const _PendingState({required this.gym});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(HyphenTokens.sp5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('승인 대기', style: HyphenTokens.sectionLabel),
          const SizedBox(height: HyphenTokens.sp2),
          Text(gym.name,
              style: HyphenTokens.h3.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: HyphenTokens.sp2),
          const Text(
            '코치 승인 대기 중. 승인되면 수업 내용 표시.',
            style: HyphenTokens.caption,
          ),
          const SizedBox(height: HyphenTokens.sp5),
          OutlinedButton(
            onPressed: () {
              Haptic.light();
              context.read<GymState>().loadMine();
            },
            child: const Text('새로고침'),
          ),
        ],
      ),
    );
  }
}

class _RejectedState extends StatelessWidget {
  final GymSummary gym;
  const _RejectedState({required this.gym});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(HyphenTokens.sp5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('거절됨', style: HyphenTokens.sectionLabel),
          const SizedBox(height: HyphenTokens.sp2),
          Text(gym.name, style: HyphenTokens.h3),
          const SizedBox(height: HyphenTokens.sp2),
          // v2.6: 박스가 하나뿐이라 "다른 박스" 는 존재하지 않는다.
          // 거절 사유는 코치에게 직접 묻는 것이 유일한 다음 행동이다.
          const Text('가입이 승인되지 않았습니다. 코치에게 문의해 주세요.',
              style: HyphenTokens.caption),
        ],
      ),
    );
  }
}

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
            _LoadErrorBanner(
              message: widget.gymState.error!,
              onRetry: refreshAll,
            ),
            const SizedBox(height: HyphenTokens.sp2),
          ],
          WeekBoard(
            key: ValueKey('week-$_tick'),
            gymState: widget.gymState,
          ),
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

/// WOD 불러오기 실패 — 한 줄 배너 + 다시 시도.
class _LoadErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _LoadErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: HyphenTokens.sp3),
      decoration: BoxDecoration(
        color: HyphenTokens.surface,
        border: Border.all(color: HyphenTokens.warning),
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: HyphenTokens.caption.copyWith(color: HyphenTokens.warning),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          HkButton.tertiary('다시 시도', neutral: true, onPressed: onRetry),
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

    return Container(
      margin: const EdgeInsets.only(top: HyphenTokens.sp2),
      decoration: BoxDecoration(
        color: HyphenTokens.surface,
        border: Border.all(color: HyphenTokens.border),
        borderRadius: BorderRadius.circular(HyphenTokens.r3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(
              horizontal: HyphenTokens.sp3, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(
              HyphenTokens.sp3, 0, HyphenTokens.sp3, HyphenTokens.sp3),
          collapsedIconColor: HyphenTokens.muted,
          iconColor: HyphenTokens.muted,
          title: const Text('공지', style: HyphenTokens.sectionLabel),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              preview,
              style: HyphenTokens.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          children: [
            for (final a in top) _AnnouncementRow(item: a),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementRow extends StatelessWidget {
  final GymAnnouncement item;
  const _AnnouncementRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final d = item.createdAt.toLocal();
    final dateLabel =
        '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.pinned) ...[
                const Icon(Icons.push_pin_outlined,
                    size: 14, color: HyphenTokens.muted),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  item.title.isNotEmpty ? item.title : '공지',
                  style: HyphenTokens.body
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: HyphenTokens.sp2),
              Text(dateLabel, style: HyphenTokens.micro),
            ],
          ),
          if (item.body.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.body,
              style: HyphenTokens.caption,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
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
        title: const Text('체육관 정보', style: HyphenTokens.sectionLabel),
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

