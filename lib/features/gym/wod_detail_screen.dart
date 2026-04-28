// v1.16 Sprint 16: 박스 WOD 상세 — 버전 선택 + 리더보드 + 댓글.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/coach_feedback.dart';
import '../../widgets/coach_badge.dart';
import '../../models/gym.dart';
import '../wod_session/wod_session_screen.dart';
import 'gym_repository.dart';
import 'gym_state.dart';

enum _ScaleLevel { rx, scaled, beginner }

class WodDetailScreen extends StatefulWidget {
  final GymWodPost wod;
  const WodDetailScreen({super.key, required this.wod});

  @override
  State<WodDetailScreen> createState() => _WodDetailScreenState();
}

class _WodDetailScreenState extends State<WodDetailScreen> {
  _ScaleLevel _level = _ScaleLevel.rx;
  Future<List<GymWodResult>>? _resultsFuture;
  Future<List<GymWodComment>>? _commentsFuture;
  Future<List<CoachFeedback>>? _feedbackFuture;
  final _commentCtrl = TextEditingController();
  bool _sendingComment = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null) return;
    final repo = context.read<GymRepository>();
    setState(() {
      _resultsFuture = repo.listWodResults(gym.id, widget.wod.id);
      _commentsFuture = repo.listWodComments(gym.id, widget.wod.id);
      _feedbackFuture = repo.listCoachFeedback(gym.id, widget.wod.id);
    });
  }

  // QA A-10: 사용 안 되는 _leaveCoachNote 제거.
  // 코치는 Coach Dashboard 멤버 sheet에서 노트 작성. 리더보드 행에는 진입점 없음.

  Future<void> _sendRequest() async {
    Haptic.medium();
    final subjectCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    // QA B-GYM-2: 모달 닫힌 후 controller dispose 보장.
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
            const Text('SEND REQUEST TO COACH',
                style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp1),
            const Text(
              '이 WOD 관련 조정·대체 요청. 예: "어깨 수술 이력 있어 Thruster 대체 부탁".',
              style: FacingTokens.caption,
            ),
            const SizedBox(height: FacingTokens.sp3),
            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(labelText: '제목'),
              maxLength: 120,
            ),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(
                labelText: '내용',
                hintText: '상황·원하는 대체 동작·비고',
              ),
              maxLines: 5,
              maxLength: 2000,
            ),
            const SizedBox(height: FacingTokens.sp3),
            ElevatedButton(
              onPressed: () async {
                final body = bodyCtrl.text.trim();
                if (body.isEmpty) return;
                final gs = context.read<GymState>();
                final gym = gs.membership.gym;
                if (gym == null) return;
                try {
                  await context.read<GymRepository>().sendMemberRequest(
                        gymId: gym.id,
                        subject: subjectCtrl.text.trim(),
                        body: body,
                        wodPostId: widget.wod.id,
                      );
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  // QA A-11: 부모 context는 ctx.mounted로는 보호 불가. ScaffoldMessenger를 ctx 기준으로 사용.
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('건의 전송. 코치 응답 대기.')),
                  );
                } on AppException catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('실패: ${e.messageKo}')),
                  );
                } catch (e) {
                  // /go Tier 3: generic catch.
                  debugPrint('[WodDetail._sendRequest] $e');
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('전송 실패. 다시 시도.')),
                  );
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
    } finally {
      subjectCtrl.dispose();
      bodyCtrl.dispose();
    }
  }

  Future<void> _sendComment() async {
    final body = _commentCtrl.text.trim();
    if (body.isEmpty) return;
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null) return;
    setState(() => _sendingComment = true);
    Haptic.medium();
    try {
      await context.read<GymRepository>().postWodComment(
            gymId: gym.id,
            wodId: widget.wod.id,
            body: body,
          );
      _commentCtrl.clear();
      _reload();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 실패: ${e.messageKo}')),
      );
    } catch (e) {
      // /go Tier 3: generic catch.
      debugPrint('[WodDetail._sendComment] $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 실패. 다시 시도.')),
      );
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  String _displayContent() {
    switch (_level) {
      case _ScaleLevel.scaled:
        final s = widget.wod.scaledVersion;
        return (s == null || s.isEmpty) ? widget.wod.content : s;
      case _ScaleLevel.beginner:
        final b = widget.wod.beginnerVersion;
        return (b == null || b.isEmpty) ? widget.wod.content : b;
      case _ScaleLevel.rx:
        return widget.wod.content;
    }
  }

  void _startSession() {
    Haptic.medium();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WodSessionScreen(wod: widget.wod),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final wod = widget.wod;
    final hasScaled = wod.scaledVersion != null && wod.scaledVersion!.isNotEmpty;
    final hasBeginner =
        wod.beginnerVersion != null && wod.beginnerVersion!.isNotEmpty;
    final isOwner = context.watch<GymState>().isOwner;
    return Scaffold(
      appBar: AppBar(
        title: Text(wod.wodType.toUpperCase()),
        actions: [
          if (isOwner) const CoachBadgeAction(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          children: [
            // 버전 선택 토글
            if (hasScaled || hasBeginner)
              SegmentedButton<_ScaleLevel>(
                segments: [
                  const ButtonSegment(
                      value: _ScaleLevel.rx, label: Text('RX')),
                  if (hasScaled)
                    const ButtonSegment(
                        value: _ScaleLevel.scaled, label: Text('Scaled')),
                  if (hasBeginner)
                    const ButtonSegment(
                        value: _ScaleLevel.beginner, label: Text('Beginner')),
                ],
                selected: {_level},
                onSelectionChanged: (s) {
                  Haptic.selection();
                  setState(() => _level = s.first);
                },
              ),
            if (hasScaled || hasBeginner)
              const SizedBox(height: FacingTokens.sp3),
            // 본문
            Container(
              padding: const EdgeInsets.all(FacingTokens.sp4),
              decoration: BoxDecoration(
                color: FacingTokens.surface,
                borderRadius: BorderRadius.circular(FacingTokens.r3),
                border: Border.all(color: FacingTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_levelLabel(),
                      style: FacingTokens.sectionLabel.copyWith(
                        color: FacingTokens.accent,
                      )),
                  const SizedBox(height: FacingTokens.sp2),
                  Text(_displayContent(), style: FacingTokens.body),
                ],
              ),
            ),
            const SizedBox(height: FacingTokens.sp3),
            ElevatedButton.icon(
              onPressed: _startSession,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Start Timer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FacingTokens.accent,
                foregroundColor: FacingTokens.fg,
              ),
            ),
            const SizedBox(height: FacingTokens.sp3),
            // v1.16 Sprint 17: 멤버 건의 버튼.
            Builder(builder: (ctx) {
              final gs = ctx.watch<GymState>();
              if (gs.isOwner) return const SizedBox.shrink();
              return OutlinedButton.icon(
                onPressed: _sendRequest,
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('Send Request to Coach'),
              );
            }),
            const SizedBox(height: FacingTokens.sp5),

            // v1.16 Sprint 17: 코치 피드백.
            const Text('COACH FEEDBACK', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            FutureBuilder<List<CoachFeedback>>(
              future: _feedbackFuture,
              builder: (ctx, snap) {
                final list = snap.data ?? const <CoachFeedback>[];
                if (list.isEmpty) {
                  return const Text(
                    '코치 피드백 없음. Coach Dashboard에서 작성.',
                    style: FacingTokens.caption,
                  );
                }
                return Column(
                  children: list
                      .map((f) => _FeedbackCard(fb: f))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: FacingTokens.sp5),

            // Leaderboard
            const Text('LEADERBOARD', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            FutureBuilder<List<GymWodResult>>(
              future: _resultsFuture,
              builder: (ctx, snap) {
                final list = snap.data ?? const <GymWodResult>[];
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(FacingTokens.sp3),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: FacingTokens.muted, strokeWidth: 2),
                    ),
                  );
                }
                if (list.isEmpty) {
                  return const Text(
                    '아직 기록 없음. Start Timer → Done으로 첫 기록 제출.',
                    style: FacingTokens.caption,
                  );
                }
                return Column(
                  children:
                      list.map((r) => _ResultRow(result: r)).toList(),
                );
              },
            ),
            const SizedBox(height: FacingTokens.sp5),

            // Comments
            const Text('COMMENTS', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            FutureBuilder<List<GymWodComment>>(
              future: _commentsFuture,
              builder: (ctx, snap) {
                final list = snap.data ?? const <GymWodComment>[];
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(FacingTokens.sp3),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: FacingTokens.muted, strokeWidth: 2),
                    ),
                  );
                }
                if (list.isEmpty) {
                  return const Text('첫 댓글을 남겨보세요.',
                      style: FacingTokens.caption);
                }
                return Column(
                  children: list.map((c) => _CommentRow(comment: c)).toList(),
                );
              },
            ),
            const SizedBox(height: FacingTokens.sp3),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: const InputDecoration(
                      hintText: '댓글 입력.',
                      isDense: true,
                    ),
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 500,
                  ),
                ),
                const SizedBox(width: FacingTokens.sp2),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: FacingTokens.accent,
                  onPressed: _sendingComment ? null : _sendComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _levelLabel() {
    switch (_level) {
      case _ScaleLevel.rx:
        return 'RX';
      case _ScaleLevel.scaled:
        return 'SCALED';
      case _ScaleLevel.beginner:
        return 'BEGINNER';
    }
  }
}

