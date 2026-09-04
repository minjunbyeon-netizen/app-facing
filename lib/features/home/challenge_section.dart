// P3 (2026-08-20 — PLAN-reward-rules.md §6 승인 설계): 도전 카드.
// 코치가 만든 리워드 규칙의 회원 접점 — 규칙 문장 + 진행바 + [인증하기].
// custom(코치 인증) 행동만 [인증하기] 버튼이 뜨고 (1일 1회), 나머지는
// 시스템이 자동으로 세는 진행률 표시다. 문장·진행률·판정 전부 서버.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/mascot.dart';

import '../../core/exception.dart';
import '../../core/futures.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../../widgets/hkit.dart';
import '../achievement/achievement_state.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';

class ChallengeSection extends StatefulWidget {
  const ChallengeSection({super.key});

  /// 레이아웃 안정성 앵커 — 상태가 바뀌어도 이 둘의 y 는 같아야 한다
  /// (`test/golden/stability_home_challenge_test.dart`).
  static const Key kLabel = Key('home-challenge-label');
  static const Key kBody = Key('home-challenge-body');

  @override
  State<ChallengeSection> createState() => _ChallengeSectionState();
}

class _ChallengeSectionState extends State<ChallengeSection> {
  Future<List<RewardProgress>>? _future;
  GymState? _gymState;

  @override
  void initState() {
    super.initState();
    _load();
    // 결함 수정 6 (2026-08-20): PC 규칙 변경 SSE(reward_rule.changed)가
    // GymState reload → notify 로 흐르므로, 그 notify 를 듣고 재조회.
    _gymState = context.read<GymState>();
    _gymState?.addListener(_load);
  }

  @override
  void dispose() {
    _gymState?.removeListener(_load);
    super.dispose();
  }

  void _load() {
    if (!mounted) return;
    setState(() {
      // 홈 ListView 의 마지막 자식이라 스크롤 밖이면 통째로 버려진다 — 그때
      // 남은 요청이 실패하면 unhandled 로 샌다 (CLAUDE.md §골든 캡처).
      _future = retainError(context.read<GymRepository>().rewardProgress());
    });
  }

  Future<void> _openLogSheet(RewardProgress r) async {
    Haptic.medium();
    final repo = context.read<GymRepository>();
    final achState = context.read<AchievementState>();
    final messenger = HkSnack.of(context);
    // 컨트롤러는 _LogSheet(State) 가 소유 — 종전엔 시트 pop 직후 finally 로
    // dispose 해, 퇴장 애니메이션 중인 TextField 가 죽은 컨트롤러를 물고
    // 프레임워크 단정('_dependents.isEmpty')으로 크래시했다 (2026-08-24 실기).
    await HkSheet.show<void>(
      context,
      builder: (ctx) => _LogSheet(
        rule: r,
        repo: repo,
        achState: achState,
        messenger: messenger,
        onLogged: _load,
      ),
    );
  }

  /// D118 (2026-09-05 · DESIGN-SSOT §레이아웃 안정성): 종전엔 규칙이 없거나·아직
  /// 안 왔거나·못 읽었으면 **섹션을 통째로 숨겼다**. 실측하면 로딩 0 · 0건 0 ·
  /// 실패 0 · 도전 2건 289px — 규칙이 도착하는 순간 섹션이 생겨나고 홈 스크롤
  /// 총길이가 145 → 434 로 3배가 됐다. "홈 마지막이라 위는 안 밀린다" 는 안전의
  /// 근거가 못 된다: 스크롤 위치·막대 길이가 튀고, 홈 아래에 무엇이 붙는 순간
  /// 그대로 밀림이 된다. 실패를 숨긴 것은 **거짓말**이기도 했다 — 못 읽은 것과
  /// 없는 것이 화면에서 똑같이 보였다.
  ///
  /// 이제 라벨과 카드는 **항상** 서 있고 카드 안만 갈아 끼운다. 로딩·0건·실패
  /// 셋은 같은 바닥([HyphenTokens.stateSlotH] = 132) 을 쓴다 — 그 값은 도전 한
  /// 행의 실측 높이(128.5)와 거의 같아, 규칙 1건짜리 체육관에서는 도착해도
  /// 사실상 안 밀린다. 빈 카드를 세우는 선택은 홈이 이미 공지에서 하고 있는
  /// 것과 같다 ('등록된 공지 없음' 이 늘 서 있다).
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RewardProgress>>(
      future: _future,
      builder: (ctx, snap) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: HyphenTokens.sp3),
          const HkSectionLabel('도전', key: ChallengeSection.kLabel),
          const SizedBox(height: HyphenTokens.sp1),
          HkCard(
            key: ChallengeSection.kBody,
            padding: EdgeInsets.zero,
            child: _body(snap),
          ),
        ],
      ),
    );
  }

  Widget _body(AsyncSnapshot<List<RewardProgress>> snap) {
    if (snap.connectionState != ConnectionState.done) {
      return const HkLoading.slot();
    }
    if (snap.hasError) {
      return HkErrorState.fromError(snap.error, onRetry: _load);
    }
    final rules = snap.data ?? const <RewardProgress>[];
    if (rules.isEmpty) {
      return const HkEmptyState(title: '등록된 도전 없음');
    }
    return Column(
      children: [
        for (var i = 0; i < rules.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: HyphenTokens.border),
          _ChallengeRow(rule: rules[i], onLog: () => _openLogSheet(rules[i])),
        ],
      ],
    );
  }
}

