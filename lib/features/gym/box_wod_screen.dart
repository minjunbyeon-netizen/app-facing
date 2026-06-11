import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../../widgets/coach_badge.dart';
import '../../widgets/gym_info_card.dart';
import '../../widgets/inbox_bell.dart';
import '../presets/presets_screen.dart';
import '../wod_builder/wod_builder_screen.dart';
import 'gym_repository.dart';
import 'wod_detail_screen.dart';
import 'coach_dashboard_screen.dart';
import 'gym_search_screen.dart';
import 'gym_state.dart';
import 'wod_post_screen.dart';
import 'wod_result_sheet.dart';
import 'wod_type_label.dart';

/// v1.15.3: WOD 탭 진입점. GymState 상태 따라 4분기 렌더.
class BoxWodScreen extends StatelessWidget {
  const BoxWodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();

    Widget body;
    if (gs.isLoading && !gs.hasGym) {
      body = const _Centered(child: CircularProgressIndicator(
          color: FacingTokens.muted, strokeWidth: 2));
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
              label: const Text('Post WOD'),
            )
          : null,
    );
  }
}

class _Centered extends StatelessWidget {
  final Widget child;
  const _Centered({required this.child});
  @override
  Widget build(BuildContext context) => Center(child: child);
}

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
          const Text('NO BOX', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          const Text(
            '박스 가입 시 코치 WOD 공개.',
            style: FacingTokens.caption,
          ),
          const SizedBox(height: FacingTokens.sp5),
          ElevatedButton(
            onPressed: () {
              Haptic.medium();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const GymSearchScreen(),
              ));
            },
            child: const Text('Find Box'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          OutlinedButton(
            onPressed: () {
              Haptic.light();
              _showCreateGymSheet(context);
            },
            child: const Text('Create Box (Coach)'),
          ),
        ],
      ),
    );
  }
}

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
              const Text('CREATE BOX', style: FacingTokens.sectionLabel),
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
          const Text('PENDING', style: FacingTokens.sectionLabel),
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
            child: const Text('Refresh'),
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
          const Text('REJECTED', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          Text(gym.name, style: FacingTokens.h3),
          const SizedBox(height: FacingTokens.sp2),
          const Text('가입 거절. 다른 박스 검색 권장.',
              style: FacingTokens.caption),
          const SizedBox(height: FacingTokens.sp5),
          OutlinedButton(
            onPressed: () {
              Haptic.light();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const GymSearchScreen(),
              ));
            },
            child: const Text('Find Another'),
          ),
        ],
      ),
    );
  }
}

/// v1.24: 날짜별 아코디언 그룹 — 각 날짜 = ExpansionTile.
/// PAST/TODAY/UPCOMING 3섹션 유지. TODAY 그룹은 initiallyExpanded=true.
/// 같은 날짜에 복수 WOD 있어도 날짜 헤더 1개 + 하위 WOD 카드 목록으로 접힘.
class _WodList extends StatelessWidget {
  final GymState gymState;
  const _WodList({required this.gymState});

  static const List<String> _wkLabel = ['월', '화', '수', '목', '금', '토', '일'];

  static String _formatDate(DateTime d) {
    const wks = ['월', '화', '수', '목', '금', '토', '일'];
    final wk = wks[(d.weekday - 1) % 7];
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$mm.$dd($wk)';
  }

