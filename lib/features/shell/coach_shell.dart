import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../boss/boss_api_client.dart';
import '../boss/boss_auth_state.dart';
import '../boss/boss_dashboard_screen.dart';
import '../gym/gym_state.dart';
import '../inbox/inbox_screen.dart';
import '../inbox/inbox_state.dart';
import '../../core/role_labels.dart';
import '../../widgets/hkit.dart';

/// 코치 앱 셸 — **2탭** (v3.28 · 2026-08-25 사용자 결정, 브리프 D51):
///   ① 예약 현황 — 오늘 예약·출석 수치 · 가입 신청 · **주간** 수업/예약 (인원·명단)
///   ② 쪽지 — MessagingScreen 임베드
///
/// 구 '수업' 탭(회원 주간보드를 isOwner 분기로 재사용)은 폐지. 한 위젯 안에서
/// 회원판·코치판이 if 로 갈리는 것도 이원화다 — 정본은 부품(HkAppBar·HkTabBar·
/// ClassLine·명단 시트)이지 화면이 아니다. 회원 주간보드는 순수 회원 화면으로 복귀.
/// "코치는 대부분 PC. 폰 코치는 진짜 기본만." (3면 대전제 ③)
///
/// 쪽지 탭은 회원 API(X-Device-Id)를 쓴다 — 로그인이 기기를 페어링하므로
/// (gym_manager_devices) 백엔드 코치 기기 폴백이 데이터를 내려준다.
/// 로그인 직후 페어링이 반영되도록 진입 시 GymState.loadMine() 재조회.
///
/// v3.23: 상단바는 셸이 하나만 갖는다 (HkAppBar.identity). v3.25: 탭바는 HkTabBar.
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
    // (수업 탭 + '가입 신청' → MemberApprovalsScreen push 둘 다 이 값에 의존.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GymState>().loadMine();
    });
  }

  /// 셸 단일 상단바 — 세 탭 어디서나 같은 모양.
  /// 어느 탭인지는 하단 탭바가 알려주므로 제목은 체육관 신원 하나로 고정한다.
  /// 셸 단일 상단바 — 세 탭 어디서나 같은 모양 (회원 셸과 같은 HkAppBar.identity).
  /// 어느 탭인지는 하단 탭바가 알려주므로 제목은 체육관 신원 하나로 고정한다.
  PreferredSizeWidget _appBar(BuildContext context) {
    final auth = context.watch<BossAuthState>();
    return HkAppBar.identity(
      name: auth.gymName ?? '체육관',
      // 운영자 호칭은 '코치' 하나 (3면 대전제 ①, 번역은 roleKoLabel SSOT).
      role: roleKoLabel(role: auth.role ?? 'coach'),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: HyphenTokens.muted, size: 20),
          tooltip: '로그아웃',
          onPressed: _logout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _logout() async {
    Haptic.medium();
    final api = context.read<BossApiClient>();
    final auth = context.read<BossAuthState>();
    final navigator = Navigator.of(context);
    try {
      await api.post('/api/v1/admin/logout', {});
    } catch (_) {}
    await auth.clear();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil('/splash', (_) => false);
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
    }

    final pages = <Widget>[
      const BossDashboardScreen(embedded: true),
      const MessagingScreen(title: '쪽지', embedded: true),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      // v3.23 (2026-08-25 사용자 지시 "상단화면 통일하라고 1개로"): 탭마다
      // 제각각이던 상단바(예약 현황=체육관명+로그아웃 / 수업=제목+배지+종+
      // 새로고침+회원 / 쪽지=제목만)를 셸이 갖는 **하나**로 합쳤다.
      // 새로고침 버튼은 뺐다 — 예약 현황·수업 둘 다 당겨서 새로고침이 있다.
      appBar: _appBar(context),
      body: IndexedStack(index: _index, children: pages),
      // v3.25: 탭바는 HkTabBar 하나 — 회원 셸과 같은 물건.
      bottomNavigationBar: HkTabBar(
        selectedIndex: _index,
        onSelected: _onTap,
        destinations: _destinations,
      ),
    );
  }
}
