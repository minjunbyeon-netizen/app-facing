import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/futures.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/hkit.dart';
import 'boss_api_client.dart';
import 'class_roster_model.dart';

/// D29 (2026-08-12) — 수업 카드 탭 시 뜨는 예약자 명단 시트.
///
/// 3면 점검(2026-08-12)에서 "누가 예약했나" 를 볼 수단이 앱·웹·백엔드 어디에도
/// 없다는 것이 유일한 진짜 미구현으로 나왔다. 코치의 핵심 화면이라 대시보드의
/// 오늘 수업 카드에서 한 번 탭으로 열리게 붙인다.
///
/// D31 (2026-08-12) — 보기 전용에서 조작 가능으로. 각 예약자 우측 [출석][노쇼]
/// 배지를 한 번 누르면 PATCH 가 나가고, 같은 것을 다시 누르면 확정으로 되돌린다.
/// 수업 끝나고 코치가 서서 12명을 훑는 동선이라 확인 다이얼로그는 두지 않았다
/// (되돌리기가 같은 자리 한 번 더 누르기라 실수 비용이 낮다).
///
/// G24 (2026-08-18) — 시트 하단에 '수업 취소' 추가. 확인 다이얼로그 →
/// POST /api/v1/admin/classes/{id}/cancel (확정 예약 일괄 취소 + 알림) →
/// 시트 닫힘. dirty 로 처리해 아래 [onChanged] 경로로 대시보드가 재조회된다.
///
/// G24 2차 (2026-08-19) — '수업 수정' 추가. 수정 시트(class_compose_sheet
/// edit 모드)에서 저장하면 명단을 재조회해 헤더·정원이 새 값으로 바뀐다.
///
/// [onChanged] — 출석 상태를 하나라도 바꾼 채로 시트가 닫히면 1회 호출된다.
/// 대시보드의 '오늘 출석' 숫자가 바뀌므로 호출부에서 다시 불러오라는 신호다.
/// (시트 pop 반환값을 안 쓰는 이유: 스와이프로 내리면 null 이라 신호가 샌다.)
Future<void> showClassRosterSheet(BuildContext context, int classId,
    {VoidCallback? onChanged}) async {
  var dirty = false;
  await HkSheet.show<void>(
    context,
    builder: (_) => _ClassRosterSheet(
      classId: classId,
      onDirty: () => dirty = true,
    ),
  );
  if (dirty) onChanged?.call();
}

class _ClassRosterSheet extends StatefulWidget {
  final int classId;
  final VoidCallback onDirty;
  const _ClassRosterSheet({required this.classId, required this.onDirty});

  @override
  State<_ClassRosterSheet> createState() => _ClassRosterSheetState();
}

class _ClassRosterSheetState extends State<_ClassRosterSheet> {
  late Future<ClassRoster> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final api = context.read<BossApiClient>();
    // retainError: Future 를 필드에 보관하는 구조라 리스너 선부착 필수 (core/futures.dart).
    _future = retainError(
      api
          .get('/api/v1/admin/classes/${widget.classId}/reservations')
          .then(ClassRoster.fromJson),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: FutureBuilder<ClassRoster>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(HyphenTokens.sp6),
                child: HkLoading(),
              );
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(HyphenTokens.sp5),
                child: HkErrorState.fromError(
                  snap.error,
                  onRetry: () => setState(_load),
                ),
              );
            }
            // ObjectKey — 수정 후 재조회하면 새 roster 로 State 를 다시 만들어
            // _items 작업 사본까지 새 값으로 간다 (key 없으면 State 가 남는다).
            return _Loaded(
              key: ObjectKey(snap.data),
              roster: snap.data!,
              onDirty: widget.onDirty,
              onReload: () => setState(_load),
            );
          },
        ),
      ),
    );
  }
}

class _Loaded extends StatefulWidget {
  final ClassRoster roster;
  final VoidCallback onDirty;

  /// 명단 재조회 신호.
  final VoidCallback onReload;

  const _Loaded(
      {super.key,
      required this.roster,
      required this.onDirty,
      required this.onReload});

