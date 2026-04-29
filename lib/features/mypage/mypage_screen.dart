import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_mode.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../core/ui_prefs_state.dart';
import '../../core/unit_state.dart';
import '../../widgets/inbox_bell.dart';
import '../_debug/persona_switcher_screen.dart';
import '../auth/auth_state.dart';
import '../goals/goals_screen.dart';
import '../gym/coach_dashboard_screen.dart';
import '../gym/gym_state.dart';
import '../profile/profile_state.dart';
import 'algorithm_screen.dart';
import 'edit_profile_screen.dart';
import 'import_screen.dart';
import 'privacy_screen.dart';

/// v1.22: Profile = identity + 측정값 편집 진입 + 잘안쓰는 actions.
/// Engine score · Tier · Radar · Category Tier · Trend · Records · RoleModel 등
/// score 관련 컨텐츠는 모두 Home 으로 이동 (중복 제거).
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        actions: const [InboxBellAction()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
          children: const [
            _IdentityCard(),
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
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: FacingTokens.sp3),
        child: Divider(height: 1, color: FacingTokens.border),
      );
}

/// v1.22: 닉네임 + 아바타 + Edit Profile 버튼.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final name = (auth.displayName?.trim().isNotEmpty == true)
        ? auth.displayName!.trim()
        : 'Athlete';
    final provider = (auth.provider ?? '').toUpperCase();
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 아바타 — 현재는 첫 글자. 향후 사진 설정 시 Avatar 위젯으로 교체.
              Container(
                width: 56,
                height: 56,
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
                  style: FacingTokens.h2.copyWith(
                    color: FacingTokens.accent,
                  ),
                ),
              ),
              const SizedBox(width: FacingTokens.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: FacingTokens.h2),
                    if (provider.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(provider, style: FacingTokens.microLabel),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp4),
          OutlinedButton.icon(
            onPressed: () {
              Haptic.light();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const EditProfileScreen(),
              ));
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }
}

class _MyBoxSection extends StatelessWidget {
  const _MyBoxSection();

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MY BOX', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          if (gym == null)
            const Text('No Box. Find Box on WOD tab.',
                style: FacingTokens.caption)
          else ...[
            Text(gym.name,
                style:
                    FacingTokens.body.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: FacingTokens.sp1),
            Text(
              '${gs.isOwner ? 'OWNER' : 'MEMBER'} · ${gs.membership.status ?? '-'} · ${gym.memberCount} members',
              style: FacingTokens.caption,
            ),
            if (gs.isOwner) ...[
              const SizedBox(height: FacingTokens.sp3),
              OutlinedButton(
                onPressed: () {
                  Haptic.light();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CoachDashboardScreen(),
                  ));
                },
                child: const Text('Manage Members'),
              ),
            ],
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BODY', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          _Kv(label: 'Weight', value: weightDisplay),
          _Kv(label: 'Height', value: height),
          _Kv(label: 'Age', value: age),
          _Kv(label: 'Sex', value: sex),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('SETTINGS', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          const _ModeRow(),
          const SizedBox(height: FacingTokens.sp3),
          Row(
            children: [
              const Expanded(child: Text('Unit', style: FacingTokens.body)),
              Consumer<UnitState>(
                builder: (ctx, u, _) => _UnitToggle(u: u),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp3),
          Consumer<UiPrefsState>(
            builder: (ctx, ui, _) => Row(
              children: [
                const Expanded(
                    child: Text('Font Size', style: FacingTokens.body)),
                _TextScaleToggle(current: ui.textScale, state: ui),
              ],
            ),
          ),
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
          child: InkWell(
            onTap: () {
              Haptic.light();
              state.setTextScale(o.$1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FacingTokens.sp3,
                vertical: FacingTokens.sp2,
              ),
              decoration: BoxDecoration(
                color: selected ? FacingTokens.fg : FacingTokens.bg,
                border: Border.all(
                  color: selected ? FacingTokens.fg : FacingTokens.border,
                ),
                borderRadius: BorderRadius.circular(FacingTokens.r2),
              ),
              child: Text(
                o.$2,
                style: FacingTokens.body.copyWith(
                  color: selected ? FacingTokens.bg : FacingTokens.fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
        _Pill(
            label: 'kg',
            selected: u.isKg,
            onTap: () {
              if (!u.isKg) u.toggle();
            }),
        const SizedBox(width: FacingTokens.sp2),
        _Pill(
            label: 'lb',
            selected: !u.isKg,
            onTap: () {
              if (u.isKg) u.toggle();
            }),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FacingTokens.r4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FacingTokens.touchMin),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FacingTokens.sp4,
              vertical: FacingTokens.sp2,
            ),
            decoration: BoxDecoration(
              color: selected ? FacingTokens.fg : Colors.transparent,
              borderRadius: BorderRadius.circular(FacingTokens.r4),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: FacingTokens.body.copyWith(
                  color: selected ? FacingTokens.bg : FacingTokens.muted,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
      ),
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
                    Expanded(
                      child: Text(
                        '${auth.provider?.toUpperCase() ?? '-'} · ${auth.displayName ?? ''}',
                        style: FacingTokens.caption,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: FacingTokens.muted,
                      ),
                      onPressed: () => _confirmSignOut(context),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushNamed('/history'),
            child: const Text('View History'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const PrivacyScreen(),
            )),
            child: const Text('Privacy Policy'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ImportScreen(),
            )),
            child: const Text('Import Data'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const GoalsScreen(),
            )),
            child: const Text('Goals'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const AlgorithmScreen(),
            )),
            child: const Text('Algorithm'),
          ),
          const SizedBox(height: FacingTokens.sp3),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: FacingTokens.accent,
            ),
            onPressed: () => _confirmReset(context),
            child: const Text('Reset data'),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: FacingTokens.sp5),
            const Divider(),
            const SizedBox(height: FacingTokens.sp3),
            const Text('DEBUG', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp1),
            const Text(
              'Debug 빌드 전용. Release 자동 차단.',
              style: FacingTokens.caption,
            ),
            const SizedBox(height: FacingTokens.sp2),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const PersonaSwitcherScreen(),
              )),
              child: const Text('Persona Switcher'),
            ),
          ],
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
        title: const Text('Reset data?'),
        content: const Text(
          '프로필·등급·벤치마크를 전부 삭제합니다.\n'
          '되돌릴 수 없습니다.',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.accent),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Reset'),
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
        title: const Text('Sign Out.'),
        content: const Text(
          '로그아웃해도 프로필·기록은 이 기기에 그대로 유지됩니다.\n'
          '같은 provider로 다시 로그인하면 모든 데이터 복구.\n'
          '계정 자체를 지우려면 Privacy Policy → Delete Account.',
          style: FacingTokens.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.muted),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Sign Out'),
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
            const Text('Mode', style: FacingTokens.body),
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
                Semantics(
                  label:
                      'Mode ${_label(m)}${_mode == m ? " selected" : ""}',
                  button: true,
                  selected: _mode == m,
                  container: true,
                  child: ChoiceChip(
                    label: Text(_label(m)),
                    selected: _mode == m,
                    backgroundColor: FacingTokens.surface,
                    selectedColor: FacingTokens.accent,
                    labelStyle: FacingTokens.caption.copyWith(
                      color:
                          _mode == m ? FacingTokens.fg : FacingTokens.muted,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: _saving ? null : (_) => _setMode(m),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
