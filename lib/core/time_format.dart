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

/// 서버 순간값 파싱 — 폰 쪽 정본 (S7 · D55 2026-08-26).
/// 표준: 서버는 순간값을 항상 오프셋 포함(`2026-08-26T20:00:00+09:00`, `api/_time.py iso`)
/// 으로 내리고, 폰은 표시 직전에만 `.toLocal()` 로 기기 시간대로 바꾼다.
/// 오프셋이 없는 옛 형식(SQLite naive, D55 이전 서버)은 +09:00 을 붙여 같은 순간으로
/// 고정한다 — `DateTime.parse` 가 이를 기기 시간대로 읽으면 UTC 기기에서 20:00 KST 수업이
/// 9시간 밀려 시작이 지난 뒤에도 '예약' 이 살아 있었다(에뮬 1차 S7).
/// 날짜 전용 값(`YYYY-MM-DD` 회원권·락커 기간)은 시간대 무관 — 이 함수 대상이 아니다.
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
