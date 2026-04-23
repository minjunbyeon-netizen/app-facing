import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/movements_repository.dart';
import '../../core/theme.dart';
import '../../models/movement.dart';
import '../../models/preset_wod.dart';
import '../wod_builder/wod_draft_state.dart';

class PresetsScreen extends StatefulWidget {
  const PresetsScreen({super.key});

  @override
  State<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends State<PresetsScreen> {
  Future<(List<PresetWod>, Map<String, Movement>)>? _future;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final repo = context.read<MovementsRepository>();
    _future = _load(repo);
  }

  Future<(List<PresetWod>, Map<String, Movement>)> _load(
      MovementsRepository repo) async {
    final presets = await repo.fetchPresets();
    final cats = await repo.fetchCategoriesList();
    final map = <String, Movement>{};
    for (final c in cats) {
      for (final m in c.movements) {
        map[m.slug] = m;
      }
    }
    return (presets, map);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preset WODs')),
      body: FutureBuilder<(List<PresetWod>, Map<String, Movement>)>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: Text('Loading.', style: FacingTokens.body));
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(FacingTokens.sp4),
              child: Text('${snap.error}', style: FacingTokens.body),
            );
          }
          final (presets, movMap) = snap.data!;
          final filtered = _filter == 'all'
              ? presets
              : presets.where((p) => p.category == _filter).toList();
          return Column(
            children: [
              _FilterBar(
                current: _filter,
                onTap: (f) => setState(() => _filter = f),
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    return InkWell(
                      onTap: () {
                        context.read<WodDraftState>().loadFromPreset(p, movMap);
                        Navigator.of(context).pushNamed('/result');
                      },
                      child: _PresetRow(preset: p),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String current;
  final ValueChanged<String> onTap;
  const _FilterBar({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tabs = <(String, String)>[
      ('all', 'All'),
      ('girl', 'Girls'),
      ('hero', 'Heroes'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FacingTokens.sp4,
        vertical: FacingTokens.sp3,
      ),
      child: Row(
        children: tabs.map((t) {
          final (value, label) = t;
          final selected = value == current;
          return Padding(
            padding: const EdgeInsets.only(right: FacingTokens.sp2),
            child: InkWell(
              onTap: () => onTap(value),
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
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  final PresetWod preset;
  const _PresetRow({required this.preset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FacingTokens.sp4,
        vertical: FacingTokens.sp4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(preset.nameKo, style: FacingTokens.h3),
              const SizedBox(width: FacingTokens.sp2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FacingTokens.sp2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: FacingTokens.border),
                  borderRadius: BorderRadius.circular(FacingTokens.r1),
                ),
                child: Text(preset.typeLabelKo, style: FacingTokens.micro),
              ),
              const Spacer(),
              if (preset.timeCapSec != null)
                Text(preset.timeCapLabelKo, style: FacingTokens.caption),
            ],
          ),
          const SizedBox(height: FacingTokens.sp1),
          Text(preset.descriptionKo, style: FacingTokens.caption),
        ],
      ),
    );
  }
}
