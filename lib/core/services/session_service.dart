import 'package:shared_preferences/shared_preferences.dart';

/// Gère la persistance locale de la session utilisateur.
///
/// Sans ce service, l'application redemanderait une connexion à chaque
/// redémarrage, ce qui est une très mauvaise expérience utilisateur.
/// Ici, dès qu'un joueur se connecte ou s'inscrit avec succès, ses
/// identifiants de session sont sauvegardés localement (via
/// SharedPreferences) et relus au prochain lancement de l'app pour
/// sauter directement l'écran de connexion. La session n'est effacée
/// que lorsque le joueur appuie explicitement sur "Se déconnecter".
class SessionService {
  SessionService._();

  static const _keyUserId = 'session_user_id';
  static const _keyDisplayName = 'session_display_name';
  static const _keyEmail = 'session_email';
  static const _keyCoins = 'session_coins';
  static const _keyXp = 'session_xp';

  static Future<void> saveXp(int xp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyXp, xp);
  }

  static Future<int> loadXp({int defaultValue = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyXp) ?? defaultValue;
  }

  /// Sauvegarde le solde de pièces actuel du joueur (gagné en jouant,
  /// dépensé dans la boutique). Séparé de saveSession() pour pouvoir être
  /// mis à jour fréquemment sans re-sauvegarder toute la session.
  static Future<void> saveCoins(int coins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCoins, coins);
  }

  static Future<int> loadCoins({int defaultValue = 500}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCoins) ?? defaultValue;
  }

  /// Sauvegarde la session après une connexion/inscription réussie.
  static Future<void> saveSession({
    required String userId,
    required String displayName,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyDisplayName, displayName);
    await prefs.setString(_keyEmail, email);
  }

  /// Retourne la session sauvegardée, ou `null` si aucun joueur n'est
  /// resté connecté (première ouverture, ou déconnexion explicite).
  static Future<Map<String, String>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    final displayName = prefs.getString(_keyDisplayName);
    final email = prefs.getString(_keyEmail);
    if (userId == null || displayName == null || email == null) return null;
    return {'userId': userId, 'displayName': displayName, 'email': email};
  }

  /// Efface la session locale. Appelé uniquement lors d'une déconnexion
  /// explicite demandée par le joueur (bouton "Se déconnecter").
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyDisplayName);
    await prefs.remove(_keyEmail);
  }
}
