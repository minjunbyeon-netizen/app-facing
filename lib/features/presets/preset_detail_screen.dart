import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/movement.dart';
import '../../models/preset_wod.dart';
import '../wod_builder/wod_draft_state.dart';

/// v1.16: Preset 탭 후 진입하는 "구성 설명" 화면.
/// WOD 이름·타입·타임캡·라운드 + 동작 순서 리스트(횟수·무게·거리) 안내.
/// 하단 `계산하기` CTA → draft state에 로드 후 /result로 push.
class PresetDetailScreen extends StatelessWidget {
  final PresetWod preset;
  final Map<String, Movement> movementBySlug;

  const PresetDetailScreen({
    super.key,
    required this.preset,
    required this.movementBySlug,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(preset.nameKo.toUpperCase()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                children: [
                  // 상단 요약 — 타입 · 타임캡 · 라운드
                  Text(
                    _headerParts().join(' · '),
                    style: FacingTokens.sectionLabel,
                  ),
                  const SizedBox(height: FacingTokens.sp3),

                  // 이름 헤드라인
                  Text(preset.nameKo,
                      style: FacingTokens.h1Serif),
                  const SizedBox(height: FacingTokens.sp4),

                  // 설명 (한글 OK)
                  if (preset.descriptionKo.isNotEmpty)
                    Text(preset.descriptionKo, style: FacingTokens.lead),
                  const SizedBox(height: FacingTokens.sp5),

                  // HOW TO — 동작 순서 리스트
                  const Text('HOW TO', style: FacingTokens.sectionLabel),
                  const SizedBox(height: FacingTokens.sp3),
                  ..._buildItemRows(),

                  // RX 시간 참고 (있으면)
                  if (preset.rxTimeAdvancedSec != null) ...[
                    const SizedBox(height: FacingTokens.sp5),
                    const Text('RX REFERENCE', style: FacingTokens.sectionLabel),
                    const SizedBox(height: FacingTokens.sp2),
                    Text(
                      'Advanced 기준 완주 시간: ${_formatSec(preset.rxTimeAdvancedSec!)}',
                      style: FacingTokens.caption,
                    ),
                  ],
                ],
              ),
            ),

            // 하단 계산하기 CTA
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                child: ElevatedButton(
                  onPressed: () {
                    Haptic.medium();
                    context
                        .read<WodDraftState>()
                        .loadFromPreset(preset, movementBySlug);
                    Navigator.of(context).pushNamed('/result');
                  },
                  child: const Text('계산하기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _headerParts() {
    final parts = <String>[];
    parts.add(preset.typeLabelKo.toUpperCase());
    if (preset.timeCapSec != null) {
      parts.add('CAP ${preset.timeCapSec! ~/ 60}분');
    }
    if (preset.rounds != null) parts.add('${preset.rounds}R');
    return parts;
  }

  List<Widget> _buildItemRows() {
    if (preset.items.isEmpty) {
      return [const Text('동작 데이터 없음', style: FacingTokens.caption)];
    }
    // 동일 동작 연속 그룹핑: (e.g. Fran 21-15-9 Thruster + Pull-up 교차를
    // 그대로 위치 순서로 보여줌 — 라운드 숫자 뒤에 간결 설명).
    final widgets = <Widget>[];
    for (int i = 0; i < preset.items.length; i++) {
      final item = preset.items[i];
      final mv = movementBySlug[item.movementSlug];
      widgets.add(_ItemRow(
        index: i + 1,
        name: mv?.nameKo ?? _prettify(item.movementSlug),
        detail: _detailLine(item),
      ));
    }
    return widgets;
  }

  String _detailLine(PresetWodItem item) {
    final parts = <String>[];
    if (item.reps != null) parts.add('${item.reps}회');
    if (item.distanceM != null && item.distanceM! > 0) {
      parts.add('${item.distanceM}m');
    }
    if (item.loadValue != null && item.loadValue! > 0) {
      final u = item.loadUnit.isEmpty ? 'lb' : item.loadUnit;
      parts.add('${item.loadValue!.toStringAsFixed(0)}$u');
    }
    if (parts.isEmpty) return 'max';
    return parts.join(' · ');
  }

  String _prettify(String slug) {
    if (slug.isEmpty) return slug;
    return slug
        .split('_')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatSec(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _ItemRow extends StatelessWidget {
  final int index;
  final String name;
  final String detail;

  const _ItemRow({
    required this.index,
    required this.name,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$index',
              style: FacingTokens.caption.copyWith(
                color: FacingTokens.muted,
                fontFeatures: FacingTokens.tabular,
              ),
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: FacingTokens.body.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            detail,
            style: FacingTokens.body.copyWith(
              fontFeatures: FacingTokens.tabular,
              color: FacingTokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}
