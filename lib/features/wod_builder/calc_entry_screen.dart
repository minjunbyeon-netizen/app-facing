import 'package:flutter/material.dart';

import '../../core/haptic.dart';
import '../../core/season.dart';
import '../../core/theme.dart';
import '../presets/presets_screen.dart';
import 'wod_builder_screen.dart';

/// v1.16: Calc 탭 진입 스크린. 3버튼 (Girls · Hero · Custom).
class CalcEntryScreen extends StatelessWidget {
  const CalcEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CALC'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // v1.16 Sprint 8 U4: 시즌 모드 배너 (offseason 아닐 때만).
              Builder(builder: (ctx) {
                final s = currentSeason();
                if (!s.isActive) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(top: FacingTokens.sp3),
                  padding: const EdgeInsets.fromLTRB(
                    FacingTokens.sp3,
                    FacingTokens.sp2,
                    FacingTokens.sp3,
                    FacingTokens.sp2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: FacingTokens.accent, width: 1),
                    borderRadius: BorderRadius.circular(FacingTokens.r2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(s.label,
                              style: FacingTokens.micro.copyWith(
                                color: FacingTokens.accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              )),
                          const Spacer(),
                          Text(
                            '* 가상 일정',
                            style: FacingTokens.micro.copyWith(
                              color: FacingTokens.muted,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(s.description, style: FacingTokens.caption),
                    ],
                  ),
                );
              }),
              const SizedBox(height: FacingTokens.sp4),
              const Text('PICK A WOD', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp1),
              const Text(
                'Split · Burst 전략을 계산할 WOD 선택.',
                style: FacingTokens.caption,
              ),
              const SizedBox(height: FacingTokens.sp4),
              const Divider(height: 1, color: FacingTokens.border),
              _ChoiceRow(
                title: 'Girls',
                subtitle: 'Fran · Grace · Helen · Diane',
                onTap: () {
                  Haptic.medium();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PresetsScreen(
                      initialFilter: 'girl',
                      lockFilter: true,
                      titleOverride: 'GIRLS WODS',
                    ),
                  ));
                },
              ),
              const Divider(height: 1, color: FacingTokens.border),
              _ChoiceRow(
                title: 'Heroes',
                subtitle: 'Murph · DT · JT · Michael',
                onTap: () {
                  Haptic.medium();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PresetsScreen(
                      initialFilter: 'hero',
                      lockFilter: true,
                      titleOverride: 'HERO WODS',
                    ),
                  ));
                },
              ),
              const Divider(height: 1, color: FacingTokens.border),
              _ChoiceRow(
                title: 'Games',
                subtitle: 'Amanda .45 · Jackie Pro · 2421 ...',
                onTap: () {
                  Haptic.medium();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PresetsScreen(
                      initialFilter: 'games',
                      lockFilter: true,
                      titleOverride: 'GAMES WODS',
                    ),
                  ));
                },
              ),
              const Divider(height: 1, color: FacingTokens.border),
              _ChoiceRow(
                title: 'Custom',
                subtitle: '동작·횟수 직접 구성. For Time 전용.',
                onTap: () {
                  Haptic.medium();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const WodBuilderScreen(),
                  ));
                },
              ),
              const Divider(height: 1, color: FacingTokens.border),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: FacingTokens.sp2),
                child: Text(
                  'Custom = For Time only.',
                  style: FacingTokens.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ChoiceRow({
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
