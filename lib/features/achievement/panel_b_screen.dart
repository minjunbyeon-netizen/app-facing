// v1.20 Phase 2.5: Panel B 20-title 갤러리 화면.
//
// reference/gamification.md §2 Panel B.
// 흑백 카드 그리드 (rarity 색 thin bar). 잠금/해금 시각 분기.
// 데이터: titles_catalog.dart kPanelBTitles + PanelBUnlocker.unlockedCodes(signals).
//
// signals 추론:
//  - totalSessions: WodHistory length
//  - benchmarkCount: ProfileState.benchmarks.length
//  - hasGym: GymState.hasGym
//  - 1RM (BS/FS/Snatch): ProfileState.benchmarks
//  - 시간대 카운트는 history.createdAt.hour 분류
//  - 주말 세션: weekday >= 6
// 백엔드 trigger 통합 전 임시.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/season_badges.dart';
import '../../core/theme.dart';
import '../../core/titles_catalog.dart';
import '../gym/gym_state.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';
import '../profile/profile_state.dart';

class PanelBScreen extends StatefulWidget {
  const PanelBScreen({super.key});

  @override
  State<PanelBScreen> createState() => _PanelBScreenState();
}

class _PanelBScreenState extends State<PanelBScreen> {
  Future<List<WodHistoryItem>>? _historyFuture;
  Future<List<String>>? _seasonBadgesFuture;

  @override
  void initState() {
    super.initState();
    final api = context.read<ApiClient>();
    _historyFuture = HistoryRepository(api).listWodHistory(limit: 500);
    _seasonBadgesFuture = SeasonBadgeService.unlockedCodes();
  }

