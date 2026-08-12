import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/glossary.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../core/unit_state.dart';
import '../../widgets/fkit.dart';
import '../profile/profile_state.dart';

class OnboardingBasicScreen extends StatefulWidget {
  const OnboardingBasicScreen({super.key});

  @override
  State<OnboardingBasicScreen> createState() => _OnboardingBasicScreenState();
}

class _OnboardingBasicScreenState extends State<OnboardingBasicScreen> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _age = TextEditingController();
  final _years = TextEditingController();
  String _gender = 'male';

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileState>();
    final unit = context.read<UnitState>();
    if (p.bodyWeightKg != null) {
      final disp = unit.kgToDisplay(p.bodyWeightKg!)!;
      _weight.text = _fmt(disp);
    }
    if (p.heightCm != null) _height.text = _fmt(p.heightCm!);
    if (p.ageYears != null) _age.text = _fmt(p.ageYears!);
    if (p.experienceYears > 0) _years.text = _fmt(p.experienceYears);
    _gender = p.gender;
  }

  // QA (2026-06-11): kg↔lb 변환 raw float 노출 방지 — 표시 소수 1자리 (benchmarks 와 동일).
  String _fmt(double v) {
    final r = (v * 10).round() / 10;
    return r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    _age.dispose();
    _years.dispose();
    super.dispose();
  }

  // v1.10.1: 모든 필드 선택. 체중만 있으면 진행 가능(등급 산정 최소 기준).
  // 비우면 다음 단계에서 평균값 추론.
  // QA B-IN-7: 체중 양수+합리적 범위 검증.
  bool get _canContinue {
    final v = double.tryParse(_weight.text.trim());
    return v != null && v > 0 && v < 500;
  }

  @override
  Widget build(BuildContext context) {
    // B-1 (2026-06-10): 분모 7 동기화 (benchmarks 카테고리 6개 + basic 1).
    const progress = 1 / 7;
    const pct = 14;
    return Scaffold(
      appBar: AppBar(
        // v2.2 (H14): 앱바 제목과 바로 아래 진행 표시가 둘 다 '1 / 7 단계' 라
        // 같은 말이 두 번이었다 (CLAUDE.md R1). 진행바 쪽을 남기고 앱바를 비운다.
        // v1.21: 베타 테스터 피드백 — 체중 입력 칸에서 뒤로가기 누락. signup 으로 복귀.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/signup'),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // v1.15 P1-13: 6단계 진행률 시각화
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FacingTokens.sp4,
                FacingTokens.sp3,
                FacingTokens.sp4,
                FacingTokens.sp2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('1 / 7 단계', style: FacingTokens.caption),
                      Text('$pct%', style: FacingTokens.caption),
                    ],
                  ),
                  const SizedBox(height: FacingTokens.sp1),
                  const LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: FacingTokens.border,
                    color: FacingTokens.fg,
                  ),
                ],
              ),
            ),
            Expanded(child: Padding(
              padding: const EdgeInsets.all(FacingTokens.sp4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const SizedBox(height: FacingTokens.sp3),
              Row(
                children: const [
                  Text('신체', style: FacingTokens.sectionLabel),
                  SizedBox(width: FacingTokens.sp2),
                  TermTip(term: 'Tier', iconSize: 16),
                ],
              ),
              const SizedBox(height: FacingTokens.sp1),
              const Text(
                '체중·키는 Tier 산정 기준. 성별·경력은 난이도 보정.',
                style: FacingTokens.caption,
              ),
              const SizedBox(height: FacingTokens.sp6),
              // v2.2 (H12): 같은 폼에서 '나이·성별'은 한글인데 체중·키·경력만
              // 영문이라 언어가 섞여 있었다. 도메인 고정어(kg·cm·CrossFit)만
              // 남기고 한글로 통일한다 (v1.29 한글 기본).
              Consumer<UnitState>(
                builder: (ctx, u, _) => _Row(
                  label: '체중 (${u.weightSuffix})',
                  child: _Input(
                    controller: _weight,
                    semanticLabel: '체중',
                    hint: u.isKg ? '예: 75' : '예: 165',
                    suffix: u.weightSuffix,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(height: FacingTokens.sp4),
              _Row(label: '키 (cm)', child: _Input(
                controller: _height, hint: '예: 176', suffix: 'cm',
                semanticLabel: '키',
                onChanged: (_) => setState(() {}),
              )),
              const SizedBox(height: FacingTokens.sp4),
              _Row(label: '나이', child: _Input(
                controller: _age, hint: '예: 32', suffix: '세',
                semanticLabel: '나이',
                onChanged: (_) => setState(() {}),
              )),
              const SizedBox(height: FacingTokens.sp4),
              _Row(label: '성별', child: _GenderToggle(
                value: _gender,
                onChanged: (g) {
                  Haptic.selection();
                  setState(() => _gender = g);
                },
              )),
              const SizedBox(height: FacingTokens.sp4),
              // v2.2: 'CrossFit XP (yr)' → '크로스핏 경력 (년)'.
              // XP 는 이 앱에서 레벨 경험치를 뜻하는데 여기선 '경력 연차'라
              // 같은 낱말이 두 뜻으로 쓰여 홈 화면의 XP 와 충돌했다.
              _Row(label: '크로스핏 경력 (년)', child: _Input(
                controller: _years, hint: '예: 3',
                suffix: '년',
                semanticLabel: '크로스핏 경력',
                onChanged: (_) => setState(() {}),
              )),
              const Spacer(),
              ElevatedButton(
                onPressed: _canContinue
                    ? () {
                        Haptic.light();
                        _onNext();
                      }
                    : null,
                child: const Text('다음'),
              ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _onNext() {
    final p = context.read<ProfileState>();
    final unit = context.read<UnitState>();
    final weightDisplay = double.tryParse(_weight.text.trim());
    final heightVal = double.tryParse(_height.text.trim());
    final ageVal = double.tryParse(_age.text.trim());
    p.setBasic(
      bodyWeightKg: unit.displayToKg(weightDisplay),
      // QA B-IN-8: 신장 100~250cm, 나이 10~80 범위 외 입력은 null 처리.
      heightCm: (heightVal != null && heightVal >= 100 && heightVal <= 250)
          ? heightVal
          : null,
      ageYears: (ageVal != null && ageVal >= 10 && ageVal <= 80)
          ? ageVal
          : null,
      gender: _gender,
      experienceYears: double.tryParse(_years.text.trim()) ?? 0,
    );
    Navigator.of(context).pushNamed('/onboarding/benchmarks');
  }
}

class _Row extends StatelessWidget {
  final String label;
  final Widget child;
  const _Row({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 4, child: Text(label, style: FacingTokens.body)),
        Expanded(flex: 5, child: child),
      ],
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final String? semanticLabel;
  final ValueChanged<String> onChanged;
  const _Input({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    // v2.2 (H12): labelText 로 넣던 이름이 좌측 _Row 라벨과 **같은 말**이라
    // 한 줄에 같은 단어가 두 번 나왔다. 화면에서는 좌측 라벨 하나만 두고,
    // 스크린리더용 이름은 Semantics 로 옮긴다 (접근성 유지, 시각 중복 제거).
    return Semantics(
      label: semanticLabel,
      textField: true,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          TextInputFormatter.withFunction((oldValue, newValue) {
            final dots = '.'.allMatches(newValue.text).length;
            if (dots > 1) return oldValue;
            return newValue;
          }),
        ],
        decoration: InputDecoration(
          hintText: hint,
          suffixText: suffix.isEmpty ? null : suffix,
          isDense: true,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: FacingTokens.border),
            borderRadius: BorderRadius.circular(FacingTokens.r2),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: FacingTokens.primary, width: 2),
            borderRadius: BorderRadius.circular(FacingTokens.r2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _GenderToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _GenderToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FkBadge(
          '남',
          color: FacingTokens.fg,
          selected: value == 'male',
          onTap: () => onChanged('male'),
        ),
        const SizedBox(width: FacingTokens.sp2),
        FkBadge(
          '여',
          color: FacingTokens.fg,
          selected: value == 'female',
          onTap: () => onChanged('female'),
        ),
      ],
    );
  }
}

