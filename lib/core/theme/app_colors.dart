import 'package:flutter/material.dart';

/// Palette de couleurs officielle de Dart Master.
///
/// Toutes les couleurs de l'application doivent provenir de cette classe
/// afin de garantir une cohérence visuelle totale entre les écrans
/// et de faciliter la maintenance (un seul point de modification).
class AppColors {
  AppColors._(); // Empêche l'instanciation, classe purement statique.

  // --- Couleurs de marque ---
  static const Color midnightBlue = Color(0xFF0F172A);   // Bleu nuit - fond principal
  static const Color electricBlue = Color(0xFF2563EB);   // Bleu électrique - actions primaires
  static const Color red = Color(0xFFDC2626);            // Rouge - alertes, IA difficile, défaite
  static const Color green = Color(0xFF16A34A);          // Vert - succès, victoire, validation
  static const Color gold = Color(0xFFFBBF24);           // Or - récompenses, monnaie premium
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFE5E7EB);
  static const Color black = Color(0xFF000000);

  // --- Couleurs dérivées pour le mode sombre ---
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceElevated = Color(0xFF334155);
  static const Color darkTextPrimary = white;
  static const Color darkTextSecondary = lightGray;

  // --- Couleurs dérivées pour le mode clair ---
  static const Color lightSurface = white;
  static const Color lightSurfaceElevated = Color(0xFFF9FAFB);
  static const Color lightTextPrimary = midnightBlue;
  static const Color lightTextSecondary = Color(0xFF64748B);

  // --- Dégradés utilisés dans les boutons et cartes premium ---
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient electricGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Couleur associée à chaque niveau de difficulté de l'IA,
  /// utilisée pour les badges de sélection de mode de jeu.
  static Color forAiDifficulty(String difficulty) {
    switch (difficulty) {
      case 'facile':
        return green;
      case 'moyenne':
        return electricBlue;
      case 'difficile':
        return gold;
      case 'experte':
        return red;
      default:
        return electricBlue;
    }
  }
}
