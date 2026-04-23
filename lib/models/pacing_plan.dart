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
