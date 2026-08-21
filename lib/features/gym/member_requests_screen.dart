// v1.16 Sprint 17: 코치용 Member Requests 수신함 + 응답 작성.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/hkit.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/coach_feedback.dart';
import '../../widgets/coach_badge.dart';
import 'gym_repository.dart';
import 'gym_state.dart';

class MemberRequestsScreen extends StatefulWidget {
  const MemberRequestsScreen({super.key});

  @override
  State<MemberRequestsScreen> createState() => _MemberRequestsScreenState();
}

class _MemberRequestsScreenState extends State<MemberRequestsScreen> {
  Future<List<MemberRequest>>? _future;
  String _filter = 'open';

  @override
  void initState() {
    super.initState();
    // QA B-SEC-2: 비코치 접근 차단.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.read<GymState>().isOwner) {
        Navigator.of(context).pop();
        return;
      }
      _reload();
    });
  }

  void _reload() {
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null || !gs.isOwner) {
      setState(() => _future = Future.value(const []));
      return;
    }
    setState(() {
      _future = context
          .read<GymRepository>()
          .listMemberRequests(gym.id, status: _filter);
    });
  }

  Future<void> _respond(MemberRequest r) async {
    // QA B-ML-6: bodyCtrl dispose 보장.
    final bodyCtrl = TextEditingController(text: r.coachResponse ?? '');
    Haptic.light();
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
            const Text('답변', style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp1),
            Text(
              '${r.fromHashPrefix} · ${r.subject.isNotEmpty ? r.subject : "(no subject)"}',
              style: HyphenTokens.caption,
            ),
            const SizedBox(height: HyphenTokens.sp2),
            Text(r.body, style: HyphenTokens.body),
            const SizedBox(height: HyphenTokens.sp3),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(
                labelText: '응답',
                hintText: '예: "오늘은 Ring Row로 대체하세요. 내일 상담 후 조정."',
              ),
              maxLines: 5,
              maxLength: 2000,
            ),
            const SizedBox(height: HyphenTokens.sp3),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await _patch(r, null, 'dismissed');
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('닫기'),
                  ),
                ),
                const SizedBox(width: HyphenTokens.sp2),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _patch(r, bodyCtrl.text.trim(), 'resolved');
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('보내고 해결'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    } finally {
      bodyCtrl.dispose();
    }
  }

  Future<void> _patch(MemberRequest r, String? body, String? status) async {
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null) return;
    try {
      await context.read<GymRepository>().respondMemberRequest(
            gymId: gym.id,
            requestId: r.id,
            coachResponse: body,
            status: status,
          );
      if (!mounted) return;
      _reload();
    } on AppException catch (e) {
      if (!mounted) return;
      HkSnack.error(context, '실패: ${e.messageKo}');
    } catch (e) {
      // /go Tier 3: generic catch.
      debugPrint('[MemberRequests._patch] $e');
      if (!mounted) return;
      HkSnack.error(context, '실패. 다시 시도.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 요청'),
        actions: [
          const CoachBadgeAction(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(HyphenTokens.sp3),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'open', label: Text('진행 중')),
                  ButtonSegment(value: 'resolved', label: Text('해결됨')),
                  ButtonSegment(value: '', label: Text('전체')),
                ],
                selected: {_filter},
                onSelectionChanged: (s) {
                  Haptic.selection();
                  setState(() => _filter = s.first);
                  _reload();
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<MemberRequest>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: HyphenTokens.muted, strokeWidth: 2),
                    );
                  }
                  final list = snap.data ?? const <MemberRequest>[];
                  if (list.isEmpty) {
                    return const Center(
                      child:
                          Text('요청 없음.', style: HyphenTokens.caption),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(HyphenTokens.sp4),
                    itemCount: list.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: HyphenTokens.sp2),
                    itemBuilder: (_, i) => _RequestRow(
                      req: list[i],
                      onTap: () => _respond(list[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final MemberRequest req;
  final VoidCallback onTap;
  const _RequestRow({required this.req, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOpen = req.isOpen;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(HyphenTokens.sp3),
        decoration: BoxDecoration(
          color: HyphenTokens.surface,
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
          border: Border.all(
            color: isOpen ? HyphenTokens.accent : HyphenTokens.border,
            width: isOpen ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  req.status.toUpperCase(),
                  style: HyphenTokens.microLabel.copyWith(
                    color: isOpen
                        ? HyphenTokens.accent
                        : HyphenTokens.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: HyphenTokens.sp2),
                Text('from ${req.fromHashPrefix}',
                    style: HyphenTokens.caption),
                const Spacer(),
                if (req.wodPostId != null)
                  Text('수업 #${req.wodPostId}',
                      style: HyphenTokens.micro.copyWith(
                          color: HyphenTokens.muted)),
              ],
            ),
            if (req.subject.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(req.subject,
                  style: HyphenTokens.body
                      .copyWith(fontWeight: FontWeight.w800)),
            ],
            const SizedBox(height: 2),
            Text(req.body,
                style: HyphenTokens.caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            if (req.coachResponse != null &&
                req.coachResponse!.isNotEmpty) ...[
              const SizedBox(height: HyphenTokens.sp2),
              Container(
                padding: const EdgeInsets.all(HyphenTokens.sp2),
                decoration: BoxDecoration(
                  color: HyphenTokens.surfaceOverlay,
                  borderRadius:
                      BorderRadius.circular(HyphenTokens.r1),
                  border: const Border(
                    left: BorderSide(
                        color: HyphenTokens.accent, width: 2),
                  ),
                ),
                child: Text(
                  '[Coach] ${req.coachResponse}',
                  style: HyphenTokens.caption,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
