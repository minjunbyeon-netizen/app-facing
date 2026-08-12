import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/announcement.dart';
import '../../models/gym.dart';
import '../../widgets/coach_badge.dart';
import '../../widgets/fkit.dart';
import '../announcements/announcements_state.dart';
import '../../widgets/gym_info_card.dart';
import '../../widgets/inbox_bell.dart';
import '../presets/presets_screen.dart';
import '../wod_builder/wod_builder_screen.dart';
import 'coach_dashboard_screen.dart';
import 'gym_state.dart';
import 'week_board.dart';
import 'wod_post_screen.dart';

/// v1.26.1 (2026-06-11): 프리셋 계산(카큘레이터) 아코디언 임시 숨김 플래그.
const bool _kShowPresetAccordion = false;

/// v1.15.3: WOD 탭 진입점. GymState 상태 따라 4분기 렌더.
class BoxWodScreen extends StatelessWidget {
  const BoxWodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();

    Widget body;
    if (gs.isLoading && !gs.hasGym) {
      body = const FkLoading();
    } else if (!gs.hasGym) {
      body = const _NoGymEmpty();
    } else if (gs.membership.isPending) {
      body = _PendingState(gym: gs.membership.gym!);
    } else if (gs.membership.isRejected) {
      body = _RejectedState(gym: gs.membership.gym!);
    } else {
      // owner or approved member
      body = _WodList(gymState: gs);
    }

    // QA B-SEC-1: 박스명 'FACING' 스푸핑 가능. isOwner 단독 조건으로 강화.
    final canViewDashboard = gs.isOwner;
    return Scaffold(
      appBar: AppBar(
        title: const Text('WOD'),
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
              context.read<GymState>().loadMine();
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
              backgroundColor: FacingTokens.accent,
              foregroundColor: FacingTokens.fg,
              onPressed: () {
                Haptic.medium();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const WodPostScreen(),
                ));
              },
              icon: const Icon(Icons.add),
              label: const Text('WOD 게시'),
            )
          : null,
    );
  }
}

// _Centered 삭제 — FkLoading(widgets/fkit.dart)으로 대체 (v1.27 UI SSOT).

class _NoGymEmpty extends StatelessWidget {
  const _NoGymEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(FacingTokens.sp5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // v2.2 (H4): 빈 상태 제목이 12px 회색 sectionLabel 이라 히스토리 쪽
          // 빈 상태(h3 굵게)와 규격이 달랐다 — 같은 앱에서 "없음" 화면이 두
          // 종류로 보였다 (링코 F7). FkEmptyState 와 같은 h3 + caption 으로 통일.
          const Text(
            '박스 미가입',
            style: FacingTokens.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: FacingTokens.sp2),
          const Text(
            '박스 가입 시 코치 WOD 공개.',
            style: FacingTokens.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: FacingTokens.sp5),
          // v2.6 (2026-08-13 사용자 지시): '박스 찾기'·'박스 만들기(코치)' 삭제.
          // 1인 샵 전용 앱이라 박스는 코치 본인 것 하나뿐이다 — 찾을 목록도,
          // 만들 두 번째 박스도 없다. 회원이 들어오는 길은 코치가 준 가입 코드,
          // 또는 로그인 화면의 '박스 가입 신청' 둘뿐이다.
          // (GymSearchScreen·박스 생성 시트 코드는 보존 — "숨김 = 코드 보존")
          ElevatedButton(
            onPressed: () {
              Haptic.medium();
              Navigator.of(context).pushNamed('/signup/claim');
            },
            child: const Text('가입 코드 입력'),
          ),
        ],
      ),
    );
  }
}

