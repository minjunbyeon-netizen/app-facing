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
import '../../core/futures.dart';
import '../../core/haptic.dart';
import '../../core/pr_detector.dart';
import '../../core/share_count_store.dart';
import '../../core/theme.dart';
import '../../core/titles_catalog.dart';
import '../../core/worn_title_store.dart';
import '../gym/gym_state.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';
import '../inbox/inbox_state.dart';
import '../profile/profile_state.dart';

class PanelBScreen extends StatefulWidget {
  const PanelBScreen({super.key});

  @override
  State<PanelBScreen> createState() => _PanelBScreenState();
}

class _PanelBScreenState extends State<PanelBScreen> {
  Future<List<WodHistoryItem>>? _historyFuture;
  /// /go Tier 3: 현재 착용 칭호 코드.
  String? _wornCode;
  /// /go 7 (B2): 누적 공유 횟수 (PB_PHOTO_FINISH 등 signal).
  int _shareCount = 0;

  @override
  void initState() {
    super.initState();
    final api = context.read<ApiClient>();
    _historyFuture = retainError(HistoryRepository(api).listWodHistory(limit: 500));
    _loadWornCode();
    _loadShareCount();
  }

  Future<void> _loadShareCount() async {
    final n = await ShareCountStore.get();
    if (!mounted) return;
    setState(() => _shareCount = n);
  }

  Future<void> _loadWornCode() async {
    final code = await WornTitleStore.get();
    if (!mounted) return;
    setState(() => _wornCode = code);
  }

  Future<void> _toggleWorn(String code) async {
    Haptic.medium();
    if (_wornCode == code) {
      await WornTitleStore.clear();
      if (!mounted) return;
      setState(() => _wornCode = null);
    } else {
      await WornTitleStore.set(code);
      if (!mounted) return;
      setState(() => _wornCode = code);
    }
  }

  TitleUnlockSignals _buildSignals(
    List<WodHistoryItem> history,
    ProfileState profile,
    GymState gym,
    InboxState inbox,
  ) {
    int beforeSix = 0;
    int afterTen = 0;
    int weekend = 0;
    bool freshStart = false;
    final dayMap = <String, int>{};
    for (final h in history) {
      final d = h.createdAt.toLocal();
      if (d.hour < 6) beforeSix++;
      if (d.hour >= 22) afterTen++;
      if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
        weekend++;
      }
      if (d.month == 1 && d.day <= 7) freshStart = true;
      final key = '${d.year}-${d.month}-${d.day}';
      dayMap[key] = (dayMap[key] ?? 0) + 1;
    }
    final doubleSessionDays = dayMap.values.where((c) => c >= 2).length;

    // v2.7 (엔진 폐기, 2026-08-13): /api/v1/history/engine 제거로 engine snapshot
    // 신호 소스 소멸 — PB_IRON_LUNG 은 영구 잠금 (Panel B 수용된 결과, plan §4).
    const engine80Plus = 0;

    // v1.21 Streak 일수 계산 (오늘 또는 어제까지 연속).
    final streakDays = _computeStreakDays(history);

    // v1.21 PR 누적 카운트 (PrDetector 위임).
    final prCount = PrDetector.countPrs(history);

    final bs = profile.benchmarks['back_squat_1rm_lb'];
    final fs = profile.benchmarks['front_squat_1rm_lb'];
    final sn = profile.benchmarks['snatch_1rm_lb'];
    final dl = profile.benchmarks['deadlift_1rm_lb'];
    final sp = profile.benchmarks['strict_press_1rm_lb'];
    final fiveKm = profile.benchmarks['run_5km_sec'];
    final twoKmRow = profile.benchmarks['row_2km_sec'];
    // /go Tier 3: Fran 1RM 키 사용 (benchmarks 에 'fran_sec' 있는 경우).
    final fran = profile.benchmarks['fran_sec'];
    // /go Phase 3: 코치 노트 송신/수신 카운트 — InboxState 가 bind 된 상태에서만 의미.
    // 미바인드(no-gym/pending/rejected) 시 0 → PB_TEACHER/PB_STUDENT 잠금 유지.
    final coachNotesSent = inbox.outbox.length;
    final coachNotesReceived =
        inbox.inbox.items.where((n) => n.kind == 'note').length;

