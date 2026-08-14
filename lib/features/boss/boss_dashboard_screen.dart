import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/hkit.dart';
import 'boss_api_client.dart';
import 'boss_auth_state.dart';
import 'boss_dashboard_model.dart';
import 'class_roster_sheet.dart';

// PHASE5 §1.2 — 사장 폰 Dashboard.
// GET /api/v1/admin/gyms/{gym_id}/dashboard → 오늘 운영 데이터.
class BossDashboardScreen extends StatefulWidget {
  const BossDashboardScreen({super.key});

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
    setState(() { _loading = true; _error = null; });
    final api  = context.read<BossApiClient>();
    final auth = context.read<BossAuthState>();
    final gymId = auth.gymId;
    if (gymId == null) {
      setState(() { _loading = false; _error = '체육관 정보 없음.'; });
      return;
    }
    try {
      final j = await api.get('/api/v1/admin/gyms/$gymId/dashboard');
      setState(() { _data = DashboardData.fromJson(j); _loading = false; });
    } on AppException catch (e) {
      setState(() { _loading = false; _error = e.messageKo; });
    } catch (e) {
      setState(() { _loading = false; _error = '데이터 로드 실패.'; });
    }
  }

  Future<void> _logout() async {
    Haptic.medium();
    final api  = context.read<BossApiClient>();
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
      appBar: _buildAppBar(context, auth),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: HyphenTokens.primary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: HyphenTokens.primary,
                  child: _Body(data: _data!, onRefresh: _load),
                ),
      // v3.1 (2026-08-14 사용자 설계): 가짜 하단탭(_BottomNav — onTap 전부 빈
      // 함수) 삭제. 실제 탭은 CoachShell(예약 현황·수업·내 정보)이 담당하고
      // 이 화면은 그 첫 탭으로 임베드된다.
    );
  }

  AppBar _buildAppBar(BuildContext context, BossAuthState auth) => AppBar(
        backgroundColor: HyphenTokens.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              auth.gymName ?? 'Box',
              style: HyphenTokens.h3.copyWith(color: HyphenTokens.fg),
            ),
            Text(
              auth.role?.toUpperCase() ?? 'STAFF',
              style: HyphenTokens.micro.copyWith(color: HyphenTokens.primary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: HyphenTokens.muted, size: 20),
            tooltip: 'Settings',
            onPressed: () =>
                Navigator.of(context).pushNamed('/boss/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: HyphenTokens.muted, size: 20),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: HyphenTokens.border),
        ),
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
          horizontal: HyphenTokens.sp4, vertical: HyphenTokens.sp4),
      children: [
        // 날짜 헤더
        Text(
          data.today,
          style: HyphenTokens.micro.copyWith(color: HyphenTokens.muted),
        ),
        const SizedBox(height: HyphenTokens.sp3),

        // ─── 오늘 현황 3 카운터 ───────────────────────────────────────
        Text('오늘', style: HyphenTokens.sectionLabel),
        const SizedBox(height: HyphenTokens.sp2),
        Row(
          children: [
            _CounterCard(label: '예약',
                count: data.todayReservations.count),
            const SizedBox(width: HyphenTokens.sp2),
            _CounterCard(label: '출석',
                count: data.todayAttendances.count),
            const SizedBox(width: HyphenTokens.sp2),
            _CounterCard(label: '주간 신규',
                count: data.newMembersThisWeek.count),
          ],
        ),
        const SizedBox(height: HyphenTokens.sp5),

        // ─── 회원 운영 관리 CTA ───────────────────────────────────────
        HkButton.primary(
          '회원 관리',
          onPressed: () {
            // TODO PHASE5 §1.3: /boss/members 진입
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PHASE5 §1.3 — 회원 목록 (구현 예정)'),
                backgroundColor: HyphenTokens.surface,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(height: HyphenTokens.sp5),

        // ─── 오늘의 수업 ──────────────────────────────────────────────
        // v2.2: 'TODAY'S CLASSES.' → 한글 (v1.29 한글 기본, 도메인 고정어 아님).
        Text('오늘 수업', style: HyphenTokens.sectionLabel),
        const SizedBox(height: HyphenTokens.sp2),
        if (data.todayClasses.isEmpty)
          _EmptyCard(message: '오늘 수업 없음.')
        else
          // onChanged: 명단에서 출석을 찍으면 위쪽 '오늘 출석' 숫자가 달라진다 (D31).
          ...data.todayClasses.map(
              (c) => _ClassCard(cls: c, onChanged: onRefresh)),
        const SizedBox(height: HyphenTokens.sp5),

        // ─── 만료 임박 ────────────────────────────────────────────────
        if (data.expiringSoon.isNotEmpty) ...[
          Text('만료 임박', style: HyphenTokens.sectionLabel),
          const SizedBox(height: HyphenTokens.sp2),
          ...data.expiringSoon.map((m) => _ExpiringCard(member: m)),
          const SizedBox(height: HyphenTokens.sp5),
        ],
      ],
    );
  }
}

// ─── 서브 위젯 ──────────────────────────────────────────────────────────────

class _CounterCard extends StatelessWidget {
  final String label;
  final int count;
  const _CounterCard({required this.label, required this.count});