  /// 날짜별 그룹화 — 정렬 순서는 diff 오름차순 (−2 → +2).
  /// 반환: List<(date, diff, entries)> — diff는 그룹의 대표값(첫 entry).
  List<({DateTime date, int diff, String dateLabel, List<_WodEntry> entries})>
      _groupByDate(List<GymWodPost> allWods, DateTime todayDate) {
    final map = <String,
        ({
          DateTime date,
          int diff,
          String dateLabel,
          List<_WodEntry> entries
        })>{};

    for (final w in allWods) {
      final d = DateTime.tryParse('${w.postDate}T00:00:00');
      if (d == null) continue;
      final diff = d.difference(todayDate).inDays;
      if (diff < -2 || diff > 2) continue;
      final wk = _wkLabel[(d.weekday - 1) % 7];
      final mm = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      final dateLabel = '$mm.$dd($wk)';
      final key = w.postDate;
      if (!map.containsKey(key)) {
        map[key] = (
          date: d,
          diff: diff,
          dateLabel: dateLabel,
          entries: <_WodEntry>[],
        );
      }
      map[key]!.entries.add(
            _WodEntry(wod: w, dateLabel: dateLabel, diff: diff),
          );
    }

    final result = map.values.toList();
    result.sort((a, b) => a.diff.compareTo(b.diff));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final gym = gymState.membership.gym!;
    final allWods = gymState.wods;
    final now = DateTime.now().toLocal();
    final todayDate = DateTime(now.year, now.month, now.day);

    final groups = _groupByDate(allWods, todayDate);

    final pastGroups =
        groups.where((g) => g.diff < 0).toList();
    final todayGroups =
        groups.where((g) => g.diff == 0).toList();
    final futureGroups =
        groups.where((g) => g.diff > 0).toList();

    final isEmpty =
        pastGroups.isEmpty && todayGroups.isEmpty && futureGroups.isEmpty;

    return RefreshIndicator(
      onRefresh: () => context.read<GymState>().loadMine(),
      child: ListView(
        padding: const EdgeInsets.all(FacingTokens.sp4),
        children: [
          // v1.25: Notice 상단에 있던 박스 기본정보 → WOD 최상단 BOX INFO 아코디언.
          _GymInfoAccordion(gym: gym),
          const SizedBox(height: FacingTokens.sp3),
          const Divider(height: 1, color: FacingTokens.border, thickness: 1),
          const SizedBox(height: FacingTokens.sp4),
          Text(gym.name,
              style: FacingTokens.h3.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: FacingTokens.sp1),
          Row(
            children: [
              Text(gymState.todayIso, style: FacingTokens.caption),
              const SizedBox(width: FacingTokens.sp2),
              if (gymState.isOwner)
                Text('· OWNER',
                    style: FacingTokens.caption.copyWith(
                      color: FacingTokens.accent,
                      fontWeight: FontWeight.w700,
                    )),
            ],
          ),
          const SizedBox(height: FacingTokens.sp4),
          if (isEmpty) ...[
            const Text("WOD", style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp3),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: FacingTokens.sp4),
              child: Text('어제 ~ 모레 게시된 WOD 없음.',
                  style: FacingTokens.caption),
            ),
          ] else ...[
            // PAST 섹션
            if (pastGroups.isNotEmpty) ...[
              const Text('PAST', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp1),
              const Divider(
                  height: 1, color: FacingTokens.border, thickness: 1),
              ...pastGroups.map((g) => _DateAccordion(
                    dateLabel: g.dateLabel,
                    entries: g.entries,
                    isToday: false,
                    initiallyExpanded: false,
                    canDelete: gymState.isOwner,
                    isOwner: gymState.isOwner,
                  )),
              const SizedBox(height: FacingTokens.sp5),
            ],
            // TODAY 섹션 — accentSoft bg로 강조.
            Container(
              padding: const EdgeInsets.fromLTRB(
                FacingTokens.sp3,
                FacingTokens.sp3,
                FacingTokens.sp3,
                FacingTokens.sp2,
              ),
              decoration: BoxDecoration(
                color: FacingTokens.accentSoft,
                borderRadius: BorderRadius.circular(FacingTokens.r3),
                border: Border.all(
                  color: FacingTokens.accent.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('TODAY',
                          style: FacingTokens.sectionLabel.copyWith(
                            color: FacingTokens.accent,
                          )),
                      const SizedBox(width: FacingTokens.sp2),
                      Text(
                        todayGroups.isNotEmpty
                            ? todayGroups.first.dateLabel
                            : _formatDate(todayDate),
                        style: FacingTokens.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: FacingTokens.sp1),
                  if (todayGroups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: FacingTokens.sp3),
                      child: Text('오늘 게시된 WOD 없음.',
                          style: FacingTokens.caption),
                    )
                  else
                    // TODAY 그룹 — 날짜 헤더 숨기고 WOD 카드 바로 표시
                    // (TODAY 컨테이너 자체가 날짜 표시 역할)
                    ...todayGroups.expand((g) => g.entries).map(
                          (e) => e.wod.locked
                              ? _LockedWodBanner(
                                  dateLabel: e.dateLabel,
                                  wodType: e.wod.wodType,
                                  isMembershipExpired: true,
                                )
                              : _WodRow(
                                  wod: e.wod,
                                  dateLabel: e.dateLabel,
                                  canDelete: gymState.isOwner,
                                  isToday: true,
                                ),
                        ),
                ],
              ),
            ),
            // UPCOMING 섹션 — owner는 카드 표시, 일반 멤버는 lock 배너.
            if (futureGroups.isNotEmpty) ...[
              const SizedBox(height: FacingTokens.sp5),
              const Text('UPCOMING', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp1),
              const Divider(
                  height: 1, color: FacingTokens.border, thickness: 1),
              ...futureGroups.map((g) => _DateAccordion(
                    dateLabel: g.dateLabel,
                    entries: g.entries,
                    isToday: false,
                    initiallyExpanded: false,
                    canDelete: gymState.isOwner,
                    isOwner: gymState.isOwner,
                    isFuture: true,
                  )),
            ],
          ],
          // v1.23 Phase 2: Home 의 프리셋 카테고리 → WOD 탭 하단 참조 아코디언.
          const SizedBox(height: FacingTokens.sp5),
          const Divider(height: 1, color: FacingTokens.border, thickness: 1),
          const _PresetAccordion(),
        ],
      ),
    );
  }
}

