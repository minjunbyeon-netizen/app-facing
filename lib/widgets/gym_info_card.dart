// 공지·인박스 화면 상단 — 박스 요약 카드 공유 위젯.
// name·location 은 GymSummary 실데이터, 나머지는 gym.id 기반 더미.
// TODO(go): GymSummary에 phone·coach·times·motto 필드 추가 후 더미 제거.

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/gym.dart';

class GymInfoCard extends StatelessWidget {
  final GymSummary? gym;
  const GymInfoCard({super.key, required this.gym});

  static const _fallback = <String, String>{
    'phone': '전화번호 미등록',
    'coach': '코치 정보 미등록',
    'times': '수업 일정 미등록',
    'motto': '—',
  };

  // gym.id → {phone, coach, times, motto} — personas.json 동기화.
  static const _gymData = <int, Map<String, String>>{
    2: {
      'phone': '02-6677-8800',
      'coach': '박지훈 코치 · CrossFit L2 Trainer, 스포츠과학 석사 / 경력 8년',
      'times': '평일  06:00 · 07:00 · 18:30 · 19:30 · 20:30\n주말  09:00 · 10:00',
      'motto': 'Earn it.',
    },
    3: {
      'phone': '02-3445-9200',
      'coach': '이수민 코치 · CrossFit L2 Trainer, 운동처방학 석사 / 경력 7년',
      'times': '평일  07:00 · 12:00 · 19:00 · 20:00\n주말  10:00 · 11:00',
      'motto': 'Show up and do the work.',
    },
  };

  Map<String, String> _data() {
    if (gym == null) return _fallback;
    return _gymData[gym!.id] ?? _fallback;
  }

  @override
  Widget build(BuildContext context) {
    final name = gym?.name ?? '내 박스';
    final location = gym?.location ?? '위치 미등록';
    final d = _data();
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
                        Text(d['phone']!, style: FacingTokens.caption),
                      ],
                    ),
                    const SizedBox(height: FacingTokens.sp3),
                    const Divider(color: FacingTokens.border, height: 1),
                    const SizedBox(height: FacingTokens.sp3),
                    _InfoRow(label: 'COACH', value: d['coach']!),
                    const SizedBox(height: FacingTokens.sp3),
                    _InfoRow(label: 'CLASS', value: d['times']!),
                    const SizedBox(height: FacingTokens.sp3),
                    Text('MOTTO', style: FacingTokens.sectionLabel),
                    const SizedBox(height: FacingTokens.sp1),
                    Text(d['motto']!, style: FacingTokens.quote),
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
