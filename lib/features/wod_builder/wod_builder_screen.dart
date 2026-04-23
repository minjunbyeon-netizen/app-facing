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
        title: const Text('Build WOD'),
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
              const Text('WOD Type', style: FacingTokens.caption),
              const SizedBox(height: FacingTokens.sp2),
              _TypeSegmented(draft: draft),
              const SizedBox(height: FacingTokens.sp5),
              Row(
                children: [
                  Expanded(
                    child: _MiniField(
                      label: 'Time Cap (min)',
                      controller: timeCapCtrl,
                      onChanged: (v) {
                        final m = int.tryParse(v);
                        draft.setTimeCap(m == null ? null : m * 60);
                      },
                    ),
                  ),
                  const SizedBox(width: FacingTokens.sp3),
                  if (draft.type != WodType.forTime)
                    Expanded(
                      child: _MiniField(
                        label: draft.type == WodType.amrap ? 'Rounds (opt)' : 'Minutes',
                        controller: roundsCtrl,
                        onChanged: (v) => draft.setRounds(int.tryParse(v)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: FacingTokens.sp6),
              const Text('Movements', style: FacingTokens.caption),
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

class _TypeSegmented extends StatelessWidget {
  final WodDraftState draft;
  const _TypeSegmented({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: WodType.values.map((t) {
        final selected = t == draft.type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: FacingTokens.sp2),
            child: InkWell(
              onTap: () => draft.setType(t),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? FacingTokens.fg : FacingTokens.bg,
                  border: Border.all(
                    color: selected ? FacingTokens.fg : FacingTokens.border,
                  ),
                  borderRadius: BorderRadius.circular(FacingTokens.r2),
                ),
                child: Text(
                  t.labelKo,
                  style: FacingTokens.body.copyWith(
                    color: selected ? FacingTokens.bg : FacingTokens.fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

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
        border: Border.all(color: FacingTokens.border),
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$index.', style: FacingTokens.body),
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
