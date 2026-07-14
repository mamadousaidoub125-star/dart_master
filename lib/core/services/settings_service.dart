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
  static const _keyMusicTrack = 'settings_music_track';

  /// Catalogue des musiques de fond disponibles (nom de fichier dans
  /// assets/audio/ associé à un nom affichable dans l'interface).
  static const List<MapEntry<String, String>> availableTracks = [
    MapEntry('music_viking_march.wav', 'Marche Viking'),
    MapEntry('music_tavern_calm.wav', 'Taverne calme'),
    MapEntry('music_victory_fanfare.wav', 'Fanfare de victoire'),
    MapEntry('music_tension.wav', 'Suspense'),
    MapEntry('music_festive.wav', 'Festif'),
  ];

  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      musicEnabled: prefs.getBool(_keyMusic) ?? true,
      soundEffectsEnabled: prefs.getBool(_keySoundEffects) ?? true,
      vibrationEnabled: prefs.getBool(_keyVibration) ?? true,
      notificationsEnabled: prefs.getBool(_keyNotifications) ?? true,
      musicTrack: prefs.getString(_keyMusicTrack) ?? availableTracks.first.key,
    );
  }

  static Future<void> setMusicTrack(String filename) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMusicTrack, filename);
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
  final String musicTrack;

  const AppSettings({
    required this.musicEnabled,
    required this.soundEffectsEnabled,
    required this.vibrationEnabled,
    required this.notificationsEnabled,
    this.musicTrack = 'music_viking_march.wav',
  });

  AppSettings copyWith({
    bool? musicEnabled,
    bool? soundEffectsEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    String? musicTrack,
  }) {
    return AppSettings(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      musicTrack: musicTrack ?? this.musicTrack,
    );
  }
}
