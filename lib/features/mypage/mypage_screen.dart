import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/goals_state.dart';
import '../../core/haptic.dart';
import '../../core/role_labels.dart';
import '../../core/titles_catalog.dart';
import '../../core/shell_nav_bus.dart';
import '../../core/theme.dart';
import '../../widgets/hkit.dart';
import '../../widgets/inbox_bell.dart';
import '../auth/auth_state.dart';
import '../contracts/member_contracts_screen.dart';
import '../goals/goals_screen.dart';
import 'strength_board_screen.dart';
import '../gym/gym_state.dart';
import 'edit_profile_screen.dart';
import 'faq_screen.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';
import '../../core/app_clock.dart';
import '../../core/time_format.dart';

/// v1.22: Profile = identity + 측정값 편집 진입 + 잘안쓰는 actions.
/// Engine score · Tier · Radar · Category Tier · Trend · Records · RoleModel 등
/// score 관련 컨텐츠는 모두 Home 으로 이동 (중복 제거).
///
/// v2.6 (2026-08-12 사용자 지시 "engine 은 우리가 쓸 데 없다"): ENGINE 섹션을
/// 이 화면에서 내렸다. 코드는 `score_section.dart` 에 보존 — 되돌리려면
/// 아래 children 에 `ScoreSection()` 한 줄을 되살리면 된다.
class MyPageScreen extends StatelessWidget {
  /// 회원 셸에 얹힐 때는 자기 AppBar 를 그리지 않는다 — 상단바는 셸 하나 (v3.24, D47).
  final bool embedded;

  const MyPageScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embedded
          ? null
          : const HkAppBar(title: '내 정보', actions: [InboxBellAction()]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp3),
          children: const [
            _IdentityCard(),
            _SectionDivider(),
            _MembershipSection(),
            _SectionDivider(),
            _MyBoxSection(),
            _SectionDivider(),
            // v3.1 (2026-08-19 사용자 지시): 신체(체중·키·나이) 아코디언 삭제 —
            // 입력 칸이 v2.3 에서 전부 빠져 영구 '-' 플레이스홀더였다.
            // v3.10 (2026-08-22 사용자 지시 "과한 거 없애라"): 설정 아코디언도
            // 삭제. 단위 토글을 뺀 뒤 남은 건 글자 크기 하나뿐이었고, 그것도
            // 필요 없다는 판단이다 — 아코디언 한 겹이 항목 하나를 감싸고 있었다.
            _ActionsSection(),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  // v2.5: 구분선 위아래 24 씩(총 48)이 섹션마다 붙어 화면의 절반이 여백이었다.
  // 아코디언 헤더가 이미 자기 여백을 갖고 있으므로 선만 남긴다 (사용자 지시).
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: HyphenTokens.sp1),
    child: Divider(height: 1, color: HyphenTokens.border),
  );
}

// v2.6 (2026-08-12): ENGINE 섹션(ScoreSection·WeaknessInline)은
// score_section.dart 로 옮겨 보존 — 이 화면에서는 더 이상 그리지 않는다.

// v1.23 Phase 3 (2026-06-02): 출석 캘린더(_AttendanceCompact·_StatBlock)는
// Attend 탭으로 이관됐다가, Attend 탭 자체가 v3.2(2026-08-20)에서 코드까지
// 삭제됨 (README §제거된 기능 대장).

