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
//
// D122 (2026-09-06 · 계약 `docs/CONTRACT-result-axes-2.md`) — **축을 서버가 내려준다.**
// D121 은 축 표를 앱에 리터럴로 복제해 뒀다 (`_scoredTypes`·`_noRepsTypes`) — 새 종류나
// 축 변경마다 앱 재배포와 스토어 심사가 필요한 상태였다. 이제 파트마다 서버가
// `score_keys`·`score_labels`·`score_target`·`score_hints`·`show_movement_reps`·`set_based` 를 싣고,
// 이 파일은 **그 열쇠만 보고 위젯을 고른다** (종류 이름을 보지 않는다).
// - EMOM 에 점수가 생겼다 — `rounds`(라벨 '완료한 분', 힌트 = duration_min). 종전에는
//   적을 칸이 없어 **파트 자체가 사라졌다** ("D 파트는 왜 없지?").
// - AMRAP 오른 칸은 '추가 회' → **'+ 회'** (뜻이 정반대로 읽히던 라벨) + 늘 있는
//   고정 높이 안내 한 줄 + 힌트 `N 미만`(서버 `score_hints` 문장 — D124, 앱 조립 금지).
// - 입력 칸이 없는 동작은 사라지지 않고 **서버 `lines`** 로 선다 (읽기 전용).
// - 세트 줄 횟수는 서버 `set_reps` — 앱은 코치 처방을 쪼개지 않는다.
// - 검사 = `test/result_axes2_test.dart`(정적 사본 금지 + 종류별 칸 + 힌트·라벨) ·
//   `test/golden/stability_result_sheet_test.dart`(파트·세트가 늘어도 밀림 0).
//
// D125 (2026-09-06 · 가시성 점검 `docs/audit-visibility-2026-09-06.html` §1, 사용자 "1") —
// **보이는 것을 고쳤다. 축·키·payload 는 그대로다.**
// - 숫자 칸이 전폭 TextField 라 1~3자리 값이 왼쪽 구석에 묻혔다 → `HkNumberField`
//   (폭 고정 · 오른쪽 정렬 · 단위는 칸 밖 · 라벨은 항상 칸 위). 폭은 `_W` 한 곳.
// - 빈 칸의 이름이 placeholder 색(2.56:1)뿐이었다 → 라벨(fgSecondary 7.7:1)이 늘 선다.
//   placeholder 는 예시 숫자·서버 힌트 문장만.
// - 세트 5개 = 카드 5장(565dp) → 동작 이름 한 줄 + `1세트 [100] kg × [5] 회` 줄(48dp).
// - 파트 머리가 안의 항목보다 작고 연했다 → `HkSectionLabel(strong: true)`.
// - 저장 버튼이 두 화면 아래로 밀렸다 → 시트 바닥에 **고정 저장 바**(머리 고정 · 본문만 스크롤).
//   그래서 이 위젯은 **높이가 유한한 자리**에 놓아야 한다 (HkSheet · Scaffold body).
//   검사·골든도 같은 구조로 올린다 (`SingleChildScrollView` 로 감싸지 않는다).
// - 수업 내용 본문은 접지 않는다 — D120(B 파트가 안 보이던 것)·v3.45 "코치 운동이
//   그대로 불러와지고" 를 지킨다. 색만 fgSecondary 로 올렸다.

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

/// AMRAP '+ 회' 안내 (계약 D122 §5). `추가 회` 는 한국어로 "정해진 것에 더해서" 로
/// 읽히는데 실제 뜻은 정반대다 — 마지막 라운드를 다 못 채우고 한 만큼이다.
/// 점수 칸 아래 **늘 있는 고정 높이 한 줄** (상태에 따라 생겼다 사라지면 아래가 밀린다).
const String kAmrapExtraNote = '마지막 라운드에서 한 횟수를 적습니다';

/// 숫자 칸 폭 (D125) — 값의 자릿수와 힌트 문장 길이에 맞춘다. 여기 한 곳.
/// 분·초 두 자리 · 라운드 두 자리 · '완료한 분'(힌트 '10분 중') · '+ 회'/'남긴 렙스'(힌트
/// '21 미만'·'캡 종료일 때만') · 무게 세 자리+소수 · 세트 횟수 한두 자리 · 자유 목표('21-15-9').
class _W {
  static const double minSec = 88;
  static const double rounds = 96;
  static const double roundsHinted = 112;
  static const double extra = 128;
  static const double load = 88;
  static const double setReps = 72;
  static const double freeReps = 112;

