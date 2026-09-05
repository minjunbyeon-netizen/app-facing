import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_clock.dart';
import '../../core/haptic.dart';
import '../../core/sse_client.dart';
import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../models/class_session.dart';
import '../../models/gym.dart';
import '../../widgets/hkit.dart';
import '../classes/class_flows.dart' show cancelClassFlow, reserveClassFlow;
import '../classes/class_line.dart';
import '../classes/classes_repository.dart';
import 'gym_state.dart';
import 'wod_row.dart';

/// 회원 수업 탭 = **통합 한 줄** (D111 · 2026-09-04 사용자 "1안").
///
/// 회원의 결정은 하나다 — "20:00 SWEAT 에 가서 이걸 한다". 종전(v3.37~v3.41)엔
/// 그 하나를 프로그램 칸(동기)과 수업 시간 칸(버튼)으로 갈라 두 칸 사이를 오가야
/// 했고, 요일 아코디언 + 카드 이중 펼침에 '수업 없음' 요일 줄이 오늘 위에 쌓여
/// 첫 화면에 행동할 것이 적었다. 이제:
///
/// 1. 주 이동 줄 (‹ 8.10 – 8.16 [이번 주] ›) — 그대로.
/// 2. **요일 띠** 7칸 ([HkDayStrip]) — 고른 날 하나만 아래에 편다. 기본 = 오늘(그 주에
///    있으면), 다른 주는 월. 점 = 내 예약(주색) / 수업 있음(회색) / 없음 — [dayMark].
/// 3. **수업 줄 목록** (고른 날, 시작 시각 순) — [ClassLine.member] 규격 그대로. 접힌
///    줄 밑에 그 종류의 그날 프로그램 한 줄 요약(서버 `summary`).
/// 4. **펼침** = 그 줄의 수업 종류(`templateId`)에 붙은 그날 글을 [WodRow] 본문만으로
///    (파트 세로 · 메모 · 완료/메시지/자세히). 글이 없으면 '아직 게시 전.'/'게시된
///    프로그램 없음.', 잠긴 글은 [LockedWodBanner].
/// 5. **여닫기** = 사람이 누른 것만 (D112 · 2026-09-04 사용자 지시). 날짜를 눌러 들어오면
///    모든 줄이 닫혀 있고, 이름 옆 화살표(또는 줄 본문)를 눌러야 열린다. 날짜를 옮기면
///    다시 전부 닫힌다 — 자동으로 열리는 줄은 없다.
/// 6. 수업 종류가 없는 단발 글·그날 수업이 없는 종류의 글은 목록 아래 '프로그램' 라벨
///    밑에 종전 카드(머리 포함) — [leftoverPrograms]. 글이 사라지지 않는다.
///
/// 정의는 여기 한 곳이다 — 요약·라벨·판정 문구는 서버 값을 그대로 적고, 순서·중복·
/// 자동 펼침·점만 이 파일의 순수 함수가 정한다 (회귀 = test/golden/class_tab_test.dart).
class WeekBoard extends StatefulWidget {
  final GymState gymState;

  const WeekBoard({super.key, required this.gymState});

  /// 요일 띠의 칸 (0=월 … 6=일) — 어느 날을 골라도, 목록이 로딩·도착·없음·실패여도
  /// 이 칸들과 [kWeekNav] 의 y 는 불변이다. 회귀 = test/golden/stability_wod_test.dart.
  static Key dayKey(int index) => ValueKey('week-day-$index');

  static const Key kWeekNav = Key('week-nav');
  static const Key kDayStrip = Key('week-day-strip');

  /// 수업 줄 (class id) — 검사가 줄을 집어 펼친다.
  static Key rowKey(int classId) => ValueKey('class-row-$classId');

  /// 고른 날의 목록이 미리 잡아 두는 자리 (공간 예약) — 수업 한 줄 실측 높이.
  /// 로딩 스켈레톤·'없음' 문구·수업 줄이 이 자리를 함께 쓴다 (DESIGN-SSOT §레이아웃 안정성).
  static const double classSlotH = 65;

  /// 수업이 없는 종류의 글이 서는 구역 라벨.
  static const String leftoverLabel = '프로그램';

  @override
  State<WeekBoard> createState() => _WeekBoardState();
}