class _IdentityCard extends StatelessWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final gs = context.watch<GymState>();
    // PC 사장이 등록한 GymMemberProfile.name 우선. 없으면 auth.displayName fallback.
    final mp = gs.membership.memberProfile;
    final boxRegisteredName = (mp?.name ?? '').trim();
    // v1.16.2 — 옛 통문자열 "박지훈 · FACING SEONGSU 코치" 가 SharedPreferences 에
    // 캐시돼 있을 수 있어 ' · ' 첫 부분만 잘라서 진짜 이름만 사용.
    String firstSegment(String s) {
      final i = s.indexOf(' · ');
      return i > 0 ? s.substring(0, i).trim() : s.trim();
    }

    final name = boxRegisteredName.isNotEmpty
        ? boxRegisteredName
        : ((auth.displayName?.trim().isNotEmpty == true)
              ? firstSegment(auth.displayName!)
              : 'Athlete');
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HyphenTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 아바타 — 현재는 첫 글자. 향후 사진 설정 시 Avatar 위젯으로 교체.
              // v2.5: 56 → 40 (사용자 지시 "50% 수준으로 컴팩트").
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HyphenTokens.accentSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: HyphenTokens.accent.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: HyphenTokens.h3.copyWith(color: HyphenTokens.accent),
                ),
              ),
              const SizedBox(width: HyphenTokens.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: HyphenTokens.h3),
                    // v3.12 (2026-08-23): 착용 칭호. 업적 화면에서 고른 것이
                    // 여기 이름 바로 아래 한 줄로 붙는다 — 고르는 자리는 있는데
                    // 드러나는 자리가 없어 아무도 못 보던 값이었다.
                    // 값은 GoalsState(서버 저장), 이름은 칭호 카탈로그가 정본.
                    Builder(
                      builder: (_) {
                        final code = context.watch<GoalsState>().wornTitle;
                        if (code.isEmpty) return const SizedBox.shrink();
                        final t = kPanelBTitles
                            .where((e) => e.code == code)
                            .firstOrNull;
                        // 카탈로그에서 사라진 code 를 착용 중일 수 있다
                        // (v3.12 해금 불가 32종 정리) — 그때는 조용히 숨긴다.
                        if (t == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: HkBadge(t.label, color: HyphenTokens.accent),
                        );
                      },
                    ),
                    // v1.16.2 — 박스명 · 역할 라벨 (GymState 데이터 소스)
                    Builder(
                      builder: (_) {
                        final gym = gs.membership.gym;
                        final roleLabel = roleKoLabel(
                          role: gs.membership.role,
                          status: gs.membership.status,
                        );
                        final gymLine = [
                          if (gym?.name != null && gym!.name.isNotEmpty)
                            gym.name,
                          if (roleLabel.isNotEmpty) roleLabel,
                        ].join(' · ');
                        if (gymLine.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(gymLine, style: HyphenTokens.caption),
                        );
                      },
                    ),
                    // 위치 (gyms.location) — 있을 때만 한 줄 더
                    Builder(
                      builder: (_) {
                        final loc = gs.membership.gym?.location ?? '';
                        if (loc.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(loc, style: HyphenTokens.caption),
                        );
                      },
                    ),
                    // v2.5: 로그인 수단(NAVER 등) 표기 삭제 — 회원이 이 화면에서
                    // 할 수 있는 일이 없는 정보다 (사용자 지시 "안 쓰는 건 안 보이게").
                  ],
                ),
              ),
              // 수정 진입은 이름 줄 오른쪽 아이콘으로 — 아래 전폭 버튼 한 줄을 없앤다.
              IconButton(
                tooltip: '프로필 수정',
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: HyphenTokens.fgSecondary,
                onPressed: () {
                  Haptic.light();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          // 코치가 남긴 메모가 실제로 있을 때만 카드를 낸다. (등록값만 있고
          // 메모가 없으면 제목만 남은 빈 카드가 돼 자리만 먹는다.)
          if (mp != null &&
              ((mp.safetyNote ?? '').isNotEmpty ||
                  (mp.note ?? '').isNotEmpty)) ...[
            const SizedBox(height: HyphenTokens.sp2),
            HkCard(
              padding: const EdgeInsets.all(HyphenTokens.sp3),
              radius: HyphenTokens.r2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HkSectionLabel('체육관 기록'),
                      const Spacer(),
                      if (mp.updatedAt != null)
                        Text(
                          mdHm(mp.updatedAt!.toLocal()),
                          style: HyphenTokens.micro,
                        ),
                    ],
                  ),
                  const SizedBox(height: HyphenTokens.sp2),
                  // v2.5 (사용자 지시): Tier·전화·생년월일·성별·선호 시간은
                  // 회원이 이미 아는 등록값을 되비추기만 할 뿐 앱이 쓰지 않는다.
                  // 코치가 회원에게 남긴 것(주의 사항·메모)만 남긴다.
                  if ((mp.safetyNote ?? '').isNotEmpty)
                    _ProfileRow(label: '주의 사항', value: mp.safetyNote!),
                  if ((mp.note ?? '').isNotEmpty)
                    _ProfileRow(label: '메모', value: mp.note!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: HyphenTokens.micro.copyWith(color: HyphenTokens.muted),
            ),
          ),
          Expanded(child: Text(value, style: HyphenTokens.caption)),
        ],
      ),
    );
  }
}

