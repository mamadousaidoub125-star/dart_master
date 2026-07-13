import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Écran de paramètres : préférences d'affichage, audio, notifications,
/// et accès aux pages légales / support.
class SettingsScreen extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool musicEnabled;
  final ValueChanged<bool> onMusicToggled;
  final bool soundEffectsEnabled;
  final ValueChanged<bool> onSoundEffectsToggled;
  final bool vibrationEnabled;
  final ValueChanged<bool> onVibrationToggled;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsToggled;
  final VoidCallback onOpenPrivacyPolicy;
  final VoidCallback onOpenSupport;
  final VoidCallback onSignOut;

  const SettingsScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    required this.musicEnabled,
    required this.onMusicToggled,
    required this.soundEffectsEnabled,
    required this.onSoundEffectsToggled,
    required this.vibrationEnabled,
    required this.onVibrationToggled,
    required this.notificationsEnabled,
    required this.onNotificationsToggled,
    required this.onOpenPrivacyPolicy,
    required this.onOpenSupport,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          _sectionTitle('Affichage'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.dark, label: Text('Sombre'), icon: Icon(Icons.dark_mode)),
              ButtonSegment(value: ThemeMode.light, label: Text('Clair'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.brightness_auto)),
            ],
            selected: {currentThemeMode},
            onSelectionChanged: (set) => onThemeModeChanged(set.first),
          ),
          const SizedBox(height: 12),
          _sectionTitle('Audio & Vibration'),
          SwitchListTile(
            title: const Text('Musique', style: TextStyle(color: AppColors.white)),
            value: musicEnabled,
            activeColor: AppColors.electricBlue,
            onChanged: onMusicToggled,
          ),
          SwitchListTile(
            title: const Text('Effets sonores', style: TextStyle(color: AppColors.white)),
            value: soundEffectsEnabled,
            activeColor: AppColors.electricBlue,
            onChanged: onSoundEffectsToggled,
          ),
          SwitchListTile(
            title: const Text('Vibrations', style: TextStyle(color: AppColors.white)),
            value: vibrationEnabled,
            activeColor: AppColors.electricBlue,
            onChanged: onVibrationToggled,
          ),
          _sectionTitle('Notifications'),
          SwitchListTile(
            title: const Text('Notifications push', style: TextStyle(color: AppColors.white)),
            subtitle: const Text('Défis quotidiens, invitations, tournois', style: TextStyle(color: AppColors.lightGray)),
            value: notificationsEnabled,
            activeColor: AppColors.electricBlue,
            onChanged: onNotificationsToggled,
          ),
          _sectionTitle('À propos'),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: AppColors.lightGray),
            title: const Text('Politique de confidentialité', style: TextStyle(color: AppColors.white)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.lightGray),
            onTap: onOpenPrivacyPolicy,
          ),
          ListTile(
            leading: const Icon(Icons.support_agent, color: AppColors.lightGray),
            title: const Text('Support', style: TextStyle(color: AppColors.white)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.lightGray),
            onTap: onOpenSupport,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton(
              onPressed: onSignOut,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red)),
              child: const Text('Se déconnecter'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(title, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
      );
}
