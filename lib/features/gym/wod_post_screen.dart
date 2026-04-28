import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import 'gym_state.dart';

/// v1.15.3: 코치 WOD 작성 폼.
class WodPostScreen extends StatefulWidget {
  const WodPostScreen({super.key});

  @override
  State<WodPostScreen> createState() => _WodPostScreenState();
}

class _WodPostScreenState extends State<WodPostScreen> {
  final _contentCtrl = TextEditingController();
  final _scaledCtrl = TextEditingController();
  final _beginnerCtrl = TextEditingController();
  final _scaleGuideCtrl = TextEditingController();
  final _roundsCtrl = TextEditingController();
  final _timeCapCtrl = TextEditingController();

  String _wodType = 'for_time';
  DateTime _date = DateTime.now();
  bool _submitting = false;
  // v1.16 Sprint 15: 라운드 배열 (각 라운드별 label·content·timeCap).
  final List<_RoundDraft> _rounds = [];

  @override
  void dispose() {
    _contentCtrl.dispose();
    _scaledCtrl.dispose();
    _beginnerCtrl.dispose();
    _scaleGuideCtrl.dispose();
    _roundsCtrl.dispose();
    _timeCapCtrl.dispose();
    // QA B-ML-1: _RoundDraft controller 누수 방지.
    for (final r in _rounds) {
      r.dispose();
    }
    super.dispose();
  }

