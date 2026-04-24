// v1.16 Sprint 15: 박스 공지 + 메시지 DTO.

class GymAnnouncement {
  final int id;
  final String title;
  final String body;
  final String priority; // normal · urgent
  final DateTime createdAt;

  const GymAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.priority,
    required this.createdAt,
  });

  bool get isUrgent => priority == 'urgent';

  factory GymAnnouncement.fromJson(Map<String, dynamic> j) => GymAnnouncement(
        id: (j['id'] as num).toInt(),
        title: (j['title'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        priority: (j['priority'] ?? 'normal').toString(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class GymMessageItem {
  final int id;
  final String fromHash;
  final String toHash;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final bool isMine;

  const GymMessageItem({
    required this.id,
    required this.fromHash,
    required this.toHash,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.isMine,
  });

  factory GymMessageItem.fromJson(Map<String, dynamic> j) => GymMessageItem(
        id: (j['id'] as num).toInt(),
        fromHash: (j['from_hash'] ?? '').toString(),
        toHash: (j['to_hash'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        isRead: (j['is_read'] == true),
        createdAt: DateTime.parse(j['created_at'] as String),
        isMine: (j['is_mine'] == true),
      );
}
