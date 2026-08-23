// v1.20: WOD "완료 표시" 결과 입력 시트.
// 기존 WodSessionScreen 타이머를 거치지 않고 직접 결과 입력 + Attendance 자동 체크.
//
// v3.3 (2026-08-20 사용자 지시 전면 개편): "라운드·스케일·중량·메모가 뭔지 알기
// 어렵다 — 오늘 수업 내용이 그대로 가져와지고 나는 최소한만 입력하게 하라".
// - 수업 내용(동작·횟수·코치 무게)을 게시물에서 그대로 가져와 보여준다
// - 동작별로 SCALED / RXD 만 고른다 (ELITE 제거 — 회원 선택지에서 삭제)
//   · 무게 있는 동작: RXD = 코치가 설정한 무게 그대로 따라옴(입력 없음),
//     SCALED = 내 무게만 입력
//   · 맨몸 동작(T2B 등): 무게 없이 SCALED/RXD 선택만
// - 결과는 종류별 최소 입력 (For Time 시간 / AMRAP 라운드+reps / EMOM 라운드)
// - 저장 시 동작별 선택이 "Wallball RXD 20lb · Squat SCALED 40kg" 형태로
//   기록에 쌓인다 — PR·기록 경신 로그가 읽히는 구조.
//
// v3.4 (2026-08-20 승인 — docs/PLAN-record-structures.md Part A):
// - Strength 분기 신설 — 최고 무게(kg)+reps 입력 (SCALED/RXD 선택 아님)
// - EMOM 라벨 "성공한 라운드" 명확화
// - 저장 응답의 서버 비교 메시지("지난 기록보다 42초 단축 — PR!")를
//   스낵바에 표시 (비교·PR 판정은 전부 백엔드 — 앱 계산 0).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/mascot.dart';

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

/// 동작 1개의 입력 상태 — 게시물의 WodMovementItem + 회원 선택.
class _MoveEntry {
  final WodMovementItem item;
  bool scaled = false; // 기본 RXD
  final TextEditingController weightCtrl = TextEditingController();
  _MoveEntry(this.item);

  bool get hasCoachLoad => item.loadValue.isNotEmpty;

