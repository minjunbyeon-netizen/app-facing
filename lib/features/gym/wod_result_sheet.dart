// v1.20: WOD "완료 표시" 결과 입력 시트.
// 기존 WodSessionScreen 타이머를 거치지 않고 직접 결과 입력 + Attendance 자동 체크.
//
// v3.3 (2026-08-20 사용자 지시 전면 개편): "라운드·스케일·중량·메모가 뭔지 알기
// 어렵다 — 오늘 수업 내용이 그대로 가져와지고 나는 최소한만 입력하게 하라".
// v3.44 (2026-09-02): 시트 다이어트 — 메모·'무게 기록(선택)' 병기·fallback 내 무게 삭제.
//
// v3.45 (2026-09-02 사용자 지시 "코치가 설정한 운동이 그대로 불러와지고 그 옆에
// 자기의 기록만 적을 수 있게. 지금 있는 내 결과·시간·라운드·무게·몇 라운드·추가
// 렙스·난이도·동작 이름·메모 이런 거 전부 없애고 … 이게 그대로 히스토리 저장"):
// - '내 결과' 섹션(기록 종류 칩·시간·라운드·추가 reps·최고 무게·동작 이름) 전부 삭제.
// - 난도(SCALED/RXD) 선택 삭제 — 동작 줄·fallback 양쪽 다. scale_level 은 안 보낸다
//   (서버 기본 rx).
// - 남는 것 = 수업 내용 + 코치 운동 목록([한 횟수][무게] 코치 값 프리필, 내 값만
//   고침) + 저장. strength 도 같은 구조 (구 최고 무게 전용칸 폐기).
// - 구조 없는 자유 서술 게시물 = 수업 내용 + 저장 (완료·출석 기록만).
// - 서버 계약: time_sec 등 점수 키는 보내지 않는다 → 히스토리 label 은 빈 문자열,
//   행 요약은 동작별 값(result_movements_summary)이 맡는다 (api/history.py D94).
//
// D121 (2026-09-05 · 계약 `docs/CONTRACT-result-axes.md`) — **파트 종류가 입력 칸을
// 정한다**. 사용자 지적: "백스쿼트 5×5 수업이면 첫 세트에 몇 kg 로 몇 회 를 적고 싶지
// 않겠나. FOR TIME 은 … 몇 분 만에 끝났나 를 적는 게 중요할 거고."
// v3.45 가 점수 칸을 걷어낸 것은 과밀 해소로는 옳았지만, 파트(D109)가 이틀 뒤에
// 들어오면서 이 시트는 파트도 종류도 못 보고 모든 동작을 평평하게 늘어놓고 있었다.
// - 입력을 **파트로 묶는다** — 서버 `title` 머리줄 아래에 그 파트의 칸 (파트 하나면
//   머리줄 없음).
// - 종류별 칸: for_time = 완주 시간(+캡 종료·남긴 렙스) · amrap = 라운드·추가 회 ·
//   emom = 점수 없음 · strength = 세트별 [무게][횟수] · custom = 동작별 [한 횟수].
// - 무게 칸은 `has_load` 인 동작에만 (토투바·풀업에는 주지 않는다).
// - 축 표의 정본은 서버 `services/result_axes.py` — 앱은 `wod_type`·`has_load`·
//   `set_count` 를 읽어서 그리기만 한다 (대전제 6-b).
// - 검사 = `test/result_axes_test.dart`(칸·payload·프리필) ·
//   `test/golden/stability_result_sheet_test.dart`(파트 넷 시트 밀림).

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

/// 파트 점수가 있는 종류 (계약 §2 축 표). 나머지는 파트 점수 칸이 없다 —
/// strength 는 세트 줄이, emom·custom 은 동작 줄이 대신한다.
const Set<String> _scoredTypes = {'for_time', 'amrap'};

/// 동작 줄에 **한 횟수 칸을 두지 않는** 종류 — 점수 축이 파트에 있어서다.
/// (`custom`(수업)과 종류를 모르는 옛 글은 종전대로 한 횟수 칸을 준다.)
const Set<String> _noRepsTypes = {'for_time', 'amrap', 'emom'};

/// 몇 초를 `분`·`초` 두 칸으로. 서버는 `time_sec` 한 값만 안다 (계약 §3·§4).
(String, String) _splitSec(int sec) =>
    ('${sec ~/ 60}', (sec % 60).toString().padLeft(2, '0'));

