// v1.16.2 (2026-05-24) — 코치 더보기 페이지 (read-only).
// ARCHITECTURE_BRIEF §11.6.
// BoxProfileScreen "COACHES" 카드 → 코치 행 탭 → 이 화면 진입.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/coach_profile.dart';

class CoachDetailScreen extends StatelessWidget {
  const CoachDetailScreen({super.key, required this.coach});
  final CoachProfile coach;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      appBar: AppBar(
        backgroundColor: FacingTokens.bg,
        title: const Text('Coach'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _PhotoHeader(coach: coach),
          if (coach.career != null)
            _Card(title: 'CAREER', body: coach.career!),
          if (coach.certifications != null)
            _Card(title: 'CERTIFICATIONS', body: coach.certifications!),
          if (coach.specialty != null)
            _Card(title: 'SPECIALTY', body: coach.specialty!),
          if (coach.competitionRecords != null)
            _Card(title: 'COMPETITION', body: coach.competitionRecords!),
          if (coach.demoVideoUrl != null)
            _LinkCard(title: 'DEMO VIDEO', url: coach.demoVideoUrl!),
          if (coach.ptBookable) _PtBookCard(coach: coach),
          if (coach.offDays.isNotEmpty)
            _Card(title: 'OFF-DAYS', body: coach.offDays.join(' · ')),
          if (coach.snsUrl != null)
            _LinkCard(title: 'SNS', url: coach.snsUrl!),
        ],
      ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.coach});
  final CoachProfile coach;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FacingTokens.surface,
              border: Border.all(color: FacingTokens.border),
              image: coach.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(coach.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: coach.photoUrl == null
                ? Icon(Icons.person, size: 48, color: FacingTokens.muted)
                : null,
          ),
          const SizedBox(height: 12),
          Text(coach.name,
              style: FacingTokens.h2.copyWith(color: FacingTokens.fg)),
          if (coach.specialty != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(coach.specialty!,
                  style: FacingTokens.caption),
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
        color: FacingTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FacingTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: FacingTokens.sectionLabel),
          const SizedBox(height: 8),
          Text(body,
              style: FacingTokens.body.copyWith(color: FacingTokens.fg)),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.title, required this.url});
  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FacingTokens.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: FacingTokens.sectionLabel),
                const SizedBox(height: 8),
                Text(url,
                    style: FacingTokens.body
                        .copyWith(color: FacingTokens.fg)),
              ],
            ),
          ),
          Icon(Icons.open_in_new, size: 18, color: FacingTokens.muted),
        ],
      ),
    );
  }
}

class _PtBookCard extends StatelessWidget {
  const _PtBookCard({required this.coach});
  final CoachProfile coach;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FacingTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PT (1:1)', style: FacingTokens.sectionLabel),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FacingTokens.primary,
                foregroundColor: FacingTokens.fg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                // TODO(v1.16.2): PT 예약 흐름 연결 (별도 작업)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PT booking — coming soon.')),
                );
              },
              child: const Text('Book PT'),
            ),
          ),
        ],
      ),
    );
  }
}
