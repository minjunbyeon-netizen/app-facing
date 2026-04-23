/// History 도메인 모델 -- 백엔드 /api/v1/history/* 응답 DTO.
class EngineSnapshotRecord {
  final int id;
  final double overallScore;
  final int overallNumber;
  final String overallLabel;
  final double? gymnasticsScore;
  final double? weightliftingScore;
  final double? cardioScore;
  final double? powerScore;
  final double? olympicScore;
  final double? metconScore;
  final int itemsUsed;
  final DateTime scoredAt;

  const EngineSnapshotRecord({
    required this.id,
    required this.overallScore,
    required this.overallNumber,
    required this.overallLabel,
    this.gymnasticsScore,
    this.weightliftingScore,
    this.cardioScore,
    this.powerScore,
    this.olympicScore,
    this.metconScore,
    required this.itemsUsed,
    required this.scoredAt,
  });

  factory EngineSnapshotRecord.fromJson(Map<String, dynamic> j) {
    double? f(dynamic v) => v == null ? null : (v as num).toDouble();
    return EngineSnapshotRecord(
      id: (j['id'] as num).toInt(),
      overallScore: (j['overall_score'] as num).toDouble(),
      overallNumber: (j['overall_number'] as num).toInt(),
      overallLabel: (j['overall_label'] ?? '').toString(),
      gymnasticsScore: f(j['gymnastics_score']),
      weightliftingScore: f(j['weightlifting_score']),
      cardioScore: f(j['cardio_score']),
      powerScore: f(j['power_score']),
      olympicScore: f(j['olympic_score']),
      metconScore: f(j['metcon_score']),
      itemsUsed: ((j['items_used'] ?? 0) as num).toInt(),
      scoredAt: DateTime.parse(j['scored_at'] as String),
    );
  }
}

class WodHistoryItem {
  final int id;
  final String wodType;
  final int? timeCapSec;
  final int? rounds;
  final String notes;
  final DateTime createdAt;
  final int? estimatedTotalSec;
  final String? grade;
  final String? formulaVersion;

  const WodHistoryItem({
    required this.id,
    required this.wodType,
    this.timeCapSec,
    this.rounds,
    required this.notes,
    required this.createdAt,
    this.estimatedTotalSec,
    this.grade,
    this.formulaVersion,
  });

  factory WodHistoryItem.fromJson(Map<String, dynamic> j) {
    final plan = j['plan'] as Map<String, dynamic>?;
    return WodHistoryItem(
      id: (j['id'] as num).toInt(),
      wodType: (j['wod_type'] ?? '').toString(),
      timeCapSec: (j['time_cap_sec'] as num?)?.toInt(),
      rounds: (j['rounds'] as num?)?.toInt(),
      notes: (j['notes'] ?? '').toString(),
      createdAt: DateTime.parse(j['created_at'] as String),
      estimatedTotalSec: (plan?['estimated_total_sec'] as num?)?.toInt(),
      grade: plan?['grade']?.toString(),
      formulaVersion: plan?['formula_version']?.toString(),
    );
  }

  String get estimatedTotalDisplay {
    if (estimatedTotalSec == null) return '-';
    final m = estimatedTotalSec! ~/ 60;
    final s = estimatedTotalSec! % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
