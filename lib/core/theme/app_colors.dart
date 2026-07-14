import 'package:flutter/material.dart';

/// Palette de couleurs officielle de Dart Master — édition "Premium Dark".
///
/// Toutes les couleurs de l'application doivent provenir de cette classe
/// afin de garantir une cohérence visuelle totale entre les écrans
/// et de faciliter la maintenance (un seul point de modification).
///
/// NOTE : le nom historique `electricBlue` est conservé pour éviter de
/// modifier des dizaines de fichiers, mais sa VALEUR a été mise à jour
/// vers le rouge premium demandé (couleur principale de la marque).
class AppColors {
  AppColors._(); // Empêche l'instanciation, classe purement statique.

  // --- Couleurs de marque (palette "Premium Dark") ---
  static const Color midnightBlue = Color(0xFF0B0B0D);   // Fond principal, quasi-noir
  static const Color electricBlue = Color(0xFFD62828);   // Rouge premium - actions primaires
  static const Color red = Color(0xFFD62828);            // Rouge - erreurs, alertes, IA experte
  static const Color green = Color(0xFF2ECC71);          // Vert - succès, victoire, validation
  static const Color gold = Color(0xFFF5B041);           // Or - récompenses, accent premium
  static const Color orange = Color(0xFFFF7A1A);         // Orange - palier intermédiaire (IA difficile)
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFB4B7C1);
  static const Color black = Color(0xFF000000);

  // --- Couleurs dérivées pour le mode sombre ---
  static const Color darkSurface = Color(0xFF181A20);
  static const Color darkSurfaceElevated = Color(0xFF23252C);
  static const Color darkTextPrimary = white;
  static const Color darkTextSecondary = lightGray;

  // --- Couleurs dérivées pour le mode clair ---
  static const Color lightSurface = white;
  static const Color lightSurfaceElevated = Color(0xFFF9FAFB);
  static const Color lightTextPrimary = Color(0xFF0B0B0D);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // --- Dégradés utilisés dans les boutons et cartes premium ---
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF5B041), Color(0xFFD68910)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient electricGradient = LinearGradient(
    colors: [Color(0xFFD62828), Color(0xFF9E1B1B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF1E9E58)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Lueur néon à utiliser derrière les boutons/cartes premium (glow doux).
  static List<BoxShadow> neonGlow(Color color, {double intensity = 0.45}) => [
        BoxShadow(color: color.withOpacity(intensity), blurRadius: 24, spreadRadius: 1),
        BoxShadow(color: color.withOpacity(intensity * 0.5), blurRadius: 48, spreadRadius: 4),
      ];

  /// Couleur associée à chaque niveau de difficulté de l'IA,
  /// utilisée pour les badges de sélection de mode de jeu.
  static Color forAiDifficulty(String difficulty) {
    switch (difficulty) {
      case 'facile':
        return green;
      case 'moyenne':
        return gold;
      case 'difficile':
        return orange;
      case 'experte':
        return red;
      default:
        return gold;
    }
  }
}
