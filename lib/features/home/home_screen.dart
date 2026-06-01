import 'package:flutter/material.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/inbox_bell.dart';
import '../../widgets/offline_banner.dart';
import '../presets/presets_screen.dart';
import '../wod_builder/wod_builder_screen.dart';

/// v1.23 (2026-06-02) 재배치 Phase 1: 점수(Tier·Engine·Radar·Trend·약점)는 Profile 로 이관.
/// Home 은 잠정적으로 "CALCULATE WOD" 카테고리만 남김.
/// - Phase 2: 이 카테고리 섹션은 WOD 탭 하단 참조 아코디언으로 이동 예정.
/// - Phase 3: Attend 의 게이미피케이션(Level·업적·Milestones)이 Home 으로 들어옴.
/// - Phase 4: Notice 공지/쪽지 아코디언이 Home 최상단에 올라옴.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOME'),
        automaticallyImplyLeading: false,
        actions: const [InboxBellAction()],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                children: [
                  const Text('CALCULATE WOD',
                      style: FacingTokens.sectionLabel),
                  const SizedBox(height: FacingTokens.sp1),
                  const Text(
                    'Pick a category. Split · Burst auto-calc.',
                    style: FacingTokens.caption,
                  ),
                  const SizedBox(height: FacingTokens.sp3),
                  _CategoryRow(
                    title: 'Girls',
                    subtitle: 'Fran · Grace · Helen · Diane',
                    onTap: () => _openPreset(context, 'girl', 'GIRLS WODS'),
                  ),
                  const Divider(height: 1, color: FacingTokens.border),
                  _CategoryRow(
                    title: 'Heroes',
                    subtitle: 'Murph · DT · JT · Michael',
                    onTap: () => _openPreset(context, 'hero', 'HERO WODS'),
                  ),
                  const Divider(height: 1, color: FacingTokens.border),
                  _CategoryRow(
                    title: 'Games',
                    subtitle: 'Amanda .45 · Jackie Pro · 2421 ...',
                    onTap: () => _openPreset(context, 'games', 'GAMES WODS'),
                  ),
                  const Divider(height: 1, color: FacingTokens.border),
                  _CategoryRow(
                    title: 'Custom',
                    subtitle: 'Build movements/reps. For Time only.',
                    onTap: () {
                      Haptic.medium();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const WodBuilderScreen(),
                      ));
                    },
                  ),
                  const Divider(height: 1, color: FacingTokens.border),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPreset(BuildContext context, String filter, String title) {
    Haptic.medium();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PresetsScreen(
        initialFilter: filter,
        lockFilter: true,
        titleOverride: title,
      ),
    ));
  }
}

class _CategoryRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _CategoryRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FacingTokens.h3.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: FacingTokens.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: FacingTokens.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
