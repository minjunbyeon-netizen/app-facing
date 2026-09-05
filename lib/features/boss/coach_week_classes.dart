import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_clock.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../models/class_session.dart';
import '../../widgets/hkit.dart';
import '../classes/class_line.dart';
import 'boss_api_client.dart';
import 'class_roster_sheet.dart';

/// 코치 주간 예약 현황 — 한 주 7줄, 누르면 그날 수업(인원 + 명단 진입).
///
/// v3.28 (2026-08-25 사용자 결정 "니 말대로 1"): 코치 앱의 '수업' 탭(회원 주간보드
/// 재사용)을 없애고, 예약 현황 탭이 오늘만 보여주던 것을 한 주로 넓혔다.
/// 회원 주간보드는 다시 순수 회원 화면이 됐다 — 정본(SSOT)은 부품(주간 헤더 규격·
/// ClassLine.coach·명단 시트)이지 화면이 아니다 (브리프 D51).
///
/// 데이터는 코치 세션 API(`GET /admin/gyms/<id>/classes?from&to`) — 회원 API 의
/// 기기 폴백에 기대지 않는다.
class CoachWeekClasses extends StatefulWidget {
  // ── 레이아웃 안정성 앵커·자리 (v3.33 · 2026-08-27) ─────────────────────────
  // 상태가 바뀌어도 y 가 움직이면 안 되는 요소들. 회귀 게이트가 이 키로 잰다
  // (test/golden/stability_coach_inbox_test.dart). 이름을 바꾸면 그 테스트도
  // 같이 바꾼다 (글로벌 §0-B 이름 일원화).
  static const Key kWeekHeader = Key('coach-week-header');

  /// 요일 행 — i = 0(월) ~ 6(일). 펼친 내용까지 포함한 줄 전체.
  static Key dayRow(int i) => ValueKey('coach-week-day-$i');

  /// 그 줄의 **누르는 머리**만 — 펼침 자리는 뺀다. 줄 전체를 누르면 펼쳐진
  /// 수업 줄이 대신 눌려 명단 시트가 열린다.
  static Key dayHeader(int i) => ValueKey('coach-week-day-head-$i');

  /// 펼친 날의 내용이 들어오는 **예약된 자리**.
  static const Key kDaySlot = Key('coach-week-day-slot');

  /// 그 자리의 최소 높이. 로딩 스피너·'등록된 수업 없음'·수업 한 줄이 전부 같은
  /// 높이가 되도록 **가장 긴 경우**로 잡았다 — 첫 진입에서 로딩이 명단으로
  /// 바뀌는 순간 아래 요일 행이 밀리던 것을 막는다. 수업이 여럿이면 그만큼
  /// 늘어난다 (명단 길이는 상태가 아니라 내용이다).
  static const double daySlotMinH = 72;

  final int gymId;

  /// 명단에서 출석을 바꾼 채 시트가 닫혔을 때 — 대시보드 카운터 재조회.
  final Future<void> Function()? onChanged;

  const CoachWeekClasses({super.key, required this.gymId, this.onChanged});

  @override
  State<CoachWeekClasses> createState() => _CoachWeekClassesState();
}

class _CoachWeekClassesState extends State<CoachWeekClasses> {
  static const List<String> _wk = ['월', '화', '수', '목', '금', '토', '일'];

