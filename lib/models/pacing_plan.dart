class PacingSegment {
  final String movementSlug;
  final String segmentType;
  final List<int> splitPattern;
  final int restBetweenSec;
  final int? targetPaceSecPer500m;
  final int estimatedSec;
  final String estimatedDisplay;
  final bool isExplosion;
  final String rationaleCode;
  final String rationaleKo;

  PacingSegment({
    required this.movementSlug,
    required this.segmentType,
    required this.splitPattern,
    required this.restBetweenSec,
    required this.targetPaceSecPer500m,
    required this.estimatedSec,
    required this.estimatedDisplay,
    required this.isExplosion,
    required this.rationaleCode,
    required this.rationaleKo,
  });

  factory PacingSegment.fromJson(Map<String, dynamic> j) => PacingSegment(
    movementSlug: j['movement_slug'] as String,
    segmentType: j['segment_type'] as String,
    splitPattern: (j['split_pattern'] as List? ?? const [])
        .map((e) => (e as num).toInt()).toList(),
    restBetweenSec: (j['rest_between_sec'] as num? ?? 0).toInt(),
    targetPaceSecPer500m: (j['target_pace_sec_per_500m'] as num?)?.toInt(),
    estimatedSec: (j['estimated_sec'] as num? ?? 0).toInt(),
    estimatedDisplay: j['estimated_display']?.toString() ?? '',
    isExplosion: j['is_explosion'] == true,
    rationaleCode: j['rationale_code']?.toString() ?? '',
    rationaleKo: j['rationale_ko']?.toString() ?? '',
  );
}

class PacingPlan {
  final String formulaVersion;
  final int estimatedTotalSec;
  final String estimatedTotalDisplay;
  final List<PacingSegment> segments;

  PacingPlan({
    required this.formulaVersion,
    required this.estimatedTotalSec,
    required this.estimatedTotalDisplay,
    required this.segments,
  });

  factory PacingPlan.fromJson(Map<String, dynamic> j) => PacingPlan(
    formulaVersion: j['formula_version']?.toString() ?? '',
    estimatedTotalSec: (j['estimated_total_sec'] as num? ?? 0).toInt(),
    estimatedTotalDisplay: j['estimated_total_display']?.toString() ?? '',
    segments: ((j['segments'] as List? ?? const []))
        .map((e) => PacingSegment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

/// v1.16: 클라이언트 합성 전략 문장. 명사구+마침표 규칙.
/// 백엔드 segment 데이터 기반. 향후 백엔드가 strategy_lines 필드를 제공하면
/// 그걸 우선하고 이 extension은 폴백으로 사용.
extension PacingPlanStrategy on PacingPlan {
  List<String> strategyLines() {
    final lines = <String>[];
    if (segments.isEmpty) return ['데이터 없음.'];

    // 1. 첫 burst 세그먼트 — 어디서 터뜨리나.
    final firstBurst = segments.where((s) => s.isExplosion).toList();
    if (firstBurst.isNotEmpty) {
      final s = firstBurst.first;
      final last = s.splitPattern.isNotEmpty ? s.splitPattern.last : null;
      if (last != null) {
        lines.add(
          '${_slugLabel(s.movementSlug)} 마지막 $last회에서 버스트.',
        );
      } else {
        lines.add('${_slugLabel(s.movementSlug)}에서 버스트.');
      }
    }

    // 2. split 패턴 분석.
    final descSegs =
        segments.where((s) => _isDescending(s.splitPattern)).toList();
    if (descSegs.isNotEmpty) {
      lines.add('앞 세트 아껴서 마지막 터뜨리기.');
    } else {
      // 모든 세트 균등이면 Unbroken 권장.
      final allFlat = segments.every((s) {
        if (s.splitPattern.length <= 1) return true;
        final first = s.splitPattern.first;
        return s.splitPattern.every((x) => x == first);
      });
      if (allFlat) lines.add('전 세트 Unbroken. 드롭 없음.');
    }

    // 3. rest 전략.
    final maxRest = segments
        .map((s) => s.restBetweenSec)
        .fold<int>(0, (a, b) => a > b ? a : b);
    if (maxRest >= 15) {
      lines.add('세트 간 ${maxRest}초 레스트. 페이스 유지.');
    } else if (maxRest == 0) {
      lines.add('중간 레스트 없음.');
    }

    // 4. 카디오 페이스 있으면 안내.
    final cardioSegs = segments
        .where((s) => s.targetPaceSecPer500m != null)
        .toList();
    if (cardioSegs.isNotEmpty) {
      final p = cardioSegs.first.targetPaceSecPer500m!;
      final m = p ~/ 60;
      final sec = p % 60;
      lines.add(
        '${_slugLabel(cardioSegs.first.movementSlug)} 페이스 $m:${sec.toString().padLeft(2, '0')}/500m.',
      );
    }

    if (lines.isEmpty) {
      lines.add('분할대로 진행. 페이스 일정.');
    }
    return lines.take(4).toList();
  }

  List<String> burstPointSummaries() {
    final out = <String>[];
    for (final s in segments) {
      if (!s.isExplosion) continue;
      final last = s.splitPattern.isNotEmpty ? s.splitPattern.last : null;
      if (last != null) {
        out.add('${_slugLabel(s.movementSlug)} 마지막 $last회.');
      } else {
        out.add('${_slugLabel(s.movementSlug)} 전부.');
      }
    }
    return out;
  }

  String _slugLabel(String slug) {
    // slug → 가독성 좋은 라벨 ("thruster" → "Thruster", "back_squat" → "Back Squat")
    return slug
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  bool _isDescending(List<int> p) {
    if (p.length < 2) return false;
    for (int i = 1; i < p.length; i++) {
      if (p[i] >= p[i - 1]) return false;
    }
    return true;
  }
}
