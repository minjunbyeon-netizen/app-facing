import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/futures.dart';
import '../../core/theme.dart';
import '../../widgets/fkit.dart';
import 'boss_api_client.dart';
import 'class_roster_model.dart';

/// D29 (2026-08-12) — 수업 카드 탭 시 뜨는 예약자 명단 시트.
///
/// 3면 점검(2026-08-12)에서 "누가 예약했나" 를 볼 수단이 앱·웹·백엔드 어디에도
/// 없다는 것이 유일한 진짜 미구현으로 나왔다. 코치의 핵심 화면이라 대시보드의
/// 오늘 수업 카드에서 한 번 탭으로 열리게 붙인다.
Future<void> showClassRosterSheet(BuildContext context, int classId) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: FacingTokens.bg,
    isScrollControlled: true,
    builder: (_) => _ClassRosterSheet(classId: classId),
  );
}

class _ClassRosterSheet extends StatefulWidget {
  final int classId;
  const _ClassRosterSheet({required this.classId});

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
                padding: EdgeInsets.all(FacingTokens.sp6),
                child: FkLoading(),
              );
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(FacingTokens.sp5),
                child: FkErrorState.fromError(
                  snap.error,
                  onRetry: () => setState(_load),
                ),
              );
            }
            return _Loaded(roster: snap.data!);
          },
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  final ClassRoster roster;
  const _Loaded({required this.roster});

  @override
  Widget build(BuildContext context) {
    final reservations = roster.reservations;
    final waitlist = roster.waitlist;
    final cap = roster.capacity;

    return ListView(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      shrinkWrap: true,
      children: [
        Text(roster.title,
            style: FacingTokens.h3.copyWith(color: FacingTokens.fg)),
        const SizedBox(height: 4),
        Text(
          [
            _hhmm(roster.startAt),
            if (roster.room != null && roster.room!.isNotEmpty) roster.room!,
            if (roster.coachUserId != null && roster.coachUserId!.isNotEmpty)
              roster.coachUserId!,
          ].join('  ·  '),
          style: FacingTokens.caption,
        ),
        const SizedBox(height: FacingTokens.sp4),

        Row(
          children: [
            Expanded(
              child: FkStatTile(
                label: '예약',
                value: cap != null
                    ? '${roster.confirmedCount} / $cap'
                    : '${roster.confirmedCount}',
              ),
            ),
            const SizedBox(width: FacingTokens.sp2),
            Expanded(
              child: FkStatTile(
                label: '대기',
                value: '${roster.waitlistCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp5),

        const FkSectionLabel('예약자'),
        const SizedBox(height: FacingTokens.sp2),
        if (reservations.isEmpty)
          const FkEmptyState(title: '예약자 없음')
        else
          ...reservations.map((e) => _EntryRow(entry: e)),

        if (waitlist.isNotEmpty) ...[
          const SizedBox(height: FacingTokens.sp5),
          const FkSectionLabel('대기자'),
          const SizedBox(height: FacingTokens.sp2),
          ...waitlist.map((e) => _EntryRow(entry: e)),
        ],
        const SizedBox(height: FacingTokens.sp4),
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
  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return FkListRow(
      title: entry.name,
      subtitle: entry.phone,
      trailing: _statusLabel(entry),
      trailingColor: _statusColor(entry),
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
    if (e.orphan) return FacingTokens.mutedStrong;
    if (e.isWaitlist) return FacingTokens.warning;
    return switch (e.status) {
      'attended' => FacingTokens.success,
      'no_show' => FacingTokens.danger,
      _ => FacingTokens.muted,
    };
  }
}
