import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../core/unit_state.dart';
import '../../widgets/tier_badge.dart';
import '../profile/profile_state.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
          children: const [
            _TierSnapshot(),
            _SectionDivider(),
            _BodyStats(),
            _SectionDivider(),
            _SettingsSection(),
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
    final score = g?['overall_score']?.toString() ?? '-';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT TIER', style: FacingTokens.micro),
          const SizedBox(height: FacingTokens.sp2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TierBadge(tier: tier, fontSize: 18),
              const SizedBox(width: FacingTokens.sp3),
              Text(
                n == null ? '-' : '${n.toInt()}/6',
                style: FacingTokens.h2.copyWith(color: FacingTokens.muted),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp2),
          Text('Score $score', style: FacingTokens.caption),
          if (n == null) ...[
            const SizedBox(height: FacingTokens.sp2),
            const Text('데이터 없음. 온보딩 완료 후 표시.',
                style: FacingTokens.caption),
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
          const Text('BODY', style: FacingTokens.micro),
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
          const Text('SETTINGS', style: FacingTokens.micro),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FacingTokens.r4),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FacingTokens.sp4,
          vertical: FacingTokens.sp2,
        ),
        decoration: BoxDecoration(
          color: selected ? FacingTokens.fg : Colors.transparent,
          borderRadius: BorderRadius.circular(FacingTokens.r4),
        ),
        child: Text(label,
            style: FacingTokens.body.copyWith(
              color: selected ? FacingTokens.bg : FacingTokens.muted,
              fontWeight: FontWeight.w700,
            )),
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
        backgroundColor: FacingTokens.surface,
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
