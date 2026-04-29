// v1.20: WOD "Mark Done" 결과 입력 시트.
// 기존 WodSessionScreen 타이머를 거치지 않고 직접 결과 입력 + Attendance 자동 체크.
// 사용자 요구: "Start 버튼 없이, 누르면 attendance 연동되고 기록·시간·무게 입력".

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../core/wod_session_bus.dart';
import '../../models/gym.dart';
import '../history/history_repository.dart';
import 'gym_repository.dart';
import 'gym_state.dart';

/// `wod` 의 종류에 따라 입력 폼이 달라진다.
/// - For Time: 시간 (mm:ss)
/// - AMRAP: 라운드 + extra reps
/// - EMOM: 라운드 (선택)
/// 공통: scale level (RX/SCALED/BEGINNER) + 무게 (kg, 선택) + notes.
class WodResultSheet extends StatefulWidget {
  final GymWodPost wod;
  const WodResultSheet({super.key, required this.wod});

  @override
  State<WodResultSheet> createState() => _WodResultSheetState();
}

class _WodResultSheetState extends State<WodResultSheet> {
  final _timeCtrl = TextEditingController();
  final _roundsCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _scale = 'rx';
  bool _saving = false;
  String? _error;

  bool get _isForTime => widget.wod.wodType.toLowerCase() == 'for_time';
  bool get _isAmrap => widget.wod.wodType.toLowerCase().contains('amrap');

  @override
  void dispose() {
    _timeCtrl.dispose();
    _roundsCtrl.dispose();
    _extraCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// "12:34" or "12" → seconds.
  int? _parseTime(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    if (t.contains(':')) {
      final parts = t.split(':');
      if (parts.length != 2) return null;
      final m = int.tryParse(parts[0]);
      final sec = int.tryParse(parts[1]);
      if (m == null || sec == null) return null;
      return m * 60 + sec;
    }
    return int.tryParse(t);
  }

  Future<void> _submit() async {
    if (_saving) return;
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null) {
      setState(() => _error = '박스 정보 없음.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    Haptic.heavy();

    // QA: await 전에 BuildContext 의존 객체를 모두 캡처. async gap 경고 회피.
    final repo = context.read<GymRepository>();
    final api = context.read<ApiClient>();
    final bus = context.read<WodSessionBus>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final timeSec = _isForTime ? _parseTime(_timeCtrl.text) : null;
    final rounds = !_isForTime ? int.tryParse(_roundsCtrl.text.trim()) : null;
    final extra = _isAmrap ? int.tryParse(_extraCtrl.text.trim()) : null;

    final weightKg = double.tryParse(_weightCtrl.text.trim());
    final notesParts = <String>[];
    if (weightKg != null && weightKg > 0) notesParts.add('${weightKg}kg');
    if (_notesCtrl.text.trim().isNotEmpty) notesParts.add(_notesCtrl.text.trim());
    final notes = notesParts.join(' · ');

    try {
      // 1) Box leaderboard 결과 제출.
      await repo.submitWodResult(
            gymId: gym.id,
            wodId: widget.wod.id,
            timeSec: timeSec,
            rounds: rounds,
            extraReps: extra,
            scaleLevel: _scale,
            notes: notes,
          );
      // 2) Attendance 캘린더 트리거 — history/wod minimal record.
      // HistoryRepository는 Provider 미등록이라 ApiClient로 직접 인스턴스화.
      try {
        final hist = HistoryRepository(api);
        await hist.saveWodHistory({
          'wod': {
            'wod_type': widget.wod.wodType,
            'notes': 'Box WOD #${widget.wod.id} · ${widget.wod.content.split('\n').first}',
          },
          'plan': {
            'formula_version': 'manual',
            'estimated_total_sec': timeSec ?? 0,
            'grade': _scale,
          },
        });
      } catch (_) {
        // history 실패해도 leaderboard는 저장됨. 무시.
      }
      if (!mounted) return;
      // 3) Attendance / Trends 즉시 reload.
      bus.bump();
      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Recorded. Attendance + 1.'),
          duration: Duration(seconds: 2),
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.messageKo;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '저장 실패: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: FacingTokens.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(FacingTokens.r3)),
        ),
        padding: const EdgeInsets.fromLTRB(
          FacingTokens.sp4,
          FacingTokens.sp4,
          FacingTokens.sp4,
          FacingTokens.sp3,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(widget.wod.wodType.toUpperCase(),
                      style: FacingTokens.sectionLabel.copyWith(
                        color: FacingTokens.accent,
                      )),
                  const SizedBox(width: FacingTokens.sp2),
                  const Text('· Mark Done', style: FacingTokens.sectionLabel),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: FacingTokens.muted,
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: FacingTokens.sp1),
              Text(
                widget.wod.content,
                style: FacingTokens.caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: FacingTokens.sp4),
              if (_isForTime) ...[
                _TimeField(controller: _timeCtrl),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _RoundField(controller: _roundsCtrl)),
                    if (_isAmrap) ...[
                      const SizedBox(width: FacingTokens.sp2),
                      Expanded(child: _ExtraField(controller: _extraCtrl)),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: FacingTokens.sp3),
              const Text('SCALE', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp1),
              Wrap(
                spacing: FacingTokens.sp2,
                children: [
                  for (final s in const ['rx', 'scaled', 'beginner'])
                    ChoiceChip(
                      label: Text(s.toUpperCase()),
                      selected: _scale == s,
                      backgroundColor: FacingTokens.surfaceOverlay,
                      selectedColor: FacingTokens.accent,
                      labelStyle: FacingTokens.caption.copyWith(
                        color: _scale == s
                            ? FacingTokens.fg
                            : FacingTokens.muted,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected:
                          _saving ? null : (_) => setState(() => _scale = s),
                    ),
                ],
              ),
              const SizedBox(height: FacingTokens.sp3),
              _WeightField(controller: _weightCtrl),
              const SizedBox(height: FacingTokens.sp3),
              _NotesField(controller: _notesCtrl),
              if (_error != null) ...[
                const SizedBox(height: FacingTokens.sp2),
                Text(_error!,
                    style: FacingTokens.caption
                        .copyWith(color: FacingTokens.warning)),
              ],
              const SizedBox(height: FacingTokens.sp4),
              SizedBox(
                height: FacingTokens.buttonH,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: FacingTokens.fg,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(_saving ? 'Saving' : 'Submit & Attend'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FacingTokens.accent,
                    foregroundColor: FacingTokens.fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  const _TimeField({required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        labelText: 'Time (mm:ss)',
        hintText: '12:34',
      ),
    );
  }
}

class _RoundField extends StatelessWidget {
  final TextEditingController controller;
  const _RoundField({required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Rounds'),
    );
  }
}

class _ExtraField extends StatelessWidget {
  final TextEditingController controller;
  const _ExtraField({required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Extra reps'),
    );
  }
}

class _WeightField extends StatelessWidget {
  final TextEditingController controller;
  const _WeightField({required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Weight (kg, 선택)',
        hintText: '예: 60',
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  const _NotesField({required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 2,
      maxLength: 200,
      decoration: const InputDecoration(
        labelText: 'Notes (선택)',
        hintText: 'PR · UB · 부상부위 등',
      ),
    );
  }
}
