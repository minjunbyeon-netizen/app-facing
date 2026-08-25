import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/mascot.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/class_session.dart';
import '../../widgets/hkit.dart';
import '../gym/gym_state.dart';
import 'classes_repository.dart';

/// 예약 실행 — 성공/대기 등록 시 스낵바 + true, 실패 시 에러 스낵바 + false.
/// v2.4 (2026-08-12): 주간 보드(week_board.dart)도 같은 흐름을 쓰므로 화면 밖으로
/// 꺼냈다 — 예약 로직이 두 벌이 되면 정책이 갈라진다 (§3 코드 SSOT).
Future<bool> reserveClassFlow(
  BuildContext context,
  ClassesRepository repo,
  ClassSessionDto c,
) async {
  Haptic.medium();
  final messenger = HkSnack.of(context);
  try {
    final result = await repo.reserve(c.id);
    final status = (result['status'] ?? '').toString();
    messenger.info(status == 'waitlisted' ? '대기열 ${result['position']}번 등록.' : '예약 완료.', mood: MascotMood.happy);
    return true;
  } on AppException catch (e) {
    messenger.fail(e.messageKo);
    return false;
  }
}

/// 예약 취소 — 확인 다이얼로그 → 취소. 취소가 성사되면 true.
Future<bool> cancelClassFlow(
  BuildContext context,
  ClassesRepository repo,
  ClassSessionDto c,
) async {
  // G30 픽스 (2026-08-24): 대기자는 예약 행이 없어 종전엔 여기서 조용히
  // return — 대기 '취소' 버튼이 무동작이었다. 대기는 전용 DELETE 로 이탈.
  final isWaitlistCancel = c.isWaitlisted;
  final res = c.myReservation;
  if (!isWaitlistCancel && (res == null || !c.isReserved)) return false;
  final l = c.startAt.toLocal();
  final when = '${l.month}/${l.day} '
      '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  final ok = await HkDialog.confirm(
    context,
    title: isWaitlistCancel ? '대기를 취소할까요?' : '예약을 취소할까요?',
    message: '${c.title} · $when',
    cancelLabel: '유지',
    confirmLabel: '취소',
  );
  if (!ok || !context.mounted) return false;
  Haptic.medium();
  final messenger = HkSnack.of(context);
  try {
    if (isWaitlistCancel) {
      await repo.cancelWaitlist(c.id);
      messenger.info('대기 취소.', mood: MascotMood.happy);
    } else {
      await repo.cancel(res!.reservationId);
      messenger.info('예약 취소.', mood: MascotMood.happy);
    }
    return true;
  } on AppException catch (e) {
    messenger.fail(e.messageKo);
    return false;
  }
}

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
      // v3.24: 새로고침 아이콘 삭제 — 아래 RefreshIndicator(당겨서 새로고침)가 있다.
      appBar: const HkAppBar(title: '수업'),
      body: SafeArea(
        child: RefreshIndicator(
          color: HyphenTokens.accent,
          onRefresh: () async => _reload(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(HyphenTokens.sp4),
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
    final ok = await reserveClassFlow(context, _repo, c);
    if (ok && mounted) _reload();
  }

  Future<void> _cancel(ClassSessionDto c) async {
    final ok = await cancelClassFlow(context, _repo, c);
    if (ok && mounted) _reload();
  }

  Widget _header() => const Padding(
        padding: EdgeInsets.only(bottom: HyphenTokens.sp2),
        child: Text('수업', style: HyphenTokens.sectionLabel),
      );

  Widget _inline(String text, {Widget? action}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: HyphenTokens.caption),
            if (action != null) ...[
              const SizedBox(height: HyphenTokens.sp2),
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
          _inline('가입 승인 후 수업 예약 가능.'),
        ],
      );
    }
    return FutureBuilder<List<ClassSessionDto>>(
      future: _future,
      builder: (ctx, snap) {
        Widget body;
        if (snap.connectionState != ConnectionState.done) {
          body = const Padding(
            padding: EdgeInsets.symmetric(vertical: HyphenTokens.sp4),
            child: Center(
              child: CircularProgressIndicator(
                  color: HyphenTokens.muted, strokeWidth: 2),
            ),
          );
        } else if (snap.hasError) {
          final err = snap.error;
          final msg = err is AppException ? err.messageKo : 'Load failed.';
          body = _inline(
            msg,
            action: HkButton.tertiary('다시 시도',
                neutral: true, onPressed: _reload),
          );
        } else {
          // v1.26: 내 예약이 없는 취소 클래스는 노이즈 — 리스트에서 제외.
          // (예약자에게는 CANCELLED 상태 고지가 필요하므로 유지.)
          final classes = (snap.data ?? const <ClassSessionDto>[])
              .where((c) => !c.isCancelled || c.myReservation != null)
              .toList();
          if (classes.isEmpty) {
            body = _inline('등록된 수업 없음. 코치 게시 시 표시.');
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
                      top: HyphenTokens.sp3,
                      bottom: HyphenTokens.sp2,
                    ),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: HyphenTokens.sectionLabel,
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
    final isEnded = session.isEnded;
    final isReserved = session.isReserved;
    final isWaitlisted = session.isWaitlisted;
    final isFull = session.isFull;

    return Container(
      // v2.3 (2026-08-12 사용자 지시): 카드가 헐거워 한 화면에 두 개도 안 들어왔다.
      margin: const EdgeInsets.only(bottom: HyphenTokens.sp2),
      padding: const EdgeInsets.all(HyphenTokens.sp3),
      decoration: BoxDecoration(
        color: HyphenTokens.surface,
        border: Border.all(
          color: isReserved
              ? HyphenTokens.success
              : isWaitlisted
                  ? HyphenTokens.warning
                  : HyphenTokens.border,
          width: (isReserved || isWaitlisted) ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(HyphenTokens.r3),
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
                  Text('$hh:$mm', style: HyphenTokens.h3),
                  const SizedBox(height: 2),
                  Text('${session.durationMinutes}분',
                      style: HyphenTokens.micro),
                ],
              ),
              const SizedBox(width: HyphenTokens.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title,
                        style: HyphenTokens.body
                            .copyWith(fontWeight: FontWeight.w800)),
                    if ((session.room ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(session.room!, style: HyphenTokens.caption),
                    ],
                    if ((session.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: HyphenTokens.sp1),
                      Text(session.description!,
                          style: HyphenTokens.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // v2.3: '8/12' 가 날짜(8월 12일)로 읽혔다. 단위를 붙여
                  // 인원임을 드러낸다 (사용자 지시 2026-08-12).
                  Text(
                    '${session.reservedCount}명 / ${session.capacity}명',
                    style: HyphenTokens.body.copyWith(
                      fontFeatures: HyphenTokens.tabular,
                      fontWeight: FontWeight.w700,
                      color: isFull ? HyphenTokens.warning : HyphenTokens.fg,
                    ),
                  ),
                  if (session.waitlistCount > 0)
                    Text('대기 ${session.waitlistCount}',
                        style: HyphenTokens.micro),
                ],
              ),
            ],
          ),
          const SizedBox(height: HyphenTokens.sp2),
          Row(
            children: [
              // G25 — 수업 트랙 배지 (초보/RX 구분). track 원문 그대로 (도메인
              // 고정어). null·빈 문자열이면 배지 자체를 그리지 않는다 — 골든 불변.
              // 서버 color hex 는 칠하지 않는다 (디자인 토큰 정책) — HkBadge 기본색.
              if ((session.track ?? '').isNotEmpty) ...[
                HkBadge(session.track!),
                const SizedBox(width: HyphenTokens.sp1),
              ],
              if (isCancelled)
                const HkBadge('취소됨', color: HyphenTokens.muted)
              else if (isEnded)
                // 2026-08-24 — 종료 수업은 예약·취소 불가 (서버 CLASS_ENDED 게이트).
                // 버튼을 숨기는 이유를 배지로 남긴다.
                const HkBadge('종료', color: HyphenTokens.muted)
              else if (isReserved)
                const HkBadge('예약됨', color: HyphenTokens.success)
              else if (isWaitlisted)
                HkBadge('대기 #${session.myWaitlistPosition}',
                    color: HyphenTokens.warning),
              const Spacer(),
              if (!isCancelled && !isEnded) ...[
                // 전역 버튼 테마의 minimumSize(double.infinity) 는 Row 안에서
                // 무한 폭 layout 예외 → 화면 전체 백지. 카드 내 버튼은 고유 폭.
                if (isReserved || isWaitlisted)
                  HkButton.secondary('취소', expand: false, onPressed: onCancel)
                else
                  HkButton.primary(
                    isFull ? '대기 신청' : '예약',
                    expand: false,
                    onPressed: isFull &&
                            session.waitlistCount >= session.waitlistCapacity
                        ? null
                        : onReserve,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