  /// 세트 줄 왼쪽 '1세트' 칸.
  static const double setLabel = 52;
}

/// 시트 바닥 고정 저장 바 — 안정성 검사·골든이 집는 앵커 (D125).
const Key kWodSaveBar = ValueKey('wod-result-save-bar');

/// 서버 `score_keys` 가 주는 **점수 칸의 열쇠**. 앱은 이 글자를 보고 어떤 위젯을
/// 세울지만 안다 — 어느 종류가 어떤 열쇠를 갖는지는 서버 `services/result_axes.py`
/// 한 곳이 정한다 (계약 D122 §3 · 대전제 6-b).
class _ScoreKey {
  static const time = 'time_sec';
  static const capped = 'capped';
  static const rounds = 'rounds';
  static const extraReps = 'extra_reps';
}

/// 몇 초를 `분`·`초` 두 칸으로. 서버는 `time_sec` 한 값만 안다 (계약 §3·§4).
(String, String) _splitSec(int sec) =>
    ('${sec ~/ 60}', (sec % 60).toString().padLeft(2, '0'));

/// 무게 실수 → 칸에 넣을 글자 ('60.0' 이 아니라 '60').
String _kgText(double w) => w == w.roundToDouble() ? '${w.toInt()}' : '$w';

/// 동작 **한 줄**의 입력 상태 — 게시물의 WodMovementItem + 회원이 실제 한 값.
///
/// 세트 축 파트는 같은 동작이 세트 수만큼 줄을 갖는다 ([setIndex] 0..n-1).
/// 어떤 칸을 그릴지는 서버 `show_movement_reps`·`has_load` 가 정한다 (계약 D122 §3) —
/// 앱은 그 값을 읽어서 그리기만 하고, 축 표 자체는 서버 `result_axes.py` 가 정본이다.
class _MoveEntry {
  final WodMovementItem item;
  final int partIndex;

  /// 파트 안 동작 순번 — 입력 칸 키를 만드는 좌표 (같은 동작이 두 번 나올 수 있다).
  final int moveIndex;

  /// strength 세트 번호. 세트가 없는 종류는 null.
  final int? setIndex;

  /// 한 횟수 칸을 그리는가 (서버 `show_movement_reps` 가 정한다).
  final bool showReps;

  /// 무게 칸을 그리는가 (`has_load` 가 정한다 — 토투바·풀업에는 안 준다).
  final bool showLoad;

  /// 서버가 그린 동작 줄 ('Toes-to-bar 9회'). 입력 칸이 하나도 없는 동작을
  /// **읽기 전용**으로 세울 때만 쓴다 (계약 D122 §5 — 줄이 사라지면 화면이 없는 척한다).
  final String line;

  /// 이 줄에 적을 칸이 하나도 없는가 — 서버 줄만 보여 준다.
  bool get isReadOnly => !showReps && !showLoad;

  /// 이 줄이 요구하는 횟수 — 세트 줄은 **그 세트의 목표**(서버 `set_reps`), 아니면
  /// 코치가 적은 글 그대로. 세트를 가르는 규칙의 정본은 서버다 (앱은 쪼개지 않는다).
  String get repsTarget =>
      setIndex == null ? item.reps : item.setRepsAt(setIndex!);