  TitleUnlockSignals _buildSignals(
    List<WodHistoryItem> history,
    ProfileState profile,
    GymState gym,
  ) {
    int beforeSix = 0;
    int afterTen = 0;
    int weekend = 0;
    for (final h in history) {
      final d = h.createdAt.toLocal();
      if (d.hour < 6) beforeSix++;
      if (d.hour >= 22) afterTen++;
      if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
        weekend++;
      }
    }
    final bs = profile.benchmarks['back_squat_1rm_lb'];
    final fs = profile.benchmarks['front_squat_1rm_lb'];
    final sn = profile.benchmarks['snatch_1rm_lb'];
    final fiveKm = profile.benchmarks['run_5km_sec'];
    final twoKmRow = profile.benchmarks['row_2km_sec'];
    return TitleUnlockSignals(
      totalSessions: history.length,
      benchmarkCount: profile.benchmarks.length,
      hasGym: gym.hasGym,
      sessionsBefore6am: beforeSix,
      sessionsAfter10pm: afterTen,
      weekendSessions: weekend,
      backSquat1rmKg: bs == null ? null : bs * 0.4536,
      frontSquat1rmKg: fs == null ? null : fs * 0.4536,
      snatch1rmKg: sn == null ? null : sn * 0.4536,
      fiveKmSub25: fiveKm != null && fiveKm < 1500, // 25:00 = 1500s
      twoKmRowSub730: twoKmRow != null && twoKmRow < 450, // 7:30 = 450s
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileState>();
    final gym = context.watch<GymState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('PANEL B · TITLES'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<WodHistoryItem>>(
          future: _historyFuture,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FacingTokens.muted,
                  ),
                ),
              );
            }
            final history = snap.data ?? const <WodHistoryItem>[];
            final signals = _buildSignals(history, profile, gym);
            final unlocked = PanelBUnlocker.unlockedCodes(signals);
            final sorted = [...kPanelBTitles]
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            return ListView(
              padding: const EdgeInsets.all(FacingTokens.sp4),
              children: [
                _Header(
                  unlocked: unlocked.length,
                  total: kPanelBTitles.length,
                ),
                const SizedBox(height: FacingTokens.sp4),
                _SeasonBadgesPanel(future: _seasonBadgesFuture),
                const SizedBox(height: FacingTokens.sp4),
                const Text('TITLES', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp2),
                ...sorted.map((t) => _TitleCard(
                      title: t,
                      unlocked: unlocked.contains(t.code),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int unlocked;
  final int total;
  const _Header({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (unlocked / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$unlocked', style: FacingTokens.h1),
            const SizedBox(width: FacingTokens.sp1),
            Text('/ $total',
                style: FacingTokens.h3.copyWith(color: FacingTokens.muted)),
            const Spacer(),
            Text(
              '${(pct * 100).toInt()}%',
              style: FacingTokens.h3.copyWith(
                color: FacingTokens.accent,
                fontFeatures: FacingTokens.tabular,
              ),
            ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp1),
        Text('UNLOCKED', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        ClipRRect(
          borderRadius: BorderRadius.circular(FacingTokens.r1),
          child: Stack(children: [
            Container(height: 4, color: FacingTokens.border),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(height: 4, color: FacingTokens.accent),
            ),
          ]),
        ),
      ],
    );
  }
}

class _TitleCard extends StatelessWidget {
  final PanelBTitle title;
  final bool unlocked;
  const _TitleCard({required this.title, required this.unlocked});

  Color _rarityColor() {
    switch (title.rarity) {
      case 'Rare':
        return FacingTokens.accent;
      case 'Epic':
        return FacingTokens.tierElite;
      case 'Legendary':
        return FacingTokens.tierGames;
      case 'Common':
      default:
        return FacingTokens.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? _rarityColor() : FacingTokens.border;
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp2),
      padding: const EdgeInsets.fromLTRB(
        FacingTokens.sp4,
        FacingTokens.sp3,
        FacingTokens.sp4,
        FacingTokens.sp3,
      ),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border(
          left: BorderSide(color: color, width: 3),
          top: BorderSide(color: FacingTokens.border, width: 1),
          right: BorderSide(color: FacingTokens.border, width: 1),
          bottom: BorderSide(color: FacingTokens.border, width: 1),
        ),
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.label,
                        style: FacingTokens.h3.copyWith(
                          color: unlocked
                              ? FacingTokens.fg
                              : FacingTokens.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      title.rarity.toUpperCase(),
                      style: FacingTokens.micro.copyWith(
                        color: _rarityColor(),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  unlocked
                      ? title.captionKo
                      : '잠금 — ${title.requirement}',
                  style: FacingTokens.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: FacingTokens.sp3),
          Icon(
            unlocked ? Icons.check_circle : Icons.lock_outline,
            size: 18,
            color: unlocked ? FacingTokens.success : FacingTokens.muted,
          ),
        ],
      ),
    );
  }
}

/// 시즌 배지 통합 패널 — Phase 2.5.
class _SeasonBadgesPanel extends StatelessWidget {
  final Future<List<String>>? future;
  const _SeasonBadgesPanel({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: future,
      builder: (ctx, snap) {
        final codes = snap.data ?? const [];
        return Container(
          padding: const EdgeInsets.all(FacingTokens.sp3),
          decoration: BoxDecoration(
            color: FacingTokens.surface,
            border: Border.all(color: FacingTokens.border),
            borderRadius: BorderRadius.circular(FacingTokens.r2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined,
                      size: 16, color: FacingTokens.muted),
                  const SizedBox(width: FacingTokens.sp2),
                  Text(
                    'SEASON BADGES',
                    style: FacingTokens.sectionLabel.copyWith(
                      color: FacingTokens.fg,
                    ),
                  ),
                  const Spacer(),
                  Text('${codes.length}',
                      style: FacingTokens.body.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: FacingTokens.tabular,
                      )),
                ],
              ),
              const SizedBox(height: FacingTokens.sp2),
              if (codes.isEmpty)
                const Text(
                  'No season badge yet. 시즌 active 시 세션 1회로 자동 unlock.',
                  style: FacingTokens.caption,
                )
              else
                Wrap(
                  spacing: FacingTokens.sp2,
                  runSpacing: FacingTokens.sp2,
                  children: codes.map((code) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FacingTokens.sp3,
                        vertical: FacingTokens.sp1,
                      ),
                      decoration: BoxDecoration(
                        color: FacingTokens.bg,
                        border:
                            Border.all(color: FacingTokens.accent, width: 1),
                        borderRadius:
                            BorderRadius.circular(FacingTokens.r1),
                      ),
                      child: Text(
                        code.replaceFirst('SEASON_', ''),
                        style: FacingTokens.micro.copyWith(
                          color: FacingTokens.fg,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 외부에서 호출 가능한 navigation helper.
void openPanelB(BuildContext context) {
  Haptic.light();
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PanelBScreen()),
  );
}
