/// Représente un utilisateur de Dart Master, indépendamment de la
/// source de données (Firebase Auth, Game Center, Play Games...).
///
/// Garder cette entité dans `domain/` sans aucun import Firebase permet
/// de changer de fournisseur d'authentification à l'avenir sans impacter
/// les écrans ni la logique métier qui consomment [AppUser].
class AppUser {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final int level;
  final int xp;
  final int coins;
  final int diamonds;
  final bool isPremium;

  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.level = 1,
    this.xp = 0,
    this.coins = 500, // Solde de bienvenue offert à l'inscription.
    this.diamonds = 10,
    this.isPremium = false,
  });

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    int? level,
    int? xp,
    int? coins,
    int? diamonds,
    bool? isPremium,
  }) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      diamonds: diamonds ?? this.diamonds,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