/// 인증 바텀시트 — 메모 컨트롤러 수명은 이 State 가 소유 (route 언마운트 후
/// dispose 되므로 퇴장 애니메이션과 안 겹친다).
class _LogSheet extends StatefulWidget {
  final RewardProgress rule;
  final GymRepository repo;
  final AchievementState achState;
  final HkSnack messenger;
  final VoidCallback onLogged;
  const _LogSheet({
    required this.rule,
    required this.repo,
    required this.achState,
    required this.messenger,
    required this.onLogged,
  });

  @override
  State<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<_LogSheet> {
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    // 키보드가 열린 채 pop 하지 않는다 — 닫힘 레이스 방지.
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final res = await widget.repo.logRewardAction(
        widget.rule.ruleId,
        note: _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      final granted = res.grantedRules.isNotEmpty;
      widget.messenger.info(
        res.status == 'approved'
            ? (granted ? '인증 완료 · 조건 충족 — 보상 지급' : '인증 완료')
            : '인증 접수 — 코치 승인 대기',
        mood: MascotMood.happy,
      );
      // 즉시 지급(자동 인정)이면 업적 해금 diff → 토스트·컨페티.
      if (granted) {
        widget.achState.check(throttle: false);
      }
      widget.onLogged();
    } on AppException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.messenger.fail(e.messageKo);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.messenger.fail('인증 실패. 다시 시도.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: HyphenTokens.sp4,
        right: HyphenTokens.sp4,
        top: HyphenTokens.sp4,
        bottom: MediaQuery.of(context).viewInsets.bottom + HyphenTokens.sp4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HkSectionLabel('${widget.rule.label} — 인증하기'),
          const SizedBox(height: HyphenTokens.sp1),
          Text(widget.rule.sentence, style: HyphenTokens.caption),
          const SizedBox(height: HyphenTokens.sp3),
          TextField(
            controller: _noteCtrl,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: '메모 (선택)',
              hintText: '예: 한강 5km',
            ),
          ),
          const SizedBox(height: HyphenTokens.sp2),
          HkButton('인증하기', onPressed: _submitting ? null : _submit),
          const SizedBox(height: HyphenTokens.sp1),
          const Text(
            '하루에 한 번 인증할 수 있습니다.',
            style: HyphenTokens.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 규칙 1행 — 문장 · 진행바 · 상태(달성/대기) · [인증하기](custom 만).
class _ChallengeRow extends StatelessWidget {
  final RewardProgress rule;
  final VoidCallback onLog;
  const _ChallengeRow({required this.rule, required this.onLog});

  @override
  Widget build(BuildContext context) {
    final done = rule.doneThisWindow;
    final ratio = rule.target > 0
        ? (rule.progress / rule.target).clamp(0.0, 1.0)
        : 0.0;
    final status = <String>[
      if (done) '이번 주기 달성',
      if (rule.pending > 0) '승인 대기 ${rule.pending}건',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.all(HyphenTokens.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  rule.sentence,
                  style: HyphenTokens.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: HyphenTokens.sp2),
              Text(
                done ? '✓' : '${rule.progress} / ${rule.target}',
                style: HyphenTokens.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: done ? HyphenTokens.success : HyphenTokens.fg,
                ),
              ),
            ],
          ),
          const SizedBox(height: HyphenTokens.sp2),
          ClipRRect(
            borderRadius: BorderRadius.circular(HyphenTokens.r1),
            child: LinearProgressIndicator(
              value: done ? 1.0 : ratio,
              minHeight: 6,
              backgroundColor: HyphenTokens.bg,
              color: done ? HyphenTokens.success : HyphenTokens.accent,
            ),
          ),
          // v3.34 (2026-08-27 · DESIGN-SSOT §레이아웃 안정성): 인증 전후로 상태줄과
          // [인증하기] 가 통째로 생겼다 사라져, 같은 카드 안 다음 규칙 행이
          // 버튼 높이만큼 뛰었다. 줄은 **항상** 두고 안의 내용만 갈아 끼운다.
          // 높이는 버튼 높이로 잡는다 — 가장 높은 경우가 기준이다.
          const SizedBox(height: HyphenTokens.sp2),
          SizedBox(
            height: HyphenTokens.buttonHCompact,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    status,
                    style: HyphenTokens.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (rule.canLog && !done) ...[
                  const SizedBox(width: HyphenTokens.sp2),
                  HkButton(
                    '인증하기',
                    kind: HkButtonKind.secondary,
                    expand: false,
                    onPressed: onLog,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
