import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../widgets/fkit.dart';
import '../profile/profile_state.dart';

/// 가입 직후 한 번 묻는 화면 — 성별과 경력 두 가지가 전부다.
///
/// v2.3 (2026-08-12 사용자 지시): 체중·키·나이와 6단계 벤치마크(운동 능력)를
/// 전부 뺐다. 이 앱은 HYPHEN 한 박스에서 예약·공지를 주고받는 것이 본업이라,
/// 가입하자마자 7단계 측정을 시키는 것이 앞을 막고 있었다.
///
/// 뺀 값들은 화면에서 사라진 것이지 코드가 사라진 것은 아니다 — 프로필 편집의
/// 신체·벤치마크 화면(`/onboarding/benchmarks`)은 그대로 살아 있고, Tier 를
/// 다시 쓰려면 그 진입점만 열면 된다 ("숨김 = 코드 보존").
class OnboardingBasicScreen extends StatefulWidget {
  const OnboardingBasicScreen({super.key});

  @override
  State<OnboardingBasicScreen> createState() => _OnboardingBasicScreenState();
}

/// 경력 구간. 사용자가 말한 경계(1년·3년)를 그대로 쓰되 서로 겹치지 않게 나눴다.
/// `years` 는 서버·등급 로직이 쓰는 대표값이다.
class _ExpBand {
  final String label;
  final double years;
  const _ExpBand(this.label, this.years);
}

const List<_ExpBand> _kExpBands = [
  _ExpBand('1년 미만', 0.5),
  _ExpBand('1~3년', 2),
  _ExpBand('3년 이상', 5),
];

class _OnboardingBasicScreenState extends State<OnboardingBasicScreen> {
  String _gender = 'male';
  int? _bandIndex;

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
  }

  bool get _canContinue => _bandIndex != null;

  void _onDone() {
    final p = context.read<ProfileState>();
    p.setBasic(
      gender: _gender,
      experienceYears: _kExpBands[_bandIndex!].years,
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/shell', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      appBar: AppBar(
        title: const Text('기본 정보'),
        backgroundColor: FacingTokens.bg,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FacingTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: FacingTokens.sp2),
              const FkSectionLabel('성별'),
              const SizedBox(height: FacingTokens.sp2),
              Row(
                children: [
                  FkBadge(
                    '남',
                    color: FacingTokens.fg,
                    selected: _gender == 'male',
                    onTap: () {
                      Haptic.selection();
                      setState(() => _gender = 'male');
                    },
                  ),
                  const SizedBox(width: FacingTokens.sp2),
                  FkBadge(
                    '여',
                    color: FacingTokens.fg,
                    selected: _gender == 'female',
                    onTap: () {
                      Haptic.selection();
                      setState(() => _gender = 'female');
                    },
                  ),
                ],
              ),
              const SizedBox(height: FacingTokens.sp6),

              const FkSectionLabel('크로스핏 경력'),
              const SizedBox(height: FacingTokens.sp2),
              Wrap(
                spacing: FacingTokens.sp2,
                runSpacing: FacingTokens.sp2,
                children: [
                  for (var i = 0; i < _kExpBands.length; i++)
                    FkBadge(
                      _kExpBands[i].label,
                      color: FacingTokens.fg,
                      selected: _bandIndex == i,
                      onTap: () {
                        Haptic.selection();
                        setState(() => _bandIndex = i);
                      },
                    ),
                ],
              ),
              // v2.6 (2026-08-12 사용자 지시 · BRIEF D36): 레벨은 경력 하나로
              // 정해진다. 고른 구간이 어느 레벨이 되는지 그 자리에서 보여준다 —
              // 나중에 코치 화면에서 처음 보게 되면 "왜 내가 스케일이냐"가 된다.
              if (_bandIndex != null) ...[
                const SizedBox(height: FacingTokens.sp3),
                Row(
                  children: [
                    const Text('내 레벨', style: FacingTokens.caption),
                    const SizedBox(width: FacingTokens.sp2),
                    Builder(builder: (_) {
                      final t = Tier.fromExperienceYears(
                          _kExpBands[_bandIndex!].years);
                      return FkBadge(t.memberLevelLabel, color: t.color);
                    }),
                  ],
                ),
              ],

              const Spacer(),
              FkButton.primary(
                '시작하기',
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
      ),
    );
  }
}
