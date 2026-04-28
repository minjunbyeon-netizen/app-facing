// v1.16 Sprint 15: 박스 내 1:1 메시지 — 간단 스레드 UI.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/announcement.dart';
import '../../widgets/coach_badge.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';

class MessagesScreen extends StatefulWidget {
  /// null이면 "전체 수신함". withHash 지정 시 해당 상대와의 스레드.
  final String? withHash;
  final String? withLabel;
  const MessagesScreen({super.key, this.withHash, this.withLabel});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  Future<List<GymMessageItem>>? _future;
  final _inputCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null) {
      setState(() => _future = Future.value(const []));
      return;
    }
    setState(() {
      _future = context
          .read<GymRepository>()
          .listMessages(gym.id, withHash: widget.withHash);
    });
  }

  Future<void> _send() async {
    final body = _inputCtrl.text.trim();
    if (body.isEmpty) return;
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null) return;
    if (widget.withHash == null || widget.withHash!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('스레드 열어 답장하세요. 수신함 직접 송신 미지원.')),
      );
      return;
    }
    setState(() => _sending = true);
    Haptic.medium();
    try {
      await context.read<GymRepository>().sendMessage(
            gymId: gym.id,
            toHash: widget.withHash!,
            body: body,
          );
      _inputCtrl.clear();
      if (!mounted) return;
      _reload();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전송 실패: ${e.messageKo}')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.withHash == null
              ? 'MESSAGES'
              : 'TO ${widget.withLabel ?? (widget.withHash!.length >= 8 ? widget.withHash!.substring(0, 8) : widget.withHash!)}',
        ),
        actions: [
          if (gs.isOwner) const CoachBadgeAction(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: SafeArea(
        child: gym == null
            ? const Center(
                child: Text('박스 소속 없음.', style: FacingTokens.caption))
            : Column(
                children: [
                  Expanded(
                    child: FutureBuilder<List<GymMessageItem>>(
                      future: _future,
                      builder: (ctx, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: FacingTokens.muted, strokeWidth: 2),
                          );
                        }
                        if (snap.hasError) {
                          final e = snap.error;
                          final msg =
                              e is AppException ? e.messageKo : '로딩 실패';
                          return Padding(
                            padding: const EdgeInsets.all(FacingTokens.sp4),
                            child: Text(msg, style: FacingTokens.body),
                          );
                        }
                        final items =
                            snap.data ?? const <GymMessageItem>[];
                        if (items.isEmpty) {
                          return const Center(
                            child: Text('메시지 없음.',
                                style: FacingTokens.caption),
                          );
                        }
                        return ListView.builder(
                          padding:
                              const EdgeInsets.all(FacingTokens.sp3),
                          reverse: true,
                          itemCount: items.length,
                          itemBuilder: (_, i) =>
                              _MessageBubble(msg: items[i]),
                        );
                      },
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: FacingTokens.border, width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.all(FacingTokens.sp3),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputCtrl,
                            decoration: const InputDecoration(
                              hintText: '메시지 입력',
                              isDense: true,
                            ),
                            maxLines: 3,
                            minLines: 1,
                          ),
                        ),
                        const SizedBox(width: FacingTokens.sp2),
                        IconButton(
                          icon: const Icon(Icons.send),
                          color: FacingTokens.accent,
                          onPressed: _sending ? null : _send,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final GymMessageItem msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final mine = msg.isMine;
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 280),
      margin: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      padding: const EdgeInsets.symmetric(
        horizontal: FacingTokens.sp3,
        vertical: FacingTokens.sp2,
      ),
      decoration: BoxDecoration(
        color: mine
            ? FacingTokens.accent.withValues(alpha: 0.18)
            : FacingTokens.surface,
        border: Border.all(
          color: mine ? FacingTokens.accent : FacingTokens.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!mine)
            Text(
              'from ${msg.fromHash.length >= 8 ? msg.fromHash.substring(0, 8) : msg.fromHash}',
              style: FacingTokens.micro.copyWith(
                color: FacingTokens.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          Text(msg.body, style: FacingTokens.body),
          const SizedBox(height: 2),
          Text(
            _fmt(msg.createdAt),
            style: FacingTokens.micro.copyWith(color: FacingTokens.muted),
          ),
        ],
      ),
    );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: mine
          ? bubble
          : InkWell(
              onTap: () {
                // v1.19 차수 5 (B-PF-15): substring 길이 안전. !mine 이미 자기 차단.
                final label = msg.fromHash.length >= 8
                    ? msg.fromHash.substring(0, 8)
                    : msg.fromHash;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MessagesScreen(
                    withHash: msg.fromHash,
                    withLabel: label,
                  ),
                ));
              },
              child: bubble,
            ),
    );
  }

  String _fmt(DateTime d) {
    final l = d.toLocal();
    return '${l.month.toString().padLeft(2, '0')}/${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}
