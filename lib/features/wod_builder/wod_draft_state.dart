import 'package:flutter/foundation.dart';

import '../../models/movement.dart';
import '../../models/preset_wod.dart';

class WodItemDraft {
  final Movement movement;
  int? reps;
  int? distanceM;
  double? loadValue;
  String loadUnit;

  WodItemDraft({
    required this.movement,
    this.reps,
    this.distanceM,
    this.loadValue,
    this.loadUnit = 'lb',
  });

  Map<String, dynamic> toApiJson() {
    final m = <String, dynamic>{'movement_slug': movement.slug};
    if (reps != null) m['reps'] = reps;
    if (distanceM != null) m['distance_m'] = distanceM;
    if (loadValue != null) {
      m['load_value'] = loadValue;
      m['load_unit'] = loadUnit;
    }
    return m;
  }

  String get summary {
    final parts = <String>[];
    if (distanceM != null) parts.add('${distanceM}m');
    if (reps != null) parts.add('$reps회');
    if (loadValue != null) parts.add('${loadValue!.toStringAsFixed(0)}$loadUnit');
    return parts.join(' · ');
  }
}

enum WodType { forTime, amrap, emom }

extension WodTypeX on WodType {
  String get slug {
    switch (this) {
      case WodType.forTime: return 'for_time';
      case WodType.amrap: return 'amrap';
      case WodType.emom: return 'emom';
    }
  }

  String get labelKo {
    switch (this) {
      case WodType.forTime: return 'For Time';
      case WodType.amrap: return 'AMRAP';
      case WodType.emom: return 'EMOM';
    }
  }
}

class WodDraftState extends ChangeNotifier {
  WodType _type = WodType.forTime;
  int? _timeCapSec;
  int? _rounds;
  final List<WodItemDraft> _items = [];

  WodType get type => _type;
  int? get timeCapSec => _timeCapSec;
  int? get rounds => _rounds;
  List<WodItemDraft> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  void setType(WodType t) {
    _type = t;
    notifyListeners();
  }

  void setTimeCap(int? sec) {
    _timeCapSec = sec;
    notifyListeners();
  }

  void setRounds(int? r) {
    _rounds = r;
    notifyListeners();
  }

  void addItem(WodItemDraft item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItemAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _timeCapSec = null;
    _rounds = null;
    _type = WodType.forTime;
    _presetSlug = null;
    _presetNameKo = null;
    notifyListeners();
  }

  String? _presetSlug;
  String? _presetNameKo;
  String? get presetSlug => _presetSlug;
  String? get presetNameKo => _presetNameKo;

  void loadFromPreset(PresetWod preset, Map<String, Movement> movementBySlug) {
    _items.clear();
    _presetSlug = preset.slug;
    _presetNameKo = preset.nameKo;
    _type = WodType.values.firstWhere(
      (t) => t.slug == preset.wodType,
      orElse: () => WodType.forTime,
    );
    _timeCapSec = preset.timeCapSec;
    _rounds = preset.rounds;
    for (final item in preset.items) {
      final mv = movementBySlug[item.movementSlug];
      if (mv == null) continue;
      _items.add(WodItemDraft(
        movement: mv,
        reps: item.reps,
        distanceM: item.distanceM,
        loadValue: item.loadValue,
        loadUnit: item.loadUnit.isEmpty ? 'lb' : item.loadUnit,
      ));
    }
    notifyListeners();
  }

  Map<String, dynamic> toApiJson() {
    return {
      'wod_type': _type.slug,
      if (_timeCapSec != null) 'time_cap_sec': _timeCapSec,
      if (_rounds != null) 'rounds': _rounds,
      'items': _items.map((e) => e.toApiJson()).toList(),
    };
  }
}
