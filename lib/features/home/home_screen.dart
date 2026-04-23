import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../profile/profile_state.dart';
import '../wod_builder/wod_draft_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('facing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FacingTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: FacingTokens.sp5),
              Consumer<ProfileState>(
                builder: (ctx, p, _) {
                  final label = p.overallGradeLabelKo;
                  if (label == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: FacingTokens.sp3),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: FacingTokens.sp3,
                            vertical: FacingTokens.sp1,
                          ),
                          decoration: BoxDecoration(
                            color: FacingTokens.accent,
                            borderRadius: BorderRadius.circular(FacingTokens.r4),
                          ),
                          child: Text(
                            label,
                            style: FacingTokens.body.copyWith(
                              color: FacingTokens.bg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Text('오늘의 WOD\n전략이 필요합니까', style: FacingTokens.h1),
              const SizedBox(height: FacingTokens.sp2),
              const Text(
                '등급에 맞춰 분할·폭발 시점을 자동 조정합니다.',
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
                          'Max 능력치가 비어 있습니다. 먼저 프로필을 채우세요.',
                          style: FacingTokens.caption,
                        ),
                        const SizedBox(height: FacingTokens.sp3),
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/profile'),
                          child: const Text('프로필 입력'),
                        ),
                        const SizedBox(height: FacingTokens.sp3),
                      ],
                      ElevatedButton(
                        onPressed: () {
                          context.read<WodDraftState>().clear();
                          Navigator.of(context).pushNamed('/presets');
                        },
                        child: const Text('유명 WOD (Fran, Grace...)'),
                      ),
                      const SizedBox(height: FacingTokens.sp3),
                      OutlinedButton(
                        onPressed: () {
                          context.read<WodDraftState>().clear();
                          Navigator.of(context).pushNamed('/builder');
                        },
                        child: const Text('직접 WOD 만들기'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: FacingTokens.sp4),
            ],
          ),
        ),
      ),
    );
  }
}