  @override
  // v2.2: ① 모서리 r3 — 이 화면 카드만 각져 있어 앱 안에서 혼자 다른 물건처럼
  // 보였다. ② 라벨을 숫자 위로 — 명단 시트·HkStatTile 은 '라벨 위/값 아래'인데
  // 여기만 뒤집혀 있어 같은 통계 타일이 두 형태였다 (H6).
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: HyphenTokens.sp3, horizontal: HyphenTokens.sp2),
          decoration: BoxDecoration(
            color: HyphenTokens.surface,
            border: Border.all(color: HyphenTokens.border),
            borderRadius: BorderRadius.circular(HyphenTokens.r3),
          ),
          child: Column(
            children: [
              Text(
                label.toUpperCase(),
                style: HyphenTokens.sectionLabel,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HyphenTokens.sp1),
              Text(
                count.toString(),
                style: HyphenTokens.h1.copyWith(color: HyphenTokens.fg),
              ),
            ],
          ),
        ),
      );
}

// v2.2: 자체 GestureDetector + 각진 색면을 HkButton.primary 로 교체 (H7).
// 앱의 다른 모든 주 버튼은 r4 둥근 52 인데 이 하나만 각진 면이라 화면에서
// 혼자 튀었다. 눌림 피드백(pressed 색)도 없었다.
// ※ 이 버튼의 동작은 아직 '구현 예정' 스낵바이며 하단 탭 '회원' 과 목적지가
//   같다 — 존치 여부는 제품 판단이라 모양만 맞추고 남겨 둔다.

class _ClassCard extends StatelessWidget {
  final TodayClass cls;

  /// 명단에서 출석을 바꾼 채 시트가 닫혔을 때 — 대시보드 재조회.
  final VoidCallback? onChanged;
  const _ClassCard({required this.cls, this.onChanged});

  // D29 (2026-08-12): 카드 탭 → 예약자 명단 시트. 그동안 예약 "수"만 보이고
  // "누가" 를 볼 곳이 없었다 — 코치 핵심 동선이라 여기서 한 번 탭으로 연다.
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () {
          Haptic.light();
          showClassRosterSheet(context, cls.id, onChanged: onChanged);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: HyphenTokens.sp2),
          padding: const EdgeInsets.all(HyphenTokens.sp3),
          decoration: BoxDecoration(
            color: HyphenTokens.surface,
            border: Border.all(color: HyphenTokens.border),
            borderRadius: BorderRadius.circular(HyphenTokens.r3),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cls.title, style: HyphenTokens.lead.copyWith(
                        color: HyphenTokens.fg, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    // v2.2 (H2): DB 원문(2026-08-12T19:00:00)이 그대로 나와
                    // 두 줄을 잡아먹었다. 오늘 수업 목록이라 날짜는 이미 위에
                    // 있으므로 시:분만 남긴다 — '19:00 – 20:00 · 박준서'.
                    Text(
                      '${_hhmm(cls.startAt)} – ${_hhmm(cls.endAt)}'
                      '${cls.coaches.isNotEmpty ? '  ·  ${cls.coaches.join(", ")}' : ''}',
                      style: HyphenTokens.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: HyphenTokens.sp3),
              // v2.2: '8' 과 '/ 12명' 이 위아래로 쪼개져 한 값이 두 덩이로
              // 보였다 — 한 줄로 붙인다.
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    cls.reserved.toString(),
                    style: HyphenTokens.h2.copyWith(color: HyphenTokens.fg),
                  ),
                  Text(
                    cls.capacity != null ? ' / ${cls.capacity}명' : '명',
                    style: HyphenTokens.micro,
                  ),
                ],
              ),
              const SizedBox(width: HyphenTokens.sp1),
              const Icon(Icons.chevron_right,
                  size: 18, color: HyphenTokens.mutedStrong),
            ],
          ),
        ),
      );
}

/// ISO 시각에서 `HH:MM` 만. 파싱 실패하면 원문을 그대로 돌려준다
/// (형식이 바뀌어도 화면이 비지 않게).
String _hhmm(String iso) {
  final t = DateTime.tryParse(iso);
  if (t == null) return iso;
  return '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

class _ExpiringCard extends StatelessWidget {
  final ExpiringMember member;
  const _ExpiringCard({required this.member});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: HyphenTokens.sp2),
        padding: const EdgeInsets.symmetric(
            horizontal: HyphenTokens.sp3, vertical: HyphenTokens.sp2),
        decoration: BoxDecoration(
          color: HyphenTokens.surface,
          border: Border.all(
            color: member.dDay <= 7
                ? HyphenTokens.danger.withValues(alpha: 0.5)
                : HyphenTokens.border,
          ),
          borderRadius: BorderRadius.circular(HyphenTokens.r3),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(member.name,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg)),
            ),
            Text(
              member.dDay == 0 ? 'D-Day' : 'D-${member.dDay}',
              style: HyphenTokens.lead.copyWith(
                color: member.dDay <= 7
                    ? HyphenTokens.danger
                    : HyphenTokens.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(HyphenTokens.sp4),
        decoration: BoxDecoration(
          color: HyphenTokens.surface,
          border: Border.all(color: HyphenTokens.border),
          borderRadius: BorderRadius.circular(HyphenTokens.r3),
        ),
        alignment: Alignment.center,
        child: Text(message, style: HyphenTokens.caption),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message,
                style: HyphenTokens.caption.copyWith(color: HyphenTokens.danger)),
            const SizedBox(height: HyphenTokens.sp3),
            GestureDetector(
              onTap: onRetry,
              child: Text('다시 시도',
                  style: HyphenTokens.body.copyWith(
                      color: HyphenTokens.primary,
                      decoration: TextDecoration.underline)),
            ),
          ],
        ),
      );
}

