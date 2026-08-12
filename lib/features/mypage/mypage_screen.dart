import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/app_mode.dart';
import '../../core/haptic.dart';
import '../../core/role_labels.dart';
import '../../core/shell_nav_bus.dart';
import '../../core/theme.dart';
import '../../core/ui_prefs_state.dart';
import '../../core/unit_state.dart';
import '../../widgets/fkit.dart';
import '../../widgets/inbox_bell.dart';
import '../auth/auth_state.dart';
import '../contracts/member_contracts_screen.dart';
import '../goals/goals_screen.dart';
import '../gym/coach_dashboard_screen.dart';
import '../gym/gym_search_screen.dart';
import '../gym/gym_state.dart';
import '../profile/profile_state.dart';
import 'algorithm_screen.dart';
import 'edit_profile_screen.dart';
import 'import_screen.dart';
import 'faq_screen.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';

/// v1.22: Profile = identity + 측정값 편집 진입 + 잘안쓰는 actions.
/// Engine score · Tier · Radar · Category Tier · Trend · Records · RoleModel 등
/// score 관련 컨텐츠는 모두 Home 으로 이동 (중복 제거).
///
/// v2.6 (2026-08-12 사용자 지시 "engine 은 우리가 쓸 데 없다"): ENGINE 섹션을
/// 이 화면에서 내렸다. 코드는 `score_section.dart` 에 보존 — 되돌리려면
/// 아래 children 에 `ScoreSection()` 한 줄을 되살리면 된다.
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: const [InboxBellAction()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
          children: const [
            _IdentityCard(),
            _SectionDivider(),
            _MembershipSection(),
            _SectionDivider(),
            _MyBoxSection(),
            _SectionDivider(),
            _BodyStats(),
            _SectionDivider(),
            _SettingsSection(),
            _SectionDivider(),
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
        padding: EdgeInsets.symmetric(vertical: FacingTokens.sp1),
        child: Divider(height: 1, color: FacingTokens.border),
      );
}

// v2.6 (2026-08-12): ENGINE 섹션(ScoreSection·WeaknessInline)은
// score_section.dart 로 옮겨 보존 — 이 화면에서는 더 이상 그리지 않는다.

// v1.23 Phase 3 (2026-06-02): 출석 캘린더(_AttendanceCompact·_StatBlock)는
// Attend 탭으로 이관됨 (attendance_screen.dart _AttendanceCalendar).

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
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
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
                  color: FacingTokens.accentSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FacingTokens.accent.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: FacingTokens.h3.copyWith(
                    color: FacingTokens.accent,
                  ),
                ),
              ),
              const SizedBox(width: FacingTokens.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: FacingTokens.h3),
                    // v1.16.2 — 박스명 · 역할 라벨 (GymState 데이터 소스)
                    Builder(builder: (_) {
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
                        child: Text(
                          gymLine,
                          style: FacingTokens.caption,
                        ),
                      );
                    }),
                    // 위치 (gyms.location) — 있을 때만 한 줄 더
                    Builder(builder: (_) {
                      final loc = gs.membership.gym?.location ?? '';
                      if (loc.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(loc, style: FacingTokens.caption),
                      );
                    }),
                    // v2.5: 로그인 수단(NAVER 등) 표기 삭제 — 회원이 이 화면에서
                    // 할 수 있는 일이 없는 정보다 (사용자 지시 "안 쓰는 건 안 보이게").
                  ],
                ),
              ),
              // 수정 진입은 이름 줄 오른쪽 아이콘으로 — 아래 전폭 버튼 한 줄을 없앤다.
              IconButton(
                tooltip: '프로필 수정',
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: FacingTokens.fgSecondary,
                onPressed: () {
                  Haptic.light();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  ));
                },
              ),
            ],
          ),
          // 코치가 남긴 메모가 실제로 있을 때만 카드를 낸다. (등록값만 있고
          // 메모가 없으면 제목만 남은 빈 카드가 돼 자리만 먹는다.)
          if (mp != null &&
              ((mp.safetyNote ?? '').isNotEmpty ||
                  (mp.note ?? '').isNotEmpty)) ...[
            const SizedBox(height: FacingTokens.sp2),
            Container(
              padding: const EdgeInsets.all(FacingTokens.sp3),
              decoration: BoxDecoration(
                color: FacingTokens.surface,
                border: Border.all(color: FacingTokens.border),
                borderRadius: BorderRadius.circular(FacingTokens.r2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('박스 기록',
                          style: FacingTokens.sectionLabel),
                      const Spacer(),
                      if (mp.updatedAt != null)
                        Text(
                          _fmtUpdated(mp.updatedAt!),
                          style: FacingTokens.micro,
                        ),
                    ],
                  ),
                  const SizedBox(height: FacingTokens.sp2),
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

  String _fmtUpdated(DateTime dt) {
    final l = dt.toLocal();
    return '${l.month}/${l.day} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
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
            child: Text(label,
                style: FacingTokens.micro
                    .copyWith(color: FacingTokens.muted)),
          ),
          Expanded(
            child: Text(value, style: FacingTokens.caption),
          ),
        ],
      ),
    );
  }
}

