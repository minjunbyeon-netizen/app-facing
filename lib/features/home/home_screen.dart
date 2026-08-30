import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/level_system.dart';
import '../../core/streak_freeze.dart';
import '../../core/theme.dart';
import '../../core/wod_session_bus.dart';
import '../../models/achievement.dart';
import '../../widgets/hkit.dart';
import '../classes/today_reservations.dart';
import '../../widgets/inbox_bell.dart';
import '../../widgets/offline_banner.dart';
import '../achievement/achievement_section.dart';
import '../achievement/achievement_state.dart';
import '../achievement/unlock_toast.dart';
import '../gym/gym_repository.dart';
import '../history/history_models.dart';
import 'challenge_section.dart';
import '../history/history_repository.dart';
import '../announcements/announcements_state.dart';
import '../profile/profile_state.dart';
import '../../core/app_clock.dart';
import '../announcements/announcement_row.dart';

/// v1.23 (2026-06-02) 재배치 Phase 3: Attend 의 게이미피케이션을 Home 으로 이관.
/// Home = LEVEL(캐릭터 진화) + ACHIEVEMENTS(업적 그리드) + MILESTONES(3종 진행바).
/// 출석 캘린더는 Attend 가 전담. (Phase 4 예정: 공지/쪽지 아코디언이 최상단 추가)
class HomeScreen extends StatefulWidget {
  /// 회원 셸에 얹힐 때는 자기 AppBar 를 그리지 않는다 — 상단바는 셸 하나 (v3.24, D47).
  final bool embedded;

  // ── 레이아웃 안정성 앵커 (v3.34 · 2026-08-27) ──────────────────────────────
  // 공지·업적·출석이 각각 따로 도착해도 y 가 움직이면 안 되는 요소들.
  // 회귀 게이트가 이 키로 잰다 (test/golden/stability_home_test.dart).
  // 이름을 바꾸면 그 테스트도 같이 바꾼다 (글로벌 §0-B 이름 일원화).
  static const Key kNotice = Key('home-notice');
  static const Key kLevel = Key('home-level');
  static const Key kAchievements = Key('home-achievements');
  static const Key kMilestoneLabel = Key('home-milestone-label');
  static const Key kMilestoneCard = Key('home-milestone-card');

