import 'package:shared_preferences/shared_preferences.dart';

/// Gère la persistance locale des préférences de l'application
/// (musique, effets sonores, vibrations, notifications).
///
/// Comme [SessionService], ces préférences sont sauvegardées localement
/// via SharedPreferences dès qu'elles sont modifiées, pour être
/// automatiquement restaurées au prochain lancement de l'app.
class SettingsService {
  SettingsService._();

  static const _keyMusic = 'settings_music_enabled';
  static const _keySoundEffects = 'settings_sound_effects_enabled';
  static const _keyVibration = 'settings_vibration_enabled';
  static const _keyNotifications = 'settings_notifications_enabled';

  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      musicEnabled: prefs.getBool(_keyMusic) ?? true,
      soundEffectsEnabled: prefs.getBool(_keySoundEffects) ?? true,
      vibrationEnabled: prefs.getBool(_keyVibration) ?? true,
      notificationsEnabled: prefs.getBool(_keyNotifications) ?? true,
    );
  }

  static Future<void> setMusicEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMusic, value);
  }

  static Future<void> setSoundEffectsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEffects, value);
  }

  static Future<void> setVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibration, value);
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }
}

/// Regroupe l'ensemble des préférences de l'application.
class AppSettings {
  final bool musicEnabled;
  final bool soundEffectsEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;

  const AppSettings({
    required this.musicEnabled,
    required this.soundEffectsEnabled,
    required this.vibrationEnabled,
    required this.notificationsEnabled,
  });

  AppSettings copyWith({
    bool? musicEnabled,
    bool? soundEffectsEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