/// 요일 칸의 점 — 정의는 이 함수 하나.
/// 내 예약(확정·대기)이 있으면 [HkDayMark.reserved], 수업이 하나라도 있으면
/// [HkDayMark.hasClass], 없으면 [HkDayMark.none].
HkDayMark dayMark(List<ClassSessionDto> dayClasses) {
  if (dayClasses.any((c) => c.isReserved || c.isWaitlisted)) {
    return HkDayMark.reserved;
  }
  return dayClasses.isEmpty ? HkDayMark.none : HkDayMark.hasClass;
}

/// 그날 프로그램을 **화면에 내보낼 순서·개수**로 고른다 (v3.41 · 2026-08-29).
///
/// - **순서** = 그 수업 종류의 그날 **첫 수업 시각**(서버 `first_class_at`).
///   시각이 없는 글(수업 종류에 안 붙은 단발)은 맨 뒤로, 그 안에서는 게시 순.
/// - **중복 제거** = 같은 수업 종류(`templateId`)는 한 번만. 종류가 없는 글은 각각
///   남긴다. D109: 같은 수업의 A·B·C 는 한 글 안의 **파트**라 카드 한 장 안에 선다.
List<GymWodPost> visibleProgram(List<GymWodPost> wods) {
  final seen = <int>{};
  final out = <GymWodPost>[];
  for (final w in wods) {
    if (w.templateId != null && !seen.add(w.templateId!)) {
      continue;
    }
    out.add(w);
  }
  out.sort((a, b) {
    final at = a.firstClassAt, bt = b.firstClassAt;
    if (at != null && bt != null) return at.compareTo(bt);
    if (at != null) return -1; // 시각이 있는 쪽이 먼저
    if (bt != null) return 1;
    return a.id.compareTo(b.id); // 둘 다 없으면 게시 순
  });
  return out;
}

/// 수업 줄에 붙는 그날 글 — 그 줄의 수업 종류(`templateId`)와 같은 글 (종류당 첫 글).
/// 종류가 없는 수업(단발)은 글을 붙이지 않는다 — 이름으로 맞추지 않는다 (6-b).
GymWodPost? programFor(ClassSessionDto c, List<GymWodPost> wods) {
  final tid = c.templateId;
  if (tid == null) return null;
  for (final w in visibleProgram(wods)) {
    if (w.templateId == tid) return w;
  }
  return null;
}

/// 수업 줄 어디에도 안 붙는 글 — 종류가 없는 단발 글 · 그날 수업이 없는 종류의 글.
/// 목록 아래 '프로그램' 라벨 밑에 종전 카드(머리 포함)로 선다.
List<GymWodPost> leftoverPrograms(
  List<GymWodPost> wods,
  List<ClassSessionDto> classes,
) {
  final attached = {
    for (final c in classes)
      if (c.templateId != null) c.templateId!,
  };
  return [
    for (final w in visibleProgram(wods))
      if (w.templateId == null || !attached.contains(w.templateId)) w,
  ];
}

class _WeekBoardState extends State<WeekBoard> {
  static const List<String> _wk = ['월', '화', '수', '목', '금', '토', '일'];

  late final ClassesRepository _repo;
  late DateTime _today;
  late DateTime _weekStart; // 그 주 월요일 00:00
  late int _selected; // 0(월)~6(일)
  List<ClassSessionDto> _classes = const [];
  bool _classesLoading = false;
  bool _classesError = false;
  StreamSubscription<SseEvent>? _sseSub;

  /// 지금 고른 날에서 **사람이 연** 줄 (class id). 날짜를 옮기면 비운다 — 새 날은 전부
  /// 닫힌 채로 시작한다 (D112). 재조회(SSE·예약)는 이 집합을 건드리지 않는다.
  Set<int> _expanded = {};

