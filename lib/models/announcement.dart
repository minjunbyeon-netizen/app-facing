// v1.19 P2: 마케팅 피드 강화 — 이미지·CTA·기간·핀고정·카테고리.

import '../core/app_clock.dart';
import '../core/time_format.dart';

/// 공지 카테고리.
enum AnnouncementCategory {
  notice, // 공지
  event, // 이벤트
  promotion; // 프로모션

  static AnnouncementCategory fromString(String? s) {
    switch (s) {
      case 'event':
        return AnnouncementCategory.event;
      case 'promotion':
        return AnnouncementCategory.promotion;
      default:
        return AnnouncementCategory.notice;
    }
  }

  String get label {
    switch (this) {
      case AnnouncementCategory.notice:
        return 'NOTICE';
      case AnnouncementCategory.event:
        return 'EVENT';
      case AnnouncementCategory.promotion:
        return 'PROMO';
    }
  }
}

class GymAnnouncement {
  final int id;
  final String title;
  final String body;
  final String priority; // normal · urgent
  final String? imageUrl;
  final String? ctaLabel;
  final String? ctaUrl;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool pinned;
  final AnnouncementCategory category;
  final String visibleTo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const GymAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.priority,
    this.imageUrl,
    this.ctaLabel,
    this.ctaUrl,
    this.startAt,
    this.endAt,
    this.pinned = false,
    this.category = AnnouncementCategory.notice,
    this.visibleTo = 'all',
    required this.createdAt,
    this.updatedAt,
  });

  bool get isUrgent => priority == 'urgent';
  bool get hasCta => ctaLabel != null && ctaLabel!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasDateRange => startAt != null || endAt != null;

  /// 기간 표시 문자열. e.g. "5월 1일 ~ 5월 30일" or "오늘 마감"
  String? get dateRangeLabel {
    if (!hasDateRange) return null;
    final now = appClock.now();
    String fmt(DateTime d) {
      return '${d.month}월 ${d.day}일';
    }

    if (endAt != null) {
      final diff = endAt!.difference(now).inHours;
      if (diff <= 24 && diff >= 0) return '오늘 마감';
      if (startAt != null) {
        return '${fmt(startAt!)} ~ ${fmt(endAt!)}';
      }
      return '~ ${fmt(endAt!)}';
    }
    if (startAt != null) {
      return '${fmt(startAt!)} ~';
    }
    return null;
  }

  factory GymAnnouncement.fromJson(Map<String, dynamic> j) => GymAnnouncement(
        id: (j['id'] as num).toInt(),
        title: (j['title'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        priority: (j['priority'] ?? 'normal').toString(),
        imageUrl: j['image_url'] as String?,
        ctaLabel: j['cta_label'] as String?,
        ctaUrl: j['cta_url'] as String?,
        startAt: j['start_at'] != null
            ? tryParseServerTime(j['start_at'] as String)?.gym()
            : null,
        endAt: j['end_at'] != null
            ? tryParseServerTime(j['end_at'] as String)?.gym()
            : null,
        pinned: j['pinned'] == true,
        category: AnnouncementCategory.fromString(j['category'] as String?),
        visibleTo: (j['visible_to'] ?? 'all').toString(),
        createdAt: parseServerTime(j['created_at'] as String).gym(),
        updatedAt: j['updated_at'] != null
            ? tryParseServerTime(j['updated_at'] as String)?.gym()
            : null,
      );
}
