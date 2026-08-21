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
import '../../widgets/coach_badge.dart';
import '../../widgets/avatar.dart';
import '../../widgets/hkit.dart';
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
    // QA B-ML-3: 6개 controller dispose 보장.
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final capCtrl = TextEditingController();
    final colorCtrl = TextEditingController(); // '#RRGGBB'
    final notesCtrl = TextEditingController();
    final selectedDays = <int>{};
    final gym = context.read<GymState>().membership.gym;
    final repo = context.read<InboxRepository>();
    final messenger = HkSnack.of(context);
    if (gym == null) {
      nameCtrl.dispose();
      descCtrl.dispose();
      timeCtrl.dispose();
      capCtrl.dispose();
      colorCtrl.dispose();
      notesCtrl.dispose();
      return;
    }
    try {
      final ok = await showModalBottomSheet<bool>(
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('새 그룹', style: HyphenTokens.sectionLabel),
                const SizedBox(height: HyphenTokens.sp2),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: '예: 새벽반',
                  ),
                  maxLength: 80,
                ),
                const SizedBox(height: HyphenTokens.sp2),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLength: 200,
                ),
                const SizedBox(height: HyphenTokens.sp3),
                // v1.19 페르소나 P1-10 (C4): 요일·시간·정원·색상.
                Text('스케줄', style: HyphenTokens.sectionLabel),
                const SizedBox(height: HyphenTokens.sp1),
                Wrap(
                  spacing: HyphenTokens.sp1,
                  children: [
                    for (int d = 0; d < 7; d++)
                      HkBadge(
                        const ['월', '화', '수', '목', '금', '토', '일'][d],
                        color: HyphenTokens.fg,
                        selected: selectedDays.contains(d),
                        onTap: () => setSheet(() {
                          if (selectedDays.contains(d)) {
                            selectedDays.remove(d);
                          } else {
                            selectedDays.add(d);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: HyphenTokens.sp2),
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
                  const SizedBox(width: HyphenTokens.sp2),
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
                const SizedBox(height: HyphenTokens.sp2),
                TextField(
                  controller: colorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Color (#RRGGBB)',
                    hintText: '#EE2B2B',
                  ),
                ),
                const SizedBox(height: HyphenTokens.sp2),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: '메모 (선택)',
                  ),
                  maxLength: 500,
                ),
                const SizedBox(height: HyphenTokens.sp3),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('만들기'),
                ),
              ],
            ),
          ),
        );
      }),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      messenger.fail('그룹 이름 필요.');
      return;
    }
    // v1.19 차수 5 fix (B-IN-3,4,6): time/capacity/color 형식 검증.
    final timeText = timeCtrl.text.trim();
    if (timeText.isNotEmpty &&
        !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(timeText)) {
      messenger.fail('시간 형식 오류 (HH:MM).');
      return;
    }
    final capText = capCtrl.text.trim();
    if (capText.isNotEmpty) {
      final cap = int.tryParse(capText);
      if (cap == null || cap <= 0) {
        messenger.fail('정원은 양수만.');
        return;
      }
    }
    final colorText = colorCtrl.text.trim();
    if (colorText.isNotEmpty &&
        !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(colorText)) {
      messenger.fail('색상 형식 오류 (#RRGGBB).');
      return;
    }
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
      messenger.fail('생성 실패: ${e.messageKo}');
    }
    } finally {
      nameCtrl.dispose();
      descCtrl.dispose();
      timeCtrl.dispose();
      capCtrl.dispose();
      colorCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  Future<void> _openAddMember(CoachGroup g) async {
    Haptic.light();
    // QA B-ML-4: hashCtrl dispose 보장.
    final hashCtrl = TextEditingController();
    final gym = context.read<GymState>().membership.gym;
    final repo = context.read<InboxRepository>();
    final messenger = HkSnack.of(context);
    if (gym == null) {
      hashCtrl.dispose();
      return;
    }
    try {
      final ok = await showModalBottomSheet<bool>(
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
            Text('회원 추가 · ${g.name.toUpperCase()}',
                style: HyphenTokens.sectionLabel),
            const SizedBox(height: HyphenTokens.sp2),
            TextField(
              controller: hashCtrl,
              decoration: const InputDecoration(
                labelText: 'Member device hash',
                hintText: '64자 SHA-256',
              ),
            ),
            const SizedBox(height: HyphenTokens.sp1),
            const Text(
              '※ 멤버 선택 UI 는 추후 지원. 현재는 코드 직접 입력.',
              style: HyphenTokens.micro,
            ),
            const SizedBox(height: HyphenTokens.sp3),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final h = hashCtrl.text.trim();
    // v1.19 차수 5 (B-IN-5): hex 형식 + 길이 검증.
    if (h.length < 8 || !RegExp(r'^[a-f0-9]+$').hasMatch(h)) {
      messenger.fail('Hash 형식 오류 (hex 8자 이상).');
      return;
    }
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
      messenger.fail('추가 실패: ${e.messageKo}');
    }
    } finally {
      hashCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹'),
        actions: [
          const CoachBadgeAction(),
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
                    color: HyphenTokens.muted, strokeWidth: 2),
              );
            }
            // QA B-FB-1: hasError 분기.
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(HyphenTokens.sp4),
                  child: Text(
                    '그룹 목록 로딩 실패. 새로고침 필요.',
                    style: HyphenTokens.caption
                        .copyWith(color: HyphenTokens.warning),
                  ),
                ),
              );
            }
            final items = snap.data ?? const [];
            if (items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('그룹 없음', style: HyphenTokens.sectionLabel),
                    SizedBox(height: HyphenTokens.sp1),
                    Text('우상단 + 버튼으로 추가.', style: HyphenTokens.caption),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(HyphenTokens.sp4),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: HyphenTokens.sp3),
              itemBuilder: (_, i) {
                final g = items[i];
                final color = Avatar.parseHex(g.colorHex, HyphenTokens.muted);
                final slotLabel = g.slotLabel();
                final cap = g.capacity != null
                    ? '${g.memberCount}/${g.capacity}'
                    : '${g.memberCount}';
                return Container(
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
                        Container(width: 4, color: color),
                        Expanded(child: Padding(
                          padding: const EdgeInsets.all(HyphenTokens.sp3),
                          child: _buildGroupCardBody(g, color, slotLabel, cap),
                        )),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HyphenTokens.accent,
        foregroundColor: HyphenTokens.fg,
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('새 그룹'),
      ),
    );
  }

  Widget _buildGroupCardBody(
    CoachGroup g, Color color, String slotLabel, String cap,
  ) {
    return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(g.name,
                                style: HyphenTokens.h3.copyWith(
                                    fontWeight: FontWeight.w800)),
                          ),
                          Text('$cap명',
                              style: HyphenTokens.micro),
                        ],
                      ),
                      if (slotLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(slotLabel,
                            style: HyphenTokens.micro.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            )),
                      ],
                      if (g.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(g.description,
                            style: HyphenTokens.caption),
                      ],
                      const SizedBox(height: HyphenTokens.sp2),
                      OutlinedButton(
                        onPressed: () => _openAddMember(g),
                        child: const Text('회원 추가'),
                      ),
                    ],
                  );
  }
}
