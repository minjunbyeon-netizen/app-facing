import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/shell_nav_bus.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../../widgets/coach_badge.dart';
import '../announcements/announcements_screen.dart';
import '../leaderboard/box_leaderboard_screen.dart';
import '../messages/messages_screen.dart';
import 'wod_detail_screen.dart';
import 'coach_dashboard_screen.dart';
import 'gym_search_screen.dart';
import 'gym_state.dart';
import 'wod_post_screen.dart';
import 'wod_result_sheet.dart';

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
    // (Phase 2: 백엔드 role 필드 도입 시 admin role 추가)
    final canViewDashboard = gs.isOwner;
    // QA B-ST-7: && / || 우선순위 괄호 명시.
    final canMessage = (gs.hasGym && gs.membership.isApprovedMember) || gs.isOwner;
    return Scaffold(
      appBar: AppBar(
        title: const Text('WOD'),
        actions: [
          if (canViewDashboard) const CoachBadgeAction(),
          if (canMessage)
            IconButton(
              tooltip: 'Messages',
              icon: const Icon(Icons.mail_outline),
              onPressed: () {
                Haptic.light();
                // v1.20 (E1 fix): 회원 시점은 코치 thread 자동 시작.
                // 코치 시점은 전체 수신함. ownerHash 미노출 시 fallback 전체 수신함.
                final ownerHash = gs.membership.gym?.ownerHash;
                final isMemberWithOwner =
                    !gs.isOwner && ownerHash != null && ownerHash.isNotEmpty;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MessagesScreen(
                    withHash: isMemberWithOwner ? ownerHash : null,
                    withLabel: isMemberWithOwner ? 'Coach' : null,
                  ),
                ));
              },
            ),
          if (canMessage)
            IconButton(
              tooltip: 'Announcements',
              icon: const Icon(Icons.campaign_outlined),
              onPressed: () {
                Haptic.light();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AnnouncementsScreen(),
                ));
              },
            ),
          if (canMessage)
            IconButton(
              tooltip: 'Leaderboard',
              icon: const Icon(Icons.emoji_events_outlined),
              onPressed: () {
                Haptic.light();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const BoxLeaderboardScreen(),
                ));
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
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Haptic.light();
              context.read<GymState>().loadMine();
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

/// v1.21: kbox 스타일 날짜 그룹 — 그저께·어제(위, 블러) / 오늘(가운데, Today 배지·자동펼침)
/// / 내일·모레(아래, 약간 dim). 윈도우: -2 ~ +2 일.
class _WodList extends StatelessWidget {
  final GymState gymState;
  const _WodList({required this.gymState});

  static const List<String> _wkLabel = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final gym = gymState.membership.gym!;
    final allWods = gymState.wods;
    final now = DateTime.now().toLocal();
    final todayDate = DateTime(now.year, now.month, now.day);

    // 윈도우 -2 ~ +2 일 (그저께·어제·오늘·내일·모레).
    final groups = <String, List<GymWodPost>>{};
    for (final w in allWods) {
      final d = DateTime.tryParse('${w.postDate}T00:00:00');
      if (d == null) continue;
      final diff = d.difference(todayDate).inDays;
      if (diff < -2 || diff > 2) continue;
      groups.putIfAbsent(w.postDate, () => []).add(w);
    }
    final sortedKeys = groups.keys.toList()..sort(); // ascending: 그저께 → ... → 모레

