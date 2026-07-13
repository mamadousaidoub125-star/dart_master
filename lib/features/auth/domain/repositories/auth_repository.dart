import '../entities/app_user.dart';

/// Contrat abstrait pour toute source d'authentification.
///
/// La Phase 2 fournit une implémentation factice ([MockAuthRepository],
/// dans le même dossier que les écrans) permettant de développer et
/// tester les écrans de connexion/inscription sans dépendre de Firebase.
/// La Phase 3 fournira [FirebaseAuthRepository] comme implémentation
/// réelle, interchangeable via l'injection de dépendances (get_it) sans
/// modifier une seule ligne des écrans de présentation.
abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signInWithEmail({required String email, required String password});

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInWithApple();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();
}
