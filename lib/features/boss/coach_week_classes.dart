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
      final from = _weekStart.toIso8601String();
      final to = _weekStart.add(const Duration(days: 7)).toIso8601String();
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
      byDate.putIfAbsent(ymd(c.startAt.toLocal()), () => []).add(c);
    }
    for (final l in byDate.values) {
      l.sort((a, b) => a.startAt.compareTo(b.startAt));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _weekHeader(),
        const SizedBox(height: HyphenTokens.sp2),
        if (_error)
          HkInlineError('수업 불러오기 실패.', onRetry: _load)
        else
          HkCard(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < 7; i++)
                  _CoachDayRow(
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
          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HyphenTokens.sp3,
                0,
                HyphenTokens.sp3,
                HyphenTokens.sp2,
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: HyphenTokens.sp3),
                      child: HkLoading(),
                    )
                  : classes.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: HyphenTokens.sp1),
                      child: Text('등록된 수업 없음.', style: HyphenTokens.caption),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final c in classes)
                          ClassLine.coach(
                            timeLabel: hhmm(c.startAt.toLocal()),
                            title: c.title,
                            subtitle: [
                              if ((c.room ?? '').isNotEmpty) c.room!,
                              if (c.waitlistCount > 0) '대기 ${c.waitlistCount}',
                            ].join(' · '),
                            reserved: c.reservedCount,
                            capacity: c.capacity,
                            onTap: () => onOpenRoster(c),
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
