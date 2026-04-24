import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/haptic.dart';
import '../../core/scoring.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../core/unit_state.dart';
import '../../widgets/tier_badge.dart';
import '../achievement/achievement_section.dart';
import '../gym/coach_dashboard_screen.dart';
import '../gym/gym_state.dart';
import '../profile/profile_state.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
          children: const [
            _TierSnapshot(),
            _SectionDivider(),
            _CategoryTiers(),
            _SectionDivider(),
            _MyBoxSection(),
            _SectionDivider(),
            _BodyStats(),
            _SectionDivider(),
            _SettingsSection(),
            _SectionDivider(),
            AchievementSection(),
            _SectionDivider(),
            _ActionsSection(),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: FacingTokens.sp3),
        child: Divider(height: 1, color: FacingTokens.border),
      );
}

class _TierSnapshot extends StatelessWidget {
  const _TierSnapshot();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final g = p.gradeResult;
    final num? n = g?['overall_number'] is num ? g!['overall_number'] as num : null;
    final tier = Tier.fromOverallNumber(n);
    final rawScore = g?['overall_score'];
    final score100 = engineScoreTo100(rawScore);
    final topPct = engineScoreToTopPercent(rawScore);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT TIER', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(n == null ? '-' : '$score100',
                  style: FacingTokens.displayCompact),
              const SizedBox(width: FacingTokens.sp2),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('/ 100', style: FacingTokens.caption),
              ),
              const Spacer(),
              TierBadge(tier: tier, fontSize: 24),
            ],
          ),
          const SizedBox(height: FacingTokens.sp1),
          if (n == null)
            const Text('데이터 없음. 온보딩 완료 후 표시.',
                style: FacingTokens.caption)
          else
            Text(
              formatTopPercent(topPct),
              style: FacingTokens.caption.copyWith(
                color: FacingTokens.fg,
                fontWeight: FontWeight.w700,
                fontFeatures: FacingTokens.tabular,
              ),
            ),
        ],
      ),
    );
  }
}

/// v1.15.3: 카테고리별(5개) Tier + Score(0~100) + Top%(백분위 근사).
/// 각 카테고리는 `gradeResult[key] = {number, score, items_used, missing}`.
class _CategoryTiers extends StatelessWidget {
  const _CategoryTiers();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final g = p.gradeResult;
    if (g == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('CATEGORY TIERS', style: FacingTokens.sectionLabel),
            SizedBox(height: FacingTokens.sp2),
            Text('온보딩 완료 후 표시.', style: FacingTokens.caption),
          ],
        ),
      );
    }
    final specs = <(String, String)>[
      ('POWER', 'power'),
      ('OLYMPIC', 'olympic'),
      ('GYMNASTICS', 'gymnastics'),
      ('CARDIO', 'cardio'),
      ('METCON', 'metcon'),
    ];
    final rows = <Widget>[];
    for (final (title, key) in specs) {
      final data = g[key];
      if (data is! Map) continue;
      final num? scoreNum = data['score'] is num ? data['score'] as num : null;
      final num? catNum = data['number'] is num ? data['number'] as num : null;
      if (scoreNum == null) continue;
      rows.add(_CategoryTierRow(
        title: title,
        tier: Tier.fromOverallNumber(catNum),
        score100: engineScoreTo100(scoreNum),
        topPct: engineScoreToTopPercent(scoreNum),
      ));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CATEGORY TIERS', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp1),
          Text('백분위는 CrossFit 커뮤니티 분포 근사값',
              style: FacingTokens.caption),
          const SizedBox(height: FacingTokens.sp3),
          if (rows.isEmpty)
            const Text('카테고리 데이터 없음', style: FacingTokens.caption)
          else
            ...rows,
        ],
      ),
    );
  }
}