class _MyBoxSection extends StatelessWidget {
  const _MyBoxSection();

  Future<void> _confirmLeave(BuildContext context, GymState gs) async {
    final gymName = gs.membership.gym?.name ?? '박스';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r5),
        ),
        title: const Text('박스를 탈퇴할까요?'),
        content: Text(
          '$gymName 에서 탈퇴합니다.\n'
          '탈퇴 후 다른 박스에 가입하거나 새로 만들 수 있습니다.',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.accent),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final success = await gs.leaveGym();
    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gs.error ?? 'Leave failed.'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    // 탈퇴 성공 → WOD 탭(index 1)으로 이동해 박스 찾기 유도.
    context.read<ShellNavBus>().requestTab(1);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const GymSearchScreen(),
    ));
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
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: FkAccordion(
        title: '내 박스',
        subtitle: gym == null
            ? '박스 없음'
            : '${gym.name} · ${gs.isOwner ? '코치' : '회원'} · $statusKo',
        children: [
          const SizedBox(height: FacingTokens.sp2),
          if (gym == null)
            const Text('박스 없음. WOD 탭에서 찾기.',
                style: FacingTokens.caption)
          else ...[
            Text(gym.name,
                style:
                    FacingTokens.body.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: FacingTokens.sp1),
            Text(
              '${gs.isOwner ? '코치' : '회원'} · $statusKo · ${gym.memberCount}명',
              style: FacingTokens.caption,
            ),
            // P1-5 (2026-06-10): 거절 상태 무안내 해소 — 멤버십이 조용히
            // 사라지는 대신 사유 고지 + 다음 행동(다른 박스 검색) 제시.
            if (gs.membership.status == 'rejected') ...[
              const SizedBox(height: FacingTokens.sp3),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(FacingTokens.sp3),
                decoration: BoxDecoration(
                  color: FacingTokens.accentSoft,
                  borderRadius: BorderRadius.circular(FacingTokens.r2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('가입이 승인되지 않았습니다.',
                        style: FacingTokens.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: FacingTokens.sp1),
                    const Text('박스에 직접 문의 또는 다른 박스 검색.',
                        style: FacingTokens.caption),
                  ],
                ),
              ),
            ],
            if (gs.isOwner) ...[
              const SizedBox(height: FacingTokens.sp3),
              OutlinedButton(
                onPressed: () {
                  Haptic.light();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CoachDashboardScreen(),
                  ));
                },
                child: const Text('회원 관리'),
              ),
            ],
            // 클래스 일정 진입 (회원·owner 모두). PC 사장이 등록한 클래스를 본다.
            if (gs.membership.isApprovedMember || gs.isOwner) ...[
              const SizedBox(height: FacingTokens.sp2),
              OutlinedButton.icon(
                onPressed: () {
                  Haptic.light();
                  Navigator.of(context).pushNamed('/classes');
                },
                icon: const Icon(Icons.event_outlined, size: 18),
                label: const Text('수업'),
              ),
            ],
            // 박스 변경(= 탈퇴 후 재검색). 구 헤더 우측 '변경' 버튼을 본문 하단으로
            // 옮겼다 — 아코디언 헤더는 제목·부제만 싣는다 (DESIGN-SSOT §7-B).
            if (!gs.isOwner) ...[
              const SizedBox(height: FacingTokens.sp2),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: FacingTokens.fgSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: FacingTokens.sp2),
                  textStyle: FacingTokens.micro,
                ),
                onPressed: () {
                  Haptic.light();
                  _confirmLeave(context, gs);
                },
                child: const Text('박스 변경'),
              ),
            ],
          ],
          const SizedBox(height: FacingTokens.sp2),
        ],
      ),
    );
  }
}

