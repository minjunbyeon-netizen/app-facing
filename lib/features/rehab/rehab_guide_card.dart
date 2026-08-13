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
          HyphenTokens.sp4, HyphenTokens.sp4, HyphenTokens.sp4, HyphenTokens.sp2),
      child: Material(
        color: HyphenTokens.surfaceHigh,
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
        child: InkWell(
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
          onTap: () {
            Haptic.light();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RehabScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(HyphenTokens.sp4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: HyphenTokens.accentSoft,
                    borderRadius: BorderRadius.circular(HyphenTokens.r1),
                  ),
                  child: const Icon(Icons.healing_outlined,
                      size: 20, color: HyphenTokens.accent),
                ),
                const SizedBox(width: HyphenTokens.sp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('재활 가이드',
                          style: HyphenTokens.sectionLabel),
                      const SizedBox(height: 2),
                      Text('통증 부위로 원인 감별 → 단계별 재활',
                          style: HyphenTokens.caption
                              .copyWith(color: HyphenTokens.fgSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 20, color: HyphenTokens.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