    // v1.21 프로필 완성도: bodyWeightKg + 5+ benchmarks.
    final profileComplete =
        profile.bodyWeightKg != null && profile.benchmarks.length >= 5;

    return TitleUnlockSignals(
      totalSessions: history.length,
      benchmarkCount: profile.benchmarks.length,
      hasGym: gym.hasGym,
      sessionsBefore6am: beforeSix,
      sessionsAfter10pm: afterTen,
      weekendSessions: weekend,
      engineScore80PlusCount: engine80Plus,
      coachNotesSent: coachNotesSent,
      coachNotesReceived: coachNotesReceived,
      backSquat1rmKg: bs == null ? null : bs * 0.4536,
      frontSquat1rmKg: fs == null ? null : fs * 0.4536,
      snatch1rmKg: sn == null ? null : sn * 0.4536,
      fiveKmSub25: fiveKm != null && fiveKm < 1500, // 25:00 = 1500s
      twoKmRowSub730: twoKmRow != null && twoKmRow < 450, // 7:30 = 450s
      franSec: fran?.toInt(),
      streakDays: streakDays,
      prCount: prCount,
      profileComplete: profileComplete,
      freshStartSession: freshStart,
      bodyWeightKg: profile.bodyWeightKg,
      deadlift1rmKg: dl == null ? null : dl * 0.4536,
      pressStrict1rmKg: sp == null ? null : sp * 0.4536,
      doubleSessionDayCount: doubleSessionDays,
      shareCount: _shareCount,
    );
  }

  /// 가장 최근 세션부터 역순 일자 연속 카운트.
  /// 어제까지 한 번도 안 한 경우 0. 같은 날 여러 세션은 1일로 카운트.
  int _computeStreakDays(List<WodHistoryItem> history) {
    if (history.isEmpty) return 0;
    final sorted = [...history]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final today = DateTime.now().toLocal();
    final todayKey = DateTime(today.year, today.month, today.day);
    final mostRecent = sorted.first.createdAt.toLocal();
    final mostRecentKey =
        DateTime(mostRecent.year, mostRecent.month, mostRecent.day);
    final daysSinceLast = todayKey.difference(mostRecentKey).inDays;
    if (daysSinceLast > 1) return 0;

    var streak = 1;
    var cursor = mostRecentKey;
    for (var i = 1; i < sorted.length; i++) {
      final d = sorted[i].createdAt.toLocal();
      final dKey = DateTime(d.year, d.month, d.day);
      if (dKey.isAtSameMomentAs(cursor)) continue;
      final diff = cursor.difference(dKey).inDays;
      if (diff == 1) {
        streak++;
        cursor = dKey;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileState>();
    final gym = context.watch<GymState>();
    final inbox = context.watch<InboxState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('칭호'),
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
                    color: HyphenTokens.muted,
                  ),
                ),
              );
            }
            // /go Tier 3: hasError 분기.
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(HyphenTokens.sp5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('칭호 로딩 실패',
                          style: HyphenTokens.sectionLabel),
                      const SizedBox(height: HyphenTokens.sp2),
                      const Text('네트워크 확인 후 다시 시도.',
                          style: HyphenTokens.caption),
                      const SizedBox(height: HyphenTokens.sp3),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            final api = context.read<ApiClient>();
                            _historyFuture = retainError(HistoryRepository(api)
                                .listWodHistory(limit: 500));
                          });
                        },
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final history = snap.data ?? const <WodHistoryItem>[];
            final signals = _buildSignals(history, profile, gym, inbox);
            final unlocked = PanelBUnlocker.unlockedCodes(signals);
            final sorted = [...kPanelBTitles]
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            return ListView(
              padding: const EdgeInsets.all(HyphenTokens.sp4),
              children: [
                _Header(
                  unlocked: unlocked.length,
                  total: kPanelBTitles.length,
                ),
                const SizedBox(height: HyphenTokens.sp4),
                // /go Tier 3: 착용 안내.
                const Text('칭호', style: HyphenTokens.sectionLabel),
                const SizedBox(height: 2),
                const Text(
                  '해금된 칭호를 탭하면 Profile 상단에 표시. 다시 탭하면 해제.',
                  style: HyphenTokens.caption,
                ),
                const SizedBox(height: HyphenTokens.sp2),
                ...sorted.map((t) => _TitleCard(
                      title: t,
                      unlocked: unlocked.contains(t.code),
                      worn: _wornCode == t.code,
                      onTap: unlocked.contains(t.code)
                          ? () => _toggleWorn(t.code)
                          : null,
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
            Text('$unlocked', style: HyphenTokens.display),
            const SizedBox(width: HyphenTokens.sp1),
            Text('/ $total',
                style: HyphenTokens.h3.copyWith(color: HyphenTokens.muted)),
            const Spacer(),
            Text(
              '${(pct * 100).toInt()}%',
              style: HyphenTokens.h3.copyWith(
                color: HyphenTokens.accent,
                fontFeatures: HyphenTokens.tabular,
              ),
            ),
          ],
        ),
        const SizedBox(height: HyphenTokens.sp1),
        Text('달성', style: HyphenTokens.sectionLabel),
        const SizedBox(height: HyphenTokens.sp2),
        ClipRRect(
          borderRadius: BorderRadius.circular(HyphenTokens.r1),
          child: Stack(children: [
            Container(height: 4, color: HyphenTokens.border),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(height: 4, color: HyphenTokens.accent),
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
  /// /go Tier 3: 현재 착용 중 여부.
  final bool worn;
  /// /go Tier 3: 탭 콜백 — 해금된 경우만 non-null. unlocked=false → null (비활성).
  final VoidCallback? onTap;
  const _TitleCard({
    required this.title,
    required this.unlocked,
    this.worn = false,
    this.onTap,
  });

  Color _rarityColor() {
    switch (title.rarity) {
      case 'Rare':
        return HyphenTokens.accent;
      case 'Epic':
        return HyphenTokens.tierElite;
      case 'Legendary':
        return HyphenTokens.tierGames;
      case 'Common':
      default:
        return HyphenTokens.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? _rarityColor() : HyphenTokens.border;
    return Padding(
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              HyphenTokens.sp4,
              HyphenTokens.sp3,
              HyphenTokens.sp4,
              HyphenTokens.sp3,
            ),
            decoration: BoxDecoration(
              color: worn
                  ? HyphenTokens.accent.withValues(alpha: 0.08)
                  : HyphenTokens.surface,
              border: Border(
                left: BorderSide(color: color, width: worn ? 4 : 3),
                top: BorderSide(
                    color: worn
                        ? HyphenTokens.accent
                        : HyphenTokens.border,
                    width: 1),
                right: BorderSide(
                    color: worn
                        ? HyphenTokens.accent
                        : HyphenTokens.border,
                    width: 1),
                bottom: BorderSide(
                    color: worn
                        ? HyphenTokens.accent
                        : HyphenTokens.border,
                    width: 1),
              ),
              borderRadius: BorderRadius.circular(HyphenTokens.r2),
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
                              style: HyphenTokens.h3.copyWith(
                                color: unlocked
                                    ? HyphenTokens.fg
                                    : HyphenTokens.muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (worn) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: HyphenTokens.accent,
                                borderRadius: BorderRadius.circular(
                                    HyphenTokens.r1),
                              ),
                              child: Text(
                                'WORN',
                                style: HyphenTokens.sectionLabel.copyWith(
                                  color: HyphenTokens.fg,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: HyphenTokens.sp2),
                          ],
                          Text(
                            title.rarity.toUpperCase(),
                            style: HyphenTokens.microLabel.copyWith(
                              color: _rarityColor(),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unlocked
                            ? title.captionKo
                            : '잠금 — ${title.requirement}',
                        style: HyphenTokens.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: HyphenTokens.sp3),
                Icon(
                  worn
                      ? Icons.star
                      : (unlocked
                          ? Icons.check_circle
                          : Icons.lock_outline),
                  size: 18,
                  color: worn
                      ? HyphenTokens.accent
                      : (unlocked
                          ? HyphenTokens.success
                          : HyphenTokens.muted),
                ),
              ],
            ),
          ),
        ),
      ),
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
