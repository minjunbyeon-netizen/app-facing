// v1.18 Sprint 19: Coach Group DTO.

class CoachGroup {
  final int id;
  final String name;
  final String description;
  final int memberCount;
  final DateTime createdAt;
  // v1.19 페르소나 P1-10 (C4 그룹 전문): 메타.
  final String? colorHex;
  final int? capacity;
  final List<int> weekdaySlot; // 0-6 (Mon=0)
  final String? timeSlot; // HH:MM
  final String? notes;

  const CoachGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.createdAt,
    this.colorHex,
    this.capacity,
    this.weekdaySlot = const [],
    this.timeSlot,
    this.notes,
  });

  String slotLabel() {
    if (weekdaySlot.isEmpty && (timeSlot == null || timeSlot!.isEmpty)) {
      return '';
    }
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = weekdaySlot
        .where((d) => d >= 0 && d < 7)
        .map((d) => wd[d])
        .join('/');
    if (timeSlot != null && timeSlot!.isNotEmpty) {
      return days.isEmpty ? timeSlot! : '$days $timeSlot';
    }
    return days;
  }

  factory CoachGroup.fromJson(Map<String, dynamic> j) {
    final weekdayRaw = j['weekday_slot'];
    final wdays = <int>[];
    if (weekdayRaw is String && weekdayRaw.isNotEmpty) {
      try {
        // backend 가 JSON 문자열로 저장.
        final cleaned = weekdayRaw.replaceAll('[', '').replaceAll(']', '');
        for (final part in cleaned.split(',')) {
          final n = int.tryParse(part.trim());
          if (n != null) wdays.add(n);
        }
      } catch (_) {}
    } else if (weekdayRaw is List) {
      for (final n in weekdayRaw) {
        if (n is num) wdays.add(n.toInt());
      }
    }
    return CoachGroup(
      id: ((j['id'] ?? 0) as num).toInt(),
      name: (j['name'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      memberCount: ((j['member_count'] ?? 0) as num).toInt(),
      createdAt: j['created_at'] is String
          ? DateTime.tryParse(j['created_at'] as String) ??
              DateTime.now().toUtc()
          : DateTime.now().toUtc(),
      colorHex: j['color_hex']?.toString(),
      capacity: j['capacity'] is num ? (j['capacity'] as num).toInt() : null,
      weekdaySlot: wdays,
      timeSlot: j['time_slot']?.toString(),
      notes: j['notes']?.toString(),
    );
  }
}
