import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../models/announcement.dart';

/// 공지 한 줄 — 고정핀 · 제목 · 날짜 · 본문 미리보기.
///
/// v3.25 (2026-08-25 사용자 지시 "따로 있는 것 전부 통일"): 홈 아코디언
/// (`_HomeAnnouncementRow`)과 수업 탭 아코디언(`_AnnouncementRow`)이 글자 하나
/// 다른 복사본이었다 (본문 줄 수 2 vs 3). 줄 수만 인자로 받는다.
class AnnouncementRow extends StatelessWidget {
  final GymAnnouncement item;
  final int bodyMaxLines;

  const AnnouncementRow({super.key, required this.item, this.bodyMaxLines = 3});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.pinned) ...[
                const Icon(
                  Icons.push_pin_outlined,
                  size: 14,
                  color: HyphenTokens.muted,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  item.title.isNotEmpty ? item.title : '공지',
                  style: HyphenTokens.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: HyphenTokens.sp2),
              Text(mdDot(item.createdAt.gym()), style: HyphenTokens.micro),
            ],
          ),
          if (item.body.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.body,
              style: HyphenTokens.caption,
              maxLines: bodyMaxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
