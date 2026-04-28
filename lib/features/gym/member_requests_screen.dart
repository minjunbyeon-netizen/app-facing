// v1.16 Sprint 17: 코치용 Member Requests 수신함 + 응답 작성.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      backgroundColor: FacingTokens.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FacingTokens.r4)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: FacingTokens.sp4,
          right: FacingTokens.sp4,
          top: FacingTokens.sp4,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + FacingTokens.sp4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('RESPOND', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp1),
            Text(
              '${r.fromHashPrefix} · ${r.subject.isNotEmpty ? r.subject : "(no subject)"}',
              style: FacingTokens.caption,
            ),
            const SizedBox(height: FacingTokens.sp2),
            Text(r.body, style: FacingTokens.body),
            const SizedBox(height: FacingTokens.sp3),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(
                labelText: '응답',
                hintText: '예: "오늘은 Ring Row로 대체하세요. 내일 상담 후 조정."',
              ),
              maxLines: 5,
              maxLength: 2000,
            ),
            const SizedBox(height: FacingTokens.sp3),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await _patch(r, null, 'dismissed');
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: FacingTokens.sp2),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _patch(r, bodyCtrl.text.trim(), 'resolved');
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Send & Resolve'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.messageKo}')),
      );
    } catch (e) {
      // /go Tier 3: generic catch.
      debugPrint('[MemberRequests._patch] $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('실패. 다시 시도.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MEMBER REQUESTS'),
        actions: [
          const CoachBadgeAction(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(FacingTokens.sp3),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'open', label: Text('Open')),
                  ButtonSegment(value: 'resolved', label: Text('Resolved')),
                  ButtonSegment(value: '', label: Text('All')),
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
                          color: FacingTokens.muted, strokeWidth: 2),
                    );
                  }
                  final list = snap.data ?? const <MemberRequest>[];
                  if (list.isEmpty) {
                    return const Center(
                      child:
                          Text('요청 없음.', style: FacingTokens.caption),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(FacingTokens.sp4),
                    itemCount: list.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: FacingTokens.sp2),
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
        padding: const EdgeInsets.all(FacingTokens.sp3),
        decoration: BoxDecoration(
          color: FacingTokens.surface,
          borderRadius: BorderRadius.circular(FacingTokens.r2),
          border: Border.all(
            color: isOpen ? FacingTokens.accent : FacingTokens.border,
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
                  style: FacingTokens.micro.copyWith(
                    color: isOpen
                        ? FacingTokens.accent
                        : FacingTokens.muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: FacingTokens.sp2),
                Text('from ${req.fromHashPrefix}',
                    style: FacingTokens.caption),
                const Spacer(),
                if (req.wodPostId != null)
                  Text('WOD #${req.wodPostId}',
                      style: FacingTokens.micro.copyWith(
                          color: FacingTokens.muted)),
              ],
            ),
            if (req.subject.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(req.subject,
                  style: FacingTokens.body
                      .copyWith(fontWeight: FontWeight.w800)),
            ],
            const SizedBox(height: 2),
            Text(req.body,
                style: FacingTokens.caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            if (req.coachResponse != null &&
                req.coachResponse!.isNotEmpty) ...[
              const SizedBox(height: FacingTokens.sp2),
              Container(
                padding: const EdgeInsets.all(FacingTokens.sp2),
                decoration: BoxDecoration(
                  color: FacingTokens.surfaceOverlay,
                  borderRadius:
                      BorderRadius.circular(FacingTokens.r1),
                  border: const Border(
                    left: BorderSide(
                        color: FacingTokens.accent, width: 2),
                  ),
                ),
                child: Text(
                  '[Coach] ${req.coachResponse}',
                  style: FacingTokens.caption,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