class _BodyStats extends StatelessWidget {
  const _BodyStats();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final unit = context.watch<UnitState>();
    final weightDisplay = p.bodyWeightKg == null
        ? '-'
        : '${_fmt(unit.kgToDisplay(p.bodyWeightKg!)!)} ${unit.weightSuffix}';
    final height = p.heightCm == null ? '-' : '${_fmt(p.heightCm!)} cm';
    final age = p.ageYears == null ? '-' : '${_fmt(p.ageYears!)} yr';
    final sex = p.gender == 'female' ? 'Female' : 'Male';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: FkAccordion(
        title: '신체',
        subtitle: '체중 $weightDisplay · 키 $height · $age',
        children: [
          const SizedBox(height: FacingTokens.sp2),
          _Kv(label: '체중', value: weightDisplay),
          _Kv(label: '키', value: height),
          _Kv(label: '나이', value: age),
          _Kv(label: '성별', value: sex),
          const SizedBox(height: FacingTokens.sp2),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _Kv extends StatelessWidget {
  final String label;
  final String value;
  const _Kv({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: FacingTokens.caption)),
          Expanded(
            flex: 5,
            child: Text(value,
                style:
                    FacingTokens.body.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      // v2.5 (사용자 지시): 부제 삭제 — 헤더가 두 줄이면 '설정' 한 줄 버튼이
      // 아니게 된다. 안에 뭐가 있는지는 눌러서 확인한다.
      child: FkAccordion(
        title: '설정',
        children: [
          const SizedBox(height: FacingTokens.sp1),
          const _ModeRow(),
          const SizedBox(height: FacingTokens.sp2),
          Row(
            children: [
              const Expanded(child: Text('단위', style: FacingTokens.body)),
              Consumer<UnitState>(
                builder: (ctx, u, _) => _UnitToggle(u: u),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp2),
          Consumer<UiPrefsState>(
            builder: (ctx, ui, _) => Row(
              children: [
                const Expanded(
                    child: Text('글자 크기', style: FacingTokens.body)),
                _TextScaleToggle(current: ui.textScale, state: ui),
              ],
            ),
          ),
          const SizedBox(height: FacingTokens.sp2),
        ],
      ),
    );
  }
}

class _TextScaleToggle extends StatelessWidget {
  final double current;
  final UiPrefsState state;
  const _TextScaleToggle({required this.current, required this.state});

  @override
  Widget build(BuildContext context) {
    const options = [(1.0, 'A'), (1.15, 'A+'), (1.30, 'A++')];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((o) {
        final selected = (current - o.$1).abs() < 0.01;
        return Padding(
          padding: const EdgeInsets.only(left: FacingTokens.sp1),
          child: FkBadge(
            o.$2,
            color: FacingTokens.fg,
            selected: selected,
            onTap: () {
              Haptic.light();
              state.setTextScale(o.$1);
            },
          ),
        );
      }).toList(),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final UnitState u;
  const _UnitToggle({required this.u});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FkBadge('kg',
            color: FacingTokens.fg,
            selected: u.isKg,
            onTap: () {
              if (!u.isKg) u.toggle();
            }),
        const SizedBox(width: FacingTokens.sp2),
        FkBadge('lb',
            color: FacingTokens.fg,
            selected: !u.isKg,
            onTap: () {
              if (u.isKg) u.toggle();
            }),
      ],
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Consumer<AuthState>(
            builder: (ctx, auth, _) {
              if (!auth.isSignedIn) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: FacingTokens.sp3),
                child: Row(
                  children: [
                    // v2.6: 앞에 붙던 로그인 수단이 실기에서 'MEMBER_ID' 라는
                    // 내부 코드값 그대로 나왔다. 회원이 이 화면에서 그걸로 할 수
                    // 있는 일이 없다 — 이름만 남긴다 (v2.5 에 IdentityCard 에서
                    // 같은 이유로 지운 표기가 여기 한 줄 남아 있었다).
                    Expanded(
                      child: Text(
                        auth.displayName ?? '',
                        style: FacingTokens.caption,
                      ),
                    ),
                    // v2.2 (H18): 계정을 끊는 동작인데 옆 계정 표시와 같은
                    // 글자 덩어리라 눌리는지 보이지 않았다. 테두리를 줘서
                    // "동작"임을 알린다 (파괴적이진 않으므로 danger 는 아니다 —
                    // 확인 다이얼로그가 이미 붙어 있다).
                    FkButton.secondary(
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
          // 단일 아코디언(기본 접힘) + 표(FkRowCard) 로 통합. 항목·진입 경로는
          // 그대로, 접힘 상태에서 헤더 한 줄만 차지한다.
          const SizedBox(height: FacingTokens.sp2),
          FkAccordion(
            title: '메뉴',
            children: [
              const SizedBox(height: FacingTokens.sp2),
              FkRowCard(rows: [
                // B-6 (2026-06-10) — 회원 전자계약 목록·상세·서명 진입
                FkListRow(
                  icon: Icons.assignment_outlined,
                  title: '계약',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const MemberContractsScreen(),
                  )),
                ),
                FkListRow(
                  icon: Icons.history,
                  title: '히스토리',
                  onTap: () => Navigator.of(context).pushNamed('/history'),
                ),
                FkListRow(
                  icon: Icons.flag_outlined,
                  title: '목표',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const GoalsScreen(),
                  )),
                ),
                FkListRow(
                  icon: Icons.download_outlined,
                  title: '데이터 가져오기',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ImportScreen(),
                  )),
                ),
                FkListRow(
                  icon: Icons.calculate_outlined,
                  title: '알고리즘',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AlgorithmScreen(),
                  )),
                ),
                // P2-1 (2026-06-11) — FAQ (시드 10문답, 실문의 누적 시 증보).
                FkListRow(
                  icon: Icons.help_outline,
                  title: 'FAQ',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const FaqScreen(),
                  )),
                ),
                // P0-3 (2026-06-10) — 고객센터 단일 채널 (카카오톡 채널 1:1 채팅).
                FkListRow(
                  icon: Icons.chat_bubble_outline,
                  title: '고객지원',
                  subtitle: '카카오톡 · 평일 10–18시 답변',
                  onTap: () => launchUrl(
                    Uri.parse('http://pf.kakao.com/_kxbxanX/chat'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                // v2.6 (2026-08-12 사용자 지시): '직원 계정 연결' 행 삭제.
                // 코치가 곧 사장 본인 한 명이라 연결할 직원이 없다. 직원 고용은
                // 나중 일 — 화면·라우트(`/auth/link-staff`)는 그대로 살아 있어
                // 이 6줄만 되살리면 복귀한다 ("숨김 = 코드 보존", BRIEF D37).
                FkListRow(
                  icon: Icons.lock_outline,
                  title: '개인정보처리방침',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PrivacyScreen(),
                  )),
                ),
                // P0-1 (2026-06-10): 이용약관 진입 — 가입 화면 외 상시 접근 경로.
                FkListRow(
                  icon: Icons.article_outlined,
                  title: '이용약관',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const TermsScreen(),
                  )),
                ),
              ]),
              // v2.2 (H3): 되돌릴 수 없는 동작이 일반 메뉴와 같은 빨강 글자
              // 링크였다 — 링코 S17('서비스 탈퇴'가 일반 항목과 같은 비중)과
              // 같은 문제. 테두리 있는 danger 버튼으로 올려 "동작"임을 알리고,
              // 위 메뉴 카드와의 간격도 벌려 오조작을 줄인다.
              const SizedBox(height: FacingTokens.sp5),
              Center(
                child: FkButton.secondary(
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r5),
        ),
        title: const Text('데이터를 초기화할까요?'),
        content: const Text(
          '프로필·등급·벤치마크를 전부 삭제합니다.\n'
          '되돌릴 수 없습니다.',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.accent),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (_) => false);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r5),
        ),
        title: const Text('로그아웃'),
        content: const Text(
          // V9: 영문 명사 + 한글 조사 혼용("provider로") 제거.
          '로그아웃해도 프로필·기록은 이 기기에 그대로 유지됩니다.\n'
          '같은 계정으로 다시 로그인하면 모든 데이터가 복구됩니다.\n'
          '계정 삭제는 Privacy Policy → Delete Account.',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.fgSecondary),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await context.read<AuthState>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/signup', (_) => false);
  }
}

