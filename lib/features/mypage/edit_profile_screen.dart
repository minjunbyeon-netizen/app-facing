import 'package:flutter/material.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';

/// v1.22: Edit Profile 영역 chooser.
/// 사용자 요구: 측정값 편집 진입 — Basic / Benchmarks 두 영역.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EDIT PROFILE')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          children: const [
            Text('AREAS', style: FacingTokens.sectionLabel),
            SizedBox(height: FacingTokens.sp1),
            Text(
              '편집할 영역 선택. 입력값은 저장 시 즉시 반영.',
              style: FacingTokens.caption,
            ),
            SizedBox(height: FacingTokens.sp4),
            _AreaCard(
              title: 'Basic',
              subtitle: '체중 · 키 · 나이 · 성별 · CrossFit 경력',
              route: '/onboarding/basic',
            ),
            _AreaCard(
              title: 'Benchmarks',
              subtitle:
                  'Power · Olympic · Gymnastics · Cardio · Metcon · Body',
              route: '/onboarding/benchmarks',
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String route;
  const _AreaCard({
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp3),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border.all(color: FacingTokens.border),
        borderRadius: BorderRadius.circular(FacingTokens.r3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Haptic.light();
            Navigator.of(context).pushNamed(route);
          },
          borderRadius: BorderRadius.circular(FacingTokens.r3),
          child: Padding(
            padding: const EdgeInsets.all(FacingTokens.sp4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: FacingTokens.h3),
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
        ),
      ),
    );
  }
}