  late DateTime _today;
  late DateTime _weekStart;
  late int _selected;
  List<ClassSessionDto> _classes = const [];
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    final now = appClock.now();
    _today = DateTime(now.year, now.month, now.day);
    _weekStart = _today.subtract(Duration(days: _today.weekday - 1));
    _selected = _today.weekday - 1;
    _load();
  }

  /// 한 주 = 한 요청. 이전 결과를 들고 있다가 갈아끼운다 (깜빡임 방지).
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final api = context.read<BossApiClient>();
      final from = _weekStart.toUtc().toIso8601String();
      final to = _weekStart.add(const Duration(days: 7)).toUtc().toIso8601String();
      final raw = await api.getList(
        '/api/v1/admin/gyms/${widget.gymId}/classes?from=$from&to=$to',
      );
      if (!mounted) return;
      setState(() {
        _classes = raw
            .whereType<Map>()
            .map((e) => ClassSessionDto.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _shiftWeek(int weeks) {
    Haptic.light();
    final next = _weekStart.add(Duration(days: 7 * weeks));
    setState(() {
      _weekStart = next;
      final isThisWeek =
          !_today.isBefore(next) &&
          _today.isBefore(next.add(const Duration(days: 7)));
      _selected = isThisWeek ? _today.weekday - 1 : 0;
    });
    _load();
  }

  void _select(int i) {
    Haptic.light();
    setState(() => _selected = _selected == i ? -1 : i);
  }

  Future<void> _openRoster(ClassSessionDto c) async {
    Haptic.light();
    await showClassRosterSheet(
      context,
      c.id,
      onChanged: () {
        _load();
        widget.onChanged?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final byDate = <String, List<ClassSessionDto>>{};
    for (final c in _classes) {
      if (c.isCancelled) continue;
      byDate.putIfAbsent(ymd(c.startAt.gym()), () => []).add(c);
    }
    for (final l in byDate.values) {
      l.sort((a, b) => a.startAt.compareTo(b.startAt));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _weekHeader(),
        const SizedBox(height: HyphenTokens.sp2),
        // D117 — 실패해도 **주간 카드는 그대로 선다**. 종전에는 카드 7행을 배너로
        // 통째 치환해서, 실패하는 순간 요일 행이 사라지고 화면이 다른 물건이 됐다
        // (앵커 자체가 없어져 좌표 검사도 못 걸었다). 이제 실패 문구는 카드 **아래**에
        // 붙는다 — 아래에 다른 요소가 없어 아무것도 밀지 않고, 주를 옮겨 다시
        // 시도하는 길(주간 헤더)도 그대로 남는다.
        HkCard(
          padding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
                for (var i = 0; i < 7; i++)
                  _CoachDayRow(
                    key: CoachWeekClasses.dayRow(i),
                    index: i,
                    date: _weekStart.add(Duration(days: i)),
                    weekdayLabel: _wk[i],
                    isToday: _weekStart.add(Duration(days: i)) == _today,
                    isPast: _weekStart.add(Duration(days: i)).isBefore(_today),
                    isSelected: _selected == i,
                    isLast: i == 6,
                    loading: _loading && _classes.isEmpty,
                    classes:
                        byDate[ymd(_weekStart.add(Duration(days: i)))] ??
                        const [],
                    onTap: () => _select(i),
                    onOpenRoster: _openRoster,
                  ),
            ],
          ),
        ),
        if (_error) ...[
          const SizedBox(height: HyphenTokens.sp2),
          HkInlineError('수업 불러오기 실패.', onRetry: _load),
        ],
      ],
    );
  }

  /// 회원 주간보드와 같은 주간 헤더 규격 (◀ 8.24 – 8.30 [이번 주] ▶).
  Widget _weekHeader() {
    final end = _weekStart.add(const Duration(days: 6));
    final isThisWeek =
        !_today.isBefore(_weekStart) &&
        _today.isBefore(_weekStart.add(const Duration(days: 7)));
    String md(DateTime d) => '${d.month}.${d.day}';
    return Row(
      key: CoachWeekClasses.kWeekHeader,
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

/// 하루 = 접힌 줄 하나 ("월 24 · 수업 3 · 예약 21명"). 펼치면 그날 수업 줄.
class _CoachDayRow extends StatelessWidget {
  /// 0(월) ~ 6(일) — 머리 키를 붙이는 데만 쓴다.
  final int index;
  final DateTime date;
  final String weekdayLabel;
  final bool isToday;
  final bool isPast;
  final bool isSelected;
  final bool isLast;
  final bool loading;
  final List<ClassSessionDto> classes;
  final VoidCallback onTap;
  final Future<void> Function(ClassSessionDto) onOpenRoster;

  const _CoachDayRow({
    super.key,
    required this.index,
    required this.date,
    required this.weekdayLabel,
    required this.isToday,
    required this.isPast,
    required this.isSelected,
    required this.isLast,
    required this.loading,
    required this.classes,
    required this.onTap,
    required this.onOpenRoster,
  });

  String get _summary {
    if (classes.isEmpty) return loading ? '' : '수업 없음';
    final reserved = classes.fold<int>(0, (a, c) => a + c.reservedCount);
    return '수업 ${classes.length} · 예약 $reserved명';
  }

  @override
  Widget build(BuildContext context) {
    final dayColor = isToday
        ? HyphenTokens.primary
        : (isPast ? HyphenTokens.muted : HyphenTokens.fg);
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
            key: CoachWeekClasses.dayHeader(index),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HyphenTokens.sp3,
                vertical: HyphenTokens.sp2,
              ),
              child: Row(
                children: [
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
          // 펼침 자리 — **미리 잡아 둔 자리**(공간 예약 / space reservation).
          // 전엔 로딩 스피너와 명단·'수업 없음' 의 높이가 달라, 첫 응답이 도착하는
          // 순간 아래 요일 행이 최대 6줄까지 통째로 밀렸다. 기본 선택이 '오늘'
          // 이라 코치가 화면에 들어갈 때마다 겪던 밀림이다.
          // 이제 로딩·수업 한 줄·빈 명단이 같은 높이다 (DESIGN-SSOT §레이아웃 안정성).
          // 수업이 여럿이면 그만큼 늘어난다 — 명단 길이는 상태가 아니라 내용이다.
          if (isSelected)
            HkReservedSlot(
              key: CoachWeekClasses.kDaySlot,
              minHeight: CoachWeekClasses.daySlotMinH,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  HyphenTokens.sp3,
                  0,
                  HyphenTokens.sp3,
                  HyphenTokens.sp2,
                ),
                child: loading
                    ? const HkLoading()
                    : classes.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: HyphenTokens.sp1),
                        child: Text(
                          '등록된 수업 없음.',
                          style: HyphenTokens.caption,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final c in classes)
                            ClassLine.coach(
                              timeLabel: hhmm(c.startAt.gym()),
                              title: c.title,
                              subtitle: [
                                if ((c.room ?? '').isNotEmpty) c.room!,
                                if (c.waitlistCount > 0)
                                  '대기 ${c.waitlistCount}',
                              ].join(' · '),
                              reserved: c.reservedCount,
                              capacity: c.capacity,
                              onTap: () => onOpenRoster(c),
                            ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
