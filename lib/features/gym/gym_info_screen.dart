import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../widgets/gym_info_card.dart';
import '../../widgets/hkit.dart';
import 'gym_state.dart';

/// 내 정보 → 메뉴 → '체육관 정보' (D83 · 2026-08-29 사용자 지시 "저기에 체육관 정보
/// 새로 만들고, 거기에 누르면 수업 종류 설명 칸 넣자").
///
/// D81 에서 수업 탭 하단 카드가 사라지며 회원이 '수업 종류(이름 + 한 줄 설명)' 를 볼
/// 자리가 0곳이 됐던 것을 여기로 옮겼다. 카드 정본은 [GymInfoCard] 하나 — 체육관 이름·
/// 주소·전화 · 코치 · **수업 종류** · 수업 시간 · 모토. 이 화면은 그 카드를 상단바와 함께
/// 세울 뿐 내용을 두 번 적지 않는다.
class GymInfoScreen extends StatelessWidget {
  const GymInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gym = context.watch<GymState>().membership.gym;
    return Scaffold(
      appBar: const HkAppBar(title: '체육관 정보'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HyphenTokens.sp3),
          children: [GymInfoCard(gym: gym, margin: EdgeInsets.zero)],
        ),
      ),
    );
  }
}
