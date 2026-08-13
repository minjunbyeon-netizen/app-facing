import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/level_system.dart';
import '../../core/pr_detector.dart';
import '../../core/scoring.dart';
import '../../core/streak_freeze.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../core/titles_catalog.dart';
import '../../core/weak_insight.dart';
import '../../core/worn_title_store.dart';
import '../../widgets/fkit.dart';
import '../../widgets/tier_badge.dart';
import '../achievement/achievement_state.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';
import '../home/benchmark_sheet.dart';
import '../profile/profile_state.dart';

/// ENGINE 섹션 — **현재 어느 화면에도 붙어 있지 않다** (v2.6 · 2026-08-12 사용자
/// 지시 "engine 은 우리가 쓸 데 없다").
///
/// 프로필(mypage_screen.dart)에서 진입점만 끊고 코드는 여기 보존한다
/// (CLAUDE.md "숨김 = 코드 보존"). 같은 데이터를 쓰는 온보딩 `/onboarding/grade`·
/// 벤치마크 시트는 그대로 살아 있으므로, 다시 보이게 하려면 프로필
/// `MyPageScreen` children 에 `ScoreSection()` 한 줄을 되돌리면 된다.
///
/// v1.23 (2026-06-02) 재배치 — Home HeroCard 의 점수 컨텐츠를 Profile 로 이관.
/// 담백 버전: radar·sparkline **그래프 제거**, 숫자만 유지.
/// Tier 배지 · Engine 점수 · LV pill · 칭호 pill · 6 카테고리 숫자칩 · 트렌드 delta · 약점.
class ScoreSection extends StatefulWidget {
  const ScoreSection({super.key});

  @override
  State<ScoreSection> createState() => _ScoreSectionState();
}

class _ScoreSectionState extends State<ScoreSection> {
  /// QA 2026-06-11 #1: Home _LevelCard 와 동일 입력으로 LV 계산해야
  /// 두 화면 레벨이 일치. limit 도 Home 과 같은 200 사용.
  static const int _kHistoryLimit = 200;

  Future<List<EngineSnapshotRecord>>? _engineFuture;
  Future<List<WodHistoryItem>>? _historyFuture;
  String? _wornTitleCode;
  DateTime? _freezeUse;

  @override
  void initState() {
    super.initState();
    final repo = HistoryRepository(context.read<ApiClient>());
    _engineFuture = repo.listEngineSnapshots(limit: 12);
    _historyFuture = repo.listWodHistory(limit: _kHistoryLimit);
    StreakFreezeStore.lastUse().then((dt) {
      if (mounted) setState(() => _freezeUse = dt);
    });
    WornTitleStore.get().then((code) {
      if (mounted) setState(() => _wornTitleCode = code);
    });
  }

  /// 현재 streak — Home _GamificationBody._currentStreak 와 동일 로직.
  /// freezeUse 가 있으면 missing day 1일 보호.
  int _currentStreak(List<WodHistoryItem> records) {
    final days = records
        .map((r) {
          final d = r.createdAt.toLocal();
          return DateTime(d.year, d.month, d.day);
        })
        .toSet();
    if (days.isEmpty) return 0;
    final today = DateTime.now();
    DateTime cursor = DateTime(today.year, today.month, today.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    bool freezeAvailable = _freezeUse != null;
    int count = 0;
    while (true) {
      if (days.contains(cursor)) {
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (freezeAvailable) {
        freezeAvailable = false;
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return count;
  }

  int _catScore(Map<String, dynamic>? grade, String key) {
    if (grade == null) return 0;
    final data = grade[key];
    if (data is! Map) return 0;
    final s = data['score'];
    if (s is! num) return 0;
    return engineScoreTo100(s);
  }

  static PanelBTitle? _findTitle(String? code) {
    if (code == null) return null;
    for (final t in kPanelBTitles) {
      if (t.code == code) return t;
    }
    return null;
  }

  static Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'Rare':
        return FacingTokens.accent;
      case 'Epic':
        return FacingTokens.tierElite;
      case 'Legendary':
        return FacingTokens.tierGames;
      default:
        return FacingTokens.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final achState = context.watch<AchievementState>();
    final g = p.gradeResult;
    final num? n =
        g?['overall_number'] is num ? g!['overall_number'] as num : null;
    final tier = Tier.fromOverallNumber(n);
    final score100 = engineScoreTo100(g?['overall_score']);
    final hasScore = score100 > 0;
    // QA 2026-06-11 #1: Home _LevelCard 와 동일 변환 ((n ?? 1).toInt()) —
    // round() 사용 시 소수 overall_number 에서 tierXp 가 갈라짐.
    final tierNum = (n ?? 1).toInt();

    // 온보딩 전 — 안내만.
    if (n == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ENGINE', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            const Text('온보딩 완료 후 표시.', style: FacingTokens.caption),
            const SizedBox(height: FacingTokens.sp3),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/onboarding/basic'),
              child: const Text('온보딩 시작'),
            ),
          ],
        ),
      );
    }

