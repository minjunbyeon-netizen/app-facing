// 재활 가이드 데이터 모델 + 로더.
//
// 원천: rahap1(협업 개발자 레포)의 data/movements/*.json 을 흡수한 사본.
//   → assets/data/rehab/{movement}.json + manifest.json
// 우리는 "정보"만 받아 우리 코드로 재구현한다. (지침: docs/ADDITIONAL_SOURCE_GUIDE.md)
//
// 스키마(원천 _schema 1.0): movement → pain_sites[] → questions/tests/causes/danger.
// 진입 단계(v1)에선 manifest(동작·통증부위 목록)만 모델링하고,
// 동작별 상세(질문·원인·6단계 루트)는 raw Map 으로 들고 카운트만 노출한다.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// manifest.json 한 항목 = 동작 1개 + 통증부위 목록.
class RehabMovement {
  final String id;
  final String name;
  final List<RehabPainSite> painSites;

  const RehabMovement({
    required this.id,
    required this.name,
    required this.painSites,
  });

  factory RehabMovement.fromJson(Map<String, dynamic> j) => RehabMovement(
        id: j['id'] as String,
        name: j['name'] as String,
        painSites: ((j['pain_sites'] as List?) ?? const [])
            .map((e) => RehabPainSite.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 통증 부위 참조 (id + 이름). 상세 분기는 동작 JSON 안에 있다.
class RehabPainSite {
  final String id;
  final String name;

  const RehabPainSite({required this.id, required this.name});

  factory RehabPainSite.fromJson(Map<String, dynamic> j) =>
      RehabPainSite(id: j['id'] as String, name: j['name'] as String);
}

/// 통증 부위 1개의 감별 미리보기 (질문·원인 개수 + 위험신호 안내).
/// 진입 단계 노출용. 전체 감별 플로우는 다음 iteration.
class RehabPainSitePreview {
  final String movementName;
  final String painSiteName;
  final int questionCount;
  final int causeCount;
  final String? dangerTitle;
  final String? dangerReason;
  final String? dangerAction;

  const RehabPainSitePreview({
    required this.movementName,
    required this.painSiteName,
    required this.questionCount,
    required this.causeCount,
    this.dangerTitle,
    this.dangerReason,
    this.dangerAction,
  });
}

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

  /// 특정 동작·통증부위의 감별 미리보기 추출.
  Future<RehabPainSitePreview> loadPreview(
      String movementId, String painSiteId) async {
    final mv = await loadMovementRaw(movementId);
    final movementName = (mv['name'] as String?) ?? movementId;
    final sites = (mv['pain_sites'] as List?) ?? const [];
    final site = sites.cast<Map<String, dynamic>>().firstWhere(
          (s) => s['id'] == painSiteId,
          orElse: () => <String, dynamic>{},
        );
    final questions = (site['questions'] as List?) ?? const [];
    final causes = (site['causes'] as List?) ?? const [];
    final danger = site['danger'] as Map<String, dynamic>?;
    return RehabPainSitePreview(
      movementName: movementName,
      painSiteName: (site['name'] as String?) ?? painSiteId,
      questionCount: questions.length,
      causeCount: causes.length,
      dangerTitle: danger?['title'] as String?,
      dangerReason: danger?['reason'] as String?,
      dangerAction: danger?['action'] as String?,
    );
  }
}