/// 무게 실수 → 칸에 넣을 글자 ('60.0' 이 아니라 '60').
String _kgText(double w) => w == w.roundToDouble() ? '${w.toInt()}' : '$w';

/// 동작 **한 줄**의 입력 상태 — 게시물의 WodMovementItem + 회원이 실제 한 값.
///
/// strength 파트는 같은 동작이 세트 수만큼 줄을 갖는다 ([setIndex] 0..n-1).
/// 어떤 칸을 그릴지는 파트 종류와 `has_load` 가 정한다 (계약 §2) — 앱은 그 두 값을
/// 읽어서 그리기만 하고, 축 표 자체는 서버 `services/result_axes.py` 가 정본이다.
class _MoveEntry {
  final WodMovementItem item;
  final int partIndex;

  /// 파트 안 동작 순번 — 입력 칸 키를 만드는 좌표 (같은 동작이 두 번 나올 수 있다).
  final int moveIndex;

  /// strength 세트 번호. 세트가 없는 종류는 null.
  final int? setIndex;

  /// 한 횟수 칸을 그리는가 (파트 종류가 정한다).
  final bool showReps;

  /// 무게 칸을 그리는가 (`has_load` 가 정한다 — 토투바·풀업에는 안 준다).
  final bool showLoad;

  late final TextEditingController repsCtrl = TextEditingController(
    // strength 세트 줄의 코치 reps 는 '5-5-5-5-5' 처럼 **세트 전체**를 적은 글이라
    // 한 줄에 그대로 넣으면 거짓말이 된다. 세트를 가르는 규칙의 정본은 서버
    // (`set_count`)뿐이므로 앱이 다시 쪼개지 않고(6-b) 힌트로만 보여 준다.
    text: setIndex == null ? item.reps : '',
  );
  late final TextEditingController weightCtrl = TextEditingController(
    text: item.loadValue,
  );

  _MoveEntry({
    required this.item,
    required this.partIndex,
    required this.moveIndex,
    required this.setIndex,
    required this.showReps,
    required this.showLoad,
  });

  bool get hasCoachLoad => item.loadValue.isNotEmpty;

  Key get repsKey =>
      WodResultSheet.fieldKey(partIndex, moveIndex, setIndex, 'reps');
  Key get loadKey =>
      WodResultSheet.fieldKey(partIndex, moveIndex, setIndex, 'load');

  /// 저장된 동작별 값이 **이 줄**의 것인가 — 파트·세트가 먼저, 그 다음 동작 신원.
  /// 옛 기록(part_index·set_index 없음)은 첫 파트·첫 세트로 읽힌다 (계약 §4).
  bool matches(MyResultMovement m) {
    if (m.partIndex != partIndex) return false;
    if ((setIndex ?? 0) != (m.setIndex ?? 0)) return false;
    if (item.movementId != null && m.movementId != null) {
      return item.movementId == m.movementId;
    }
    return item.name.trim().toLowerCase() == m.name.trim().toLowerCase();
  }

  void prefill(MyResultMovement m) {
    if (m.reps.isNotEmpty) repsCtrl.text = m.reps;
    if (m.loadKg != null) weightCtrl.text = _kgText(m.loadKg!);
  }

  /// 서버로 보낼 한 줄 (계약 §4). **빈 칸은 아예 빼고**, 둘 다 비었으면 줄 자체를
  /// 보내지 않는다 — 0 을 지어내지 않는다.
  Map<String, dynamic>? toJson() {
    final reps = showReps ? repsCtrl.text.trim() : '';
    final load = showLoad ? double.tryParse(weightCtrl.text.trim()) : null;
    if (reps.isEmpty && load == null) return null;
    return {
      'part_index': partIndex,
      'set_index': ?setIndex,
      'movement_id': ?item.movementId,
      'name': item.name,
      'unit': item.unit,
      if (reps.isNotEmpty) 'reps': reps,
      'load_kg': ?load,
    };
  }

  void dispose() {
    repsCtrl.dispose();
    weightCtrl.dispose();
  }
}

/// 파트 하나의 입력 상태 — 종류가 정하는 점수 칸 + 그 파트의 동작 줄 (계약 §2).
class _PartEntry {
  final WodRoundItem part;

