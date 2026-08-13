import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/appkit.gen.dart';
import '../../core/haptic.dart';
import '../../core/shell_nav_bus.dart';
import '../../core/theme.dart';
import '../../widgets/fkit.dart';
import '../auth/auth_state.dart';
import '../gym/box_wod_screen.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';
import '../home/home_screen.dart';
import '../announcements/announcements_state.dart';
import '../inbox/inbox_state.dart';
import '../mypage/mypage_screen.dart';

/// v1.27 (2026-07-28 사용자 지시): 3기둥 집중 — Home(게이미피케이션) · WOD(보드) ·
/// Profile 만 노출. Attend·Rehab 탭 숨김 (코드 보존 — 화면·라우트는 잔존, 셸에서만 제외).
/// 페이싱 계산 진입점도 전부 숨김 상태 유지 (box_wod _kShowPresetAccordion=false).
/// Default landing = WOD(index 1).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _defaultIndex = 1; // WOD as landing tab
  // v1.27 (2026-07-28): 3기둥 개편 → 힌트 버전 v6 로 bump (기존 사용자도 1회 재노출).
  static const String _kTabHintShown = 'shell_tab_hint_shown_v6';
  int _index = _defaultIndex;
  bool _showTabHint = false;
  // v1.21: 베타 피드백 — 더블탭 종료 패턴. 첫 탭 SnackBar, 2초 내 재탭 시 종료.
  DateTime? _lastBackPress;

  ShellNavBus? _navBus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kTabHintShown) == true) return;
      if (!mounted) return;
      setState(() => _showTabHint = true);
    });
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

  Future<void> _dismissHint() async {
    if (!_showTabHint) return;
    setState(() => _showTabHint = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTabHintShown, true);
  }

  // v1.27: 3탭 — Home(게이미피케이션) · WOD(보드) · Profile.
  static const List<_TabDef> _tabs = [
    _TabDef(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: '홈',
    ),
    _TabDef(
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt,
      label: 'WOD',
    ),
    _TabDef(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: '프로필',
    ),
  ];

  late final List<Widget> _pages = [
    const HomeScreen(),
    const BoxWodScreen(),
    const MyPageScreen(),
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
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!).inSeconds >= 2) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('한 번 더 누르면 앱이 종료됩니다.'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
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
        body: Stack(
          children: [
            IndexedStack(index: _index, children: _pages),
            if (_showTabHint) _TabHintOverlay(onDismiss: _dismissHint),
          ],
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: FacingTokens.bg,
            surfaceTintColor: Colors.transparent,
            indicatorColor: FacingTokens.accent.withValues(alpha: 0.18),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FacingTokens.r2),
            ),
            // v2.2: 켜진 탭을 브랜드색으로. 그전엔 아이콘·라벨이 둘 다 검정이라
            // 연분홍 인디케이터 면 하나로만 구분돼 어느 탭인지 흐렸다.
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return FacingTokens.micro.copyWith(
                color: selected ? FacingTokens.primary : FacingTokens.muted,
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
                  top: BorderSide(color: FacingTokens.border, width: 1),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _onTap,
                height: AppKit.tabbarH,
                labelBehavior:
                    NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  for (int i = 0; i < _tabs.length; i++)
                    NavigationDestination(
                      // v1.26: 쪽지 미읽음 dot 은 종(벨)이 담당, 탭 dot 은
                      // 새 공지(WOD 보드 상단 아코디언)만 표시.
                      icon: _IconWithDot(
                        icon: _tabs[i].icon,
                        showDot: i == 1 &&
                            context.watch<AnnouncementsState>().unreadCount >
                                0,
                        color: FacingTokens.muted,
                      ),
                      selectedIcon: _IconWithDot(
                        icon: _tabs[i].selectedIcon,
                        showDot: i == 1 &&
                            context.watch<AnnouncementsState>().unreadCount >
                                0,
                        color: FacingTokens.primary,
                      ),
                      label: _tabs[i].label,
                    ),
                ],
              ),
            ),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('아직 승인 전입니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthState>().signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(FacingTokens.sp6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '승인 대기중입니다',
                  style: FacingTokens.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: FacingTokens.sp3),
                const Text(
                  '가입 신청이 코치에게 전달됐습니다.\n'
                  '코치가 승인하면 오늘의 WOD·수업 예약이 열립니다.',
                  style: FacingTokens.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: FacingTokens.sp6),
                _checking
                    ? const FkLoading()
                    : FkButton.primary('승인됐는지 확인', onPressed: _recheck),
                const SizedBox(height: FacingTokens.sp3),
                TextButton(
                  onPressed: _signOut,
                  child: const Text('로그아웃'),
                ),
              ],
            ),
          ),
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
                color: FacingTokens.accent,
                shape: BoxShape.circle,
                border: Border.all(color: FacingTokens.bg, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// 첫 실행 1회 탭 힌트. v1.21: 5탭 재구성에 맞게 갱신.
class _TabHintOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  const _TabHintOverlay({required this.onDismiss});

  // v1.29: 카피 한글 기본 (DESIGN-SSOT §7).
  static const List<(String, String)> _hints = [
    ('홈', '레벨 · 업적 · 마일스톤'),
    ('WOD', '코치 오늘 WOD · 박스 공지'),
    ('프로필', 'Tier · 신체 · 설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: FacingTokens.bg.withValues(alpha: 0.88),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(FacingTokens.sp5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: FacingTokens.sp5),
                const Text('3탭', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp2),
                const Text('하단 내비게이션 구성',
                    style: FacingTokens.caption),
                const SizedBox(height: FacingTokens.sp5),
                ..._hints.map((h) => Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: FacingTokens.sp3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 72,
                            child: Text(h.$1,
                                style: FacingTokens.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: FacingTokens.accent,
                                )),
                          ),
                          Expanded(
                            child: Text(h.$2,
                                style: FacingTokens.body.copyWith(
                                  color: FacingTokens.fg,
                                )),
                          ),
                        ],
                      ),
                    )),
                const Spacer(),
                ElevatedButton(
                  onPressed: onDismiss,
                  child: const Text('확인'),
                ),
                const SizedBox(height: FacingTokens.sp3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