  /// v1.16 Sprint 12: 어제 게시한 WOD를 현재 폼에 prefill.
  void _duplicateYesterday() {
    final yestWods = context.read<GymState>().todayWods; // 같은 리스트 재활용 (최근 50개)
    // todayWods는 "오늘" 필터로 loadMine 하지만 실제로는 전체 최근 WOD를 가져오도록 loadMine 구조 필요.
    // 간소 구현: 가장 최근 WOD 1개를 복제.
    if (yestWods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('복제할 기존 WOD 없음.')),
      );
      return;
    }
    final w = yestWods.first;
    Haptic.medium();
    setState(() {
      _wodType = w.wodType;
      _contentCtrl.text = w.content;
      if (w.rounds != null) _roundsCtrl.text = '${w.rounds}';
      if (w.timeCapSec != null) {
        _timeCapCtrl.text = '${(w.timeCapSec! / 60).round()}';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('이전 WOD 복제. 필요 시 수정 후 Post.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String get _dateIso =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WOD 내용을 입력하세요.')),
      );
      return;
    }
    setState(() => _submitting = true);
    Haptic.medium();
    final roundsData = _rounds
        .where((r) => r.content.text.trim().isNotEmpty)
        .map((r) => WodRoundItem(
              label: r.label.text.trim().isEmpty
                  ? 'Round ${_rounds.indexOf(r) + 1}'
                  : r.label.text.trim(),
              content: r.content.text.trim(),
              timeCapSec: _parseTimeCap(r.timeCap.text.trim()),
            ))
        .toList();
    final ok = await context.read<GymState>().postWod(
          postDate: _dateIso,
          wodType: _wodType,
          content: content,
          scaledVersion: _scaledCtrl.text.trim().isEmpty
              ? null
              : _scaledCtrl.text.trim(),
          beginnerVersion: _beginnerCtrl.text.trim().isEmpty
              ? null
              : _beginnerCtrl.text.trim(),
          scaleGuide: _scaleGuideCtrl.text.trim().isEmpty
              ? null
              : _scaleGuideCtrl.text.trim(),
          roundsData: roundsData,
          // QA B-IN-9, B-IN-10: 양수 검증.
          rounds: () {
            final r = int.tryParse(_roundsCtrl.text.trim());
            return (r != null && r > 0) ? r : null;
          }(),
          timeCapSec: () {
            final t = _parseTimeCap(_timeCapCtrl.text.trim());
            return (t != null && t > 0) ? t : null;
          }(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<GymState>().error ?? '게시 실패')),
      );
    }
  }

  int? _parseTimeCap(String raw) {
    if (raw.isEmpty) return null;
    // "10", "10:30", "10min" 수용.
    if (raw.contains(':')) {
      final parts = raw.split(':');
      final m = int.tryParse(parts[0]) ?? 0;
      final s = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return m * 60 + s;
    }
    final onlyNum = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final m = int.tryParse(onlyNum);
    return m == null ? null : m * 60;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POST WOD'),
        actions: [
          TextButton.icon(
            onPressed: _duplicateYesterday,
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Duplicate'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          children: [
            const Text('DATE', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(FacingTokens.sp3),
                decoration: BoxDecoration(
                  border: Border.all(color: FacingTokens.border),
                  borderRadius: BorderRadius.circular(FacingTokens.r2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: FacingTokens.muted),
                    const SizedBox(width: FacingTokens.sp2),
                    Text(_dateIso, style: FacingTokens.body),
                  ],
                ),
              ),
            ),
            const SizedBox(height: FacingTokens.sp4),
            const Text('TYPE', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            Wrap(
              spacing: FacingTokens.sp2,
              children: const ['for_time', 'amrap', 'emom'].map((t) {
                final selected = t == _wodType;
                return ChoiceChip(
                  label: Text(t.toUpperCase()),
                  selected: selected,
                  backgroundColor: FacingTokens.surface,
                  selectedColor: FacingTokens.accent,
                  labelStyle: FacingTokens.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? FacingTokens.fg : FacingTokens.muted,
                  ),
                  onSelected: (_) {
                    Haptic.selection();
                    setState(() => _wodType = t);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: FacingTokens.sp4),
            const Text('RX', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            TextField(
              controller: _contentCtrl,
              decoration: const InputDecoration(
                labelText: 'RX 버전',
                hintText: '21-15-9 Thruster 95/65lb + Pull-up',
              ),
              maxLines: 5,
              maxLength: 2000,
            ),
            const SizedBox(height: FacingTokens.sp3),
            const Text('SCALED', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            TextField(
              controller: _scaledCtrl,
              decoration: const InputDecoration(
                labelText: 'Scaled 버전',
                hintText: '21-15-9 Thruster 65/45lb + Ring Row',
              ),
              maxLines: 4,
              maxLength: 2000,
            ),
            const SizedBox(height: FacingTokens.sp3),
            const Text('BEGINNER', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            TextField(
              controller: _beginnerCtrl,
              decoration: const InputDecoration(
                labelText: 'Beginner 버전',
                hintText: '15-12-9 Goblet Squat 20lb + Jumping Pull-up',
              ),
              maxLines: 4,
              maxLength: 2000,
            ),
            const SizedBox(height: FacingTokens.sp3),
            const Text('SCALE GUIDE (선택)', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            TextField(
              controller: _scaleGuideCtrl,
              decoration: const InputDecoration(
                labelText: 'RX vs Scaled 무게·대체 동작',
                hintText: 'RX: Thruster 95/65lb · Pull-up\nScaled: 65/45lb · Ring Row',
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: FacingTokens.sp3),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _roundsCtrl,
                    decoration: const InputDecoration(labelText: 'Rounds (선택)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: FacingTokens.sp3),
                Expanded(
                  child: TextField(
                    controller: _timeCapCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Time Cap (min 또는 m:ss)'),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FacingTokens.sp5),
            // v1.16 Sprint 15: 여러 라운드/블록 편집.
            Row(
              children: [
                const Expanded(
                  child: Text('ROUNDS (선택)',
                      style: FacingTokens.sectionLabel),
                ),
                TextButton.icon(
                  onPressed: _addRound,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Round'),
                ),
              ],
            ),
            const SizedBox(height: FacingTokens.sp1),
            const Text(
              '구조화 라운드: Chipper · 3 Rounds · Block 1/2/3 등. 위 CONTENT는 전체 요약.',
              style: FacingTokens.caption,
            ),
            const SizedBox(height: FacingTokens.sp2),
            ..._rounds.asMap().entries.map((e) {
              final i = e.key;
              final r = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: FacingTokens.sp3),
                padding: const EdgeInsets.all(FacingTokens.sp3),
                decoration: BoxDecoration(
                  color: FacingTokens.surface,
                  borderRadius: BorderRadius.circular(FacingTokens.r2),
                  border: Border.all(color: FacingTokens.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: r.label,
                            decoration: InputDecoration(
                              labelText: 'Label',
                              hintText: 'Round ${i + 1}',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: FacingTokens.muted,
                          onPressed: () => _removeRound(i),
                        ),
                      ],
                    ),
                    TextField(
                      controller: r.content,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        hintText: '15 Thrusters · 12 Pull-ups',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: FacingTokens.sp2),
                    TextField(
                      controller: r.timeCap,
                      decoration: const InputDecoration(
                        labelText: 'Time Cap (min, 선택)',
                        hintText: '5',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: FacingTokens.sp4),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Posting.' : 'Post WOD'),
            ),
          ],
        ),
      ),
    );
  }

  void _addRound() {
    Haptic.light();
    setState(() {
      _rounds.add(_RoundDraft());
    });
  }

  void _removeRound(int i) {
    Haptic.light();
    setState(() {
      _rounds[i].dispose();
      _rounds.removeAt(i);
    });
  }
}

/// v1.16 Sprint 15: 단일 라운드 편집 상태.
class _RoundDraft {
  final TextEditingController label = TextEditingController();
  final TextEditingController content = TextEditingController();
  final TextEditingController timeCap = TextEditingController();
  void dispose() {
    label.dispose();
    content.dispose();
    timeCap.dispose();
  }
}