  /// D58 (2026-08-26 PC·에뮬 실주행): 코치가 회원권을 해지·정지·수정해 서버가 예약을
  /// 지웠는데(revoke_uncovered_reservations) 보드는 '예약됨' 을 그대로 보였다.
  /// GymState 는 회원권·수업 내용만 다시 받으므로 수업 목록은 여기서 직접 듣는다.
  /// 2026-09-02: 코치가 수업을 새로 등록·수정하면 서버가 `wod.posted` 를 쏜다
  /// (classes.py D106) — 여기서도 듣는다. 다른 회원의 예약 생성(member_reservation_created)
  /// 도 듣는다 — isFull(마감)·대기 순번이 이 수에 달려 있다.
  static const _classReloadEvents = <String>{
    'wod.posted',
    'member_reservation_created',
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
    // 2026-09-06 — '오늘' 도 체육관 시각(한국). 기기 시계(UTC 에뮬 등)로 세면
    // 수업(기기 날짜)과 글(서버 한국 날짜)이 다른 날에 묶인다.
    _today = appClock.now().gymDay();
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
      _expanded = {}; // 다른 날 = 다시 전부 닫힘 (D112)
    });
    // 주가 바뀌면 이전 주 수업은 남겨 둘 이유가 없다 (다른 날짜의 데이터).
    _loadClasses(keepPrevious: false);
  }

  void _select(int i) {
    if (i == _selected) return;
    Haptic.light();
    setState(() {
      _selected = i;
      _expanded = {}; // 날짜를 옮기면 전부 닫힌 채로 (D112)
    });
  }

  /// 이름 옆 화살표(또는 줄 본문) 탭 — 그 줄만 여닫는다. 여러 줄을 함께 열어 둘 수 있다.
  void _toggleRow(int classId) {
    Haptic.light();
    setState(() {
      final next = Set<int>.from(_expanded);
      if (!next.remove(classId)) next.add(classId);
      _expanded = next;
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
      classesByDate.putIfAbsent(ymd(c.startAt.gym()), () => []).add(c);
    }
    for (final list in classesByDate.values) {
      list.sort((a, b) => a.startAt.compareTo(b.startAt));
    }

    final date = _weekStart.add(Duration(days: _selected));
    final day = ymd(date);
    final dayClasses = classesByDate[day] ?? const <ClassSessionDto>[];
    final dayWods = wodsByDate[day] ?? const <GymWodPost>[];
    final expanded = _expanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _weekHeader(),
        const SizedBox(height: HyphenTokens.sp2),
        HkDayStrip(
          key: WeekBoard.kDayStrip,
          cells: [
            for (var i = 0; i < 7; i++)
              HkDayCell(
                weekday: _wk[i],
                day: _weekStart.add(Duration(days: i)).day,
                isToday: _weekStart.add(Duration(days: i)) == _today,
                mark: dayMark(
                  classesByDate[ymd(_weekStart.add(Duration(days: i)))] ??
                      const <ClassSessionDto>[],
                ),
              ),
          ],
          selected: _selected,
          onSelected: _select,
          cellKey: WeekBoard.dayKey,
        ),
        const SizedBox(height: HyphenTokens.sp2),
        HkCard(
          padding: const EdgeInsets.symmetric(
            horizontal: HyphenTokens.sp3,
            vertical: HyphenTokens.sp2,
          ),
          clipBehavior: Clip.antiAlias,
          child: _DayList(
            date: date,
            today: _today,
            classes: dayClasses,
            wods: dayWods,
            expanded: expanded,
            // 이전 결과를 들고 있는 동안은 로딩 취급하지 않는다 (깜빡임 방지).
            loading: _classesLoading && _classes.isEmpty,
            error: _classesError,
            // S5 (2026-08-26): 그날 유효한 회원권이 없으면 예약 배지가 '회원권 필요'.
            // 과제 4 (2026-08-30): 그 답은 서버가 수업마다 내려준다 (membership_ok —
            // 예약 게이트와 같은 함수). 폰은 날짜를 세지 않는다.
            membershipOk: dayClasses.every((c) => c.membershipOk ?? true),
            onToggle: (c) => _toggleRow(c.id),
            onReserve: (c) async {
              final ok = await reserveClassFlow(context, _repo, c);
              if (ok && mounted) {
                _loadClasses();
                gs.refreshMemberships(); // D57 횟수권 잔여 갱신
                // 완료 배지(completion_blocked)는 회원별 판정 — 예약을
                // 따라가야 한다 (2026-09-02 프로드 stale 결함 픽스).
                gs.refreshWods();
              }
            },
            onCancel: (c) async {
              final ok = await cancelClassFlow(context, _repo, c);
              if (ok && mounted) {
                _loadClasses();
                gs.refreshMemberships(); // D57 횟수권 잔여 갱신
                gs.refreshWods(); // 위 onReserve 와 같은 이유
              }
            },
            onRetry: _loadClasses,
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

/// 고른 날의 수업 줄 목록 + 어디에도 안 붙는 글.
///
/// 로딩·없음·실패·목록이 같은 예약 자리([HkSectionSlot])를 쓴다 — 어느 상태여도
/// 위의 요일 띠·주 이동 줄은 제자리다 (v3.34 의 처방 그대로).
class _DayList extends StatelessWidget {
  final DateTime date;
  final DateTime today;
  final List<ClassSessionDto> classes;
  final List<GymWodPost> wods;
  final Set<int> expanded;
  final bool loading;
  final bool error;
  final bool membershipOk;
  final void Function(ClassSessionDto) onToggle;
  final Future<void> Function(ClassSessionDto) onReserve;
  final Future<void> Function(ClassSessionDto) onCancel;
  final VoidCallback onRetry;

  const _DayList({
    required this.date,
    required this.today,
    required this.classes,
    required this.wods,
    required this.expanded,
    required this.loading,
    required this.error,
    required this.membershipOk,
    required this.onToggle,
    required this.onReserve,
    required this.onCancel,
    required this.onRetry,
  });

  bool get _isFuture => date.isAfter(today);
  bool get _isPast => date.isBefore(today);

  @override
  Widget build(BuildContext context) {
    if (error) {
      return HkSectionSlot(
        minHeight: WeekBoard.classSlotH,
        loading: false,
        empty: '',
        child: HkInlineError('수업 불러오기 실패.', onRetry: onRetry),
      );
    }
    final leftovers = leftoverPrograms(wods, classes);
    final Widget? content = (classes.isEmpty && leftovers.isEmpty)
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final c in classes) ...[
                ClassLine.member(
                  key: WeekBoard.rowKey(c.id),
                  session: c,
                  isPastDay: _isPast,
                  membershipOk: membershipOk,
                  expanded: expanded.contains(c.id),
                  onToggle: () => onToggle(c),
                  onReserve: () => onReserve(c),
                  onCancel: () => onCancel(c),
                ),
                if (expanded.contains(c.id))
                  _ProgramBlock(
                    post: programFor(c, wods),
                    date: date,
                    isFuture: _isFuture,
                    isPast: _isPast,
                  ),
              ],
              if (leftovers.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.only(
                    top: classes.isEmpty ? HyphenTokens.sp1 : HyphenTokens.sp3,
                  ),
                  child: const HkSectionLabel(WeekBoard.leftoverLabel),
                ),
                for (final w in leftovers)
                  if (w.locked)
                    LockedWodBanner(
                      dateLabel: mdDot(date),
                      wodType: w.wodType,
                      showDate: false,
                    )
                  else
                    WodRow(
                      wod: w,
                      dateLabel: mdDot(date),
                      // 지난 날 글도 이 날을 직접 골라 연 것이므로 흐리게 두지 않는다.
                      isToday: !_isPast,
                      // D112 — 이 날의 모든 것은 닫힌 채로 시작한다. 수업 줄과 같은
                      // 규칙이라야 한 화면에 두 규칙이 살지 않는다 (구 v3.41 '전부 펼침' 폐기).
                      initiallyExpanded: false,
                      showDate: false,
                    ),
              ],
            ],
          );
    return HkSectionSlot(
      minHeight: WeekBoard.classSlotH,
      loading: loading,
      empty: '등록된 수업 없음.',
      child: content,
    );
  }
}

