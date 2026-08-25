/// 날짜·시각 표기 정본 (v3.25 · 2026-08-25 사용자 지시 "따로 있는 것 전부 통일").
///
/// 10개 파일이 각자 `_hhmm`·`_ymd`·`_fmt`·`_dateShort` 를 들고 있었다 — 같은 일을
/// 열 벌로. 화면 코드는 이 넷만 쓴다. 새 표기가 필요하면 여기에 추가한다 (§0-B).
library;

String _two(int n) => n.toString().padLeft(2, '0');

/// `19:05`
String hhmm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// ISO 문자열에서 `HH:MM` 만. 파싱 실패하면 원문을 그대로 돌려준다
/// (형식이 바뀌어도 화면이 비지 않게).
String hhmmIso(String iso) {
  final t = DateTime.tryParse(iso);
  return t == null ? iso : hhmm(t);
}

/// `2026-08-25`
String ymd(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// `08.25`
String mdDot(DateTime d) => '${_two(d.month)}.${_two(d.day)}';

/// `08/25 19:05`
String mdHm(DateTime d) => '${_two(d.month)}/${_two(d.day)} ${hhmm(d)}';

/// 초 → `m:ss` (기록 시간). 숫자가 아니면 `-`.
String mmss(dynamic sec) {
  if (sec is! num) return '-';
  final t = sec.toInt();
  return '${t ~/ 60}:${_two(t % 60)}';
}
