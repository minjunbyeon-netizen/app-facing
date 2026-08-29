import '../gym/wod_type_label.dart';
import 'history_models.dart';

/// 히스토리 검색 — **연관도순** 정렬 (D84 · 2026-08-29 사용자 지시 "히스토리라는 목록
/// 만들어. 거기는 검색이 되는 거고 연관도순으로 검색되게").
///
/// 순위를 매기는 자리는 **이 파일 하나**다 (글로벌 §3 코드 SSOT). 화면은 호출만 한다.
/// 서버는 손대지 않았다 — 히스토리는 회원 한 사람의 기록이라 전부 받아 둔 뒤(저장소가
/// 100건씩 끝까지 읽는다) 폰에서 고른다. 페이싱 계산이 아니라 목록 고르기라 앱 계산 0
/// 원칙(계산은 서버)과 충돌하지 않는다.
///
/// 규칙
/// - 검색어는 공백으로 나눈 **낱말 전부**가 어딘가에 맞아야 한다 (AND). 하나라도 안
///   맞으면 빠진다 — 낱말을 더 칠수록 좁아지는 것이 검색의 상식이다.
/// - 낱말 하나의 점수 = 가장 잘 맞는 칸의 (맞는 정도 × 칸 가중치). 맞는 정도는
///   칸 전체 일치 10 · 칸 앞부분 6 · 칸 안 단어 앞부분 4 · 어디든 포함 2.
/// - 칸 가중치: 요약(수업 내용 첫 줄) 3 · 종류(FOR TIME·AMRAP·수업) 2 · 날짜 2 ·
///   본문(메모 전체) 1 · 난도(scaled/rxd/elite) 1 · 시간(12:34) 1.
/// - 같은 점수면 **최근 것이 먼저**. 검색어가 비면 순위 없이 최근순 그대로.
List<WodHistoryItem> rankHistory(String query, List<WodHistoryItem> items) {
  final tokens = searchTokens(query);
  final out = List<WodHistoryItem>.of(items);
  if (tokens.isEmpty) {
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }
  final scored = <(WodHistoryItem, int)>[];
  for (final it in out) {
    final s = scoreHistoryItem(tokens, it);
    if (s > 0) scored.add((it, s));
  }
  scored.sort((a, b) {
    final c = b.$2.compareTo(a.$2);
    if (c != 0) return c;
    return b.$1.createdAt.compareTo(a.$1.createdAt);
  });
  return [for (final e in scored) e.$1];
}

/// 검색어 → 낱말 목록 (소문자 · 공백/가운뎃점 기준 분리 · 빈 것 제거).
List<String> searchTokens(String query) => query
    .toLowerCase()
    .split(RegExp(r'[\s·]+'))
    .map((t) => t.trim())
    .where((t) => t.isNotEmpty)
    .toList();

/// 기록 하나의 점수. 낱말 하나라도 못 맞추면 0.
int scoreHistoryItem(List<String> tokens, WodHistoryItem item) {
  final fields = searchFields(item);
  var total = 0;
  for (final t in tokens) {
    var best = 0;
    for (final (text, weight) in fields) {
      final k = _matchKind(text, t) * weight;
      if (k > best) best = k;
    }
    if (best == 0) return 0;
    total += best;
  }
  return total;
}

/// 검색 대상 칸 (소문자 본문, 가중치). 화면에 보이는 것만 찾는다 — 보이지 않는 값으로
/// 순위가 오르면 "왜 이게 위에 있지" 가 된다.
List<(String, int)> searchFields(WodHistoryItem item) {
  final d = item.createdAt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  final grade = item.grade?.toLowerCase().trim() ?? '';
  return [
    (item.summary.toLowerCase(), 3),
    (wodTypeLabel(item.wodType).toLowerCase(), 2),
    ('${d.year}-${two(d.month)}-${two(d.day)}', 2),
    ('${d.year}.${d.month}.${d.day}', 2),
    ('${d.month}/${d.day}', 2),
    ('${d.month}월 ${d.day}일', 2),
    (item.notes.toLowerCase(), 1),
    if (grade.isNotEmpty) (grade, 1),
    // 앱 표기는 RXD (GLOSSARY §3) — 서버 값 'rx' 를 그 이름으로도 찾는다.
    if (grade == 'rx') ('rxd', 1),
    if (item.estimatedTotalDisplay != '-') (item.estimatedTotalDisplay, 1),
  ];
}

int _matchKind(String text, String token) {
  if (text.isEmpty) return 0;
  if (text == token) return 10;
  if (text.startsWith(token)) return 6;
  final idx = text.indexOf(token);
  if (idx < 0) return 0;
  // 단어 앞부분: 바로 앞 글자가 구분자(공백·기호)일 때.
  final prev = text[idx - 1];
  if (RegExp(r'[\s\-·#(/.:×x]').hasMatch(prev)) return 4;
  return 2;
}
