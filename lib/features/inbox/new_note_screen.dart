import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../../widgets/avatar.dart';
import '../../widgets/hkit.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';
import 'inbox_screen.dart';

/// 새 쪽지 — 내 회원 목록에서 받을 사람을 누르면 그 회원과의 대화(ChatThreadScreen)
/// 로 들어가 아래 입력칸에 쓰고 보낸다.
///
/// v3.28 (2026-08-25 사용자 지시): 구 작성 화면(대상 individual/group/all · 종류
/// note/assignment · 제목·근거·기한·동작 표)을 전부 걷었다. 코치 폰에서 쪽지는
/// "누구에게 → 뭐라고" 둘이면 끝. 전송은 종전과 같은 API
/// (`POST /gym/<id>/notes` individual, kind=note) — PC 쪽지함이 그대로 받는다.
class NewNoteScreen extends StatefulWidget {
  const NewNoteScreen({super.key});

  @override
  State<NewNoteScreen> createState() => _NewNoteScreenState();
}

class _NewNoteScreenState extends State<NewNoteScreen> {
  Future<List<GymMember>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final gym = context.read<GymState>().membership.gym;
    if (gym == null) return;
    setState(() {
      _future = context.read<GymRepository>().listMembers(gym.id);
    });
  }

  Future<void> _open(GymMember m) async {
    final gym = context.read<GymState>().membership.gym;
    final hash = m.deviceHashFull;
    if (gym == null || hash == null || hash.isEmpty) return;
    Haptic.light();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(
          gymId: gym.id,
          peerHash: hash,
          peerName: m.displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HkAppBar(title: '새 쪽지'),
      body: SafeArea(
        child: _future == null
            ? const HkEmptyState(title: '체육관 정보 없음')
            : FutureBuilder<List<GymMember>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const HkLoading();
                  }
                  if (snap.hasError) {
                    return HkErrorState.fromError(snap.error, onRetry: _load);
                  }
                  final members =
                      (snap.data ?? const <GymMember>[])
                          .where((m) => m.isApproved)
                          .toList()
                        ..sort(
                          (a, b) => a.displayName.compareTo(b.displayName),
                        );
                  if (members.isEmpty) {
                    return const HkEmptyState(
                      title: '회원 없음',
                      caption: '승인된 회원이 아직 없습니다.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: HyphenTokens.sp4,
                      vertical: HyphenTokens.sp3,
                    ),
                    children: [
                      const HkSectionLabel('받는 사람'),
                      const SizedBox(height: HyphenTokens.sp2),
                      HkRowCard(
                        rows: [
                          for (final m in members)
                            HkListRow(
                              leadingWidget: Avatar(
                                hash: m.deviceHashFull ?? m.deviceHashPrefix,
                                displayName: m.displayName,
                              ),
                              title: m.displayName,
                              subtitle: (m.phone ?? '').isNotEmpty
                                  ? m.phone
                                  : null,
                              onTap: () => _open(m),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