  late final TextEditingController repsCtrl = TextEditingController(
    text: repsTarget,
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
    this.line = '',
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

/// 파트 하나의 입력 상태 — **서버 `score_keys` 가 정하는** 점수 칸 + 그 파트의 동작 줄
/// (계약 D122 §3). 앱은 종류 이름을 보지 않는다.
class _PartEntry {
  final WodRoundItem part;
  final List<_MoveEntry> moves;

  /// 캡에 걸려 끝났는가. 켜면 '남긴 렙스' 칸이 열린다.
  bool capped = false;

  final TextEditingController minCtrl = TextEditingController();
  final TextEditingController secCtrl = TextEditingController();
  final TextEditingController roundsCtrl = TextEditingController();
  final TextEditingController extraCtrl = TextEditingController();

  _PartEntry({required this.part, required this.moves});

  int get index => part.index;

  /// 점수 칸 — 전부 서버가 준 열쇠로만 판단한다.
  bool get showsTime => part.hasScoreKey(_ScoreKey.time);
  bool get showsRounds => part.hasScoreKey(_ScoreKey.rounds);

  /// 캡 종료 줄 — 열쇠가 있고 **그 파트에 실제로 캡이 걸려 있을 때만**.
  /// (캡이 없는 수업에 '캡 종료' 를 물으면 없는 규칙을 지어내는 것이다.)
  bool get showsCap => part.hasScoreKey(_ScoreKey.capped) && part.timeCapSec != null;

  /// 남은 렙스 칸. `capped` 열쇠와 짝인 모양(FOR TIME)에서는 **캡이 걸린 파트에만**
  /// 뜻이 있다 — 캡이 없으면 남길 렙스라는 개념 자체가 없다.
  bool get showsExtra =>
      part.hasScoreKey(_ScoreKey.extraReps) &&
      (!part.hasScoreKey(_ScoreKey.capped) || showsCap);

  /// '+ 회' 안내 줄 — 라운드와 추가 회를 함께 갖는 모양에만 뜻이 있다 (계약 §5).
  /// 완주 시간이 있는 모양의 `extra_reps` 는 '남긴 렙스' 라 뜻이 다르다.
  bool get showsExtraNote => showsRounds && showsExtra;

  bool get hasScore => part.scoreKeys.isNotEmpty;

  /// 점수 칸의 라벨 — 한글도 서버가 준다 (앱에 심지 않는다, 대전제 6-b).
  String labelOf(String key) => part.scoreLabels[key] ?? '';

  /// 이 파트가 시트에 자리를 차지하는가. 동작 줄이 하나라도 있으면(읽기 전용이라도)
  /// 남는다 — 적을 칸이 없다고 파트를 지우면 "이 파트는 왜 없지?" 가 된다 (계약 §4).
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

  /// 서버로 보낼 파트 점수 (계약 §4). **화면에 선 칸만** 담고, 적은 것이 없으면
  /// null — 그 파트는 안 보낸다 (0 을 지어내지 않는다).
  /// `wod_type` 은 담지 않는다 (서버가 게시물에서 읽는다).
  Map<String, dynamic>? toJson() {
    if (!hasScore) return null;
    final t = showsTime ? _timeSec : null;
    final r = showsRounds ? _int(roundsCtrl) : null;
    // 캡 줄이 있는데 안 켰으면 '남긴 렙스' 칸은 잠겨 있다 — 값도 없다.
    final e = (showsExtra && !(showsCap && !capped)) ? _int(extraCtrl) : null;
    if (t == null && r == null && e == null) return null;
    return {
      'index': index,
      'time_sec': ?t,
      'rounds': ?r,
      'extra_reps': ?e,
      if (showsCap) 'capped': capped,
    };
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
      for (final r in widget.wod.roundsData) _buildPart(r),
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

  /// 파트 하나를 입력 상태로 편다 — **서버가 정한다**: `show_movement_reps` 가 한 횟수
  /// 칸을, `has_load` 가 무게 칸을, `set_based`·`set_reps` 가 세트 줄을 (계약 D122 §3·§6).
  _PartEntry _buildPart(WodRoundItem r) {
    final moves = <_MoveEntry>[];
    for (var i = 0; i < r.movements.length; i++) {
      final m = r.movements[i];
      final showLoad = m.hasLoad;
      if (!r.showMovementReps && !showLoad) {
        // 적을 칸이 하나도 없는 동작 — 사라지게 두지 않고 서버가 그린 줄로 세운다
        // (계약 §5). 줄이 없으면 앱이 지어낼 수 없으므로 그때만 뺀다.
        final line = r.lineFor(i);
        if (line.isEmpty) continue;
        moves.add(
          _MoveEntry(
            item: m,
            partIndex: r.index,
            moveIndex: i,
            setIndex: null,
            showReps: false,
            showLoad: false,
            line: line,
          ),
        );
        continue;
      }
      // 세트 줄 수는 서버 `set_reps` 길이(없으면 `set_count`) — 앱은 쪼개지 않는다.
      final sets = r.setBased ? m.setLines : 1;
      for (var s = 0; s < sets; s++) {
        moves.add(
          _MoveEntry(
            item: m,
            partIndex: r.index,
            moveIndex: i,
            setIndex: r.setBased ? s : null,
            showReps: r.showMovementReps,
            showLoad: showLoad,
          ),
        );
      }
    }
    return _PartEntry(part: r, moves: moves);
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
        // D125 — 머리(고정) · 본문(스크롤) · 저장 바(고정) 세 층. 세트가 늘어도
        // 저장 버튼은 손가락 아래 그 자리다. 높이가 유한한 자리에만 놓는다.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HyphenTokens.sp4,
                HyphenTokens.sp3,
                HyphenTokens.sp2,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    widget.wod.wodTypeLabel,
                    style: HyphenTokens.sectionLabel.copyWith(
                      color: HyphenTokens.accent,
                    ),
                  ),
                  const SizedBox(width: HyphenTokens.sp2),
                  const Text('완료 기록', style: HyphenTokens.h3),
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
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  HyphenTokens.sp4,
                  HyphenTokens.sp1,
                  HyphenTokens.sp4,
                  HyphenTokens.sp3,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 오늘 수업 내용 — 그대로 가져온다 (내가 다시 적지 않는다).
                    //
                    // 2026-09-05 실사용 검증에서 잡음: `maxLines: 4` 는 파트가 생기기
                    // 전(D109 이전) 값이라, A·B 두 파트짜리 수업을 열면 A 파트에서
                    // 잘려 **자기가 지금 적는 B 파트 동작이 안 보였다**. 시트는 이미
                    // 스크롤되므로 자를 이유가 없다. 게이트 = test/result_sheet_content_test.dart.
                    // D125 — 색만 fgSecondary(7.7:1). 본문은 접지 않는다.
                    Text(
                      widget.wod.content,
                      key: WodResultSheet.kWodContent,
                      style: HyphenTokens.caption.copyWith(
                        color: HyphenTokens.fgSecondary,
                      ),
                    ),
                    const SizedBox(height: HyphenTokens.sp3),

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

                    // ── 내 기록 — 파트로 묶고, 서버 score_keys 가 칸을 정한다 (D122 §3) ──
                    if (_structured) ...[
                      const Divider(
                        height: HyphenTokens.sp4,
                        thickness: 1,
                        color: HyphenTokens.border,
                      ),
                      const HkSectionLabel('내 기록'),
                      const SizedBox(height: HyphenTokens.sp1),
                      const Text(
                        '코치가 정한 값이 채워져 있습니다 — 다르게 했으면 고치세요.',
                        style: HyphenTokens.caption,
                      ),
                      const SizedBox(height: HyphenTokens.sp3),
                      for (final p in _parts)
                        _PartBlock(
                          entry: p,
                          enabled: !_saving,
                          multi: _parts.length > 1,
                          onCapped: (v) => setState(() => p.capped = v),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            // 저장 바 — 시트 바닥 고정 (D125). 버튼은 '저장' 하나 — 출석 동반 처리는
            // 아래 한 줄로 고지 (GLOSSARY §3). 저장 중엔 버튼 자리 그대로 busy
            // (D67 로그인과 같은 결 — 밀림 0).
            Container(
              key: kWodSaveBar,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: HyphenTokens.border)),
              ),
              padding: const EdgeInsets.fromLTRB(
                HyphenTokens.sp4,
                HyphenTokens.sp3,
                HyphenTokens.sp4,
                HyphenTokens.sp3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
          ],
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
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (head.isNotEmpty) ...[
            // D125 — 묶음 제목은 안의 항목보다 무거워야 한다 (strong).
            HkSectionLabel(head, strong: true),
            const SizedBox(height: HyphenTokens.sp2),
          ],
          if (entry.hasScore)
            _PartScore(entry: entry, enabled: enabled, onCapped: onCapped),
          // 동작 이름은 동작마다 한 번 — 세트 줄은 그 아래 '1세트 · 2세트 …' 로 선다.
          for (final e in entry.moves) ...[
            if (!e.isReadOnly && (e.setIndex ?? 0) == 0)
              Padding(
                padding: const EdgeInsets.only(
                  top: HyphenTokens.sp1,
                  bottom: HyphenTokens.sp1,
                ),
                child: Text(
                  e.item.name.isEmpty ? e.item.slug : e.item.name,
                  style: HyphenTokens.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            _MovementRow(entry: e, enabled: enabled),
          ],
        ],
      ),
    );
  }
}

/// 파트 점수 — **어떤 칸을 세울지는 서버 `score_keys` 가 정한다** (계약 D122 §3).
/// 앱은 열쇠(`time_sec`·`capped`·`rounds`·`extra_reps`)를 보고 위젯만 고르고,
/// 라벨은 서버 `score_labels` 를 그대로 쓴다 (한글을 앱에 심지 않는다 — 대전제 6-b).
///
/// 자리의 **높이**는 상태가 바뀌어도 같아야 한다 — 캡을 켜면 '남긴 렙스' 칸이 생기는
/// 식으로 만들면 그 아래가 통째로 밀린다 (DESIGN-SSOT §레이아웃 안정성). 그래서 칸을
/// 늘 그려 두고 `enabled` 만 바꾸고, 안내 줄도 고정 높이로 늘 세워 둔다.
class _PartScore extends StatelessWidget {
  final _PartEntry entry;
  final bool enabled;
  final ValueChanged<bool> onCapped;
  const _PartScore({
    required this.entry,
    required this.enabled,
    required this.onCapped,
  });

