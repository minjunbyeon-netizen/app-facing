// v1.16.2 (2026-05-25) — 박스 소식 카드.
// 사람들이 가장 궁금해하는 정보 위주: 박스 이름·위치·연락·코치 (이름·전문분야·수상) + 가격 + 수업시간.
// NOTICE 화면 상단에 노출. GymInfoCard 위젯 — GymState.coaches 도 활용.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../features/gym/gym_state.dart';
import '../models/coach_profile.dart';
import '../models/gym.dart';

class GymInfoCard extends StatelessWidget {
  final GymSummary? gym;
  // v1.25: WOD 탭 BOX INFO 아코디언 안에서는 ListView 패딩과 이중이라 margin=0 으로.
  final EdgeInsetsGeometry margin;
  const GymInfoCard({
    super.key,
    required this.gym,
    this.margin = const EdgeInsets.fromLTRB(
        FacingTokens.sp4, FacingTokens.sp4, FacingTokens.sp4, 0),
  });

  @override
  Widget build(BuildContext context) {
    final coaches = context.watch<GymState>().coaches;

    final name = gym?.name ?? '내 박스';
    final location = (gym?.location ?? '').trim().isNotEmpty
        ? gym!.location
        : '위치 미등록';
    final profile = gym?.profile;
    final phone = (profile?.phone ?? '').trim();
    final kakao = (profile?.contactKakao ?? '').trim();
    final price = (profile?.priceSummary ?? '').trim();
    final times = (profile?.classSchedule ?? '').trim();
    final motto = (profile?.motto ?? '').trim();

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
        border: Border.all(color: FacingTokens.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: const BoxDecoration(
                color: FacingTokens.accent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(FacingTokens.r2),
                  bottomLeft: Radius.circular(FacingTokens.r2),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: FacingTokens.h3
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: FacingTokens.sp1),
                    _IconRow(icon: Icons.location_on_outlined, text: location),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      _IconRow(icon: Icons.phone_outlined, text: phone),
                    ],
                    if (kakao.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      _IconRow(icon: Icons.chat_bubble_outline, text: kakao),
                    ],

                    const SizedBox(height: FacingTokens.sp3),
                    const Divider(color: FacingTokens.border, height: 1),
                    const SizedBox(height: FacingTokens.sp3),

                    // 코치 카드 — v1.16.2 신규
                    _CoachesSection(coaches: coaches, fallbackProfile: profile),

                    if (times.isNotEmpty) ...[
                      const SizedBox(height: FacingTokens.sp3),
                      _InfoBlock(label: '수업', value: times),
                    ],

                    if (price.isNotEmpty) ...[
                      const SizedBox(height: FacingTokens.sp3),
                      _InfoBlock(label: '가격', value: price),
                    ],

                    if (motto.isNotEmpty) ...[
                      const SizedBox(height: FacingTokens.sp3),
                      Text('모토', style: FacingTokens.sectionLabel),
                      const SizedBox(height: FacingTokens.sp1),
                      Text(motto, style: FacingTokens.quote),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachesSection extends StatelessWidget {
  const _CoachesSection({required this.coaches, required this.fallbackProfile});
  final List<CoachProfile> coaches;
  final GymProfile? fallbackProfile;

  @override
  Widget build(BuildContext context) {
    if (coaches.isEmpty) {
      // 새 GymCoachProfile 미등록 시 옛 GymProfile.coach_name·coach_bio fallback
      final name = (fallbackProfile?.coachName ?? '').trim();
      final bio = (fallbackProfile?.coachBio ?? '').trim();
      if (name.isEmpty && bio.isEmpty) {
        return Text('COACH 정보 미등록', style: FacingTokens.caption);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('코치', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp1),
          Text(
            name.isNotEmpty ? '$name 코치' : bio,
            style: FacingTokens.body.copyWith(height: 1.5),
          ),
          if (name.isNotEmpty && bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(bio, style: FacingTokens.caption),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COACH (${coaches.length})', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        ...coaches.map((c) => _CoachRow(coach: c)),
      ],
    );
  }
}

class _CoachRow extends StatelessWidget {
  const _CoachRow({required this.coach});
  final CoachProfile coach;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    if ((coach.specialty ?? '').trim().isNotEmpty) {
      lines.add(coach.specialty!.trim());
    }
    if ((coach.certifications ?? '').trim().isNotEmpty) {
      // certifications 본문 다 보여주면 길어서 첫 줄만
      final first = coach.certifications!.split(RegExp(r'[\n,·]')).first.trim();
      if (first.isNotEmpty) lines.add(first);
    }
    if ((coach.competitionRecords ?? '').trim().isNotEmpty) {
      final first =
          coach.competitionRecords!.split(RegExp(r'[\n,·]')).first.trim();
      if (first.isNotEmpty) lines.add(first);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: FacingTokens.sp2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('· ',
              style: FacingTokens.body.copyWith(color: FacingTokens.muted)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coach.name,
                    style: FacingTokens.body
                        .copyWith(fontWeight: FontWeight.w700)),
                if (lines.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(lines.join(' · '),
                        style: FacingTokens.caption),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: FacingTokens.muted),
        const SizedBox(width: FacingTokens.sp1),
        Expanded(child: Text(text, style: FacingTokens.caption)),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp1),
        Text(value, style: FacingTokens.body.copyWith(height: 1.6)),
      ],
    );
  }
}