    final cats = <(String, int)>[
      ('POWER', _catScore(g, 'power')),
      ('OLYMPIC', _catScore(g, 'olympic')),
      ('GYMNASTICS', _catScore(g, 'gymnastics')),
      ('CARDIO', _catScore(g, 'cardio')),
      ('METCON', _catScore(g, 'metcon')),
      ('BODY', _catScore(g, 'body_composition')),
    ];
    final titleObj = _findTitle(_wornTitleCode);
    final achXp = achState.snapshot.unlocked.values.fold<int>(0, (sum, u) {
      final cat =
          achState.snapshot.catalog.where((c) => c.code == u.code).toList();
      if (cat.isEmpty) return sum;
      return sum + (LevelSystem.rarityXp[cat.first.rarity] ?? 20);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ENGINE', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          // Tier · Engine · LV · 칭호 — 한 줄 담백.
          // QA 2026-06-11 #1: streak·PR 누락으로 Home LEVEL 과 다른 LV 가
          // 표시되던 바인딩 버그 — Home _LevelCard 와 동일 입력으로 통일.
          FutureBuilder<List<WodHistoryItem>>(
            future: _historyFuture,
            builder: (_, snap) {
              final records = snap.data ?? const <WodHistoryItem>[];
              final bd = LevelSystem.compute(
                totalSessions: records.length,
                currentStreakDays: _currentStreak(records),
                tierNumber: tierNum,
                prCount: PrDetector.countPrs(records),
                achievementXp: achXp,
              );
              return Wrap(
                spacing: FacingTokens.sp2,
                runSpacing: FacingTokens.sp2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TierBadge(tier: tier, fontSize: 13),
                  if (hasScore)
                    Text(
                      'Engine $score100',
                      style: FacingTokens.body.copyWith(
                        color: tier.color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  FkBadge('LV ${bd.level}', color: tier.color),
                  if (titleObj != null)
                    FkBadge(
                      titleObj.label,
                      color: _rarityColor(titleObj.rarity),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: FacingTokens.sp2),
          // 6 카테고리 숫자 칩 (그래프 없음).
          LayoutBuilder(
            builder: (ctx, bc) {
              final chipW = (bc.maxWidth - FacingTokens.sp2 * 2) / 3;
              return Wrap(
                spacing: FacingTokens.sp2,
                runSpacing: FacingTokens.sp2,
                children: cats.map((c) {
                  final hasVal = c.$2 > 0;
                  return GestureDetector(
                    onTap: () {
                      Haptic.light();
                      showBenchmarkSheet(ctx, c.$1);
                    },
                    child: Container(
                      width: chipW,
                      // v2.5: 6칸이 두 줄로 134 를 먹었다 — 여백만 줄여 80 대로.
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: FacingTokens.sp2,
                      ),
                      decoration: BoxDecoration(
                        color: FacingTokens.surface,
                        border: Border.all(color: FacingTokens.border),
                        borderRadius: BorderRadius.circular(FacingTokens.r2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.$1,
                            style: FacingTokens.sectionLabel
                                .copyWith(letterSpacing: 0.6),
                          ),
                          Row(
                            children: [
                              Text(
                                hasVal ? '${c.$2}' : '—',
                                style: FacingTokens.body.copyWith(
                                  color: hasVal
                                      ? FacingTokens.fg
                                      : FacingTokens.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right,
                                  size: 13, color: FacingTokens.muted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: FacingTokens.sp2),
          // 트렌드 — delta 숫자만 (sparkline 그래프 제거).
          FutureBuilder<List<EngineSnapshotRecord>>(
            future: _engineFuture,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox.shrink();
              }
              final records = snap.data ?? const <EngineSnapshotRecord>[];
              if (records.length < 2) {
                return Text(
                  records.isEmpty
                      ? '기록 없음. Engine 측정 후 표시.'
                      : '추세는 기록 2회부터 표시.',
                  style: FacingTokens.caption,
                );
              }
              final sorted = [...records]
                ..sort((a, b) => a.scoredAt.compareTo(b.scoredAt));
              final values =
                  sorted.map((r) => engineScoreTo100(r.overallScore)).toList();
              final delta = values.last - values.first;
              return Text(
                delta > 0
                    ? '▲ +$delta · ${values.length} snapshots'
                    : (delta < 0
                        ? '▼ $delta · ${values.length} snapshots'
                        : 'Hold · ${values.length} snapshots'),
                style: FacingTokens.caption.copyWith(
                  color: delta > 0
                      ? FacingTokens.success
                      : (delta < 0
                          ? FacingTokens.warning
                          : FacingTokens.muted),
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
          const SizedBox(height: FacingTokens.sp2),
          // 약점 분석 (숫자 기반).
          WeaknessInline(scores: {
            'POWER': cats[0].$2,
            'OLYMPIC': cats[1].$2,
            'GYMNASTICS': cats[2].$2,
            'CARDIO': cats[3].$2,
            'METCON': cats[4].$2,
            'BODY': cats[5].$2,
          }),
        ],
      ),
    );
  }
}

/// 약점 분석 inline — 6 카테고리 점수에서 가장 약한 영역 1줄 코멘트.
/// [ScoreSection] 전용 — 같이 화면에서 내려왔다 (v2.6).
class WeaknessInline extends StatelessWidget {
  final Map<String, int> scores;
  const WeaknessInline({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    // QA 2026-06-11 #4: 미측정(0) 카테고리는 WEAKEST 산정에서 제외.
    // BODY "—"(미측정) 인데 "BODY · WEAKEST 0/100" 으로 잡히던 모순 해소.
    final measured = <String, int>{
      for (final e in scores.entries)
        if (e.value > 0) e.key: e.value,
    };
    if (measured.isEmpty) return const SizedBox.shrink();
    final insight = analyzeWeakness(measured);
    if (insight == null) return const SizedBox.shrink();
    final isBalanced = insight.weakestCategory == 'BALANCED';
    // QA 2026-06-11 #4: "(베타 샘플 코멘트 · AI 분석은 추후 제공)" 류
    // 개발 메모 줄은 사용자 노출 금지 — 표시 직전 제거.
    final commentText = insight.comment
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('('))
        .join('\n')
        .trim();

    return Container(
      padding: const EdgeInsets.all(FacingTokens.sp3),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border.all(color: FacingTokens.border),
        borderRadius: BorderRadius.circular(FacingTokens.r3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 36,
            color: isBalanced ? FacingTokens.success : FacingTokens.accent,
          ),
          const SizedBox(width: FacingTokens.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBalanced ? '균형' : '${insight.weakestCategory} · 약점',
                  style: FacingTokens.microLabel.copyWith(
                    color: isBalanced
                        ? FacingTokens.success
                        : FacingTokens.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(commentText, style: FacingTokens.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
