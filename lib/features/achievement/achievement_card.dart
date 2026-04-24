import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/achievement.dart';

/// v1.16 Sprint 9a: Achievement 배지 카드.
/// 잠긴 배지에도 해금 조건 힌트 표시 — hidden 배지만 "· · ·" 유지.
class AchievementCard extends StatelessWidget {
  final AchievementCatalog catalog;
  final AchievementUnlock? unlock; // null이면 미해금

  const AchievementCard({
    super.key,
    required this.catalog,
    this.unlock,
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
    final unlocked = unlock != null;
    final color = unlocked ? _rarityColor() : FacingTokens.border;
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp3),
      padding: const EdgeInsets.fromLTRB(
        FacingTokens.sp4, FacingTokens.sp3, FacingTokens.sp4, FacingTokens.sp3,
      ),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border(
          left: BorderSide(color: color, width: 3),
          top: BorderSide(color: FacingTokens.border, width: 1),
          right: BorderSide(color: FacingTokens.border, width: 1),
          bottom: BorderSide(color: FacingTokens.border, width: 1),
        ),
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      koreanTitle(catalog.code),
                      style: FacingTokens.h3.copyWith(
                        color:
                            unlocked ? FacingTokens.fg : FacingTokens.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      catalog.name,
                      style: FacingTokens.caption.copyWith(
                        color:
                            unlocked ? FacingTokens.muted : FacingTokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                catalog.rarity.toUpperCase(),
                style: FacingTokens.micro.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp1),
          // v1.16 Sprint 9a: 해금 시 description · 미해금 시 trigger hint.
          Text(
            unlocked
                ? catalog.description
                : (catalog.isHidden
                    ? '· · · (조건 공개 안 됨)'
                    : triggerHint(catalog.code)),
            style: FacingTokens.caption,
          ),
          if (unlocked) ...[
            const SizedBox(height: FacingTokens.sp1),
            Text(
              _formatDate(unlock!.unlockedAt),
              style: FacingTokens.micro.copyWith(color: FacingTokens.muted),
            ),
          ],
        ],
      ),
    );
  }

  /// v1.16 Sprint 9a: 배지 해금 조건 한글 힌트.
  /// 백엔드 trigger_value JSON 수동 파싱 대신 정적 매핑 (간단·안전).
  static String triggerHint(String code) {
    switch (code) {
      case 'FIRST_ENGINE':
        return '첫 Engine 측정 1회.';
      case 'REACH_RX':
        return 'Tier RX(3) 이상 도달.';
      case 'REACH_RX_PLUS':
        return 'Tier RX+(4) 이상 도달.';
      case 'REACH_ELITE':
        return 'Tier Elite(5) 이상 도달.';
      case 'REACH_GAMES':
        return 'Tier Games(6) 도달.';
      case 'SCORE_80_OVERALL':
        return 'Overall Engine 80 이상 돌파.';
      case 'SCORE_95_OVERALL':
        return 'Overall Engine 95 이상 — Games급.';
      case 'ALL_CAT_80':
        return '전 카테고리 Engine 80 동시 달성.';
      case 'WOD_50':
        return 'WOD 50회 이상 계산.';
      case 'STREAK_10':
        return '10일 연속 출석.';
      case 'STREAK_30':
        return '30일 연속 출석.';
      case 'GIRLS_5_COMPLETE':
        return 'Girls WOD 5개 이상 완주.';
      case 'GIRLS_ALL':
        return 'Girls WOD 전부 완주.';
      case 'HEROES_3':
        return 'Hero WOD 3개 이상 완주.';
      case 'GAMES_1':
        return 'Games WOD 1개 이상 완주.';
      // v1.16 Sprint 14: 칭호 5개.
      case 'TITLE_POLYMATH':
        return '6 카테고리 Engine 80 동시 돌파.';
      case 'TITLE_OBSESSED':
        return '365일 연속 출석.';
      case 'TITLE_SCHOLAR':
        return 'Overall Engine 80 이상.';
      case 'TITLE_RELENTLESS':
        return '100일 연속 출석.';
      case 'TITLE_UNDEFEATED':
        return '한 주 모든 기록 갱신 (주 7회).';
      default:
        return '미공개 조건.';
    }
  }

  /// v1.16 Sprint 14: 한글 칭호 매핑 (Panel B).
  static String koreanTitle(String code) {
    switch (code) {
      case 'FIRST_ENGINE':
        return '첫 측정';
      case 'REACH_RX':
        return 'RX 기준';
      case 'REACH_RX_PLUS':
        return 'RX+ 선택';
      case 'REACH_ELITE':
        return '엘리트 급';
      case 'REACH_GAMES':
        return '게임스 선수';
      case 'SCORE_80_OVERALL':
        return '분석가';
      case 'SCORE_95_OVERALL':
        return '정점에';
      case 'ALL_CAT_80':
        return '만능 선수';
      case 'WOD_50':
        return '철의 의지';
      case 'STREAK_10':
        return '10일 투지';
      case 'STREAK_30':
        return '성실한';
      case 'GIRLS_5_COMPLETE':
        return 'Girls 5연';
      case 'GIRLS_ALL':
        return 'Girls 완수';
      case 'HEROES_3':
        return 'Hero 헌정';
      case 'GAMES_1':
        return 'Games 도전';
      case 'TITLE_POLYMATH':
        return '만능 선수';
      case 'TITLE_OBSESSED':
        return '집착하는';
      case 'TITLE_SCHOLAR':
        return '분석가';
      case 'TITLE_RELENTLESS':
        return '끝을 모르는';
      case 'TITLE_UNDEFEATED':
        return '불패 일주일';
      default:
        return '칭호';
    }
  }

  static String _formatDate(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
  }
}