/// 펼친 수업 줄 아래 — 그 종류의 그날 글 본문만 (이름표 머리 없음).
class _ProgramBlock extends StatelessWidget {
  final GymWodPost? post;
  final DateTime date;
  final bool isFuture;
  final bool isPast;

  const _ProgramBlock({
    required this.post,
    required this.date,
    required this.isFuture,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final p = post;
    final Widget body;
    if (p == null) {
      body = Text(
        isFuture ? '아직 게시 전.' : '게시된 프로그램 없음.',
        style: HyphenTokens.caption,
      );
    } else if (p.locked) {
      body = LockedWodBanner(
        dateLabel: mdDot(date),
        wodType: p.wodType,
        showDate: false,
      );
    } else {
      body = WodRow(
        wod: p,
        dateLabel: mdDot(date),
        isToday: !isPast,
        showDate: false,
        headerless: true,
      );
    }
    return Container(
      margin: const EdgeInsets.only(
        top: HyphenTokens.sp1,
        bottom: HyphenTokens.sp2,
      ),
      padding: const EdgeInsets.fromLTRB(
        HyphenTokens.sp3,
        HyphenTokens.sp2,
        HyphenTokens.sp3,
        HyphenTokens.sp2,
      ),
      decoration: BoxDecoration(
        color: HyphenTokens.surfaceAlt,
        borderRadius: BorderRadius.circular(HyphenTokens.r1),
      ),
      child: body,
    );
  }
}