  const HomeScreen({super.key, this.embedded = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// QA B-PF-6: 매직 200 제거. ~6개월 일일 1세션 가정 — streak·업적 계산에 충분.
  static const int _kHistoryLimit = 200;

  late final HistoryRepository _repo;
  late final GymRepository _gymRepo;
  WodSessionBus? _bus;
  Future<WodHistoryPage>? _future;

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
    // 기록 저장 직후 — 실제 트리거이므로 업적 체크 스로틀 우회 (토스트·컨페티).
    _reload(checkThrottle: false);
  }

  @override
  void dispose() {
    _bus?.removeListener(_onSessionBump);
    super.dispose();
  }

  void _reload({bool checkThrottle = true}) {
    setState(() {
      _future = _repo.listWodHistory(limit: _kHistoryLimit);
    });
    StreakFreezeStore.lastUse().then((dt) {
      if (!mounted) return;
      setState(() => _freezeUse = dt);
    });
    // Attend 탭과 동일 소스의 실제 출석 — 실패·미가입이면 milestone 숨김.
    _gymRepo
        .listMyAttendances()
        .then((map) {
          if (!mounted) return;
          setState(() => _attendDays = map.keys.toSet());
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() => _attendDays = null);
        });
    // 진입·새로고침마다 업적 자동 체크 (초기 진입만 10분 스로틀).
    // v3.3 (2026-08-20 사용자 지시): 새 해금이 있으면 홈에서 토스트 + 컨페티
    // 캐논 축하 (리워드 규칙 해금은 서버 훅에서 일어나 diff 로 감지된다).
    context.read<AchievementState>().check(throttle: checkThrottle).then((
      newly,
    ) {
      if (!mounted || newly.isEmpty) return;
      UnlockToast.showAll(context, newly);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // v3.24 (2026-08-25 사용자 지시 "상단화면 통일"): 셸에 얹히면 상단바 없음.
      // 종은 셸 상단바로, 새로고침은 아래 당겨서 새로고침으로 옮겼다.
      appBar: widget.embedded
          ? null
          : const HkAppBar(
              title: '홈',
              implyLeading: false,
              actions: [InboxBellAction()],
            ),
      // v3.34 (2026-08-27 · DESIGN-SSOT §레이아웃 안정성): 오프라인 배너를
      // Column 첫 칸에서 빼 **본문 위에 겹치는** 오버레이로 옮겼다. 전엔 연결이
      // 끊길 때마다 배너 높이만큼 본문 전체가 아래로 밀렸다.
      body: OfflineBannerOverlay(
        child: SafeArea(
          child: FutureBuilder<WodHistoryPage>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const HkLoading();
              }
              if (snap.hasError) {
                final e = snap.error;
                final msg = e is AppException ? e.messageKo : 'Load failed.';
                return HkErrorState(message: msg, onRetry: _reload);
              }
              final page = snap.data ?? WodHistoryPage.empty;
              // 수동 새로고침 — 코치 승인 등 서버 해금을 바로 축하하도록 스로틀 우회.
              return RefreshIndicator(
                color: HyphenTokens.primary,
                onRefresh: () async {
                  _reload(checkThrottle: false);
                  await _future;
                },
                child: _GamificationBody(
                  records: page.items,
                  // D91 (2026-08-30): 총 기록 수·PR 수는 서버 meta — 목록 길이(limit 로
                  // 잘림)나 앱 자체 PR 판정(구 PrDetector)으로 만들지 않는다.
                  totalSessions: page.total,
                  prCount: page.prCount,
                  freezeUse: _freezeUse,
                  attendDays: _attendDays,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// R7 (2026-08-21 사용자 보고): 여기가 인박스(쪽지·자동 알림 혼합)를 그리면서
/// 라벨만 '공지' 라 "달리기 인증 승인" 같은 리워드 통지가 공지로 보였다.
/// 데이터 소스를 진짜 공지(AnnouncementsState — 코치가 PC 공지사항에서 등록한
/// GymAnnouncement)로 교체. 쪽지·알림은 종(MessagingScreen)이 전담한다.
///
/// v3.34 (2026-08-27 · DESIGN-SSOT §레이아웃 안정성): **자리를 항상 지킨다.**
/// 전엔 공지 0건이면 `SizedBox.shrink()` 로 카드 자체가 없었고, 셸이 첫 렌더
/// 뒤에 공지를 바인딩(main_shell 의 `Future.microtask`)하는 탓에 화면이 다
/// 그려진 다음 카드가 생기며 그 아래 전부가 밀렸다. 이제 접힌 카드는 어느
/// 상태에서도 같은 골격(같은 제목 줄 + 같은 부제 한 줄)이라 높이가 같고,
/// 공지가 도착하면 **부제 문구만** 갈아 끼운다. 고정 높이 숫자를 따로 두지 않는
/// 이유는 두 상태가 같은 위젯으로 그려져 높이가 구조적으로 같기 때문이다.
class _NoticeAccordion extends StatelessWidget {
  const _NoticeAccordion({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AnnouncementsState>();
    final items = [...state.items]
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    final top = items.take(3).toList();
    final isEmpty = top.isEmpty;
    final hasUnread = state.unreadCount > 0;
    // v3.43 (2026-08-29 사용자 "공지부분은 검정바탕에 흰글자가 꽉채워서 흐르게").
    // 접힌 줄이 **검정 전광판**이다 — 흰 글자, 짧은 글도 이어 붙여 꽉 채워 항상 흐른다.
    // 공지가 없을 땐 문구만 서 있다(없는 것을 흐르게 하면 거짓 신호).
    // 공지는 이제 **홈에서만** 본다 — 수업 탭 하단 아코디언은 같은 날 삭제.
    final preview = isEmpty
        ? '등록된 공지 없음'
        : top.map((a) => a.title.isNotEmpty ? a.title : a.body).join('   ·   ');

    return HkCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: HyphenTokens.sp4),
      clipBehavior: Clip.antiAlias,
      borderColor: HyphenTokens.fg,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        // 공지가 없으면 펼칠 것도 없다 — 골격은 그대로 두고 조작만 막는다
        // (자리를 지키되 헛도는 화살표를 남기지 않는다).
        child: AbsorbPointer(
          absorbing: isEmpty,
          child: ExpansionTile(
            initiallyExpanded: false,
            backgroundColor: HyphenTokens.surface,
            collapsedBackgroundColor: HyphenTokens.fg,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: HyphenTokens.sp3,
              vertical: 2,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              HyphenTokens.sp3,
              0,
              HyphenTokens.sp3,
              HyphenTokens.sp3,
            ),
            collapsedIconColor: HyphenTokens.bg,
            iconColor: HyphenTokens.muted,
            // 화살표를 지워도 세로 높이는 그대로다 (행 높이는 제목·부제가 정한다).
            trailing: isEmpty ? const SizedBox.shrink() : null,
            title: Row(
              children: [
                Text(
                  '공지',
                  style: HyphenTokens.sectionLabel
                      .copyWith(color: HyphenTokens.bg),
                ),
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
              child: HkMarquee(
                preview,
                fill: !isEmpty,
                style: HyphenTokens.body.copyWith(
                  color: HyphenTokens.bg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            children: [
              for (final a in top) AnnouncementRow(bodyMaxLines: 2, item: a),
            ],
          ),
        ),
      ),
    );
  }
}

/// 홈 공지 행 — box_wod_screen._AnnouncementRow 와 같은 문법 (핀·제목·날짜·본문).
class _GamificationBody extends StatelessWidget {
  final List<WodHistoryItem> records;

  /// 서버가 센 총 수업 기록 수 · PR 수 (히스토리 API meta).
  final int totalSessions;
  final int prCount;

  /// 이번 주 freeze 사용 기록. 있으면 streak 1일 보호.
  final DateTime? freezeUse;

  /// 실제 출석일 (Attend 탭 동일 소스). null = 로드 실패·미가입 → 숨김.
  final Set<DateTime>? attendDays;
  const _GamificationBody({
    required this.records,
    required this.totalSessions,
    required this.prCount,
    required this.freezeUse,
    required this.attendDays,
  });

  /// 전체 기록에서 고유 일자 집합 (date 기준).
  Set<DateTime> _uniqueDays() {
    return records.map((r) {
      final d = r.createdAt.toLocal();
      return DateTime(d.year, d.month, d.day);
    }).toSet();
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
    final totalLifetime = totalSessions;
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
        const _NoticeAccordion(key: HomeScreen.kNotice),
        // 2026-08-28 테스터 지시 — "오늘 몇 시 예약했더라" 에 홈에서 바로 답한다.
        // 예약이 없으면 통째로 숨으므로 평소 레이아웃은 그대로다.
        const TodayReservationsCard(),
        // LEVEL 카드 = 캐릭터 + 진화.
        _LevelCard(
          key: HomeScreen.kLevel,
          totalSessions: totalLifetime,
          currentStreakDays: currentStreak,
          prCount: prCount,
        ),
        const SizedBox(height: HyphenTokens.sp3),

        // 업적 — 캐릭터 바로 아래 표 (v1.30: 그리드 → 한 줄 한 항목)
        const AchievementSection(key: HomeScreen.kAchievements),
        const SizedBox(height: HyphenTokens.sp3),

        // 마일스톤 — 3종 요약 진행바 (업적과 같은 표 리듬)
        const HkSectionLabel('마일스톤', key: HomeScreen.kMilestoneLabel),
        const SizedBox(height: HyphenTokens.sp1),
        HkRowCard(
          key: HomeScreen.kMilestoneCard,
          rows: [
            // QA 2026-06-11: WOD 계산 기록이 아닌 실제 출석(Attend 탭 동일
            // 소스)으로 표기 — 두 화면 수치 불일치 해소.
            //
            // v3.34 (2026-08-27 · DESIGN-SSOT §레이아웃 안정성): 출석은 기록·업적과
            // 따로 오는 비동기라, 늦게 도착하면 '출석' 행이 표 맨 위에 끼어들며
            // '세션'·'업적' 두 행을 아래로 밀어냈다. 이제 세 행을 **항상** 그리고
            // 아직 못 받은 값만 `--` 로 둔다 (자리는 지키되 없는 척하지 않는다).
            Builder(
              builder: (context) {
                final days = attendDays;
                final attendThisMonth = days
                    ?.where((d) => d.year == now.year && d.month == now.month)
                    .length;
                final ratio = (attendThisMonth != null && daysElapsed > 0)
                    ? (attendThisMonth / daysElapsed).clamp(0.0, 1.0)
                    : 0.0;
                return _ProgressStat(
                  title: '출석',
                  subtitle: '이번 달 ${attendThisMonth ?? '--'} / $daysElapsed일',
                  value: ratio,
                  trailing: attendThisMonth == null
                      ? '--'
                      : '${(ratio * 100).round()}%',
                );
              },
            ),
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
                  ? (unlockedCount / achState.snapshot.visibleCount).clamp(
                      0.0,
                      1.0,
                    )
                  : 0.0,
              trailing: '$unlockedCount / ${achState.snapshot.visibleCount}',
            ),
          ],
        ),
        // P3 (2026-08-20 승인 설계 §6): 도전 카드 — 코치 리워드 규칙의
        // 진행률 + custom 행동 [인증하기]. 규칙 없으면 통째로 숨김.
        const ChallengeSection(),
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
    super.key,
    required this.totalSessions,
    required this.currentStreakDays,
    required this.prCount,
  });

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

    // v2.2 위계 정리 — 레벨 숫자·진행도를 앞세운다.
    // 2026-08-21: 레벨 옆 캐릭터는 사용자 지시로 걷었다 (스낵바 전용).
    // 나머지 요소는 그대로 (레벨·XP·캡션·진행바·다음레벨).
    return HkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 2026-08-21 사용자 지시: 캐릭터는 **스낵바에만**. 레벨 옆 그림은
              // 나중에 따로 받기로 해서 아바타 상자째 걷었다 (레벨대 색은
              // 아래 캡션·진행바가 이어받는다). 되살릴 때는 HyphenMascot 에
              // 레벨용 mood 를 추가하고 그 그림을 물린다.
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