  /// '남긴 렙스' 칸의 힌트. 캡 줄과 짝이면 캡을 켜야 열린다는 뜻(화면 상태)을 적고,
  /// 아니면 서버 `score_hints['extra_reps']`('21 미만') 를 그대로 (계약 §5 · D124 —
  /// 앱이 `score_target` 숫자로 문장을 조립하지 않는다). 없으면 빈 값 표시 '0'.
  String get _extraHint {
    if (entry.showsCap) return entry.capped ? '0' : '캡 종료일 때만';
    return entry.part.scoreHints[_ScoreKey.extraReps] ?? '0';
  }

  /// 라운드 칸의 힌트. '추가 회' 칸이 따로 없는 모양(EMOM)에서는 서버
  /// `score_hints['rounds']`('10분 중') 가 이 칸의 기준이다 (계약 §4 · D124).
  String get _roundsHint {
    if (entry.showsExtra) return '0';
    return entry.part.scoreHints[_ScoreKey.rounds] ?? '0';
  }

  @override
  Widget build(BuildContext context) {
    // '남긴 렙스'/'+ 회' 칸 — 라벨은 서버 것, 힌트 문장도 서버 것 (D124). 폭은 힌트가
    // 다 보이는 128 (D125 · `_W.extra`).
    final extraField = HkNumberField(
      fieldKey: WodResultSheet.partFieldKey(entry.index, 'extra'),
      controller: entry.extraCtrl,
      label: entry.labelOf(_ScoreKey.extraReps),
      hint: _extraHint,
      width: _W.extra,
      enabled: enabled && (!entry.showsCap || entry.capped),
    );
    return Padding(
      // 이 자리의 높이를 안정성 게이트가 잰다 (`stability_result_sheet_test.dart`).
      // 앵커 y 만 재면 스크롤이 차이를 감춘다(2026-09-05 실측).
      key: WodResultSheet.partFieldKey(entry.index, 'score'),
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 완주 시간 — 서버는 `time_sec` 한 값만 안다. 분·초 두 칸은 앱이 나눠 받는
          // 방식일 뿐이고(§4 `_splitSec`), 무엇을 묻는지는 서버 라벨이 말한다.
          // 라벨은 첫 칸 위에 한 번, 둘째 칸은 빈 라벨 줄로 y 를 맞춘다 (D125).
          if (entry.showsTime)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                HkNumberField(
                  fieldKey: WodResultSheet.partFieldKey(entry.index, 'min'),
                  controller: entry.minCtrl,
                  label: entry.labelOf(_ScoreKey.time),
                  hint: '0',
                  unit: '분',
                  width: _W.minSec,
                  enabled: enabled,
                ),
                const SizedBox(width: HyphenTokens.sp3),
                HkNumberField(
                  fieldKey: WodResultSheet.partFieldKey(entry.index, 'sec'),
                  controller: entry.secCtrl,
                  label: '',
                  hint: '00',
                  unit: '초',
                  width: _W.minSec,
                  enabled: enabled,
                ),
              ],
            ),
          // 라운드(+ 회) — 캡 줄이 따로 있는 모양에서는 '남긴 렙스' 가 캡 줄로 간다.
          if (entry.showsRounds || (entry.showsExtra && !entry.showsCap)) ...[
            if (entry.showsTime) const SizedBox(height: HyphenTokens.sp2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (entry.showsRounds)
                  HkNumberField(
                    fieldKey: WodResultSheet.partFieldKey(
                      entry.index,
                      'rounds',
                    ),
                    controller: entry.roundsCtrl,
                    label: entry.labelOf(_ScoreKey.rounds),
                    hint: _roundsHint,
                    // '완료한 분' 처럼 힌트 문장('10분 중')이 있는 칸만 조금 넓다.
                    width: entry.showsExtra ? _W.rounds : _W.roundsHinted,
                    enabled: enabled,
                  ),
                if (entry.showsRounds && entry.showsExtra && !entry.showsCap)
                  const SizedBox(width: HyphenTokens.sp3),
                if (entry.showsExtra && !entry.showsCap) extraField,
              ],
            ),
          ],
          // 캡 종료 — 켜든 껐든 같은 자리 (밀림 0). 체크 줄(48)은 숫자 칸의 상자와
          // 바닥을 맞춘다 (라벨 줄만큼 숫자 칸이 더 높다).
          if (entry.showsCap) ...[
            const SizedBox(height: HyphenTokens.sp2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                HkCheckRow(
                  key: WodResultSheet.partFieldKey(entry.index, 'cap'),
                  value: entry.capped,
                  label: entry.labelOf(_ScoreKey.capped),
                  onChanged: enabled ? onCapped : (_) {},
                ),
                const SizedBox(width: HyphenTokens.sp3),
                if (entry.showsExtra) extraField,
              ],
            ),
          ],
          // '+ 회' 가 무엇인지 알려 주는 한 줄 — **늘 있고 높이가 고정**이다 (계약 §5).
          if (entry.showsExtraNote) ...[
            const SizedBox(height: HyphenTokens.sp1),
            SizedBox(
              key: WodResultSheet.partFieldKey(entry.index, 'note'),
              height: 18,
              child: const Text(
                kAmrapExtraNote,
                style: HyphenTokens.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 동작 1줄 — 서버가 정한 칸만 한 줄에 (계약 §3). 동작 이름은 `_PartBlock` 이
/// 동작마다 한 번 세우고, 이 줄은 세트면 `1세트 [100] kg × [5] 회`, 아니면
/// `[42.5] kg × [21-15-9] 회` 다 (D125 — 카드 한 장 113dp 가 한 줄 48dp 로).
/// 무게 칸은 `has_load` 인 동작에만 — 토투바·풀업에 무게 칸을 주지 않는다.
/// 적을 칸이 하나도 없는 동작은 **서버가 그린 줄**을 읽기 전용으로 세운다 (계약 §5).
/// 단위 글자: 무게는 계약이 kg 하나(서버 `LOAD_UNIT`), 횟수는 서버 `unit` 이 reps 일 때만
/// '회' — 미터·칼로리 동작에 '회' 를 지어 붙이지 않는다.
class _MovementRow extends StatelessWidget {
  final _MoveEntry entry;
  final bool enabled;
  const _MovementRow({required this.entry, required this.enabled});

  @override
  Widget build(BuildContext context) {
    if (entry.isReadOnly) {
      return Padding(
        padding: const EdgeInsets.only(
          top: HyphenTokens.sp1,
          bottom: HyphenTokens.sp2,
        ),
        child: Text(entry.line, style: HyphenTokens.body),
      );
    }
    final it = entry.item;
    final isSet = entry.setIndex != null;
    // 세트 줄은 **그 세트의 목표**만 힌트로 (전체 처방 '5-5-5-5-5' 를 다섯 줄에 그대로
    // 보여 주면 그 줄이 무엇을 요구하는지 알 수 없다 — 계약 §6).
    final repsHint = entry.repsTarget.isNotEmpty
        ? entry.repsTarget
        : (isSet ? null : '21-15-9');
    return Padding(
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isSet)
            SizedBox(
              width: _W.setLabel,
              child: Text(
                '${entry.setIndex! + 1}세트',
                style: HyphenTokens.caption.copyWith(
                  color: HyphenTokens.fgSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (entry.showLoad)
            HkNumberField(
              fieldKey: entry.loadKey,
              controller: entry.weightCtrl,
              // 코치 무게는 값으로 채워져 있고, 지우면 그 값이 힌트로 남는다.
              // 코치 무게가 없는 동작은 적어도 되고 안 적어도 된다 — '선택'.
              hint: entry.hasCoachLoad ? it.loadValue : '선택',
              unit: 'kg',
              width: _W.load,
              enabled: enabled,
            ),
          if (entry.showLoad && entry.showReps)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: HyphenTokens.sp2),
              child: Text(
                '×',
                style: HyphenTokens.body.copyWith(color: HyphenTokens.muted),
              ),
            ),
          if (entry.showReps)
            HkNumberField(
              fieldKey: entry.repsKey,
              controller: entry.repsCtrl,
              hint: repsHint,
              unit: it.unit == 'reps' ? '회' : null,
              width: isSet ? _W.setReps : _W.freeReps,
              enabled: enabled,
              // 자유 목표는 '21-15-9' 같은 글자라 문자 자판, 세트 한 줄은 숫자 자판.
              numeric: isSet,
            ),
        ],
      ),
    );
  }
}
