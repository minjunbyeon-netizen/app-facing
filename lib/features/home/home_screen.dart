import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/level_system.dart';
import '../../core/pr_detector.dart';
import '../../core/streak_freeze.dart';
import '../../core/theme.dart';
import '../../core/wod_session_bus.dart';
import '../../models/achievement.dart';
import '../../widgets/hkit.dart';
import '../../widgets/inbox_bell.dart';
import '../../widgets/offline_banner.dart';
import '../achievement/achievement_section.dart';
import '../achievement/achievement_state.dart';
import '../achievement/unlock_toast.dart';
import '../gym/gym_repository.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';
import '../inbox/inbox_screen.dart';
import '../inbox/inbox_state.dart';
import '../profile/profile_state.dart';
import '../../core/app_clock.dart';

/// v1.23 (2026-06-02) 재배치 Phase 3: Attend 의 게이미피케이션을 Home 으로 이관.
/// Home = LEVEL(캐릭터 진화) + ACHIEVEMENTS(업적 그리드) + MILESTONES(3종 진행바).
/// 출석 캘린더는 Attend 가 전담. (Phase 4 예정: 공지/쪽지 아코디언이 최상단 추가)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// QA B-PF-6: 매직 200 제거. ~6개월 일일 1세션 가정 — streak·업적 계산에 충분.
  static const int _kHistoryLimit = 200;

  late final HistoryRepository _repo;
  late final GymRepository _gymRepo;
  WodSessionBus? _bus;
  Future<List<WodHistoryItem>>? _future;

  /// Streak Freeze 통합 — 마지막 사용일을 _currentStreak 계산 시 활용.
  DateTime? _freezeUse;

  /// QA 2026-06-11: 실제 출석일 집합 (Attend 탭과 동일 소스 —
  /// GymRepository.listMyAttendances). null = 로드 실패·미가입 →
  /// Attendance milestone 숨김. WOD 계산 기록(_future)과 별개.
  Set<DateTime>? _attendDays;

  @override
  void initState() {
    super.initState();
    _repo = HistoryRepository(context.read<ApiClient>());
    _gymRepo = GymRepository(context.read<ApiClient>());
    _reload();
    _bus = context.read<WodSessionBus>();
    _bus?.addListener(_onSessionBump);
  }

  void _onSessionBump() {
    if (!mounted) return;
    _reload();
  }

  @override
  void dispose() {
    _bus?.removeListener(_onSessionBump);
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _repo.listWodHistory(limit: _kHistoryLimit);
    });
    StreakFreezeStore.lastUse().then((dt) {
      if (!mounted) return;
      setState(() => _freezeUse = dt);
    });
    // Attend 탭과 동일 소스의 실제 출석 — 실패·미가입이면 milestone 숨김.
    _gymRepo.listMyAttendances().then((map) {
      if (!mounted) return;
      setState(() => _attendDays = map.keys.toSet());
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _attendDays = null);
    });
    // 진입·새로고침마다 업적 자동 체크 (throttle: 10분 1회).
    // v3.3 (2026-08-20 사용자 지시): 새 해금이 있으면 홈에서 토스트 + 컨페티
    // 캐논 축하 (리워드 규칙 해금은 서버 훅에서 일어나 diff 로 감지된다).
    context.read<AchievementState>().check(throttle: true).then((newly) {
      if (!mounted || newly.isEmpty) return;
      UnlockToast.showAll(context, newly);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        automaticallyImplyLeading: false,
        // v1.25: 종(쪽지·공지) = 모든 화면 공통 메시징 진입. Home 도 예외 아님.
        //   (D7 에서 잠깐 뺐다가, 종이 핵심 메시징 버튼이라 전 화면 유지로 복원)
        actions: [
          const InboxBellAction(),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SafeArea(
              child: FutureBuilder<List<WodHistoryItem>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const HkLoading();
                  }
                  if (snap.hasError) {
                    final e = snap.error;
                    final msg =
                        e is AppException ? e.messageKo : 'Load failed.';
                    return HkErrorState(message: msg, onRetry: _reload);
                  }
                  final records = snap.data ?? const [];
                  return _GamificationBody(
                    records: records,
                    freezeUse: _freezeUse,
                    attendDays: _attendDays,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// v1.23 Phase 4 (2026-06-02): Notice 의 쪽지+공지 요약을 Home 최상단 아코디언으로.
/// 데이터 = InboxState.inbox.items (쪽지·숙제·공지 합쳐진 NOTICE 피드, 최신순).
/// 기본 접힘 — 최신 1건 헤드라인만 노출. 펼치면 최신 3건 + "더 보기" → Notice 탭.
class _NoticeAccordion extends StatelessWidget {
  const _NoticeAccordion();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InboxState>();
    final items = [...state.inbox.items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (items.isEmpty) return const SizedBox.shrink();
    final top = items.take(3).toList();
    final latest = top.first;
    final hasUnread = state.unreadCount > 0;
    final latestPreview =
        latest.title.isNotEmpty ? latest.title : latest.body;

    return Container(
      margin: const EdgeInsets.only(bottom: HyphenTokens.sp4),
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
          title: Row(
            children: [
              const Text('공지', style: HyphenTokens.sectionLabel),
              if (hasUnread) ...[
                const SizedBox(width: HyphenTokens.sp2),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: HyphenTokens.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              latestPreview,
              style: HyphenTokens.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          children: [
            ...top.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: HyphenTokens.sp2),
                  child: CoachDossierTile(note: n),
                )),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Haptic.light();
                  // v1.26: 쪽지·공지 풀 피드 = MessagingScreen (종 일원화).
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const MessagingScreen()));
                },
                style: TextButton.styleFrom(
                  foregroundColor: HyphenTokens.fgSecondary,
                  minimumSize: const Size(0, HyphenTokens.touchMin),
                ),
                child: const Text('더 보기 →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GamificationBody extends StatelessWidget {
  final List<WodHistoryItem> records;

  /// 이번 주 freeze 사용 기록. 있으면 streak 1일 보호.
  final DateTime? freezeUse;

  /// 실제 출석일 (Attend 탭 동일 소스). null = 로드 실패·미가입 → 숨김.
  final Set<DateTime>? attendDays;
  const _GamificationBody({
    required this.records,
    required this.freezeUse,
    required this.attendDays,
  });

  /// 전체 기록에서 고유 일자 집합 (date 기준).
  Set<DateTime> _uniqueDays() {
    return records
        .map((r) {
          final d = r.createdAt.toLocal();
          return DateTime(d.year, d.month, d.day);
        })
        .toSet();
  }

  /// 현재 streak — 오늘(또는 가장 최근 세션일)부터 연속된 일수.
  /// freezeUse 가 있으면 missing day 1일 보호 (streak 카운트에 포함).
  int _currentStreak() {
    final days = _uniqueDays();
    if (days.isEmpty) return 0;
    final today = appClock.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    DateTime cursor = todayDate;
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    bool freezeAvailable = freezeUse != null;
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

  @override
  Widget build(BuildContext context) {
    final totalLifetime = records.length;
    final currentStreak = _currentStreak();
    final now = appClock.now();
    final daysElapsed = now.day;
    final achState = context.watch<AchievementState>();
    final unlockedCount = achState.snapshot.unlocked.length;
    final int nextMilestone;
    if (totalLifetime < 50) {
      nextMilestone = 50;
    } else if (totalLifetime < 100) {
      nextMilestone = 100;
    } else {
      nextMilestone = 365;
    }

    // v2.5 (2026-08-12 사용자 지시): 섹션 사이 16·24 여백이 스크롤의 절반을
    // 차지했다. 바깥 여백 12 · 섹션 간격 12 로 통일.
    return ListView(
      padding: const EdgeInsets.all(HyphenTokens.sp3),
      children: [
        // v1.23 Phase 4: 공지/쪽지 아코디언 — 화면 최상단(게이미피케이션 위).
        const _NoticeAccordion(),
        // LEVEL 카드 = 캐릭터 + 진화.
        _LevelCard(
          totalSessions: totalLifetime,
          currentStreakDays: currentStreak,
          prCount: PrDetector.countPrs(records),
        ),
        const SizedBox(height: HyphenTokens.sp3),

        // 업적 — 캐릭터 바로 아래 표 (v1.30: 그리드 → 한 줄 한 항목)
        const AchievementSection(),
        const SizedBox(height: HyphenTokens.sp3),

        // 마일스톤 — 3종 요약 진행바 (업적과 같은 표 리듬)
        const HkSectionLabel('마일스톤'),
        const SizedBox(height: HyphenTokens.sp1),
        HkRowCard(
          rows: [
            // QA 2026-06-11: WOD 계산 기록이 아닌 실제 출석(Attend 탭 동일
            // 소스)으로 표기 — 두 화면 수치 불일치 해소. 미가입·로드 실패 시 숨김.
            if (attendDays != null)
              Builder(builder: (context) {
                final attendThisMonth = attendDays!
                    .where((d) => d.year == now.year && d.month == now.month)
                    .length;
                return _ProgressStat(
                  title: '출석',
                  subtitle: '이번 달 $attendThisMonth / $daysElapsed일',
                  value: daysElapsed > 0
                      ? (attendThisMonth / daysElapsed).clamp(0.0, 1.0)
                      : 0.0,
                  trailing: daysElapsed > 0
                      ? '${(attendThisMonth / daysElapsed * 100).round()}%'
                      : '0%',
                );
              }),
            _ProgressStat(
              title: '세션',
              subtitle: '누적 $totalLifetime회 → $nextMilestone 목표',
              value: (totalLifetime / nextMilestone).clamp(0.0, 1.0),
              trailing: totalLifetime >= 365
                  ? 'MAX'
                  : '$totalLifetime / $nextMilestone',
            ),
            _ProgressStat(
              title: '업적',
              subtitle: '해금한 업적',
              value: achState.snapshot.visibleCount > 0
                  ? (unlockedCount / achState.snapshot.visibleCount)
                      .clamp(0.0, 1.0)
                  : 0.0,
              trailing: '$unlockedCount / ${achState.snapshot.visibleCount}',
            ),
          ],
        ),
      ],
    );
  }
}

/// LEVEL 카드 — 친근한 캐릭터 + 격려 캡션.
/// 레벨대별 stickman 진화 (motivation → discipline → obsession).
class _LevelCard extends StatelessWidget {
  final int totalSessions;
  final int currentStreakDays;
  final int prCount;
  const _LevelCard({
    required this.totalSessions,
    required this.currentStreakDays,
    required this.prCount,
  });

  /// 레벨대별 캐릭터 진화. lv2/lv3 자산 없으면 mascot.png 폴백.
  String _mascotForLevel(int level) {
    if (level >= 41) return 'assets/images/character/mascot_lv5.png';
    if (level >= 31) return 'assets/images/character/mascot_lv4.png';
    if (level >= 21) return 'assets/images/character/mascot_lv3.png';
    if (level >= 11) return 'assets/images/character/mascot_lv2.png';
    return 'assets/images/character/mascot.png';
  }

  static const String _mascotFallback = 'assets/images/character/mascot.png';

  /// 레벨대별 캐릭터 강조 색 — 회색 → 흰 → 탠 (5 단계).
  Color _colorForLevel(int level) {
    if (level >= 41) return HyphenTokens.accent;
    if (level >= 31) return HyphenTokens.accent;
    if (level >= 21) return HyphenTokens.fg;
    if (level >= 11) return HyphenTokens.fg;
    return HyphenTokens.muted;
  }

  /// 레벨대별 격려 한 줄. 친근한 톤.
  String _captionForLevel(int level) {
    if (level <= 5) return '좋은 출발. 페이스 유지.';
    if (level <= 10) return 'Engine 만드는 중.';
    if (level <= 15) return '단단해지는 중.';
    if (level <= 20) return '루틴이 잡혔다.';
    if (level <= 30) return '몰입 구간.';
    if (level <= 40) return '베테랑.';
    return '경지에 올랐다.';
  }

  /// 업적 등급별 XP 합산.
  int _computeAchievementXp(AchievementSnapshot snap) {
    if (snap.unlocked.isEmpty) return 0;
    final byCode = <String, AchievementCatalog>{
      for (final c in snap.catalog) c.code: c,
    };
    int total = 0;
    for (final code in snap.unlocked.keys) {
      final c = byCode[code];
      final xp = LevelSystem.rarityXp[c?.rarity ?? 'Common'] ?? 20;
      total += xp;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final num? n = p.gradeResult?['overall_number'] is num
        ? p.gradeResult!['overall_number'] as num
        : null;
    final tierNum = (n ?? 1).toInt();
    final achState = context.watch<AchievementState>();
    final achXp = _computeAchievementXp(achState.snapshot);
    final bd = LevelSystem.compute(
      totalSessions: totalSessions,
      currentStreakDays: currentStreakDays,
      tierNumber: tierNum,
      prCount: prCount,
      achievementXp: achXp,
    );
    final pct = (bd.progress * 100).round();
    final isMax = bd.level >= LevelSystem.maxLevel;
    final charColor = _colorForLevel(bd.level);

    // v2.2 위계 정리 — 전엔 캐릭터가 카드 가로의 44% 를 먹었다. 정보량은 0 인데
    // 화면에서 가장 큰 요소였고, 정작 읽어야 할 레벨 숫자·진행도는 남은 절반에
    // 눌려 있었다. 캐릭터를 고정 88 아바타로 접고 숫자·진행바를 앞세운다.
    // 요소는 하나도 빼지 않았다 (캐릭터·레벨·XP·캡션·진행바·다음레벨 전부 유지).
    return HkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 캐릭터 — 연분홍 면·반투명 컬러 보더를 걷고 중립 면 + 1px.
              // 레벨대 색은 테두리 한 곳에만 남겨 강조를 분산시키지 않는다.
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: HyphenTokens.surfaceAlt,
                  borderRadius: BorderRadius.circular(HyphenTokens.r2),
                  border: Border.all(color: charColor, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  _mascotForLevel(bd.level),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset(
                    _mascotFallback,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: HyphenTokens.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HkSectionLabel('레벨'),
                    Text(
                      '${bd.level}',
                      style: HyphenTokens.displayCompact.copyWith(
                        color: HyphenTokens.primary,
                      ),
                    ),
                    const SizedBox(height: HyphenTokens.sp1),
                    // 캡션 색을 레벨대 색에서 본문색으로 고정. 레벨이 낮으면
                    // 회색이라 격려 문구가 가장 흐렸다.
                    Text(
                      _captionForLevel(bd.level),
                      style: HyphenTokens.caption.copyWith(
                        color: HyphenTokens.fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: HyphenTokens.sp3),
          // 진행바를 카드 전체 폭으로. 반쪽 폭일 때는 14% 가 5px 밖에 안 돼
          // 채워졌는지 눈으로 확인되지 않았다.
          ClipRRect(
            borderRadius: BorderRadius.circular(HyphenTokens.r1),
            child: Stack(
              children: [
                Container(height: 6, color: HyphenTokens.border),
                FractionallySizedBox(
                  widthFactor: bd.progress,
                  child: Container(height: 6, color: HyphenTokens.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: HyphenTokens.sp2),
          Row(
            children: [
              Text(
                '${_comma(bd.totalXp)} XP',
                style: HyphenTokens.micro.copyWith(
                  color: HyphenTokens.fgSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                isMax
                    ? '최고 레벨'
                    : '다음 Lv${bd.level + 1} · ${_comma(bd.xpToNext)} XP · $pct%',
                style: HyphenTokens.micro,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 세 자리마다 쉼표. 큰 XP 값이 `1570` 처럼 붙어 나오면 자릿수를 세게 된다
/// (v2.2 — 링코가 `62,500` 으로 잘 하던 부분).
String _comma(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// 마일스톤 3종 요약 진행바 (출석 / 세션 / 업적).
/// v1.30: 자체 레이아웃 폐기 — HkListRow(제목·부제·우측 값) + below 슬롯 진행바.
class _ProgressStat extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value; // 0.0 ~ 1.0
  final String trailing;
  const _ProgressStat({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final done = value >= 1.0;
    return HkListRow(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      // 달성 여부는 우측 수치의 색으로만 가른다 (진행바는 길이가 말한다).
      trailingColor: done ? HyphenTokens.primary : HyphenTokens.fgSecondary,
      below: ClipRRect(
        borderRadius: BorderRadius.circular(HyphenTokens.r1),
        child: Stack(
          children: [
            // v2.2: 진행 중일 때 alpha 0.55 로 흐리던 것을 걷었다. 라이트 배경에서
            // 반투명 브랜드색은 "덜 채워짐"이 아니라 "비활성"으로 읽힌다.
            // 채운 길이가 이미 진행도를 말하므로 색까지 흐릴 이유가 없다.
            // 높이도 레벨 카드 진행바와 같은 6 으로 맞춘다.
            Container(height: 6, color: HyphenTokens.border),
            FractionallySizedBox(
              widthFactor: value,
              child: Container(height: 6, color: HyphenTokens.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// _ErrorState 삭제 — HkErrorState(widgets/hkit.dart)로 대체 (v1.27 UI SSOT).
