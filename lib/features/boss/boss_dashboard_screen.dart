import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import 'boss_api_client.dart';
import 'boss_auth_state.dart';
import 'boss_dashboard_model.dart';

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
      setState(() { _loading = false; _error = '박스 정보 없음.'; });
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
      backgroundColor: FacingTokens.bg,
      appBar: _buildAppBar(context, auth),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: FacingTokens.primary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: FacingTokens.primary,
                  child: _Body(data: _data!),
                ),
      bottomNavigationBar: _BottomNav(),
    );
  }

  AppBar _buildAppBar(BuildContext context, BossAuthState auth) => AppBar(
        backgroundColor: FacingTokens.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              auth.gymName ?? 'Box',
              style: FacingTokens.h3.copyWith(color: FacingTokens.fg),
            ),
            Text(
              auth.role?.toUpperCase() ?? 'BOSS',
              style: FacingTokens.micro.copyWith(color: FacingTokens.primary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: FacingTokens.muted, size: 20),
            tooltip: 'Settings',
            onPressed: () =>
                Navigator.of(context).pushNamed('/boss/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: FacingTokens.muted, size: 20),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: FacingTokens.border),
        ),
      );
}

// ─── 메인 바디 ─────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final DashboardData data;
  const _Body({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: FacingTokens.sp4, vertical: FacingTokens.sp4),
      children: [
        // 날짜 헤더
        Text(
          data.today,
          style: FacingTokens.micro.copyWith(color: FacingTokens.muted),
        ),
        const SizedBox(height: FacingTokens.sp3),

        // ─── 오늘 현황 3 카운터 ───────────────────────────────────────
        Text('TODAY.', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        Row(
          children: [
            _CounterCard(label: 'RESERVATION',
                count: data.todayReservations.count),
            const SizedBox(width: FacingTokens.sp2),
            _CounterCard(label: 'ATTENDANCE',
                count: data.todayAttendances.count),
            const SizedBox(width: FacingTokens.sp2),
            _CounterCard(label: 'NEW / WEEK',
                count: data.newMembersThisWeek.count),
          ],
        ),
        const SizedBox(height: FacingTokens.sp5),

        // ─── 회원 운영 관리 CTA ───────────────────────────────────────
        _PrimaryCtaButton(
          label: 'Member Management',
          onTap: () {
            // TODO PHASE5 §1.3: /boss/members 진입
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PHASE5 §1.3 — 회원 목록 (구현 예정)'),
                backgroundColor: FacingTokens.surface,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(height: FacingTokens.sp5),

        // ─── 오늘의 수업 ──────────────────────────────────────────────
        Text('TODAY\'S CLASSES.', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        if (data.todayClasses.isEmpty)
          _EmptyCard(message: '오늘 수업 없음.')
        else
          ...data.todayClasses.map((c) => _ClassCard(cls: c)),
        const SizedBox(height: FacingTokens.sp5),

        // ─── 만료 임박 ────────────────────────────────────────────────
        if (data.expiringSoon.isNotEmpty) ...[
          Text('EXPIRING SOON.', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          ...data.expiringSoon.map((m) => _ExpiringCard(member: m)),
          const SizedBox(height: FacingTokens.sp5),
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
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: FacingTokens.sp3, horizontal: FacingTokens.sp2),
          decoration: BoxDecoration(
            color: FacingTokens.surface,
            border: Border.all(color: FacingTokens.border),
          ),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: FacingTokens.h1.copyWith(color: FacingTokens.fg),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: FacingTokens.sectionLabel,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _PrimaryCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryCtaButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp4),
          color: FacingTokens.primary,
          alignment: Alignment.center,
          child: Text(
            label,
            style: FacingTokens.h3.copyWith(
              color: FacingTokens.onColor,
              letterSpacing: 0.8,
            ),
          ),
        ),
      );
}

class _ClassCard extends StatelessWidget {
  final TodayClass cls;
  const _ClassCard({required this.cls});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: FacingTokens.sp2),
        padding: const EdgeInsets.all(FacingTokens.sp3),
        decoration: BoxDecoration(
          color: FacingTokens.surface,
          border: Border.all(color: FacingTokens.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cls.title, style: FacingTokens.lead.copyWith(
                      color: FacingTokens.fg, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${cls.startAt} – ${cls.endAt}'
                    '${cls.coaches.isNotEmpty ? '  ·  ${cls.coaches.join(", ")}' : ''}',
                    style: FacingTokens.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: FacingTokens.sp3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  cls.reserved.toString(),
                  style: FacingTokens.h2.copyWith(color: FacingTokens.fg),
                ),
                Text(
                  cls.capacity != null ? '/ ${cls.capacity}명' : '명',
                  style: FacingTokens.micro,
                ),
              ],
            ),
          ],
        ),
      );
}

class _ExpiringCard extends StatelessWidget {
  final ExpiringMember member;
  const _ExpiringCard({required this.member});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: FacingTokens.sp2),
        padding: const EdgeInsets.symmetric(
            horizontal: FacingTokens.sp3, vertical: FacingTokens.sp2),
        decoration: BoxDecoration(
          color: FacingTokens.surface,
          border: Border.all(
            color: member.dDay <= 7
                ? FacingTokens.danger.withValues(alpha: 0.5)
                : FacingTokens.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(member.name,
                  style: FacingTokens.body.copyWith(color: FacingTokens.fg)),
            ),
            Text(
              member.dDay == 0 ? 'D-Day' : 'D-${member.dDay}',
              style: FacingTokens.lead.copyWith(
                color: member.dDay <= 7
                    ? FacingTokens.danger
                    : FacingTokens.warning,
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
        padding: const EdgeInsets.all(FacingTokens.sp4),
        decoration: BoxDecoration(
          color: FacingTokens.surface,
          border: Border.all(color: FacingTokens.border),
        ),
        alignment: Alignment.center,
        child: Text(message, style: FacingTokens.caption),
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
                style: FacingTokens.caption.copyWith(color: FacingTokens.danger)),
            const SizedBox(height: FacingTokens.sp3),
            GestureDetector(
              onTap: onRetry,
              child: Text('Retry.',
                  style: FacingTokens.body.copyWith(
                      color: FacingTokens.primary,
                      decoration: TextDecoration.underline)),
            ),
          ],
        ),
      );
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 56 + MediaQuery.of(context).padding.bottom,
        decoration: const BoxDecoration(
          color: FacingTokens.surface,
          border: Border(top: BorderSide(color: FacingTokens.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home, label: 'Home', active: true,
                onTap: () {}),
            _NavItem(icon: Icons.people_outline, label: 'Members',
                onTap: () {}),
            _NavItem(icon: Icons.event_note_outlined, label: 'Classes',
                onTap: () {}),
            _NavItem(icon: Icons.settings_outlined, label: 'Settings',
                onTap: () {}),
          ],
        ),
      );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22,
                  color: active ? FacingTokens.primary : FacingTokens.muted),
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: FacingTokens.sectionLabel.copyWith(
                  color: active ? FacingTokens.primary : FacingTokens.mutedStrong,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      );
}
