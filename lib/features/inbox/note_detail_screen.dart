// v1.19 Sprint 20: Note 상세 — 페르소나 P0-4/P0-5/P0-6/P1-15 반영.
//
// 추가:
// - WHY 섹션 (rationale) 본문 위 고정 노출
// - Ask Coach 버튼 (자유 질문 → 코치에게 새 노트 발송)
// - Complete 모달 (set별 actual_load/reps/rpe 입력)
// - Decline 모달 (사유 chip 4개 + 자유 입력)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../core/unit_state.dart';
import '../../models/coach_note.dart';
import '../../widgets/avatar.dart';
import '../../widgets/hkit.dart';
import '../profile/profile_state.dart';
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

  Future<void> _accept() async {
    Haptic.medium();
    final ok = await context.read<InboxState>().accept(widget.noteId);
    if (!mounted) return;
    if (ok) {
      _toast('Accepted.');
      await _load();
    }
  }

  Future<void> _complete() async {
    Haptic.medium();
    final n = _note;
    if (n == null) return;
    final actuals = await _openCompleteModal(n);
    if (!mounted) return;
    if (actuals == null) return; // 취소
    final ok = await context
        .read<InboxState>()
        .complete(widget.noteId, actual: actuals);
    if (!mounted) return;
    if (ok) {
      _toast('Completed.');
      await _load();
    }
  }

  Future<void> _decline() async {
    Haptic.medium();
    final reason = await _openDeclineModal();
    if (!mounted) return;
    if (reason == null) return;
    // QA B-IN-12: 빈 reason 차단.
    if (reason.trim().isEmpty) {
      _toast('거절 사유 1개 이상 선택 필요.');
      return;
    }
    final ok =
        await context.read<InboxState>().decline(widget.noteId, reason: reason);
    if (!mounted) return;
    if (ok) {
      _toast('Declined.');
      await _load();
    }
  }

  Future<void> _ask() async {
    Haptic.medium();
    final body = await _openAskModal();
    if (!mounted) return;
    if (body == null || body.trim().isEmpty) return;
    final ok = await context.read<InboxState>().askCoach(widget.noteId, body);
    if (!mounted) return;
    if (ok) {
      _toast('Sent to Coach.');
      await _load();
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: HyphenTokens.surface,
      content: Text(msg, style: HyphenTokens.body),
    ));
  }

  Future<List<ActualSet>?> _openCompleteModal(CoachNote n) async {
    final controllers = <int, _ActualCtrls>{};
    final setsHint = n.structured.isNotEmpty
        ? (n.structured.first.sets ?? 1)
        : 1;
    final totalSets = setsHint.clamp(1, 10);
    for (int i = 0; i < totalSets; i++) {
      controllers[i] = _ActualCtrls();
    }
    final result = await showModalBottomSheet<List<ActualSet>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HyphenTokens.surface,
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
            const Text('실제 기록', style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp1),
            Text('세트별 실제 무게·횟수·RPE 기록 (선택).',
                style: HyphenTokens.caption),
            const SizedBox(height: HyphenTokens.sp3),
            for (int i = 0; i < totalSets; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text('SET ${i + 1}',
                          style: HyphenTokens.micro.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controllers[i]!.load,
                        decoration: const InputDecoration(
                          labelText: 'Load',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: HyphenTokens.sp2),
                    Expanded(
                      child: TextField(
                        controller: controllers[i]!.reps,
                        decoration: const InputDecoration(
                          labelText: 'Reps',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: HyphenTokens.sp2),
                    Expanded(
                      child: TextField(
                        controller: controllers[i]!.rpe,
                        decoration: const InputDecoration(
                          labelText: 'RPE',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: HyphenTokens.sp3),
            ElevatedButton(
              onPressed: () {
                final list = <ActualSet>[];
                controllers.forEach((idx, c) {
                  final load = double.tryParse(c.load.text.trim());
                  final reps = int.tryParse(c.reps.text.trim());
                  final rpe = double.tryParse(c.rpe.text.trim());
                  if (load != null || reps != null || rpe != null) {
                    list.add(ActualSet(
                      setIndex: idx,
                      actualLoad: load,
                      actualReps: reps,
                      rpe: rpe,
                    ));
                  }
                });
                Navigator.of(ctx).pop(list);
              },
              child: const Text('완료'),
            ),
            const SizedBox(height: HyphenTokens.sp1),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(<ActualSet>[]),
              child: const Text('기록 생략'),
            ),
          ],
        ),
      ),
    );
    for (final c in controllers.values) {
      c.dispose();
    }
    return result;
  }

  Future<String?> _openDeclineModal() async {
    String? selectedReason;
    final freeCtrl = TextEditingController();
    // v1.19 페르소나 P0-6: 회원이 거절 사유 선택 가능. P1-17: '부상' 선택 시 의료 메모 prefill.
    final injuryNotes = context.read<ProfileState>().injuryNotes;
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HyphenTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(HyphenTokens.r4)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (innerCtx, setSheet) {
        return Padding(
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
              const Text('거절 사유', style: HyphenTokens.sectionLabel),
              const SizedBox(height: HyphenTokens.sp1),
              Text('이유를 알려주면 코치가 다음 처방 조정.',
                  style: HyphenTokens.caption),
              const SizedBox(height: HyphenTokens.sp3),
              Wrap(
                spacing: HyphenTokens.sp2,
                runSpacing: HyphenTokens.sp2,
                children: [
                  // QA B-IN-13: V8 위반 — chip 라벨 영문 단독.
                  for (final r in const [
                    'INJURY',
                    'CONDITION',
                    'TIME',
                    'SUBSTITUTE',
                  ])
                    HkBadge(
                      r,
                      color: HyphenTokens.fg,
                      selected: selectedReason == r,
                      onTap: () {
                        setSheet(() {
                          selectedReason = r;
                          if (r == 'INJURY' &&
                              injuryNotes != null &&
                              injuryNotes.isNotEmpty &&
                              freeCtrl.text.isEmpty) {
                            freeCtrl.text = injuryNotes;
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: HyphenTokens.sp3),
              TextField(
                controller: freeCtrl,
                decoration: const InputDecoration(
                  labelText: '추가 설명 (선택)',
                ),
                maxLines: 3,
                maxLength: 300,
              ),
              const SizedBox(height: HyphenTokens.sp3),
              ElevatedButton(
                onPressed: () {
                  final parts = <String>[];
                  if (selectedReason != null) parts.add(selectedReason!);
                  final free = freeCtrl.text.trim();
                  if (free.isNotEmpty) parts.add(free);
                  Navigator.of(ctx).pop(parts.join(' · '));
                },
                child: const Text('거절'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('취소'),
              ),
            ],
          ),
        );
      }),
    );
    freeCtrl.dispose();
    return result;
  }

  Future<String?> _openAskModal() async {
    final ctrl = TextEditingController();
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HyphenTokens.surface,
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
            const Text('코치에게 질문', style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp1),
            Text('거절 대신 질문 1줄. 코치 인박스로 발송.',
                style: HyphenTokens.caption),
            const SizedBox(height: HyphenTokens.sp2),
            // 빠른 템플릿 chip.
            Wrap(
              spacing: HyphenTokens.sp1,
              children: [
                for (final t in const [
                  '무게 낮춰도 되나요?',
                  '동작 대체 가능?',
                  '날짜 조정 부탁',
                ])
                  HkBadge(
                    t,
                    color: HyphenTokens.fg,
                    onTap: () {
                      // QA B-ST-12: 같은 템플릿 중복 append 방지.
                      if (ctrl.text.contains(t)) return;
                      ctrl.text = ctrl.text.isEmpty ? t : '${ctrl.text}\n$t';
                    },
                  ),
              ],
            ),
            const SizedBox(height: HyphenTokens.sp2),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: '질문 내용',
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: HyphenTokens.sp3),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text),
              child: const Text('보내기'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('노트')),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: HyphenTokens.muted, strokeWidth: 2),
              )
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(HyphenTokens.sp4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(_error!, style: HyphenTokens.body),
                        const SizedBox(height: HyphenTokens.sp3),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _load();
                          },
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  )
                : _note != null
                    // QA B-INB-5: _note null 시 강제 unwrap 크래시 방지.
                    ? _buildBody(_note!)
                    : const Padding(
                        padding: EdgeInsets.all(HyphenTokens.sp4),
                        child: Text('노트를 열 수 없음.',
                            style: HyphenTokens.caption),
                      ),
      ),
    );
  }

  Widget _buildBody(CoachNote n) {
    final color = n.my?.isUnread == true
        ? HyphenTokens.accent
        : HyphenTokens.muted;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(HyphenTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 발신자 — Avatar + name + ago
          Row(
            children: [
              Avatar(
                hash: n.senderShort,
                displayName: n.senderName,
                colorHex: n.senderColor,
                size: 44,
              ),
              const SizedBox(width: HyphenTokens.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COACH',
                      style: HyphenTokens.microLabel.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(n.displayLabel(),
                        style: HyphenTokens.h3
                            .copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: HyphenTokens.sp2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(HyphenTokens.r1),
                ),
                child: Text(
                  n.isAuto
                      ? 'AUTO'
                      : (n.kind == 'assignment' ? 'ASSIGNMENT' : 'NOTE'),
                  style: HyphenTokens.microLabel.copyWith(
                    color: n.isAuto ? HyphenTokens.success : color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: HyphenTokens.sp4),
          if (n.title.isNotEmpty)
            Text(n.title,
                style: HyphenTokens.h3.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: HyphenTokens.sp2),
          // v1.19 페르소나 P0-4 (M1 송): WHY 섹션 — 본문 위 고정.
          if (n.rationale != null && n.rationale!.isNotEmpty) ...[
            const SizedBox(height: HyphenTokens.sp1),
            Container(
              decoration: BoxDecoration(
                color: HyphenTokens.surface,
                border: Border.all(color: HyphenTokens.border, width: 1),
                borderRadius: BorderRadius.circular(HyphenTokens.r2),
              ),
              clipBehavior: Clip.antiAlias,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 3, color: HyphenTokens.accent),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.all(HyphenTokens.sp3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('이유', style: HyphenTokens.sectionLabel),
                          const SizedBox(height: 4),
                          Text(n.rationale!, style: HyphenTokens.body),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: HyphenTokens.sp3),
          ],
          if (n.body.isNotEmpty)
            Text(n.body, style: HyphenTokens.lead),
          if (n.dueDate != null && n.dueDate!.isNotEmpty) ...[
            const SizedBox(height: HyphenTokens.sp4),
            Text('기한', style: HyphenTokens.sectionLabel),
            const SizedBox(height: 2),
            Text(n.dueDate!, style: HyphenTokens.body),
          ],
          if (n.dueStart != null && n.dueEnd != null) ...[
            const SizedBox(height: HyphenTokens.sp1),
            Text(
              '${n.dueStart} ~ ${n.dueEnd}',
              style: HyphenTokens.caption,
            ),
          ],
          if (n.structured.isNotEmpty) ...[
            const SizedBox(height: HyphenTokens.sp4),
            Text('처방', style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp2),
            for (final it in n.structured)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: HyphenTokens.sp1),
                child: Container(
                  padding: const EdgeInsets.all(HyphenTokens.sp3),
                  decoration: BoxDecoration(
                    color: HyphenTokens.surface,
                    border: Border.all(color: HyphenTokens.border),
                    borderRadius: BorderRadius.circular(HyphenTokens.r2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.displayLine(),
                          style: HyphenTokens.body.copyWith(
                              fontWeight: FontWeight.w700)),
                      if (it.alternateMovement != null &&
                          it.alternateMovement!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Substitute: ${it.alternateMovement!}',
                            style: HyphenTokens.caption.copyWith(
                              color: HyphenTokens.success,
                            ),
                          ),
                        ),
                      if (it.note != null && it.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(it.note!, style: HyphenTokens.caption),
                        ),
                    ],
                  ),
                ),
              ),
          ],
          // 액션 결과(actual / decline_reason) 표시.
          if (n.my?.actual.isNotEmpty == true) ...[
            const SizedBox(height: HyphenTokens.sp4),
            Text('기록됨', style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp1),
            for (final a in n.my!.actual)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  'SET ${a.setIndex + 1} · '
                  '${a.actualLoad != null ? '${a.actualLoad}${context.read<UnitState>().weightSuffix}' : '-'} · '
                  '${a.actualReps ?? '-'} reps · '
                  'RPE ${a.rpe ?? '-'}',
                  style: HyphenTokens.body,
                ),
              ),
          ],
          if (n.my?.declineReason != null &&
              n.my!.declineReason!.isNotEmpty) ...[
            const SizedBox(height: HyphenTokens.sp4),
            Text('거절 사유', style: HyphenTokens.sectionLabel),
            const SizedBox(height: 2),
            Text(n.my!.declineReason!, style: HyphenTokens.body),
          ],
          const SizedBox(height: HyphenTokens.sp5),
          if (n.my != null) _buildActions(n),
          if (n.recipients.isNotEmpty) _RecipientsList(items: n.recipients),
        ],
      ),
    );
  }

  Widget _buildActions(CoachNote n) {
    final status = n.my!.status;
    if (status == 'completed' || status == 'declined') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HyphenTokens.sp3),
        decoration: BoxDecoration(
          border: Border.all(
            color: status == 'completed'
                ? HyphenTokens.success
                : HyphenTokens.muted,
          ),
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
        ),
        child: Text(
          status == 'completed' ? 'Completed.' : 'Declined.',
          textAlign: TextAlign.center,
          style: HyphenTokens.body.copyWith(
            color: status == 'completed'
                ? HyphenTokens.success
                : HyphenTokens.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    if (n.kind == 'note') {
      // v1.19 페르소나 P1-15: 일반 노트도 Ask Coach 가능.
      if (n.isAuto) return const SizedBox.shrink(); // 자동 칭찬은 답장 불필요.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            onPressed: _ask,
            child: const Text('코치에게 질문'),
          ),
        ],
      );
    }
    final isAccepted = status == 'accepted';
    final isAsked = status == 'asked';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAccepted)
          ElevatedButton(
            onPressed: _complete,
            child: const Text('완료'),
          )
        else
          ElevatedButton(
            onPressed: _accept,
            child: const Text('수락'),
          ),
        const SizedBox(height: HyphenTokens.sp2),
        // v1.19 페르소나 P1-15: Accept/Decline 사이 Ask Coach.
        OutlinedButton(
          onPressed: _ask,
          child: Text(isAsked ? 'Asked · Ask again' : 'Ask Coach'),
        ),
        const SizedBox(height: HyphenTokens.sp2),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: HyphenTokens.fgSecondary),
          onPressed: _decline,
          child: const Text('거절'),
        ),
      ],
    );
  }
}

