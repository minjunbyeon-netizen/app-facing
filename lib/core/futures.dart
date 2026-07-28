/// Future 보관 화면용 유틸.
library;

/// 화면이 Future 를 필드에 보관하고 FutureBuilder 가 나중에 붙는 구조
/// (숨은 TabBarView 탭 · 중첩 FutureBuilder)에서, 리스너가 붙기 전에 에러로
/// 완료되면 unhandled async error 로 샌다 — 위젯 테스트는 즉사, 실앱은 zone
/// 로그만 남고 화면은 멀쩡해 보여 원인 추적이 어렵다 (2026-07-28 골든에서 발견).
///
/// 무해한 리스너를 선부착해 에러를 "보관"만 하고 원본 future 를 그대로 반환.
/// FutureBuilder 는 늦게 붙어도 같은 에러를 정상 수신한다.
Future<T> retainError<T>(Future<T> future) {
  future.then<void>((_) {}, onError: (Object _, StackTrace _) {});
  return future;
}
