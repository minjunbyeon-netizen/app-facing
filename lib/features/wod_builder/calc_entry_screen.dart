import 'package:flutter/material.dart';

import '../../core/haptic.dart';
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
          padding: const EdgeInsets.all(FacingTokens.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: FacingTokens.sp3),
              const Text('PICK A WOD', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp2),
              const Text(
                'Split · Burst 전략을 계산하려면 WOD 선택.',
                style: FacingTokens.caption,
              ),
              const SizedBox(height: FacingTokens.sp5),
              _ChoiceCard(
                title: 'GIRLS',
                subtitle: 'Fran · Grace · Helen · Diane ...',
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
              const SizedBox(height: FacingTokens.sp3),
              _ChoiceCard(
                title: 'HEROES',
                subtitle: 'Murph · DT · JT · Michael ...',
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
              const SizedBox(height: FacingTokens.sp3),
              _ChoiceCard(
                title: 'CUSTOM',
                subtitle: '동작·횟수·중량 직접 구성. For Time 전용.',
                onTap: () {
                  Haptic.medium();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const WodBuilderScreen(),
                  ));
                },
              ),
              const Spacer(),
              const Text(
                'All types supported on Presets.\nCustom = For Time only.',
                style: FacingTokens.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FacingTokens.sp2),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FacingTokens.r3),
      child: Container(
        padding: const EdgeInsets.all(FacingTokens.sp4),
        decoration: BoxDecoration(
          color: FacingTokens.surface,
          border: Border.all(color: FacingTokens.border),
          borderRadius: BorderRadius.circular(FacingTokens.r3),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: FacingTokens.h2.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: FacingTokens.sp1),
                  Text(subtitle, style: FacingTokens.caption),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward,
                color: FacingTokens.muted, size: 22),
          ],
        ),
      ),
    );
  }
}
