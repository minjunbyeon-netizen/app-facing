// v1.22: 코치(owner) 전용 — 체육관 부가정보 편집 화면.
// 전화·코치이름·약력·수업시간·모토·인스타 6 필드. 저장 시 PATCH /api/v1/gyms/{id}/profile.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import 'gym_state.dart';

class GymProfileEditScreen extends StatefulWidget {
  const GymProfileEditScreen({super.key});

  @override
  State<GymProfileEditScreen> createState() => _GymProfileEditScreenState();
}

class _GymProfileEditScreenState extends State<GymProfileEditScreen> {
  late final TextEditingController _phone;
  late final TextEditingController _coachName;
  late final TextEditingController _coachBio;
  late final TextEditingController _classSchedule;
  late final TextEditingController _motto;
  late final TextEditingController _instagram;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<GymState>().membership.gym?.profile;
    _phone = TextEditingController(text: p?.phone ?? '');
    _coachName = TextEditingController(text: p?.coachName ?? '');
    _coachBio = TextEditingController(text: p?.coachBio ?? '');
    _classSchedule = TextEditingController(text: p?.classSchedule ?? '');
    _motto = TextEditingController(text: p?.motto ?? '');
    _instagram = TextEditingController(text: p?.instagram ?? '');
  }

  @override
  void dispose() {
    _phone.dispose();
    _coachName.dispose();
    _coachBio.dispose();
    _classSchedule.dispose();
    _motto.dispose();
    _instagram.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    Haptic.medium();
    final gs = context.read<GymState>();
    final ok = await gs.updateGymProfile(
      phone: _phone.text.trim(),
      coachName: _coachName.text.trim(),
      coachBio: _coachBio.text.trim(),
      classSchedule: _classSchedule.text.trim(),
      motto: _motto.text.trim(),
      instagram: _instagram.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 저장 완료.')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(gs.error ?? 'Save failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gym = context.watch<GymState>().membership.gym;
    return Scaffold(
      appBar: AppBar(
        title: const Text('체육관 프로필 수정'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: HyphenTokens.fg, strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: SafeArea(
        child: gym == null
            ? const Center(
                child: Text('체육관 정보 없음.', style: HyphenTokens.caption),
              )
            : ListView(
                padding: const EdgeInsets.all(HyphenTokens.sp4),
                children: [
                  Text(gym.name,
                      style: HyphenTokens.h3
                          .copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: HyphenTokens.sp1),
                  Text(gym.location, style: HyphenTokens.caption),
                  const SizedBox(height: HyphenTokens.sp5),
                  _Field(
                    label: '전화',
                    controller: _phone,
                    hint: '02-1234-5678',
                    keyboardType: TextInputType.phone,
                  ),
                  _Field(
                    label: '코치 이름',
                    controller: _coachName,
                    hint: '박지훈',
                  ),
                  _Field(
                    label: '코치 소개',
                    controller: _coachBio,
                    hint: '지도자 자격 · 경력 9년 · 올림픽 리프팅 전문',
                    maxLines: 3,
                  ),
                  _Field(
                    label: '수업 시간표',
                    controller: _classSchedule,
                    hint:
                        '평일  06:00 · 07:00 · 18:30 · 19:30\n주말  09:00 · 10:00',
                    maxLines: 4,
                  ),
                  _Field(
                    label: '모토',
                    controller: _motto,
                    hint: 'Earn it.',
                  ),
                  _Field(
                    label: '인스타그램',
                    controller: _instagram,
                    hint: '@hyphen.seongsu',
                  ),
                  const SizedBox(height: HyphenTokens.sp5),
                  Text(
                    '저장하면 NOTICE 탭과 공지 화면 상단 카드에 바로 반영돼요.',
                    style: HyphenTokens.caption,
                  ),
                ],
              ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HyphenTokens.sectionLabel),
          const SizedBox(height: HyphenTokens.sp1),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: HyphenTokens.body,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  HyphenTokens.body.copyWith(color: HyphenTokens.muted),
              filled: true,
              fillColor: HyphenTokens.bg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: HyphenTokens.sp3,
                vertical: HyphenTokens.sp3,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(HyphenTokens.r2),
                borderSide: const BorderSide(color: HyphenTokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(HyphenTokens.r2),
                borderSide: const BorderSide(color: HyphenTokens.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