  /// 이 파트의 종류. 파트에 없으면 게시물 종류를 쓴다 (파트 필드가 없던 옛 글).
  final String wodType;
  final List<_MoveEntry> moves;

  /// 캡에 걸려 끝났는가 — for_time 만. 켜면 '남긴 렙스' 칸이 열린다.
  bool capped = false;

  final TextEditingController minCtrl = TextEditingController();
  final TextEditingController secCtrl = TextEditingController();
  final TextEditingController roundsCtrl = TextEditingController();
  final TextEditingController extraCtrl = TextEditingController();

  _PartEntry({required this.part, required this.wodType, required this.moves});

  int get index => part.index;
  bool get isForTime => wodType == 'for_time';
  bool get isAmrap => wodType == 'amrap';
  bool get hasScore => _scoredTypes.contains(wodType);
  bool get hasCap => part.timeCapSec != null;

  /// 이 파트가 시트에 자리를 차지하는가 (점수 칸도 동작 칸도 없으면 그리지 않는다).
  bool get hasAnything => hasScore || moves.isNotEmpty;

  static int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  /// 완주 시간 — 두 칸 다 비었으면 null (0 을 지어내지 않는다).
  int? get _timeSec {
    final m = minCtrl.text.trim();
    final s = secCtrl.text.trim();
    if (m.isEmpty && s.isEmpty) return null;
    return (int.tryParse(m) ?? 0) * 60 + (int.tryParse(s) ?? 0);
  }

  void prefill(MyResultPart p) {
    if (p.timeSec != null) {
      final (m, s) = _splitSec(p.timeSec!);
      minCtrl.text = m;
      secCtrl.text = s;
    }
    if (p.rounds != null) roundsCtrl.text = '${p.rounds}';
    if (p.extraReps != null) extraCtrl.text = '${p.extraReps}';
    capped = p.capped;
  }

  /// 서버로 보낼 파트 점수 (계약 §4). 적은 것이 없으면 null — 그 파트는 안 보낸다.
  /// `wod_type` 은 담지 않는다 (서버가 게시물에서 읽는다).
  Map<String, dynamic>? toJson() {
    if (isForTime) {
      final t = _timeSec;
      final extra = capped ? _int(extraCtrl) : null;
      if (t == null && extra == null) return null;
      return {
        'index': index,
        'time_sec': ?t,
        'extra_reps': ?extra,
        'capped': capped,
      };
    }
    if (isAmrap) {
      final r = _int(roundsCtrl);
      final e = _int(extraCtrl);
      if (r == null && e == null) return null;
      return {'index': index, 'rounds': ?r, 'extra_reps': ?e};
    }
    return null;
  }

  void dispose() {
    minCtrl.dispose();
    secCtrl.dispose();
    roundsCtrl.dispose();
    extraCtrl.dispose();
    for (final m in moves) {
      m.dispose();
    }
  }
}

class WodResultSheet extends StatefulWidget {
  /// 수업 내용 블록 — 잘리지 않는지 재는 앵커 (2026-09-05).
  static const Key kWodContent = Key('wod-result-content');

  /// 파트 점수 칸의 키 — (파트 index, 칸). 칸 = min·sec·rounds·extra·cap.
  /// 검사가 종류별로 어떤 칸이 섰는지 집어 볼 수 있게 (계약 D121 §7).
  static Key partFieldKey(int part, String field) =>
      ValueKey('wod-p-$part-$field');

  /// 동작 입력 칸의 키 — (파트 index, 파트 안 동작 순번, 세트 index, 칸).
  /// 세트가 없는 종류는 [set] 이 null. 칸 = load·reps.
  static Key fieldKey(int part, int move, int? set, String field) =>
      ValueKey('wod-f-$part-$move-${set ?? 'x'}-$field');

  final GymWodPost wod;
  const WodResultSheet({super.key, required this.wod});

  @override
  State<WodResultSheet> createState() => _WodResultSheetState();
}

class _WodResultSheetState extends State<WodResultSheet> {
  bool _saving = false;
  String? _error;

  late final List<_PartEntry> _parts;

  Iterable<_MoveEntry> get _moves => _parts.expand((p) => p.moves);

  /// 게시물에 적을 칸이 하나라도 있으면 입력 면, 없으면 수업 내용 + 저장뿐 (v3.45).
  bool get _structured => _parts.any((p) => p.hasAnything);