// v2.6 (2026-08-13): 진입점은 끊었지만 코드는 남긴다 ("숨김 = 코드 보존").
// 1인 샵이 아닌 형태로 확장할 때 버튼 한 줄만 되살리면 그대로 동작한다.
// ignore: unused_element
void _showCreateGymSheet(BuildContext context) {
  final nameCtrl = TextEditingController();
  final locCtrl = TextEditingController();
  // QA B-GYM-1: 모달 닫힌 후 controller dispose 보장.
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: FacingTokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(FacingTokens.r4)),
    ),
    builder: (sheetCtx) {
      // /go 전수조사: 더블 탭 시 createGym API 중복 호출 방지 — _creating 플래그.
      var creating = false;
      return StatefulBuilder(builder: (innerCtx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(
            left: FacingTokens.sp4,
            right: FacingTokens.sp4,
            top: FacingTokens.sp4,
            bottom:
                MediaQuery.of(sheetCtx).viewInsets.bottom + FacingTokens.sp4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('박스 만들기', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp1),
              const Text('코치가 자기 박스를 생성합니다.',
                  style: FacingTokens.caption),
              const SizedBox(height: FacingTokens.sp4),
              TextField(
                controller: nameCtrl,
                enabled: !creating,
                decoration: const InputDecoration(labelText: 'Box Name'),
                maxLength: 80,
              ),
              const SizedBox(height: FacingTokens.sp2),
              TextField(
                controller: locCtrl,
                enabled: !creating,
                decoration: const InputDecoration(
                    labelText: 'Location (optional)'),
                maxLength: 200,
              ),
              const SizedBox(height: FacingTokens.sp4),
              ElevatedButton(
                onPressed: creating
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        Haptic.medium();
                        setSheet(() => creating = true);
                        final ok =
                            await sheetCtx.read<GymState>().createGym(
                                  name: name,
                                  location: locCtrl.text.trim(),
                                );
                        if (!sheetCtx.mounted) return;
                        Navigator.of(sheetCtx).pop();
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('박스 생성 실패. 이름 중복 확인.')),
                          );
                        }
                      },
                child: Text(creating ? 'Creating.' : 'Create'),
              ),
            ],
          ),
        );
      });
    },
  ).whenComplete(() {
    nameCtrl.dispose();
    locCtrl.dispose();
  });
}

