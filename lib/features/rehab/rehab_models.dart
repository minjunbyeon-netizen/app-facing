// 재활 가이드 데이터 모델 + 로더.
//
// 원천: rahap1(협업 개발자 레포)의 data/movements/*.json 을 흡수한 사본.
//   → assets/data/rehab/{movement}.json + manifest.json
// 우리는 "정보"만 받아 우리 코드로 재구현한다. (지침: docs/ADDITIONAL_SOURCE_GUIDE.md)
//
// 스키마(원천 _schema 1.0):
//   movement → pain_sites[] → { entry_question, questions[], tests[], danger, causes[] }
//   question.choices[].next / test.pass_next / test.fail_next 는 노드 참조 문자열:
//     "q:<id>"     → 다음 질문
//     "test:<id>"  → 자가 테스트
//     "cause:<id>" → 원인 + 6단계 재활 루트 (종착)
//     "danger"     → 즉시 중단 경고 (종착)
//   cause.route.stages[] 는 type 으로 분기:
//     (type 없음)        → 운동 단계 (exercises[])
//     "reassessment"     → 재평가 (checklist[])
//     "tips"             → 운동 복귀 (tips[])

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

// ─────────────────────────────────────────────────────────────
// manifest (진입 화면용)
// ─────────────────────────────────────────────────────────────

/// manifest.json 한 항목 = 동작 1개 + 통증부위 목록.
class RehabMovement {
  final String id;
  final String name;
  final bool comingSoon;
  final List<RehabPainSite> painSites;

  const RehabMovement({
    required this.id,
    required this.name,
    required this.comingSoon,
    required this.painSites,
  });

