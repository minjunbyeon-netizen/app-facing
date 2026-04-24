import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/haptic.dart';
import '../../core/shell_nav_bus.dart';
import '../../core/theme.dart';
import '../attendance/attendance_screen.dart';
import '../gym/box_wod_screen.dart';
import '../mypage/mypage_screen.dart';
import '../trends/trends_screen.dart';
import '../wod_builder/calc_entry_screen.dart';

/// v1.15.3: 5탭 하단 내비 Shell.
/// 순서(좌→우): WOD계산기 · 와드확인 · 변화추이(center·default) · 출석률 · 마이프로필.
/// Android 시스템 뒤로가기 처리: center 아닌 탭에서 back → center(2)로 복귀.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _centerIndex = 2;
  static const String _kTabHintShown = 'shell_tab_hint_shown_v1';
  int _index = _centerIndex;
  bool _showTabHint = false;

  ShellNavBus? _navBus;

  @override
  void initState() {
    super.initState();
    // v1.16 Sprint 7b U1: 첫 실행 시 1회 탭 힌트 오버레이.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kTabHintShown) == true) return;
      if (!mounted) return;
      setState(() => _showTabHint = true);
    });
    // v1.16 Sprint 11: 딥링크 탭 전환 요청 리스닝.
    _navBus = context.read<ShellNavBus>();
    _navBus?.addListener(_onNavRequest);
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

  // v1.15.3: 탭 라벨 영문화 (HWPO/NOBULL 톤 정합).
  static const List<_TabDef> _tabs = [
    _TabDef(
      icon: Icons.calculate_outlined,
      selectedIcon: Icons.calculate,
      label: 'Calc',
    ),
    _TabDef(
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt,
      label: 'WOD',
    ),
    _TabDef(
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
      label: 'Trends',
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

  static const List<Widget> _pages = [
    CalcEntryScreen(),
    BoxWodScreen(),
    TrendsScreen(),
    AttendanceScreen(),
    MyPageScreen(),
  ];

  void _onTap(int i) {
    if (i == _index) return;
    Haptic.selection();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    // canPop=false 고정 — 모든 back을 intercept 후 직접 처리.
    // 비-중앙 탭: 중앙으로 복귀. 중앙 탭: SystemNavigator.pop()으로 앱 종료.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_index != _centerIndex) {
          setState(() => _index = _centerIndex);
        } else {
          SystemNavigator.pop();
        }
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
                destinations: _tabs
                    .map((t) => NavigationDestination(
                          icon: Icon(t.icon,
                              size: 22, color: FacingTokens.muted),
                          selectedIcon: Icon(t.selectedIcon,
                              size: 22, color: FacingTokens.fg),
                          label: t.label,
                        ))
                    .toList(),
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

/// v1.16 Sprint 7b U1: 첫 실행 탭 힌트 풀스크린 오버레이.
/// 5탭 한 줄 설명 + '확인' 버튼. 이후 SharedPreferences 플래그로 숨김.
class _TabHintOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  const _TabHintOverlay({required this.onDismiss});

  static const List<(String, String)> _hints = [
    ('Calc', 'WOD 골라 Split · Burst 계산'),
    ('WOD', '내 박스 코치의 오늘 WOD'),
    ('Trends', '업적 배지 15개 갤러리'),
    ('Attend', '출석 streak · 마일스톤'),
    ('Profile', '내 Tier · 기록 · 설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.88),
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
