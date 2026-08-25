// v1.16.2 (2026-05-24) — 박스 프로필 페이지 (회원·신규 방문자 read-only view).
// ARCHITECTURE_BRIEF §11.6.
// 사장이 GymProfile 9 필드 + 코치 프로필 입력하면 회원·신규 방문자가 이 화면에서 본다.
// 와이어프레임: docs/PERSONA_BACKLOG.md 와 docs/GYM_PROFILE_SCHEMA.md §4 매핑 참조.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/coach_profile.dart';
import '../../models/gym.dart';
import 'gym_state.dart';
import 'coach_detail_screen.dart';
import '../../widgets/hkit.dart';

class BoxProfileScreen extends StatelessWidget {
  const BoxProfileScreen({super.key, this.overrideCoaches});

  /// 코치 리스트 override (테스트·미리보기 전용). null 이면 GymState.coaches 사용.
  final List<CoachProfile>? overrideCoaches;

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    final profile = gym?.profile;
    final coaches = overrideCoaches ?? gs.coaches;

    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      appBar: const HkAppBar(title: '체육관'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Header(gym: gym),
          if (profile?.priceSummary != null)
            _Card(title: '가격', body: profile!.priceSummary!),
          if ((profile?.paymentMethods != null) ||
              (profile?.receiptInfo != null))
            _Card(
              title: '결제',
              body: [
                if (profile?.paymentMethods != null) profile!.paymentMethods!,
                if (profile?.receiptInfo != null) profile!.receiptInfo!,
              ].join('\n'),
            ),
          if ((profile?.firstVisitGuide != null) ||
              (profile?.attireGuide != null) ||
              (profile?.wifiInfo != null))
            _Card(
              title: '첫 방문',
              body: [
                if (profile?.firstVisitGuide != null) profile!.firstVisitGuide!,
                if (profile?.attireGuide != null) profile!.attireGuide!,
                if (profile?.wifiInfo != null) 'WiFi: ${profile!.wifiInfo!}',
              ].join('\n'),
            ),
          _CoachesCard(coaches: coaches, gymProfile: profile),
          if (profile?.freeNotice != null)
            _Card(title: '공지', body: profile!.freeNotice!),
          // QA (2026-06-11): V4 이모지 금지 — 📞💬🚗 프리픽스 → Material outline 아이콘 Row.
          if ((profile?.phone != null) ||
              (profile?.contactKakao != null) ||
              (profile?.parkingInfo != null))
            _ContactCard(
              rows: [
                if (profile?.phone != null)
                  (Icons.call_outlined, profile!.phone!),
                if (profile?.contactKakao != null)
                  (Icons.chat_bubble_outline, profile!.contactKakao!),
                if (profile?.parkingInfo != null)
                  (Icons.local_parking_outlined, profile!.parkingInfo!),
              ],
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.gym});
  final GymSummary? gym;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gym?.name ?? 'BOX',
            style: HyphenTokens.h1.copyWith(color: HyphenTokens.fg),
          ),
          const SizedBox(height: 4),
          Text(
            gym?.location ?? '',
            style: HyphenTokens.body.copyWith(color: HyphenTokens.muted),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HyphenTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HyphenTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HkSectionLabel(title),
          const SizedBox(height: 8),
          Text(body, style: HyphenTokens.body.copyWith(color: HyphenTokens.fg)),
        ],
      ),
    );
  }
}

/// QA (2026-06-11): CONTACT 카드 전용 — 아이콘 + 텍스트 행 목록 (V4 이모지 대체).
class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.rows});
  final List<(IconData, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HyphenTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HyphenTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HkSectionLabel('연락처'),
          const SizedBox(height: 8),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(r.$1, size: 16, color: HyphenTokens.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachesCard extends StatelessWidget {
  const _CoachesCard({required this.coaches, required this.gymProfile});
  final List<CoachProfile> coaches;
  final GymProfile? gymProfile;

  @override
  Widget build(BuildContext context) {
    final hasCoaches = coaches.isNotEmpty;
    final fallbackCoach = gymProfile?.coachName;
    if (!hasCoaches && (fallbackCoach == null || fallbackCoach.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HyphenTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HyphenTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HkSectionLabel('코치 (${hasCoaches ? coaches.length : 1})'),
          const SizedBox(height: 8),
          if (hasCoaches)
            ...coaches.map((c) => _CoachRow(coach: c))
          else
            Text(
              fallbackCoach!,
              style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
            ),
        ],
      ),
    );
  }
}

class _CoachRow extends StatelessWidget {
  const _CoachRow({required this.coach});
  final CoachProfile coach;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CoachDetailScreen(coach: coach)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach.name,
                    style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  ),
                  if (coach.specialty != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        coach.specialty!,
                        style: HyphenTokens.caption,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: HyphenTokens.muted),
          ],
        ),
      ),
    );
  }
}
