import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Enregistre l'historique des points d'impact du joueur (coordonnées
/// normalisées -1..1 par rapport au centre de la cible), pour alimenter
/// la carte de précision (voir PrecisionMapScreen).
///
/// Limité aux [_maxEntries] derniers lancers pour ne pas faire grossir
/// indéfiniment le stockage local — largement suffisant pour visualiser
/// une tendance de précision sur les dernières parties.
class ThrowHistoryService {
  ThrowHistoryService._();

  static const _key = 'throw_history_impacts';
  static const _maxEntries = 300;

  static Future<void> recordImpact(double dx, double dy) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final List<dynamic> history = raw != null ? jsonDecode(raw) as List<dynamic> : [];
    history.add({'x': dx, 'y': dy});
    final trimmed = history.length > _maxEntries
        ? history.sublist(history.length - _maxEntries)
        : history;
    await prefs.setString(_key, jsonEncode(trimmed));
  }

  static Future<List<(double, double)>> loadImpacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List<dynamic> history = jsonDecode(raw) as List<dynamic>;
    return history
        .map((e) => ((e['x'] as num).toDouble(), (e['y'] as num).toDouble()))
        .toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