class _ActualCtrls {
  final TextEditingController load = TextEditingController();
  final TextEditingController reps = TextEditingController();
  final TextEditingController rpe = TextEditingController();
  void dispose() {
    load.dispose();
    reps.dispose();
    rpe.dispose();
  }
}

class _RecipientsList extends StatelessWidget {
  final List<RecipientSummary> items;
  const _RecipientsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: HyphenTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECIPIENTS · ${items.length}',
              style: HyphenTokens.sectionLabel),
          const SizedBox(height: HyphenTokens.sp2),
          for (final r in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Avatar(
                    hash: r.hash,
                    displayName: r.name,
                    colorHex: r.color,
                    size: 28,
                  ),
                  const SizedBox(width: HyphenTokens.sp2),
                  Expanded(
                    child: Text(r.displayLabel(),
                        style: HyphenTokens.body.copyWith(
                            fontWeight: FontWeight.w700)),
                  ),
                  Text(
                    r.status.toUpperCase(),
                    style: HyphenTokens.micro.copyWith(
                      color: _statusColor(r.status),
                      fontWeight: FontWeight.w800,
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
        return HyphenTokens.success;
      case 'accepted':
        return HyphenTokens.fg;
      case 'asked':
        return HyphenTokens.warning;
      case 'read':
        return HyphenTokens.muted;
      case 'declined':
        return HyphenTokens.muted;
      case 'sent':
      default:
        return HyphenTokens.accent;
    }
  }
}
