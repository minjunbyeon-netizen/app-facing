// v1.16.2 (2026-05-24) — 코치 더보기 페이지 (read-only).
// ARCHITECTURE_BRIEF §11.6.
// BoxProfileScreen "COACHES" 카드 → 코치 행 탭 → 이 화면 진입.

import 'package:flutter/material.dart';
import '../../widgets/hkit.dart';
import '../../widgets/mascot.dart';

import '../../core/theme.dart';
import '../../models/coach_profile.dart';

class CoachDetailScreen extends StatelessWidget {
  const CoachDetailScreen({super.key, required this.coach});
  final CoachProfile coach;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      appBar: const HkAppBar(title: '코치'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _PhotoHeader(coach: coach),
          if (coach.career != null) _Card(title: '경력', body: coach.career!),
          if (coach.certifications != null)
            _Card(title: '자격증', body: coach.certifications!),
          if (coach.specialty != null)
            _Card(title: '전문 분야', body: coach.specialty!),
          if (coach.competitionRecords != null)
            _Card(title: '대회 기록', body: coach.competitionRecords!),
          if (coach.demoVideoUrl != null)
            _LinkCard(title: '시범 영상', url: coach.demoVideoUrl!),
          // v2.6 (2026-08-13 사용자 지시): 'PT 예약' 카드 제외 — 버튼을 눌러도
          // "준비 중" 스낵바만 뜨는 죽은 버튼이었다. 예약 흐름이 실제로 붙는
          // 커밋에서 이 한 줄을 되살린다 (_PtBookCard 는 보존).
          if (coach.offDays.isNotEmpty)
            _Card(title: '휴무', body: coach.offDays.join(' · ')),
          if (coach.snsUrl != null) _LinkCard(title: 'SNS', url: coach.snsUrl!),
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
              color: HyphenTokens.surface,
              border: Border.all(color: HyphenTokens.border),
              image: coach.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(coach.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: coach.photoUrl == null
                ? Icon(Icons.person, size: 48, color: HyphenTokens.muted)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            coach.name,
            style: HyphenTokens.h2.copyWith(color: HyphenTokens.fg),
          ),
          if (coach.specialty != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(coach.specialty!, style: HyphenTokens.caption),
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
    return HkCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      radius: HyphenTokens.r2,
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

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.title, required this.url});
  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return HkCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      radius: HyphenTokens.r2,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HkSectionLabel(title),
                const SizedBox(height: 8),
                Text(
                  url,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                ),
              ],
            ),
          ),
          Icon(Icons.open_in_new, size: 18, color: HyphenTokens.muted),
        ],
      ),
    );
  }
}

// ignore: unused_element  — 진입점만 끊었다 ("숨김 = 코드 보존", 위 build 주석 참조).
class _PtBookCard extends StatelessWidget {
  const _PtBookCard({required this.coach});
  final CoachProfile coach;

  @override
  Widget build(BuildContext context) {
    return HkCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      radius: HyphenTokens.r2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HkSectionLabel('PT (1:1)'),
          const SizedBox(height: 12),
          HkButton.primary(
            'PT 예약',
            onPressed: () {
              // TODO(v1.16.2): PT 예약 흐름 연결 (별도 작업)
              HkSnack.show(context, 'PT 예약 — 준비 중.', mood: MascotMood.neutral);
            },
          ),
        ],
      ),
    );
  }
}
