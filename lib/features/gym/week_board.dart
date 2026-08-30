import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/sse_client.dart';
import '../../core/theme.dart';
import '../../models/class_session.dart';
import '../../models/gym.dart';
import '../../widgets/hkit.dart';
import '../classes/classes_repository.dart';
import '../classes/class_flows.dart' show cancelClassFlow, reserveClassFlow;
import 'gym_state.dart';
import 'wod_row.dart';
import 'wod_type_label.dart';
import '../../core/app_clock.dart';
import '../classes/class_line.dart';
import '../../core/time_format.dart';

/// v2.4 (2026-08-12 사용자 지시): WOD 탭 = **그 주 월~일 아코디언**.
///
/// 전에는 오늘·예정·지난 3섹션이 세로로 이어져 오늘 것을 보려면 어느 덩어리를
/// 봐야 하는지부터 골라야 했다. 이제 한 주가 7줄로 고정되고, 요일·날짜를 누르면
/// 그날 것이 그 자리에서 펼쳐진다 (한 번에 하나만).
///
/// v3.37 (2026-08-29 테스터 지시 "수업에는 수업 시간표에 대한 내용만 있어야
/// 합니다. 프로그램과 수업은 분리시킵니다"): 하루를 펼치면 **한 카드 안에**
/// 프로그램(수업 내용)과 수업 시간이 세로로 쌓여, 예약하러 들어온 사람이 운동
/// 설명을 다 지나쳐야 예약 버튼에 닿았다. 이제 위에 칸 두 개를 두고 한 칸이
/// 한 가지만 보여 준다 — **수업 시간**(예약) · **프로그램**(그날 내용).
///
/// v3.40 (2026-08-29 사용자 지시 "수업시간-프로그램 순서 바꾸자. 프로그램 누르면
/// 그날 되는 운동목록이 한번에 보이게"): 칸 순서를 **프로그램 · 수업 시간**으로
/// 뒤집고 기본 진입도 프로그램으로. 탭을 열면 "오늘 뭐 하지"가 먼저 답해지고,
/// 예약하러 온 사람은 옆 칸 한 번이면 된다.
///
/// 주(週)와 펼친 날은 두 칸이 함께 쓴다 (여기 State 한 벌뿐이라 칸을 바꿔도
/// 보던 자리가 그대로다). 단 **프로그램 칸으로 갈 때는 오늘을 펼친다** — 그 칸의
/// 목적이 "오늘 운동"이라 접힌 채로 열리면 답이 안 보인다.
class WeekBoard extends StatefulWidget {
  final GymState gymState;

  const WeekBoard({super.key, required this.gymState});

  /// 레이아웃 안정성 앵커 (v3.34 · 2026-08-27) — 어느 날을 펼쳐도 그 아래
  /// 요일 줄은 제자리에 있어야 한다 (0=월 … 6=일).
  /// 회귀 게이트 = test/golden/stability_wod_test.dart.
  static Key dayKey(int index) => ValueKey('week-day-$index');

  /// 칸 전환 줄 · 주간 이동 줄 (v3.37) — 칸을 바꿔도 이 둘과 그 아래 요일 줄이
  /// 같은 y 에 있어야 한다. 회귀 게이트 = test/golden/stability_wod_test.dart.
  static const Key kPaneSwitch = Key('week-pane-switch');
  static const Key kWeekNav = Key('week-nav');

  /// 칸 이름 — 골든·회귀 테스트가 이 문자열로 칸을 누른다 (§0-B).
  static const String paneSchedule = '수업 시간';
  static const String paneProgram = '프로그램';

  /// 펼친 날의 '수업 시간' 구역이 미리 잡아 두는 자리 (공간 예약).
  /// 값 = 수업 한 줄(ClassLine)의 실측 높이 — 로딩 스켈레톤·'없음' 문구·수업
  /// 줄이 이 자리를 함께 쓴다 (DESIGN-SSOT §레이아웃 안정성).
  static const double classSlotH = 65;

  @override
  State<WeekBoard> createState() => _WeekBoardState();
}

class _WeekBoardState extends State<WeekBoard> {
  static const List<String> _wk = ['월', '화', '수', '목', '금', '토', '일'];

