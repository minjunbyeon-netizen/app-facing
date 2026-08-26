import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/input_formatters.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../widgets/hkit.dart';
import '../auth/auth_state.dart';
import '../gym/gym_state.dart';
import '../profile/profile_state.dart';

/// 회원 가입 신청 — 이름·연락처 + 아이디 + 비밀번호(2회).
///
/// v2.3 (2026-08-12): 이 앱은 **HYPHEN 한 박스 전용**이라 박스를 고르는 절차가
/// 없다. 그때는 아이디·비밀번호만 받고 이름은 코치가 나중에 채우기로 했었다.
///
/// v2.7 (2026-08-13 사용자 지시 — 실검증에서 뒤집힘): 코치 화면에 신청자가
/// **'이름 미등록'** 으로만 떠서, 누가 신청했는지 모른 채 승인해야 했다.
/// 그래서 이름(필수)·연락처(선택)를 가입 신청에서 받는다. 코치가 승인 버튼을
/// 누르기 전에 사람을 식별할 수 있어야 한다.
///
/// 박스 id 는 `/api/v1/member/gyms-list` 에서 이름이 HYPHEN 인 행으로 찾는다
/// (목록이 안 오면 [_kFallbackGymId]). 나중에 박스가 늘어나면 이 화면에
/// 선택 UI 를 되살리는 것이 아니라, 서버가 기본 박스를 내려주게 하면 된다.
///
/// 백엔드: POST /api/v1/member/gyms/`<gid>`/self-signup
///   body {login_id, password} · header X-Device-Id
///   → status='pending' 으로 신청 + MemberCredential 생성 (승인 후 바로 로그인)
// S9 (2026-08-26 사용자 결정): 이 앱은 HYPHEN 체육관 1곳 전용 — 가입 대상 고정은 의도.
// 다른 체육관을 받게 되면 그때 선택 UI 를 (숨긴 채) 살린다. 지금은 손대지 않는다.
const String _kBrandGymName = 'HYPHEN';
const int _kFallbackGymId = 2;

class SelfSignupScreen extends StatefulWidget {
  const SelfSignupScreen({super.key});

  @override
  State<SelfSignupScreen> createState() => _SelfSignupScreenState();
}

