import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implémentation réelle de [AuthRepository] basée sur Firebase Auth
/// et Cloud Firestore (pour les champs de progression : niveau, XP,
/// pièces, diamants, qui ne sont pas stockés par Firebase Auth lui-même).
///
/// Remplace [MockAuthRepository] une fois le projet Firebase configuré
/// (voir GUIDE_INSTALLATION.md pour la configuration de
/// google-services.json / GoogleService-Info.plist).
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _loadOrCreateUserProfile(firebaseUser);
    });
  }

  @override
  Future<AppUser> signInWithEmail({required String email, required String password}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    return _loadOrCreateUserProfile(credential.user!);
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    await credential.user!.updateDisplayName(displayName);
    return _loadOrCreateUserProfile(credential.user!, initialDisplayName: displayName);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Connexion Google annulée par l\'utilisateur');
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    return _loadOrCreateUserProfile(userCredential.user!);
  }

  @override
  Future<AppUser> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    final oAuthCredential = fb.OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(oAuthCredential);
    return _loadOrCreateUserProfile(userCredential.user!);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  /// Charge le document Firestore `users/{uid}` correspondant à
  /// l'utilisateur Firebase Auth connecté, ou le crée avec les valeurs
  /// de bienvenue par défaut s'il s'agit d'une première connexion.
  Future<AppUser> _loadOrCreateUserProfile(fb.User firebaseUser, {String? initialDisplayName}) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      return AppUser(
        id: firebaseUser.uid,
        displayName: data['displayName'] ?? firebaseUser.displayName ?? 'Joueur',
        email: firebaseUser.email ?? '',
        photoUrl: data['photoUrl'] ?? firebaseUser.photoURL,
        level: data['level'] ?? 1,
        xp: data['xp'] ?? 0,
        coins: data['coins'] ?? 500,
        diamonds: data['diamonds'] ?? 10,
        isPremium: data['isPremium'] ?? false,
      );
    }

    // Première connexion : création du profil avec les valeurs de bienvenue.
    final newUser = AppUser(
      id: firebaseUser.uid,
      displayName: initialDisplayName ?? firebaseUser.displayName ?? 'Joueur',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
    );
    await docRef.set({
      'displayName': newUser.displayName,
      'email': newUser.email,
      'photoUrl': newUser.photoUrl,
      'level': newUser.level,
      'xp': newUser.xp,
      'coins': newUser.coins,
      'diamonds': newUser.diamonds,
      'isPremium': newUser.isPremium,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return newUser;
  }
}