class _MyBoxSection extends StatelessWidget {
  const _MyBoxSection();

  // v2.6 (2026-08-13): '박스 변경' 진입점을 끊으면서 호출부가 사라졌다.
  // 탈퇴 자체를 없앤 결정은 아니므로 흐름은 그대로 둔다 ("숨김 = 코드 보존").
  // ignore: unused_element
  Future<void> _confirmLeave(BuildContext context, GymState gs) async {
    final gymName = gs.membership.gym?.name ?? '체육관';
    final ok = await HkDialog.confirm(
      context,
      title: '체육관을 탈퇴할까요?',
      message:
          '$gymName 에서 탈퇴합니다.\n'
          '다시 들어오려면 가입 신청을 넣고 코치 승인을 받아야 합니다.',
      confirmLabel: '탈퇴',
      danger: true,
    );
    if (!ok) return;
    if (!context.mounted) return;
    final success = await gs.leaveGym();
    if (!context.mounted) return;
    if (!success) {
      HkSnack.error(context, gs.error ?? 'Leave failed.');
      return;
    }
    // v2.6 (2026-08-13): 탈퇴 후 '박스 찾기'로 보내지 않는다 — 박스는 하나뿐이라
    // 찾을 목록이 없다. WOD 탭의 미가입 안내가 다음 길(가입 신청)을 알려준다.
    context.read<ShellNavBus>().requestTab(1);
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    final statusKo = switch (gs.membership.status) {
      'approved' => '승인됨',
      'pending' => '대기 중',
      'rejected' => '거절됨',
      _ => '-',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HyphenTokens.sp4),
      child: HkAccordion(
        title: '내 체육관',
        subtitle: gym == null ? '체육관 없음' : '${gym.name} · 회원 · $statusKo',
        children: [
          const SizedBox(height: HyphenTokens.sp2),
          if (gym == null)
            const Text('체육관 없음. 수업 탭에서 확인.', style: HyphenTokens.caption)
          else ...[
            Text(
              gym.name,
              style: HyphenTokens.body.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: HyphenTokens.sp1),
            Text(
              '회원 · $statusKo · ${gym.memberCount}명',
              style: HyphenTokens.caption,
            ),
            // P1-5 (2026-06-10): 거절 상태 무안내 해소 — 멤버십이 조용히
            // 사라지는 대신 사유 고지 + 다음 행동(다른 박스 검색) 제시.
            if (gs.membership.status == 'rejected') ...[
              const SizedBox(height: HyphenTokens.sp3),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(HyphenTokens.sp3),
                decoration: BoxDecoration(
                  color: HyphenTokens.accentSoft,
                  borderRadius: BorderRadius.circular(HyphenTokens.r2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '가입이 승인되지 않았습니다.',
                      style: HyphenTokens.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: HyphenTokens.sp1),
                    const Text(
                      '체육관에 직접 문의 또는 다른 체육관 검색.',
                      style: HyphenTokens.caption,
                    ),
                  ],
                ),
              ),
            ],
            // v3.28: 코치 분기('가입 신청' 버튼) 제거 — 내 정보는 회원만 본다.
            // v3.25: '수업' 버튼 삭제 — 예약은 수업 탭 주간보드 한 곳 (대장 19).
            // v2.6 (2026-08-13 사용자 지시): '박스 변경' 삭제. 1인 샵 전용이라
            // 옮겨 갈 다른 박스가 없다. 탈퇴가 필요하면 코치에게 말하는 쪽이 맞다.
            // (leaveGym·_confirmLeave 코드는 보존 — 진입점만 끊었다)
          ],
          const SizedBox(height: HyphenTokens.sp2),
        ],
      ),
    );
  }
}

// v3.1 (2026-08-19 사용자 지시): _BodyStats·_Kv(신체 아코디언) 삭제 —
// 체중·키·나이 입력 경로가 v2.3 온보딩·프로필 수정 개편에서 전부 빠져
// 값이 영구 '-' 인 죽은 표시부였다. 성별은 프로필 수정 화면이 담당.

