import '../models/movement.dart';
import '../models/preset_wod.dart';
import 'api_client.dart';

class MovementsRepository {
  final ApiClient _api;
  List<MovementCategory>? _cache;
  List<PresetWod>? _presetsCache;

  MovementsRepository(this._api);

  Future<List<PresetWod>> fetchPresets({bool force = false}) async {
    if (_presetsCache != null && !force) return _presetsCache!;
    final list = await _api.getList('/api/v1/wods/presets');
    _presetsCache = list
        .map((e) => PresetWod.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return _presetsCache!;
  }

  Future<List<MovementCategory>> fetchCategories({bool force = false}) async {
    if (_cache != null && !force) return _cache!;
    final data = await _api.get('/api/v1/movements/categories');
    // API returns {data: [...]} and _unwrap gives back a Map,
    // but this endpoint returns a List inside data. _unwrap returns Map<>.
    // Adapt: the pacing endpoint returns Map; movements returns List.
    // We need a list variant.
    throw StateError('Use fetchCategoriesList()');
  }

  Future<List<MovementCategory>> fetchCategoriesList({bool force = false}) async {
    if (_cache != null && !force) return _cache!;
    final list = await _api.getList('/api/v1/movements/categories');
    _cache = list
        .map((e) => MovementCategory.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return _cache!;
  }

  Movement? findBySlug(String slug) {
    if (_cache == null) return null;
    for (final c in _cache!) {
      for (final m in c.movements) {
        if (m.slug == slug) return m;
      }
    }
    return null;
  }
}
