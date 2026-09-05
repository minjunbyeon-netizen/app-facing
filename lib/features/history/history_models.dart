import '../../core/time_format.dart';

/// 히스토리 한 줄 — 백엔드 `GET /api/v1/history/wod` 응답 DTO (D91 · 2026-08-30).
///
/// 정본은 서버의 수업 결과 표(`gym_wod_results`) 한 벌이다 — `id` 는 **결과 id**.
/// 점수 라벨(`label` — '4:18' · '5R+3' · '40kg×5')·종류(`kind`)·PR(`isPr`)·그날 운동 요약
/// (`summary`)·종류 라벨(`wodTypeLabel`)은 **서버가 완성**해 내려주고 앱은 그대로 보여 준다
/// (대전제 6-b — 앱은 다시 판정하지 않는다. 구 클라이언트 PR 판정 `PrDetector` 는 삭제).
class WodHistoryItem {
  final int id;
  final int postId;
  final int? classSessionId;
  final String wodType;
  final String wodTypeLabel;

  /// 게시물 본문 첫 줄 — 수업 이름 ('AWAKE').
  final String title;

  /// 그날 운동 한 줄 — 'Back Squat 5×5 · 105kg'. 동작 검색의 축.
  final String summary;

  /// 게시물 본문 전체 (검색 본문 칸 · 상세 표시).
  final String content;
  final String kind; // 'time' | 'rounds' | 'weight'
  final String label;
  final int? timeSec;
  final int? rounds;
  final int? extraReps;
  final double? weightKg;
  final int? weightReps;
  final String? movement;
  final String scaleLevel; // 'rx' | 'scaled' | 'elite'
  final bool isPr;

  /// 회원이 적은 메모.
  final String notes;

  /// 동작별 완료 값 — 서버 `movements[]` (D94). 줄 문자열은 서버 `line` 그대로,
  /// 동작 사전 번호(`movement_id`)는 동작 필터(`?movement_id=`)의 키 (2026-09-02).
  final List<WodMovementRef> movements;

  /// 파트별 점수 (D122 §7 `parts[]`). 종전에는 서버가 내려주는데 **앱이 파싱조차
  /// 하지 않아**, 회원이 파트마다 적어 낸 값을 다시 볼 방법이 없었다.
  final List<WodHistoryPart> parts;

  /// 캡에 걸려 끝난 기록인가 (서버가 파트에서 파생 — 결과 행 컬럼이 아니다).
  /// 캡 기록과 완주 기록은 **다른 단위**라 화면에서 갈라 보여 준다 (D122 §2).
  final bool capped;

  /// 헤드라인 점수가 **어느 파트에서 온 값인지** (서버 `headline_part_label`).
  /// 파트가 하나면 null — 그때는 밝힐 것이 없다.
  final String? headlinePartLabel;
  final DateTime createdAt;

  /// 동작별 완료 값 줄들 — 서버 `line` 그대로. 앱은 조립하지 않는다.
  List<String> get movementLines => [for (final m in movements) m.line];

  const WodHistoryItem({
    required this.id,
    required this.postId,
    this.classSessionId,
    required this.wodType,
    required this.wodTypeLabel,
    required this.title,
    this.summary = '',
    this.content = '',
    this.kind = 'time',
    this.label = '',
    this.timeSec,
    this.rounds,
    this.extraReps,
    this.weightKg,
    this.weightReps,
    this.movement,
    this.scaleLevel = 'rx',
    this.isPr = false,
    this.notes = '',
    this.movements = const [],
    this.parts = const [],
    this.capped = false,
    this.headlinePartLabel,
    required this.createdAt,
  });