  void dispose() => weightCtrl.dispose();
}

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
  final _weightCtrl = TextEditingController(); // fallback(자유 서술 게시물) 전용
  final _stWeightCtrl = TextEditingController(); // strength — 최고 무게
  final _stRepsCtrl = TextEditingController(); // strength — reps (선택)
  // v3.14 (2026-08-23 조인트 1) — custom 수업의 무게 기록(선택).
  // 그날 내용(BUILD Back Squat 5×5 …)은 custom 게시물이라 strength 분기가
  // 안 떠, 회원이 무게를 적을 곳이 없었다. 동작 이름이 기록의 묶음 열쇠
  // (서버가 strength 게시물과 같은 그룹으로 묶어 PR·1RM 보드 연동).
  final _liftNameCtrl = TextEditingController();
  final _liftWeightCtrl = TextEditingController();
  final _liftRepsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _fallbackScaled = false; // fallback 전용 — 기본 RXD
  bool _saving = false;
  String? _error;

  late final List<_MoveEntry> _moves;

  bool get _isForTime => widget.wod.wodType.toLowerCase() == 'for_time';
  bool get _isAmrap => widget.wod.wodType.toLowerCase().contains('amrap');
  bool get _isEmom => widget.wod.wodType.toLowerCase() == 'emom';
  bool get _isStrength => widget.wod.wodType.toLowerCase() == 'strength';

  /// 게시물에 구조화 동작이 있으면 동작별 입력, 없으면 fallback(전체 1선택).
  bool get _structured => _moves.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _moves = [
      for (final r in widget.wod.roundsData)
        for (final m in r.movements) _MoveEntry(m),
    ];
    // 라운드 수는 게시물 값이 있으면 그대로 가져온다 (EMOM 10 → 10).
    if (!_isForTime && !_isStrength && widget.wod.rounds != null) {
      _roundsCtrl.text = '${widget.wod.rounds}';
    }
    // 결함 수정 4 (2026-08-20 실기 발견): 기존 기록이 있으면 프리필 —
    // 빈 시트로 열려 조용히 덮어쓰던 문제. 안내줄은 build 쪽에.
    final mr = widget.wod.myResult;
    if (mr != null) {
      if (mr.timeSec != null && mr.timeSec! > 0) {
        final m = mr.timeSec! ~/ 60;
        final s = mr.timeSec! % 60;
        _timeCtrl.text = '$m:${s.toString().padLeft(2, '0')}';
      }
      if (mr.rounds != null) _roundsCtrl.text = '${mr.rounds}';
      if (mr.extraReps != null) _extraCtrl.text = '${mr.extraReps}';
      if (mr.weightKg != null) {
        final w = mr.weightKg!;
        _stWeightCtrl.text = w == w.roundToDouble() ? '${w.toInt()}' : '$w';
      }
      if (mr.weightReps != null) _stRepsCtrl.text = '${mr.weightReps}';
    }
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _roundsCtrl.dispose();
    _extraCtrl.dispose();
    _weightCtrl.dispose();
    _stWeightCtrl.dispose();
    _stRepsCtrl.dispose();
    _liftNameCtrl.dispose();
    _liftWeightCtrl.dispose();
    _liftRepsCtrl.dispose();
    _notesCtrl.dispose();
    for (final m in _moves) {
      m.dispose();
    }
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

  /// 동작별 선택 → 기록 한 줄 ("Wallball RXD 20lb · T2B SCALED").
  String _movesSummary() {
    final parts = <String>[];
    for (final e in _moves) {
      final name = e.item.name.isEmpty ? e.item.slug : e.item.name;
      if (e.scaled) {
        final w = e.weightCtrl.text.trim();
        parts.add(w.isEmpty ? '$name SCALED' : '$name SCALED ${w}kg');
      } else {
        final load = e.hasCoachLoad
            ? ' ${e.item.loadValue}${e.item.loadUnit}'
            : '';
        parts.add('$name RXD$load');
      }
    }
    return parts.join(' · ');
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
    final messenger = HkSnack.of(context);
    final navigator = Navigator.of(context);

    final timeSec = _isForTime ? _parseTime(_timeCtrl.text) : null;
    final rounds = (!_isForTime && !_isStrength)
        ? int.tryParse(_roundsCtrl.text.trim())
        : null;
    final extra = _isAmrap ? int.tryParse(_extraCtrl.text.trim()) : null;
    // strength — 최고 무게(+reps). 다른 유형은 null.
    final liftName = _isStrength ? null : _liftNameCtrl.text.trim();
    final liftWeight =
        _isStrength ? null : double.tryParse(_liftWeightCtrl.text.trim());
    final hasLift =
        liftName != null && liftName.isNotEmpty && liftWeight != null;
    final stWeight = _isStrength
        ? double.tryParse(_stWeightCtrl.text.trim())
        : (hasLift ? liftWeight : null);
    final stReps = _isStrength
        ? int.tryParse(_stRepsCtrl.text.trim())
        : (hasLift ? int.tryParse(_liftRepsCtrl.text.trim()) : null);

    // 전체 난도 = 동작 중 하나라도 SCALED 면 scaled (enum 은 scaled/rx 유지).
    // strength 는 난도 선택이 없다 — 기본 rx.
    final anyScaled = _isStrength
        ? false
        : _structured
            ? _moves.any((m) => m.scaled)
            : _fallbackScaled;
    final scale = anyScaled ? 'scaled' : 'rx';

    final notesParts = <String>[];
    if (_isStrength) {
      // 무게는 weight_kg 필드로 간다 — 메모엔 사용자 입력만.
    } else if (_structured) {
      notesParts.add(_movesSummary());
    } else {
      final weightKg = double.tryParse(_weightCtrl.text.trim());
      if (weightKg != null && weightKg > 0) notesParts.add('${weightKg}kg');
    }
    if (_notesCtrl.text.trim().isNotEmpty) notesParts.add(_notesCtrl.text.trim());
    final notes = notesParts.join(' · ');

    try {
      // 1) 결과 제출. (첫 제출이면 points_awarded > 0)
      final res = await repo.submitWodResult(
            gymId: gym.id,
            wodId: widget.wod.id,
            timeSec: timeSec,
            rounds: rounds,
            extraReps: extra,
            weightKg: stWeight,
            weightReps: stReps,
            movement: hasLift ? liftName : null,
            scaleLevel: scale,
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
            'grade': scale,
          },
        });
      } catch (_) {
        // history 실패해도 결과는 저장됨. 무시.
      }
      if (!mounted) return;
      // 3) Attendance / Trends 즉시 reload.
      bus.bump();
      navigator.pop(true);
      final earned = res.pointsAwarded > 0;
      // v3.4 — 서버 비교 메시지 붙여 발전 피드백 ("지난 기록보다 42초 단축 — PR!").
      final base = earned
          ? '저장됨 · 출석 +1 · +${res.pointsAwarded}P'
          : '저장됨 · 출석 +1';
      final msg = res.comparisonMessage;
      messenger.info(
        msg == null ? base : '$base\n$msg',
        mood: MascotMood.happy,
        duration: Duration(seconds: msg == null ? 2 : 3),
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
        // 원문은 로그로만 — 화면에는 사람이 읽을 문구 (2026-08-23).
        debugPrint('[WodResultSheet.save] $e');
        _error = '저장하지 못했습니다. 연결을 확인해 주세요.';
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
              // 오늘 수업 내용 — 그대로 가져온다 (내가 다시 적지 않는다).
              Text(
                widget.wod.content,
                style: HyphenTokens.caption,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: HyphenTokens.sp4),

              // ── 내 결과 (종류별 최소 입력) ──
              const Text('내 결과', style: HyphenTokens.sectionLabel),
              const SizedBox(height: HyphenTokens.sp1),
              // 결함 수정 4 — 재제출 = 덮어쓰기임을 알린다 (프리필과 한 쌍).
              if (widget.wod.myResult != null) ...[
                Text(
                  '이미 저장한 기록이 있습니다 — 저장하면 새 값으로 바뀝니다.',
                  style: HyphenTokens.caption
                      .copyWith(color: HyphenTokens.warning),
                ),
                const SizedBox(height: HyphenTokens.sp2),
              ],
              if (_isForTime) ...[
                _TimeField(controller: _timeCtrl),
              ] else if (_isStrength) ...[
                // v3.4 — 무게 측정일: 최고 무게(+reps)가 점수다.
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _stWeightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: '오늘 최고 무게 (kg)',
                          hintText: '예: 100',
                        ),
                      ),
                    ),
                    const SizedBox(width: HyphenTokens.sp2),
                    Expanded(
                      child: TextField(
                        controller: _stRepsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'reps (선택)',
                          hintText: '예: 5',
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _roundsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          // EMOM 은 "성공한 라운드"가 점수 (승인 결정 1).
                          labelText: _isEmom ? '성공한 라운드' : '몇 라운드 했는지',
                          hintText: _isEmom && widget.wod.rounds != null
                              ? '${widget.wod.rounds}라운드 중 몇 개 성공'
                              : null,
                        ),
                      ),
                    ),
                    if (_isAmrap) ...[
                      const SizedBox(width: HyphenTokens.sp2),
                      Expanded(
                        child: TextField(
                          controller: _extraCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '추가 reps (선택)',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // v3.14 — 무게 기록 (선택). 근력 파트가 낀 날(BUILD Back
                // Squat 5×5 …) 여기 적으면 최고 기록·PR 로 이어진다.
                // 동작 이름이 같으면 날짜가 달라도 같은 기록으로 묶인다.
                const SizedBox(height: HyphenTokens.sp4),
                const Text('무게 기록 (선택)', style: HyphenTokens.sectionLabel),
                const SizedBox(height: HyphenTokens.sp1),
                Text('오늘 리프트를 했으면 적어 주세요 — 최고 기록과 PR 에 반영됩니다.',
                    style: HyphenTokens.caption),
                const SizedBox(height: HyphenTokens.sp2),
                TextField(
                  controller: _liftNameCtrl,
                  decoration: const InputDecoration(
                    labelText: '동작 이름',
                    hintText: '예: Back Squat',
                  ),
                ),
                const SizedBox(height: HyphenTokens.sp2),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _liftWeightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: '오늘 최고 무게 (kg)',
                          hintText: '예: 100',
                        ),
                      ),
                    ),
                    const SizedBox(width: HyphenTokens.sp2),
                    Expanded(
                      child: TextField(
                        controller: _liftRepsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'reps (선택)',
                          hintText: '예: 5',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: HyphenTokens.sp4),

              // ── 동작별 난도 (게시물에서 그대로) — strength 는 난도 없음 ──
              if (_structured && !_isStrength) ...[
                const Text('동작별 난도', style: HyphenTokens.sectionLabel),
                const SizedBox(height: HyphenTokens.sp1),
                for (final e in _moves) _MovementRow(
                  entry: e,
                  enabled: !_saving,
                  onChanged: () => setState(() {}),
                ),
              ] else if (!_isStrength) ...[
                // 자유 서술 게시물 — 전체 1선택 (코치 무게는 본문에 이미 있음).
                const Text('난도', style: HyphenTokens.sectionLabel),
                const SizedBox(height: HyphenTokens.sp1),
                Wrap(
                  spacing: HyphenTokens.sp2,
                  children: [
                    HkBadge(
                      'SCALED',
                      color: HyphenTokens.fg,
                      selected: _fallbackScaled,
                      onTap: _saving
                          ? null
                          : () => setState(() => _fallbackScaled = true),
                    ),
                    HkBadge(
                      'RXD',
                      color: HyphenTokens.fg,
                      selected: !_fallbackScaled,
                      onTap: _saving
                          ? null
                          : () => setState(() => _fallbackScaled = false),
                    ),
                  ],
                ),
                if (_fallbackScaled) ...[
                  const SizedBox(height: HyphenTokens.sp2),
                  TextField(
                    controller: _weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '내 무게 (kg · 선택)',
                      hintText: '예: 40',
                    ),
                  ),
                ],
              ],
              const SizedBox(height: HyphenTokens.sp3),
              TextField(
                controller: _notesCtrl,
                maxLines: 1,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  hintText: 'PR · UB 등',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: HyphenTokens.sp2),
                Text(_error!,
                    style: HyphenTokens.caption
                        .copyWith(color: HyphenTokens.warning)),
              ],
              const SizedBox(height: HyphenTokens.sp4),
              // 버튼은 '저장' 하나 — 출석 동반 처리는 아래 한 줄로 고지 (GLOSSARY §3).
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