    return RefreshIndicator(
      onRefresh: () => context.read<GymState>().loadMine(),
      child: ListView(
        padding: const EdgeInsets.all(FacingTokens.sp4),
        children: [
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
          if (sortedKeys.isEmpty) ...[
            const Text("WOD", style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp3),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: FacingTokens.sp4),
              child: Text('어제 ~ 모레 게시된 WOD 없음.',
                  style: FacingTokens.caption),
            ),
          ] else
            ...sortedKeys.map((key) {
              final d = DateTime.parse('${key}T00:00:00');
              final diff = d.difference(todayDate).inDays;
              final isToday = diff == 0;
              final wk = _wkLabel[(d.weekday - 1) % 7];
              final mm = d.month.toString().padLeft(2, '0');
              final dd = d.day.toString().padLeft(2, '0');
              final dateLabel = '$mm.$dd · $wk';
              final relLabel = switch (diff) {
                -2 => 'D-2',
                -1 => 'YESTERDAY',
                0 => 'TODAY',
                1 => 'TOMORROW',
                2 => 'D+2',
                _ => '',
              };
              // v1.22: 아코디언 도입 후 opacity 완화 (과거 0.7 / 미래 0.9 / 오늘 1.0).
              final opacity = isToday ? 1.0 : (diff < 0 ? 0.7 : 0.9);
              final isFuture = diff > 0;
              return Opacity(
                opacity: opacity,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: FacingTokens.sp4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(dateLabel,
                              style: FacingTokens.h3.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isToday
                                    ? FacingTokens.fg
                                    : FacingTokens.muted,
                              )),
                          const SizedBox(width: FacingTokens.sp2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? FacingTokens.accent
                                  : Colors.transparent,
                              border: Border.all(
                                color: isToday
                                    ? FacingTokens.accent
                                    : FacingTokens.border,
                                width: 1,
                              ),
                              borderRadius:
                                  BorderRadius.circular(FacingTokens.r1),
                            ),
                            child: Text(
                              relLabel,
                              style: FacingTokens.microLabel.copyWith(
                                color: isToday
                                    ? FacingTokens.fg
                                    : FacingTokens.muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // v1.22: 미래 일자 안내. Mark Done 잠금 사유 명시.
                      if (isFuture) ...[
                        const SizedBox(height: 2),
                        const Text(
                          '코치가 미리 게시. Mark Done은 당일부터.',
                          style: FacingTokens.caption,
                        ),
                      ],
                      const SizedBox(height: FacingTokens.sp2),
                      // v1.22: 아코디언 — 오늘만 펼침. 그 외 접힘 상태 클릭 시 펼침.
                      ...groups[key]!.map((w) => _WodCard(
                            wod: w,
                            canDelete: gymState.isOwner,
                            initiallyExpanded: isToday,
                            disableMarkDone: isFuture,
                          )),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// v1.22: 아코디언 + Mark Done 잠금 지원.
/// initiallyExpanded=true (오늘만): 펼침 상태 진입.
/// disableMarkDone=true (미래만): Mark Done 버튼 비활성 + "Not yet" 라벨.
class _WodCard extends StatefulWidget {
  final GymWodPost wod;
  final bool canDelete;
  final bool initiallyExpanded;
  final bool disableMarkDone;
  const _WodCard({
    required this.wod,
    required this.canDelete,
    required this.initiallyExpanded,
    required this.disableMarkDone,
  });

  @override
  State<_WodCard> createState() => _WodCardState();
}

class _WodCardState extends State<_WodCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() {
    Haptic.light();
    setState(() => _expanded = !_expanded);
  }

  Widget _versionChip(String label, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(
          color: accent ? FacingTokens.accent : FacingTokens.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(FacingTokens.r1),
      ),
      child: Text(
        label,
        style: FacingTokens.microLabel.copyWith(
          color: accent ? FacingTokens.accent : FacingTokens.muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Haptic.light();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WodDetailScreen(wod: widget.wod),
    ));
  }

  /// v1.20: Start 버튼 없이 바로 결과 입력. v1.22: 미래 일자에는 진입 차단.
  void _openResultSheet(BuildContext context) {
    if (widget.disableMarkDone) return;
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
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp3),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        borderRadius: BorderRadius.circular(FacingTokens.r3),
        border: Border.all(color: FacingTokens.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // v1.22: 접힘 상태 = 펼치기 / 펼침 상태 = 상세화면 진입.
          onTap: _expanded ? () => _openDetail(context) : _toggle,
          borderRadius: BorderRadius.circular(FacingTokens.r3),
          child: Padding(
            padding: const EdgeInsets.all(FacingTokens.sp4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(wod.wodType.toUpperCase(),
                        style: FacingTokens.sectionLabel.copyWith(
                          color: FacingTokens.accent,
                        )),
                    const SizedBox(width: FacingTokens.sp2),
                    if (wod.timeCapSec != null)
                      Text(wod.timeCapDisplay, style: FacingTokens.caption),
                    if (wod.rounds != null) ...[
                      const SizedBox(width: FacingTokens.sp2),
                      Text('${wod.rounds} rounds',
                          style: FacingTokens.caption),
                    ],
                    const Spacer(),
                    if (widget.canDelete)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: FacingTokens.muted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final ok = await _confirmDelete(context);
                          if (ok == true && context.mounted) {
                            Haptic.medium();
                            await context.read<GymState>().deleteWod(wod.id);
                          }
                        },
                      ),
                    // v1.22: 아코디언 토글 chevron.
                    IconButton(
                      icon: Icon(
                        _expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 22,
                      ),
                      color: FacingTokens.muted,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                      onPressed: _toggle,
                    ),
                  ],
                ),
                // v1.22: 접힘 상태 — 1줄 미리보기.
                if (!_expanded) ...[
                  const SizedBox(height: 2),
                  Text(
                    wod.content,
                    style: FacingTokens.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // v1.22: 펼침 상태 — 본 콘텐츠 + 액션.
                if (_expanded) ...[
                  if (wod.hasVersions) ...[
                    const SizedBox(height: FacingTokens.sp2),
                    Wrap(
                      spacing: FacingTokens.sp1,
                      children: [
                        _versionChip('RX', accent: true),
                        if (wod.scaledVersion != null &&
                            wod.scaledVersion!.isNotEmpty)
                          _versionChip('SCALED'),
                        if (wod.beginnerVersion != null &&
                            wod.beginnerVersion!.isNotEmpty)
                          _versionChip('BEGINNER'),
                      ],
                    ),
                  ],
                  const SizedBox(height: FacingTokens.sp2),
                  Text(wod.content, style: FacingTokens.body),
                  if (wod.roundsData.isNotEmpty) ...[
                    const SizedBox(height: FacingTokens.sp3),
                    ...wod.roundsData.asMap().entries.map((e) {
                      final i = e.key;
                      final r = e.value;
                      return Container(
                        margin:
                            const EdgeInsets.only(top: FacingTokens.sp1),
                        padding: const EdgeInsets.all(FacingTokens.sp2),
                        decoration: BoxDecoration(
                          color: FacingTokens.surfaceOverlay,
                          borderRadius:
                              BorderRadius.circular(FacingTokens.r1),
                          border: Border(
                            left: BorderSide(
                                color: FacingTokens.accent, width: 2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.label.isEmpty
                                  ? 'ROUND ${i + 1}'
                                  : r.label.toUpperCase(),
                              style: FacingTokens.microLabel.copyWith(
                                color: FacingTokens.accent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(r.content, style: FacingTokens.caption),
                            if (r.timeCapSec != null)
                              Text(
                                'cap ${r.timeCapSec! ~/ 60}:${(r.timeCapSec! % 60).toString().padLeft(2, '0')}',
                                style: FacingTokens.micro.copyWith(
                                    color: FacingTokens.muted),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (wod.scaleGuide != null &&
                      wod.scaleGuide!.isNotEmpty) ...[
                    const SizedBox(height: FacingTokens.sp3),
                    Container(
                      padding: const EdgeInsets.all(FacingTokens.sp3),
                      decoration: BoxDecoration(
                        color: FacingTokens.surfaceOverlay,
                        borderRadius:
                            BorderRadius.circular(FacingTokens.r2),
                        border: Border.all(color: FacingTokens.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SCALE GUIDE',
                              style: FacingTokens.microLabel),
                          const SizedBox(height: 2),
                          Text(wod.scaleGuide!,
                              style: FacingTokens.caption),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: FacingTokens.sp3),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          // v1.22: 미래 일자는 Mark Done 잠금.
                          onPressed: widget.disableMarkDone
                              ? null
                              : () => _openResultSheet(context),
                          icon: Icon(
                            widget.disableMarkDone
                                ? Icons.lock_outline
                                : Icons.check,
                            size: 18,
                          ),
                          label: Text(widget.disableMarkDone
                              ? 'Not yet'
                              : 'Mark Done'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.disableMarkDone
                                ? FacingTokens.border
                                : FacingTokens.accent,
                            foregroundColor: widget.disableMarkDone
                                ? FacingTokens.muted
                                : FacingTokens.fg,
                            padding: const EdgeInsets.symmetric(
                              horizontal: FacingTokens.sp4,
                              vertical: FacingTokens.sp2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: FacingTokens.sp2),
                      TextButton.icon(
                        onPressed: () {
                          Haptic.light();
                          context.read<ShellNavBus>().requestTab(0);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Calc 탭 이동. WOD 구성 후 Split·Burst 계산.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calculate_outlined,
                            size: 18),
                        label: const Text('Pacing'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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
