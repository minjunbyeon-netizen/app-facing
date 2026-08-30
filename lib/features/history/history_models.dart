import '../../core/time_format.dart';
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
      createdAt: parseServerTime(j['created_at'] as String).toLocal(),
      estimatedTotalSec: (plan?['estimated_total_sec'] as num?)?.toInt(),
      grade: plan?['grade']?.toString(),
      formulaVersion: plan?['formula_version']?.toString(),
    );
  }

  /// 목록 한 줄 제목 — 메모 첫 줄 (수업 결과 저장은 '수업 #N · 내용 첫 줄' 을 남긴다).
  /// 메모가 비면 종류 코드 그대로(화면이 라벨로 바꾼다). D84 검색의 3배 가중 칸.
  String get summary {
    final first = notes.split('\n').first.trim();
    return first.isEmpty ? wodType : first;
  }

  /// 목록 오른쪽 점수 — 시간이 있으면 시간, 없으면 라운드(`5R`), 둘 다 없으면 '-'.
  /// D90 (2026-08-30): AMRAP 결과가 '-' 로만 보이던 것 — 서버 거울 행이 라운드를 싣는다.
  String get scoreDisplay {
    final t = estimatedTotalDisplay;
    if (t != '-') return t;
    if (rounds != null && rounds! > 0) return '${rounds}R';
    return '-';
  }

  String get estimatedTotalDisplay {
    // 결함 수정 3 (2026-08-20 실기 발견): 수업 기록 미러 등 시간 없는 기록이
    // "0:00" 으로 도배되던 문제 — 0초는 시간 미측정으로 취급.
    if (estimatedTotalSec == null || estimatedTotalSec == 0) return '-';
    final m = estimatedTotalSec! ~/ 60;
    final s = estimatedTotalSec! % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