class _ResultRow extends StatelessWidget {
  final GymWodResult result;
  const _ResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final mine = result.isMine;
    final isTop = result.rank <= 3;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      padding: const EdgeInsets.all(FacingTokens.sp3),
      decoration: BoxDecoration(
        color: mine
            ? FacingTokens.accent.withValues(alpha: 0.12)
            : FacingTokens.surface,
        border: Border.all(
          color: mine ? FacingTokens.accent : FacingTokens.border,
          width: mine ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${result.rank}${_suffix(result.rank)}',
              style: FacingTokens.h3.copyWith(
                color: isTop ? FacingTokens.accent : FacingTokens.fg,
                fontWeight: FontWeight.w800,
                fontFeatures: FacingTokens.tabular,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mine ? 'You' : 'user:${result.deviceHashPrefix}',
                  style: FacingTokens.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (result.scaleLevel != 'rx')
                  Text(
                    result.scaleLevel.toUpperCase(),
                    style: FacingTokens.microLabel,
                  ),
              ],
            ),
          ),
          Text(result.display,
              style: FacingTokens.h3.copyWith(
                fontFeatures: FacingTokens.tabular,
                fontWeight: FontWeight.w800,
              )),
        ],
      ),
    );
  }

  String _suffix(int rank) {
    if (rank == 1) return 'st';
    if (rank == 2) return 'nd';
    if (rank == 3) return 'rd';
    return 'th';
  }
}

