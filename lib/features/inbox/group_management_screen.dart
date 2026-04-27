// v1.18 Sprint 19: 그룹 생성·멤버 추가/제거 (코치 전용).
//
// MVP: 그룹 이름 + 설명만. 멤버 추가는 device hash 입력 (간이).
// Phase 2: GymMembers 리스트에서 체크박스 일괄 추가 / 그룹 색상·아이콘.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/coach_group.dart';
import '../../widgets/avatar.dart';
import '../gym/gym_state.dart';
import 'inbox_repository.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  Future<List<CoachGroup>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final gym = context.read<GymState>().membership.gym;
    if (gym == null) return;
    setState(() {
      _future = context.read<InboxRepository>().listGroups(gym.id);
    });
  }

  Future<void> _openCreate() async {
    Haptic.light();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final capCtrl = TextEditingController();
    final colorCtrl = TextEditingController(); // '#RRGGBB'
    final notesCtrl = TextEditingController();
    final selectedDays = <int>{};
    final gym = context.read<GymState>().membership.gym;
    final repo = context.read<InboxRepository>();
    final messenger = ScaffoldMessenger.of(context);
    if (gym == null) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FacingTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FacingTokens.r4)),
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
                const Text('NEW GROUP', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp2),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: '예: 새벽반',
                  ),
                  maxLength: 80,
                ),
                const SizedBox(height: FacingTokens.sp2),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (선택)',
                  ),
                  maxLength: 200,
                ),
                const SizedBox(height: FacingTokens.sp3),
                // v1.19 페르소나 P1-10 (C4): 요일·시간·정원·색상.
                Text('SCHEDULE', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp1),
                Wrap(
                  spacing: FacingTokens.sp1,
                  children: [
                    for (int d = 0; d < 7; d++)
                      ChoiceChip(
                        label: Text(const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d]),
                        selected: selectedDays.contains(d),
                        backgroundColor: FacingTokens.surface,
                        selectedColor: FacingTokens.accent,
                        onSelected: (sel) => setSheet(() {
                          if (sel) {
                            selectedDays.add(d);
                          } else {
                            selectedDays.remove(d);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: FacingTokens.sp2),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: timeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Time (HH:MM)',
                        hintText: '06:00',
                      ),
                    ),
                  ),
                  const SizedBox(width: FacingTokens.sp2),
                  Expanded(
                    child: TextField(
                      controller: capCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Capacity',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ]),
                const SizedBox(height: FacingTokens.sp2),
                TextField(
                  controller: colorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Color (#RRGGBB, 선택)',
                    hintText: '#EE2B2B',
                  ),
                ),
                const SizedBox(height: FacingTokens.sp2),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (선택)',
                  ),
                  maxLength: 500,
                ),
                const SizedBox(height: FacingTokens.sp3),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        );
      }),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      await repo.createGroup(
        gymId: gym.id,
        name: name,
        description: descCtrl.text.trim(),
        colorHex: colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim(),
        capacity: int.tryParse(capCtrl.text.trim()),
        weekdaySlot: selectedDays.toList()..sort(),
        timeSlot: timeCtrl.text.trim().isEmpty ? null : timeCtrl.text.trim(),
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      Haptic.medium();
      if (!mounted) return;
      _reload();
    } on AppException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('생성 실패: ${e.messageKo}')),
      );
    }
  }

  Future<void> _openAddMember(CoachGroup g) async {
    Haptic.light();
    final hashCtrl = TextEditingController();
    final gym = context.read<GymState>().membership.gym;
    final repo = context.read<InboxRepository>();
    final messenger = ScaffoldMessenger.of(context);
    if (gym == null) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FacingTokens.surface,
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
            Text('ADD MEMBER · ${g.name.toUpperCase()}',
                style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            TextField(
              controller: hashCtrl,
              decoration: const InputDecoration(
                labelText: 'Member device hash',
                hintText: '64자 SHA-256',
              ),
            ),
            const SizedBox(height: FacingTokens.sp1),
            const Text(
              '※ Phase 2: 멤버 리스트에서 체크박스 선택. 현재는 hash 직접 입력.',
              style: FacingTokens.micro,
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
    final h = hashCtrl.text.trim();
    if (h.isEmpty) return;
    try {
      await repo.addGroupMember(
        gymId: gym.id,
        groupId: g.id,
        memberHash: h,
      );
      Haptic.medium();
      if (!mounted) return;
      _reload();
    } on AppException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('추가 실패: ${e.messageKo}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GROUPS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<CoachGroup>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                    color: FacingTokens.muted, strokeWidth: 2),
              );
            }
            final items = snap.data ?? const [];
            if (items.isEmpty) {
              return const Center(
                child: Text('그룹 없음. + 버튼으로 추가.',
                    style: FacingTokens.caption),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(FacingTokens.sp4),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: FacingTokens.sp3),
              itemBuilder: (_, i) {
                final g = items[i];
                final color = Avatar.parseHex(g.colorHex, FacingTokens.muted);
                final slotLabel = g.slotLabel();
                final cap = g.capacity != null
                    ? '${g.memberCount}/${g.capacity}'
                    : '${g.memberCount}';
                return Container(
                  decoration: BoxDecoration(
                    color: FacingTokens.surface,
                    border: Border(
                      left: BorderSide(color: color, width: 4),
                      top: const BorderSide(color: FacingTokens.border),
                      right: const BorderSide(color: FacingTokens.border),
                      bottom: const BorderSide(color: FacingTokens.border),
                    ),
                    borderRadius: BorderRadius.circular(FacingTokens.r2),
                  ),
                  padding: const EdgeInsets.all(FacingTokens.sp3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(g.name,
                                style: FacingTokens.h3.copyWith(
                                    fontWeight: FontWeight.w800)),
                          ),
                          Text('$cap members',
                              style: FacingTokens.micro),
                        ],
                      ),
                      if (slotLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(slotLabel,
                            style: FacingTokens.micro.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            )),
                      ],
                      if (g.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(g.description,
                            style: FacingTokens.caption),
                      ],
                      const SizedBox(height: FacingTokens.sp2),
                      OutlinedButton(
                        onPressed: () => _openAddMember(g),
                        child: const Text('Add Member'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: FacingTokens.accent,
        foregroundColor: FacingTokens.fg,
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
    );
  }
}
