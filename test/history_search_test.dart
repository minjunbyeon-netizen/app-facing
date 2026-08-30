import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen_app/features/history/history_models.dart';
import 'package:hyphen_app/features/history/history_search.dart';

/// D84 — 히스토리 검색 연관도순. 순위 규칙 정본 = history_search.dart.
/// D91 — 칸의 값은 서버가 완성한 것(제목·그날 운동 요약·종류 라벨·점수 라벨·난도).
WodHistoryItem _item(
  int id,
  String title, {
  String summary = '',
  String type = 'custom',
  String typeLabel = '수업',
  int daysAgo = 0,
  String label = '',
  String scale = 'rx',
}) => WodHistoryItem(
  id: id,
  postId: id,
  wodType: type,
  wodTypeLabel: typeLabel,
  title: title,
  summary: summary,
  content: '$title\n$typeLabel\n$summary',
  label: label,
  scaleLevel: scale,
  createdAt: DateTime(2026, 8, 29, 10).subtract(Duration(days: daysAgo)),
);

void main() {
  final items = [
    _item(1, 'BUILD', summary: 'Back Squat 5×5 · 105kg', type: 'strength',
        typeLabel: 'STRENGTH', daysAgo: 1, label: '105kg×5'),
    _item(2, 'SWEAT', summary: 'Fran 21-15-9 Thruster · Pull-up',
        type: 'for_time', typeLabel: 'FOR TIME', daysAgo: 3, label: '6:52',
        scale: 'scaled'),
    _item(3, 'AWAKE', summary: '12min AMRAP Burpee · Row 250m', type: 'amrap',
        typeLabel: 'AMRAP', daysAgo: 6, label: '7R+4'),
    _item(4, 'BUILD', summary: 'Front Squat 3×5 · 80kg', type: 'strength',
        typeLabel: 'STRENGTH', daysAgo: 8, label: '80kg×5', scale: 'elite'),
    _item(5, 'SWEAT', summary: 'Helen 3 rounds Run 400m · KB Swing · Pull-up',
        type: 'for_time', typeLabel: 'FOR TIME', daysAgo: 14, label: '10:55'),
  ];

  List<int> ids(String q) => rankHistory(q, items).map((e) => e.id).toList();

  test('빈 검색어 — 걸러내지 않고 최근순', () {
    expect(ids(''), [1, 2, 3, 4, 5]);
    expect(ids('   '), [1, 2, 3, 4, 5]);
  });

  test('낱말 하나 — 맞는 것만, 같은 점수면 최근 것이 먼저 (동작은 요약 칸)', () {
    expect(ids('squat'), [1, 4]);
    expect(ids('pull-up'), [2, 5]);
  });

  test('낱말 여러 개는 AND — 전부 맞아야 남는다', () {
    expect(ids('squat front'), [4]);
    expect(ids('squat helen'), isEmpty);
  });

  test('수업 이름이 종류보다, 종류가 본문보다 위', () {
    // 'build' 는 1·4 의 제목에, 'for time' 은 2·5 의 종류 라벨에 맞는다.
    expect(ids('build'), [1, 4]);
    expect(ids('for time'), [2, 5]);
    expect(ids('amrap'), [3]);
  });

  test('날짜·난도·점수 라벨로도 찾는다', () {
    expect(ids('8/28'), [1]);
    expect(ids('2026-08-26'), [2]);
    expect(ids('rxd'), [1, 3, 5]);
    expect(ids('scaled'), [2]);
    expect(ids('6:52'), [2]);
    expect(ids('7r+4'), [3]);
  });

  test('대소문자·가운뎃점 무시', () {
    expect(ids('THRUSTER'), [2]);
    expect(ids('fran·thruster'), [2]);
  });

  test('더 정확히 맞는 기록이 위로 — 제목 전체 일치 > 요약 앞부분', () {
    final exact = _item(9, 'Fran', type: 'for_time', typeLabel: 'FOR TIME',
        daysAgo: 30);
    final ranked = rankHistory('fran', [...items, exact]);
    // 9 는 14일 더 오래됐지만 제목이 통째로 일치해 2(요약 앞부분)보다 위.
    expect(ranked.map((e) => e.id).toList(), [9, 2]);
  });

  test('헤딩·둘째 줄은 비면 다른 칸으로 채운다 — 행 높이가 같도록', () {
    final bare = _item(7, '', typeLabel: 'FOR TIME', type: 'for_time');
    expect(bare.heading, 'FOR TIME');
    expect(bare.subheading, 'FOR TIME');
    expect(bare.scoreDisplay, '-');
    expect(items[1].scaleLabel, 'SCALED');
    expect(items[0].scaleLabel, 'RXD');
  });
}
