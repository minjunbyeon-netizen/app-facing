// Q3 (v3.4 2026-08-20 승인 — docs/PLAN-record-structures.md Part A R3):
// 1RM 보드 — 리프트(동작)별 내 역대 최고 무게. Strength 수업의 완료 기록이
// 쌓이면 추이가 보인다. 집계는 전부 서버(strength-board API) — 앱은 표시만.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/gym.dart';
import '../../widgets/hkit.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';

class StrengthBoardScreen extends StatefulWidget {
  const StrengthBoardScreen({super.key});

  @override
  State<StrengthBoardScreen> createState() => _StrengthBoardScreenState();
}

class _StrengthBoardScreenState extends State<StrengthBoardScreen> {
  Future<List<StrengthBoardEntry>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final gym = context.read<GymState>().membership.gym;
    if (gym == null) return;
    setState(() {
      _future = context.read<GymRepository>().strengthBoard(gym.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HkAppBar(title: '최고 기록'),
      body: SafeArea(
        child: FutureBuilder<List<StrengthBoardEntry>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.hasError) {
              return HkErrorState.fromError(snap.error, onRetry: _load);
            }
            if (snap.connectionState != ConnectionState.done) {
              return const HkLoading();
            }
            final list = snap.data ?? const <StrengthBoardEntry>[];
            if (list.isEmpty) {
              return const HkEmptyState(
                title: '아직 무게 기록 없음',
                caption: 'Strength 수업의 완료 기록에서 무게를 저장하면 여기에 쌓입니다.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(HyphenTokens.sp4),
              children: [
                const Text('동작별 역대 최고 무게', style: HyphenTokens.caption),
                const SizedBox(height: HyphenTokens.sp3),
                for (final e in list) _BoardRow(entry: e),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 리프트 1행 — 동작명 · 최고 무게(굵게) · reps/날짜/기록 수 보조.
class _BoardRow extends StatelessWidget {
  final StrengthBoardEntry entry;
  const _BoardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final sub = <String>[
      if (entry.bestReps != null) '×${entry.bestReps}',
      if (entry.bestDate != null) entry.bestDate!,
      '기록 ${entry.count}회',
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: HyphenTokens.sp2),
      padding: const EdgeInsets.all(HyphenTokens.sp3),
      decoration: BoxDecoration(
        color: HyphenTokens.surface,
        border: Border.all(color: HyphenTokens.border),
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.movement,
                  style:
                      HyphenTokens.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(sub, style: HyphenTokens.caption),
              ],
            ),
          ),
          Text(
            '${entry.bestKg == entry.bestKg.roundToDouble() ? entry.bestKg.toInt() : entry.bestKg}kg',
            style: HyphenTokens.h3,
          ),
        ],
      ),
    );
  }
}
