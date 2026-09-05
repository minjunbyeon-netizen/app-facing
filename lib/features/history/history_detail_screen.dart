import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/time_format.dart';
import '../../widgets/hkit.dart';
import 'history_models.dart';
import 'history_repository.dart';

/// 히스토리 상세 — 기록 한 줄(`result`) + 그날 운동(`post`) + 완료한 수업(`class`).
///
/// D91 (2026-08-30): `GET /api/v1/history/wod/<결과 id>`. 목록과 **같은 줄**(서버
/// `history_item`)을 받아 크게 펼친다 — 점수·난도·PR·메모는 그 줄, 운동 본문은 게시물의
/// `content`(서버가 그린 글 그대로). 앱은 어떤 값도 조립하지 않는다.
/// (구 화면은 엔진 시절 페이싱 플랜·세그먼트를 그렸다 — 엔진 표 폐기와 함께 삭제.)
class HistoryDetailScreen extends StatefulWidget {
  final int recordId;
  const HistoryDetailScreen({super.key, required this.recordId});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late final HistoryRepository _repo;
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _repo = HistoryRepository(context.read<ApiClient>());
    _future = _repo.getWodDetail(widget.recordId);
  }

  void _load() {
    setState(() {
      _future = _repo.getWodDetail(widget.recordId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HkAppBar(title: '기록'),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const HkLoading.slot();
          }
          if (snap.hasError) {
            return HkErrorState.fromError(snap.error, onRetry: _load);
          }
          final d = snap.data;
          final resultRaw = d?['result'];
          if (d == null || resultRaw is! Map<String, dynamic>) {
            return const HkEmptyState(title: '기록 데이터 없음');
          }
          final item = WodHistoryItem.fromJson(resultRaw);
          final post = d['post'] is Map<String, dynamic>
              ? d['post'] as Map<String, dynamic>
              : const <String, dynamic>{};
          final cls = d['class'] is Map<String, dynamic>
              ? d['class'] as Map<String, dynamic>
              : null;
          final classTitle = (cls?['display_title'] ?? '').toString();
          final content = (post['content'] ?? item.content).toString().trim();
          final scaleGuide = (post['scale_guide'] ?? '').toString().trim();
          // 동작 필터 진입점 (2026-09-02) — 내가 적은 동작 + 그날 운동 동작, 사전 번호로
          // 중복 제거. 탭하면 목록으로 돌아가며 그 동작의 기록만 거른다 (판정은 서버).
          final seen = <int>{};
          final movementRefs = [
            for (final m in item.movements)
              if (m.id != null && seen.add(m.id!)) m,
            for (final m in (post['movements'] as List? ?? const []))
              if (m is Map &&
                  (m['movement_id'] as num?) != null &&
                  (m['name'] ?? '').toString().trim().isNotEmpty &&
                  seen.add((m['movement_id'] as num).toInt()))
                WodMovementRef(
                  id: (m['movement_id'] as num).toInt(),
                  name: m['name'].toString().trim(),
                ),
          ];
          return ListView(
            padding: const EdgeInsets.all(HyphenTokens.sp4),
            children: [
              Text(item.heading, style: HyphenTokens.h3),
              const SizedBox(height: HyphenTokens.sp1),
              Text(
                [
                  item.wodTypeLabel,
                  ymd(item.createdAt.gym()),
                  hhmm(item.createdAt.gym()),
                  if (classTitle.isNotEmpty && classTitle != item.heading)
                    classTitle,
                ].join(' · '),
                style: HyphenTokens.caption,
              ),
              // 점수 — 서버 라벨 그대로 (시간·라운드·무게 어느 것이든 한 문자열).
              // v3.45 (2026-09-02): 완료 입력에서 점수·난도를 없앴다. 점수가 없는
              // 기록은 이 히어로 줄을 통째로 숨긴다 — 종전엔 빈 라벨의 '-' 를 64sp
              // 로 그려 검은 막대처럼 보였다(E2E 실검증에서 발견). 동작별 기록이
              // 곧 그 회원의 기록이다. 옛 점수·난도 기록은 그대로 보여 준다.
              if (item.label.isNotEmpty) ...[
                const SizedBox(height: HyphenTokens.sp4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      item.scoreDisplay,
                      style: HyphenTokens.display.copyWith(
                        fontFeatures: HyphenTokens.tabular,
                      ),
                    ),
                    // 2026-09-05 — 난도 배지 삭제. v3.45 에서 회원이 난도를 고르는
                    // 칸을 없앴는데 앱은 기본값 'rx' 를 계속 보냈고, 이 자리가 그것을
                    // 조건 없이 'RXD' 라고 단정했다. 코치 처방보다 가볍게 든 기록에도
                    // 붙는 거짓말이다 (제1원칙). 다시 보여주려면 **고르는 창구**부터
                    // 만든다. 게이트 = test/no_false_scale_badge_test.dart.
                    // D122 §2 — 캡에 걸려 끝난 기록은 완주 기록과 **다른 단위**다.
                    // 같은 얼굴로 보여 주면 자기 기록끼리도 잘못 견준다.
                    if (item.capped) ...[
                      const SizedBox(width: HyphenTokens.sp2),
                      const HkBadge('캡'),
                    ],
                    if (item.isPr) ...[
                      const SizedBox(width: HyphenTokens.sp2),
                      const HkBadge('PR', color: HyphenTokens.primary),
                    ],
                  ],
                ),
              ],
              if (item.movement != null && item.movement!.isNotEmpty) ...[
                const SizedBox(height: HyphenTokens.sp1),
                Text(item.movement!, style: HyphenTokens.caption),
              ],
              // D122 §7 — 파트별 점수. 서버 `parts[]` 의 `line` 을 그대로 세운다
              // (앱이 파트 라벨·종류를 조립하지 않는다). 파트가 하나뿐이거나 점수를
              // 안 적은 기록에는 칸도 없다.
              if (item.parts.isNotEmpty) ...[
                const SizedBox(height: HyphenTokens.sp5),
                const HkSectionLabel('파트별 기록'),
                const SizedBox(height: HyphenTokens.sp2),
                for (final p in item.parts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: HyphenTokens.sp1),
                    child: Text(p.line, style: HyphenTokens.body),
                  ),
              ],
              // D94 — 회원이 적은 동작별 값 (서버 줄 그대로). 없으면 칸도 없다 —
              // 2차 검증(2026-08-30)에서 상세에 이 칸이 빠져 있던 것을 채움.
              if (item.movementLines.isNotEmpty) ...[
                const SizedBox(height: HyphenTokens.sp5),
                const HkSectionLabel('동작별 기록'),
                const SizedBox(height: HyphenTokens.sp2),
                for (final line in item.movementLines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: HyphenTokens.sp1),
                    child: Text(line, style: HyphenTokens.body),
                  ),
              ],
              if (item.notes.trim().isNotEmpty) ...[
                const SizedBox(height: HyphenTokens.sp5),
                const HkSectionLabel('메모'),
                const SizedBox(height: HyphenTokens.sp2),
                Text(item.notes.trim(), style: HyphenTokens.body),
              ],
              const SizedBox(height: HyphenTokens.sp5),
              const HkSectionLabel('수업 내용'),
              const SizedBox(height: HyphenTokens.sp2),
              Text(
                content.isEmpty ? '내용 없음.' : content,
                style: HyphenTokens.body,
              ),
              if (scaleGuide.isNotEmpty) ...[
                const SizedBox(height: HyphenTokens.sp4),
                const HkSectionLabel('난도 안내'),
                const SizedBox(height: HyphenTokens.sp2),
                Text(scaleGuide, style: HyphenTokens.caption),
              ],
              // 동작 배지 탭 → 목록이 그 동작의 기록만 거른다 (`?movement_id=`,
              // 판정 정본 = 서버 program_lines.result_movement_ids — 6-b).
              if (movementRefs.isNotEmpty) ...[
                const SizedBox(height: HyphenTokens.sp5),
                const HkSectionLabel('동작별 기록 보기'),
                const SizedBox(height: HyphenTokens.sp2),
                Wrap(
                  spacing: HyphenTokens.sp2,
                  runSpacing: HyphenTokens.sp2,
                  children: [
                    for (final m in movementRefs)
                      HkBadge(m.name, onTap: () => Navigator.of(context).pop(m)),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