  late final ClassesRepository _repo;
  late DateTime _today;
  late DateTime _weekStart; // 그 주 월요일 00:00
  late int _selected; // 0(월)~6(일)
  /// false = 수업 시간(예약) · true = 프로그램. 기본은 **프로그램** (v3.40).
  bool _program = true;
  List<ClassSessionDto> _classes = const [];
  bool _classesLoading = false;
  bool _classesError = false;
  StreamSubscription<SseEvent>? _sseSub;

  /// D58 (2026-08-26 PC·에뮬 실주행): 코치가 회원권을 해지·정지·수정해 서버가 예약을
  /// 지웠는데(revoke_uncovered_reservations) 보드는 '예약됨' 을 그대로 보였다.
  /// GymState 는 회원권·수업 내용만 다시 받으므로 수업 목록은 여기서 직접 듣는다.
  static const _classReloadEvents = <String>{
    'member_reservation_cancelled',
    'class_cancelled',
    'member_promoted_from_waitlist',
    'membership.cancelled',
    'membership.paused',
    'membership.resumed',
    'membership.updated',
    'membership.issued',
  };

  @override
  void initState() {
    super.initState();
    _repo = ClassesRepository(context.read<ApiClient>());
    final now = appClock.now();
    _today = DateTime(now.year, now.month, now.day);
    _weekStart = _today.subtract(Duration(days: _today.weekday - 1));
    _selected = _today.weekday - 1;
    _loadClasses();
    _sseSub = widget.gymState.sse?.events.listen((ev) {
      if (_classReloadEvents.contains(ev.type) && mounted) _loadClasses();
    });
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    super.dispose();
  }

  /// 이 주 전체(월 00:00 ~ 다음 월 00:00) 한 번에 받아 날짜별로 나눈다.
  /// 요일마다 따로 부르면 7배 왕복 — 한 주는 한 요청이면 충분하다.
  ///
  /// FutureBuilder 를 쓰지 않는 이유: 예약 직후 다시 부를 때 스냅샷이 waiting
  /// 으로 초기화되면서 **한 주 요약이 통째로 빈칸으로 깜빡였다** (에뮬 확인).
  /// 이전 결과를 그대로 들고 있다가 새 결과로 갈아끼운다.
  Future<void> _loadClasses({bool keepPrevious = true}) async {
    setState(() {
      _classesLoading = true;
      _classesError = false;
      if (!keepPrevious) _classes = const [];
    });
    try {
      final list = await _repo.listClasses(
        from: _weekStart,
        to: _weekStart.add(const Duration(days: 7)),
      );
      if (!mounted) return;
      setState(() {
        _classes = list;
        _classesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _classesLoading = false;
        _classesError = true;
      });
    }
  }

  void _shiftWeek(int weeks) {
    Haptic.light();
    final next = _weekStart.add(Duration(days: 7 * weeks));
    setState(() {
      _weekStart = next;
      // 이번 주로 돌아오면 오늘, 다른 주면 월요일부터 본다.
      final isThisWeek =
          !_today.isBefore(next) &&
          _today.isBefore(next.add(const Duration(days: 7)));
      _selected = isThisWeek ? _today.weekday - 1 : 0;
    });
    // 주가 바뀌면 이전 주 수업은 남겨 둘 이유가 없다 (다른 날짜의 데이터).
    _loadClasses(keepPrevious: false);
  }

  void _select(int i) {
    Haptic.light();
    // 열린 날을 다시 누르면 접는다 — 7줄만 남아 한 주 전체가 한눈에 들어온다.
    setState(() => _selected = _selected == i ? -1 : i);
  }

