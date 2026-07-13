import 'dart:async';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implémentation factice (mock) de [AuthRepository].
///
/// ⚠️ À REMPLACER en Phase 3 par `FirebaseAuthRepository`, qui
/// implémentera exactement la même interface via `firebase_auth`.
/// Utile pour développer/tester l'UI sans connexion réseau ni projet
/// Firebase configuré.
class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<AppUser> signInWithEmail({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simule la latence réseau.
    final user = AppUser(id: 'mock-${email.hashCode}', displayName: email.split('@').first, email: email);
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final user = AppUser(id: 'mock-${email.hashCode}', displayName: displayName, email: email);
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final user = const AppUser(id: 'mock-google', displayName: 'Joueur Google', email: 'joueur@gmail.com');
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signInWithApple() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final user = const AppUser(id: 'mock-apple', displayName: 'Joueur Apple', email: 'joueur@icloud.com');
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
}
