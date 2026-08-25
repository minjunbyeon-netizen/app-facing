import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/shell_nav_bus.dart';
import '../../core/theme.dart';
import '../../widgets/hkit.dart';
import '../../widgets/mascot.dart';
import '../auth/auth_state.dart';
import '../gym/box_wod_screen.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';
import '../home/home_screen.dart';
import '../announcements/announcements_state.dart';
import '../inbox/inbox_state.dart';
import '../mypage/mypage_screen.dart';
import '../../core/app_clock.dart';
import '../../core/role_labels.dart';
import '../../widgets/inbox_bell.dart';
import '../gym/membership_status_view.dart';

/// v1.27 (2026-07-28 사용자 지시): 3기둥 집중 — Home(게이미피케이션) · WOD(보드) ·
/// Profile 만 노출. 구 Attend·Rehab 탭·페이싱 계산 진입점은 숨김을 거쳐
/// v3.2(2026-08-20)에서 코드까지 삭제 (README §제거된 기능 대장).
/// Default landing = WOD(index 1).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _defaultIndex = 1; // WOD as landing tab
  int _index = _defaultIndex;
  // v1.21: 베타 피드백 — 더블탭 종료 패턴. 첫 탭 SnackBar, 2초 내 재탭 시 종료.
  DateTime? _lastBackPress;

  ShellNavBus? _navBus;

  @override
  void initState() {
    super.initState();
    _navBus = context.read<ShellNavBus>();
    _navBus?.addListener(_onNavRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final gs = context.read<GymState>();
      if (gs.membership.gym != null) {
        await context.read<InboxState>().bind(gs.membership.gym!.id);
      }
    });
  }

  void _onNavRequest() {
    final idx = _navBus?.requestedIndex;
    if (idx == null) return;
    if (idx == _index) {
      _navBus?.consume();
      return;
    }
    setState(() => _index = idx);
    _navBus?.consume();
  }

  @override
  void dispose() {
    _navBus?.removeListener(_onNavRequest);
    super.dispose();
  }

  // v1.27: 3탭 — Home(게이미피케이션) · WOD(보드) · Profile.
  // v3.0 (2026-08-14 사용자 지시): 크로스핏장이 아니므로 표기를 일반 용어로 —
  // 홈 · 수업 · 내 정보. 내부 심볼·라우트는 유지 (표기만 교체).
  static const List<_TabDef> _tabs = [
    _TabDef(icon: Icons.home_outlined, selectedIcon: Icons.home, label: '홈'),
    _TabDef(
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt,
      label: '수업',
    ),
    _TabDef(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: '내 정보',
    ),
  ];

  late final List<Widget> _pages = [
    const HomeScreen(embedded: true),
    const BoxWodScreen(embedded: true),
    const MyPageScreen(embedded: true),
  ];

  void _onTap(int i) {
    if (i == _index) return;
    Haptic.selection();
    setState(() => _index = i);
    // v1.26: 공지 노출처가 WOD 보드 상단 아코디언 → WOD 진입 시점에 읽음 처리
    if (i == 1) {
      context.read<AnnouncementsState>().markSeen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // v1.21 (BLOCKER fix): GymState 로드 완료 후 InboxState bind 재시도.
    // initState 시점 gym=null 이라 bind 누락되는 케이스 보완.
    final gs = context.watch<GymState>();
    // v2.8 (2026-08-13 사용자 지시): 코치가 승인하기 전에는 아무 기능도 열지 않는다.
    // 탭마다 따로 막으면 한 곳을 빠뜨리므로 셸 입구에서 한 번에 막는다.
    if (gs.membership.isPending) return const _PendingGate();
    final inboxState = context.read<InboxState>();
    final annState = context.read<AnnouncementsState>();
    final currentGymId = gs.membership.gym?.id;
    if (currentGymId != null && inboxState.boundGymId != currentGymId) {
      Future.microtask(() => inboxState.bind(currentGymId));
    }
    if (currentGymId != null && annState.boundGymId != currentGymId) {
      final repo = context.read<GymRepository>();
      Future.microtask(() => annState.bind(repo, currentGymId));
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_index != _defaultIndex) {
          setState(() => _index = _defaultIndex);
          return;
        }
        // v1.21: 더블탭 종료. 2초 내 재탭 시만 종료.
        final now = appClock.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!).inSeconds >= 2) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).clearSnackBars();
          HkSnack.show(
            context,
            '한 번 더 누르면 앱이 종료됩니다.',
            mood: MascotMood.neutral,
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        // 탭 내부 중첩 화면(채팅 입력바 등)이 키보드를 직접 처리하도록 shell 은
        // 인셋을 먹지 않는다. 그래야 키보드가 하단 탭바를 덮고, 채팅 입력칸만
        // 키보드 위로 올라온다 (탭바가 키보드와 입력칸 사이에 끼는 현상 방지).
        resizeToAvoidBottomInset: false,
        // v3.24 (2026-08-25 사용자 지시 "상단화면 통일하라고 1개로" — 코치 셸에
        // 이어 회원 셸도): 탭마다 다르던 상단바(홈=종+새로고침 / 수업=배지+종+
        // 새로고침+회원 / 내 정보=종)를 셸이 갖는 하나로. 체육관명 + '회원' + 종.
        // 어느 탭인지는 하단 탭바가 알려준다 (브리프 D47).
        appBar: HkAppBar.identity(
          name: gs.membership.gym?.name ?? 'HYPHEN',
          role: roleKoLabel(role: 'member', status: 'approved'),
          actions: const [InboxBellAction()],
        ),
        body: IndexedStack(index: _index, children: _pages),
        // v3.25: 탭바는 HkTabBar 하나 — 코치 셸과 같은 물건.
        bottomNavigationBar: HkTabBar(
          selectedIndex: _index,
          onSelected: _onTap,
          destinations: [
            for (int i = 0; i < _tabs.length; i++)
              NavigationDestination(
                // v1.26: 쪽지 미읽음 dot 은 종(벨)이 담당, 탭 dot 은
                // 새 공지(WOD 보드 상단 아코디언)만 표시.
                icon: _IconWithDot(
                  icon: _tabs[i].icon,
                  showDot:
                      i == 1 &&
                      context.watch<AnnouncementsState>().unreadCount > 0,
                  color: HyphenTokens.muted,
                ),
                selectedIcon: _IconWithDot(
                  icon: _tabs[i].selectedIcon,
                  showDot:
                      i == 1 &&
                      context.watch<AnnouncementsState>().unreadCount > 0,
                  color: HyphenTokens.primary,
                ),
                label: _tabs[i].label,
              ),
          ],
        ),
      ),
    );
  }
}