/// 동작 1줄 — 이름·횟수·코치 무게는 그대로, 회원은 SCALED/RXD 만 고른다.
/// SCALED + 무게 동작이면 내 무게 입력칸이 열린다.
class _MovementRow extends StatelessWidget {
  final _MoveEntry entry;
  final bool enabled;
  final VoidCallback onChanged;
  const _MovementRow({
    required this.entry,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final it = entry.item;
    final title = [
      if (it.reps.isNotEmpty) it.reps,
      it.name,
    ].join(' ');
    return Container(
      margin: const EdgeInsets.only(bottom: HyphenTokens.sp2),
      padding: const EdgeInsets.all(HyphenTokens.sp3),
      decoration: BoxDecoration(
        border: Border.all(color: HyphenTokens.border),
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: HyphenTokens.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              HkBadge(
                'SCALED',
                color: HyphenTokens.fg,
                selected: entry.scaled,
                onTap: enabled
                    ? () {
                        entry.scaled = true;
                        onChanged();
                      }
                    : null,
              ),
              const SizedBox(width: HyphenTokens.sp1),
              HkBadge(
                'RXD',
                color: HyphenTokens.fg,
                selected: !entry.scaled,
                onTap: enabled
                    ? () {
                        entry.scaled = false;
                        onChanged();
                      }
                    : null,
              ),
            ],
          ),
          // RXD + 코치 무게 = 그대로 따라온다 (입력 없음).
          if (!entry.scaled && entry.hasCoachLoad) ...[
            const SizedBox(height: HyphenTokens.sp1),
            Text(
              '코치 설정 무게 ${it.loadValue}${it.loadUnit} 그대로',
              style: HyphenTokens.caption,
            ),
          ],
          // SCALED + 무게 동작 = 내 무게만 입력.
          if (entry.scaled && entry.hasCoachLoad) ...[
            const SizedBox(height: HyphenTokens.sp2),
            TextField(
              controller: entry.weightCtrl,
              enabled: enabled,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '내 무게 (kg)',
                hintText: '코치 설정 ${it.loadValue}${it.loadUnit}',
                isDense: true,
              ),
            ),
          ],
        ],
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
