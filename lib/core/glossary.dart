// facing-app 용어 사전 SSOT.
// v1.16 Sprint 7a: 간단 Map → 구조체 + TermTip 위젯.
// VISUAL_CONCEPT.md · CLAUDE.md 용어 팔레트 동기화.

import 'package:flutter/material.dart';

import 'haptic.dart';
import 'theme.dart';

class GlossaryEntry {
  final String term;
  final String nameKo;
  final String description;
  const GlossaryEntry({
    required this.term,
    required this.nameKo,
    required this.description,
  });
}

/// v1.16: 20+ 용어 정의.
const Map<String, GlossaryEntry> kGlossary = {
  '1RM': GlossaryEntry(
    term: '1RM',
    nameKo: '1회 최대 중량',
    description:
        '한 번에 최대로 들 수 있는 무게(One Rep Max). 근력 측정 기준. '
        '정확히 몰라도 추정값 입력 가능.',
  ),
  'AMRAP': GlossaryEntry(
    term: 'AMRAP',
    nameKo: 'As Many Rounds As Possible',
    description:
        '정해진 시간 동안 가능한 많은 라운드 반복. '
        '예: 20분 AMRAP → 20분 안에 최대 라운드.',
  ),
  'EMOM': GlossaryEntry(
    term: 'EMOM',
    nameKo: 'Every Minute On the Minute',
    description:
        '매 분 시작할 때마다 지정 작업 수행. 남은 시간은 휴식. '
        '예: 10분 EMOM Thrusters 10회.',
  ),
  'RFT': GlossaryEntry(
    term: 'RFT',
    nameKo: 'Rounds For Time',
    description: '라운드 × N회 최단 시간 완수.',
  ),
  'For Time': GlossaryEntry(
    term: 'For Time',
    nameKo: '타임 레이스',
    description: '정해진 양을 최대한 빨리 끝내는 WOD 유형. 기록 = 완수 시간.',
  ),
  'Chipper': GlossaryEntry(
    term: 'Chipper',
    nameKo: '치퍼',
    description: '동작 리스트를 위→아래 한 번씩만 통과하는 구성.',
  ),
  'Split': GlossaryEntry(
    term: 'Split',
    nameKo: '분할 전략',
    description:
        '세트 분할 방식. 예: 21회를 15-6으로 나누기. '
        '페이싱·체력 관리 핵심.',
  ),
  'Burst': GlossaryEntry(
    term: 'Burst',
    nameKo: '폭발 구간',
    description:
        '남은 체력을 전부 쏟아내는 구간. '
        'WOD 후반 85% 이후 W-prime 전소 지점.',
  ),
  'Engine': GlossaryEntry(
    term: 'Engine',
    nameKo: '엔진 (종합 체력)',
    description:
        '6 카테고리(POWER/OLYMPIC/GYMNASTICS/CARDIO/METCON) 종합 점수. '
        '1~6 내부 스케일 · 0~100 표시.',
  ),
  'Unbroken': GlossaryEntry(
    term: 'Unbroken',
    nameKo: '무중단 완수',
    description: '한 세트를 내려놓거나 멈추지 않고 연속 완료. Max UB = 한 번에 가능한 최대 반복수.',
  ),
  'UB': GlossaryEntry(
    term: 'UB',
    nameKo: 'Unbroken 약자',
    description: 'Unbroken과 동일. 끊지 않고 연속 완료.',
  ),
  'RX': GlossaryEntry(
    term: 'RX',
    nameKo: '정규 표준',
    description: 'As Prescribed. 정해진 중량·동작 그대로 완수. 스케일 없는 기본 기준.',
  ),
  'RX+': GlossaryEntry(
    term: 'RX+',
    nameKo: '정규+',
    description: 'RX 기준을 상회하는 고난도 버전. 무게·반복수 증가. Elite 직전 단계.',
  ),
  'Scaled': GlossaryEntry(
    term: 'Scaled',
    nameKo: '스케일드',
    description: 'RX 기준이 어려울 때 축소·대체. 진입 기준. 수치·동작 난이도 낮춤.',
  ),
  'Elite': GlossaryEntry(
    term: 'Elite',
    nameKo: '엘리트',
    description: 'Regionals 급 상위권. 전국 상위 5% 수준.',
  ),
  'Games': GlossaryEntry(
    term: 'Games',
    nameKo: '게임즈',
    description: 'CrossFit Games 출전권 보유 수준. 매년 개최되는 세계 대회. 상위 0.1%.',
  ),
  'Metcon': GlossaryEntry(
    term: 'Metcon',
    nameKo: '대사 컨디셔닝',
    description: 'Metabolic Conditioning. 심폐·근지구력 복합 자극. CrossFit WOD 핵심.',
  ),
  'T2B': GlossaryEntry(
    term: 'T2B',
    nameKo: 'Toes To Bar',
    description: '풀업 바에 발끝을 터치하는 코어 동작.',
  ),
  'HSPU': GlossaryEntry(
    term: 'HSPU',
    nameKo: 'Handstand Push-Up',
    description: '물구나무 선 자세에서 푸쉬업. 어깨 근력 측정.',
  ),
  'WOD': GlossaryEntry(
    term: 'WOD',
    nameKo: 'Workout of the Day',
    description: '하루 단위 CrossFit 트레이닝 세션.',
  ),
  'PR': GlossaryEntry(
    term: 'PR',
    nameKo: 'Personal Record',
    description: '개인 최고 기록. 1RM·Fran 타임 등 갱신 시점.',
  ),
  'Benchmark': GlossaryEntry(
    term: 'Benchmark',
    nameKo: '벤치마크',
    description: '성능 평가 기준. Fran·Helen 같은 유명 WOD로 능력치 측정.',
  ),
  'Tier': GlossaryEntry(
    term: 'Tier',
    nameKo: '등급',
    description:
        '종합 Engine 점수에 따른 5단계 분류: '
        'Scaled · RX · RX+ · Elite · Games.',
  ),
};

/// 기존 API 호환: 간단 텍스트 반환 (legacy `glossaryOf(term)` 호출 대응).
String? glossaryOf(String term) {
  final e = lookupTerm(term);
  return e?.description;
}

GlossaryEntry? lookupTerm(String term) {
  final normalized = term.trim();
  if (kGlossary.containsKey(normalized)) return kGlossary[normalized];
  for (final e in kGlossary.entries) {
    if (e.key.toLowerCase() == normalized.toLowerCase()) return e.value;
  }
  return null;
}

/// v1.16: 용어 옆 info 아이콘. 탭 시 bottom sheet.
/// Onboarding · Builder · Grade 등 진입 지점에 배치.
class TermTip extends StatelessWidget {
  final String term;
  final double iconSize;

  const TermTip({super.key, required this.term, this.iconSize = 14});

  @override
  Widget build(BuildContext context) {
    final entry = lookupTerm(term);
    if (entry == null) return const SizedBox.shrink();
    return InkWell(
      onTap: () => _showSheet(context, entry),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          Icons.info_outline,
          size: iconSize,
          color: FacingTokens.muted,
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, GlossaryEntry e) {
    Haptic.light();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FacingTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FacingTokens.r3)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FacingTokens.sp5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(e.term, style: FacingTokens.h2),
                  const SizedBox(width: FacingTokens.sp3),
                  Flexible(
                    child: Text(e.nameKo,
                        style: FacingTokens.caption.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: FacingTokens.sp3),
              Text(e.description, style: FacingTokens.body),
              const SizedBox(height: FacingTokens.sp4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