  @override
  void initState() {
    super.initState();
    _parts = [
      for (final r in widget.wod.roundsData)
        _buildPart(r, fallbackType: widget.wod.wodType),
    ]..removeWhere((p) => !p.hasAnything);

    // 재수정이면 저장된 값으로 프리필 — 빈 시트로 열려 조용히 덮어쓰던 문제의
    // 픽스(2026-08-20)는 그대로 산다. 파트 점수는 index 로, 동작은 파트·세트로 붙는다.
    final mr = widget.wod.myResult;
    if (mr != null) {
      for (final saved in mr.parts) {
        for (final p in _parts) {
          if (p.index == saved.index) p.prefill(saved);
        }
      }
      for (final saved in mr.movements) {
        for (final e in _moves) {
          if (e.matches(saved)) e.prefill(saved);
        }
      }
    }
  }

  /// 파트 하나를 입력 상태로 편다 — 종류가 칸을, `has_load` 가 무게 칸을,
  /// `set_count` 가 세트 줄 수를 정한다 (계약 §2). 규칙의 정본은 서버다.
  _PartEntry _buildPart(WodRoundItem r, {required String fallbackType}) {
    final type = (r.wodType?.isNotEmpty == true) ? r.wodType! : fallbackType;
    final showReps = !_noRepsTypes.contains(type);
    final isStrength = type == 'strength';
    final moves = <_MoveEntry>[];
    for (var i = 0; i < r.movements.length; i++) {
      final m = r.movements[i];
      // 세트 줄 수는 서버 `set_count` — 없거나 0 이하면 한 줄 (줄이 아예 없으면
      // 그 동작을 못 적는다).
      final sets = isStrength ? ((m.setCount ?? 1) < 1 ? 1 : m.setCount!) : 1;
      for (var s = 0; s < sets; s++) {
        // 아무 칸도 안 서는 동작은 줄 자체를 만들지 않는다 (죽은 줄 금지).
        if (!showReps && !m.hasLoad) continue;
        moves.add(
          _MoveEntry(
            item: m,
            partIndex: r.index,
            moveIndex: i,
            setIndex: isStrength ? s : null,
            showReps: showReps,
            showLoad: m.hasLoad,
          ),
        );
      }
    }
    return _PartEntry(part: r, wodType: type, moves: moves);
  }

