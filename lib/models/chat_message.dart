// v1.25: 회원↔코치 양방향 대화 메시지.
// GET /api/v1/gym/<id>/messages 의 항목 1개. direction=out → 내가 보낸 것.

class ChatMessage {
  final int id;
  final bool mine; // direction == 'out' (내가 보냄)
  final String title;
  final String body;
  final String kind; // note / assignment
  final String? senderName;
  final String? senderColor;
  final String? autoKind; // 시스템 자동 메시지면 값 있음
  final DateTime createdAt;
  final String? status; // 받은 것만: sent/read/accepted/...

  const ChatMessage({
    required this.id,
    required this.mine,
    required this.title,
    required this.body,
    required this.kind,
    required this.senderName,
    required this.senderColor,
    required this.autoKind,
    required this.createdAt,
    required this.status,
  });

  bool get isAuto => (autoKind ?? '').isNotEmpty;

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    final dir = (j['direction'] ?? 'in').toString();
    final my = j['my'];
    return ChatMessage(
      id: (j['id'] as num?)?.toInt() ?? 0,
      mine: dir == 'out',
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? '').toString(),
      kind: (j['kind'] ?? 'note').toString(),
      senderName: j['sender_name']?.toString(),
      senderColor: j['sender_color']?.toString(),
      autoKind: j['auto_kind']?.toString(),
      createdAt:
          DateTime.tryParse((j['created_at'] ?? '').toString())?.toLocal() ??
              DateTime.fromMillisecondsSinceEpoch(0),
      status: my is Map ? my['status']?.toString() : null,
    );
  }
}

/// v1.25: 코치 대화 목록의 1개 스레드(회원별 1:1 요약).
class CoachThread {
  final String peerHash;
  final String? peerName;
  final String? peerColor;
  final String lastBody;
  final DateTime lastAt;
  final int unread;

  const CoachThread({
    required this.peerHash,
    required this.peerName,
    required this.peerColor,
    required this.lastBody,
    required this.lastAt,
    required this.unread,
  });

  factory CoachThread.fromJson(Map<String, dynamic> j) => CoachThread(
        peerHash: (j['peer_hash'] ?? '').toString(),
        peerName: j['peer_name']?.toString(),
        peerColor: j['peer_color']?.toString(),
        lastBody: (j['last_body'] ?? '').toString(),
        lastAt:
            DateTime.tryParse((j['last_at'] ?? '').toString())?.toLocal() ??
                DateTime.fromMillisecondsSinceEpoch(0),
        unread: (j['unread'] as num?)?.toInt() ?? 0,
      );
}
