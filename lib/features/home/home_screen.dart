import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../core/unit_state.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/tier_badge.dart';
import '../profile/profile_state.dart';
import '../wod_builder/wod_draft_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FACING'),
        actions: [
          Consumer<UnitState>(
            builder: (ctx, u, _) => TextButton(
              onPressed: u.toggle,
              child: Text(
                u.isKg ? 'kg' : 'lb',
                style: FacingTokens.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: FacingTokens.fg,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.timeline),
            onPressed: () => Navigator.of(context).pushNamed('/history'),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).pushNamed('/mypage'),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FacingTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: FacingTokens.sp5),
              Consumer<ProfileState>(
                builder: (ctx, p, _) {
                  final g = p.gradeResult;
                  if (g == null) return const SizedBox.shrink();
                  final num? n = g['overall_number'] is num
                      ? g['overall_number'] as num
                      : null;
                  final tier = Tier.fromOverallNumber(n);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: FacingTokens.sp3),
                    child: Row(children: [TierBadge(tier: tier)]),
                  );
                },
              ),
              const Text("Today's WOD.\nPull your Split.", style: FacingTokens.h1),
              const SizedBox(height: FacingTokens.sp2),
              const Text(
                'RX부터 Games까지. Split과 Burst 자동 계산.',
                style: FacingTokens.caption,
              ),
              const Spacer(),
              Consumer<ProfileState>(
                builder: (ctx, profile, _) {
                  final missing = profile.isEmpty;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (missing) ...[
                        const Text(
                          '1RM 없음. 먼저 입력.',
                          style: FacingTokens.caption,
                        ),
                        const SizedBox(height: FacingTokens.sp3),
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/profile'),
                          child: const Text('Enter 1RM'),
                        ),
                        const SizedBox(height: FacingTokens.sp3),
                      ],
                      ElevatedButton(
                        onPressed: () {
                          context.read<WodDraftState>().clear();
                          Navigator.of(context).pushNamed('/presets');
                        },
                        child: const Text('Benchmark WOD'),
                      ),
                      const SizedBox(height: FacingTokens.sp1),
                      const Text(
                        'Fran · Grace · Murph · Helen…',
                        style: FacingTokens.micro,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: FacingTokens.sp3),
                      OutlinedButton(
                        onPressed: () {
                          context.read<WodDraftState>().clear();
                          Navigator.of(context).pushNamed('/builder');
                        },
                        child: const Text('Custom WOD Builder'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: FacingTokens.sp4),
            ],
          ),
        ),
      )),
        ],
      ),
    );
  }
}
