// v1.16 Sprint 13: 엘리트 선수 롤모델 프리셋.
// ⚠️ 가상 데이터 — 공개 인터뷰·HWPO 프로그램 기반 큐레이션. 선수 실명은 공개 브랜드 인용.

import 'package:shared_preferences/shared_preferences.dart';

class Athlete {
  final String id;
  final String name;
  final String tier;
  final String philosophy;
  final String signatureWod;
  const Athlete({
    required this.id,
    required this.name,
    required this.tier,
    required this.philosophy,
    required this.signatureWod,
  });
}

const List<Athlete> kAthletes = [
  Athlete(
    id: 'mat_fraser',
    name: 'Mat Fraser',
    tier: 'Games Champion · 2016-20',
    philosophy: 'Hard work pays off. HWPO.',
    signatureWod:
        'MURPH · 1 mile Run → 100 Pull-ups → 200 Push-ups → 300 Air Squats → 1 mile Run',
  ),
  Athlete(
    id: 'rich_froning',
    name: 'Rich Froning Jr.',
    tier: 'Games Champion · 2011-14, Team 2015-23',
    philosophy: 'Do the work. Every day.',
    signatureWod:
        'FRONING · 5 Rounds: 200m Run / 10 DB Snatch 70lb / 10 Pull-ups',
  ),
  Athlete(
    id: 'tia_toomey',
    name: 'Tia-Clair Toomey',
    tier: 'Games Champion · 2017-22, 2024',
    philosophy: 'Impossible isn\'t far.',
    signatureWod:
        'TIA · 21-18-15-12-9-6-3: Thruster 65lb + C2B Pull-up',
  ),
  Athlete(
    id: 'ben_bergeron',
    name: 'Ben Bergeron (Coach)',
    tier: 'CompTrain · CrossFit Mayhem coach',
    philosophy: 'Character over performance.',
    signatureWod:
        'COMPTRAIN DAILY · 10min AMRAP Engine + 1RM Strength + Skill',
  ),
  Athlete(
    id: 'camille_lb',
    name: 'Camille Leblanc-Bazinet',
    tier: 'Games Champion · 2014',
    philosophy: 'Train smart, rest hard.',
    signatureWod:
        'CAMILLE · 21-15-9: Thruster 95/65 + Ring Muscle-Up',
  ),
];

class FavoriteAthleteStore {
  static const _key = 'favorite_athlete_id_v1';

  static Future<Athlete?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_key);
    if (id == null) return null;
    for (final a in kAthletes) {
      if (a.id == id) return a;
    }
    return null;
  }

  static Future<void> set(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