/// 승인 대기 화면 — 코치가 가입 신청을 승인하기 전까지 앱 전체를 대신한다.
///
/// v2.8 (2026-08-13 사용자 지시). 신청은 끝났지만 아직 회원이 아니므로 WOD·수업·
/// 기록 어느 것도 열지 않는다. 대신 지금 무슨 상태인지와 다음에 무엇이 일어나는지
/// 한 화면에 적어 둔다. 로그아웃은 남겨 둔다 — 안 그러면 승인 전까지 앱에 갇힌다.
class _PendingGate extends StatefulWidget {
  const _PendingGate();

  @override
  State<_PendingGate> createState() => _PendingGateState();
}

class _PendingGateState extends State<_PendingGate> {
  bool _checking = false;

  Future<void> _recheck() async {
    if (_checking) return;
    setState(() => _checking = true);
    Haptic.light();
    await context.read<GymState>().loadMine();
    if (!mounted) return;
    setState(() => _checking = false);
    // 아직 pending 이면 이 화면이 그대로 다시 그려진다 — 헛걸음이 아님을 알려준다.
    if (context.read<GymState>().membership.isPending) {
      HkSnack.show(context, '아직 승인 전입니다.', mood: MascotMood.neutral);
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthState>().signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // v3.25: 문구·골격은 MembershipStatusView 한 벌 (수업 탭 안 대기 화면과 동일).
    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      body: SafeArea(
        child: MembershipStatusView.pending(
          gymName: context.watch<GymState>().membership.gym?.name,
          onRecheck: _recheck,
          checking: _checking,
          onSignOut: _signOut,
        ),
      ),
    );
  }
}

class _TabDef {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _TabDef({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// 탭 아이콘 우상단 빨간 dot. InboxState 미읽음 표시.
class _IconWithDot extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final Color color;
  const _IconWithDot({
    required this.icon,
    required this.showDot,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).textScaler.scale(1.0);
    final dotSize = 12 * scale;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 22, color: color),
        if (showDot)
          Positioned(
            right: -4,
            top: -3,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: HyphenTokens.accent,
                shape: BoxShape.circle,
                border: Border.all(color: HyphenTokens.bg, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

// v2.9 (2026-08-14 사용자 지시): 첫 실행 탭 힌트(_TabHintOverlay) 삭제 —
// 앱에서 사라진 Tier 등 없는 기능을 안내하고 있었다. 3탭은 라벨이 곧 설명이라
// 별도 튜토리얼 없이 충분하다.
