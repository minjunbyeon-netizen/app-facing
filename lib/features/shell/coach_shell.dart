import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/appkit.gen.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../announcements/announcements_state.dart';
import '../boss/boss_dashboard_screen.dart';
import '../gym/box_wod_screen.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';
import '../inbox/inbox_screen.dart';
import '../inbox/inbox_state.dart';

/// v3.4 (2026-08-21 사용자 지시 "앱에서 코치 쪽지 필요") — 코치 앱 셸 3탭:
///   ① 예약 현황 — 오늘 예약·출석·수업 명단·수업 등록 (BossDashboardScreen 임베드)
///   ② 수업 — 회원 셸의 수업 탭과 **동일한 위젯** (BoxWodScreen 그대로 재사용,
///      variant 신설 금지). v3.20: 코치에게도 **보는 화면**이다 — 수업 내용
///      게시·삭제는 PC 몫 (README §제거된 기능 대장 16, 브리프 D43)
///   ③ 쪽지 — MessagingScreen 임베드 (v3.3 에서 종 뒤에 숨겼더니 기능이
///      없는 걸로 보였다 — 탭 복귀. 수업 탭 종 진입도 유지)
/// "코치는 대부분 PC. 폰 코치는 진짜 기본만." — 내 정보류 탭은 코치에게 불필요.
///
/// v3.2 의 회원 현황(CoachDashboardScreen) 탭은 계속 제거 상태. 진입 동선:
///   · 가입 승인 → 예약 현황 탭 '회원 관리' 버튼 → CoachDashboardScreen push
///
/// 수업 탭은 회원 API(X-Device-Id)를 쓴다 — 로그인만 한 기기도 admin_login 이
/// GymManager.device_hash 를 페어링하므로 백엔드 코치 기기 폴백
/// (services/facing api/roles.py is_staff_device · G13 공지 기기판 폴백)이
/// 데이터를 내려준다. 프론트에 role 분기를 추가하지 않는다 (2026-08-18).
/// 로그인 직후 페어링이 반영되도록 진입 시 GymState.loadMine() 재조회.
///
/// MainShell(회원 셸)과 같은 NavigationBar 규격 — 셸이 둘이어도 물건은 하나로
/// 보이게 한다. 공지 dot 등 회원 전용 배선은 싣지 않는다 (간단이 목적).
class CoachShell extends StatefulWidget {
  const CoachShell({super.key});

  @override
  State<CoachShell> createState() => _CoachShellState();
}

class _CoachShellState extends State<CoachShell> {
  int _index = 0;

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.event_note_outlined),
      selectedIcon: Icon(Icons.event_note),
      label: '예약 현황',
    ),
    NavigationDestination(
      icon: Icon(Icons.list_alt_outlined),
      selectedIcon: Icon(Icons.list_alt),
      label: '수업',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: '쪽지',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 코치 로그인 직후 진입 — 앱 부팅 시점 loadMine 은 페어링 전이라
    // gym=null 일 수 있다. 여기서 한 번 더 읽어 코치 기기 폴백을 반영.
    // (수업 탭 + '회원 관리' → CoachDashboardScreen push 둘 다 이 값에 의존.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GymState>().loadMine();
    });
  }

  void _onTap(int i) {
    if (i == _index) return;
    Haptic.selection();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    // 수업 탭 공지 아코디언(AnnouncementsState) + 쪽지 탭·종 미읽음
    // dot(InboxState) 배선.
    final gymId = gs.membership.gym?.id;
    if (gymId != null) {
      final inboxState = context.read<InboxState>();
      if (inboxState.boundGymId != gymId) {
        Future.microtask(() => inboxState.bind(gymId));
      }
      final annState = context.read<AnnouncementsState>();
      if (annState.boundGymId != gymId) {
        final repo = context.read<GymRepository>();
        Future.microtask(() => annState.bind(repo, gymId));
      }
    }

    final pages = <Widget>[
      const BossDashboardScreen(),
      const BoxWodScreen(),
      const MessagingScreen(title: '쪽지'),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: HyphenTokens.bg,
          surfaceTintColor: Colors.transparent,
          indicatorColor: HyphenTokens.accent.withValues(alpha: 0.18),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HyphenTokens.r2),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return HyphenTokens.micro.copyWith(
              color: selected ? HyphenTokens.primary : HyphenTokens.muted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.1,
            );
          }),
        ),
        child: SafeArea(
          top: false,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: HyphenTokens.border, width: 1),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _onTap,
              height: AppKit.tabbarH,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: _destinations,
            ),
          ),
        ),
      ),
    );
  }
}
