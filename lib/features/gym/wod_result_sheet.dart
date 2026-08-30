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
//
// v3.15 (2026-08-23 승인 — 기록 UX 1): 기록 종류 칩 [시간/라운드/무게].
// 그날 내용은 custom(수업) 게시물로 흘러와 타입이 기록 종류를 못 정한다 —
// 회원이 직접 고른다. 기본값은 타입에서 (for_time→시간 · strength→무게 ·
// 그 외→라운드), 재수정이면 저장된 값의 종류를 그대로 연다. 서버는 기록이
// 실제 담은 값으로 비교·표시한다 (services/wod_compare.py result_kind_of).
//
// v3.16 (2026-08-23 승인 — 기록 UX 2·3): 서버 추천 배선.
// - 칩 기본값 = 서버 score_hint (custom 도 내용에서 추정 — 판정 사전은
//   services/wod_compare.py score_hint 한 곳, 앱 판정 0)
// - 동작 이름 칩 = 서버 movement_suggestions (게시물 구조화 동작 +
//   movement_library 대조) — 탭 한 번 = 오타 없는 이름 (PR 묶음 열쇠).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/mascot.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../core/wod_session_bus.dart';
import '../../models/gym.dart';
import '../../widgets/hkit.dart';
import 'gym_repository.dart';
import 'gym_state.dart';
import 'wod_type_label.dart';

/// 저장 중 토스트 (2026-08-30 사용자 원문 "수업을 저장중이에요 로딩바 두두둥"). 굵은 제목 +
/// 가로 로딩바(HkSnack.progress). 골든 `snack_06_saving` · `state_29_result_sheet_saving`.
const String kWodSavingTitle = '수업을 저장 중이에요';

/// 저장 성공 — 하이피(마스코트, `MascotMood.happy`)가 응원한다 (2026-08-30 사용자 원문
/// "하이피가 예____ 화이팅!!!!"). 둘째 줄부터는 종전 '저장됨 · 출석 +1' + 서버 비교 문구.
/// 골든 `snack_07_saved_fighting`.
const String kWodSavedCheer = '예____ 화이팅!!!!';

/// 저장 결과 첫 줄(둘째 줄) — 출석 동반 처리 고지. 문구는 여기 한 곳.
const String kWodSavedBase = '저장됨 · 출석 +1';

/// 그날 이미 출석이 있어 출석일이 늘지 않은 저장 — 서버 `attendance_added` 가 false 일 때
/// (하루 1회, D93). '+1' 이라고 말하면 화면이 거짓말한다 (2026-08-30 2차 검증).
const String kWodSavedOnly = '저장됨';

/// 레이아웃 안정성 앵커 — 저장 버튼·고지 줄. 저장 중(busy)에도 y 가 같아야 한다
/// (`test/golden/stability_result_sheet_test.dart`).
const Key kWodSaveButton = ValueKey('wod-result-save');
const Key kWodSaveCaption = ValueKey('wod-result-save-caption');

/// 기록 종류 — 회원이 칩으로 직접 고른다 (v3.15 UX 1).
enum _RecordKind { time, rounds, weight }

/// 동작 1개의 입력 상태 — 게시물의 WodMovementItem + 회원이 실제 한 값 (D94).
///
/// D94 (2026-08-30 사용자 지시 "동작별 완료 값 입력"): 횟수·무게 칸이 코치가 정한 값으로
/// 미리 채워져 있고 회원은 다르게 했을 때만 고친다. 저장된 값이 있으면 그것으로 채운다.
/// 판정·요약은 서버(`program_lines.normalize_result_movements`·`result_movements_summary`).
class _MoveEntry {
  final WodMovementItem item;
  bool scaled = false; // 기본 RXD
  late final TextEditingController repsCtrl = TextEditingController(
    text: item.reps,
  );
  late final TextEditingController weightCtrl = TextEditingController(
    text: item.loadValue,
  );
  _MoveEntry(this.item);

