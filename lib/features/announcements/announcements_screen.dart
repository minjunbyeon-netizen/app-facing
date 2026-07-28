// v1.19 P2: 마케팅 피드 강화 — 이미지 배너·CTA·기간·핀고정·카테고리·pull-to-refresh.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/announcement.dart';
import '../../widgets/coach_badge.dart';
import '../../widgets/gym_info_card.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';
import 'announcements_state.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<GymAnnouncement> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementsState>().markSeen();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final gs = context.read<GymState>();
      final repo = context.read<GymRepository>();
      final List<GymAnnouncement> items;
      if (gs.isOwner) {
        // 사장은 전체 목록 (기간 만료 포함)
        final gym = gs.membership.gym;
        if (gym == null) {
          items = [];
        } else {
          items = await repo.listAnnouncements(gym.id);
        }
      } else {
        // 회원은 활성 공지만
        items = await repo.listMemberAnnouncements();
      }
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.messageKo;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Calc failed. Retry.';
        _loading = false;
      });
    }
  }

  Future<void> _openCompose() async {
    Haptic.light();
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null) return;

    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final ctaLabelCtrl = TextEditingController();
    final ctaUrlCtrl = TextEditingController();
    String priority = 'normal';
    String category = 'notice';
    bool pinned = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: FacingTokens.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(FacingTokens.r4)),
        ),
        builder: (ctx) => StatefulBuilder(builder: (innerCtx, setSheet) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: FacingTokens.sp4,
              right: FacingTokens.sp4,
              top: FacingTokens.sp4,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + FacingTokens.sp4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('새 공지', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp3),
                // 카테고리
                Wrap(
                  spacing: FacingTokens.sp2,
                  children: [
                    for (final c in ['notice', 'event', 'promotion'])
                      ChoiceChip(
                        label: Text(AnnouncementCategory.fromString(c).label),
                        selected: category == c,
                        backgroundColor: FacingTokens.surface,
                        selectedColor: _categoryColor(c),
                        labelStyle: FacingTokens.micro.copyWith(
                          color: category == c
                              ? FacingTokens.bg
                              : FacingTokens.muted,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => setSheet(() => category = c),
                      ),
                  ],
                ),
                const SizedBox(height: FacingTokens.sp2),
                TextField(
                  controller: titleCtrl,
                  style: FacingTokens.body.copyWith(color: FacingTokens.fg),
                  decoration: const InputDecoration(labelText: 'Title'),
                  maxLength: 120,
                ),
                const SizedBox(height: FacingTokens.sp2),
                TextField(
                  controller: bodyCtrl,
                  style: FacingTokens.body.copyWith(color: FacingTokens.fg),
                  decoration: const InputDecoration(
                    labelText: 'Body',
                    hintText: '멤버에게 전달할 내용',
                  ),
                  maxLines: 5,
                  maxLength: 2000,
                ),
                const SizedBox(height: FacingTokens.sp2),
                TextField(
                  controller: ctaLabelCtrl,
                  style: FacingTokens.body.copyWith(color: FacingTokens.fg),
                  decoration: const InputDecoration(
                    labelText: 'CTA 버튼 텍스트 (선택)',
                    hintText: '예: 자세히 보기',
                  ),
                  maxLength: 60,
                ),
                const SizedBox(height: FacingTokens.sp2),
                TextField(
                  controller: ctaUrlCtrl,
                  style: FacingTokens.body.copyWith(color: FacingTokens.fg),
                  decoration: const InputDecoration(
                    labelText: 'CTA URL (선택)',
                    hintText: 'https://',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: FacingTokens.sp3),
                Row(
                  children: [
                    Text('핀고정', style: FacingTokens.caption),
                    const SizedBox(width: FacingTokens.sp2),
                    Switch(
                      value: pinned,
                      activeThumbColor: FacingTokens.accent,
                      onChanged: (v) => setSheet(() => pinned = v),
                    ),
                  ],
                ),
                const SizedBox(height: FacingTokens.sp3),
                Wrap(
                  spacing: FacingTokens.sp2,
                  children: ['normal', 'urgent']
                      .map((p) => ChoiceChip(
                            label: Text(p.toUpperCase()),
                            selected: priority == p,
                            backgroundColor: FacingTokens.surface,
                            selectedColor: p == 'urgent'
                                ? FacingTokens.accent
                                : FacingTokens.muted,
                            onSelected: (_) => setSheet(() => priority = p),
                          ))
                      .toList(),
                ),
                const SizedBox(height: FacingTokens.sp4),
                ElevatedButton(
                  onPressed: () async {
                    final body = bodyCtrl.text.trim();
                    if (body.isEmpty) return;
                    Haptic.medium();
                    try {
                      await context.read<GymRepository>().postAnnouncementRich(
                            gymId: gym.id,
                            title: titleCtrl.text.trim(),
                            body: body,
                            priority: priority,
                            category: category,
                            pinned: pinned,
                            ctaLabel: ctaLabelCtrl.text.trim().isEmpty
                                ? null
                                : ctaLabelCtrl.text.trim(),
                            ctaUrl: ctaUrlCtrl.text.trim().isEmpty
                                ? null
                                : ctaUrlCtrl.text.trim(),
                          );
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      _load();
                    } on AppException catch (e) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('게시 실패: ${e.messageKo}')),
                      );
                    } catch (e) {
                      debugPrint('[Announcements._compose] $e');
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('요청 실패. 다시 시도해 주세요.')),
                      );
                    }
                  },
                  child: const Text('게시'),
                ),
              ],
            ),
          );
        }),
      );
    } finally {
      titleCtrl.dispose();
      bodyCtrl.dispose();
      ctaLabelCtrl.dispose();
      ctaUrlCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지'),
        actions: [
          if (gs.isOwner) const CoachBadgeAction(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GymInfoCard(gym: gym),
            Expanded(child: _buildBody(gym)),
          ],
        ),
      ),
      floatingActionButton: gs.isOwner
          ? FloatingActionButton.extended(
              backgroundColor: FacingTokens.accent,
              foregroundColor: FacingTokens.fg,
              onPressed: _openCompose,
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('새 공지'),
            )
          : null,
    );
  }

  Widget _buildBody(dynamic gym) {
    if (gym == null) {
      return const Center(
        child: Text('박스 소속 없음.', style: FacingTokens.caption),
      );
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
            color: FacingTokens.muted, strokeWidth: 2),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(FacingTokens.sp4),
        child: Text(_error!, style: FacingTokens.body),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('Engine 기록 없음', style: FacingTokens.caption),
      );
    }
    return RefreshIndicator(
      color: FacingTokens.accent,
      backgroundColor: FacingTokens.surface,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(FacingTokens.sp4),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(height: FacingTokens.sp3),
        itemBuilder: (_, i) => _AnnouncementCard(item: _items[i]),
      ),
    );
  }
}

