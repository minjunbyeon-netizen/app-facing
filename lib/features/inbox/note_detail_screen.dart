// v1.18 Sprint 19: Note 상세 — 본문 + Assignment items + Accept/Decline/Complete.
// 진입 즉시 read 처리 (본인 미읽음일 때만).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/coach_note.dart';
import 'inbox_repository.dart';
import 'inbox_state.dart';

class NoteDetailScreen extends StatefulWidget {
  final int noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  CoachNote? _note;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final n = await context.read<InboxRepository>().getNote(widget.noteId);
      if (!mounted) return;
      setState(() {
        _note = n;
        _loading = false;
      });
      // 미읽음 → read 자동 마킹.
      if (n.my != null && n.my!.isUnread) {
        await context.read<InboxState>().markRead(widget.noteId);
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.messageKo;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '로딩 실패: $e';
        _loading = false;
      });
    }
  }

  Future<void> _act(String action) async {
    Haptic.medium();
    final state = context.read<InboxState>();
    bool ok;
    if (action == 'accept') {
      ok = await state.accept(widget.noteId);
    } else if (action == 'complete') {
      ok = await state.complete(widget.noteId);
    } else {
      ok = await state.decline(widget.noteId);
    }
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: FacingTokens.surface,
          content: Text('${_actionLabel(action)} done.',
              style: FacingTokens.body),
        ),
      );
      // 상세 새로고침.
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: FacingTokens.surface,
          content: Text('실패. ${state.error ?? ''}',
              style: FacingTokens.body),
        ),
      );
    }
  }

  String _actionLabel(String a) {
    switch (a) {
      case 'accept':
        return 'Accepted';
      case 'complete':
        return 'Completed';
      case 'decline':
        return 'Declined';
      default:
        return 'Done';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NOTE')),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: FacingTokens.muted, strokeWidth: 2),
              )
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(FacingTokens.sp4),
                    child: Text(_error!, style: FacingTokens.body),
                  )
                : _buildBody(_note!),
      ),
    );
  }

  Widget _buildBody(CoachNote n) {
    final color = n.my?.isUnread == true
        ? FacingTokens.accent
        : FacingTokens.muted;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 — kind + 발신자 + 시간
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FacingTokens.sp2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(FacingTokens.r1),
                ),
                child: Text(
                  n.kind.toUpperCase(),
                  style: FacingTokens.micro.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: FacingTokens.sp2),
              Text(
                'COACH · ${n.senderShort.toUpperCase()}',
                style: FacingTokens.micro.copyWith(
                  color: FacingTokens.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp3),
          // 제목
          if (n.title.isNotEmpty)
            Text(n.title,
                style: FacingTokens.h2.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: FacingTokens.sp2),
          // 본문
          if (n.body.isNotEmpty)
            Text(n.body, style: FacingTokens.lead),
          // due
          if (n.dueDate != null && n.dueDate!.isNotEmpty) ...[
            const SizedBox(height: FacingTokens.sp4),
            Text('DUE',
                style: FacingTokens.sectionLabel),
            const SizedBox(height: 2),
            Text(n.dueDate!, style: FacingTokens.body),
          ],
          // structured items
          if (n.structured.isNotEmpty) ...[
            const SizedBox(height: FacingTokens.sp4),
            Text('PRESCRIPTION',
                style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            for (final it in n.structured)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
                child: Container(
                  padding: const EdgeInsets.all(FacingTokens.sp3),
                  decoration: BoxDecoration(
                    color: FacingTokens.surface,
                    border: Border.all(color: FacingTokens.border),
                    borderRadius: BorderRadius.circular(FacingTokens.r2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.displayLine(),
                          style: FacingTokens.body.copyWith(
                              fontWeight: FontWeight.w700)),
                      if (it.note != null && it.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(it.note!, style: FacingTokens.caption),
                        ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: FacingTokens.sp5),
          if (n.my != null) _MyActions(note: n, onAct: _act),
          if (n.recipients.isNotEmpty) _RecipientsList(items: n.recipients),
        ],
      ),
    );
  }
}

class _MyActions extends StatelessWidget {
  final CoachNote note;
  final Future<void> Function(String) onAct;
  const _MyActions({required this.note, required this.onAct});

  @override
  Widget build(BuildContext context) {
    final status = note.my!.status;
    if (status == 'completed' || status == 'declined') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(FacingTokens.sp3),
        decoration: BoxDecoration(
          border: Border.all(
            color: status == 'completed'
                ? FacingTokens.success
                : FacingTokens.muted,
          ),
          borderRadius: BorderRadius.circular(FacingTokens.r2),
        ),
        child: Text(
          status == 'completed' ? 'Completed.' : 'Declined.',
          textAlign: TextAlign.center,
          style: FacingTokens.body.copyWith(
            color: status == 'completed'
                ? FacingTokens.success
                : FacingTokens.muted,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      );
    }
    if (note.kind == 'note') {
      // 일반 쪽지는 read 후 별도 액션 없음.
      return const SizedBox.shrink();
    }
    // assignment — Accept / Decline / (이미 accepted면 Complete)
    final isAccepted = status == 'accepted';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAccepted)
          ElevatedButton(
            onPressed: () => onAct('complete'),
            child: const Text('Complete'),
          )
        else
          ElevatedButton(
            onPressed: () => onAct('accept'),
            child: const Text('Accept'),
          ),
        const SizedBox(height: FacingTokens.sp2),
        OutlinedButton(
          onPressed: () => onAct('decline'),
          child: const Text('Decline'),
        ),
      ],
    );
  }
}

class _RecipientsList extends StatelessWidget {
  final List<RecipientSummary> items;
  const _RecipientsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECIPIENTS · ${items.length}',
              style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          for (final r in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(r.hash.toUpperCase(),
                        style: FacingTokens.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: FacingTokens.tabular)),
                  ),
                  const SizedBox(width: FacingTokens.sp2),
                  Expanded(
                    child: Text(
                      r.status.toUpperCase(),
                      style: FacingTokens.micro.copyWith(
                        color: _statusColor(r.status),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return FacingTokens.success;
      case 'accepted':
        return FacingTokens.fg;
      case 'read':
        return FacingTokens.muted;
      case 'declined':
        return FacingTokens.muted;
      case 'sent':
      default:
        return FacingTokens.accent;
    }
  }
}
