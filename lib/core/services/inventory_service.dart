import 'package:shared_preferences/shared_preferences.dart';

/// Gère la persistance locale des objets cosmétiques débloqués
/// (haches et planches achetées avec les pièces/diamants gagnés en
/// jouant, ou débloquées gratuitement en regardant une publicité).
///
/// NOTE (Phase 3) : une fois Firebase connecté, cet inventaire devra être
/// stocké dans Firestore (`inventories/{userId}`, voir SCHEMA.md) plutôt
/// que localement, pour survivre à un changement d'appareil.
class InventoryService {
  InventoryService._();

  static const _keyUnlockedAxes = 'inventory_unlocked_axes';
  static const _keyUnlockedBoards = 'inventory_unlocked_boards';
  static const _keyEquippedAxe = 'inventory_equipped_axe';
  static const _keyEquippedBoard = 'inventory_equipped_board';

  // --- Haches ---
  static Future<Set<String>> loadUnlockedAxes() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyUnlockedAxes) ?? const []).toSet();
  }

  static Future<void> unlockAxe(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_keyUnlockedAxes) ?? const []).toSet();
    current.add(productId);
    await prefs.setStringList(_keyUnlockedAxes, current.toList());
  }

  static Future<String?> loadEquippedAxe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEquippedAxe);
  }

  static Future<void> setEquippedAxe(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEquippedAxe, productId);
  }

  // --- Planches / cibles ---
  static Future<Set<String>> loadUnlockedBoards() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyUnlockedBoards) ?? const []).toSet();
  }

  static Future<void> unlockBoard(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_keyUnlockedBoards) ?? const []).toSet();
    current.add(productId);
    await prefs.setStringList(_keyUnlockedBoards, current.toList());
  }

  static Future<String?> loadEquippedBoard() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEquippedBoard);
  }

  static Future<void> setEquippedBoard(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEquippedBoard, productId);
  }
}
