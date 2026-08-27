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
/// 그날 WOD 와 수업이 그 자리에서 펼쳐진다 (한 번에 하나만). 수업 줄 오른쪽에
/// 예약 버튼이 붙어 "보고 → 바로 예약"이 한 화면에서 끝난다.
class WeekBoard extends StatefulWidget {
  final GymState gymState;

  const WeekBoard({super.key, required this.gymState});

  /// 레이아웃 안정성 앵커 (v3.34 · 2026-08-27) — 어느 날을 펼쳐도 그 아래
  /// 요일 줄은 제자리에 있어야 한다 (0=월 … 6=일).
  /// 회귀 게이트 = test/golden/stability_wod_test.dart.
  static Key dayKey(int index) => ValueKey('week-day-$index');

  /// 펼친 날의 '수업 시간' 구역이 미리 잡아 두는 자리 (공간 예약).
  /// 값 = 수업 한 줄(ClassLine)의 실측 높이 — 로딩 스켈레톤·'없음' 문구·수업
  /// 줄이 이 자리를 함께 쓴다 (DESIGN-SSOT §레이아웃 안정성).
  static const double classSlotH = 56;

  @override
  State<WeekBoard> createState() => _WeekBoardState();
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
                  // '회원권 필요' 로 바뀐다 (서버 MEMBERSHIP_REQUIRED 의 거울).
                  membershipOk: gs.hasMembershipOn(
                    _weekStart.add(Duration(days: i)),
                  ),
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

/// 하루 = 접힌 줄 하나. 펼치면 그날 WOD + 수업(예약 버튼 포함).
class _DayTile extends StatelessWidget {
  final DateTime date;
  final String weekdayLabel;
  final bool isToday;
  final bool isSelected;
  final bool isLast;
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

  String get _summary {
    final parts = <String>[];
    if (wods.isNotEmpty) {
      final first = wodTypeLabel(wods.first.wodType);
      parts.add(wods.length > 1 ? '$first 외 ${wods.length - 1}' : first);
    }
    if (classes.isNotEmpty) parts.add('수업 ${classes.length}');
    if (parts.isEmpty) return classesLoading ? '' : '일정 없음';
    return parts.join(' · ');
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // v3.0 (2026-08-14): 게시물 면 = '수업 내용', 시간표 면 = '수업 시간'
                  // — '수업' 단독 표기가 두 면 중 어느 쪽인지 안 읽히던 것을 분리.
                  const HkSectionLabel('수업 내용'),
                  _wodBlock(),
                  const SizedBox(height: HyphenTokens.sp3),
                  const HkSectionLabel('수업 시간'),
                  _classBlock(),
                ],
              ),
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
          _isFuture ? '아직 게시 전.' : '게시된 수업 내용 없음.',
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
        for (final (i, w) in wods.indexed)
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
              // 하루에 WOD 가 둘 이상이면 첫 개만 펼친다 — 실기에서 둘 다 펼쳐져
              // 그 밑 수업이 화면 밖으로 밀렸다 (2026-08-12 에뮬 확인).
              initiallyExpanded: i == 0,
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
