import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/unit_state.dart';
import '../../models/movement.dart';
import 'wod_draft_state.dart';

Future<WodItemDraft?> showMovementPicker(
  BuildContext context,
  List<MovementCategory> categories,
) async {
  final picked = await showModalBottomSheet<Movement>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FacingTokens.bg,
    builder: (_) => _CategorySheet(categories: categories),
  );
  if (picked == null || !context.mounted) return null;
  return await showModalBottomSheet<WodItemDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FacingTokens.bg,
    builder: (_) => _ItemParamsSheet(movement: picked),
  );
}

class _CategorySheet extends StatefulWidget {
  final List<MovementCategory> categories;
  const _CategorySheet({required this.categories});

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  int _catIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.categories[_catIndex];
    // v1.16 Sprint 7a: 검색 필터 (카테고리 전체 or 현재 카테고리 내).
    final List<Movement> filtered;
    if (_query.isEmpty) {
      filtered = cat.movements;
    } else {
      final q = _query.toLowerCase();
      // 검색 중엔 전 카테고리 합쳐서 필터링.
      filtered = widget.categories
          .expand((c) => c.movements)
          .where((m) =>
              m.nameKo.toLowerCase().contains(q) ||
              m.slug.toLowerCase().contains(q))
          .toList();
    }
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: FacingTokens.sp3),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
              child: Text('Select Movement.', style: FacingTokens.h3),
            ),
            const SizedBox(height: FacingTokens.sp3),
            // v1.16 Sprint 7a: 검색 필드.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: '동작 검색 (예: 스내치, Thruster)',
                  prefixIcon: const Icon(Icons.search,
                      color: FacingTokens.muted, size: 18),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: FacingTokens.sp3),
            if (_query.isEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: FacingTokens.sp3),
                child: Row(
                  children: List.generate(widget.categories.length, (i) {
                    final selected = i == _catIndex;
                    final c = widget.categories[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: FacingTokens.sp2),
                      child: _CategoryChip(
                        label: c.nameKo,
                        selected: selected,
                        onTap: () => setState(() => _catIndex = i),
                      ),
                    );
                  }),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FacingTokens.sp4,
                ),
                child: Text(
                  '${filtered.length} results for "$_query"',
                  style: FacingTokens.caption,
                ),
              ),
            const Divider(),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(FacingTokens.sp5),
                        child: Text('No results.', style: FacingTokens.caption),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final m = filtered[i];
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(m),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: FacingTokens.sp4,
                              vertical: FacingTokens.sp4,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(m.nameKo,
                                      style: FacingTokens.body),
                                ),
                                Text(_unitLabel(m.unit),
                                    style: FacingTokens.caption),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _unitLabel(String unit) {
    switch (unit) {
      case 'reps': return '회';
      case 'meters': return 'm';
      case 'calories': return 'cal';
      case 'seconds': return '초';
      default: return unit;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FacingTokens.r4),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FacingTokens.sp4,
          vertical: FacingTokens.sp2,
        ),
        decoration: BoxDecoration(
          color: selected ? FacingTokens.fg : FacingTokens.bg,
          border: Border.all(
            color: selected ? FacingTokens.fg : FacingTokens.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(FacingTokens.r4),
        ),
        child: Text(
          label,
          style: FacingTokens.body.copyWith(
            color: selected ? FacingTokens.bg : FacingTokens.fg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ItemParamsSheet extends StatefulWidget {
  final Movement movement;
  const _ItemParamsSheet({required this.movement});

  @override
  State<_ItemParamsSheet> createState() => _ItemParamsSheetState();
}

class _ItemParamsSheetState extends State<_ItemParamsSheet> {
  final _repsCtrl = TextEditingController();
  final _distCtrl = TextEditingController();
  final _loadCtrl = TextEditingController();
  // v1.16 Sprint 7a: 기본 단위를 UnitState에서. 세션 일관성.
  String? _loadUnit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUnit ??= context.read<UnitState>().isKg ? 'kg' : 'lb';
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    _distCtrl.dispose();
    _loadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movement;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: FacingTokens.sp4,
          right: FacingTokens.sp4,
          top: FacingTokens.sp4,
          bottom: MediaQuery.of(context).viewInsets.bottom + FacingTokens.sp4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(m.nameKo, style: FacingTokens.h3),
            const SizedBox(height: FacingTokens.sp4),
            if (m.isCardio)
              _LabelledField(
                label: '거리',
                controller: _distCtrl,
                suffix: 'm',
              )
            else
              _LabelledField(
                label: '횟수',
                controller: _repsCtrl,
                suffix: '회',
              ),
            if (m.hasLoad) ...[
              const SizedBox(height: FacingTokens.sp3),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _LabelledField(
                      label: '중량',
                      controller: _loadCtrl,
                      suffix: _loadUnit ?? 'lb',
                    ),
                  ),
                  const SizedBox(width: FacingTokens.sp2),
                  _UnitToggle(
                    unit: _loadUnit ?? 'lb',
                    onChanged: (u) => setState(() => _loadUnit = u),
                  ),
                ],
              ),
            ],
            const SizedBox(height: FacingTokens.sp5),
            ElevatedButton(
              onPressed: () {
                final item = WodItemDraft(
                  movement: m,
                  reps: _intOrNull(_repsCtrl.text),
                  distanceM: _intOrNull(_distCtrl.text),
                  loadValue: _doubleOrNull(_loadCtrl.text),
                  loadUnit: _loadUnit ?? 'lb',
                );
                Navigator.of(context).pop(item);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  int? _intOrNull(String s) {
    final v = int.tryParse(s.trim());
    return (v == null || v <= 0) ? null : v;
  }

  double? _doubleOrNull(String s) {
    final v = double.tryParse(s.trim());
    return (v == null || v <= 0) ? null : v;
  }
}

class _LabelledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;
  const _LabelledField({
    required this.label,
    required this.controller,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final String unit;
  final ValueChanged<String> onChanged;
  const _UnitToggle({required this.unit, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['lb', 'kg'].map((u) {
        final selected = u == unit;
        return Padding(
          padding: const EdgeInsets.only(left: FacingTokens.sp1),
          child: InkWell(
            onTap: () => onChanged(u),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FacingTokens.sp3,
                vertical: FacingTokens.sp2,
              ),
              decoration: BoxDecoration(
                color: selected ? FacingTokens.fg : FacingTokens.bg,
                border: Border.all(
                  color: selected ? FacingTokens.fg : FacingTokens.border,
                ),
                borderRadius: BorderRadius.circular(FacingTokens.r2),
              ),
              child: Text(
                u,
                style: FacingTokens.body.copyWith(
                  color: selected ? FacingTokens.bg : FacingTokens.fg,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
