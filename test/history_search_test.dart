import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen_app/features/history/history_models.dart';
import 'package:hyphen_app/features/history/history_search.dart';

/// D84 — 히스토리 검색 연관도순. 순위 규칙 정본 = history_search.dart.
WodHistoryItem _item(
  int id,
  String notes, {
  String type = 'custom',
  int daysAgo = 0,
  int? sec,
  String? grade,
}) => WodHistoryItem(
  id: id,
  wodType: type,
  notes: notes,
  createdAt: DateTime(2026, 8, 29, 10).subtract(Duration(days: daysAgo)),
  estimatedTotalSec: sec,
  grade: grade,
);

void main() {
  final items = [
    _item(1, '수업 #41 · BUILD Back Squat 5×5', daysAgo: 1, grade: 'rx'),
    _item(
      2,
      '수업 #40 · SWEAT Fran 21-15-9 Thruster · Pull-up',
      type: 'for_time',
      daysAgo: 3,
      sec: 412,
      grade: 'scaled',
    ),
    _item(
      3,
      '수업 #38 · AWAKE 12min AMRAP Burpee · Row 250m',
      type: 'amrap',
      daysAgo: 6,
      sec: 720,
      grade: 'rx',
    ),
    _item(4, '수업 #35 · BUILD Front Squat 3×5', daysAgo: 8, grade: 'elite'),
    _item(
      5,
      '수업 #30 · SWEAT Helen 3 rounds Run 400m · KB Swing · Pull-up',
      type: 'for_time',
      daysAgo: 14,
      sec: 655,
      grade: 'rx',
    ),
  ];

  List<int> ids(String q) => rankHistory(q, items).map((e) => e.id).toList();

  test('빈 검색어 — 걸러내지 않고 최근순', () {
    expect(ids(''), [1, 2, 3, 4, 5]);
    expect(ids('   '), [1, 2, 3, 4, 5]);
  });

  test('낱말 하나 — 맞는 것만, 같은 점수면 최근 것이 먼저', () {
    expect(ids('squat'), [1, 4]);
    expect(ids('pull-up'), [2, 5]);
  });

  test('낱말 여러 개는 AND — 전부 맞아야 남는다', () {
    expect(ids('squat front'), [4]);
    expect(ids('squat helen'), isEmpty);
  });

  test('요약(첫 줄)이 종류보다, 종류가 본문보다 위', () {
    // 'build' 는 1·4 의 요약에, 'for time' 은 2·5 의 종류에 맞는다.
    expect(ids('build'), [1, 4]);
    expect(ids('for time'), [2, 5]);
    expect(ids('amrap'), [3]);
  });

  test('날짜·난도·시간으로도 찾는다', () {
    expect(ids('8/28'), [1]);
    expect(ids('2026-08-26'), [2]);
    expect(ids('rxd'), [1, 3, 5]);
    expect(ids('scaled'), [2]);
    expect(ids('6:52'), [2]);
  });

  test('대소문자·가운뎃점 무시', () {
    expect(ids('THRUSTER'), [2]);
    expect(ids('fran·thruster'), [2]);
  });

  test('더 정확히 맞는 기록이 위로 — 요약 전체 일치 > 단어 앞부분', () {
    final exact = _item(9, 'Fran', type: 'for_time', daysAgo: 30);
    final ranked = rankHistory('fran', [...items, exact]);
    // 9 는 14일 더 오래됐지만 요약이 통째로 일치해 2(단어 앞부분)보다 위.
    expect(ranked.map((e) => e.id).toList(), [9, 2]);
  });
}
