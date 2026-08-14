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
import '../../widgets/hkit.dart';
import '../history/history_repository.dart';
import 'gym_repository.dart';
import 'gym_state.dart';
import 'wod_type_label.dart';

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
      setState(() => _error = '체육관 정보 없음.');
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
      // 1) Box leaderboard 결과 제출. (첫 제출이면 points_awarded > 0)
      final res = await repo.submitWodResult(
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
            'notes': '수업 #${widget.wod.id} · ${widget.wod.content.split('\n').first}',
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
      final earned = res.pointsAwarded > 0;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            // v2.6: 한글 기본 (v1.29) — 영문 문장이 남아 있던 자리.
            earned
                ? '저장됨 · 출석 +1 · +${res.pointsAwarded}P'
                : '저장됨 · 출석 +1',
          ),
          duration: const Duration(seconds: 2),
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
          color: HyphenTokens.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(HyphenTokens.r3)),
        ),
        padding: const EdgeInsets.fromLTRB(
          HyphenTokens.sp4,
          HyphenTokens.sp4,
          HyphenTokens.sp4,
          HyphenTokens.sp3,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(wodTypeLabel(widget.wod.wodType),
                      style: HyphenTokens.sectionLabel.copyWith(
                        color: HyphenTokens.accent,
                      )),
                  const SizedBox(width: HyphenTokens.sp2),
                  const Text('· 완료 기록', style: HyphenTokens.sectionLabel),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: HyphenTokens.muted,
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: HyphenTokens.sp1),
              Text(
                widget.wod.content,
                style: HyphenTokens.caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: HyphenTokens.sp4),
              if (_isForTime) ...[
                _TimeField(controller: _timeCtrl),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _RoundField(controller: _roundsCtrl)),
                    if (_isAmrap) ...[
                      const SizedBox(width: HyphenTokens.sp2),
                      Expanded(child: _ExtraField(controller: _extraCtrl)),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: HyphenTokens.sp3),
              const Text('스케일', style: HyphenTokens.sectionLabel),
              const SizedBox(height: HyphenTokens.sp1),
              Wrap(
                spacing: HyphenTokens.sp2,
                children: [
                  // 등급 enum: elite / rx(=RXD 표기) / scaled (2026-05-30 통일)
                  // v2.6 (2026-08-12 사용자 지시): 낮은 난도부터 순서대로.
                  // 뒤섞여 있으면 셋 사이의 위아래 관계가 안 읽힌다.
                  for (final s in const [
                    ['scaled', 'SCALED'],
                    ['rx', 'RXD'],
                    ['elite', 'ELITE'],
                  ])
                    HkBadge(
                      s[1],
                      color: HyphenTokens.fg,
                      selected: _scale == s[0],
                      onTap:
                          _saving ? null : () => setState(() => _scale = s[0]),
                    ),
                ],
              ),
              const SizedBox(height: HyphenTokens.sp3),
              _WeightField(controller: _weightCtrl),
              const SizedBox(height: HyphenTokens.sp3),
              _NotesField(controller: _notesCtrl),
              if (_error != null) ...[
                const SizedBox(height: HyphenTokens.sp2),
                Text(_error!,
                    style: HyphenTokens.caption
                        .copyWith(color: HyphenTokens.warning)),
              ],
              const SizedBox(height: HyphenTokens.sp4),
              // v2.6 (2026-08-12 사용자 지시): 버튼이 '제출하고 출석' 이었다 —
              // 회원이 하는 일은 "내 기록을 남기는 것" 하나인데, 그 뒤에 앱이
              // 알아서 하는 출석 처리까지 버튼 이름에 끌고 들어와 무슨 흐름인지
              // 읽히지 않았다. 버튼은 '저장' 하나로 두고, 출석이 같이 된다는
              // 사실은 아래 한 줄로 알린다 (동작 이름 ≠ 부수 효과 나열).
              SizedBox(
                height: HyphenTokens.buttonH,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: HyphenTokens.fg,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(_saving ? '저장 중' : '저장'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HyphenTokens.accent,
                    foregroundColor: HyphenTokens.fg,
                  ),
                ),
              ),
              const SizedBox(height: HyphenTokens.sp2),
              const Text(
                '저장하면 오늘 출석도 함께 기록됩니다.',
                style: HyphenTokens.caption,
                textAlign: TextAlign.center,
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
        labelText: '기록 (분:초)',
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
        labelText: '중량 (kg · 선택)',
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
        labelText: '메모 (선택)',
        hintText: 'PR · UB · 부상부위 등',
      ),
    );
  }
}