class _FeedbackCard extends StatelessWidget {
  final CoachFeedback fb;
  const _FeedbackCard({required this.fb});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp2),
      padding: const EdgeInsets.all(FacingTokens.sp3),
      decoration: BoxDecoration(
        color: FacingTokens.surfaceOverlay,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
        border: const Border(
          left: BorderSide(color: FacingTokens.accent, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                fb.isMine ? 'COACH → YOU' : 'COACH → ${fb.memberHashPrefix}',
                style: FacingTokens.microLabel.copyWith(
                  color: FacingTokens.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                _fmt(fb.updatedAt),
                style: FacingTokens.micro.copyWith(color: FacingTokens.muted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(fb.body, style: FacingTokens.body),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    final l = d.toLocal();
    return '${l.month.toString().padLeft(2, '0')}/${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

class _CommentRow extends StatelessWidget {
  final GymWodComment comment;
  const _CommentRow({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      padding: const EdgeInsets.all(FacingTokens.sp2),
      decoration: BoxDecoration(
        color: comment.isMine
            ? FacingTokens.accent.withValues(alpha: 0.10)
            : FacingTokens.surface,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
        border: Border.all(color: FacingTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.isMine ? 'You' : 'user:${comment.authorPrefix}',
                style: FacingTokens.microLabel.copyWith(
                  color: comment.isMine
                      ? FacingTokens.accent
                      : FacingTokens.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                _fmt(comment.createdAt),
                style: FacingTokens.micro.copyWith(color: FacingTokens.muted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(comment.body, style: FacingTokens.body),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    final l = d.toLocal();
    return '${l.month.toString().padLeft(2, '0')}/${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}
