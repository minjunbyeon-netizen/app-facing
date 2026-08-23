// Coach Dashboard — 승인 관리 + 멤버 로스터 + 활동 통계.
// (부상 메모 가짜 데이터는 삭제됐다 — 지금은 '준비 중' 안내만 띄운다.)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/mascot.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../../widgets/coach_badge.dart';
import '../../widgets/hkit.dart';
import '../inbox/inbox_screen.dart';
import 'gym_profile_edit_screen.dart';
import 'gym_repository.dart';
import 'gym_state.dart';
import 'member_requests_screen.dart';
import 'wod_type_label.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  Future<List<GymMember>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null) {
      setState(() => _future = Future.value(const []));
      return;
    }
    setState(() {
      _future = context.read<GymRepository>().listMembers(gym.id);
    });
  }

  Future<void> _decide(GymMember m, String action) async {
    Haptic.medium();
    final ok = await context.read<GymState>().decideMember(
          memberId: m.id,
          action: action,
        );
    if (!mounted) return;
    if (ok) {
      _reload();
    } else {
      HkSnack.error(context, context.read<GymState>().error ?? '처리 실패');
    }
  }

  void _openMemberSheet(GymMember m) {
    Haptic.light();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: HyphenTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(HyphenTokens.r4)),
      ),
      builder: (ctx) => _MemberDetailSheet(member: m),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    return Scaffold(
      appBar: AppBar(
        title: const Text('코치 대시보드'),
        actions: [
          const CoachBadgeAction(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: SafeArea(
        child: gym == null
            ? const Center(
                child: Text('체육관 정보 없음.', style: HyphenTokens.caption))
            : FutureBuilder<List<GymMember>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: HyphenTokens.muted, strokeWidth: 2),
                    );
                  }
                  if (snap.hasError) {
                    final e = snap.error;
                    final msg =
                        e is AppException ? e.messageKo : '로딩 실패';
                    return Padding(
                      padding: const EdgeInsets.all(HyphenTokens.sp4),
                      child: Text(msg, style: HyphenTokens.body),
                    );
                  }
                  final members = snap.data ?? const [];
                  final pending = members.where((m) => m.isPending).toList();
                  final approved =
                      members.where((m) => m.isApproved).toList();
                  final rejected =
                      members.where((m) => m.isRejected).toList();
                  final activeCount = approved
                      .where((m) => m.lastWodAt != null && !m.isDormant)
                      .length;
                  final dormantCount =
                      approved.where((m) => m.isDormant).length;
                  final totalSessions = approved
                      .map((m) => m.totalSessions)
                      .fold<int>(0, (a, b) => a + b);

                  return ListView(
                    padding: const EdgeInsets.all(HyphenTokens.sp4),
                    children: [
                      // Overview stats
                      Text(gym.name,
                          style: HyphenTokens.h3.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: HyphenTokens.sp1),
                      Text(
                        '승인 ${approved.length} · 활동 $activeCount · 휴면 $dormantCount · 세션 $totalSessions',
                        style: HyphenTokens.caption,
                      ),
                      const SizedBox(height: HyphenTokens.sp3),
                      // v1.16 Sprint 17: Member Requests 진입점.
                      OutlinedButton.icon(
                        onPressed: () {
                          Haptic.light();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const MemberRequestsScreen(),
                          ));
                        },
                        icon: const Icon(Icons.inbox_outlined, size: 18),
                        label: const Text('회원 요청'),
                      ),
                      const SizedBox(height: HyphenTokens.sp2),
                      // v1.22: 체육관 정보 (전화·코치·수업·모토) 편집 진입점.
                      OutlinedButton.icon(
                        onPressed: () async {
                          Haptic.light();
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const GymProfileEditScreen(),
                          ));
                          if (!mounted) return;
                          _reload();
                        },
                        icon: const Icon(Icons.edit_note_outlined, size: 18),
                        label: const Text('체육관 프로필 수정'),
                      ),
                      const SizedBox(height: HyphenTokens.sp5),
                      if (pending.isNotEmpty) ...[
                        Text('승인 대기 (${pending.length})',
                            style: HyphenTokens.sectionLabel),
                        const SizedBox(height: HyphenTokens.sp2),
                        ...pending.map((m) => _PendingRow(
                              member: m,
                              onApprove: () => _decide(m, 'approve'),
                              onReject: () => _decide(m, 'reject'),
                            )),
                        const SizedBox(height: HyphenTokens.sp5),
                      ],
                      Text('회원 명단 (${approved.length})',
                          style: HyphenTokens.sectionLabel),
                      const SizedBox(height: HyphenTokens.sp2),
                      if (approved.isEmpty)
                        const Text('승인된 멤버 없음.',
                            style: HyphenTokens.caption)
                      else
                        ...approved.map((m) => _RosterRow(
                              member: m,
                              onTap: () => _openMemberSheet(m),
                            )),
                      if (rejected.isNotEmpty) ...[
                        const SizedBox(height: HyphenTokens.sp5),
                        Text('거절됨 (${rejected.length})',
                            style: HyphenTokens.sectionLabel),
                        const SizedBox(height: HyphenTokens.sp2),
                        ...rejected.map((m) => _RosterRow(
                              member: m,
                              onTap: () => _openMemberSheet(m),
                              muted: true,
                            )),
                      ],
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  final GymMember member;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingRow({
    required this.member,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.displayName,
                    style: HyphenTokens.body.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                Text(_dateShort(member.requestedAt),
                    style: HyphenTokens.caption),
                if ((member.phone ?? '').isNotEmpty)
                  Text(member.phone!, style: HyphenTokens.caption),
              ],
            ),
          ),
          TextButton(onPressed: onApprove, child: const Text('승인')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: HyphenTokens.fgSecondary),
            onPressed: onReject,
            child: const Text('거절'),
          ),
        ],
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  final GymMember member;
  final VoidCallback onTap;
  final bool muted;

  const _RosterRow({
    required this.member,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = muted ? HyphenTokens.muted : HyphenTokens.fg;
    final lastLabel = _lastLabel(member);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.displayName,
                          style: HyphenTokens.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: HyphenTokens.sp2),
                      if ((member.level ?? '').isNotEmpty)
                        // 저장값 'RX' 의 노출 표기는 'RXD' (GLOSSARY §3).
                        HkBadge(
                          member.level == 'RX' ? 'RXD' : member.level!,
                          color: HyphenTokens.accent,
                        ),
                      if (member.isDormant)
                        const HkBadge('DORMANT', color: HyphenTokens.warning)
                      else if (member.lastWodAt == null && member.isApproved)
                        const HkBadge('NEW', color: HyphenTokens.muted),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastLabel,
                    style: HyphenTokens.caption,
                  ),
                ],
              ),
            ),
            _numBlock(label: '세션', value: '${member.totalSessions}'),
            const SizedBox(width: HyphenTokens.sp3),
            _numBlock(label: '스트릭', value: '${member.streakDays}'),
            const SizedBox(width: HyphenTokens.sp2),
            const Icon(Icons.chevron_right, color: HyphenTokens.muted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _numBlock({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: HyphenTokens.microLabel),
        Text(value,
            style: HyphenTokens.body.copyWith(
              fontFeatures: HyphenTokens.tabular,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }

  String _lastLabel(GymMember m) {
    if (m.status != 'approved') {
      return _dateShort(m.requestedAt);
    }
    if (m.lastWodAt == null) return '기록 없음';
    final days = m.daysSinceLastWod;
    if (days == 0) return '오늘 활동';
    if (days == 1) return '어제 활동';
    if (days < 7) return '$days일 전';
    if (days < 30) return '${days ~/ 7}주 전';
    return _dateShort(m.lastWodAt!);
  }
}

String _dateShort(DateTime d) {
  final l = d.toLocal();
  return '${l.month.toString().padLeft(2, '0')}/${l.day.toString().padLeft(2, '0')} '
      '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// 멤버 탭 시 bottom sheet — 부상 메모·목표는 아직 저장 경로가 없어 안내만 띄운다.
class _MemberDetailSheet extends StatelessWidget {
  final GymMember member;
  const _MemberDetailSheet({required this.member});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(HyphenTokens.sp5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('회원 ${member.deviceHashPrefix}',
                      style: HyphenTokens.h3),
                ),
                Text(
                  // 서버 상태 코드를 그대로 대문자 노출하던 것 → 한글
                  // (roleKoLabel 은 '회원·승인됨' 묶음이라 상태 단독 표기는 여기서).
                  switch (member.status) {
                    'approved' => '승인됨',
                    'pending' => '대기',
                    'rejected' => '거절됨',
                    _ => member.status,
                  },
                  style: HyphenTokens.microLabel.copyWith(
                    color: HyphenTokens.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: HyphenTokens.sp4),
            _kv('가입 요청', _dateShort(member.requestedAt)),
            if (member.decidedAt != null)
              _kv('승인·거절', _dateShort(member.decidedAt!)),
            _kv('총 세션', '${member.totalSessions}'),
            _kv('현재 Streak', '${member.streakDays}일'),
            _kv('마지막 기록',
                member.lastWodAt == null ? '-' : _dateShort(member.lastWodAt!)),
            const SizedBox(height: HyphenTokens.sp4),
            const Text('코치 노트', style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp2),
            // v2.6 (2026-08-13 사용자 지시): 할 말이 있을 때만 띄운다.
            // 종전엔 평범한 회원에게 '부상 메모·목표 기록은 준비 중' 이라는
            // 없는 기능 예고가 기본값으로 깔렸다.
            if (member.isDormant || member.totalSessions == 0) ...[
              Container(
                padding: const EdgeInsets.all(HyphenTokens.sp3),
                decoration: BoxDecoration(
                  color: HyphenTokens.surfaceOverlay,
                  borderRadius: BorderRadius.circular(HyphenTokens.r2),
                  border: Border.all(color: HyphenTokens.border),
                ),
                child: Text(
                  member.isDormant
                      ? '2주 이상 미참석. 재참여 캠페인 추천.'
                      : '신규 회원. 첫 수업 유도 필요.',
                  style: HyphenTokens.caption,
                ),
              ),
              const SizedBox(height: HyphenTokens.sp4),
            ],
            if (member.deviceHashFull != null) ...[
              ElevatedButton.icon(
                onPressed: () {
                  // 통합 v1.26: 쪽지는 GymCoachNote 단일 시스템.
                  // ChatThreadScreen → 회원 메시지 피드와 동일 저장소.
                  final gymId =
                      context.read<GymState>().membership.gym?.id;
                  Navigator.of(context).pop();
                  if (gymId == null) return;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatThreadScreen(
                      gymId: gymId,
                      peerHash: member.deviceHashFull!,
                      peerName: 'user:${member.deviceHashPrefix}',
                    ),
                  ));
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('메시지 보내기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HyphenTokens.accent,
                  foregroundColor: HyphenTokens.fg,
                ),
              ),
              const SizedBox(height: HyphenTokens.sp2),
              // v1.16 Sprint 17: 오늘 WOD 중 선택해 코치 노트 작성.
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _coachNoteFlow(context, member);
                },
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('코치 노트 남기기'),
              ),
            ],
            const SizedBox(height: HyphenTokens.sp2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _coachNoteFlow(BuildContext context, GymMember m) async {
    Haptic.light();
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null || m.deviceHashFull == null) return;
    final wods = gs.todayWods;
    if (wods.isEmpty) {
      HkSnack.error(context, '오늘 수업 내용 없음. 먼저 게시.');
      return;
    }
    // WOD 선택 (today 1개면 스킵).
    GymWodPost? pickedWod = wods.length == 1 ? wods.first : null;
    pickedWod ??= await showModalBottomSheet<GymWodPost>(
        context: context,
        backgroundColor: HyphenTokens.surface,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(HyphenTokens.sp4),
                child: Text('수업 내용 선택', style: HyphenTokens.sectionLabel),
              ),
              ...wods.map((w) => ListTile(
                    title: Text(wodTypeLabel(w.wodType)),
                    subtitle: Text(
                      w.content.length > 40
                          ? '${w.content.substring(0, 40)}…'
                          : w.content,
                      style: HyphenTokens.caption,
                    ),
                    onTap: () => Navigator.of(ctx).pop(w),
                  )),
            ],
          ),
        ),
      );
    // QA B-AS-2: 이중 mounted 체크 데드코드 제거.
    if (pickedWod == null || !context.mounted) return;

    // QA B-ML-5: bodyCtrl dispose 보장.
    final bodyCtrl = TextEditingController();
    try {
      await showModalBottomSheet<void>(
      context: context,
      backgroundColor: HyphenTokens.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(HyphenTokens.r4)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: HyphenTokens.sp4,
          right: HyphenTokens.sp4,
          top: HyphenTokens.sp4,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + HyphenTokens.sp4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('쪽지 보내기 → ${m.deviceHashPrefix}',
                style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp1),
            Text(
              '수업 내용: ${wodTypeLabel(pickedWod!.wodType)} · ${pickedWod.postDate}',
              style: HyphenTokens.caption,
            ),
            const SizedBox(height: HyphenTokens.sp3),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(
                labelText: '노트',
                hintText:
                    '예: "오늘 쓰러스터 중 어깨가 아파 보였음. 하지 드라이브 활용 권장."',
              ),
              maxLines: 6,
              maxLength: 2000,
            ),
            const SizedBox(height: HyphenTokens.sp3),
            ElevatedButton(
              onPressed: () async {
                final body = bodyCtrl.text.trim();
                // v1.19 차수 5 (B-IN-11): 빈 / 공백 / 너무 짧음 차단.
                if (body.length < 4) {
                  HkSnack.error(ctx, '노트 4자 이상 필요.');
                  return;
                }
                try {
                  await context.read<GymRepository>().upsertCoachFeedback(
                        gymId: gym.id,
                        wodId: pickedWod!.id,
                        memberHash: m.deviceHashFull!,
                        body: body,
                      );
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  HkSnack.show(context, '코치 노트 저장.', mood: MascotMood.happy);
                } on AppException catch (e) {
                  if (!ctx.mounted) return;
                  HkSnack.error(ctx, '실패: ${e.messageKo}');
                } catch (e) {
                  // /go Tier 3: generic catch.
                  debugPrint('[CoachDashboard._coachNoteFlow] $e');
                  if (!ctx.mounted) return;
                  HkSnack.error(ctx, '실패. 다시 시도.');
                }
              },
              child: const Text('노트 저장'),
            ),
          ],
        ),
      ),
    );
    } finally {
      bodyCtrl.dispose();
    }
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp1),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: HyphenTokens.microLabel),
          ),
          Expanded(
            child: Text(v,
                style: HyphenTokens.body.copyWith(
                  fontFeatures: HyphenTokens.tabular,
                )),
          ),
        ],
      ),
    );
  }
}
