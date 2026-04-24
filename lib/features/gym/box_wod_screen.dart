import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/shell_nav_bus.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../wod_session/wod_session_screen.dart';
import 'coach_dashboard_screen.dart';
import 'gym_search_screen.dart';
import 'gym_state.dart';
import 'wod_post_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('WOD'),
        actions: [
          if (gs.isOwner)
            IconButton(
              tooltip: 'Manage Members',
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
            '박스에 가입하면 코치의 오늘 WOD을 볼 수 있다.',
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: FacingTokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(FacingTokens.r4)),
    ),
    builder: (sheetCtx) {
      return Padding(
        padding: EdgeInsets.only(
          left: FacingTokens.sp4,
          right: FacingTokens.sp4,
          top: FacingTokens.sp4,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + FacingTokens.sp4,
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
              decoration: const InputDecoration(labelText: 'Box Name'),
              maxLength: 80,
            ),
            const SizedBox(height: FacingTokens.sp2),
            TextField(
              controller: locCtrl,
              decoration: const InputDecoration(labelText: 'Location (optional)'),
              maxLength: 200,
            ),
            const SizedBox(height: FacingTokens.sp4),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Haptic.medium();
                final ok = await sheetCtx.read<GymState>().createGym(
                      name: name,
                      location: locCtrl.text.trim(),
                    );
                if (!sheetCtx.mounted) return;
                Navigator.of(sheetCtx).pop();
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('박스 생성 실패. 이름 중복 확인.')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      );
    },
  );
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
            '코치 승인 대기 중. 승인되면 오늘의 WOD이 표시됨.',
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

class _WodList extends StatelessWidget {
  final GymState gymState;
  const _WodList({required this.gymState});

  @override
  Widget build(BuildContext context) {
    final gym = gymState.membership.gym!;
    final wods = gymState.todayWods;
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
          const Text("TODAY'S WOD", style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp3),
          if (wods.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: FacingTokens.sp4),
              child: Text('오늘 게시된 WOD 없음.', style: FacingTokens.caption),
            )
          else
            ...wods.map((w) => _WodCard(wod: w, canDelete: gymState.isOwner)),
        ],
      ),
    );
  }
}

class _WodCard extends StatelessWidget {
  final GymWodPost wod;
  final bool canDelete;
  const _WodCard({required this.wod, required this.canDelete});

  void _openSession(BuildContext context) {
    Haptic.medium();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WodSessionScreen(wod: wod),
    ));
  }

  @override
  Widget build(BuildContext context) {
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
          onTap: () => _openSession(context),
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
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: FacingTokens.muted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final ok = await _confirmDelete(context);
                          if (ok == true && context.mounted) {
                            Haptic.medium();
                            context.read<GymState>().deleteWod(wod.id);
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: FacingTokens.sp2),
                Text(wod.content, style: FacingTokens.body),
                const SizedBox(height: FacingTokens.sp3),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openSession(context),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FacingTokens.accent,
                        foregroundColor: FacingTokens.fg,
                        padding: const EdgeInsets.symmetric(
                          horizontal: FacingTokens.sp4,
                          vertical: FacingTokens.sp2,
                        ),
                      ),
                    ),
                    const SizedBox(width: FacingTokens.sp2),
                    TextButton.icon(
                      onPressed: () {
                        Haptic.light();
                        // v1.16 Sprint 11: Calc 탭(index 0) 딥링크.
                        context.read<ShellNavBus>().requestTab(0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Calc 탭 이동. WOD 구성 후 Split·Burst 계산.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calculate_outlined, size: 18),
                      label: const Text('Pacing'),
                    ),
                  ],
                ),
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
