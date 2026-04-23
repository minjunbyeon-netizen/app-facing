import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileState extends ChangeNotifier {
  static const _kBody = 'profile_body_weight_kg';
  static const _kHeight = 'profile_height_cm';
  static const _kAge = 'profile_age_years';
  static const _kGender = 'profile_gender';
  static const _kExp = 'profile_experience_years';
  static const _kBenchmarks = 'profile_benchmarks_json';
  static const _kGrade = 'profile_grade_json';
  static const _kMaxes = 'profile_max_records_json';

  double? _bodyWeightKg;
  double? _heightCm;
  double? _ageYears;
  String _gender = 'male';
  double _experienceYears = 0;

  final Map<String, double> _benchmarks = {};
  Map<String, dynamic>? _gradeResult;
  final Map<String, Map<String, double>> _maxRecords = {};

  bool _loaded = false;

  double? get bodyWeightKg => _bodyWeightKg;
  double? get heightCm => _heightCm;
  double? get ageYears => _ageYears;
  String get gender => _gender;
  double get experienceYears => _experienceYears;
  Map<String, double> get benchmarks => _benchmarks;
  Map<String, dynamic>? get gradeResult => _gradeResult;
  Map<String, Map<String, double>> get maxRecords => _maxRecords;
  bool get isLoaded => _loaded;

  bool get hasGrade => _gradeResult != null &&
      _gradeResult!['overall'] != null;

  bool get isEmpty =>
      _bodyWeightKg == null && _benchmarks.isEmpty && _maxRecords.isEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _bodyWeightKg = prefs.getDouble(_kBody);
    _heightCm = prefs.getDouble(_kHeight);
    _ageYears = prefs.getDouble(_kAge);
    _gender = prefs.getString(_kGender) ?? 'male';
    _experienceYears = prefs.getDouble(_kExp) ?? 0;

    _benchmarks.clear();
    final bRaw = prefs.getString(_kBenchmarks);
    if (bRaw != null && bRaw.isNotEmpty) {
      try {
        final m = jsonDecode(bRaw) as Map<String, dynamic>;
        m.forEach((k, v) => _benchmarks[k] = (v as num).toDouble());
      } catch (_) {}
    }

    final gRaw = prefs.getString(_kGrade);
    if (gRaw != null && gRaw.isNotEmpty) {
      try {
        _gradeResult = jsonDecode(gRaw) as Map<String, dynamic>;
      } catch (_) {}
    }

    _maxRecords.clear();
    final mRaw = prefs.getString(_kMaxes);
    if (mRaw != null && mRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(mRaw) as Map<String, dynamic>;
        decoded.forEach((slug, v) {
          final inner = Map<String, dynamic>.from(v as Map);
          _maxRecords[slug] = inner.map(
            (k, val) => MapEntry(k, (val as num).toDouble()),
          );
        });
      } catch (_) {}
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (_bodyWeightKg != null) {
      await prefs.setDouble(_kBody, _bodyWeightKg!);
    } else {
      await prefs.remove(_kBody);
    }
    if (_heightCm != null) {
      await prefs.setDouble(_kHeight, _heightCm!);
    } else {
      await prefs.remove(_kHeight);
    }
    if (_ageYears != null) {
      await prefs.setDouble(_kAge, _ageYears!);
    } else {
      await prefs.remove(_kAge);
    }
    await prefs.setString(_kGender, _gender);
    await prefs.setDouble(_kExp, _experienceYears);
    await prefs.setString(_kBenchmarks, jsonEncode(_benchmarks));
    if (_gradeResult != null) {
      await prefs.setString(_kGrade, jsonEncode(_gradeResult));
    } else {
      await prefs.remove(_kGrade);
    }
    await prefs.setString(_kMaxes, jsonEncode(_maxRecords));
  }

  // ---- mutation ----
  void setBasic({
    double? bodyWeightKg,
    double? heightCm,
    double? ageYears,
    String? gender,
    double? experienceYears,
  }) {
    if (bodyWeightKg != null) _bodyWeightKg = bodyWeightKg;
    if (heightCm != null) _heightCm = heightCm;
    if (ageYears != null) _ageYears = ageYears;
    if (gender != null) _gender = gender;
    if (experienceYears != null) _experienceYears = experienceYears;
    _save();
    notifyListeners();
  }

  void setBenchmark(String key, double? value) {
    if (value == null || value <= 0) {
      _benchmarks.remove(key);
    } else {
      _benchmarks[key] = value;
    }
    _save();
    notifyListeners();
  }

  double? getBenchmark(String key) => _benchmarks[key];

  void setGradeResult(Map<String, dynamic>? result) {
    _gradeResult = result;
    _save();
    notifyListeners();
  }

  // Legacy max records (per-movement) still supported for the builder flow.
  double? getMax(String movementSlug, String metricType) {
    return _maxRecords[movementSlug]?[metricType];
  }

  void setMax(String movementSlug, String metricType, double? value) {
    _maxRecords.putIfAbsent(movementSlug, () => <String, double>{});
    if (value == null) {
      _maxRecords[movementSlug]!.remove(metricType);
      if (_maxRecords[movementSlug]!.isEmpty) {
        _maxRecords.remove(movementSlug);
      }
    } else {
      _maxRecords[movementSlug]![metricType] = value;
    }
    _save();
    notifyListeners();
  }

  /// Build `profile_overrides` for calculate API.
  /// Merges benchmark-derived maxes with any explicit per-movement maxes.
  Map<String, dynamic> toOverrides() {
    final out = <String, Map<String, double>>{};
    if (_benchmarks['back_squat_1rm_lb'] != null) {
      out.putIfAbsent('back_squat', () => {})['one_rep_max'] =
          _benchmarks['back_squat_1rm_lb']!;
    }
    if (_benchmarks['deadlift_1rm_lb'] != null) {
      out.putIfAbsent('deadlift', () => {})['one_rep_max'] =
          _benchmarks['deadlift_1rm_lb']!;
    }
    if (_benchmarks['front_squat_1rm_lb'] != null) {
      out.putIfAbsent('front_squat', () => {})['one_rep_max'] =
          _benchmarks['front_squat_1rm_lb']!;
    }
    if (_benchmarks['pull_up_max_ub'] != null) {
      out.putIfAbsent('pull_up', () => {})['max_unbroken'] =
          _benchmarks['pull_up_max_ub']!;
    }
    if (_benchmarks['toes_to_bar_max_ub'] != null) {
      out.putIfAbsent('toes_to_bar', () => {})['max_unbroken'] =
          _benchmarks['toes_to_bar_max_ub']!;
    }
    if (_benchmarks['run_mile_sec'] != null) {
      // mile 1609m -> pace / 500m = mile_sec * 500 / 1609
      final pace = _benchmarks['run_mile_sec']! * 500 / 1609;
      out.putIfAbsent('run', () => {})['max_pace_sec_per_500m'] = pace;
    }
    if (_benchmarks['row_500m_sec'] != null) {
      out.putIfAbsent('row', () => {})['max_pace_sec_per_500m'] =
          _benchmarks['row_500m_sec']!;
    }
    // Merge any manual maxRecords on top (explicit > derived).
    _maxRecords.forEach((slug, metrics) {
      out.putIfAbsent(slug, () => {}).addAll(metrics);
    });
    return out.map((k, v) => MapEntry(k, v.map((k2, v2) => MapEntry(k2, v2))));
  }

  String? get overallGrade {
    final g = _gradeResult;
    if (g == null) return null;
    return g['overall']?.toString();
  }

  String? get overallGradeLabelKo {
    return _gradeResult?['overall_label_ko']?.toString();
  }

  Map<String, dynamic> toGradePayload() {
    return {
      'body_weight_kg': _bodyWeightKg,
      'height_cm': _heightCm,
      'age_years': _ageYears,
      'gender': _gender,
      'experience_years': _experienceYears,
      ..._benchmarks,
    };
  }
}