class _SelfSignupScreenState extends State<SelfSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _sportsCtrl = TextEditingController();
  final _injuryCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  int _gymId = _kFallbackGymId;
  String? _gender;
  int? _bandIndex;
  bool _submitting = false;
  bool _pwVisible = false;

  @override
  void initState() {
    super.initState();
    _resolveGym();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthCtrl.dispose();
    _phoneCtrl.dispose();
    _sportsCtrl.dispose();
    _injuryCtrl.dispose();
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  /// 가입 대상 박스를 이름으로 찾는다. 목록을 못 받으면 폴백 id 로 그대로 진행 —
  /// 신청 자체를 막을 이유가 없다 (서버가 없는 박스면 404 로 알려준다).
  Future<void> _resolveGym() async {
    try {
      final api = context.read<ApiClient>();
      final raw = await api.getList('/api/v1/member/gyms-list');
      if (!mounted) return;
      for (final e in raw) {
        if ((e['name'] ?? '') == _kBrandGymName) {
          setState(() => _gymId = (e['id'] as num).toInt());
          return;
        }
      }
    } catch (_) {
      // 폴백 id 유지.
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final gymId = _gymId;
    final loginId = _idCtrl.text.trim();

    setState(() => _submitting = true);
    Haptic.medium();
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final profile = context.read<ProfileState>();

    try {
      final phone = _phoneCtrl.text.trim();
      final birth = _birthCtrl.text.trim();
      final sports = _sportsCtrl.text.trim();
      final injury = _injuryCtrl.text.trim();
      final res = await api.post('/api/v1/member/gyms/$gymId/self-signup', {
        'login_id': loginId,
        'password': _pwCtrl.text,
        'name': _nameCtrl.text.trim(),
        if (phone.isNotEmpty) 'phone': phone,
        if (birth.isNotEmpty) 'birth_date': birth,
        if (_gender != null) 'gender': _gender,
        if (_bandIndex != null)
          'experience_years': Tier.bands[_bandIndex!].years,
        if (sports.isNotEmpty) 'sports_history': sports,
        if (injury.isNotEmpty) 'safety_note': injury,
      });
      if (!mounted) return;
      final status = (res['status'] ?? 'pending') as String;
      final duplicate = res['duplicate'] == true;

      // 가입 신청 성공 = 이 기기의 신원 확정. AuthState 를 세워 두지 않으면
      // 다음 실행 때 splash 가 !isSignedIn 을 보고 로그인 화면으로 되돌린다.
      await auth.signIn('self', displayName: _nameCtrl.text.trim());
      if (!mounted) return;
      // S1 후속 (2026-08-26): 신청 직후 소속을 다시 읽어야 셸이 '승인 대기' 를
      // 그린다. 안 읽으면 (로그아웃으로 비운) 빈 소속 그대로라 '체육관 미가입'
      // 이 떠서 방금 신청한 사람에게 다시 신청하라고 말한다.
      try {
        await context.read<GymState>().loadMine();
      } catch (_) {}
      if (!mounted) return;

      if (duplicate) {
        _toast(status == 'pending' ? '이미 승인 대기 중입니다.' : '이미 가입된 회원입니다.');
        _goNext(profile);
      } else if (status == 'pending') {
        _showApprovalDialog(_kBrandGymName, profile);
      } else {
        _toast('이미 가입된 회원입니다.');
        _goNext(profile);
      }
    } on AppException catch (e) {
      if (!mounted) return;
      _toast(e.messageKo);
    } catch (_) {
      if (!mounted) return;
      _toast('가입 신청 실패. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showApprovalDialog(String gymName, ProfileState profile) {
    HkDialog.info(
      context,
      title: '가입 신청 완료',
      message: '$gymName 에 가입을 신청했습니다.\n코치 승인 후 아이디로 로그인할 수 있습니다.',
    ).then((_) {
      if (mounted) _goNext(profile);
    });
  }

  /// 가입 직후 목적지.
  ///
  /// v2.8 (2026-08-13 사용자 지시): 신청서가 성별·생년월일·경력까지 받으므로
  /// 곧바로 뒤이어 같은 것을 묻던 '내 정보' 단계를 거치지 않는다. 셸로 보내면
  /// 승인 전에는 대기 화면이 뜨고, 승인되면 그대로 쓰던 화면이 열린다.
  /// (`/onboarding/basic` 화면은 프로필 수정 경로로 그대로 살아 있다.)
  void _goNext(ProfileState profile) {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/shell', (_) => false);
  }

  void _toast(String msg) {
    HkSnack.error(context, msg);
  }

  /// 입력한 칸이 하나라도 있는가 — BACK 확인의 기준 (S6).
  bool get _dirty => [
        _nameCtrl,
        _birthCtrl,
        _phoneCtrl,
        _sportsCtrl,
        _injuryCtrl,
        _idCtrl,
        _pwCtrl,
        _pw2Ctrl,
      ].any((c) => c.text.trim().isNotEmpty);

  /// S6 (2026-08-26 사용자 지시): 뒤로가기 한 번에 폼 전체가 사라지던 것 —
  /// 입력이 있으면 한 번 묻는다. 비어 있으면 그대로 나간다.
  Future<void> _onBack(bool didPop, Object? _) async {
    if (didPop || _submitting) return;
    final nav = Navigator.of(context);
    if (!_dirty) {
      nav.pop();
      return;
    }
    final ok = await HkDialog.confirm(
      context,
      title: '작성을 그만둘까요?',
      message: '입력한 내용이 사라집니다.',
      cancelLabel: '계속 작성',
      confirmLabel: '나가기',
      danger: true,
    );
    if (ok && mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      appBar: const HkAppBar(title: '가입 신청'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            HyphenTokens.sp5,
            HyphenTokens.sp4,
            HyphenTokens.sp5,
            HyphenTokens.sp5,
          ),
          child: Form(
            key: _formKey,
            // v3.3 (2026-08-21 사용자 지시 "유효성 검사·자동 하이픈으로 돕기"):
            // 제출 버튼을 눌러야만 빨간 글씨가 나오던 것을, 한 번 만진 칸은
            // 고치는 즉시 검사·해제되게 바꾼다. 자동 하이픈(생년월일·연락처)과
            // 형식 검증 자체는 v2.6 input_formatters SSOT 그대로다 — 서버로
            // 보내는 필드·형식은 그대로라 PC 명단·신규 등록 폼과 어긋나지 않는다.
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HkSectionLabel('이름'),
                const SizedBox(height: HyphenTokens.sp1),
                TextFormField(
                  controller: _nameCtrl,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  decoration: const InputDecoration(hintText: '코치에게 보일 이름'),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? '이름을 입력해 주세요.' : null,
                ),
                const SizedBox(height: HyphenTokens.sp4),

                const HkSectionLabel('생년월일'),
                const SizedBox(height: HyphenTokens.sp1),
                TextFormField(
                  controller: _birthCtrl,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  decoration: const InputDecoration(hintText: '1995-01-01'),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  // 숫자만 치면 하이픈이 알아서 들어간다 (input_formatters SSOT).
                  inputFormatters: [BirthDateInputFormatter()],
                  validator: (v) => birthDateError(v ?? ''),
                ),
                const SizedBox(height: HyphenTokens.sp4),

                const HkSectionLabel('성별'),
                const SizedBox(height: HyphenTokens.sp2),
                Row(
                  children: [
                    HkBadge(
                      '남',
                      color: HyphenTokens.fg,
                      selected: _gender == 'male',
                      onTap: () {
                        Haptic.selection();
                        setState(() => _gender = 'male');
                      },
                    ),
                    const SizedBox(width: HyphenTokens.sp2),
                    HkBadge(
                      '여',
                      color: HyphenTokens.fg,
                      selected: _gender == 'female',
                      onTap: () {
                        Haptic.selection();
                        setState(() => _gender = 'female');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: HyphenTokens.sp4),

                const HkSectionLabel('연락처'),
                const SizedBox(height: HyphenTokens.sp1),
                TextFormField(
                  controller: _phoneCtrl,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  decoration: const InputDecoration(hintText: '010-1234-5678'),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [PhoneInputFormatter()],
                  // 선택 입력 — 비워 두면 코치가 나중에 채운다. 넣었다면 형식은 맞춰야
                  // 서버(normalize_phone)가 거절하지 않는다.
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    final digits = t.replaceAll('-', '');
                    if (digits.length < 9 || digits.length > 11) {
                      return '전화번호를 다시 확인해 주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: HyphenTokens.sp4),

                const HkSectionLabel('운동 경력'),
                const SizedBox(height: HyphenTokens.sp2),
                Wrap(
                  spacing: HyphenTokens.sp2,
                  runSpacing: HyphenTokens.sp2,
                  children: [
                    for (var i = 0; i < Tier.bands.length; i++)
                      HkBadge(
                        Tier.bands[i].label,
                        color: HyphenTokens.fg,
                        selected: _bandIndex == i,
                        onTap: () {
                          Haptic.selection();
                          setState(() => _bandIndex = i);
                        },
                      ),
                  ],
                ),
                // 고른 구간이 어느 레벨이 되는지 그 자리에서 보여준다 —
                // 코치 화면에서 처음 보게 되면 "왜 내가 스케일이냐"가 된다 (D36).
                if (_bandIndex != null) ...[
                  const SizedBox(height: HyphenTokens.sp3),
                  Row(
                    children: [
                      const Text('내 레벨', style: HyphenTokens.caption),
                      const SizedBox(width: HyphenTokens.sp2),
                      Builder(
                        builder: (_) {
                          final t = Tier.fromExperienceYears(
                            Tier.bands[_bandIndex!].years,
                          );
                          return HkBadge(t.memberLevelLabel, color: t.color);
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: HyphenTokens.sp4),

                // 구체 종목을 받는 칸이라 '해온 종목' 표기 유지 ('운동' 금지는 2026-08-14 해제).
                const HkSectionLabel('해온 종목'),
                const SizedBox(height: HyphenTokens.sp1),
                TextFormField(
                  controller: _sportsCtrl,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  decoration: const InputDecoration(
                    hintText: '예: 축구 5년, 웨이트 2년 · 없으면 비워 두세요',
                  ),
                  textInputAction: TextInputAction.next,
                  maxLength: 200,
                ),
                const SizedBox(height: HyphenTokens.sp3),

                const HkSectionLabel('부상 이력 · 주의사항'),
                const SizedBox(height: HyphenTokens.sp1),
                TextFormField(
                  controller: _injuryCtrl,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  // 코치가 수업 전에 보는 값이라 무엇을 적어야 하는지 예를 준다.
                  decoration: const InputDecoration(
                    hintText:
                        '예: 오른쪽 어깨 부상 · 오버헤드 동작 주의\n'
                        '없으면 비워 두세요',
                  ),
                  textInputAction: TextInputAction.next,
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: HyphenTokens.sp4),

                const HkSectionLabel('아이디'),
                const SizedBox(height: HyphenTokens.sp1),
                TextFormField(
                  controller: _idCtrl,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  decoration: const InputDecoration(hintText: '로그인에 쓸 아이디'),
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9._-]'),
                    ),
                  ],
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.length < 4) return '아이디는 4자 이상 입력해 주세요.';
                    return null;
                  },
                ),
                const SizedBox(height: HyphenTokens.sp4),

                const HkSectionLabel('비밀번호'),
                const SizedBox(height: HyphenTokens.sp1),
                TextFormField(
                  controller: _pwCtrl,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  decoration: InputDecoration(
                    hintText: '비밀번호',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _pwVisible ? Icons.visibility_off : Icons.visibility,
                        color: HyphenTokens.muted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _pwVisible = !_pwVisible),
                    ),
                  ),
                  obscureText: !_pwVisible,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v ?? '').length < 4 ? '비밀번호는 4자 이상 입력해 주세요.' : null,
                ),
                const SizedBox(height: HyphenTokens.sp3),
                TextFormField(
                  controller: _pw2Ctrl,
                  style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  decoration: const InputDecoration(hintText: '비밀번호 확인'),
                  obscureText: !_pwVisible,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) => v != _pwCtrl.text ? '비밀번호가 서로 다릅니다.' : null,
                ),

                const SizedBox(height: HyphenTokens.sp6),
                _submitting
                    ? const HkLoading()
                    : HkButton.primary('신청하기', onPressed: _submit),
                const SizedBox(height: HyphenTokens.sp3),
                Text(
                  '코치가 승인하면 이 아이디로 로그인할 수 있습니다.',
                  style: HyphenTokens.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
