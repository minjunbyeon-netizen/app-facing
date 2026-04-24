import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/movements_repository.dart';
import '../../core/theme.dart';
import '../../models/movement.dart';
import 'movement_picker.dart';
import 'wod_draft_state.dart';

class WodBuilderScreen extends StatefulWidget {
  const WodBuilderScreen({super.key});

  @override
  State<WodBuilderScreen> createState() => _WodBuilderScreenState();
}

class _WodBuilderScreenState extends State<WodBuilderScreen> {
  Future<List<MovementCategory>>? _future;
  final _timeCapCtrl = TextEditingController();
  final _roundsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = context.read<MovementsRepository>().fetchCategoriesList();
    // v1.16: Custom WOD은 for_time 고정. 진입 시 draft type 강제.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = context.read<WodDraftState>();
      if (draft.type != WodType.forTime) draft.setType(WodType.forTime);
    });
  }

  @override
  void dispose() {
    _timeCapCtrl.dispose();
    _roundsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<WodDraftState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('CUSTOM WOD'),
        actions: [
          TextButton(
            onPressed: draft.isEmpty ? null : () => draft.clear(),
            child: const Text('Reset'),
          ),
        ],
      ),
      body: FutureBuilder<List<MovementCategory>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: Text('Loading', style: FacingTokens.body));
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}', style: FacingTokens.body));
          }
          final cats = snap.data ?? [];
          return _Body(
            draft: draft,
            cats: cats,
            timeCapCtrl: _timeCapCtrl,
            roundsCtrl: _roundsCtrl,
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final WodDraftState draft;
  final List<MovementCategory> cats;
  final TextEditingController timeCapCtrl;
  final TextEditingController roundsCtrl;
  const _Body({
    required this.draft,
    required this.cats,
    required this.timeCapCtrl,
    required this.roundsCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              FacingTokens.sp4, FacingTokens.sp4, FacingTokens.sp4, FacingTokens.sp4,
            ),
            children: [
              // v1.16: Custom WOD = For Time 전용. AMRAP/EMOM은 Girls/Hero preset로.
              const Text('FOR TIME', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp1),
              const Text('동작·횟수·중량 설정 후 Split 계산.',
                  style: FacingTokens.caption),
              const SizedBox(height: FacingTokens.sp4),
              _MiniField(
                label: 'Time Cap (min)',
                controller: timeCapCtrl,
                onChanged: (v) {
                  final m = int.tryParse(v);
                  draft.setTimeCap(m == null ? null : m * 60);
                },
              ),
              const SizedBox(height: FacingTokens.sp6),
              const Text('MOVEMENTS', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp2),
              if (draft.items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(FacingTokens.sp4),
                  decoration: BoxDecoration(
                    color: FacingTokens.surface,
                    borderRadius: BorderRadius.circular(FacingTokens.r2),
                  ),
                  child: const Text(
                    '아래 버튼으로 동작 추가.',
                    style: FacingTokens.caption,
                  ),
                )
              else
                ...List.generate(draft.items.length, (i) {
                  final item = draft.items[i];
                  return Dismissible(
                    key: ValueKey('${item.movement.slug}_$i'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => draft.removeItemAt(i),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: FacingTokens.sp4),
                      color: FacingTokens.border,
                      child: const Text('Delete', style: FacingTokens.body),
                    ),
                    child: _ItemRow(index: i + 1, item: item),
                  );
                }),
              const SizedBox(height: FacingTokens.sp3),
              OutlinedButton(
                onPressed: () async {
                  final added = await showMovementPicker(context, cats);
                  if (added != null) draft.addItem(added);
                },
                child: const Text('Add Movement'),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(FacingTokens.sp4),
            child: ElevatedButton(
              onPressed: draft.isEmpty
                  ? null
                  : () => Navigator.of(context).pushNamed('/result'),
              child: const Text('Calculate'),
            ),
          ),
        ),
      ],
    );
  }
}

// v1.16: _TypeSegmented 제거 (AMRAP/EMOM 삭제, for_time 고정).

class _MiniField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _MiniField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}

class _ItemRow extends StatelessWidget {
  final int index;
  final WodItemDraft item;
  const _ItemRow({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp2),
      padding: const EdgeInsets.all(FacingTokens.sp3),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: FacingTokens.sp6,
            child: Text('$index.', style: FacingTokens.body.copyWith(
              color: FacingTokens.muted,
              fontFeatures: FacingTokens.tabular,
            )),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.movement.nameKo,
                  style: FacingTokens.body.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(item.summary, style: FacingTokens.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