  factory WodHistoryItem.fromJson(Map<String, dynamic> j) {
    return WodHistoryItem(
      id: (j['id'] as num).toInt(),
      postId: (j['post_id'] as num?)?.toInt() ?? 0,
      classSessionId: (j['class_session_id'] as num?)?.toInt(),
      wodType: (j['wod_type'] ?? '').toString(),
      wodTypeLabel: (j['wod_type_label'] ?? j['wod_type'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      summary: (j['summary'] ?? '').toString(),
      content: (j['content'] ?? '').toString(),
      kind: (j['kind'] ?? 'time').toString(),
      label: (j['label'] ?? '').toString(),
      timeSec: (j['time_sec'] as num?)?.toInt(),
      rounds: (j['rounds'] as num?)?.toInt(),
      extraReps: (j['extra_reps'] as num?)?.toInt(),
      weightKg: (j['weight_kg'] as num?)?.toDouble(),
      weightReps: (j['weight_reps'] as num?)?.toInt(),
      movement: j['movement']?.toString(),
      scaleLevel: (j['scale_level'] ?? 'rx').toString(),
      isPr: j['is_pr'] == true,
      notes: (j['notes'] ?? '').toString(),
      movements: [
        for (final m in (j['movements'] as List? ?? const []))
          if (m is Map && (m['line'] ?? '').toString().trim().isNotEmpty)
            WodMovementRef.fromJson(m.cast<String, dynamic>()),
      ],
      parts: [
        for (final p in (j['parts'] as List? ?? const []))
          if (p is Map && (p['line'] ?? '').toString().trim().isNotEmpty)
            WodHistoryPart.fromJson(p.cast<String, dynamic>()),
      ],
      capped: j['capped'] == true,
      headlinePartLabel: (j['headline_part_label'] ?? '')
              .toString()
              .trim()
              .isEmpty
          ? null
          : j['headline_part_label'].toString().trim(),
      createdAt: parseServerTime(j['created_at'] as String).gym(),
    );
  }

  /// 목록 첫 줄 — 제목이 비면 종류 라벨.
  String get heading => title.trim().isEmpty ? wodTypeLabel : title.trim();

  /// 목록 둘째 줄 — 그날 운동 요약, 없으면 메모, 그것도 없으면 종류 라벨 (항상 한 줄 있다).
  String get subheading {
    if (summary.trim().isNotEmpty) return summary.trim();
    if (notes.trim().isNotEmpty) return notes.trim();
    return wodTypeLabel;
  }

  /// 목록 오른쪽 점수 — 서버 라벨 그대로, 없으면 '-'.
  String get scoreDisplay => label.isEmpty ? '-' : label;

  // (구 scaleLabel — 2026-09-05 삭제. 회원이 난도를 고르는 칸이 v3.45 에서
  //  사라진 뒤로 이 값은 아무도 고르지 않은 기본값 'rx' 뿐이라, 그것을 'RXD'
  //  라는 표기로 바꾸는 순간 화면이 거짓말을 했다. [scaleLevel] 값 자체는
  //  휴면으로 계속 받는다 — 데이터는 지우지 않는다.)
}

/// 파트 한 구간의 점수 (D122 §7 `history_item.parts[]`).
///
/// [line] 은 **서버가 그린 글 그대로**다 ('A 파트 · STRENGTH — 70kg×5'). 앱은 파트
/// 라벨도 종류 이름도 조립하지 않는다 (대전제 6-b) — 받은 줄을 세우기만 한다.
class WodHistoryPart {
  final int index;
  final String wodType;
  final String line;

  const WodHistoryPart({
    required this.index,
    this.wodType = '',
    required this.line,
  });

  factory WodHistoryPart.fromJson(Map<String, dynamic> j) => WodHistoryPart(
    index: (j['index'] as num?)?.toInt() ?? 0,
    wodType: (j['wod_type'] ?? '').toString(),
    line: (j['line'] ?? '').toString().trim(),
  );
}

/// 동작 한 개 참조 — 동작 사전 번호 + 표시 이름(+완료 값 줄). 히스토리 상세의
/// '동작별 기록 보기' 탭 → 목록 `?movement_id=` 필터가 이것을 주고받는다 (2026-09-02).
/// 판정·필터는 전부 서버 — 앱은 번호를 넘길 뿐이다 (6-b).
class WodMovementRef {
  final int? id;
  final String name;
  final String line;

  const WodMovementRef({required this.id, required this.name, this.line = ''});

  factory WodMovementRef.fromJson(Map<String, dynamic> j) => WodMovementRef(
    id: (j['movement_id'] as num?)?.toInt(),
    name: (j['name'] ?? '').toString().trim(),
    line: (j['line'] ?? '').toString().trim(),
  );
}

/// 히스토리 한 페이지 + 레벨 카드가 쓰는 세 수 (서버 `meta` — 앱은 세지 않는다).
class WodHistoryPage {
  final List<WodHistoryItem> items;
  final int total;
  final int prCount;
  final int streakDays;

  const WodHistoryPage({
    required this.items,
    required this.total,
    required this.prCount,
    required this.streakDays,
  });

  static const empty = WodHistoryPage(
    items: [],
    total: 0,
    prCount: 0,
    streakDays: 0,
  );
}
