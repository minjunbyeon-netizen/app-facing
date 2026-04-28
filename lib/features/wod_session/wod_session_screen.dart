// v1.16 Sprint 10: WOD 세션 실행·기록 화면.
// Persona P0 Top-4 대응:
//  1. WOD 카드 Start/Complete 버튼 (시간·라운드 입력 → 기록 저장)
//  2. 내장 타이머 (For Time count-up · AMRAP count-down · EMOM interval)
//  3. 완료 시 WodSessionBus.bump() → Attendance 탭 캘린더 자동 체크
//  4. Share placeholder (Phase 2) · Calc 페이싱 안내

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/season_badges.dart';
import '../../core/theme.dart';
import '../../core/pr_detector.dart';
import '../../core/wod_session_bus.dart';
import '../../models/gym.dart';
import '../achievement/achievement_state.dart';
import '../achievement/unlock_toast.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';
import '../history/history_repository.dart';

enum _TimerMode { forTime, amrap, emom }

class WodSessionScreen extends StatefulWidget {
  final GymWodPost wod;
  const WodSessionScreen({super.key, required this.wod});

  @override
  State<WodSessionScreen> createState() => _WodSessionScreenState();
}

class _WodSessionScreenState extends State<WodSessionScreen> {
  late final _TimerMode _mode;
  late final int _capSec; // AMRAP·EMOM 지속시간. For Time은 optional.
  Timer? _tick;
  int _elapsedSec = 0;
  bool _running = false;
  bool _completed = false;
  bool _saving = false;
  bool _scaled = false; // v1.16 Sprint 11: Scaled 기록 여부.

  @override
  void initState() {
    super.initState();
    _mode = _modeFrom(widget.wod.wodType);
    _capSec = _resolveCap(widget.wod, _mode);
  }