class _CategoryTierRow extends StatelessWidget {
  final String title;
  final Tier tier;
  final int score100;
  final double topPct;
  const _CategoryTierRow({
    required this.title,
    required this.tier,
    required this.score100,
    required this.topPct,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: FacingTokens.sectionLabel),
              ),
              TierBadge(tier: tier),
              const SizedBox(width: FacingTokens.sp3),
              Text(
                formatTopPercent(topPct),
                style: FacingTokens.caption.copyWith(
                  color: FacingTokens.fg,
                  fontWeight: FontWeight.w700,
                  fontFeatures: FacingTokens.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  '$score100',
                  style: FacingTokens.lead.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: FacingTokens.tabular,
                  ),
                ),
              ),
              const SizedBox(width: FacingTokens.sp2),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(FacingTokens.r1),
                  child: Stack(
                    children: [
                      Container(height: 6, color: FacingTokens.border),
                      FractionallySizedBox(
                        widthFactor: (score100 / 100).clamp(0.02, 1.0),
                        child: Container(height: 6, color: tier.color),
                      ),
                    ],
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

/// v1.15.3: 소속 박스 요약. owner면 'Manage Members' 버튼 노출.
class _MyBoxSection extends StatelessWidget {
  const _MyBoxSection();

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MY BOX', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          if (gym == null)
            const Text('박스 미가입. WOD 탭에서 Find Box.',
                style: FacingTokens.caption)
          else ...[
            Text(gym.name,
                style: FacingTokens.body.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: FacingTokens.sp1),
            Text(
              '${gs.isOwner ? 'OWNER' : 'MEMBER'} · ${gs.membership.status ?? '-'} · ${gym.memberCount} members',
              style: FacingTokens.caption,
            ),
            if (gs.isOwner) ...[
              const SizedBox(height: FacingTokens.sp3),
              OutlinedButton(
                onPressed: () {
                  Haptic.light();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CoachDashboardScreen(),
                  ));
                },
                child: const Text('Manage Members'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _BodyStats extends StatelessWidget {
  const _BodyStats();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final unit = context.watch<UnitState>();
    final weightDisplay = p.bodyWeightKg == null
        ? '-'
        : '${_fmt(unit.kgToDisplay(p.bodyWeightKg!)!)} ${unit.weightSuffix}';
    final height = p.heightCm == null ? '-' : '${_fmt(p.heightCm!)} cm';
    final age = p.ageYears == null ? '-' : '${_fmt(p.ageYears!)} yr';
    final sex = p.gender == 'female' ? 'Female' : 'Male';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BODY', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          _Kv(label: 'Weight', value: weightDisplay),
          _Kv(label: 'Height', value: height),
          _Kv(label: 'Age', value: age),
          _Kv(label: 'Sex', value: sex),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _Kv extends StatelessWidget {
  final String label;
  final String value;
  const _Kv({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: FacingTokens.caption)),
          Expanded(
            flex: 5,
            child: Text(value,
                style: FacingTokens.body.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('SETTINGS', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          Row(
            children: [
              const Expanded(child: Text('Unit', style: FacingTokens.body)),
              Consumer<UnitState>(
                builder: (ctx, u, _) => _UnitToggle(u: u),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final UnitState u;
  const _UnitToggle({required this.u});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pill(label: 'kg', selected: u.isKg, onTap: () {
          if (!u.isKg) u.toggle();
        }),
        const SizedBox(width: FacingTokens.sp2),
        _Pill(label: 'lb', selected: !u.isKg, onTap: () {
          if (u.isKg) u.toggle();
        }),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // v1.15 P1-3/P1-4: Semantics + 48dp 터치.
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FacingTokens.r4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FacingTokens.touchMin),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FacingTokens.sp4,
              vertical: FacingTokens.sp2,
            ),
            decoration: BoxDecoration(
              color: selected ? FacingTokens.fg : Colors.transparent,
              borderRadius: BorderRadius.circular(FacingTokens.r4),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: FacingTokens.body.copyWith(
                  color: selected ? FacingTokens.bg : FacingTokens.muted,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/onboarding/basic'),
            child: const Text('Edit Profile'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushNamed('/history'),
            child: const Text('View History'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: FacingTokens.accent,
            ),
            onPressed: () => _confirmReset(context),
            child: const Text('Reset data'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r5),
        ),
        title: const Text('Reset data?'),
        content: const Text(
          '프로필·등급·벤치마크를 전부 삭제합니다.\n'
          '되돌릴 수 없습니다.',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.accent),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (_) => false);
  }
}