// ─── category 칩 색상 ────────────────────────────────────────────────────────
Color _categoryColor(String cat) {
  switch (cat) {
    case 'event':
      return FacingTokens.info; // v1.23: 파랑 — FacingTokens 참조로 교체.
    case 'promotion':
      return FacingTokens.warning; // 주황
    default:
      return FacingTokens.muted; // 회색
  }
}

// ─── 공지 카드 ────────────────────────────────────────────────────────────────
class _AnnouncementCard extends StatefulWidget {
  final GymAnnouncement item;
  const _AnnouncementCard({required this.item});

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  bool _expanded = false;

  GymAnnouncement get item => widget.item;

  static const int _bodyTruncate = 3; // 더보기 기준 줄 수

  @override
  Widget build(BuildContext context) {
    final isUrgent = item.isUrgent;
    final catColor = _categoryColor(item.category.name);
    final borderColor = isUrgent ? FacingTokens.accent : FacingTokens.border;

    return Container(
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
        border: Border.all(color: borderColor, width: isUrgent ? 2 : 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 이미지 배너
          if (item.hasImage) _ImageBanner(imageUrl: item.imageUrl!),

          Padding(
            padding: const EdgeInsets.all(FacingTokens.sp3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 메타 행
                Row(
                  children: [
                    // 카테고리 칩
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(FacingTokens.r1),
                        border: Border.all(color: catColor, width: 1),
                      ),
                      child: Text(
                        item.category.label,
                        style: FacingTokens.micro.copyWith(
                          color: catColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    // 핀고정 — 이모지 금지 규칙: SVG 없으므로 Icons 핀 아이콘 사용
                    if (item.pinned) ...[
                      const SizedBox(width: FacingTokens.sp1),
                      Icon(Icons.push_pin,
                          size: 14, color: FacingTokens.muted),
                    ],
                    const Spacer(),
                    Text(
                      _formatDate(item.createdAt),
                      style:
                          FacingTokens.micro.copyWith(color: FacingTokens.muted),
                    ),
                  ],
                ),

                // 제목
                if (item.title.isNotEmpty) ...[
                  const SizedBox(height: FacingTokens.sp2),
                  Text(
                    item.title,
                    style: FacingTokens.h3
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ],

                // 본문 (truncate + 더보기)
                const SizedBox(height: FacingTokens.sp1),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.body,
                        style: FacingTokens.body,
                        maxLines: _expanded ? null : _bodyTruncate,
                        overflow:
                            _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      ),
                      if (!_expanded &&
                          item.body.split('\n').length > _bodyTruncate) ...[
                        const SizedBox(height: 2),
                        Text('더보기',
                            style: FacingTokens.caption
                                .copyWith(color: FacingTokens.muted)),
                      ],
                    ],
                  ),
                ),

                // 기간 표시
                if (item.hasDateRange) ...[
                  const SizedBox(height: FacingTokens.sp2),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: FacingTokens.muted),
                      const SizedBox(width: 4),
                      Text(
                        item.dateRangeLabel ?? '',
                        style: FacingTokens.caption
                            .copyWith(color: FacingTokens.muted),
                      ),
                    ],
                  ),
                ],

                // CTA 버튼
                if (item.hasCta) ...[
                  const SizedBox(height: FacingTokens.sp3),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FacingTokens.accent,
                        foregroundColor: FacingTokens.fg,
                        padding: const EdgeInsets.symmetric(
                            vertical: FacingTokens.sp2),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(FacingTokens.r2),
                        ),
                      ),
                      onPressed: () => _handleCta(context),
                      child: Text(
                        item.ctaLabel!,
                        style: FacingTokens.body
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCta(BuildContext context) async {
    Haptic.light();
    final url = item.ctaUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크 열기 실패.')),
        );
      }
    } catch (e) {
      debugPrint('[CTA] $e');
    }
  }

  String _formatDate(DateTime d) {
    final l = d.toLocal();
    return '${l.month.toString().padLeft(2, '0')}/${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

// ─── 이미지 배너 ──────────────────────────────────────────────────────────────
class _ImageBanner extends StatelessWidget {
  final String imageUrl;
  const _ImageBanner({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    // static 상수이므로 클래스명으로 직접 접근
    final fullUrl = imageUrl.startsWith('http')
        ? imageUrl
        : '${ApiClient.baseUrl}$imageUrl';

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.network(
        fullUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: FacingTokens.border,
          child: const Center(
            child: Icon(Icons.broken_image_outlined,
                color: FacingTokens.muted, size: 32),
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: FacingTokens.border,
            child: const Center(
              child: CircularProgressIndicator(
                  color: FacingTokens.muted, strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }
}
