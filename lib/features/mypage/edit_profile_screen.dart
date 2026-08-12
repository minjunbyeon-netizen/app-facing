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
      appBar: AppBar(title: const Text('프로필 수정')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          children: const [
            Text('수정 영역', style: FacingTokens.sectionLabel),
            SizedBox(height: FacingTokens.sp1),
            Text(
              '편집할 영역 선택. 입력값은 저장 시 즉시 반영.',
              style: FacingTokens.caption,
            ),
            SizedBox(height: FacingTokens.sp4),
            // v2.6 (2026-08-13): 부제가 실제 화면과 달랐다 — 기본 정보는
            // v2.3 에서 성별·경력 둘만 남았는데 체중·키·나이를 약속하고 있었다.
            _AreaCard(
              title: '기본 정보',
              subtitle: '성별 · CrossFit 경력 (레벨 기준)',
              route: '/onboarding/basic',
            ),
            // v2.6 (2026-08-13 사용자 지시 "지금 없는 건 다 지워"): Benchmarks
            // 카드 삭제. ENGINE 을 프로필에서 내린 뒤(D34) 측정 입구만 남아
            // 있었다 — 넣어도 결과를 볼 곳이 없다. 화면·라우트
            // (`/onboarding/benchmarks`)는 보존 ("숨김 = 코드 보존").
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