class _ModeRow extends StatefulWidget {
  const _ModeRow();

  @override
  State<_ModeRow> createState() => _ModeRowState();
}

class _ModeRowState extends State<_ModeRow> {
  AppMode? _mode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await AppModeStore.get();
    if (!mounted) return;
    setState(() => _mode = m);
  }

  Future<void> _setMode(AppMode m) async {
    if (_mode == m || _saving) return;
    Haptic.medium();
    setState(() => _saving = true);
    await AppModeStore.set(m);
    if (!mounted) return;
    setState(() {
      _mode = m;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mode → ${_label(m)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _label(AppMode m) => switch (m) {
        AppMode.coach => 'Coach',
        AppMode.member => 'Member',
        AppMode.solo => 'Solo',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('모드', style: FacingTokens.body),
            const SizedBox(width: FacingTokens.sp2),
            if (_saving)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: FacingTokens.muted,
                ),
              ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp2),
        Semantics(
          explicitChildNodes: true,
          container: true,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: FacingTokens.sp2,
            children: [
              for (final m in AppMode.values)
                FkBadge(
                  _label(m),
                  color: FacingTokens.fg,
                  selected: _mode == m,
                  onTap: _saving ? null : () => _setMode(m),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// v1.16.2 (2026-05-24) — 내 회원권 카드 (진행 막대 + 월별 타임라인).
/// GymState.currentMembership 에서 fetch. 회원권 없으면 안 그림.
/// 갱신 시 늘어난 구간은 primary 색, 이미 지난 구간은 muted 색으로 분리.
/// v1.31 — 회원권 + 락커를 아코디언 1개로 묶는다. 만료 임박처럼 놓치면 안 되는
/// 값은 접힌 상태에서도 보이도록 헤더 부제에 싣는다 (DESIGN-SSOT §7-B).
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
    }
    if (lk != null) parts.add('락커 ${lk.lockerNo}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: FkAccordion(
        title: '회원권',
        subtitle: parts.join(' · '),
        children: const [
          SizedBox(height: FacingTokens.sp2),
          _MembershipCard(),
          _LockerCard(),
          SizedBox(height: FacingTokens.sp2),
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
      accentColor = FacingTokens.danger;
    } else if (isExpiringSoon) {
      accentColor = FacingTokens.warning;
    } else {
      accentColor = FacingTokens.primary;
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
      child: Container(
        padding: const EdgeInsets.all(FacingTokens.sp4),
        decoration: BoxDecoration(
          color: FacingTokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FacingTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ms.planName ?? 'Active',
                  style: FacingTokens.h3.copyWith(color: FacingTokens.fg),
                ),
                const Spacer(),
                if (days != null)
                  Text(
                    isExpired ? 'EXPIRED' : 'D-${days.abs()}',
                    style:
                        FacingTokens.h3.copyWith(color: accentColor),
                  ),
              ],
            ),
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
                      Container(height: 8, color: FacingTokens.surfaceMax),
                      FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: FacingTokens.mutedStrong,
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
                  style: FacingTokens.caption,
                ),
                const Spacer(),
                Text(
                  '${((1 - progress) * 100).toStringAsFixed(0)}% 남음',
                  style: FacingTokens.caption
                      .copyWith(color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 월별 타임라인
            if (start != null && end != null)
              _MembershipTimeline(
                start: start,
                end: end,
                accent: accentColor,
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(ms.startDate ?? '', style: FacingTokens.caption),
                const Spacer(),
                Text(ms.endDate ?? '', style: FacingTokens.caption),
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final elapsedDays =
        today.difference(start).inDays.clamp(0, totalDays).toInt();
    final todayFraction = elapsedDays / totalDays;

    // 월 단위 라벨 — 시작 월부터 끝 월까지.
    final monthLabels = <DateTime>[];
    DateTime cursor = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);
    while (!cursor.isAfter(endMonth)) {
      monthLabels.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return LayoutBuilder(builder: (context, constraints) {
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
                final monthFrac =
                    m.difference(start).inDays / totalDays;
                final clamped = monthFrac.clamp(0, 1).toDouble();
                final x = (width * clamped).clamp(0, width - 22).toDouble();
                return Positioned(
                  left: x,
                  top: 0,
                  child: Text(
                    '${m.month}월',
                    style: FacingTokens.caption.copyWith(
                      color: m.month == now.month && m.year == now.year
                          ? accent
                          : FacingTokens.muted,
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
                      color: FacingTokens.surfaceMax,
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
                      color: FacingTokens.mutedStrong,
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
                  child: Container(color: FacingTokens.fg),
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
                    style: FacingTokens.caption.copyWith(
                      color: FacingTokens.fg,
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
    });
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
      padding: const EdgeInsets.only(top: FacingTokens.sp3),
      child: Container(
        padding: const EdgeInsets.all(FacingTokens.sp4),
        decoration: BoxDecoration(
          color: FacingTokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FacingTokens.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FacingTokens.surfaceMax,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(lk.lockerNo,
                  style:
                      FacingTokens.h3.copyWith(color: FacingTokens.fg)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('내 락커', style: FacingTokens.sectionLabel),
                  const SizedBox(height: 4),
                  Text(
                    lk.endDate != null && lk.endDate!.isNotEmpty
                        ? '${lk.endDate} 까지'
                        : '회원권 만료일 자동',
                    style: FacingTokens.body
                        .copyWith(color: FacingTokens.fg),
                  ),
                  if (lk.memo != null && lk.memo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(lk.memo!,
                          style: FacingTokens.caption),
                    ),
                ],
              ),
            ),
            if (days != null && days >= 0 && days <= 14)
              Text('D-$days',
                  style: FacingTokens.h3
                      .copyWith(color: FacingTokens.warning)),
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
      padding: const EdgeInsets.only(bottom: FacingTokens.sp3),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: FacingTokens.sp4, vertical: FacingTokens.sp3),
        decoration: BoxDecoration(
          color: FacingTokens.surface,
          border: Border.all(color: FacingTokens.border),
          borderRadius: BorderRadius.circular(FacingTokens.r2),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text('포인트', style: FacingTokens.sectionLabel),
            ),
            Text('$balance P',
                style: FacingTokens.h3.copyWith(color: FacingTokens.primary)),
          ],
        ),
      ),
    );
  }
}