  @override
  State<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends State<_Loaded> {
  /// 서버에서 받은 명단의 작업용 사본 — 출석을 찍으면 이 리스트만 갱신한다
  /// (전체 재조회 없이 즉시 반영. 실패하면 원래 상태로 되돌린다).
  late final List<RosterEntry> _items = List.of(widget.roster.items);

  /// PATCH 진행 중인 예약 id — 같은 행 연타를 막는다.
  final Set<int> _busy = {};

  // v3.21 (2026-08-25 사용자 지시): 수업 수정·수업 취소 삭제 — 수업을 만들고
  // 고치고 없애는 건 PC 몫이다. 폰 명단에 남는 동작은 출석·노쇼 체크뿐
  // (README §제거된 기능 대장 17).

  Future<void> _mark(RosterEntry e, String next) async {
    final id = e.reservationId;
    if (id == null || _busy.contains(id)) return;
    final idx = _items.indexOf(e);
    if (idx < 0) return;

    Haptic.light();
    final prev = e.status;
    setState(() {
      _busy.add(id);
      _items[idx] = e.withStatus(next); // 낙관적 반영 — 손끝 반응이 먼저다
    });

    try {
      await context
          .read<BossApiClient>()
          .patch('/api/v1/admin/reservations/$id/status', {'status': next});
      widget.onDirty();
    } catch (err) {
      if (!mounted) return;
      setState(() => _items[idx] = e.withStatus(prev)); // 롤백
      HkSnack.error(context, '출석 저장 실패');
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final roster = widget.roster;
    final reservations = _items.where((e) => !e.isWaitlist).toList();
    final waitlist = _items.where((e) => e.isWaitlist).toList();
    final cap = roster.capacity;
    // 예약 인원은 서버 값 그대로 (출석 표시는 상태만 바꿔 인원수가 안 변한다).
    // 출석 수는 방금 찍은 것까지 즉시 반영돼야 하므로 사본에서 다시 센다.
    final attended = reservations.where((e) => e.status == 'attended').length;

    return ListView(
      padding: const EdgeInsets.all(HyphenTokens.sp4),
      shrinkWrap: true,
      children: [
        Text(roster.title,
            style: HyphenTokens.h3.copyWith(color: HyphenTokens.fg)),
        const SizedBox(height: 4),
        Text(
          [
            _hhmm(roster.startAt),
            if (roster.room != null && roster.room!.isNotEmpty) roster.room!,
            if (roster.coachUserId != null && roster.coachUserId!.isNotEmpty)
              roster.coachUserId!,
          ].join('  ·  '),
          style: HyphenTokens.caption,
        ),
        const SizedBox(height: HyphenTokens.sp4),

        Row(
          children: [
            Expanded(
              child: HkStatTile(
                label: '예약',
                value: cap != null
                    ? '${roster.confirmedCount} / $cap'
                    : '${roster.confirmedCount}',
              ),
            ),
            const SizedBox(width: HyphenTokens.sp2),
            Expanded(
              child: HkStatTile(label: '출석', value: '$attended'),
            ),
            const SizedBox(width: HyphenTokens.sp2),
            Expanded(
              child: HkStatTile(
                label: '대기',
                value: '${roster.waitlistCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: HyphenTokens.sp5),

        const HkSectionLabel('예약자'),
        const SizedBox(height: HyphenTokens.sp2),
        if (reservations.isEmpty)
          const HkEmptyState(title: '예약자 없음')
        else
          ...reservations.map((e) => _EntryRow(entry: e, onMark: _mark)),

        if (waitlist.isNotEmpty) ...[
          const SizedBox(height: HyphenTokens.sp5),
          const HkSectionLabel('대기자'),
          const SizedBox(height: HyphenTokens.sp2),
          ...waitlist.map((e) => _EntryRow(entry: e, onMark: _mark)),
        ],

        const SizedBox(height: HyphenTokens.sp4),
      ],
    );
  }

  /// '2026-08-12T19:00:00' → '19:00'. 파싱 실패 시 원문 유지.
  static String _hhmm(String iso) {
    final t = DateTime.tryParse(iso);
    if (t == null) return iso;
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }
}

class _EntryRow extends StatelessWidget {
  final RosterEntry entry;

  /// (행, 새 상태) — 출석 체크. 대기자·고아 행에는 배지가 붙지 않는다.
  final void Function(RosterEntry, String) onMark;
  const _EntryRow({required this.entry, required this.onMark});

  @override
  Widget build(BuildContext context) {
    // 찍을 수 없는 행(대기자·탈퇴 회원)은 종전대로 상태 글자만 보여준다.
    if (!entry.markable) {
      return HkListRow(
        title: entry.name,
        subtitle: entry.phone,
        trailing: _statusLabel(entry),
        trailingColor: _statusColor(entry),
      );
    }
    // 같은 배지를 다시 누르면 확정으로 되돌린다 — 잘못 찍었을 때의 유일한 탈출구.
    final isAttended = entry.status == 'attended';
    final isNoShow = entry.status == 'no_show';
    return HkListRow(
      title: entry.name,
      subtitle: entry.phone,
      trailingWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HkBadge(
            '출석',
            color: HyphenTokens.success,
            selected: isAttended,
            onTap: () => onMark(entry, isAttended ? 'confirmed' : 'attended'),
          ),
          const SizedBox(width: HyphenTokens.sp2),
          HkBadge(
            '노쇼',
            color: HyphenTokens.danger,
            selected: isNoShow,
            onTap: () => onMark(entry, isNoShow ? 'confirmed' : 'no_show'),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(RosterEntry e) {
    if (e.isWaitlist) return e.position != null ? '대기 ${e.position}' : '대기';
    return switch (e.status) {
      'attended' => '출석',
      'no_show' => '노쇼',
      _ => e.promotedFromWaitlist ? '승격' : '확정',
    };
  }

  static Color _statusColor(RosterEntry e) {
    if (e.orphan) return HyphenTokens.mutedStrong;
    if (e.isWaitlist) return HyphenTokens.warning;
    return switch (e.status) {
      'attended' => HyphenTokens.success,
      'no_show' => HyphenTokens.danger,
      _ => HyphenTokens.muted,
    };
  }
}
