// Notice 영역 재활 가이드 진입 카드.
// 탭하면 RehabScreen(동작·통증부위 브라우즈)로 이동.

import 'package:flutter/material.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import 'rehab_screen.dart';

class RehabGuideCard extends StatelessWidget {
  const RehabGuideCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          FacingTokens.sp4, FacingTokens.sp4, FacingTokens.sp4, FacingTokens.sp2),
      child: Material(
        color: FacingTokens.surfaceHigh,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
        child: InkWell(
          borderRadius: BorderRadius.circular(FacingTokens.r2),
          onTap: () {
            Haptic.light();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RehabScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(FacingTokens.sp4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: FacingTokens.accentSoft,
                    borderRadius: BorderRadius.circular(FacingTokens.r1),
                  ),
                  child: const Icon(Icons.healing_outlined,
                      size: 20, color: FacingTokens.accent),
                ),
                const SizedBox(width: FacingTokens.sp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('재활 가이드',
                          style: FacingTokens.sectionLabel),
                      const SizedBox(height: 2),
                      Text('통증 부위로 원인 감별 → 단계별 재활',
                          style: FacingTokens.caption
                              .copyWith(color: FacingTokens.fgSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 20, color: FacingTokens.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
