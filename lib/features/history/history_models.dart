/// History 도메인 모델 -- 백엔드 /api/v1/history/* 응답 DTO.
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
