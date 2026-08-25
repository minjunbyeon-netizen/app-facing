import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/role_labels.dart';
import '../../core/theme.dart';
import '../../widgets/hkit.dart';
import '../gym/member_approvals_screen.dart';
import 'boss_api_client.dart';
import 'boss_auth_state.dart';
import 'boss_dashboard_model.dart';
import 'class_roster_sheet.dart';
import '../classes/class_line.dart';
import '../../core/time_format.dart';

// PHASE5 §1.2 — 사장 폰 Dashboard.
// GET /api/v1/admin/gyms/{gym_id}/dashboard → 오늘 운영 데이터.
class BossDashboardScreen extends StatefulWidget {
  /// 셸(CoachShell) 안에 얹힐 때는 자기 AppBar 를 그리지 않는다 — 상단바는
  /// 셸이 하나만 갖는다 (v3.23 사용자 지시 "상단화면 통일하라고 1개로").
  final bool embedded;

  const BossDashboardScreen({super.key, this.embedded = false});

  @override
  State<BossDashboardScreen> createState() => _BossDashboardScreenState();
}

class _BossDashboardScreenState extends State<BossDashboardScreen> {
  DashboardData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = context.read<BossApiClient>();
    final auth = context.read<BossAuthState>();
    final gymId = auth.gymId;
    if (gymId == null) {
      setState(() {
        _loading = false;
        _error = '체육관 정보 없음.';
      });
      return;
    }
    try {
      final j = await api.get('/api/v1/admin/gyms/$gymId/dashboard');
      setState(() {
        _data = DashboardData.fromJson(j);
        _loading = false;
      });
    } on AppException catch (e) {
      setState(() {
        _loading = false;
        _error = e.messageKo;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '데이터 로드 실패.';
      });
    }
  }

  // v3.21 (2026-08-25 사용자 지시): 폰 수업 등록(_openCompose) 삭제 —
  // 수업을 만들고 고치는 건 PC 몫이다 (README §제거된 기능 대장 17).

  Future<void> _logout() async {
    Haptic.medium();
    final api = context.read<BossApiClient>();
    final auth = context.read<BossAuthState>();
    try {
      await api.post('/api/v1/admin/logout', {});
    } catch (_) {}
    await auth.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<BossAuthState>();
    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      appBar: widget.embedded ? null : _buildAppBar(context, auth),
      body: _loading
          ? const HkLoading()
          : _error != null
          ? HkErrorState(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              color: HyphenTokens.primary,
              child: _Body(data: _data!, onRefresh: _load),
            ),
      // v3.1 (2026-08-14 사용자 설계): 가짜 하단탭(_BottomNav — onTap 전부 빈
      // 함수) 삭제. 실제 탭은 CoachShell(v3.3 — 예약 현황·수업 2탭)이
      // 담당하고 이 화면은 예약 현황 탭으로 임베드된다.
    );
  }

  // 단독으로 띄울 때(골든)만 쓰는 상단바 — 셸 안에서는 셸 것을 쓴다.
  PreferredSizeWidget _buildAppBar(BuildContext context, BossAuthState auth) =>
      HkAppBar.identity(
        name: auth.gymName ?? '체육관',
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

// ─── 메인 바디 ─────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final DashboardData data;

  /// 대시보드 재조회 — 명단에서 출석을 찍고 나온 경우에만 불린다 (D31).
  final Future<void> Function()? onRefresh;

  const _Body({required this.data, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: HyphenTokens.sp4,
        vertical: HyphenTokens.sp4,
      ),
      children: [
        // 날짜 헤더
        Text(
          data.today,
          style: HyphenTokens.micro.copyWith(color: HyphenTokens.muted),
        ),
        const SizedBox(height: HyphenTokens.sp3),

        // ─── 오늘 현황 3 카운터 ───────────────────────────────────────
        HkSectionLabel('오늘'),
        const SizedBox(height: HyphenTokens.sp2),
        Row(
          children: [
            Expanded(
              child: HkStatTile(
                label: '예약',
                value: '${data.todayReservations.count}',
              ),
            ),
            const SizedBox(width: HyphenTokens.sp2),
            Expanded(
              child: HkStatTile(
                label: '출석',
                value: '${data.todayAttendances.count}',
              ),
            ),
            const SizedBox(width: HyphenTokens.sp2),
            Expanded(
              child: HkStatTile(
                label: '주간 신규',
                value: '${data.newMembersThisWeek.count}',
              ),
            ),
          ],
        ),
        const SizedBox(height: HyphenTokens.sp5),

        // ─── 가입 신청 CTA ───────────────────────────────────────────
        // v3.21: 폰 코치가 하는 회원 관리는 '가입 신청 승인/거절' 하나다
        // (명단·통계·프로필은 PC). 라벨을 그 하나에 맞춘다.
        // 회원 API 접근은 백엔드 코치 기기 폴백(is_staff_device)이 처리한다.
        HkButton.primary(
          '가입 신청',
          onPressed: () {
            Haptic.light();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MemberApprovalsScreen()),
            );
          },
        ),
        const SizedBox(height: HyphenTokens.sp5),

        // ─── 오늘의 수업 ──────────────────────────────────────────────
        // v2.2: 'TODAY'S CLASSES.' → 한글 (v1.29 한글 기본, 도메인 고정어 아님).
        // v3.21: '수업 등록' 버튼 삭제 — 수업 만들기는 PC 몫.
        HkSectionLabel('오늘 수업'),
        const SizedBox(height: HyphenTokens.sp2),
        if (data.todayClasses.isEmpty)
          const HkEmptyState(title: '오늘 수업 없음')
        else
          // v3.25: 회원 주간보드와 같은 ClassLine — 한 수업을 두 모양으로 그리지 않는다.
          // onChanged: 명단에서 출석을 찍으면 위쪽 '오늘 출석' 숫자가 달라진다 (D31).
          // D29: 탭 → 예약자 명단 시트 (예약 "수"만 보이고 "누가" 를 볼 곳이 없었다).
          ...data.todayClasses.map(
            (c) => ClassLine.coach(
              timeLabel: '${hhmmIso(c.startAt)} – ${hhmmIso(c.endAt)}',
              title: c.title,
              subtitle: c.coaches.join(', '),
              reserved: c.reserved,
              capacity: c.capacity,
              onTap: () {
                Haptic.light();
                showClassRosterSheet(context, c.id, onChanged: onRefresh);
              },
            ),
          ),
        const SizedBox(height: HyphenTokens.sp5),

        // v3.21: '만료 임박' 섹션 삭제 — 회원권은 PC 에서 본다
        // (백엔드 응답의 expiring_soon 은 PC 가 계속 쓰므로 유지).
      ],
    );
  }
}

// ─── 서브 위젯 ──────────────────────────────────────────────────────────────

// (구 _CounterCard 는 v3.26 에서 HkStatTile 로 — 명단 시트·홈과 같은 타일.)

// v2.2: 자체 GestureDetector + 각진 색면을 HkButton.primary 로 교체 (H7).
// 앱의 다른 모든 주 버튼은 r4 둥근 52 인데 이 하나만 각진 면이라 화면에서
// 혼자 튀었다. 눌림 피드백(pressed 색)도 없었다.
// (구 '구현 예정' 스낵바는 v3.3 에서 CoachDashboardScreen push 로 실배선 —
//  회원 현황 탭이 사라지면서 이 버튼이 가입 승인 진입점이 됐다.)

// (구 _ClassCard·_hhmm·_EmptyCard·_ErrorView 는 v3.25 에서 정본으로 —
//  ClassLine.coach · core/time_format.hhmmIso · HkEmptyState · HkErrorState.)
