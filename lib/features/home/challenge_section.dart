// P3 (2026-08-20 — PLAN-reward-rules.md §6 승인 설계): 도전 카드.
// 코치가 만든 리워드 규칙의 회원 접점 — 규칙 문장 + 진행바 + [인증하기].
// custom(코치 인증) 행동만 [인증하기] 버튼이 뜨고 (1일 1회), 나머지는
// 시스템이 자동으로 세는 진행률 표시다. 문장·진행률·판정 전부 서버.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../../widgets/hkit.dart';
import '../achievement/achievement_state.dart';
import '../gym/gym_repository.dart';

class ChallengeSection extends StatefulWidget {
  const ChallengeSection({super.key});

  @override
  State<ChallengeSection> createState() => _ChallengeSectionState();
}

class _ChallengeSectionState extends State<ChallengeSection> {
  Future<List<RewardProgress>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = context.read<GymRepository>().rewardProgress();
    });
  }

  Future<void> _openLogSheet(RewardProgress r) async {
    Haptic.medium();
    final noteCtrl = TextEditingController();
    final repo = context.read<GymRepository>();
    final achState = context.read<AchievementState>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: HyphenTokens.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(HyphenTokens.r4)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            left: HyphenTokens.sp4,
            right: HyphenTokens.sp4,
            top: HyphenTokens.sp4,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + HyphenTokens.sp4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${r.label} — 인증하기',
                  style: HyphenTokens.sectionLabel),
              const SizedBox(height: HyphenTokens.sp1),
              Text(r.sentence, style: HyphenTokens.caption),
              const SizedBox(height: HyphenTokens.sp3),
              TextField(
                controller: noteCtrl,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  hintText: '예: 한강 5km',
                ),
              ),
              const SizedBox(height: HyphenTokens.sp2),
              HkButton(
                '인증하기',
                onPressed: () async {
                    try {
                      final res = await repo.logRewardAction(
                        r.ruleId,
                        note: noteCtrl.text.trim(),
                      );
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      final granted = res.grantedRules.isNotEmpty;
                      messenger.showSnackBar(SnackBar(
                        content: Text(res.status == 'approved'
                            ? (granted
                                ? '인증 완료 · 조건 충족 — 보상 지급'
                                : '인증 완료')
                            : '인증 접수 — 코치 승인 대기'),
                        duration: const Duration(seconds: 2),
                      ));
                      // 즉시 지급(자동 인정)이면 업적 해금 diff → 토스트·컨페티.
                      if (granted) {
                        achState.check(throttle: false);
                      }
                      _load();
                    } on AppException catch (e) {
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.messageKo)),
                      );
                    } catch (_) {
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      messenger.showSnackBar(const SnackBar(
                          content: Text('인증 실패. 다시 시도.')));
                    }
                },
              ),
              const SizedBox(height: HyphenTokens.sp1),
              const Text(
                '하루에 한 번 인증할 수 있습니다.',
                style: HyphenTokens.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } finally {
      noteCtrl.dispose();
    }
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
