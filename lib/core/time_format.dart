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
  final t = tryParseServerTime(iso);
  return t == null ? iso : hhmm(t.toLocal());
}

/// 서버 시각 파싱 — S7 (2026-08-26). 서버(SQLite)는 KST 벽시계를 오프셋 없이
/// 내려준다('2026-08-26T20:00:00'). `DateTime.parse` 는 이것을 **기기 시간대**로
/// 읽어서, 기기 시계가 UTC 면 20:00 KST 수업이 9시간 뒤로 밀려 시작이 지난 뒤에도
/// '예약' 이 살아 있었다(에뮬 1차 S7). 오프셋이 없으면 +09:00 을 붙여 같은
/// 순간(instant)으로 고정하고, 이미 오프셋/Z 가 있으면(Postgres 프로드) 그대로.
/// 화면 표시는 호출부가 `.toLocal()` 로 — KST 폰에서는 종전과 픽셀 동일.
DateTime parseServerTime(String iso) {
  final s = iso.trim();
  final hasOffset = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(s);
  return DateTime.parse(hasOffset ? s : '$s+09:00');
}

DateTime? tryParseServerTime(String iso) {
  try {
    return parseServerTime(iso);
  } catch (_) {
    return null;
  }
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
