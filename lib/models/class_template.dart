/// 수업 종류(수업 안내) — 코치가 PC '수업 안내' 에서 등록한 것 (2026-08-29 · D79).
///
/// 서버 `GET /api/v1/member/gyms/<id>/class-templates` 가 준다. 종전엔 서버는
/// 주고 있었는데 앱이 **한 번도 부르지 않아** 회원 폰 어디에도 안 보였다
/// (사용자 보고 "이벤트 수업 만들었는데 회원폰에 노출이 안된다").
///
/// 이름(AWAKE·SWEAT·BUILD)이 곧 회원이 아는 이름이고, `kind == 'event'` 는
/// 정규 수업이 아닌 이벤트다 — 화면이 배지로 가른다.
class ClassTemplate {
  final int id;
  final String name;
  final String description;
  final String kind; // 'regular' | 'event'
  final String? track;
  final int durationMinutes;
  final int capacity;

  const ClassTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    this.track,
    required this.durationMinutes,
    required this.capacity,
  });

  bool get isEvent => kind == 'event';

  factory ClassTemplate.fromJson(Map<String, dynamic> j) => ClassTemplate(
    id: (j['id'] as num).toInt(),
    name: (j['name'] ?? '').toString(),
    description: (j['description'] ?? '').toString(),
    kind: (j['kind'] ?? 'regular').toString(),
    track: j['default_track']?.toString(),
    durationMinutes: (j['default_duration'] as num?)?.toInt() ?? 60,
    capacity: (j['default_capacity'] as num?)?.toInt() ?? 12,
  );
}
