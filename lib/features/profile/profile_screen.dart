import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/movements_repository.dart';
import '../../core/theme.dart';
import '../../models/movement.dart';
import 'profile_state.dart';

class ProfileScreen extends StatefulWidget {
  final bool isOnboarding;
  const ProfileScreen({super.key, this.isOnboarding = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<List<MovementCategory>>? _future;

  @override
  void initState() {
    super.initState();
    final repo = context.read<MovementsRepository>();
    _future = repo.fetchCategoriesList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: FutureBuilder<List<MovementCategory>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: Text('불러오는 중', style: FacingTokens.body));
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                child: Text('${snap.error}', style: FacingTokens.body),
              ),
            );
          }
          final cats = snap.data ?? [];
          return _ProfileForm(
            categories: cats,
            isOnboarding: widget.isOnboarding,
          );
        },
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  final List<MovementCategory> categories;
  final bool isOnboarding;
  const _ProfileForm({required this.categories, required this.isOnboarding});

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FacingTokens.sp4, FacingTokens.sp3, FacingTokens.sp4, FacingTokens.sp8,
      ),
      children: [
        const Text('체중', style: FacingTokens.h3),
        const SizedBox(height: FacingTokens.sp2),
        _NumberField(
          value: state.bodyWeightKg,
          hint: '예: 75',
          suffix: 'kg',
          onChanged: (v) => state.setBasic(bodyWeightKg: v),
        ),
        const SizedBox(height: FacingTokens.sp6),
        ...widget.categories.expand((c) => [
          Padding(
            padding: const EdgeInsets.only(bottom: FacingTokens.sp3),
            child: Text(c.nameKo, style: FacingTokens.h3),
          ),
          ...c.movements.map((m) => _MovementMaxRow(movement: m, state: state)),
          const SizedBox(height: FacingTokens.sp5),
        ]),
        if (widget.isOnboarding) ...[
          const SizedBox(height: FacingTokens.sp3),
          ElevatedButton(
            onPressed: state.isEmpty ? null : () {
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('완료'),
          ),
        ],
      ],
    );
  }
}

class _MovementMaxRow extends StatelessWidget {
  final Movement movement;
  final ProfileState state;
  const _MovementMaxRow({required this.movement, required this.state});

  @override
  Widget build(BuildContext context) {
    final metrics = movement.requiredMetrics;
    if (metrics.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: FacingTokens.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(movement.nameKo, style: FacingTokens.body.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: FacingTokens.sp1),
          ...metrics.map((metric) => Padding(
            padding: const EdgeInsets.only(top: FacingTokens.sp2),
            child: _MetricInput(
              label: _metricLabel(metric),
              suffix: _metricSuffix(metric),
              value: state.getMax(movement.slug, metric),
              onChanged: (v) => state.setMax(movement.slug, metric, v),
            ),
          )),
        ],
      ),
    );
  }

  String _metricLabel(String m) {
    switch (m) {
      case 'max_unbroken': return 'Max Unbroken';
      case 'one_rep_max': return '1RM';
      case 'max_pace_sec_per_500m': return 'Max Pace (500m)';
      default: return m;
    }
  }

  String _metricSuffix(String m) {
    switch (m) {
      case 'max_unbroken': return '회';
      case 'one_rep_max': return 'lb';
      case 'max_pace_sec_per_500m': return '초';
      default: return '';
    }
  }
}

class _MetricInput extends StatelessWidget {
  final String label;
  final String suffix;
  final double? value;
  final ValueChanged<double?> onChanged;
  const _MetricInput({
    required this.label,
    required this.suffix,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 3, child: Text(label, style: FacingTokens.caption)),
        Expanded(
          flex: 4,
          child: _NumberField(
            value: value,
            hint: '-',
            suffix: suffix,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatefulWidget {
  final double? value;
  final String hint;
  final String suffix;
  final ValueChanged<double?> onChanged;
  const _NumberField({
    required this.value,
    required this.hint,
    required this.suffix,
    required this.onChanged,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.value == null ? '' : _fmt(widget.value!),
    );
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = widget.value == null ? '' : _fmt(widget.value!);
    if (_ctrl.text != newText && !_ctrl.text.endsWith('.')) {
      _ctrl.text = newText;
    }
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        hintText: widget.hint,
        suffixText: widget.suffix.isEmpty ? null : widget.suffix,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FacingTokens.sp3, vertical: FacingTokens.sp3,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: FacingTokens.border, width: 1),
          borderRadius: BorderRadius.circular(FacingTokens.r2),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: FacingTokens.fg, width: 1),
          borderRadius: BorderRadius.circular(FacingTokens.r2),
        ),
      ),
      onChanged: (s) {
        final trimmed = s.trim();
        if (trimmed.isEmpty) {
          widget.onChanged(null);
          return;
        }
        final v = double.tryParse(trimmed);
        if (v != null) widget.onChanged(v);
      },
    );
  }
}
