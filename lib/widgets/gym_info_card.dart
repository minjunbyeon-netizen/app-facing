// 공지·인박스 화면 상단 — 체육관 요약 카드 공유 위젯.
// v1.22: GymSummary.profile 실데이터 사용. 미등록 필드는 "정보 미등록" 으로 fallback.

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/gym.dart';

class GymInfoCard extends StatelessWidget {
  final GymSummary? gym;
  const GymInfoCard({super.key, required this.gym});

  @override
  Widget build(BuildContext context) {
    final name = gym?.name ?? '내 박스';
    final location = gym?.location ?? '위치 미등록';
    final profile = gym?.profile;
    final phone = profile?.phone ?? '전화번호 미등록';
    final coachLine = _composeCoach(profile);
    final times = profile?.classSchedule ?? '수업 일정 미등록';
    final motto = profile?.motto ?? '—';

    return Container(
      margin: const EdgeInsets.fromLTRB(
          FacingTokens.sp4, FacingTokens.sp4, FacingTokens.sp4, 0),
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
                      style:
                          FacingTokens.h3.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: FacingTokens.sp1),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: FacingTokens.muted),
                        const SizedBox(width: FacingTokens.sp1),
                        Expanded(
                            child: Text(location, style: FacingTokens.caption)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 13, color: FacingTokens.muted),
                        const SizedBox(width: FacingTokens.sp1),
                        Text(phone, style: FacingTokens.caption),
                      ],
                    ),
                    const SizedBox(height: FacingTokens.sp3),
                    const Divider(color: FacingTokens.border, height: 1),
                    const SizedBox(height: FacingTokens.sp3),
                    _InfoRow(label: 'COACH', value: coachLine),
                    const SizedBox(height: FacingTokens.sp3),
                    _InfoRow(label: 'CLASS', value: times),
                    const SizedBox(height: FacingTokens.sp3),
                    Text('MOTTO', style: FacingTokens.sectionLabel),
                    const SizedBox(height: FacingTokens.sp1),
                    Text(motto, style: FacingTokens.quote),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "이름 · 약력" 한 줄. 둘 다 비면 "코치 정보 미등록".
  String _composeCoach(GymProfile? p) {
    if (p == null) return '코치 정보 미등록';
    final name = (p.coachName ?? '').trim();
    final bio = (p.coachBio ?? '').trim();
    if (name.isEmpty && bio.isEmpty) return '코치 정보 미등록';
    if (name.isEmpty) return bio;
    if (bio.isEmpty) return '$name 코치';
    return '$name 코치 · $bio';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

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