  factory RehabMovement.fromJson(Map<String, dynamic> j) => RehabMovement(
        id: j['id'] as String,
        name: j['name'] as String,
        comingSoon: j['coming_soon'] == true,
        painSites: ((j['pain_sites'] as List?) ?? const [])
            .map((e) => RehabPainSite.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 통증 부위 참조 (id + 이름). 상세 분기는 동작 JSON 안에 있다.
class RehabPainSite {
  final String id;
  final String name;
  final bool comingSoon;

  const RehabPainSite({
    required this.id,
    required this.name,
    this.comingSoon = false,
  });

  factory RehabPainSite.fromJson(Map<String, dynamic> j) => RehabPainSite(
        id: j['id'] as String,
        name: j['name'] as String,
        comingSoon: j['coming_soon'] == true,
      );
}

// ─────────────────────────────────────────────────────────────
// 감별 플로우 노드
// ─────────────────────────────────────────────────────────────

/// 질문 1개의 선택지.
class RehabChoice {
  final String id;
  final String text;

  /// 다음 노드 참조. "q:..", "test:..", "cause:..", "danger".
  final String next;

  const RehabChoice({required this.id, required this.text, required this.next});

  factory RehabChoice.fromJson(Map<String, dynamic> j) => RehabChoice(
        id: j['id'] as String,
        text: j['text'] as String,
        next: j['next'] as String,
      );
}

/// 감별 질문.
class RehabQuestion {
  final String id;
  final String text;
  final String? sub;
  final List<RehabChoice> choices;

  const RehabQuestion({
    required this.id,
    required this.text,
    this.sub,
    required this.choices,
  });

  factory RehabQuestion.fromJson(Map<String, dynamic> j) => RehabQuestion(
        id: j['id'] as String,
        text: j['text'] as String,
        sub: j['sub'] as String?,
        choices: ((j['choices'] as List?) ?? const [])
            .map((e) => RehabChoice.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 자가 테스트 (통과/실패로 원인이 갈린다).
class RehabTest {
  final String id;
  final String name;
  final String purpose;
  final List<String> steps;
  final String? note;
  final String passText;
  final String failText;
  final String passNext; // "cause:.."
  final String failNext; // "cause:.."

  const RehabTest({
    required this.id,
    required this.name,
    required this.purpose,
    required this.steps,
    this.note,
    required this.passText,
    required this.failText,
    required this.passNext,
    required this.failNext,
  });

  factory RehabTest.fromJson(Map<String, dynamic> j) => RehabTest(
        id: j['id'] as String,
        name: j['name'] as String,
        purpose: (j['purpose'] as String?) ?? '',
        steps: ((j['steps'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        note: j['note'] as String?,
        passText: (j['pass_text'] as String?) ?? '통과',
        failText: (j['fail_text'] as String?) ?? '실패',
        passNext: j['pass_next'] as String,
        failNext: j['fail_next'] as String,
      );
}

/// 즉시 중단 경고.
class RehabDanger {
  final String title;
  final String reason;
  final String action;

  const RehabDanger({
    required this.title,
    required this.reason,
    required this.action,
  });

  factory RehabDanger.fromJson(Map<String, dynamic> j) => RehabDanger(
        title: (j['title'] as String?) ?? '운동을 멈추세요',
        reason: (j['reason'] as String?) ?? '',
        action: (j['action'] as String?) ?? '',
      );
}

// ─────────────────────────────────────────────────────────────
// 원인 + 6단계 재활 루트
// ─────────────────────────────────────────────────────────────

/// 재활 운동 1개.
class RehabExercise {
  final String name;
  final String why;
  final String sets;
  final String cue;
  final List<String> how;

  const RehabExercise({
    required this.name,
    required this.why,
    required this.sets,
    required this.cue,
    required this.how,
  });

  factory RehabExercise.fromJson(Map<String, dynamic> j) => RehabExercise(
        name: (j['name'] as String?) ?? '',
        why: (j['why'] as String?) ?? '',
        sets: (j['sets'] as String?) ?? '',
        cue: (j['cue'] as String?) ?? '',
        how: ((j['how'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
      );
}

/// 운동 복귀 팁.
class RehabTip {
  final String title;
  final String body;

  const RehabTip({required this.title, required this.body});

  factory RehabTip.fromJson(Map<String, dynamic> j) => RehabTip(
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
      );
}

/// 재활 루트의 한 단계. type 으로 3종 분기.
enum RehabStageKind { exercise, reassessment, tips }

class RehabStage {
  final String id;
  final String name;
  final RehabStageKind kind;
  final String? duration;

  // exercise
  final List<RehabExercise> exercises;
  // reassessment
  final List<String> checklist;
  final String? passNote;
  final String? failNote;
  // tips
  final List<RehabTip> tips;

  const RehabStage({
    required this.id,
    required this.name,
    required this.kind,
    this.duration,
    this.exercises = const [],
    this.checklist = const [],
    this.passNote,
    this.failNote,
    this.tips = const [],
  });

  factory RehabStage.fromJson(Map<String, dynamic> j) {
    final type = j['type'] as String?;
    final kind = switch (type) {
      'reassessment' => RehabStageKind.reassessment,
      'tips' => RehabStageKind.tips,
      _ => RehabStageKind.exercise,
    };
    return RehabStage(
      id: (j['id'] as String?) ?? '',
      name: (j['name'] as String?) ?? '',
      kind: kind,
      duration: j['duration'] as String?,
      exercises: ((j['exercises'] as List?) ?? const [])
          .map((e) => RehabExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      checklist: ((j['checklist'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
      passNote: j['pass_note'] as String?,
      failNote: j['fail_note'] as String?,
      tips: ((j['tips'] as List?) ?? const [])
          .map((e) => RehabTip.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 원인 + 루트.
class RehabCause {
  final String id;
  final String label; // "원인 A"
  final String tag; // 짧은 분류 태그
  final String name; // 풀 네임
  final String description;
  final String? priorityNote;
  final List<RehabStage> stages;

  const RehabCause({
    required this.id,
    required this.label,
    required this.tag,
    required this.name,
    required this.description,
    this.priorityNote,
    required this.stages,
  });

  factory RehabCause.fromJson(Map<String, dynamic> j) {
    final route = j['route'] as Map<String, dynamic>?;
    final stagesRaw = (route?['stages'] as List?) ?? const [];
    return RehabCause(
      id: j['id'] as String,
      label: (j['label'] as String?) ?? '',
      tag: (j['tag'] as String?) ?? '',
      name: (j['name'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      priorityNote: j['priority_note'] as String?,
      stages: stagesRaw
          .map((e) => RehabStage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 통증 부위 1개의 전체 감별 데이터 (질문·테스트·위험·원인 그래프).
class RehabPainSiteDetail {
  final String movementName;
  final String painSiteName;
  final String entryQuestion;
  final bool comingSoon;
  final Map<String, RehabQuestion> questions;
  final Map<String, RehabTest> tests;
  final RehabDanger? danger;
  final Map<String, RehabCause> causes;

  const RehabPainSiteDetail({
    required this.movementName,
    required this.painSiteName,
    required this.entryQuestion,
    required this.comingSoon,
    required this.questions,
    required this.tests,
    required this.danger,
    required this.causes,
  });

  /// 감별 플로우를 시작할 수 있는가 (질문이 하나라도 있어야).
  bool get isReady => questions.isNotEmpty && !comingSoon;

  /// 진입 노드 참조.
  String get entryRef => 'q:$entryQuestion';
}

// ─────────────────────────────────────────────────────────────
// 미리보기 (시트용 — 질문·원인 개수 + 위험신호)
// ─────────────────────────────────────────────────────────────

class RehabPainSitePreview {
  final String movementName;
  final String painSiteName;
  final int questionCount;
  final int causeCount;
  final bool comingSoon;
  final String? dangerTitle;
  final String? dangerReason;
  final String? dangerAction;

  const RehabPainSitePreview({
    required this.movementName,
    required this.painSiteName,
    required this.questionCount,
    required this.causeCount,
    required this.comingSoon,
    this.dangerTitle,
    this.dangerReason,
    this.dangerAction,
  });
}

// ─────────────────────────────────────────────────────────────
// 로더
// ─────────────────────────────────────────────────────────────

class RehabRepository {
  static const _base = 'assets/data/rehab';

  List<RehabMovement>? _manifestCache;
  final Map<String, Map<String, dynamic>> _movementCache = {};

  /// 동작·통증부위 목록 (진입 화면).
  Future<List<RehabMovement>> loadManifest() async {
    if (_manifestCache != null) return _manifestCache!;
    final raw = await rootBundle.loadString('$_base/manifest.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => RehabMovement.fromJson(e as Map<String, dynamic>))
        .toList();
    _manifestCache = list;
    return list;
  }

  /// 동작별 원본 상세 Map (질문·테스트·원인·루트 전부 포함).
  Future<Map<String, dynamic>> loadMovementRaw(String movementId) async {
    final cached = _movementCache[movementId];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('$_base/$movementId.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _movementCache[movementId] = map;
    return map;
  }

  Map<String, dynamic> _findSite(
      Map<String, dynamic> mv, String painSiteId) {
    final sites = (mv['pain_sites'] as List?) ?? const [];
    return sites.cast<Map<String, dynamic>>().firstWhere(
          (s) => s['id'] == painSiteId,
          orElse: () => <String, dynamic>{},
        );
  }

  /// 특정 동작·통증부위의 감별 미리보기 추출.
  Future<RehabPainSitePreview> loadPreview(
      String movementId, String painSiteId) async {
    final mv = await loadMovementRaw(movementId);
    final movementName = (mv['name'] as String?) ?? movementId;
    final site = _findSite(mv, painSiteId);
    final questions = (site['questions'] as List?) ?? const [];
    final causes = (site['causes'] as List?) ?? const [];
    final danger = site['danger'] as Map<String, dynamic>?;
    return RehabPainSitePreview(
      movementName: movementName,
      painSiteName: (site['name'] as String?) ?? painSiteId,
      questionCount: questions.length,
      causeCount: causes.length,
      comingSoon: site['coming_soon'] == true,
      dangerTitle: danger?['title'] as String?,
      dangerReason: danger?['reason'] as String?,
      dangerAction: danger?['action'] as String?,
    );
  }

  /// 특정 동작·통증부위의 전체 감별 그래프 (플로우 화면용).
  Future<RehabPainSiteDetail> loadPainSiteDetail(
      String movementId, String painSiteId) async {
    final mv = await loadMovementRaw(movementId);
    final movementName = (mv['name'] as String?) ?? movementId;
    final site = _findSite(mv, painSiteId);

    final questions = <String, RehabQuestion>{};
    for (final q in (site['questions'] as List?) ?? const []) {
      final qq = RehabQuestion.fromJson(q as Map<String, dynamic>);
      questions[qq.id] = qq;
    }
    final tests = <String, RehabTest>{};
    for (final t in (site['tests'] as List?) ?? const []) {
      final tt = RehabTest.fromJson(t as Map<String, dynamic>);
      tests[tt.id] = tt;
    }
    final causes = <String, RehabCause>{};
    for (final c in (site['causes'] as List?) ?? const []) {
      final cc = RehabCause.fromJson(c as Map<String, dynamic>);
      causes[cc.id] = cc;
    }
    final dangerMap = site['danger'] as Map<String, dynamic>?;

    return RehabPainSiteDetail(
      movementName: movementName,
      painSiteName: (site['name'] as String?) ?? painSiteId,
      entryQuestion: (site['entry_question'] as String?) ?? 'q1',
      comingSoon: site['coming_soon'] == true,
      questions: questions,
      tests: tests,
      danger: dangerMap == null ? null : RehabDanger.fromJson(dangerMap),
      causes: causes,
    );
  }
}
