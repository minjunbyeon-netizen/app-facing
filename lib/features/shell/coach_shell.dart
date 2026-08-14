import 'package:flutter/material.dart';

import '../../core/appkit.gen.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../boss/boss_dashboard_screen.dart';
import '../gym/box_wod_screen.dart';
import '../mypage/mypage_screen.dart';

/// v3.1 (2026-08-14 사용자 설계) — 코치 앱 셸.
///
/// 코치는 PC(디테일)와 앱(간단) 둘 다 쓴다 (3면 대전제 ③). 앱 쪽은 딱 3탭:
///   ① 예약 — 오늘 예약·출석·수업 명단 (BossDashboardScreen 임베드)
///   ② 수업 — 회원과 동일한 수업 안내 보드 (BoxWodScreen)
///   ③ 내 정보 — 회원과 동일 (MyPageScreen, 거의 안 쓸 것 — 사용자가 "없어도
///      된다" 했으나 로그아웃·계정 동선이 여기 있어 유지)
/// 상세 운영(회원·계약·설정 디테일)은 전부 PC 관리자 웹이 정본이다.
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
      label: '예약',
    ),
    NavigationDestination(
      icon: Icon(Icons.list_alt_outlined),
      selectedIcon: Icon(Icons.list_alt),
      label: '수업',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: '내 정보',
    ),
  ];

  late final List<Widget> _pages = [
    const BossDashboardScreen(),
    const BoxWodScreen(),
    const MyPageScreen(),
  ];

  void _onTap(int i) {
    if (i == _index) return;
    Haptic.selection();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _index, children: _pages),
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
