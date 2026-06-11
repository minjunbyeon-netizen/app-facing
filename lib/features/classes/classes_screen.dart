import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/class_session.dart';
import '../gym/gym_state.dart';
import 'classes_repository.dart';

/// PHASE4 §1.1 — 회원 폰 클래스 일정·예약 화면.
/// PC 사장이 /admin/classes 에서 등록한 클래스를 회원이 그대로 봄.
/// v1.26 (2026-06-11): 본문을 ClassesSection 으로 분리 — Attend 탭 상단
/// "수업 허브" 임베드와 이 단독 화면(Profile 진입)이 같은 위젯을 쓴다.
class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  int _tick = 0;

  void _reload() => setState(() => _tick++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CLASSES'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: FacingTokens.accent,
          onRefresh: () async => _reload(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(FacingTokens.sp4),
            children: [
              ClassesSection(
                key: ValueKey('cls-$_tick'),
                showHeader: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 임베드 가능한 클래스 예약 섹션 — 스크롤 부모(ListView) 안에서 동작.
/// showHeader=true 면 'CLASSES' 섹션 라벨을 직접 그린다 (Attend 임베드용).
class ClassesSection extends StatefulWidget {
  final bool showHeader;
  const ClassesSection({super.key, this.showHeader = true});

  @override
  State<ClassesSection> createState() => _ClassesSectionState();
}

class _ClassesSectionState extends State<ClassesSection> {
  Future<List<ClassSessionDto>>? _future;
  late final ClassesRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = ClassesRepository(context.read<ApiClient>());
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _repo.listClasses();
    });
  }

  Future<void> _reserve(ClassSessionDto c) async {
    Haptic.medium();
    try {
      final result = await _repo.reserve(c.id);
      if (!mounted) return;
      final status = (result['status'] ?? '').toString();
      final msg = status == 'waitlisted'
          ? '대기열 ${result['position']}번 등록.'
          : '예약 완료.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ));
      _reload();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.messageKo),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  Future<void> _cancel(ClassSessionDto c) async {
    final res = c.myReservation;
    if (res == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r4),
        ),
        title: const Text('Cancel reservation?'),
        content: Text(
          '${c.title} · ${_fmtDateTime(c.startAt)}',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    Haptic.medium();
    try {
      await _repo.cancel(res.reservationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('예약 취소.'),
        duration: Duration(seconds: 2),
      ));
      _reload();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.messageKo),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  Widget _header() => const Padding(
        padding: EdgeInsets.only(bottom: FacingTokens.sp2),
        child: Text('CLASSES', style: FacingTokens.sectionLabel),
      );

  Widget _inline(String text, {Widget? action}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: FacingTokens.caption),
            if (action != null) ...[
              const SizedBox(height: FacingTokens.sp2),
              action,
            ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final hasMembership = gs.membership.isApprovedMember || gs.isOwner;

    if (!hasMembership) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) _header(),
          _inline('박스 가입 후 클래스 예약 가능.'),
        ],
      );
    }
    return FutureBuilder<List<ClassSessionDto>>(
      future: _future,
      builder: (ctx, snap) {
        Widget body;
        if (snap.connectionState != ConnectionState.done) {
          body = const Padding(
            padding: EdgeInsets.symmetric(vertical: FacingTokens.sp4),
            child: Center(
              child: CircularProgressIndicator(
                  color: FacingTokens.muted, strokeWidth: 2),
            ),
          );
        } else if (snap.hasError) {
          final err = snap.error;
          final msg = err is AppException ? err.messageKo : 'Load failed.';
          body = _inline(
            msg,
            action: TextButton(
              onPressed: _reload,
              style: TextButton.styleFrom(
                foregroundColor: FacingTokens.muted,
                minimumSize: const Size(0, 36),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Retry'),
            ),
          );
        } else {
          // v1.26: 내 예약이 없는 취소 클래스는 노이즈 — 리스트에서 제외.
          // (예약자에게는 CANCELLED 상태 고지가 필요하므로 유지.)
          final classes = (snap.data ?? const <ClassSessionDto>[])
              .where((c) => !c.isCancelled || c.myReservation != null)
              .toList();
          if (classes.isEmpty) {
            body = _inline('등록된 클래스 없음. 사장 등록 시 표시.');
          } else {
            // 날짜별 그룹.
            final groups = <String, List<ClassSessionDto>>{};
            for (final c in classes) {
              final key = _fmtDateKey(c.startAt);
              groups.putIfAbsent(key, () => []).add(c);
            }
            body = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: FacingTokens.sp3,
                      bottom: FacingTokens.sp2,
                    ),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: FacingTokens.sectionLabel,
                    ),
                  ),
                  for (final c in entry.value)
                    _ClassCard(
                      session: c,
                      onReserve: () => _reserve(c),
                      onCancel: () => _cancel(c),
                    ),
                ],
              ],
            );
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHeader) _header(),
            body,
          ],
        );
      },
    );
  }

  String _fmtDateKey(DateTime dt) {
    final local = dt.toLocal();
    const dows = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final dow = dows[local.weekday - 1];
    return '${local.month}/${local.day} $dow';
  }

  String _fmtDateTime(DateTime dt) {
    final l = dt.toLocal();
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    return '${l.month}/${l.day} $hh:$mm';
  }
}