class _ActionsSection extends StatelessWidget {
  const _ActionsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HyphenTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Consumer<AuthState>(
            builder: (ctx, auth, _) {
              if (!auth.isSignedIn) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: HyphenTokens.sp3),
                child: Row(
                  children: [
                    // v2.6: 앞에 붙던 로그인 수단이 실기에서 'MEMBER_ID' 라는
                    // 내부 코드값 그대로 나왔다. 회원이 이 화면에서 그걸로 할 수
                    // 있는 일이 없다 — 이름만 남긴다 (v2.5 에 IdentityCard 에서
                    // 같은 이유로 지운 표기가 여기 한 줄 남아 있었다).
                    Expanded(
                      child: Text(
                        auth.displayName ?? '',
                        style: HyphenTokens.caption,
                      ),
                    ),
                    // v2.2 (H18): 계정을 끊는 동작인데 옆 계정 표시와 같은
                    // 글자 덩어리라 눌리는지 보이지 않았다. 테두리를 줘서
                    // "동작"임을 알린다 (파괴적이진 않으므로 danger 는 아니다 —
                    // 확인 다이얼로그가 이미 붙어 있다).
                    HkButton.secondary(
                      '로그아웃',
                      expand: false,
                      onPressed: () => _confirmSignOut(context),
                    ),
                  ],
                ),
              );
            },
          ),
          // B-5 (2026-06-10) — 회원 포인트 잔액 (적립 토스트 "+NP" 와 신뢰 일치)
          const _PointsBalanceRow(),
          // v1.31 (2026-08-07) — 메뉴 10종이 세로로 주렁주렁 길다는 사용자 지시로
          // 단일 아코디언(기본 접힘) + 표(HkRowCard) 로 통합. 항목·진입 경로는
          // 그대로, 접힘 상태에서 헤더 한 줄만 차지한다.
          const SizedBox(height: HyphenTokens.sp2),
          HkAccordion(
            title: '메뉴',
            children: [
              const SizedBox(height: HyphenTokens.sp2),
              HkRowCard(
                rows: [
                  // B-6 (2026-06-10) — 회원 전자계약 목록·상세·서명 진입
                  HkListRow(
                    icon: Icons.assignment_outlined,
                    title: '계약',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MemberContractsScreen(),
                      ),
                    ),
                  ),
                  HkListRow(
                    icon: Icons.history,
                    title: '히스토리',
                    onTap: () => Navigator.of(context).pushNamed('/history'),
                  ),
                  HkListRow(
                    icon: Icons.flag_outlined,
                    title: '목표',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GoalsScreen()),
                    ),
                  ),
                  // Q3 (v3.4 2026-08-20 승인) — 리프트별 역대 최고 무게 (1RM 보드).
                  HkListRow(
                    icon: Icons.fitness_center,
                    title: '최고 기록',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StrengthBoardScreen(),
                      ),
                    ),
                  ),
                  // v2.6 (2026-08-13 사용자 지시) — 없는 기능 두 줄 삭제.
                  //  · '데이터 가져오기' = 화면 스스로 "가상 UI" 라고 적어둔 껍데기.
                  //    BTWB·Wodify '지원 예정' 만 늘어놓을 뿐 붙는 데가 없다.
                  //  · '알고리즘' = Engine 점수 6 카테고리·Tier 1~6(Scaled–Games)·
                  //    SPLIT/BURST 산식 설명. 앱에서 D34 로 전부 내린 기능이고,
                  //    회원 레벨은 경력 3단(SCALED/RXD/ELITE)이라 RX+·Games 는 없는 등급이다.
                  // 화면 파일은 v3.2(2026-08-20)에서 코드까지 삭제
                  // (README §제거된 기능 대장 — 복원은 git log).
                  // P2-1 (2026-06-11) — FAQ (시드 10문답, 실문의 누적 시 증보).
                  HkListRow(
                    icon: Icons.help_outline,
                    title: 'FAQ',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FaqScreen()),
                    ),
                  ),
                  // P0-3 (2026-06-10) — 고객센터 단일 채널 (카카오톡 채널 1:1 채팅).
                  HkListRow(
                    icon: Icons.chat_bubble_outline,
                    title: '고객지원',
                    subtitle: '카카오톡 · 평일 10–18시 답변',
                    onTap: () => launchUrl(
                      Uri.parse('http://pf.kakao.com/_kxbxanX/chat'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  // v2.6 (2026-08-12 사용자 지시): '직원 계정 연결' 행 삭제 — 코치가
                  // 곧 본인 한 명이라 연결할 직원이 없다 (BRIEF D37). 화면·라우트는
                  // v3.2(2026-08-20)에서 코드까지 삭제 (README §제거된 기능 대장).
                  HkListRow(
                    icon: Icons.lock_outline,
                    title: '개인정보처리방침',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                    ),
                  ),
                  // P0-1 (2026-06-10): 이용약관 진입 — 가입 화면 외 상시 접근 경로.
                  HkListRow(
                    icon: Icons.article_outlined,
                    title: '이용약관',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TermsScreen()),
                    ),
                  ),
                ],
              ),
              // v2.2 (H3): 되돌릴 수 없는 동작이 일반 메뉴와 같은 빨강 글자
              // 링크였다 — 링코 S17('서비스 탈퇴'가 일반 항목과 같은 비중)과
              // 같은 문제. 테두리 있는 danger 버튼으로 올려 "동작"임을 알리고,
              // 위 메뉴 카드와의 간격도 벌려 오조작을 줄인다.
              const SizedBox(height: HyphenTokens.sp5),
              Center(
                child: HkButton.secondary(
                  '데이터 초기화',
                  danger: true,
                  expand: false,
                  onPressed: () => _confirmReset(context),
                ),
              ),
            ],
          ),
          // v2.2 (2026-08-12 사용자 지시): DEBUG 블록 전면 삭제.
          // 빠른 전환 아바타 바 · Persona Switcher · 데모 진입은 화면을 어지럽히기만
          // 했다. kDebugMode 가드가 있어도 개발 중 매번 보이는 화면이라 제거한다.
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    // v3.2 (2026-08-20): 등급·벤치마크는 소멸한 항목 — 실동작은
    // prefs.clear() (이 기기 한정). 서버 기록은 남는다.
    final ok = await HkDialog.confirm(
      context,
      title: '데이터를 초기화할까요?',
      message:
          '이 기기에 저장된 프로필·목표·설정을 전부 삭제합니다.\n'
          '되돌릴 수 없습니다.',
      confirmLabel: '초기화',
      danger: true,
    );
    if (!ok) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (_) => false);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await HkDialog.confirm(
      context,
      title: '로그아웃',
      message:
          '로그아웃하면 이 기기와 회원 연결이 끊깁니다.\n'
          '같은 아이디로 다시 로그인하면 기록이 그대로 이어집니다.\n'
          '계정 삭제는 내 정보 → 개인정보처리방침 → 계정 삭제.',
      confirmLabel: '로그아웃',
    );
    if (!ok) return;
    if (!context.mounted) return;
    await context.read<AuthState>().signOut();
    if (!context.mounted) return;
    context.read<GymState>().resetLocal();
    Navigator.of(context).pushNamedAndRemoveUntil('/signup', (_) => false);
  }
}