  bool get hasCoachLoad => item.loadValue.isNotEmpty;

  /// 저장된 동작별 값과 같은 동작인가 — id 로, 없으면 이름으로.
  bool matches(MyResultMovement m) {
    if (item.movementId != null && m.movementId != null) {
      return item.movementId == m.movementId;
    }
    return item.name.trim().toLowerCase() == m.name.trim().toLowerCase();
  }

  void prefill(MyResultMovement m) {
    scaled = m.scaled;
    if (m.reps.isNotEmpty) repsCtrl.text = m.reps;
    if (m.loadKg != null) {
      final w = m.loadKg!;
      weightCtrl.text = w == w.roundToDouble() ? '${w.toInt()}' : '$w';
    }
  }

  /// 서버로 보낼 한 줄. 무게는 비었으면 null.
  Map<String, dynamic> toJson() => {
    'movement_id': item.movementId,
    'name': item.name,
    'reps': repsCtrl.text.trim(),
    'load_kg': double.tryParse(weightCtrl.text.trim()),
    'scaled': scaled,
  };

  void dispose() {
    repsCtrl.dispose();
    weightCtrl.dispose();
  }
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

  /// v3.15 — 이번에 적을 기록 종류. 칩으로 전환.
  late _RecordKind _kind;

  bool get _isForTime => widget.wod.wodType.toLowerCase() == 'for_time';
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
        final txt = w == w.roundToDouble() ? '${w.toInt()}' : '$w';
        // strength 는 전용칸, 그 외는 무게 칩·선택 리프트칸 — 양쪽 다 채워
        // 어느 UI 로 열려도 프리필이 산다 (v3.15).
        _stWeightCtrl.text = txt;
        _liftWeightCtrl.text = txt;
      }
      if (mr.weightReps != null) {
        _stRepsCtrl.text = '${mr.weightReps}';
        _liftRepsCtrl.text = '${mr.weightReps}';
      }
      if (mr.movement != null && mr.movement!.isNotEmpty) {
        _liftNameCtrl.text = mr.movement!;
      }
      // D94 — 동작별 저장값 프리필 (같은 동작만).
      for (final saved in mr.movements) {
        for (final e in _moves) {
          if (e.matches(saved)) e.prefill(saved);
        }
      }
    }
    _kind = _initialKind();
  }

  /// 기본 기록 종류 — 재수정이면 저장된 값 > 서버 힌트(UX 2) > 게시물 타입.
  _RecordKind _initialKind() {
    final mr = widget.wod.myResult;
    if (mr != null) {
      if (mr.rounds != null || mr.extraReps != null) return _RecordKind.rounds;
      if ((mr.timeSec ?? 0) > 0) return _RecordKind.time;
      if (mr.weightKg != null) return _RecordKind.weight;
    }
    switch (widget.wod.scoreHint) {
      case 'time':
        return _RecordKind.time;
      case 'weight':
        return _RecordKind.weight;
      case 'rounds':
        return _RecordKind.rounds;
    }
    // 힌트 없음 (구 서버) — 타입 폴백.
    if (_isForTime) return _RecordKind.time;
    if (_isStrength) return _RecordKind.weight;
    return _RecordKind.rounds;
  }

  /// v3.16 (UX 3) — 동작 이름 후보 칩. 탭 = 이름 채움 (오타 원천 차단).
  List<Widget> _liftNameSuggestions() {
    final names = widget.wod.movementSuggestions;
    if (names.isEmpty) return const [];
    return [
      Wrap(
        spacing: HyphenTokens.sp1,
        runSpacing: HyphenTokens.sp1,
        children: [
          for (final n in names)
            HkBadge(
              n,
              color: HyphenTokens.fgSecondary,
              selected: _liftNameCtrl.text.trim() == n,
              onTap: _saving
                  ? null
                  : () => setState(() => _liftNameCtrl.text = n),
            ),
        ],
      ),
      const SizedBox(height: HyphenTokens.sp2),
    ];
  }

  static String _kindLabel(_RecordKind k) => switch (k) {
    _RecordKind.time => '시간',
    _RecordKind.rounds => '라운드',
    _RecordKind.weight => '무게',
  };

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
    final bus = context.read<WodSessionBus>();
    final messenger = HkSnack.of(context);
    final navigator = Navigator.of(context);
    // 저장 중 토스트 — 버튼은 자리 그대로 busy, 아래 토스트가 로딩바를 보여 준다.
    messenger.progress(kWodSavingTitle);

    // v3.15 — 칩이 정한 종류의 값만 주 기록으로 나간다.
    final timeSec = _kind == _RecordKind.time
        ? _parseTime(_timeCtrl.text)
        : null;
    final rounds = _kind == _RecordKind.rounds
        ? int.tryParse(_roundsCtrl.text.trim())
        : null;
    final extra = (_kind == _RecordKind.rounds && !_isEmom)
        ? int.tryParse(_extraCtrl.text.trim())
        : null;
    // 무게 — 무게 칩이면 주 기록, 시간·라운드 칩이면 선택 리프트 병기(v3.14).
    double? weightKg;
    int? weightReps;
    String? movement;
    if (_kind == _RecordKind.weight) {
      weightKg = double.tryParse(
        (_isStrength ? _stWeightCtrl : _liftWeightCtrl).text.trim(),
      );
      weightReps = int.tryParse(
        (_isStrength ? _stRepsCtrl : _liftRepsCtrl).text.trim(),
      );
      // strength 게시물은 게시물 자체가 리프트 그룹 — 이름 없이도 묶인다.
      final name = _liftNameCtrl.text.trim();
      if (!_isStrength && name.isNotEmpty) movement = name;
    } else if (!_isStrength) {
      final name = _liftNameCtrl.text.trim();
      final w = double.tryParse(_liftWeightCtrl.text.trim());
      if (name.isNotEmpty && w != null) {
        weightKg = w;
        weightReps = int.tryParse(_liftRepsCtrl.text.trim());
        movement = name;
      }
    }

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
      // D94 — 동작별 값은 `movements` 로 구조째 간다. 요약 문장은 서버가 만든다
      // (구 `_movesSummary` 앱 조립 폐기 — 히스토리 둘째 줄이 그 결과다).
    } else {
      final weightKg = double.tryParse(_weightCtrl.text.trim());
      if (weightKg != null && weightKg > 0) notesParts.add('${weightKg}kg');
    }
    if (_notesCtrl.text.trim().isNotEmpty) {
      notesParts.add(_notesCtrl.text.trim());
    }
    final notes = notesParts.join(' · ');
    // D94 — 구조화 글의 동작별 완료 값 (strength 는 최고 무게 한 값이 점수라 제외).
    final movements = (_structured && !_isStrength)
        ? [for (final e in _moves) e.toJson()]
        : null;

    try {
      // 1) 결과 제출.
      final res = await repo.submitWodResult(
        gymId: gym.id,
        wodId: widget.wod.id,
        timeSec: timeSec,
        rounds: rounds,
        extraReps: extra,
        weightKg: weightKg,
        weightReps: weightReps,
        movement: movement,
        scaleLevel: scale,
        notes: notes,
        movements: movements,
      );
      // 2) (D90 · 2026-08-30) 히스토리 행은 서버가 결과 저장과 같은 트랜잭션에서
      //    쓴다 — 종전의 두 번째 POST(/history/wod)는 재저장마다 중복 행을 만들고
      //    라운드를 빠뜨렸다. 앱은 정본에 한 번만 쓴다.
      if (!mounted) return;
      // 3) Attendance / Trends 즉시 reload.
      bus.bump();
      navigator.pop(true);
      // 저장 중 토스트를 걷고, 하이피가 응원하는 결과 토스트 (2026-08-30 사용자 원문).
      // 둘째 줄 = 종전 고지, 셋째 줄 = 서버 비교 문구 ("지난 기록보다 42초 단축 — PR!").
      // (구 +100P 표기는 2026-08-24 첫 제출 적립 폐기와 함께 제거.)
      final msg = res.comparisonMessage;
      messenger.dismiss();
      messenger.info(
        kWodSavedCheer,
        detail: [res.attendanceAdded ? kWodSavedBase : kWodSavedOnly, ?msg],
        mood: MascotMood.happy,
        duration: Duration(seconds: msg == null ? 3 : 5),
      );
      // 폭죽은 D86 과 같은 부품 — PR 을 세운 순간에만 (시트는 이미 닫혀 navigator 의
      // context 로 쏜다).
      if (res.isPr && navigator.mounted) HkConfetti.burst(navigator.context);
    } on AppException catch (e) {
      if (!mounted) return;
      messenger.dismiss();
      setState(() {
        _saving = false;
        _error = e.messageKo;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.dismiss();
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
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(HyphenTokens.r3),
          ),
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
                  Text(
                    wodTypeLabel(widget.wod.wodType),
                    style: HyphenTokens.sectionLabel.copyWith(
                      color: HyphenTokens.accent,
                    ),
                  ),
                  const SizedBox(width: HyphenTokens.sp2),
                  const HkSectionLabel('· 완료 기록'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: HyphenTokens.muted,
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
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

              // ── 내 결과 (칩이 정한 종류의 최소 입력 — v3.15) ──
              const HkSectionLabel('내 결과'),
              const SizedBox(height: HyphenTokens.sp1),
              // 기록 종류 칩 — 게시물 타입은 기본값만 정하고 최종 선택은 회원.
              // custom(수업) 게시물에서 시간·무게 기록일 곳이 없던 갭의 입구.
              Wrap(
                spacing: HyphenTokens.sp2,
                children: [
                  for (final k in _RecordKind.values)
                    HkBadge(
                      _kindLabel(k),
                      color: HyphenTokens.fg,
                      selected: _kind == k,
                      onTap: _saving ? null : () => setState(() => _kind = k),
                    ),
                ],
              ),
              const SizedBox(height: HyphenTokens.sp2),
              // 결함 수정 4 — 재제출 = 덮어쓰기임을 알린다 (프리필과 한 쌍).
              if (widget.wod.myResult != null) ...[
                Text(
                  '이미 저장한 기록이 있습니다 — 저장하면 새 값으로 바뀝니다.',
                  style: HyphenTokens.caption.copyWith(
                    color: HyphenTokens.warning,
                  ),
                ),
                const SizedBox(height: HyphenTokens.sp2),
              ],
              if (_kind == _RecordKind.time) ...[
                _TimeField(controller: _timeCtrl),
              ] else if (_kind == _RecordKind.weight) ...[
                // v3.4 — 무게가 점수. strength 게시물은 게시물이 리프트
                // 그룹이라 이름 생략, 그 외(수업 등)는 이름이 묶음 열쇠.
                if (!_isStrength) ...[
                  ..._liftNameSuggestions(),
                  TextField(
                    controller: _liftNameCtrl,
                    // 칩 selected 상태를 타이핑에도 따라가게.
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: '동작 이름',
                      hintText: '예: Back Squat',
                    ),
                  ),
                  const SizedBox(height: HyphenTokens.sp2),
                ],
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _isStrength
                            ? _stWeightCtrl
                            : _liftWeightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: '오늘 최고 무게 (kg)',
                          hintText: '예: 100',
                        ),
                      ),
                    ),
                    const SizedBox(width: HyphenTokens.sp2),
                    Expanded(
                      child: TextField(
                        controller: _isStrength ? _stRepsCtrl : _liftRepsCtrl,
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
                    // EMOM 만 추가 reps 가 없다 — custom 도 AMRAP 식 기록 가능.
                    if (!_isEmom) ...[
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
              ],
              // v3.14 — 무게 기록 (선택). 근력 파트가 낀 날(BUILD Back
              // Squat 5×5 …) 여기 적으면 최고 기록·PR 로 이어진다.
              // 동작 이름이 같으면 날짜가 달라도 같은 기록으로 묶인다.
              // 무게 칩이 주 기록일 때는 중복이라 숨긴다 (v3.15).
              if (_kind != _RecordKind.weight && !_isStrength) ...[
                const SizedBox(height: HyphenTokens.sp4),
                const HkSectionLabel('무게 기록 (선택)'),
                const SizedBox(height: HyphenTokens.sp1),
                Text(
                  '오늘 리프트를 했으면 적어 주세요 — 최고 기록과 PR 에 반영됩니다.',
                  style: HyphenTokens.caption,
                ),
                const SizedBox(height: HyphenTokens.sp2),
                ..._liftNameSuggestions(),
                TextField(
                  controller: _liftNameCtrl,
                  onChanged: (_) => setState(() {}),
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
                          decimal: true,
                        ),
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

              // ── 동작별 완료 값 (D94) — 코치 값으로 채워져 있고 다르게 했을 때만 고친다 ──
              if (_structured && !_isStrength) ...[
                const HkSectionLabel('동작별 기록'),
                const SizedBox(height: HyphenTokens.sp1),
                const Text(
                  '코치가 정한 값이 채워져 있습니다 — 다르게 했으면 고치세요.',
                  style: HyphenTokens.caption,
                ),
                const SizedBox(height: HyphenTokens.sp1),
                for (final e in _moves)
                  _MovementRow(
                    entry: e,
                    enabled: !_saving,
                    onChanged: () => setState(() {}),
                  ),
              ] else if (!_isStrength) ...[
                // 자유 서술 게시물 — 전체 1선택 (코치 무게는 본문에 이미 있음).
                const HkSectionLabel('난도'),
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                Text(
                  _error!,
                  style: HyphenTokens.caption.copyWith(
                    color: HyphenTokens.warning,
                  ),
                ),
              ],
              const SizedBox(height: HyphenTokens.sp4),
              // 버튼은 '저장' 하나 — 출석 동반 처리는 아래 한 줄로 고지 (GLOSSARY §3).
              // 저장 중엔 버튼 자리 그대로 busy (D67 로그인과 같은 결 — 밀림 0).
              HkButton.primary(
                '저장',
                key: kWodSaveButton,
                icon: Icons.check,
                busy: _saving,
                onPressed: _submit,
              ),
              const SizedBox(height: HyphenTokens.sp2),
              const Text(
                '저장하면 오늘 출석도 함께 기록됩니다.',
                key: kWodSaveCaption,
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

/// 동작 1줄 — 이름 + SCALED/RXD, 아래 [한 횟수][무게 kg] 칸 (D94).
/// 두 칸은 코치가 정한 값으로 채워져 있다. 무게 칸은 코치 무게가 있거나 SCALED 일 때만.
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
    final title = it.name.isEmpty ? it.slug : it.name;
    final showWeight = entry.hasCoachLoad || entry.scaled;
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
          const SizedBox(height: HyphenTokens.sp2),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.repsCtrl,
                  enabled: enabled,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: '한 횟수',
                    hintText: it.reps.isEmpty ? '예: 21-15-9' : it.reps,
                    isDense: true,
                  ),
                ),
              ),
              // 무게 자리는 늘 잡아 둔다 — 칩을 바꿔도 줄 높이가 같다.
              const SizedBox(width: HyphenTokens.sp2),
              Expanded(
                child: showWeight
                    ? TextField(
                        controller: entry.weightCtrl,
                        enabled: enabled,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: '무게 (kg)',
                          hintText: entry.hasCoachLoad
                              ? '코치 ${it.loadValue}${it.loadUnit}'
                              : '선택',
                          isDense: true,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
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
