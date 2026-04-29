import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/haptic.dart';
import '../../core/shell_nav_bus.dart';
import '../../core/theme.dart';
import '../attendance/attendance_screen.dart';
import '../gym/box_wod_screen.dart';
import '../gym/gym_state.dart';
import '../home/home_screen.dart';
import '../inbox/inbox_screen.dart';
import '../inbox/inbox_state.dart';
import '../mypage/mypage_screen.dart';

/// v1.21: 5탭 재배치 — Home(default) · WOD · Inbox · Attend · Profile.
/// Trends 폐지, Calc → Home 격상 (점수 카드 + 카테고리 진입 통합).
/// dot 위치: Profile(4) → Inbox(2). Default index 2 → 0 (Home leftmost).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _defaultIndex = 0;
  static const String _kTabHintShown = 'shell_tab_hint_shown_v2';
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

  // v1.21: 5탭 — Home · WOD · Inbox · Attend · Profile.
  static const List<_TabDef> _tabs = [
    _TabDef(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    _TabDef(
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt,
      label: 'WOD',
    ),
    _TabDef(
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
      label: 'Notice',
    ),
    _TabDef(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Attend',
    ),
    _TabDef(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  /// v1.21 (BLOCKER fix): InboxScreen 은 isOwner 따라 TabController 길이 결정.
  /// IndexedStack 에 const InboxScreen() 으로 mount 하면 initState 시점 GymState
  /// 미로드 → _isCoach 영구 false 가능. Consumer + ValueKey 로 isOwner 변경 시 재생성.
  Widget _buildInbox() {
    return Consumer<GymState>(
      builder: (ctx, gs, _) => InboxScreen(
        key: ValueKey('inbox-${gs.isOwner}'),
      ),
    );
  }

  late final List<Widget> _pages = [
    const HomeScreen(),
    const BoxWodScreen(),
    _buildInbox(),
    const AttendanceScreen(),
    const MyPageScreen(),
  ];

  void _onTap(int i) {
    if (i == _index) return;
    Haptic.selection();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    // v1.21 (BLOCKER fix): GymState 로드 완료 후 InboxState bind 재시도.
    // initState 시점 gym=null 이라 bind 누락되는 케이스 보완.
    final gs = context.watch<GymState>();
    final inboxState = context.read<InboxState>();
    final currentGymId = gs.membership.gym?.id;
    if (currentGymId != null && inboxState.boundGymId != currentGymId) {
      Future.microtask(() => inboxState.bind(currentGymId));
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
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return FacingTokens.micro.copyWith(
                color: selected ? FacingTokens.fg : FacingTokens.muted,
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
                height: 64,
                labelBehavior:
                    NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  for (int i = 0; i < _tabs.length; i++)
                    NavigationDestination(
                      icon: _IconWithDot(
                        icon: _tabs[i].icon,
                        // v1.21: dot 위치 Profile(4) → Inbox(2).
                        showDot: i == 2 &&
                            context.watch<InboxState>().unreadCount > 0,
                        color: FacingTokens.muted,
                      ),
                      selectedIcon: _IconWithDot(
                        icon: _tabs[i].selectedIcon,
                        showDot: i == 2 &&
                            context.watch<InboxState>().unreadCount > 0,
                        color: FacingTokens.fg,
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

  static const List<(String, String)> _hints = [
    ('Home', 'Tier · Engine Score · WOD 카테고리'),
    ('WOD', '내 박스 코치의 오늘 WOD'),
    ('Inbox', '코치 쪽지 · 박스 공지'),
    ('Attend', '출석 · 레벨 · 해금 · 업적'),
    ('Profile', '바디 · 설정 · 데이터'),
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
                const Text('5 TABS', style: FacingTokens.sectionLabel),
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
                                  fontWeight: FontWeight.w800,
                                  color: FacingTokens.accent,
                                  letterSpacing: 0.4,
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