  @override
  void dispose() {
    _tick?.cancel();
    // v1.16 Sprint 11: 세션 종료 시 wakelock 해제.
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  static _TimerMode _modeFrom(String type) {
    switch (type.toLowerCase()) {
      case 'amrap':
        return _TimerMode.amrap;
      case 'emom':
        return _TimerMode.emom;
      default:
        return _TimerMode.forTime;
    }
  }

  /// AMRAP/EMOM 지속시간. time_cap_sec 우선, 없으면 content에서 "AMRAP 12" · "EMOM 10" 숫자 추출.
  static int _resolveCap(GymWodPost wod, _TimerMode mode) {
    if (wod.timeCapSec != null && wod.timeCapSec! > 0) return wod.timeCapSec!;
    final m = RegExp(r'(AMRAP|EMOM)\s+(\d+)', caseSensitive: false)
        .firstMatch(wod.content);
    if (m != null) {
      final mins = int.tryParse(m.group(2) ?? '') ?? 0;
      if (mins > 0) return mins * 60;
    }
    // 기본값: AMRAP/EMOM 10분, For Time 무한.
    if (mode == _TimerMode.forTime) return 0;
    return 600;
  }

  void _start() {
    if (_running || _completed) return;
    Haptic.medium();
    // v1.16 Sprint 11: 타이머 실행 중 화면 꺼짐 방지.
    WakelockPlus.enable().catchError((_) {});
    setState(() => _running = true);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // QA B-COR-4: setState 안에서 _autoStop() 호출 시 setState 중첩.
      // tick 처리는 setState로, 종료 트리거는 별도 호출.
      setState(() {
        _elapsedSec++;
        if (_mode == _TimerMode.emom && _elapsedSec % 60 == 0) {
          Haptic.light();
        }
      });
      if (_capSec > 0 && _elapsedSec >= _capSec) {
        _autoStop();
      }
    });
  }

  void _pause() {
    if (!_running) return;
    Haptic.light();
    _tick?.cancel();
    WakelockPlus.disable().catchError((_) {});
    setState(() => _running = false);
  }

  void _reset() {
    Haptic.light();
    _tick?.cancel();
    WakelockPlus.disable().catchError((_) {});
    setState(() {
      _running = false;
      _elapsedSec = 0;
      _completed = false;
    });
  }

  void _autoStop() {
    _tick?.cancel();
    WakelockPlus.disable().catchError((_) {});
    Haptic.heavy();
    setState(() {
      _running = false;
      _completed = true;
    });
  }

  Future<void> _complete() async {
    Haptic.heavy();
    _tick?.cancel();
    setState(() {
      _running = false;
      _completed = true;
    });
    await _openRecordSheet();
  }

  int get _displaySec {
    if (_mode == _TimerMode.amrap && _capSec > 0) {
      return (_capSec - _elapsedSec).clamp(0, _capSec);
    }
    return _elapsedSec;
  }

  String _formatMMSS(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  Future<void> _openRecordSheet() async {
    final timeCtrl = TextEditingController(text: _formatMMSS(_elapsedSec));
    final roundsCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    // QA B-COR-2: 모달 닫힌 후 controller dispose 보장.
    try {
      await showModalBottomSheet<void>(
      context: context,
      backgroundColor: FacingTokens.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FacingTokens.r4)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (innerCtx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(
            left: FacingTokens.sp4,
            right: FacingTokens.sp4,
            top: FacingTokens.sp4,
            bottom:
                MediaQuery.of(sheetCtx).viewInsets.bottom + FacingTokens.sp4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('SAVE RECORD', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp1),
              Text(widget.wod.wodType.toUpperCase(),
                  style: FacingTokens.h3.copyWith(
                    color: FacingTokens.accent,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: FacingTokens.sp4),
              if (_mode == _TimerMode.forTime) ...[
                const Text('완료 시간 (MM:SS)', style: FacingTokens.caption),
                const SizedBox(height: FacingTokens.sp1),
                TextField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(hintText: '7:43'),
                  keyboardType: TextInputType.datetime,
                ),
              ] else if (_mode == _TimerMode.amrap) ...[
                const Text('완료한 라운드', style: FacingTokens.caption),
                const SizedBox(height: FacingTokens.sp1),
                TextField(
                  controller: roundsCtrl,
                  decoration: const InputDecoration(hintText: '5'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: FacingTokens.sp3),
                const Text('추가 반복 (optional)', style: FacingTokens.caption),
                const SizedBox(height: FacingTokens.sp1),
                TextField(
                  controller: repsCtrl,
                  decoration: const InputDecoration(hintText: '12'),
                  keyboardType: TextInputType.number,
                ),
              ] else ...[
                Text('${_capSec ~/ 60}분 EMOM 완료.',
                    style: FacingTokens.body),
              ],
              const SizedBox(height: FacingTokens.sp3),
              // v1.16 Sprint 11: Scaled 토글 (P2 Q8/Q18).
              Row(
                children: [
                  const Expanded(
                    child: Text('Scaled 기록',
                        style: FacingTokens.body),
                  ),
                  Switch(
                    value: _scaled,
                    activeTrackColor: FacingTokens.accent,
                    onChanged: (v) {
                      setSheet(() {});
                      setState(() => _scaled = v);
                    },
                  ),
                ],
              ),
              Text(
                _scaled
                    ? 'Scaled — Tier 반영 시 감산 가중치 적용.'
                    : 'RX — 등급 기본 반영.',
                style: FacingTokens.caption,
              ),
              const SizedBox(height: FacingTokens.sp4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(sheetCtx).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: FacingTokens.sp3),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              final ok = await _saveRecord(
                                timeStr: timeCtrl.text.trim(),
                                rounds: int.tryParse(roundsCtrl.text.trim()),
                                extraReps: int.tryParse(repsCtrl.text.trim()),
                              );
                              if (!sheetCtx.mounted) return;
                              if (ok) Navigator.of(sheetCtx).pop();
                            },
                      child: Text(_saving ? 'Saving…' : 'Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FacingTokens.sp2),
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('공유 카드 생성은 Phase 2에서 제공.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Share (Phase 2)'),
                ),
              ),
            ],
          ),
        );
        });
      },
    );
    } finally {
      timeCtrl.dispose();
      roundsCtrl.dispose();
      repsCtrl.dispose();
    }
  }

  int _parseTimeToSec(String s) {
    final m = RegExp(r'^(\d+):(\d{1,2})$').firstMatch(s);
    if (m != null) {
      final mm = int.parse(m.group(1)!);
      final ss = int.parse(m.group(2)!);
      return mm * 60 + ss;
    }
    final n = int.tryParse(s);
    return n ?? _elapsedSec;
  }

  Future<bool> _saveRecord({
    required String timeStr,
    int? rounds,
    int? extraReps,
  }) async {
    // QA B-COR-3: 시작 시점 mounted 확인. 모달 콜백 호출 타이밍에 dispose 가능.
    if (!mounted) return false;
    final api = context.read<ApiClient>();
    setState(() => _saving = true);
    try {
      final repo = HistoryRepository(api);
      final totalSec = _mode == _TimerMode.forTime
          ? _parseTimeToSec(timeStr)
          : _elapsedSec;

      // /go Phase 2.5+: PR 감지 — 저장 전에 prior history 캐시.
      // 판정은 PrDetector.isPrAgainst (forTime 모드 한정).
      bool isPr = false;
      if (_mode == _TimerMode.forTime && totalSec > 0) {
        try {
          final prior = await repo.listWodHistory(limit: 200);
          isPr = PrDetector.isPrAgainst(
            priorHistory: prior,
            wodType: widget.wod.wodType,
            newTotalSec: totalSec,
          );
        } catch (_) {
          // 네트워크 실패 시 PR 감지 skip — 저장 흐름은 계속.
        }
      }

      final notes = StringBuffer();
      notes.writeln(_scaled
          ? '[SCALED] FACING WOD — ${widget.wod.postDate}'
          : '[RX] FACING WOD — ${widget.wod.postDate}');
      if (rounds != null) notes.writeln('Rounds: $rounds');
      if (extraReps != null) notes.writeln('Extra reps: $extraReps');
      notes.writeln('---');
      notes.writeln(widget.wod.content);

      await repo.saveWodHistory({
        'wod': {
          'wod_type': widget.wod.wodType,
          'time_cap_sec': widget.wod.timeCapSec,
          'rounds': rounds ?? widget.wod.rounds,
          'notes': notes.toString().substring(
                0,
                notes.length > 500 ? 500 : notes.length,
              ),
          'items': const [],
        },
        'plan': {
          'formula_version': 'manual_session_v1',
          'estimated_total_sec': totalSec,
          'grade': '',
          'segments': const [],
        },
      });

      // v1.16 Sprint 16: 박스 WOD인 경우 참가자 기록 리더보드 POST (best-effort).
      // QA A-18: await 후 context.read 전 mounted 검사.
      if (!mounted) return true;
      try {
        final gs = context.read<GymState>();
        final gym = gs.membership.gym;
        final gymRepo = context.read<GymRepository>();
        if (gym != null &&
            (gs.isOwner || gs.membership.isApprovedMember)) {
          await gymRepo.submitWodResult(
                gymId: gym.id,
                wodId: widget.wod.id,
                timeSec: _mode == _TimerMode.forTime ? totalSec : null,
                rounds: rounds,
                extraReps: extraReps,
                scaleLevel: _scaled ? 'scaled' : 'rx',
                notes: '',
              );
        }
      } catch (_) {
        // 리더보드 실패는 history 저장 성공을 막지 않음.
      }

      if (!mounted) return true;
      context.read<WodSessionBus>().bump();

      // /go Phase 2.5+ (toast 가독성): unlock 발화 추적 → 마지막 '기록 저장.' toast 중복 회피.
      // SnackBar duration 도 3s → 2s 로 통일 (ScaffoldMessenger 자동 큐 누적 시간 단축).
      var anyUnlockShown = false;

      // PR unlock 모먼트 (forTime + 신규 best).
      if (isPr && mounted) {
        final m = totalSec ~/ 60;
        final s = totalSec % 60;
        Haptic.achievementUnlock(emphasize: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PR · ${widget.wod.wodType.toUpperCase()} '
              '$m:${s.toString().padLeft(2, '0')}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        anyUnlockShown = true;
      }

      // v1.20 Phase 2.5: 시즌 배지 자동 unlock (active 시즌일 때만).
      try {
        final newBadge = await SeasonBadgeService.recordSessionToday();
        if (newBadge != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Season badge unlocked · ${newBadge.label}'),
              duration: const Duration(seconds: 2),
            ),
          );
          Haptic.achievementUnlock();
          anyUnlockShown = true;
        }
      } catch (_) {
        // 배지 실패는 사용자에게 노출 안 함.
      }

      // /go Phase 2.5+: AchievementState.check() 호출 — 백엔드 trigger 신규 unlock 즉시 노출.
      // throttle=true 로 10분 간격 제한 (백엔드 부하 + 중복 toast 방지).
      if (mounted) {
        try {
          final achState = context.read<AchievementState>();
          final newly = await achState.check(throttle: true);
          if (newly.isNotEmpty && mounted) {
            // ignore: use_build_context_synchronously — UnlockToast 내부 mounted 가드.
            UnlockToast.showAll(context, newly);
            anyUnlockShown = true;
          }
        } catch (_) {
          // achievement 실패는 사용자에게 노출 안 함.
        }
      }

      if (!mounted) return true;
      // unlock 발화 시 '기록 저장.' toast 생략 — 사용자에 이미 완료 신호 전달됨.
      if (!anyUnlockShown) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기록 저장. 출석 · 박스 리더보드 자동 반영.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      Navigator.of(context).pop(); // 세션 스크린 종료
      return true;
    } on AppException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: ${e.messageKo}')),
      );
      return false;
    } catch (e) {
      // /go 전수조사: 원본 exception toString 노출 차단 — 일반 메시지 + debugPrint.
      debugPrint('[WodSession._saveRecord] $e');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 실패. 다시 시도.')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmExitIfRunning() async {
    if (!_running && _elapsedSec == 0) return true;
    if (_completed) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        title: const Text('세션 진행 중'),
        content: const Text(
          '타이머 기록을 저장하지 않고 종료하면 소실됩니다.\n계속 종료하시겠습니까?',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('계속'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('종료'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final ok = await _confirmExitIfRunning();
        if (ok && mounted) {
          _tick?.cancel();
          WakelockPlus.disable().catchError((_) {});
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.wod.wodType.toUpperCase()),
        ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          child: Column(
            children: [
              // WOD 내용
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(FacingTokens.sp4),
                decoration: BoxDecoration(
                  color: FacingTokens.surface,
                  borderRadius: BorderRadius.circular(FacingTokens.r3),
                  border: Border.all(color: FacingTokens.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_modeLabel(_mode),
                        style: FacingTokens.sectionLabel.copyWith(
                          color: FacingTokens.accent,
                        )),
                    const SizedBox(height: FacingTokens.sp2),
                    Text(widget.wod.content, style: FacingTokens.body),
                    if (widget.wod.roundsData.isNotEmpty) ...[
                      const SizedBox(height: FacingTokens.sp2),
                      ...widget.wod.roundsData.asMap().entries.map((e) {
                        final i = e.key;
                        final r = e.value;
                        return Padding(
                          padding:
                              const EdgeInsets.only(top: FacingTokens.sp1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.label.isEmpty
                                    ? 'ROUND ${i + 1}'
                                    : r.label.toUpperCase(),
                                style: FacingTokens.micro.copyWith(
                                  color: FacingTokens.accent,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(r.content,
                                  style: FacingTokens.caption),
                              if (r.timeCapSec != null)
                                Text(
                                  'cap ${r.timeCapSec! ~/ 60}:${(r.timeCapSec! % 60).toString().padLeft(2, '0')}',
                                  style: FacingTokens.micro.copyWith(
                                      color: FacingTokens.muted),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                    if (widget.wod.scaleGuide != null &&
                        widget.wod.scaleGuide!.isNotEmpty) ...[
                      const SizedBox(height: FacingTokens.sp3),
                      Text('SCALE',
                          style: FacingTokens.micro.copyWith(
                            color: FacingTokens.muted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          )),
                      const SizedBox(height: 2),
                      Text(widget.wod.scaleGuide!,
                          style: FacingTokens.caption),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              // 타이머 표시
              Text(
                _formatMMSS(_displaySec),
                style: FacingTokens.display.copyWith(
                  fontFeatures: FacingTokens.tabular,
                ),
              ),
              const SizedBox(height: FacingTokens.sp1),
              Text(_subLabel(),
                  style: FacingTokens.caption.copyWith(
                    color: FacingTokens.muted,
                  )),
              const Spacer(),
              // 컨트롤 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: FacingTokens.sp3),
                  Expanded(
                    flex: 2,
                    child: _running
                        ? ElevatedButton(
                            onPressed: _pause,
                            child: const Text('Pause'),
                          )
                        : ElevatedButton(
                            // QA B-PF-5: _start/_resume 동일 함수였음. 단일 호출로 정리.
                            // 라벨만 시작/재개로 분기.
                            onPressed: _start,
                            child:
                                Text(_elapsedSec == 0 ? 'Start' : 'Resume'),
                          ),
                  ),
                  const SizedBox(width: FacingTokens.sp3),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FacingTokens.accent,
                        foregroundColor: FacingTokens.fg,
                      ),
                      onPressed: _elapsedSec == 0 ? null : _complete,
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FacingTokens.sp2),
              Text(
                _mode == _TimerMode.amrap
                    ? 'AMRAP · 카운트다운 종료 시 자동 기록 전환'
                    : _mode == _TimerMode.emom
                        ? 'EMOM · 매 분 Haptic 알림'
                        : 'For Time · 스톱워치 · Done 누르면 기록 저장',
                style: FacingTokens.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  String _modeLabel(_TimerMode m) {
    switch (m) {
      case _TimerMode.forTime:
        return 'FOR TIME';
      case _TimerMode.amrap:
        return 'AMRAP · ${_capSec ~/ 60} MIN';
      case _TimerMode.emom:
        return 'EMOM · ${_capSec ~/ 60} MIN';
    }
  }

  String _subLabel() {
    if (_mode == _TimerMode.amrap) {
      return _running ? 'Remaining' : 'Countdown';
    }
    return _running ? 'Running' : (_elapsedSec == 0 ? 'Ready' : 'Paused');
  }
}