  /// 칸 전환. 주(`_weekStart`)는 건드리지 않는다 — 보던 주가 그대로다.
  ///
  /// v3.40: **프로그램 칸으로 갈 때만 오늘을 펼친다.** 그 칸은 "오늘 뭐 하지"에
  /// 답하는 자리라 접힌 채로 열리면 아무것도 안 보인다. 보고 있던 주에 오늘이
  /// 없으면(지난 주·다음 주) 건드리지 않는다 — 없는 날을 펼칠 수는 없다.
  /// 수업 시간 칸은 종전대로 보던 자리를 유지한다.
  void _selectPane(int i) {
    final program = i == 0;
    if (program == _program) return;
    Haptic.light();
    setState(() {
      _program = program;
      if (program) {
        final todayIdx = _today.difference(_weekStart).inDays;
        if (todayIdx >= 0 && todayIdx < 7) _selected = todayIdx;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gymState;
    final wodsByDate = <String, List<GymWodPost>>{};
    for (final w in gs.wods) {
      wodsByDate.putIfAbsent(w.postDate, () => []).add(w);
    }

    final classesByDate = <String, List<ClassSessionDto>>{};
    for (final c in _classes) {
      // 내 예약이 없는 취소 수업은 노이즈 — 목록에서 제외 (v1.26 규칙 유지).
      if (c.isCancelled && c.myReservation == null) continue;
      classesByDate.putIfAbsent(ymd(c.startAt.toLocal()), () => []).add(c);
    }
    for (final list in classesByDate.values) {
      list.sort((a, b) => a.startAt.compareTo(b.startAt));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HkSegment(
          key: WeekBoard.kPaneSwitch,
          labels: const [WeekBoard.paneProgram, WeekBoard.paneSchedule],
          selected: _program ? 0 : 1,
          onSelected: _selectPane,
        ),
        const SizedBox(height: HyphenTokens.sp2),
        _weekHeader(),
        const SizedBox(height: HyphenTokens.sp2),
        HkCard(
          padding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < 7; i++)
                _DayTile(
                  key: WeekBoard.dayKey(i),
                  date: _weekStart.add(Duration(days: i)),
                  weekdayLabel: _wk[i],
                  isToday: _weekStart.add(Duration(days: i)) == _today,
                  isSelected: _selected == i,
                  isLast: i == 6,
                  program: _program,
                  wods:
                      wodsByDate[ymd(_weekStart.add(Duration(days: i)))] ??
                      const [],
                  classes:
                      classesByDate[ymd(_weekStart.add(Duration(days: i)))] ??
                      const [],
                  // 이전 결과를 들고 있는 동안은 로딩 취급하지 않는다 (깜빡임 방지).
                  classesLoading: _classesLoading && _classes.isEmpty,
                  classesError: _classesError,
                  today: _today,
                  // S5 (2026-08-26): 그날 유효한 회원권이 없으면 예약 배지가
                  // '회원권 필요' 로 바뀐다. 과제 4 (2026-08-30): 그 답은 서버가 수업마다
                  // 내려준다 (membership_ok — 예약 게이트와 같은 함수). 폰은 날짜를 세지 않는다.
                  membershipOk:
                      (classesByDate[ymd(_weekStart.add(Duration(days: i)))] ??
                              const <ClassSessionDto>[])
                          .every((c) => c.membershipOk ?? true),
                  onTap: () => _select(i),
                  onReserve: (c) async {
                    final ok = await reserveClassFlow(context, _repo, c);
                    if (ok && mounted) {
                      _loadClasses();
                      gs.refreshMemberships(); // D57 횟수권 잔여 갱신
                    }
                  },
                  onCancel: (c) async {
                    final ok = await cancelClassFlow(context, _repo, c);
                    if (ok && mounted) {
                      _loadClasses();
                      gs.refreshMemberships(); // D57 횟수권 잔여 갱신
                    }
                  },
                  onRetryClasses: _loadClasses,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weekHeader() {
    final end = _weekStart.add(const Duration(days: 6));
    final isThisWeek =
        !_today.isBefore(_weekStart) &&
        _today.isBefore(_weekStart.add(const Duration(days: 7)));
    String md(DateTime d) => '${d.month}.${d.day}';
    return Row(
      key: WeekBoard.kWeekNav,
      children: [
        IconButton(
          onPressed: () => _shiftWeek(-1),
          icon: const Icon(Icons.chevron_left, size: 22),
          color: HyphenTokens.fgSecondary,
          tooltip: '이전 주',
          constraints: const BoxConstraints(
            minWidth: HyphenTokens.touchMin,
            minHeight: HyphenTokens.touchMin,
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${md(_weekStart)} – ${md(end)}',
                style: HyphenTokens.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: HyphenTokens.tabular,
                ),
              ),
              if (isThisWeek) ...[
                const SizedBox(width: HyphenTokens.sp2),
                // 브랜드색은 '오늘' 표식 하나로 충분하다 — 여기까지 빨강이면
                // 강조가 둘로 갈린다 (링코 F1).
                const HkBadge('이번 주', color: HyphenTokens.muted),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () => _shiftWeek(1),
          icon: const Icon(Icons.chevron_right, size: 22),
          color: HyphenTokens.fgSecondary,
          tooltip: '다음 주',
          constraints: const BoxConstraints(
            minWidth: HyphenTokens.touchMin,
            minHeight: HyphenTokens.touchMin,
          ),
        ),
      ],
    );
  }
}

/// 그날 프로그램을 **화면에 내보낼 순서·개수**로 고른다 (v3.41 · 2026-08-29).
///
/// 사용자 지시: "그날 수업이 시간 순서대로 (어웨이크, 스웻, 빌드): 가장 빠른순대로
/// 중복은 표시하지 않고, 수업 펼쳐져서 내용은 다 보여야 함".
///
/// - **순서** = 그 수업 종류의 그날 **첫 수업 시각**(서버가 `first_class_at` 로 준다).
///   시각이 없는 글(수업 종류에 안 붙은 단발)은 맨 뒤로, 그 안에서는 게시 순.
/// - **중복 제거** = 같은 수업 종류(`templateId`)·같은 세션(`variant`, D89)은 한 번만.
///   하루에 BUILD 가 두 번 돌아도 내용은 하나이므로 두 번 적을 이유가 없다. 다만
///   AWAKE A 세션과 B 세션은 다른 프로그램이라 둘 다 남는다. 종류가 없는 글은 각각
///   남긴다 (서로 다른 글일 수 있다).
List<GymWodPost> visibleProgram(List<GymWodPost> wods) {
  final seen = <String>{};
  final out = <GymWodPost>[];
  for (final w in wods) {
    if (w.templateId != null &&
        !seen.add('${w.templateId}|${w.variant ?? ''}')) {
      continue;
    }
    out.add(w);
  }
  out.sort((a, b) {
    final at = a.firstClassAt, bt = b.firstClassAt;
    if (at != null && bt != null) return at.compareTo(bt);
    if (at != null) return -1;   // 시각이 있는 쪽이 먼저
    if (bt != null) return 1;
    return a.id.compareTo(b.id); // 둘 다 없으면 게시 순
  });
  return out;
}

/// 하루 = 접힌 줄 하나. 펼치면 지금 보고 있는 칸의 것 **하나만** — 수업 시간
/// 칸이면 수업 줄(예약 버튼 포함), 프로그램 칸이면 그날 프로그램 (v3.37).
class _DayTile extends StatelessWidget {
  final DateTime date;
  final String weekdayLabel;
  final bool isToday;
  final bool isSelected;
  final bool isLast;

  /// true = 프로그램 칸 · false = 수업 시간 칸.
  final bool program;
  final List<GymWodPost> wods;
  final List<ClassSessionDto> classes;
  final bool classesLoading;
  final bool classesError;
  final DateTime today;
  final bool membershipOk;
  final VoidCallback onTap;
  final Future<void> Function(ClassSessionDto) onReserve;
  final Future<void> Function(ClassSessionDto) onCancel;
  final VoidCallback onRetryClasses;

  const _DayTile({
    super.key,
    required this.date,
    required this.weekdayLabel,
    required this.isToday,
    required this.isSelected,
    required this.isLast,
    required this.program,
    required this.wods,
    required this.classes,
    required this.classesLoading,
    required this.classesError,
    required this.today,
    required this.membershipOk,
    required this.onTap,
    required this.onReserve,
    required this.onCancel,
    required this.onRetryClasses,
  });

  bool get _isFuture => date.isAfter(today);
  bool get _isPast => date.isBefore(today);

  /// 요일 줄 오른쪽 한 줄 요약 — **펼치지 않고도 그날을 고를 수 있게** 하는 줄이라
  /// 지금 보고 있는 칸이 답해야 하는 질문에 답한다 (v3.37).
  ///
  /// 2026-08-28 테스터 보고 — "수업 외 2 라고 되어 있는 것보다 항목 이름이 있으면
  /// 좋겠다". 종전 문구 `'$first 외 ${n}'` 은 "그 수업 **외** 2건" 이라는 뜻이었는데,
  /// 읽는 사람에겐 **'수업외' 라는 분류가 2개** 로 읽혔다. 뜻이 뒤집혀 읽히는 문구는
  /// 없는 것만 못하다. 그래서 개수 대신 **이름을 그대로** 적는다.
  String get _summary => program ? _programSummary : _scheduleSummary;

  /// 수업 시간 칸 — "그날 무슨 수업이 도느냐". 코치가 시간표에 적어 둔 수업 이름이
  /// 곧 회원이 아는 이름이다 (AWAKE·SWEAT·BUILD).
  String get _scheduleSummary {
    final names = <String>[];
    for (final c in classes) {
      final t = c.displayTitle.trim(); // D89 — 'AWAKE · A 세션' (서버 표시 제목)
      if (t.isNotEmpty && !names.contains(t)) names.add(t);
    }
    if (names.isEmpty) return classesLoading ? '' : '수업 없음';
    return _joined(names);
  }

  /// 프로그램 칸 — "그날 무엇을 하느냐". 수업 이름은 옆 칸의 것이므로 여기엔
  /// 안 적는다 (그게 두 칸을 나눈 이유다).
  String get _programSummary {
    final names = <String>[];
    // 접힌 줄 요약과 펼친 내용이 어긋나면 안 된다 — 같은 목록을 쓴다 (v3.41).
    for (final w in visibleProgram(wods)) {
      final n = _programName(w);
      if (n.isNotEmpty && !names.contains(n)) names.add(n);
    }
    if (names.isEmpty) return _isFuture ? '게시 전' : '프로그램 없음';
    return _joined(names);
  }

  /// 좁은 줄이라 최대 3개까지 적고 넘으면 `+N` 으로 센다 (그때의 N 은 '더 있다'
  /// 는 뜻이라 오해할 여지가 없다).
  static String _joined(List<String> names) => names.length <= 3
      ? names.join(' · ')
      : '${names.take(3).join(' · ')} +${names.length - 3}';

  /// 프로그램 한 건의 이름표.
  ///
  /// 종류(FOR TIME·AMRAP·EMOM)가 곧 이름이다. 다만 PC 에서 자동 게시된 글은
  /// 종류가 `custom` 이라 라벨이 '수업' 인데, 프로그램 칸에서 '수업' 은 옆 칸을
  /// 가리키는 말로 읽힌다 — 그때는 본문 첫 줄을 대신 적는다 (코치가 쓴 말이
  /// 가장 정확한 이름표다). 잠긴 글은 본문이 비어 오므로 잠긴 사유를 적는다.
  static String _programName(GymWodPost w) {
    if (w.locked) return '회원권 만료';
    // v3.41 — 수업 종류 이름이 곧 회원이 아는 이름이다 (AWAKE·SWEAT·BUILD).
    // D89 — 세션이 있으면 서버가 붙인 이름표 그대로 ('AWAKE · A 세션').
    final tn = (w.displayName ?? w.templateName ?? '').trim();
    if (tn.isNotEmpty) return tn;
    if (w.wodType != 'custom') return wodTypeLabel(w.wodType);
    for (final line in w.content.split('\n')) {
      final t = line.trim();
      if (t.isNotEmpty) return t;
    }
    return '게시됨';
  }

  @override
  Widget build(BuildContext context) {
    final dayColor = isToday
        ? HyphenTokens.primary
        : (_isPast ? HyphenTokens.muted : HyphenTokens.fg);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? HyphenTokens.surfaceAlt : HyphenTokens.surface,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: HyphenTokens.border, width: 1),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HyphenTokens.sp3,
                vertical: HyphenTokens.sp2,
              ),
              child: Row(
                children: [
                  // 요일 + 일자 — 좌측 고정 폭. 세로 두 줄이면 줄이 길어지므로
                  // 가로 한 줄로 붙인다 ('월 10').
                  SizedBox(
                    width: 46,
                    child: Row(
                      children: [
                        Text(
                          weekdayLabel,
                          style: HyphenTokens.caption.copyWith(
                            color: dayColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${date.day}',
                          style: HyphenTokens.body.copyWith(
                            color: dayColor,
                            fontWeight: FontWeight.w700,
                            fontFeatures: HyphenTokens.tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isToday) ...[
                    const HkBadge('오늘', color: HyphenTokens.primary),
                    const SizedBox(width: HyphenTokens.sp2),
                  ],
                  Expanded(
                    child: Text(
                      _summary,
                      style: HyphenTokens.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: HyphenTokens.muted,
                  ),
                ],
              ),
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HyphenTokens.sp3,
                0,
                HyphenTokens.sp3,
                HyphenTokens.sp3,
              ),
              // v3.37: 칸 이름이 이미 어느 면인지 말하므로 구역 라벨을 다시 달지
              // 않는다 (DESIGN-SSOT §7-D 8 — 같은 말을 두 번 쓰지 않는다).
              // 구 v3.0 의 '수업 내용'·'수업 시간' 두 라벨은 한 카드에 두 면이
              // 쌓여 있을 때 어느 쪽인지 갈라 주던 것이라 칸 분리로 소임이 끝났다.
              child: program ? _wodBlock() : _classBlock(),
            ),
        ],
      ),
    );
  }

  Widget _wodBlock() {
    if (wods.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: HyphenTokens.sp1),
        child: Text(
          // v3.37: 칸 이름이 '프로그램' 이므로 없는 것도 프로그램이라고 부른다
          // — 칸 이름과 빈 문구가 다른 것을 가리키면 그게 곧 헷갈림이다.
          _isFuture ? '아직 게시 전.' : '게시된 프로그램 없음.',
          style: HyphenTokens.caption,
        ),
      );
    }
    final dateLabel =
        '${date.month.toString().padLeft(2, '0')}'
        '.${date.day.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // '당일 공개' 잠금 폐지 (2026-08-23) — 미래 게시물도 회원에게 그대로.
        // 잠금 사유는 회원권 만료(w.locked)뿐.
        for (final w in visibleProgram(wods))
          if (w.locked)
            LockedWodBanner(
              dateLabel: dateLabel,
              wodType: w.wodType,
              showDate: false,
            )
          else
            WodRow(
              wod: w,
              dateLabel: dateLabel,
              // 지난 날 WOD 도 이 날을 직접 골라 연 것이므로 흐리게 두지 않는다.
              isToday: !_isPast,
              // v3.41 (2026-08-29 사용자 지시 "수업 펼쳐져서 내용은 다 보여야 함")
              // — **전부 펼친다.** 종전엔 첫 개만 펼쳤는데(2026-08-12 그 밑 수업이
              // 밀려서), 이제 프로그램 칸에는 수업 줄이 아예 없어 밀릴 것이 없다.
              initiallyExpanded: true,
              showDate: false,
            ),
      ],
    );
  }

  /// v3.34 (2026-08-27): 요일을 펼치면 스피너 자리(46) → 수업 목록으로 높이가
  /// 바뀌며 그 아래 요일 줄들이 밀렸다. 이제 로딩·없음·목록이 같은 예약 자리를
  /// 쓴다 (HkSectionSlot — DESIGN-SSOT §레이아웃 안정성).
  /// `_loadClasses(keepPrevious: true)` 가 재조회 깜빡임을 막아 둔 것과 같은 뜻 —
  /// 화면이 바뀌는 것은 내용이지 자리가 아니다.
  Widget _classBlock() {
    final Widget? content = classesError
        ? HkInlineError('수업 불러오기 실패.', onRetry: onRetryClasses)
        : (classes.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final c in classes)
                      ClassLine.member(
                        session: c,
                        isPastDay: _isPast,
                        membershipOk: membershipOk,
                        onReserve: () => onReserve(c),
                        onCancel: () => onCancel(c),
                      ),
                  ],
                ));
    return Padding(
      padding: const EdgeInsets.only(top: HyphenTokens.sp1),
      child: HkSectionSlot(
        minHeight: WeekBoard.classSlotH,
        loading: classesLoading && !classesError,
        empty: '등록된 수업 없음.',
        child: content,
      ),
    );
  }
}

// (구 _ClassLine 은 v3.25 에서 classes/class_line.dart 로. v3.28: 코치 분기(isOwner)
// 제거 — 코치는 boss/coach_week_classes.dart 가 같은 부품으로 따로 조립한다.)
