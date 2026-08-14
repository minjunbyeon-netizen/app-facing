import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/appkit.gen.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../announcements/announcements_state.dart';
import '../boss/boss_dashboard_screen.dart';
import '../gym/coach_dashboard_screen.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';
import '../inbox/inbox_screen.dart';
import '../inbox/inbox_state.dart';

/// v3.2 (2026-08-14 사용자 확정) — 코치 앱 셸. 딱 3탭:
///   ① 회원 현황 — 승인 대기·로스터·활동 통계 (CoachDashboardScreen 재사용)
///   ② 예약 조회 — 오늘 예약·출석·수업 명단 (BossDashboardScreen 임베드)
///   ③ 쪽지 — 핀 공지 + 회원 쪽지 스레드 (MessagingScreen 재사용)
/// v3.1 의 수업(BoxWodScreen)·내 정보(MyPageScreen) 탭은 삭제 — 수업 안내는
/// PC·회원 앱 몫이고, 로그아웃은 예약 조회 AppBar 에 이미 있다.
///
/// 회원 현황·쪽지는 회원 API(X-Device-Id)를 쓴다 — 로그인만 한 기기도
/// admin_login 이 GymManager.device_hash 를 페어링하므로 백엔드 코치 기기
/// 폴백(services/facing api/roles.py is_staff_device)이 체육관을 내려준다.
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
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups),
      label: '회원 현황',
    ),
    NavigationDestination(
      icon: Icon(Icons.event_note_outlined),
      selectedIcon: Icon(Icons.event_note),
      label: '예약 조회',
    ),
    NavigationDestination(
      icon: Icon(Icons.mail_outline),
      selectedIcon: Icon(Icons.mail),
      label: '쪽지',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 코치 로그인 직후 진입 — 앱 부팅 시점 loadMine 은 페어링 전이라
    // gym=null 일 수 있다. 여기서 한 번 더 읽어 코치 기기 폴백을 반영.
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

  /// 회원 현황 탭 — gym 확정 전에는 자리 화면. gymId 를 key 로 태워
  /// loadMine 완료(null → id 전환) 시 CoachDashboardScreen 이 재조회한다.
  Widget _membersTab(GymState gs) {
    final gymId = gs.membership.gym?.id;
    if (gymId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('회원 현황')),
        body: Center(
          child: gs.isLoading
              ? const CircularProgressIndicator(
                  color: HyphenTokens.muted, strokeWidth: 2)
              : const Text('체육관 정보를 불러오지 못했습니다.',
                  style: HyphenTokens.caption),
        ),
      );
    }
    return CoachDashboardScreen(key: ValueKey(gymId));
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    // 쪽지 탭 배선 — MainShell 과 같은 재시도 패턴 (gym 로드 완료 후 bind).
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
      _membersTab(gs),
      const BossDashboardScreen(),
      const MessagingScreen(),
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
