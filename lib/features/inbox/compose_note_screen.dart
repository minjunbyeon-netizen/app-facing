// v1.18 Sprint 19: 코치 발송 화면.
// Target: Individual / Group / All
// Kind: Note / Assignment
// Assignment 시 structured items 추가 가능.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/coach_group.dart';
import '../../models/coach_note.dart';
import '../gym/gym_state.dart';
import 'inbox_repository.dart';

class ComposeNoteScreen extends StatefulWidget {
  const ComposeNoteScreen({super.key});

  @override
  State<ComposeNoteScreen> createState() => _ComposeNoteScreenState();
}

class _ComposeNoteScreenState extends State<ComposeNoteScreen> {
  String _targetType = 'group';
  CoachGroup? _selectedGroup;
  final _individualHashCtrl = TextEditingController();
  String _kind = 'note';
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _dueCtrl = TextEditingController(); // YYYY-MM-DD

  final List<AssignmentItem> _items = [];
  bool _sending = false;
  Future<List<CoachGroup>>? _groupsFuture;

  @override
  void initState() {
    super.initState();
    final gym = context.read<GymState>().membership.gym;
    if (gym != null) {
      _groupsFuture = context.read<InboxRepository>().listGroups(gym.id);
    }
  }

  @override
  void dispose() {
    _individualHashCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _dueCtrl.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    Haptic.light();
    final movementCtrl = TextEditingController();
    final setsCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    final loadCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FacingTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(FacingTokens.r4),
        ),
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
            const Text('ADD MOVEMENT', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            TextField(
              controller: movementCtrl,
              decoration: const InputDecoration(
                labelText: 'Movement (slug)',
                hintText: 'back-squat / clean / run',
              ),
            ),
            const SizedBox(height: FacingTokens.sp2),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: setsCtrl,
                  decoration: const InputDecoration(labelText: 'Sets'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: FacingTokens.sp2),
              Expanded(
                child: TextField(
                  controller: repsCtrl,
                  decoration: const InputDecoration(labelText: 'Reps'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: FacingTokens.sp2),
              Expanded(
                child: TextField(
                  controller: loadCtrl,
                  decoration: const InputDecoration(labelText: 'Load %'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ]),
            const SizedBox(height: FacingTokens.sp2),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (선택)'),
              maxLength: 100,
            ),
            const SizedBox(height: FacingTokens.sp3),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final slug = movementCtrl.text.trim();
    if (slug.isEmpty) return;
    setState(() {
      _items.add(AssignmentItem(
        movementSlug: slug,
        sets: int.tryParse(setsCtrl.text.trim()),
        reps: int.tryParse(repsCtrl.text.trim()),
        loadPct: () {
          final raw = double.tryParse(loadCtrl.text.trim());
          if (raw == null) return null;
          return raw > 1.5 ? raw / 100 : raw;
        }(),
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      ));
    });
  }

  Future<void> _send() async {
    final gym = context.read<GymState>().membership.gym;
    if (gym == null) return;
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty && _titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용 또는 제목 필요.')),
      );
      return;
    }
    String? targetId;
    if (_targetType == 'individual') {
      targetId = _individualHashCtrl.text.trim();
      if (targetId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수신자 hash 필요.')),
        );
        return;
      }
    } else if (_targetType == 'group') {
      if (_selectedGroup == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('그룹 선택 필요.')),
        );
        return;
      }
      targetId = _selectedGroup!.id.toString();
    }
    setState(() => _sending = true);
    Haptic.medium();
    try {
      await context.read<InboxRepository>().postNote(
            gymId: gym.id,
            targetType: _targetType,
            targetId: targetId,
            kind: _kind,
            title: _titleCtrl.text.trim(),
            body: body,
            structured: _kind == 'assignment' ? _items : const [],
            dueDate: _dueCtrl.text.trim().isEmpty ? null : _dueCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    return Scaffold(
      appBar: AppBar(title: const Text('NEW NOTE')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('TARGET', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp2),
              Wrap(
                spacing: FacingTokens.sp2,
                children: [
                  for (final t in const ['individual', 'group', 'all'])
                    ChoiceChip(
                      label: Text(t.toUpperCase()),
                      selected: _targetType == t,
                      backgroundColor: FacingTokens.surface,
                      selectedColor: FacingTokens.accent,
                      onSelected: (_) => setState(() => _targetType = t),
                    ),
                ],
              ),
              const SizedBox(height: FacingTokens.sp3),
              if (_targetType == 'individual')
                TextField(
                  controller: _individualHashCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Member device hash',
                    hintText: '8자 이상',
                  ),
                ),
              if (_targetType == 'group') _buildGroupPicker(),
              const SizedBox(height: FacingTokens.sp4),
              const Text('KIND', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp2),
              Wrap(
                spacing: FacingTokens.sp2,
                children: [
                  for (final k in const ['note', 'assignment'])
                    ChoiceChip(
                      label: Text(k.toUpperCase()),
                      selected: _kind == k,
                      backgroundColor: FacingTokens.surface,
                      selectedColor: FacingTokens.accent,
                      onSelected: (_) => setState(() => _kind = k),
                    ),
                ],
              ),
              const SizedBox(height: FacingTokens.sp4),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: '예: Squat 5×5 @ 70%',
                ),
                maxLength: 120,
              ),
              const SizedBox(height: FacingTokens.sp2),
              TextField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  hintText: '코치 메시지',
                ),
                maxLines: 5,
                maxLength: 2000,
              ),
              if (_kind == 'assignment') ...[
                const SizedBox(height: FacingTokens.sp4),
                Row(
                  children: [
                    const Expanded(
                      child: Text('PRESCRIPTION',
                          style: FacingTokens.sectionLabel),
                    ),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: FacingTokens.sp2),
                    child: Text('운동 항목 없음. 자유 텍스트 쪽지로도 발송 가능.',
                        style: FacingTokens.caption),
                  )
                else
                  for (int i = 0; i < _items.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: FacingTokens.sp1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: FacingTokens.surface,
                          border: Border.all(color: FacingTokens.border),
                          borderRadius:
                              BorderRadius.circular(FacingTokens.r2),
                        ),
                        padding: const EdgeInsets.all(FacingTokens.sp3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(_items[i].displayLine(),
                                  style: FacingTokens.body),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () =>
                                  setState(() => _items.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: FacingTokens.sp3),
                TextField(
                  controller: _dueCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Due date (YYYY-MM-DD, 선택)',
                  ),
                ),
              ],
              const SizedBox(height: FacingTokens.sp5),
              ElevatedButton(
                onPressed: _sending ? null : _send,
                child: Text(_sending ? 'Sending…' : 'Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupPicker() {
    return FutureBuilder<List<CoachGroup>>(
      future: _groupsFuture,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: FacingTokens.sp2),
            child: Text('Loading groups.', style: FacingTokens.caption),
          );
        }
        final groups = snap.data ?? const [];
        if (groups.isEmpty) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('그룹 없음. 먼저 그룹 생성 필요.',
                    style: FacingTokens.caption),
                const SizedBox(height: FacingTokens.sp2),
                OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Manage Groups'),
                ),
              ],
            ),
          );
        }
        return Wrap(
          spacing: FacingTokens.sp2,
          runSpacing: FacingTokens.sp2,
          children: [
            for (final g in groups)
              ChoiceChip(
                label: Text('${g.name} · ${g.memberCount}'),
                selected: _selectedGroup?.id == g.id,
                backgroundColor: FacingTokens.surface,
                selectedColor: FacingTokens.accent,
                onSelected: (_) => setState(() => _selectedGroup = g),
              ),
          ],
        );
      },
    );
  }
}
