// P3 (2026-08-20 — PLAN-reward-rules.md §6 승인 설계): 도전 카드.
// 코치가 만든 리워드 규칙의 회원 접점 — 규칙 문장 + 진행바 + [인증하기].
// custom(코치 인증) 행동만 [인증하기] 버튼이 뜨고 (1일 1회), 나머지는
// 시스템이 자동으로 세는 진행률 표시다. 문장·진행률·판정 전부 서버.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/mascot.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../../widgets/hkit.dart';
import '../achievement/achievement_state.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';

class ChallengeSection extends StatefulWidget {
  const ChallengeSection({super.key});

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
      _future = context.read<GymRepository>().rewardProgress();
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RewardProgress>>(
      future: _future,
      builder: (ctx, snap) {
        // 규칙 없음·미가입·로드 실패 = 섹션 통째로 숨김 (홈은 조용히).
        final rules = snap.data ?? const <RewardProgress>[];
        if (rules.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: HyphenTokens.sp3),
            const HkSectionLabel('도전'),
            const SizedBox(height: HyphenTokens.sp1),
            Container(
              decoration: BoxDecoration(
                color: HyphenTokens.surface,
                border: Border.all(color: HyphenTokens.border),
                borderRadius: BorderRadius.circular(HyphenTokens.r3),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < rules.length; i++) ...[
                    if (i > 0)
                      const Divider(
                          height: 1, color: HyphenTokens.border),
                    _ChallengeRow(
                      rule: rules[i],
                      onLog: () => _openLogSheet(rules[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
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
          mood: MascotMood.happy);
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
          Text('${widget.rule.label} — 인증하기',
              style: HyphenTokens.sectionLabel),
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
          if (status.isNotEmpty || (rule.canLog && !done)) ...[
            const SizedBox(height: HyphenTokens.sp2),
            Row(
              children: [
                if (status.isNotEmpty)
                  Expanded(
                    child:
                        Text(status, style: HyphenTokens.caption),
                  )
                else
                  const Spacer(),
                if (rule.canLog && !done)
                  HkButton(
                    '인증하기',
                    kind: HkButtonKind.secondary,
                    expand: false,
                    onPressed: onLog,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
