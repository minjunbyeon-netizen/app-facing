import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import 'gym_state.dart';

/// v1.15.3: 코치 WOD 작성 폼.
class WodPostScreen extends StatefulWidget {
  const WodPostScreen({super.key});

  @override
  State<WodPostScreen> createState() => _WodPostScreenState();
}

class _WodPostScreenState extends State<WodPostScreen> {
  final _contentCtrl = TextEditingController();
  final _scaleGuideCtrl = TextEditingController();
  final _roundsCtrl = TextEditingController();
  final _timeCapCtrl = TextEditingController();

  String _wodType = 'for_time';
  DateTime _date = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _scaleGuideCtrl.dispose();
    _roundsCtrl.dispose();
    _timeCapCtrl.dispose();
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
    final ok = await context.read<GymState>().postWod(
          postDate: _dateIso,
          wodType: _wodType,
          content: content,
          scaleGuide: _scaleGuideCtrl.text.trim().isEmpty
              ? null
              : _scaleGuideCtrl.text.trim(),
          rounds: int.tryParse(_roundsCtrl.text.trim()),
          timeCapSec: _parseTimeCap(_timeCapCtrl.text.trim()),
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
            const Text('CONTENT', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            TextField(
              controller: _contentCtrl,
              decoration: const InputDecoration(
                labelText: 'WOD 내용 (예: 21-15-9 Thrusters 95lb, Pull-ups)',
              ),
              maxLines: 6,
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
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Posting...' : 'Post WOD'),
            ),
          ],
        ),
      ),
    );
  }
}
