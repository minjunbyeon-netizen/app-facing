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

/// 동작 1개의 입력 상태 — 게시물의 WodMovementItem + 회원이 실제 한 값 (D94·v3.45).
///
/// 횟수·무게 칸이 코치가 정한 값으로 미리 채워져 있고 회원은 다르게 했을 때만 고친다.
/// 저장된 값이 있으면 그것으로 채운다. 판정·요약은 서버
/// (`program_lines.normalize_result_movements`·`result_movements_summary`).
class _MoveEntry {
  final WodMovementItem item;
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
    if (m.reps.isNotEmpty) repsCtrl.text = m.reps;
    if (m.loadKg != null) {
      final w = m.loadKg!;
      weightCtrl.text = w == w.roundToDouble() ? '${w.toInt()}' : '$w';
    }
  }

  /// 서버로 보낼 한 줄. 무게는 비었으면 null. (난도는 v3.45 에서 삭제 — 서버 기본 false.)
  Map<String, dynamic> toJson() => {
    'movement_id': item.movementId,
    'name': item.name,
    'reps': repsCtrl.text.trim(),
    'load_kg': double.tryParse(weightCtrl.text.trim()),
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
  bool _saving = false;
  String? _error;

  late final List<_MoveEntry> _moves;

  /// 게시물에 구조화 동작이 있으면 동작별 입력, 없으면 수업 내용 + 저장뿐 (v3.45).
  bool get _structured => _moves.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _moves = [
      for (final r in widget.wod.roundsData)
        for (final m in r.movements) _MoveEntry(m),
    ];
    // 재수정이면 저장된 동작별 값으로 프리필 (같은 동작만) — 빈 시트로 열려
    // 조용히 덮어쓰던 문제의 픽스(2026-08-20)는 그대로 산다.
    final mr = widget.wod.myResult;
    if (mr != null) {
      for (final saved in mr.movements) {
        for (final e in _moves) {
          if (e.matches(saved)) e.prefill(saved);
        }
      }
    }
  }

  @override
  void dispose() {
    for (final m in _moves) {
      m.dispose();
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

    // v3.45 — 보내는 것은 동작별 기록뿐. 점수(time_sec 등)·난도·메모 키는 없다.
    final movements = _structured
        ? [for (final e in _moves) e.toJson()]
        : null;

    try {
      // 1) 결과 제출.
      final res = await repo.submitWodResult(
        gymId: gym.id,
        wodId: widget.wod.id,
        movements: movements,
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
              Text(
                widget.wod.content,
                style: HyphenTokens.caption,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
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

              // ── 내 기록 (v3.45) — 코치 운동 목록이 그대로, 내 값만 고친다 ──
              if (_structured) ...[
                const HkSectionLabel('내 기록'),
                const SizedBox(height: HyphenTokens.sp1),
                const Text(
                  '코치가 정한 값이 채워져 있습니다 — 다르게 했으면 고치세요.',
                  style: HyphenTokens.caption,
                ),
                const SizedBox(height: HyphenTokens.sp1),
                for (final e in _moves)
                  _MovementRow(entry: e, enabled: !_saving),
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

/// 동작 1줄 — 코치가 정한 동작 이름 + [한 횟수][무게 kg] 칸 (D94·v3.45).
/// 두 칸은 코치가 정한 값으로 채워져 있다. 무게 칸은 항상 있다 — 코치 무게가 없어도
/// (strength 5x5·중량 풀업처럼) 내가 든 무게를 적을 자리가 필요하다.
class _MovementRow extends StatelessWidget {
  final _MoveEntry entry;
  final bool enabled;
  const _MovementRow({required this.entry, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final it = entry.item;
    final title = it.name.isEmpty ? it.slug : it.name;
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
              const SizedBox(width: HyphenTokens.sp2),
              Expanded(
                child: TextField(
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