  @override
  void dispose() {
    for (final p in _parts) {
      p.dispose();
    }
    super.dispose();
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

    // D121 계약 §4 — 파트 점수 + 동작별 기록. 둘 다 **적은 것만** 담는다
    // (빈 칸은 아예 빼고 보낸다 — 0 을 지어내지 않는다). 구 점수 키(time_sec 등
    // 최상위)·난도·메모는 v3.45 에서 걷어낸 그대로 안 보낸다.
    final movements = _structured
        ? [for (final e in _moves) ?e.toJson()]
        : null;
    final parts = _structured ? [for (final p in _parts) ?p.toJson()] : null;

    try {
      // 1) 결과 제출.
      final res = await repo.submitWodResult(
        gymId: gym.id,
        wodId: widget.wod.id,
        movements: movements,
        parts: (parts == null || parts.isEmpty) ? null : parts,
      );
      // 2) (D90 · 2026-08-30) 히스토리 행은 서버가 결과 저장과 같은 트랜잭션에서
      //    쓴다 — 앱은 정본에 한 번만 쓴다.
      if (!mounted) return;
      // 3) Attendance / Trends 즉시 reload.
      bus.bump();
      navigator.pop(true);
      // 저장 중 토스트를 걷고, 하이피가 응원하는 결과 토스트 (2026-08-30 사용자 원문).
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
              //
              // 2026-09-05 실사용 검증에서 잡음: `maxLines: 4` 는 파트가 생기기
              // 전(D109 이전) 값이라, A·B 두 파트짜리 수업을 열면 A 파트에서
              // 잘려 **자기가 지금 적는 B 파트 동작이 안 보였다**. 시트는 이미
              // 스크롤되므로 자를 이유가 없다. 게이트 = test/result_sheet_content_test.dart.
              Text(
                widget.wod.content,
                key: WodResultSheet.kWodContent,
                style: HyphenTokens.caption,
              ),
              const SizedBox(height: HyphenTokens.sp4),

              // 재제출 = 덮어쓰기임을 알린다 (프리필과 한 쌍, 2026-08-20 픽스).
              if (widget.wod.myResult != null) ...[
                Text(
                  '이미 저장한 기록이 있습니다 — 저장하면 새 값으로 바뀝니다.',
                  style: HyphenTokens.caption.copyWith(
                    color: HyphenTokens.warning,
                  ),
                ),
                const SizedBox(height: HyphenTokens.sp2),
              ],

              // ── 내 기록 — 파트로 묶고, 파트 종류가 칸을 정한다 (계약 D121 §2) ──
              if (_structured) ...[
                const HkSectionLabel('내 기록'),
                const SizedBox(height: HyphenTokens.sp1),
                const Text(
                  '코치가 정한 값이 채워져 있습니다 — 다르게 했으면 고치세요.',
                  style: HyphenTokens.caption,
                ),
                const SizedBox(height: HyphenTokens.sp2),
                for (final p in _parts)
                  _PartBlock(
                    entry: p,
                    enabled: !_saving,
                    multi: _parts.length > 1,
                    onCapped: (v) => setState(() => p.capped = v),
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
              // D117 — 실패 문구는 **이미 있는 이 한 줄 자리**에서 글자만 바뀐다.
              // 종전에는 버튼 위에 조건부 블록으로 생겨 버튼과 이 줄을 27px 밀어
              // 내렸다 — 실패 직후가 다시 누르기 가장 쉬운 순간인데 손가락 아래에서
              // 버튼이 도망갔다. 빈 띠를 새로 예약하지 않고 문장을 교체하는 쪽이
              // DESIGN-SSOT §레이아웃 안정성 의 '빈 띠 없이 자리를 지키는 법' 이다.
              Text(
                _error ?? '저장하면 오늘 출석도 함께 기록됩니다.',
                key: kWodSaveCaption,
                style: _error == null
                    ? HyphenTokens.caption
                    : HyphenTokens.caption.copyWith(
                        color: HyphenTokens.warning,
                      ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 파트 한 덩이 — 서버가 그린 머리줄 + 그 종류의 점수 칸 + 동작 줄 (계약 §2).
///
/// 머리줄 글자는 서버 `program_lines.api_rounds` 가 만든 것을 그대로 놓는다
/// (수업 탭 카드와 같은 부품 결 — 앱이 조립하지 않는다, 대전제 6-b).
class _PartBlock extends StatelessWidget {
  final _PartEntry entry;
  final bool enabled;
  final ValueChanged<bool> onCapped;

  /// 파트가 둘 이상인가 — 하나뿐이면 머리줄을 세우지 않는다 (수업 탭 카드와 같은
  /// 규칙: 파트가 하나면 나눌 것이 없다). 서버가 `title` 을 준 파트는 항상 세운다.
  final bool multi;
  const _PartBlock({
    required this.entry,
    required this.enabled,
    required this.onCapped,
    required this.multi,
  });

  @override
  Widget build(BuildContext context) {
    final head = entry.part.title.isNotEmpty
        ? entry.part.title
        : (multi ? entry.part.label : '');
    return Padding(
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (head.isNotEmpty) ...[
            HkSectionLabel(head),
            const SizedBox(height: HyphenTokens.sp1),
          ],
          if (entry.isForTime) _ForTimeScore(entry: entry, enabled: enabled, onCapped: onCapped),
          if (entry.isAmrap) _AmrapScore(entry: entry, enabled: enabled),
          for (final e in entry.moves) _MovementRow(entry: e, enabled: enabled),
        ],
      ),
    );
  }
}

/// 칸 하나 — 화면 어디서든 같은 규격. 라벨·힌트만 다르다.
class _Field extends StatelessWidget {
  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final bool numeric;
  const _Field({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.enabled,
    this.hint,
    this.numeric = true,
  });

  @override
  Widget build(BuildContext context) => TextField(
    key: fieldKey,
    controller: controller,
    enabled: enabled,
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
    ),
  );
}

/// FOR TIME — 몇 분 만에 끝났나. 캡이 걸린 파트는 '캡 종료' + 남긴 렙스가 따라온다.
///
/// 캡 줄은 **켜든 껐든 같은 자리**에 있다 (남긴 렙스 칸이 켤 때 생기면 그 아래가
/// 통째로 밀린다 — DESIGN-SSOT §레이아웃 안정성).
class _ForTimeScore extends StatelessWidget {
  final _PartEntry entry;
  final bool enabled;
  final ValueChanged<bool> onCapped;
  const _ForTimeScore({
    required this.entry,
    required this.enabled,
    required this.onCapped,
  });

  @override
  Widget build(BuildContext context) => Padding(
    // 이 자리의 **높이**가 캡을 켜고 꺼도 같아야 한다 — 안정성 게이트가 잰다
    // (`stability_result_sheet_test.dart`). 앵커 y 만 재면 스크롤이 차이를
    // 감춘다(2026-09-05 실측): 자리 높이로 재야 잡힌다.
    key: WodResultSheet.partFieldKey(entry.index, 'score'),
    padding: const EdgeInsets.only(bottom: HyphenTokens.sp2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _Field(
                fieldKey: WodResultSheet.partFieldKey(entry.index, 'min'),
                controller: entry.minCtrl,
                label: '완주 시간 (분)',
                hint: '0',
                enabled: enabled,
              ),
            ),
            const SizedBox(width: HyphenTokens.sp2),
            Expanded(
              child: _Field(
                fieldKey: WodResultSheet.partFieldKey(entry.index, 'sec'),
                controller: entry.secCtrl,
                label: '초',
                hint: '00',
                enabled: enabled,
              ),
            ),
          ],
        ),
        if (entry.hasCap) ...[
          const SizedBox(height: HyphenTokens.sp1),
          Row(
            children: [
              HkCheckRow(
                key: WodResultSheet.partFieldKey(entry.index, 'cap'),
                value: entry.capped,
                label: '캡 종료',
                onChanged: enabled ? onCapped : (_) {},
              ),
              const SizedBox(width: HyphenTokens.sp2),
              Expanded(
                child: _Field(
                  fieldKey: WodResultSheet.partFieldKey(entry.index, 'extra'),
                  controller: entry.extraCtrl,
                  label: '남긴 렙스',
                  hint: entry.capped ? '0' : '캡 종료일 때만',
                  enabled: enabled && entry.capped,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

/// AMRAP — 몇 라운드 + 추가 몇 회.
class _AmrapScore extends StatelessWidget {
  final _PartEntry entry;
  final bool enabled;
  const _AmrapScore({required this.entry, required this.enabled});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: HyphenTokens.sp2),
    child: Row(
      children: [
        Expanded(
          child: _Field(
            fieldKey: WodResultSheet.partFieldKey(entry.index, 'rounds'),
            controller: entry.roundsCtrl,
            label: '라운드',
            hint: '0',
            enabled: enabled,
          ),
        ),
        const SizedBox(width: HyphenTokens.sp2),
        Expanded(
          child: _Field(
            fieldKey: WodResultSheet.partFieldKey(entry.index, 'extra'),
            controller: entry.extraCtrl,
            label: '추가 회',
            hint: '0',
            enabled: enabled,
          ),
        ),
      ],
    ),
  );
}

/// 동작 1줄 — 코치가 정한 동작 이름 + 그 종류가 정한 칸 (계약 §2).
/// strength 는 세트마다 한 줄이고 이름 자리에 '1세트' 가 붙는다.
/// 무게 칸은 `has_load` 인 동작에만 — 토투바·풀업에 무게 칸을 주지 않는다.
class _MovementRow extends StatelessWidget {
  final _MoveEntry entry;
  final bool enabled;
  const _MovementRow({required this.entry, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final it = entry.item;
    final name = it.name.isEmpty ? it.slug : it.name;
    final title = entry.setIndex == null
        ? name
        : '$name · ${entry.setIndex! + 1}세트';
    final fields = <Widget>[
      if (entry.showLoad)
        _Field(
          fieldKey: entry.loadKey,
          controller: entry.weightCtrl,
          label: '무게 (kg)',
          hint: entry.hasCoachLoad ? '코치 ${it.loadValue}${it.loadUnit}' : '선택',
          enabled: enabled,
        ),
      if (entry.showReps)
        _Field(
          fieldKey: entry.repsKey,
          controller: entry.repsCtrl,
          label: entry.setIndex == null ? '한 횟수' : '횟수',
          hint: it.reps.isEmpty ? '예: 21-15-9' : it.reps,
          enabled: enabled,
          numeric: false,
        ),
    ];
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
          Text(
            title,
            style: HyphenTokens.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: HyphenTokens.sp2),
          Row(
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(width: HyphenTokens.sp2),
                Expanded(child: fields[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
