// v1.18 Sprint 19: Coach Group DTO.

class CoachGroup {
  final int id;
  final String name;
  final String description;
  final int memberCount;
  final DateTime createdAt;

  const CoachGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.createdAt,
  });

  factory CoachGroup.fromJson(Map<String, dynamic> j) => CoachGroup(
        id: ((j['id'] ?? 0) as num).toInt(),
        name: (j['name'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        memberCount: ((j['member_count'] ?? 0) as num).toInt(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