/// v1.25 (2026-06-02): Notice 상단 박스 기본정보(GymInfoCard) → WOD 탭 최상단 아코디언.
/// Notice 는 새 글(쪽지·공지) 전용으로 비움. 기본 접힘, 펼치면 박스·코치·가격·수업시간.
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
        title: const Text('BOX INFO', style: FacingTokens.sectionLabel),
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
        title: const Text('CALCULATE WOD', style: FacingTokens.sectionLabel),
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
            title: 'Custom',
            subtitle: 'Build movements/reps. For Time only.',
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

/// v1.24: 날짜 아코디언 — ExpansionTile 기반.
/// title: "05.22(금)" + "N개" 카운트.
/// subtitle: 첫 프로그램 wodType preview.
/// children: 해당 날짜 WOD 목록.
class _DateAccordion extends StatelessWidget {
  final String dateLabel;
  final List<_WodEntry> entries;
  final bool isToday;
  final bool initiallyExpanded;
  final bool canDelete;
  final bool isOwner;
  final bool isFuture;

  const _DateAccordion({
    required this.dateLabel,
    required this.entries,
    required this.isToday,
    required this.initiallyExpanded,
    required this.canDelete,
    required this.isOwner,
    this.isFuture = false,
  });

  @override
  Widget build(BuildContext context) {
    final count = entries.length;
    // preview: 첫 번째 WOD wodType (+ "외 N건" if multiple)
    final firstType = entries.isNotEmpty
        ? wodTypeLabel(entries.first.wod.wodType)
        : '';
    final previewText = count > 1 ? '$firstType 외 ${count - 1}건' : firstType;

    return Theme(
      // ExpansionTile 기본 divider 제거
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        childrenPadding: EdgeInsets.zero,
        collapsedIconColor: FacingTokens.muted,
        iconColor: FacingTokens.muted,
        title: Row(
          children: [
            Text(
              dateLabel,
              style: FacingTokens.body.copyWith(
                fontWeight: FontWeight.w700,
                color: FacingTokens.fg,
              ),
            ),
            const SizedBox(width: FacingTokens.sp2),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: FacingTokens.surface,
                border: Border.all(color: FacingTokens.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$count',
                style: FacingTokens.micro.copyWith(
                  color: FacingTokens.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: count > 0
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  previewText,
                  style: FacingTokens.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        children: entries.map((e) {
          if (e.wod.locked) {
            return _LockedWodBanner(
              dateLabel: e.dateLabel,
              wodType: e.wod.wodType,
              isMembershipExpired: !isFuture,
            );
          }
          if (isFuture && !isOwner) {
            return _LockedWodBanner(
              dateLabel: e.dateLabel,
              wodType: e.wod.wodType,
              isMembershipExpired: false,
            );
          }
          return _WodRow(
            wod: e.wod,
            dateLabel: e.dateLabel,
            canDelete: canDelete,
            isToday: isToday,
          );
        }).toList(),
      ),
    );
  }
}

class _WodEntry {
  final GymWodPost wod;
  final String dateLabel;
  final int diff;
  const _WodEntry(
      {required this.wod, required this.dateLabel, required this.diff});
}

/// v1.23: locked WOD 카드 — 회원권 만료 시 내용 숨김 + 자물쇠 배너.
class _LockedWodBanner extends StatelessWidget {
  final String dateLabel;
  final String wodType;
  final bool isMembershipExpired; // true=회원권 만료, false=미래 WOD
  const _LockedWodBanner({
    required this.dateLabel,
    required this.wodType,
    required this.isMembershipExpired,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(
          vertical: FacingTokens.sp3, horizontal: FacingTokens.sp3),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border.all(color: FacingTokens.border),
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            color: isMembershipExpired ? FacingTokens.warning : FacingTokens.border,
          ),
          const SizedBox(width: FacingTokens.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: FacingTokens.microLabel.copyWith(color: FacingTokens.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  wodTypeLabel(wodType),
                  style: FacingTokens.body.copyWith(
                    color: FacingTokens.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isMembershipExpired)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '회원권 만료. 갱신 후 열람.',
                      style: FacingTokens.caption.copyWith(color: FacingTokens.warning),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            isMembershipExpired ? Icons.lock : Icons.lock_outline,
            size: 16,
            color: isMembershipExpired ? FacingTokens.warning : FacingTokens.muted,
          ),
        ],
      ),
    );
  }
}

/// v1.22 (rev2): row 미니멀 — 일자 inline + 항상 toggle.
/// past/future는 muted+1줄, today는 펼친 상태 + Mark Done 가능.
class _WodRow extends StatefulWidget {
  final GymWodPost wod;
  final String dateLabel;
  final bool canDelete;
  final bool isToday;
  const _WodRow({
    required this.wod,
    required this.dateLabel,
    required this.canDelete,
    required this.isToday,
  });

