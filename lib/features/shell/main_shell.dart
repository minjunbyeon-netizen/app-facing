import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/haptic.dart';
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
  int _index = _centerIndex;

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
        body: IndexedStack(index: _index, children: _pages),
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
