// v1.16.2 (2026-05-25) — 박스 소식 카드.
// 사람들이 가장 궁금해하는 정보 위주: 박스 이름·위치·연락·코치 (이름·전문분야·수상) + 가격 + 수업시간.
// NOTICE 화면 상단에 노출. GymInfoCard 위젯 — GymState.coaches 도 활용.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../features/gym/gym_state.dart';
import '../models/coach_profile.dart';
import '../models/class_template.dart';
import '../models/gym.dart';
import 'hkit.dart';

class GymInfoCard extends StatelessWidget {
  final GymSummary? gym;
  // v1.25: WOD 탭 BOX INFO 아코디언 안에서는 ListView 패딩과 이중이라 margin=0 으로.
  final EdgeInsetsGeometry margin;
  const GymInfoCard({
    super.key,
    required this.gym,
    this.margin = const EdgeInsets.fromLTRB(
        HyphenTokens.sp4, HyphenTokens.sp4, HyphenTokens.sp4, 0),
  });

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final coaches = gs.coaches;
    final templates = gs.classTemplates;

    final name = gym?.name ?? '내 체육관';
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
        color: HyphenTokens.surface,
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
        border: Border.all(color: HyphenTokens.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: const BoxDecoration(
                color: HyphenTokens.accent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(HyphenTokens.r2),
                  bottomLeft: Radius.circular(HyphenTokens.r2),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(HyphenTokens.sp4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: HyphenTokens.h2
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: HyphenTokens.sp2),
                    _IconRow(icon: Icons.location_on_outlined, text: location),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: HyphenTokens.sp1),
                      // 2026-08-28 테스터 요청 9 — 번호를 누르면 전화 앱.
                      _IconRow(
                        icon: Icons.phone_outlined,
                        text: phone,
                        dial: true,
                      ),
                    ],
                    if (kakao.isNotEmpty) ...[
                      const SizedBox(height: HyphenTokens.sp1),
                      _IconRow(icon: Icons.chat_bubble_outline, text: kakao),
                    ],

                    const SizedBox(height: HyphenTokens.sp3),
                    const Divider(color: HyphenTokens.border, height: 1),
                    const SizedBox(height: HyphenTokens.sp3),

                    // 코치 카드 — v1.16.2 신규
                    _CoachesSection(coaches: coaches, fallbackProfile: profile),

                    // 수업 종류 — D79 (2026-08-29 사용자 보고 "이벤트 수업
                    // 만들었는데 회원폰에 노출이 안된다"). 서버는 주고 있었고
                    // 부르는 곳만 없었다. 이벤트는 배지로 가른다.
                    if (templates.isNotEmpty) ...[
                      const SizedBox(height: HyphenTokens.sp3),
                      const Divider(color: HyphenTokens.border, height: 1),
                      const SizedBox(height: HyphenTokens.sp3),
                      _ClassTypesSection(templates: templates),
                    ],

                    if (times.isNotEmpty) ...[
                      const SizedBox(height: HyphenTokens.sp3),
                      _InfoBlock(label: '수업', value: times),
                    ],

                    if (price.isNotEmpty) ...[
                      const SizedBox(height: HyphenTokens.sp3),
                      _InfoBlock(label: '가격', value: price),
                    ],

                    if (motto.isNotEmpty) ...[
                      const SizedBox(height: HyphenTokens.sp3),
                      Text('모토', style: HyphenTokens.sectionLabel),
                      const SizedBox(height: HyphenTokens.sp1),
                      Text(motto, style: HyphenTokens.quote),
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

/// 수업 종류 목록 — 이름 · (이벤트 배지) · 설명. 코치가 PC '수업 안내' 에 적은
/// 순서 그대로. 설명은 코치가 쓴 말이 가장 정확한 안내라 자르지 않는다.
class _ClassTypesSection extends StatelessWidget {
  const _ClassTypesSection({required this.templates});
  final List<ClassTemplate> templates;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('수업 종류 (${templates.length})', style: HyphenTokens.sectionLabel),
        const SizedBox(height: HyphenTokens.sp2),
        for (final (i, t) in templates.indexed) ...[
          if (i > 0) const SizedBox(height: HyphenTokens.sp2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            t.name,
                            style: HyphenTokens.body
                                .copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (t.isEvent) ...[
                          const SizedBox(width: HyphenTokens.sp2),
                          const HkBadge('이벤트', color: HyphenTokens.accent),
                        ],
                      ],
                    ),
                    if (t.description.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          t.description.trim(),
                          style: HyphenTokens.caption.copyWith(height: 1.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
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
        return Text('COACH 정보 미등록', style: HyphenTokens.caption);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('코치', style: HyphenTokens.sectionLabel),
          const SizedBox(height: HyphenTokens.sp1),
          Text(
            name.isNotEmpty ? '$name 코치' : bio,
            style: HyphenTokens.body.copyWith(height: 1.5),
          ),
          if (name.isNotEmpty && bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(bio, style: HyphenTokens.caption),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COACH (${coaches.length})', style: HyphenTokens.sectionLabel),
        const SizedBox(height: HyphenTokens.sp2),
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
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('· ',
              style: HyphenTokens.body.copyWith(color: HyphenTokens.muted)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coach.name,
                    style: HyphenTokens.body
                        .copyWith(fontWeight: FontWeight.w700)),
                if (lines.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(lines.join(' · '),
                        style: HyphenTokens.caption),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 주소·전화 한 줄.
///
/// 2026-08-28 테스터 보고 — "체육관 정보가 너무 작게 뜨는 것 같음". 종전엔 주소·
/// 전화가 caption(13sp·흐림) + 13px 아이콘이었다. 이 둘은 부연이 아니라 회원이
/// **실제로 쓰는 값**이다 (길 찾고 전화 건다). 본문 크기(body)로 올리고 흐림을
/// 걷는다. 잔글씨로 적어 두고 "썼다" 고 하면 안 읽히는 것과 같다.
class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.text, this.dial = false});
  final IconData icon;
  final String text;

  /// 전화번호 줄 — 누르면 전화 앱 (HkPhoneText). 걸 수 없는 값이면 탭도 색도 없다.
  final bool dial;

  @override
  Widget build(BuildContext context) {
    final style = HyphenTokens.body.copyWith(height: 1.5);
    // 전화 줄은 터치 48 을 세로로 잡으므로 아이콘도 그 가운데에 맞춘다.
    // 주소는 여러 줄이 될 수 있어 첫 줄에 붙인다 (start).
    return Row(
      crossAxisAlignment:
          dial ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: dial ? 0 : 2),
          child: Icon(icon, size: 16, color: HyphenTokens.muted),
        ),
        const SizedBox(width: HyphenTokens.sp2),
        Expanded(
          // Expanded 안이라 폭이 꽉 찬다 — 번호 글자만이 아니라 줄 전체가 탭 자리.
          child: dial ? HkPhoneText(text, style: style) : Text(text, style: style),
        ),
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
        Text(label, style: HyphenTokens.sectionLabel),
        const SizedBox(height: HyphenTokens.sp1),
        Text(value, style: HyphenTokens.body.copyWith(height: 1.6)),
      ],
    );
  }
}