  @override
  State<_WodRow> createState() => _WodRowState();
}

class _WodRowState extends State<_WodRow> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isToday;
  }

  void _toggle() {
    Haptic.light();
    setState(() => _expanded = !_expanded);
  }

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text('·',
            style: FacingTokens.caption.copyWith(color: FacingTokens.muted)),
      );

  Widget _kv(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: FacingTokens.microLabel),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Haptic.light();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WodDetailScreen(wod: widget.wod),
    ));
  }

  void _openMsgSheet(BuildContext context) {
    final gs = context.read<GymState>();
    final gymId = gs.membership.gym?.id;
    if (gymId == null) return;
    Haptic.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FacingTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FacingTokens.r3)),
      ),
      builder: (_) => _MsgCoachSheet(
        gymId: gymId,
        wod: widget.wod,
      ),
    );
  }

  /// v1.20: Start 버튼 없이 바로 결과 입력.
  void _openResultSheet(BuildContext context) {
    Haptic.medium();
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WodResultSheet(wod: widget.wod),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wod = widget.wod;
    final isMinimal = !widget.isToday;
    final fgColor =
        isMinimal ? FacingTokens.muted : FacingTokens.fg;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // v1.22 rev2: 항상 toggle. Detail은 명시 버튼만.
        onTap: _toggle,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: FacingTokens.border, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(
            vertical: isMinimal ? FacingTokens.sp2 : FacingTokens.sp3,
            horizontal: 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 row — past/future는 일자 prefix + type · time · rounds · chevron
              Row(
                children: [
                  if (isMinimal) ...[
                    Text(
                      widget.dateLabel,
                      style: FacingTokens.microLabel.copyWith(
                        color: FacingTokens.muted,
                      ),
                    ),
                    _dot(),
                  ],
                  Text(
                    wodTypeLabel(wod.wodType),
                    style: FacingTokens.sectionLabel.copyWith(
                      color: isMinimal
                          ? FacingTokens.muted
                          : FacingTokens.accent,
                    ),
                  ),
                  if (wod.timeCapSec != null) ...[
                    _dot(),
                    Text(wod.timeCapDisplay,
                        style: FacingTokens.caption),
                  ],
                  if (wod.rounds != null) ...[
                    _dot(),
                    Text('${wod.rounds} rounds',
                        style: FacingTokens.caption),
                  ],
                  const Spacer(),
                  if (widget.canDelete && _expanded)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: FacingTokens.muted,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 28, minHeight: 28),
                      onPressed: () async {
                        final ok = await _confirmDelete(context);
                        if (ok == true && context.mounted) {
                          Haptic.medium();
                          await context.read<GymState>().deleteWod(wod.id);
                        }
                      },
                    ),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                    color: FacingTokens.muted,
                  ),
                ],
              ),
              // 본 콘텐츠 — 접힘 1줄 / 펼침 full.
              if (!_expanded) ...[
                const SizedBox(height: 4),
                Text(
                  wod.content,
                  style: FacingTokens.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (_expanded) ...[
                const SizedBox(height: FacingTokens.sp2),
                Text(
                  wod.content,
                  style: FacingTokens.body.copyWith(color: fgColor),
                ),
                if (wod.roundsData.isNotEmpty) ...[
                  ...wod.roundsData.asMap().entries.map((e) {
                    final i = e.key;
                    final r = e.value;
                    final label = r.label.isEmpty
                        ? 'R${i + 1}'
                        : r.label.toUpperCase();
                    return _kv(
                      label,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.content,
                              style: FacingTokens.caption),
                          if (r.timeCapSec != null)
                            Text(
                              'cap ${r.timeCapSec! ~/ 60}:${(r.timeCapSec! % 60).toString().padLeft(2, '0')}',
                              style: FacingTokens.micro,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
                if (wod.scaleGuide != null &&
                    wod.scaleGuide!.isNotEmpty)
                  _kv(
                    'SCALE',
                    Text(wod.scaleGuide!, style: FacingTokens.caption),
                  ),
                if (wod.hasVersions)
                  _kv(
                    'VERSIONS',
                    Text(
                      [
                        'RX',
                        if (wod.scaledVersion != null &&
                            wod.scaledVersion!.isNotEmpty)
                          'SCALED',
                        if (wod.beginnerVersion != null &&
                            wod.beginnerVersion!.isNotEmpty)
                          'BEGINNER',
                      ].join(' · '),
                      style: FacingTokens.caption.copyWith(
                        color: FacingTokens.fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: FacingTokens.sp3),
                // 액션 — TextButton으로 가볍게.
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _openResultSheet(context),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark Done'),
                      style: TextButton.styleFrom(
                        foregroundColor: FacingTokens.accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: FacingTokens.sp2,
                        ),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                    // 회원 전용: 코치에게 메시지 (owner는 숨김)
                    if (!context.watch<GymState>().isOwner) ...[
                      const SizedBox(width: FacingTokens.sp2),
                      TextButton.icon(
                        onPressed: () => _openMsgSheet(context),
                        icon: const Icon(Icons.chat_bubble_outline,
                            size: 15),
                        label: const Text('Message'),
                        style: TextButton.styleFrom(
                          foregroundColor: FacingTokens.muted,
                          padding: const EdgeInsets.symmetric(
                            horizontal: FacingTokens.sp2,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                    ],
                    const Spacer(),
                    TextButton(
                      onPressed: () => _openDetail(context),
                      style: TextButton.styleFrom(
                        foregroundColor: FacingTokens.muted,
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Detail →'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        title: const Text('Delete WOD?'),
        content: const Text('멤버에게 더 이상 보이지 않음.',
            style: FacingTokens.caption),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── 회원 → 코치 메시지 바텀시트 ───────────────────────────────────────────────

class _MsgCoachSheet extends StatefulWidget {
  final int gymId;
  final GymWodPost wod;
  const _MsgCoachSheet({required this.gymId, required this.wod});

  @override
  State<_MsgCoachSheet> createState() => _MsgCoachSheetState();
}

class _MsgCoachSheetState extends State<_MsgCoachSheet> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    try {
      final repo = GymRepository(context.read<ApiClient>());
      await repo.memberReport(
        gymId: widget.gymId,
        message: msg,
        wodId: widget.wod.id,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코치에게 전송됨.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전송 실패. 다시 시도.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          FacingTokens.sp4, FacingTokens.sp4, FacingTokens.sp4,
          FacingTokens.sp4 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: FacingTokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: FacingTokens.sp4),
          const Text('MESSAGE COACH', style: FacingTokens.sectionLabel),
          const SizedBox(height: 4),
          Text(
            '${wodTypeLabel(widget.wod.wodType)} · ${widget.wod.postDate}',
            style: FacingTokens.caption,
          ),
          const SizedBox(height: FacingTokens.sp3),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: 4,
            maxLength: 500,
            style: FacingTokens.body,
            decoration: InputDecoration(
              hintText: '오늘 무릎 통증 있어서 스케일드로 할게요.',
              hintStyle: FacingTokens.caption,
              filled: true,
              fillColor: FacingTokens.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FacingTokens.r2),
                borderSide: const BorderSide(color: FacingTokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FacingTokens.r2),
                borderSide: const BorderSide(color: FacingTokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FacingTokens.r2),
                borderSide:
                    const BorderSide(color: FacingTokens.accent, width: 1.5),
              ),
              counterStyle: FacingTokens.micro,
            ),
          ),
          const SizedBox(height: FacingTokens.sp3),
          ElevatedButton(
            onPressed: _sending ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: FacingTokens.accent,
              foregroundColor: FacingTokens.fg,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FacingTokens.r2),
              ),
            ),
            child: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: FacingTokens.fg, strokeWidth: 2),
                  )
                : const Text('Send'),
          ),
        ],
      ),
    );
  }
}