class _MembershipSection extends StatelessWidget {
  const _MembershipSection();

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final ms = gs.currentMembership;
    final lk = gs.myLocker;
    if (ms == null && lk == null) return const SizedBox.shrink();

    final parts = <String>[];
    if (ms != null) {
      final days = ms.daysUntilExpiry;
      if (days == null) {
        parts.add('기간 정보 없음');
      } else if (days < 0) {
        parts.add('만료됨');
      } else {
        parts.add('$days일 남음');
      }
      if (ms.isPausedNow) parts.add('일시정지 중');
    }
    if (lk != null) parts.add('락커 ${lk.lockerNo}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HyphenTokens.sp4),
      child: HkAccordion(
        title: '회원권',
        subtitle: parts.join(' · '),
        children: const [
          SizedBox(height: HyphenTokens.sp2),
          _MembershipCard(),
          _LockerCard(),
          SizedBox(height: HyphenTokens.sp2),
        ],
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard();

  @override
  Widget build(BuildContext context) {
    final ms = context.watch<GymState>().currentMembership;
    if (ms == null) return const SizedBox.shrink();
    final days = ms.daysUntilExpiry;
    final progress = ms.progress ?? 0;
    final isExpiringSoon = days != null && days <= 14 && days >= 0;
    final isExpired = days != null && days < 0;
    Color accentColor;
    if (isExpired) {
      accentColor = HyphenTokens.danger;
    } else if (isExpiringSoon) {
      accentColor = HyphenTokens.warning;
    } else {
      accentColor = HyphenTokens.primary;
    }

    DateTime? start;
    DateTime? end;
    try {
      if (ms.startDate != null) start = DateTime.parse(ms.startDate!);
      if (ms.endDate != null) end = DateTime.parse(ms.endDate!);
    } catch (_) {}

    return Padding(
      // 가로 여백은 감싸는 _MembershipSection 아코디언이 준다.
      padding: EdgeInsets.zero,
      child: HkCard(
        padding: const EdgeInsets.all(HyphenTokens.sp4),
        radius: HyphenTokens.r2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ms.planName ?? 'Active',
                  style: HyphenTokens.h3.copyWith(color: HyphenTokens.fg),
                ),
                const Spacer(),
                if (days != null)
                  Text(
                    isExpired ? 'EXPIRED' : 'D-${days.abs()}',
                    style: HyphenTokens.h3.copyWith(color: accentColor),
                  ),
              ],
            ),
            // 일시정지 상태 (2026-08-24 갭 해소 — PC 만 알던 정지 창 표시).
            if (ms.isPausedNow || ms.isPauseScheduled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  HkBadge(
                    ms.isPausedNow ? '일시정지 중' : '일시정지 예정',
                    color: HyphenTokens.warning,
                  ),
                  const SizedBox(width: HyphenTokens.sp2),
                  Expanded(
                    child: Text(
                      '${ms.pauseStart ?? ''} ~ ${ms.pauseEnd ?? ''}',
                      style: HyphenTokens.caption,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // 진행 막대 — 사용 비율 = progress, 남은 비율 = 1-progress
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0, 1)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(height: 8, color: HyphenTokens.surfaceMax),
                      FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: HyphenTokens.mutedStrong,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% 사용',
                  style: HyphenTokens.caption,
                ),
                const Spacer(),
                Text(
                  '${((1 - progress) * 100).toStringAsFixed(0)}% 남음',
                  style: HyphenTokens.caption.copyWith(color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 월별 타임라인
            if (start != null && end != null)
              _MembershipTimeline(start: start, end: end, accent: accentColor),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(ms.startDate ?? '', style: HyphenTokens.caption),
                const Spacer(),
                Text(ms.endDate ?? '', style: HyphenTokens.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// v1.16.2 — 회원권 월별 타임라인.
/// start ~ end 범위를 6 ~ 12 칸 셀로 분할해서 가로 띠로 렌더.
/// 셀 색: 지난 구간 = mutedStrong / 미래 구간 = accent (primary).
/// today 위치에 ▲ 마커, 위쪽에 월 라벨.
class _MembershipTimeline extends StatelessWidget {
  const _MembershipTimeline({
    required this.start,
    required this.end,
    required this.accent,
  });
  final DateTime start;
  final DateTime end;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final totalDays = end.difference(start).inDays.clamp(1, 9999);
    final now = appClock.now();
    final today = DateTime(now.year, now.month, now.day);
    final elapsedDays = today
        .difference(start)
        .inDays
        .clamp(0, totalDays)
        .toInt();
    final todayFraction = elapsedDays / totalDays;

    // 월 단위 라벨 — 시작 월부터 끝 월까지.
    final monthLabels = <DateTime>[];
    DateTime cursor = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);
    while (!cursor.isAfter(endMonth)) {
      monthLabels.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final todayX = (width * todayFraction).clamp(0, width).toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 월 라벨 줄
            SizedBox(
              height: 14,
              child: Stack(
                clipBehavior: Clip.none,
                children: monthLabels.map((m) {
                  final monthFrac = m.difference(start).inDays / totalDays;
                  final clamped = monthFrac.clamp(0, 1).toDouble();
                  final x = (width * clamped).clamp(0, width - 22).toDouble();
                  return Positioned(
                    left: x,
                    top: 0,
                    child: Text(
                      '${m.month}월',
                      style: HyphenTokens.caption.copyWith(
                        color: m.month == now.month && m.year == now.year
                            ? accent
                            : HyphenTokens.muted,
                        fontWeight: m.month == now.month && m.year == now.year
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
            // 타임라인 바 (왼쪽=과거 mutedStrong / 오른쪽=미래 accent)
            SizedBox(
              height: 18,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 전체 배경
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: HyphenTokens.surfaceMax,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // 지난 구간
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: todayX,
                    child: Container(
                      decoration: BoxDecoration(
                        color: HyphenTokens.mutedStrong,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // 미래 구간 (남은 회원권)
                  Positioned(
                    left: todayX,
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // today 마커
                  Positioned(
                    left: todayX - 1,
                    top: -2,
                    bottom: -2,
                    width: 2,
                    child: Container(color: HyphenTokens.fg),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // 오늘 표식. clamp 상한이 라벨 실폭(약 30)이 아니라 24 로 잡혀 있어
            // 만료 직전(todayX 가 오른쪽 끝)이면 글자가 잘렸다 — v1.31 정정.
            SizedBox(
              height: 14,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: (todayX - 15)
                        .clamp(0, (width - 30).clamp(0, double.infinity))
                        .toDouble(),
                    top: 0,
                    child: Text(
                      '오늘',
                      style: HyphenTokens.caption.copyWith(
                        color: HyphenTokens.fg,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// v1.16.2 (2026-05-24) — 내 락커 카드.
/// GymState.myLocker 에서 fetch. 배정된 락커 없으면 안 그림.
class _LockerCard extends StatelessWidget {
  const _LockerCard();

  @override
  Widget build(BuildContext context) {
    final lk = context.watch<GymState>().myLocker;
    if (lk == null) return const SizedBox.shrink();
    final days = lk.daysUntilExpiry;
    return Padding(
      // 가로 여백은 감싸는 _MembershipSection 아코디언이 준다.
      padding: const EdgeInsets.only(top: HyphenTokens.sp3),
      child: HkCard(
        padding: const EdgeInsets.all(HyphenTokens.sp4),
        radius: HyphenTokens.r2,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HyphenTokens.surfaceMax,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                lk.lockerNo,
                style: HyphenTokens.h3.copyWith(color: HyphenTokens.fg),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HkSectionLabel('내 락커'),
                  const SizedBox(height: 4),
                  Text(
                    lk.endDate != null && lk.endDate!.isNotEmpty
                        ? '${lk.endDate} 까지'
                        : '회원권 만료일 자동',
                    style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  ),
                  if (lk.memo != null && lk.memo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(lk.memo!, style: HyphenTokens.caption),
                    ),
                ],
              ),
            ),
            if (days != null && days >= 0 && days <= 14)
              Text(
                'D-$days',
                style: HyphenTokens.h3.copyWith(color: HyphenTokens.warning),
              ),
          ],
        ),
      ),
    );
  }
}

/// B-5 (2026-06-10) — 회원 포인트 잔액 행.
/// 박스 소속(approved)이 아니면 백엔드가 gym:null 을 주므로 행 자체를 숨긴다.
class _PointsBalanceRow extends StatefulWidget {
  const _PointsBalanceRow();

  @override
  State<_PointsBalanceRow> createState() => _PointsBalanceRowState();
}

class _PointsBalanceRowState extends State<_PointsBalanceRow> {
  int? _balance;
  GymState? _gymState;

  @override
  void initState() {
    super.initState();
    _load();
    // 2026-08-24 — 적립·SSE 후에도 800P 고착되던 갱신 배선 (challenge_section
    // 결함 수정 6 과 동일 패턴: GymState notify 를 듣고 재조회).
    _gymState = context.read<GymState>();
    _gymState?.addListener(_load);
  }

  @override
  void dispose() {
    _gymState?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/v1/member/points');
      if (!mounted) return;
      final balance = (res['balance'] as num?)?.toInt();
      setState(() => _balance = balance);
    } catch (_) {
      // 미소속·네트워크 실패 → 행 미표시 (조용히 숨김)
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _balance;
    if (balance == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp3),
      child: HkCard(
        padding: const EdgeInsets.symmetric(
          horizontal: HyphenTokens.sp4,
          vertical: HyphenTokens.sp3,
        ),
        radius: HyphenTokens.r2,
        child: Row(
          children: [
            const Expanded(child: HkSectionLabel('포인트')),
            Text(
              '$balance P',
              style: HyphenTokens.h3.copyWith(color: HyphenTokens.primary),
            ),
          ],
        ),
      ),
    );
  }
}
