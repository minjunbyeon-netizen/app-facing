import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/unit_state.dart';
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

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

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
  bool get _canContinue =>
      double.tryParse(_weight.text.trim()) != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('1 / 6 · BODY')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: FacingTokens.sp3),
              const Text('1RM 입력 전 · Body.', style: FacingTokens.h2),
              const SizedBox(height: FacingTokens.sp1),
              const Text(
                '체중·키는 Tier 산정 기준. 성별·경력은 난이도 보정.',
                style: FacingTokens.caption,
              ),
              const SizedBox(height: FacingTokens.sp6),
              Consumer<UnitState>(
                builder: (ctx, u, _) => _Row(
                  label: '체중 (${u.weightSuffix})',
                  child: _Input(
                    controller: _weight,
                    hint: u.isKg ? '예: 75' : '예: 165',
                    suffix: u.weightSuffix,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(height: FacingTokens.sp4),
              _Row(label: '키 (cm)', child: _Input(
                controller: _height, hint: '예: 176', suffix: 'cm',
                onChanged: (_) => setState(() {}),
              )),
              const SizedBox(height: FacingTokens.sp4),
              _Row(label: '만 나이', child: _Input(
                controller: _age, hint: '예: 32', suffix: '세',
                onChanged: (_) => setState(() {}),
              )),
              const SizedBox(height: FacingTokens.sp4),
              _Row(label: '성별', child: _GenderToggle(
                value: _gender,
                onChanged: (g) => setState(() => _gender = g),
              )),
              const SizedBox(height: FacingTokens.sp4),
              _Row(label: 'CrossFit 경력 (년)', child: _Input(
                controller: _years, hint: '예: 3',
                suffix: '년',
                onChanged: (_) => setState(() {}),
              )),
              const Spacer(),
              ElevatedButton(
                onPressed: _canContinue ? _onNext : null,
                child: const Text('다음'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNext() {
    final p = context.read<ProfileState>();
    final unit = context.read<UnitState>();
    final weightDisplay = double.tryParse(_weight.text.trim());
    p.setBasic(
      bodyWeightKg: unit.displayToKg(weightDisplay),
      heightCm: double.tryParse(_height.text.trim()),
      ageYears: double.tryParse(_age.text.trim()),
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
  final ValueChanged<String> onChanged;
  const _Input({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
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
          borderSide: const BorderSide(color: FacingTokens.fg),
          borderRadius: BorderRadius.circular(FacingTokens.r2),
        ),
      ),
      onChanged: onChanged,
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
        _Pill(
          label: '남성',
          selected: value == 'male',
          onTap: () => onChanged('male'),
        ),
        const SizedBox(width: FacingTokens.sp2),
        _Pill(
          label: '여성',
          selected: value == 'female',
          onTap: () => onChanged('female'),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FacingTokens.r4),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FacingTokens.sp4,
          vertical: FacingTokens.sp2,
        ),
        decoration: BoxDecoration(
          color: selected ? FacingTokens.fg : FacingTokens.bg,
          border: Border.all(
            color: selected ? FacingTokens.fg : FacingTokens.border,
          ),
          borderRadius: BorderRadius.circular(FacingTokens.r4),
        ),
        child: Text(
          label,
          style: FacingTokens.body.copyWith(
            color: selected ? FacingTokens.bg : FacingTokens.fg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
