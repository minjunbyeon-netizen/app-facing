import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/input_formatters.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../widgets/hkit.dart';
import '../profile/profile_state.dart';

/// 가입 직후 한 번 묻는 화면 — 내 정보(이름·생년월일·전화)와 성별·경력.
///
/// v2.3 (2026-08-12 사용자 지시): 체중·키·나이와 6단계 벤치마크(운동 능력)를
/// 전부 뺐다. 이 앱은 HYPHEN 한 박스에서 예약·공지를 주고받는 것이 본업이라,
/// 가입하자마자 7단계 측정을 시키는 것이 앞을 막고 있었다.
///
/// v2.6 (2026-08-13 사용자 지시): **이름·생년월일·전화**를 여기서 받는다.
/// 코치 PC 회원 목록은 이 세 값을 보여주는데, 앱으로 들어온 회원은 넣을 곳이
/// 없어 늘 비어 있었다. 저장하면 `PATCH /api/v1/member/me/profile` 로 올라가
/// PC 목록에 바로 뜬다. 레벨도 서버가 경력에서 계산해 같이 넣는다 (D36).
///
/// 뺀 값들은 화면에서 사라진 것이지 코드가 사라진 것은 아니다 — 프로필 편집의
/// 신체·벤치마크 화면(`/onboarding/benchmarks`)은 그대로 살아 있고, Tier 를
/// 다시 쓰려면 그 진입점만 열면 된다 ("숨김 = 코드 보존").
class OnboardingBasicScreen extends StatefulWidget {
  const OnboardingBasicScreen({super.key});

  @override
  State<OnboardingBasicScreen> createState() => _OnboardingBasicScreenState();
}

// v2.8 (2026-08-13): 경력 구간 목록은 `Tier.bands` 하나로 모았다 — 가입 신청서와
// 이 화면이 같은 질문을 하는데 상수를 각자 들고 있었다 (글로벌 §0-B).
const List<ExperienceBand> _kExpBands = Tier.bands;

class _OnboardingBasicScreenState extends State<OnboardingBasicScreen> {
  final _nameCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _gender = 'male';
  int? _bandIndex;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileState>();
    _gender = p.gender;
    final y = p.experienceYears;
    if (y > 0) {
      _bandIndex = y < 1
          ? 0
          : y < 3
              ? 1
              : 2;
    }
    _prefill();
  }

  /// 코치가 PC 에서 이미 적어둔 값이 있으면 그것부터 보여준다 (다시 묻지 않게).
  Future<void> _prefill() async {
    try {
      final api = context.read<ApiClient>();
      final data = await api.get('/api/v1/member/me/profile');
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = (data['name'] ?? '').toString();
        _birthCtrl.text = (data['birth_date'] ?? '').toString();
        _phoneCtrl.text = (data['phone'] ?? '').toString();
        final g = (data['gender'] ?? '').toString();
        if (g == '여') _gender = 'female';
        if (g == '남') _gender = 'male';
      });
    } catch (_) {
      // 미가입·네트워크 실패 → 빈 칸으로 시작. 입력 자체는 막지 않는다.
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _bandIndex != null &&
      _nameCtrl.text.trim().isNotEmpty &&
      // 안 적은 건 통과, 적었는데 없는 날짜면 막는다 (서버로 쓰레기 안 보냄).
      birthDateError(_birthCtrl.text) == null &&
      !_saving;

  Future<void> _onDone() async {
    final years = _kExpBands[_bandIndex!].years;
    context.read<ProfileState>().setBasic(
          gender: _gender,
          experienceYears: years,
        );
    setState(() {
      _saving = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    try {
      // 서버에 올려야 코치 PC 목록에 뜬다. 실패해도 앱은 계속 쓸 수 있어야 하므로
      // 막지 않고 안내만 남긴다 (다음에 프로필 수정에서 다시 시도 가능).
      await context.read<ApiClient>().patch('/api/v1/member/me/profile', {
        'name': _nameCtrl.text.trim(),
        'birth_date': _birthCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'gender': _gender == 'female' ? '여' : '남',
        'experience_years': years,
      });
    } catch (_) {
      if (mounted) setState(() => _error = '저장은 됐지만 박스에 전달하지 못했습니다.');
    }
    if (!mounted) return;
    setState(() => _saving = false);
    navigator.pushNamedAndRemoveUntil('/shell', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      appBar: AppBar(
        title: const Text('내 정보'),
        backgroundColor: HyphenTokens.bg,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HyphenTokens.sp5),
          children: [
            const Text(
              '코치가 회원 명단에서 보는 정보입니다.',
              style: HyphenTokens.caption,
            ),
            const SizedBox(height: HyphenTokens.sp4),
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: '이름'),
            ),
            const SizedBox(height: HyphenTokens.sp3),
            // v2.6: 숫자만 치면 하이픈이 알아서 들어간다. 8자리를 다 채우기
            // 전에는 오류를 띄우지 않는다 (타이핑 도중 빨간 글씨는 방해다).
            TextField(
              controller: _birthCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [BirthDateInputFormatter()],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: '생년월일 (선택)',
                hintText: '1995-01-01',
                errorText: birthDateError(_birthCtrl.text),
              ),
            ),
            const SizedBox(height: HyphenTokens.sp3),
            // v2.6: 생년월일과 같은 이유로 하이픈을 자동으로 넣는다 —
            // 코치 명단의 번호 표기를 한 가지로 고정한다.
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneInputFormatter()],
              decoration: const InputDecoration(
                labelText: '전화 (선택)',
                hintText: '010-0000-0000',
              ),
            ),
            const SizedBox(height: HyphenTokens.sp5),

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
            const SizedBox(height: HyphenTokens.sp5),

            const HkSectionLabel('크로스핏 경력'),
            const SizedBox(height: HyphenTokens.sp2),
            Wrap(
              spacing: HyphenTokens.sp2,
              runSpacing: HyphenTokens.sp2,
              children: [
                for (var i = 0; i < _kExpBands.length; i++)
                  HkBadge(
                    _kExpBands[i].label,
                    color: HyphenTokens.fg,
                    selected: _bandIndex == i,
                    onTap: () {
                      Haptic.selection();
                      setState(() => _bandIndex = i);
                    },
                  ),
              ],
            ),
            // v2.6 (BRIEF D36): 레벨은 경력 하나로 정해진다. 고른 구간이 어느
            // 레벨이 되는지 그 자리에서 보여준다 — 나중에 코치 화면에서 처음
            // 보게 되면 "왜 내가 스케일이냐"가 된다.
            if (_bandIndex != null) ...[
              const SizedBox(height: HyphenTokens.sp3),
              Row(
                children: [
                  const Text('내 레벨', style: HyphenTokens.caption),
                  const SizedBox(width: HyphenTokens.sp2),
                  Builder(builder: (_) {
                    final t = Tier.fromExperienceYears(
                        _kExpBands[_bandIndex!].years);
                    return HkBadge(t.memberLevelLabel, color: t.color);
                  }),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: HyphenTokens.sp3),
              Text(_error!,
                  style:
                      HyphenTokens.caption.copyWith(color: HyphenTokens.warning)),
            ],
            const SizedBox(height: HyphenTokens.sp6),
            HkButton.primary(
              _saving ? '저장 중' : '시작하기',
              onPressed: _canContinue
                  ? () {
                      Haptic.light();
                      _onDone();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
