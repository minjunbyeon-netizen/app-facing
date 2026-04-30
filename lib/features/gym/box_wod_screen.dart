import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../../widgets/coach_badge.dart';
import '../../widgets/inbox_bell.dart';
import 'gym_repository.dart';
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

    // v1.22 (rev2): 3섹션(PAST/TODAY/UPCOMING) — 일자 헤더 중복 제거.
    final past = <_WodEntry>[];
    final todayList = <_WodEntry>[];
    final future = <_WodEntry>[];
    for (final w in allWods) {
      final d = DateTime.tryParse('${w.postDate}T00:00:00');
      if (d == null) continue;
      final diff = d.difference(todayDate).inDays;
      if (diff < -2 || diff > 2) continue;
      final wk = _wkLabel[(d.weekday - 1) % 7];
      final mm = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      final entry = _WodEntry(wod: w, dateLabel: '$mm.$dd · $wk', diff: diff);
      if (diff < 0) {
        past.add(entry);
      } else if (diff == 0) {
        todayList.add(entry);
      } else {
        future.add(entry);
      }
    }
    past.sort((a, b) => a.diff.compareTo(b.diff)); // -2 → -1
    future.sort((a, b) => a.diff.compareTo(b.diff)); // +1 → +2

    final isEmpty = past.isEmpty && todayList.isEmpty && future.isEmpty;

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
          if (isEmpty) ...[
            const Text("WOD", style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp3),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: FacingTokens.sp4),
              child: Text('어제 ~ 모레 게시된 WOD 없음.',
                  style: FacingTokens.caption),
            ),
          ] else ...[
            // PAST 섹션 — 1줄 압축 row.
            if (past.isNotEmpty) ...[
              const Text('PAST', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp1),
              const Divider(
                  height: 1, color: FacingTokens.border, thickness: 1),
              ...past.map((e) => _WodRow(
                    wod: e.wod,
                    dateLabel: e.dateLabel,
                    canDelete: gymState.isOwner,
                    isToday: false,
                    isFuture: false,
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
                        todayList.isNotEmpty
                            ? todayList.first.dateLabel
                            : _formatDate(todayDate),
                        style: FacingTokens.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: FacingTokens.sp1),
                  if (todayList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: FacingTokens.sp3),
                      child: Text('오늘 게시된 WOD 없음.',
                          style: FacingTokens.caption),
                    )
                  else
                    ...todayList.map((e) => _WodRow(
                          wod: e.wod,
                          dateLabel: e.dateLabel,
                          canDelete: gymState.isOwner,
                          isToday: true,
                          isFuture: false,
                        )),
                ],
              ),
            ),
            // UPCOMING 섹션 — 1줄 압축 row + lock (caption 제거: lock 아이콘으로 충분).
            if (future.isNotEmpty) ...[
              const SizedBox(height: FacingTokens.sp5),
              const Text('UPCOMING', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp1),
              const Divider(
                  height: 1, color: FacingTokens.border, thickness: 1),
              ...future.map((e) => _WodRow(
                    wod: e.wod,
                    dateLabel: e.dateLabel,
                    canDelete: gymState.isOwner,
                    isToday: false,
                    isFuture: true,
                  )),
            ],
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const wks = ['월', '화', '수', '목', '금', '토', '일'];
    final wk = wks[(d.weekday - 1) % 7];
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$mm.$dd · $wk';
  }
}

class _WodEntry {
  final GymWodPost wod;
  final String dateLabel;
  final int diff;
  const _WodEntry(
      {required this.wod, required this.dateLabel, required this.diff});
}

/// v1.22 (rev2): row 미니멀 — 일자 inline + 항상 toggle.
/// past/future는 muted+1줄, today는 펼친 상태 + Mark Done 가능.
class _WodRow extends StatefulWidget {
  final GymWodPost wod;
  final String dateLabel;
  final bool canDelete;
  final bool isToday;
  final bool isFuture;
  const _WodRow({
    required this.wod,
    required this.dateLabel,
    required this.canDelete,
    required this.isToday,
    required this.isFuture,
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

  Widget _dot() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text('·',
            style: TextStyle(color: FacingTokens.muted, fontSize: 12)),
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

  /// v1.20: Start 버튼 없이 바로 결과 입력. v1.22: 미래 일자에는 진입 차단.
  void _openResultSheet(BuildContext context) {
    if (widget.isFuture) return;
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
                    wod.wodType.toUpperCase(),
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
                  if (widget.isFuture)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.lock_outline,
                          size: 14, color: FacingTokens.muted),
                    ),
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
                      onPressed: widget.isFuture
                          ? null
                          : () => _openResultSheet(context),
                      icon: Icon(
                        widget.isFuture
                            ? Icons.lock_outline
                            : Icons.check,
                        size: 16,
                      ),
                      label: Text(widget.isFuture
                          ? 'Not yet'
                          : 'Mark Done'),
                      style: TextButton.styleFrom(
                        foregroundColor: widget.isFuture
                            ? FacingTokens.muted
                            : FacingTokens.accent,
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
            '${widget.wod.wodType.toUpperCase()} · ${widget.wod.postDate}',
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
