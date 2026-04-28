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
import 'group_management_screen.dart';
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
  // v1.19 페르소나 P0-4 (M1 송): WHY rationale 입력.
  final _rationaleCtrl = TextEditingController();
  final _dueCtrl = TextEditingController(); // YYYY-MM-DD
  // v1.19 페르소나 P2-26 (M6 이): 윈도우형 due (선택).
  final _dueStartCtrl = TextEditingController();
  final _dueEndCtrl = TextEditingController();

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
    _rationaleCtrl.dispose();
    _dueCtrl.dispose();
    _dueStartCtrl.dispose();
    _dueEndCtrl.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    Haptic.light();
    // QA B-ML-2: 9개 controller 모달 종료 후 dispose 보장.
    final movementCtrl = TextEditingController();
    final altCtrl = TextEditingController();
    final setsCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    final loadCtrl = TextEditingController();
    final restCtrl = TextEditingController();
    final tempoCtrl = TextEditingController();
    final timecapCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String unit = 'pct_1rm';
    bool? ok;
    try {
      ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FacingTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(FacingTokens.r4),
        ),
      ),
      builder: (ctx) => StatefulBuilder(builder: (innerCtx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(
            left: FacingTokens.sp4,
            right: FacingTokens.sp4,
            top: FacingTokens.sp4,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + FacingTokens.sp4,
          ),
          child: SingleChildScrollView(
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
                // v1.19 페르소나 P1-17: Substitute 옵션.
                TextField(
                  controller: altCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Substitute (선택, 부상자용)',
                    hintText: '예: dumbbell-thruster',
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
                ]),
                const SizedBox(height: FacingTokens.sp3),
                // v1.19 페르소나 P0-3: Load 단위 picker.
                Text('LOAD UNIT', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp1),
                Wrap(
                  spacing: FacingTokens.sp1,
                  runSpacing: FacingTokens.sp1,
                  children: [
                    for (final u in const [
                      ('pct_1rm', '%1RM'),
                      ('rpe', 'RPE'),
                      ('kg', 'kg'),
                      ('lb', 'lb'),
                      ('sec_per_500m', 'sec/500m'),
                      ('feel', 'feel'),
                    ])
                      ChoiceChip(
                        label: Text(u.$2),
                        selected: unit == u.$1,
                        backgroundColor: FacingTokens.surface,
                        selectedColor: FacingTokens.accent,
                        onSelected: (_) => setSheet(() => unit = u.$1),
                      ),
                  ],
                ),
                const SizedBox(height: FacingTokens.sp2),
                TextField(
                  controller: loadCtrl,
                  decoration: InputDecoration(
                    labelText: _loadHint(unit),
                    hintText: _loadHint(unit),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                ),
                const SizedBox(height: FacingTokens.sp2),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: restCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Rest (s)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: FacingTokens.sp2),
                  Expanded(
                    child: TextField(
                      controller: tempoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tempo',
                        hintText: '3-1-1-0',
                      ),
                    ),
                  ),
                  const SizedBox(width: FacingTokens.sp2),
                  Expanded(
                    child: TextField(
                      controller: timecapCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Time cap (s)'),
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
      }),
    );
    if (ok != true) return;
    final slug = movementCtrl.text.trim();
    if (slug.isEmpty) return;
    setState(() {
      _items.add(AssignmentItem(
        movementSlug: slug,
        alternateMovement: altCtrl.text.trim().isEmpty
            ? null
            : altCtrl.text.trim(),
        sets: int.tryParse(setsCtrl.text.trim()),
        reps: int.tryParse(repsCtrl.text.trim()),
        loadValue: () {
          final raw = double.tryParse(loadCtrl.text.trim());
          if (raw == null) return null;
          // pct_1rm 입력 50 → 0.5 자동 변환.
          if (unit == 'pct_1rm' && raw > 1.5) return raw / 100;
          return raw;
        }(),
        unit: unit,
        restSec: int.tryParse(restCtrl.text.trim()),
        tempoPattern: tempoCtrl.text.trim().isEmpty
            ? null
            : tempoCtrl.text.trim(),
        timeCapSec: int.tryParse(timecapCtrl.text.trim()),
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      ));
    });
    } finally {
      movementCtrl.dispose();
      altCtrl.dispose();
      setsCtrl.dispose();
      repsCtrl.dispose();
      loadCtrl.dispose();
      restCtrl.dispose();
      tempoCtrl.dispose();
      timecapCtrl.dispose();
      noteCtrl.dispose();
    }
  }

  String _loadHint(String unit) {
    switch (unit) {
      case 'pct_1rm':
        return '%1RM (예: 75)';
      case 'rpe':
        return 'RPE 1~10 (예: 7.5)';
      case 'kg':
        return 'kg';
      case 'lb':
        return 'lb';
      case 'sec_per_500m':
        return 'sec/500m';
      case 'feel':
        return '0=lighter 1=same 2=heavier';
      default:
        return 'Load';
    }
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
      // v1.19 차수 5 fix (B-IN-1): 디바이스 hash는 SHA-256 hex 64자 또는 prefix(8~64자).
      if (targetId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수신자 hash 필요.')),
        );
        return;
      }
      if (targetId.length < 8 || !RegExp(r'^[a-f0-9]+$').hasMatch(targetId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('hash 형식 오류 (hex 8자 이상).')),
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
    // v1.19 차수 5 fix (B-IN-2): YYYY-MM-DD 형식 검증.
    final dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    final dueDate = _dueCtrl.text.trim();
    final dueStart = _dueStartCtrl.text.trim();
    final dueEnd = _dueEndCtrl.text.trim();
    for (final entry in [
      ['Due Date', dueDate],
      ['Due Start', dueStart],
      ['Due End', dueEnd],
    ]) {
      if (entry[1].isNotEmpty && !dateRe.hasMatch(entry[1])) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entry[0]} 형식 오류 (YYYY-MM-DD).')),
        );
        return;
      }
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
            rationale: _rationaleCtrl.text.trim().isEmpty
                ? null
                : _rationaleCtrl.text.trim(),
            structured: _kind == 'assignment' ? _items : const [],
            dueDate: _dueCtrl.text.trim().isEmpty ? null : _dueCtrl.text.trim(),
            dueStart: _dueStartCtrl.text.trim().isEmpty
                ? null
                : _dueStartCtrl.text.trim(),
            dueEnd: _dueEndCtrl.text.trim().isEmpty
                ? null
                : _dueEndCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전송 실패: ${e.messageKo}')),
      );
    } catch (e) {
      // /go Tier 3: generic catch — 타임아웃/예외 시 사용자 알림.
      debugPrint('[ComposeNote._send] $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전송 실패. 다시 시도.')),
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
              const SizedBox(height: FacingTokens.sp3),
              // v1.19 페르소나 P0-4 (M1 송): WHY rationale.
              TextField(
                controller: _rationaleCtrl,
                decoration: InputDecoration(
                  labelText: _kind == 'assignment' ? 'Why this · 권장' : 'Why this · 선택',
                  hintText: '예: 지난 Fran 4R grip 풀림 → unbroken 회복',
                ),
                maxLines: 3,
                maxLength: 500,
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
                const SizedBox(height: FacingTokens.sp2),
                // v1.19 페르소나 P2-26 (M6 이): 윈도우형 due (이번 주 내 1회).
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _dueStartCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Due start (선택)',
                      ),
                    ),
                  ),
                  const SizedBox(width: FacingTokens.sp2),
                  Expanded(
                    child: TextField(
                      controller: _dueEndCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Due end (선택)',
                      ),
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: FacingTokens.sp5),
              ElevatedButton(
                onPressed: _sending ? null : _send,
                child: Text(_sending ? 'Sending.' : 'Send'),
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
        // QA B-FB-2: hasError 분기 추가.
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
            child: Text(
              '그룹 목록 로딩 실패. 새로고침 필요.',
              style: FacingTokens.caption.copyWith(color: FacingTokens.warning),
            ),
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
                  // QA B-NAV-1: 작성 화면을 닫는 대신 GroupManagement 화면 push.
                  onPressed: () => Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => const GroupManagementScreen(),
                    ),
                  ),
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
