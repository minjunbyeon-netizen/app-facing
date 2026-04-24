import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/achievement.dart';
import '../achievement/achievement_state.dart';

/// v1.16: TRENDS = Achievement 갤러리 전용.
/// 점수·스파크라인·MOMENTUM은 Profile로 이관됨.
/// 15개 배지 (해금 + 미해금) 카드 리스트. 데모 해금 포함.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  bool _showLocked = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AchievementState>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AchievementState>();
    final snap = state.snapshot;

    // 해금·미해금 분리. 데모 해금 포함.
    final unlocked = <AchievementCatalog>[];
    final locked = <AchievementCatalog>[];
    for (final c in snap.catalog) {
      if (state.isUnlockedInUi(c.code)) {
        unlocked.add(c);
      } else {
        locked.add(c);
      }
    }
    unlocked.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    locked.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      appBar: AppBar(
        title: const Text('TRENDS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AchievementState>().load(),
          ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading && snap.catalog.isEmpty
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: FacingTokens.muted),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                children: [
                  // Summary header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${unlocked.length}',
                          style: FacingTokens.displayCompact),
                      const SizedBox(width: FacingTokens.sp2),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '/ ${snap.catalog.length + _hiddenLockedCount(snap, state)} badges',
                          style: FacingTokens.caption,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FacingTokens.sp1),
                  const Text('ACHIEVEMENTS UNLOCKED',
                      style: FacingTokens.sectionLabel),
                  const SizedBox(height: FacingTokens.sp5),

                  // Unlocked
                  if (unlocked.isEmpty) ...[
                    const Text('해금된 배지 없음. Engine 측정부터 시작.',
                        style: FacingTokens.caption),
                  ] else ...[
                    const Text('UNLOCKED', style: FacingTokens.sectionLabel),
                    const SizedBox(height: FacingTokens.sp2),
                    ...unlocked.map((c) => _BadgeCard(
                          catalog: c,
                          unlocked: true,
                          isDemo: AchievementState.demoUnlockedCodes
                              .contains(c.code),
                        )),
                  ],
                  const SizedBox(height: FacingTokens.sp5),

                  // Locked toggle + list
                  if (locked.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'LOCKED (${locked.length})',
                            style: FacingTokens.sectionLabel,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: FacingTokens.muted,
                          ),
                          onPressed: () =>
                              setState(() => _showLocked = !_showLocked),
                          child: Text(_showLocked ? 'Hide' : 'Show'),
                        ),
                      ],
                    ),
                    if (_showLocked) ...[
                      const SizedBox(height: FacingTokens.sp2),
                      ...locked.map((c) => _BadgeCard(
                            catalog: c,
                            unlocked: false,
                          )),
                    ],
                  ],
                ],
              ),
      ),
    );
  }

  /// hidden 배지는 해금 전 catalog에서 제외되어 visible 카운트에 포함 안됨.
  /// 총합 카운트 보정 위해 대략 추가. 정확한 총 15개 고정값 노출해도 OK.
  int _hiddenLockedCount(AchievementSnapshot snap, AchievementState state) {
    // 총합 고정 15로 표기.
    final visibleTotal = snap.catalog.length;
    return (15 - visibleTotal).clamp(0, 15);
  }
}

class _BadgeCard extends StatelessWidget {
  final AchievementCatalog catalog;
  final bool unlocked;
  final bool isDemo;

  const _BadgeCard({
    required this.catalog,
    required this.unlocked,
    this.isDemo = false,
  });

  Color _rarityColor() {
    switch (catalog.rarity) {
      case 'Rare':
        return FacingTokens.accent;
      case 'Epic':
        return FacingTokens.tierElite;
      case 'Legendary':
        return FacingTokens.tierGames;
      case 'Common':
      default:
        return FacingTokens.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? _rarityColor() : FacingTokens.border;
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp3),
      padding: const EdgeInsets.fromLTRB(
          FacingTokens.sp4, FacingTokens.sp3, FacingTokens.sp4, FacingTokens.sp3),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color, width: unlocked ? 3 : 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  catalog.name,
                  style: FacingTokens.h3.copyWith(
                    color: unlocked ? FacingTokens.fg : FacingTokens.muted,
                  ),
                ),
              ),
              Text(
                catalog.rarity.toUpperCase(),
                style: FacingTokens.micro.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp1),
          Text(
            unlocked ? catalog.description : '· · ·',
            style: FacingTokens.caption,
          ),
          if (isDemo) ...[
            const SizedBox(height: FacingTokens.sp1),
            Text(
              'demo sample',
              style: FacingTokens.micro.copyWith(
                color: FacingTokens.muted,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