class _PendingState extends StatelessWidget {
  final GymSummary gym;
  const _PendingState({required this.gym});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(FacingTokens.sp5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('승인 대기', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          Text(gym.name,
              style: FacingTokens.h3.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: FacingTokens.sp2),
          const Text(
            '코치 승인 대기 중. 승인되면 오늘의 WOD 표시.',
            style: FacingTokens.caption,
          ),
          const SizedBox(height: FacingTokens.sp5),
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
      padding: const EdgeInsets.all(FacingTokens.sp5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('거절됨', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          Text(gym.name, style: FacingTokens.h3),
          const SizedBox(height: FacingTokens.sp2),
          // v2.6: 박스가 하나뿐이라 "다른 박스" 는 존재하지 않는다.
          // 거절 사유는 코치에게 직접 묻는 것이 유일한 다음 행동이다.
          const Text('가입이 승인되지 않았습니다. 코치에게 문의해 주세요.',
              style: FacingTokens.caption),
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
  const _WodList({required this.gymState});

  @override
  State<_WodList> createState() => _WodListState();
}

class _WodListState extends State<_WodList> {
  // 당겨서 새로고침은 WOD(GymState) 와 수업(WeekBoard 내부 fetch) 둘 다 다시
  // 받아야 한다. key 를 갈아 WeekBoard 를 새로 만드는 것이 가장 단순한 배선.
  int _tick = 0;

  Future<void> _refresh() async {
    await context.read<GymState>().loadMine();
    if (mounted) setState(() => _tick++);
  }

  @override
  Widget build(BuildContext context) {
    final gym = widget.gymState.membership.gym!;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(FacingTokens.sp3),
        children: [
          // 불러오기가 실패한 날에도 요일 줄은 그려진다 — 그대로 두면 '게시된
          // WOD 없음' 으로 읽혀 코치가 안 올린 것처럼 보인다. 실패는 실패라고
          // 먼저 말한다 (2026-08-12).
          if (widget.gymState.error != null) ...[
            _LoadErrorBanner(
              message: widget.gymState.error!,
              onRetry: _refresh,
            ),
            const SizedBox(height: FacingTokens.sp2),
          ],
          WeekBoard(
            key: ValueKey('week-$_tick'),
            gymState: widget.gymState,
          ),
          // 박스 정보·공지는 맨 아래 (자주 보는 것이 아니다 — 접힌 줄로 유지).
          const SizedBox(height: FacingTokens.sp3),
          const Divider(height: 1, color: FacingTokens.border, thickness: 1),
          _GymInfoAccordion(gym: gym),
          const _AnnouncementsAccordion(),
          // v1.26.1: 프리셋 계산 아코디언은 당분간 숨김 (사용자 지시 2026-06-11).
          // 복원 시 _kShowPresetAccordion = true 한 줄.
          if (_kShowPresetAccordion) ...[
            const SizedBox(height: FacingTokens.sp5),
            const Divider(height: 1, color: FacingTokens.border, thickness: 1),
            const _PresetAccordion(),
          ],
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
      padding: const EdgeInsets.only(left: FacingTokens.sp3),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border.all(color: FacingTokens.warning),
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: FacingTokens.caption.copyWith(color: FacingTokens.warning),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          FkButton.tertiary('다시 시도', neutral: true, onPressed: onRetry),
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
      margin: const EdgeInsets.only(top: FacingTokens.sp2),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border.all(color: FacingTokens.border),
        borderRadius: BorderRadius.circular(FacingTokens.r3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(
              horizontal: FacingTokens.sp3, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(
              FacingTokens.sp3, 0, FacingTokens.sp3, FacingTokens.sp3),
          collapsedIconColor: FacingTokens.muted,
          iconColor: FacingTokens.muted,
          title: const Text('공지', style: FacingTokens.sectionLabel),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              preview,
              style: FacingTokens.caption,
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
      padding: const EdgeInsets.only(bottom: FacingTokens.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.pinned) ...[
                const Icon(Icons.push_pin_outlined,
                    size: 14, color: FacingTokens.muted),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  item.title.isNotEmpty ? item.title : '공지',
                  style: FacingTokens.body
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: FacingTokens.sp2),
              Text(dateLabel, style: FacingTokens.micro),
            ],
          ),
          if (item.body.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.body,
              style: FacingTokens.caption,
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
        collapsedIconColor: FacingTokens.muted,
        iconColor: FacingTokens.muted,
        title: const Text('박스 정보', style: FacingTokens.sectionLabel),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            sub,
            style: FacingTokens.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        children: [
          const SizedBox(height: FacingTokens.sp2),
          GymInfoCard(gym: gym, margin: EdgeInsets.zero),
        ],
      ),
    );
  }
}

/// v1.23 Phase 2: Home 의 "CALCULATE WOD" 카테고리를 WOD 탭 하단으로 이관.
/// 참조자료용 — 기본 접힘. 펼치면 Girls/Heroes/Games/Custom 프리셋 페이싱 계산 진입.
class _PresetAccordion extends StatelessWidget {
  const _PresetAccordion();

  void _openPreset(BuildContext context, String filter, String title) {
    Haptic.medium();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PresetsScreen(
        initialFilter: filter,
        lockFilter: true,
        titleOverride: title,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        childrenPadding: EdgeInsets.zero,
        collapsedIconColor: FacingTokens.muted,
        iconColor: FacingTokens.muted,
        title: const Text('WOD 계산', style: FacingTokens.sectionLabel),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            'Preset pacing · Girls · Heroes · Games · Custom',
            style: FacingTokens.caption,
          ),
        ),
        children: [
          _PresetRow(
            title: 'Girls',
            subtitle: 'Fran · Grace · Helen · Diane',
            onTap: () => _openPreset(context, 'girl', 'GIRLS WODS'),
          ),
          const Divider(height: 1, color: FacingTokens.border),
          _PresetRow(
            title: 'Heroes',
            subtitle: 'Murph · DT · JT · Michael',
            onTap: () => _openPreset(context, 'hero', 'HERO WODS'),
          ),
          const Divider(height: 1, color: FacingTokens.border),
          _PresetRow(
            title: 'Games',
            subtitle: 'Amanda .45 · Jackie Pro · 2421 ...',
            onTap: () => _openPreset(context, 'games', 'GAMES WODS'),
          ),
          const Divider(height: 1, color: FacingTokens.border),
          _PresetRow(
            title: '커스텀',
            subtitle: '동작·횟수 직접 구성. For Time 전용.',
            onTap: () {
              Haptic.medium();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const WodBuilderScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _PresetRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: FacingTokens.sp3,
          horizontal: 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FacingTokens.body
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: FacingTokens.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: FacingTokens.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