class _ClassCard extends StatelessWidget {
  final ClassSessionDto session;
  final VoidCallback onReserve;
  final VoidCallback onCancel;
  const _ClassCard({
    required this.session,
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

    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp3),
      padding: const EdgeInsets.all(FacingTokens.sp4),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border.all(
          color: isReserved
              ? FacingTokens.success
              : isWaitlisted
                  ? FacingTokens.warning
                  : FacingTokens.border,
          width: (isReserved || isWaitlisted) ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(FacingTokens.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('$hh:$mm', style: FacingTokens.h3),
                  const SizedBox(height: 2),
                  Text('${session.durationMinutes}min',
                      style: FacingTokens.micro),
                ],
              ),
              const SizedBox(width: FacingTokens.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title,
                        style: FacingTokens.body
                            .copyWith(fontWeight: FontWeight.w800)),
                    if ((session.room ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(session.room!, style: FacingTokens.caption),
                    ],
                    if ((session.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: FacingTokens.sp1),
                      Text(session.description!,
                          style: FacingTokens.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${session.reservedCount}/${session.capacity}',
                    style: FacingTokens.body.copyWith(
                      fontFeatures: FacingTokens.tabular,
                      fontWeight: FontWeight.w700,
                      color: isFull ? FacingTokens.warning : FacingTokens.fg,
                    ),
                  ),
                  if (session.waitlistCount > 0)
                    Text('WL ${session.waitlistCount}',
                        style: FacingTokens.micro),
                ],
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp3),
          Row(
            children: [
              if (isCancelled)
                _Pill(label: 'CANCELLED', color: FacingTokens.muted)
              else if (isReserved)
                _Pill(label: 'RESERVED', color: FacingTokens.success)
              else if (isWaitlisted)
                _Pill(
                    label: 'WAITLIST #${session.myWaitlistPosition}',
                    color: FacingTokens.warning),
              const Spacer(),
              if (!isCancelled) ...[
                // 전역 버튼 테마의 minimumSize(double.infinity) 는 Row 안에서
                // 무한 폭 layout 예외 → 화면 전체 백지. 카드 내 버튼은 고유 폭.
                if (isReserved || isWaitlisted)
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(96, 44),
                      foregroundColor: FacingTokens.accent,
                      side:
                          BorderSide(color: FacingTokens.accent.withAlpha(120)),
                    ),
                    child: const Text('Cancel'),
                  )
                else
                  ElevatedButton(
                    onPressed: isFull && session.waitlistCount >=
                            session.waitlistCapacity
                        ? null
                        : onReserve,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(96, 44),
                      backgroundColor: FacingTokens.accent,
                      foregroundColor: FacingTokens.onColor,
                    ),
                    child: Text(isFull ? 'Join Waitlist' : 'Reserve'),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        border: Border.all(color: color.withAlpha(120)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: FacingTokens.micro.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

