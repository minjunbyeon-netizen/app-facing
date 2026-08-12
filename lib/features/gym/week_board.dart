import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/class_session.dart';
import '../../models/gym.dart';
import '../../widgets/fkit.dart';
import '../classes/classes_repository.dart';
import '../classes/classes_screen.dart'
    show cancelClassFlow, reserveClassFlow;
import 'gym_state.dart';
import 'wod_row.dart';
import 'wod_type_label.dart';

/// v2.4 (2026-08-12 사용자 지시): WOD 탭 = **그 주 월~일 아코디언**.
///
/// 전에는 오늘·예정·지난 3섹션이 세로로 이어져 오늘 것을 보려면 어느 덩어리를
/// 봐야 하는지부터 골라야 했다. 이제 한 주가 7줄로 고정되고, 요일·날짜를 누르면
/// 그날 WOD 와 수업이 그 자리에서 펼쳐진다 (한 번에 하나만). 수업 줄 오른쪽에
/// 예약 버튼이 붙어 "보고 → 바로 예약"이 한 화면에서 끝난다.
class WeekBoard extends StatefulWidget {
  final GymState gymState;
  const WeekBoard({super.key, required this.gymState});

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

  @override
  void initState() {
    super.initState();
    _repo = ClassesRepository(context.read<ApiClient>());
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _weekStart = _today.subtract(Duration(days: _today.weekday - 1));
    _selected = _today.weekday - 1;
    _loadClasses();
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
      final isThisWeek = !_today.isBefore(next) &&
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

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
      classesByDate.putIfAbsent(_ymd(c.startAt.toLocal()), () => []).add(c);
    }
    for (final list in classesByDate.values) {
      list.sort((a, b) => a.startAt.compareTo(b.startAt));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _weekHeader(),
        const SizedBox(height: FacingTokens.sp2),
        Container(
          decoration: BoxDecoration(
            color: FacingTokens.surface,
            border: Border.all(color: FacingTokens.border),
            borderRadius: BorderRadius.circular(FacingTokens.r3),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < 7; i++)
                _DayTile(
                  date: _weekStart.add(Duration(days: i)),
                  weekdayLabel: _wk[i],
                  isToday: _weekStart.add(Duration(days: i)) == _today,
                  isSelected: _selected == i,
                  isLast: i == 6,
                  wods: wodsByDate[_ymd(_weekStart.add(Duration(days: i)))] ??
                      const [],
                  classes:
                      classesByDate[_ymd(_weekStart.add(Duration(days: i)))] ??
                          const [],
                  // 이전 결과를 들고 있는 동안은 로딩 취급하지 않는다 (깜빡임 방지).
                  classesLoading: _classesLoading && _classes.isEmpty,
                  classesError: _classesError,
                  isOwner: gs.isOwner,
                  today: _today,
                  onTap: () => _select(i),
                  onReserve: (c) async {
                    final ok = await reserveClassFlow(context, _repo, c);
                    if (ok && mounted) _loadClasses();
                  },
                  onCancel: (c) async {
                    final ok = await cancelClassFlow(context, _repo, c);
                    if (ok && mounted) _loadClasses();
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
    final isThisWeek = !_today.isBefore(_weekStart) &&
        _today.isBefore(_weekStart.add(const Duration(days: 7)));
    String md(DateTime d) => '${d.month}.${d.day}';
    return Row(
      children: [
        IconButton(
          onPressed: () => _shiftWeek(-1),
          icon: const Icon(Icons.chevron_left, size: 22),
          color: FacingTokens.fgSecondary,
          tooltip: '이전 주',
          constraints: const BoxConstraints(
              minWidth: FacingTokens.touchMin, minHeight: FacingTokens.touchMin),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${md(_weekStart)} – ${md(end)}',
                style: FacingTokens.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: FacingTokens.tabular,
                ),
              ),
              if (isThisWeek) ...[
                const SizedBox(width: FacingTokens.sp2),
                // 브랜드색은 '오늘' 표식 하나로 충분하다 — 여기까지 빨강이면
                // 강조가 둘로 갈린다 (링코 F1).
                const FkBadge('이번 주', color: FacingTokens.muted),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () => _shiftWeek(1),
          icon: const Icon(Icons.chevron_right, size: 22),
          color: FacingTokens.fgSecondary,
          tooltip: '다음 주',
          constraints: const BoxConstraints(
              minWidth: FacingTokens.touchMin, minHeight: FacingTokens.touchMin),
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
  final bool isOwner;
  final DateTime today;
  final VoidCallback onTap;
  final Future<void> Function(ClassSessionDto) onReserve;
  final Future<void> Function(ClassSessionDto) onCancel;
  final VoidCallback onRetryClasses;

  const _DayTile({
    required this.date,
    required this.weekdayLabel,
    required this.isToday,
    required this.isSelected,
    required this.isLast,
    required this.wods,
    required this.classes,
    required this.classesLoading,
    required this.classesError,
    required this.isOwner,
    required this.today,
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
        ? FacingTokens.primary
        : (_isPast ? FacingTokens.muted : FacingTokens.fg);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? FacingTokens.surfaceAlt : FacingTokens.surface,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: FacingTokens.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FacingTokens.sp3,
                vertical: FacingTokens.sp2,
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
                          style: FacingTokens.caption.copyWith(
                            color: dayColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${date.day}',
                          style: FacingTokens.body.copyWith(
                            color: dayColor,
                            fontWeight: FontWeight.w700,
                            fontFeatures: FacingTokens.tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isToday) ...[
                    const FkBadge('오늘', color: FacingTokens.primary),
                    const SizedBox(width: FacingTokens.sp2),
                  ],
                  Expanded(
                    child: Text(
                      _summary,
                      style: FacingTokens.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: FacingTokens.muted,
                  ),
                ],
              ),
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FacingTokens.sp3,
                0,
                FacingTokens.sp3,
                FacingTokens.sp3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _wodBlock(),
                  const SizedBox(height: FacingTokens.sp3),
                  const Text('수업', style: FacingTokens.sectionLabel),
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
        padding: const EdgeInsets.only(top: FacingTokens.sp1),
        child: Text(
          _isFuture ? '아직 게시 전.' : '게시된 WOD 없음.',
          style: FacingTokens.caption,
        ),
      );
    }
    final dateLabel = '${date.month.toString().padLeft(2, '0')}'
        '.${date.day.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, w) in wods.indexed)
          if (w.locked)
            LockedWodBanner(
              dateLabel: dateLabel,
              wodType: w.wodType,
              isMembershipExpired: true,
              showDate: false,
            )
          else if (_isFuture && !isOwner)
            LockedWodBanner(
              dateLabel: dateLabel,
              wodType: w.wodType,
              isMembershipExpired: false,
              showDate: false,
            )
          else
            WodRow(
              wod: w,
              dateLabel: dateLabel,
              canDelete: isOwner,
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

  Widget _classBlock() {
    if (classesError) {
      return Padding(
        padding: const EdgeInsets.only(top: FacingTokens.sp2),
        child: Row(
          children: [
            const Expanded(
              child: Text('수업 불러오기 실패.', style: FacingTokens.caption),
            ),
            FkButton.tertiary('다시 시도',
                neutral: true, onPressed: onRetryClasses),
          ],
        ),
      );
    }
    if (classesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: FacingTokens.sp3),
        child: FkLoading(),
      );
    }
    if (classes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: FacingTokens.sp1),
        child: Text('등록된 수업 없음.', style: FacingTokens.caption),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in classes)
          _ClassLine(
            session: c,
            isPastDay: _isPast,
            onReserve: () => onReserve(c),
            onCancel: () => onCancel(c),
          ),
      ],
    );
  }
}

/// 수업 한 줄 — 시각 · 이름/정원 · 예약 버튼. 카드가 아니라 줄이라 한 화면에
/// 하루치가 다 들어온다 (v2.4 — 카드 형태는 두 개만 보여도 화면이 찼다).
class _ClassLine extends StatelessWidget {
  final ClassSessionDto session;
  final bool isPastDay;
  final VoidCallback onReserve;
  final VoidCallback onCancel;

  const _ClassLine({
    required this.session,
    required this.isPastDay,
    required this.onReserve,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l = session.startAt.toLocal();
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    final isCancelled = session.isCancelled;
    final isReserved = session.isReserved;
    final isWaitlisted = session.isWaitlisted;
    final isFull = session.isFull;
    final isOver = l.isBefore(DateTime.now());
    final waitlistFull = session.waitlistCount >= session.waitlistCapacity;

    // '8/12' 가 날짜(8월 12일)로 읽혔다 — 앞에 '정원' 을 붙여 인원임을 못 박는다.
    final capText = '정원 ${session.reservedCount}/${session.capacity}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: FacingTokens.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              '$hh:$mm',
              style: FacingTokens.body.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: FacingTokens.tabular,
                color: isCancelled ? FacingTokens.muted : FacingTokens.fg,
              ),
            ),
          ),
          const SizedBox(width: FacingTokens.sp2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: FacingTokens.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCancelled ? FacingTokens.muted : FacingTokens.fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  [
                    capText,
                    if (session.waitlistCount > 0)
                      '대기 ${session.waitlistCount}',
                    if ((session.room ?? '').isNotEmpty) session.room!,
                  ].join(' · '),
                  style: FacingTokens.caption.copyWith(
                    color: isFull ? FacingTokens.warning : FacingTokens.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: FacingTokens.sp2),
          _action(isCancelled, isReserved, isWaitlisted, isFull, isOver,
              waitlistFull),
        ],
      ),
    );
  }

  /// 우측 조작 슬롯 — 전부 **배지 한 규격**.
  /// v2.5 (2026-08-12 사용자 지시): 예약 버튼이 '예약됨' 배지보다 훨씬 커서
  /// 같은 줄 안에서 층이 졌다. FkBadge 는 onTap 을 주면 그대로 조작 컨트롤이
  /// 되고(터치 48 은 안쪽에서 확보), 표시·조작이 시각적으로 같은 크기가 된다.
  Widget _action(bool isCancelled, bool isReserved, bool isWaitlisted,
      bool isFull, bool isOver, bool waitlistFull) {
    if (isCancelled) {
      return const FkBadge('취소됨', color: FacingTokens.muted);
    }
    if (isReserved || isWaitlisted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FkBadge(
            isWaitlisted ? '대기 ${session.myWaitlistPosition}' : '예약됨',
            color: isWaitlisted ? FacingTokens.warning : FacingTokens.success,
          ),
          if (!isOver) ...[
            const SizedBox(width: FacingTokens.sp2),
            FkBadge('취소', color: FacingTokens.muted, onTap: onCancel),
          ],
        ],
      );
    }
    if (isPastDay || isOver) {
      return const FkBadge('종료', color: FacingTokens.muted);
    }
    final blocked = isFull && waitlistFull;
    if (blocked) return const FkBadge('마감', color: FacingTokens.muted);
    return FkBadge(
      isFull ? '대기' : '예약',
      color: isFull ? FacingTokens.warning : FacingTokens.accent,
      onTap: onReserve,
    );
  }
}
