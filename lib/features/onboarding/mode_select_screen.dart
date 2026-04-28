import 'package:flutter/material.dart';

import '../../core/app_mode.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';

/// Tier 부여 후 진입. 3 모드 (Coach / Member / Solo) 중 선택.
/// 선택 시 SharedPreferences 저장 + 다음 분기 진입.
/// Settings 에서 재진입 시 (arguments == 'settings') 뒤로가기 허용 + pop.
class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  bool _isFromSettings(BuildContext context) =>
      ModalRoute.of(context)?.settings.arguments == 'settings';

  Future<void> _select(BuildContext context, AppMode mode) async {
    Haptic.medium();
    final fromSettings = _isFromSettings(context);
    await AppModeStore.set(mode);
    if (!context.mounted) return;
    if (fromSettings) {
      Navigator.of(context).pop();
      return;
    }
    final next = switch (mode) {
      AppMode.coach => '/onboarding/create-gym',
      AppMode.member => '/onboarding/find-gym',
      AppMode.solo => '/shell',
    };
    Navigator.of(context).pushNamedAndRemoveUntil(next, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final fromSettings = _isFromSettings(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOUR ROLE'),
        automaticallyImplyLeading: fromSettings,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FacingTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: FacingTokens.sp2),
              const Text('역할 선택', style: FacingTokens.h2),
              const SizedBox(height: FacingTokens.sp2),
              const Text(
                '코치는 박스를 운영합니다. 멤버는 박스에 가입합니다. Solo 는 혼자 트레이닝.',
                style: FacingTokens.caption,
              ),
              const SizedBox(height: FacingTokens.sp5),
              _ModeCard(
                label: 'COACH',
                title: '박스 운영',
                lines: const [
                  'Box 등록 + WOD 게시',
                  '멤버 관리 + 인박스',
                  'Coach Dashboard',
                ],
                onTap: () => _select(context, AppMode.coach),
              ),
              const SizedBox(height: FacingTokens.sp4),
              _ModeCard(
                label: 'MEMBER',
                title: '박스 멤버',
                lines: const [
                  'Box 검색 + 가입 신청',
                  '코치 WOD 받기',
                  'Coach 노트 + 숙제',
                ],
                onTap: () => _select(context, AppMode.member),
              ),
              const SizedBox(height: FacingTokens.sp4),
              _ModeCard(
                label: 'SOLO',
                title: '혼자 트레이닝',
                lines: const [
                  'Engine 측정 + 페이싱 계산',
                  '업적 / 시즌 배지',
                  '박스 기능 잠금',
                ],
                onTap: () => _select(context, AppMode.solo),
              ),
              const SizedBox(height: FacingTokens.sp5),
              const Text(
                '언제든 Settings 에서 변경.',
                style: FacingTokens.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final String title;
  final List<String> lines;
  final VoidCallback onTap;
  const _ModeCard({
    required this.label,
    required this.title,
    required this.lines,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(FacingTokens.sp4),
        decoration: BoxDecoration(
          color: FacingTokens.surface,
          border: Border.all(color: FacingTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp1),
            Text(title, style: FacingTokens.h3),
            const SizedBox(height: FacingTokens.sp2),
            ...lines.map((l) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('· $l', style: FacingTokens.caption),
                )),
          ],
        ),
      ),
    );
  }
}
