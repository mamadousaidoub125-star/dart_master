import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/online_match.dart';

/// Gère la création, la jonction et la synchronisation en temps réel
/// d'une partie multijoueur en ligne via Cloud Firestore.
///
/// ⚠️ NE PAS UTILISER tant que `Firebase.initializeApp()` n'a pas été
/// réellement appelé au démarrage de l'app (voir lib/app_shell.dart,
/// méthode `_initializeApp`, actuellement commentée). Appeler une
/// méthode de cette classe sans Firebase initialisé provoquera un
/// plantage. Voir docs/GUIDE_INSTALLATION.md pour l'activer.
///
/// Une fois Firebase actif, cette classe permet :
/// - de créer une partie et d'obtenir un code à partager à un ami
///   (matchmaking privé) ;
/// - de rejoindre une partie existante avec ce code ;
/// - d'écouter en temps réel les changements de score/tour de l'adversaire,
///   via un simple `StreamBuilder` côté écran, sans polling.
class OnlineMatchRepository {
  final FirebaseFirestore _firestore;

  OnlineMatchRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _matches => _firestore.collection('matches');

  /// Crée une nouvelle partie en attente d'un adversaire, et retourne son
  /// identifiant (à partager comme "code d'invitation" à un ami).
  Future<String> createMatch({required String hostId}) async {
    final doc = await _matches.add(
      OnlineMatch(
        matchId: '',
        hostId: hostId,
        status: 'waiting',
        currentTurnPlayerId: hostId,
      ).toFirestore(),
    );
    return doc.id;
  }

  /// Rejoint une partie existante grâce à son identifiant/code.
  Future<void> joinMatch({required String matchId, required String guestId}) async {
    await _matches.doc(matchId).update({
      'guestId': guestId,
      'status': 'in_progress',
    });
  }

  /// Écoute les changements en temps réel d'une partie (score, tour actif).
  /// À utiliser avec un StreamBuilder<OnlineMatch> côté écran.
  Stream<OnlineMatch> watchMatch(String matchId) {
    return _matches.doc(matchId).snapshots().map(
          (snap) => OnlineMatch.fromFirestore(snap.id, snap.data()!),
        );
  }

  /// Soumet le score d'une manche jouée, en additionnant de façon atomique
  /// (transaction) pour éviter toute perte de données en cas d'écriture
  /// simultanée des deux joueurs.
  Future<void> submitRoundScore({
    required String matchId,
    required bool isHost,
    required int roundScore,
  }) async {
    await _firestore.runTransaction((tx) async {
      final ref = _matches.doc(matchId);
      final snap = await tx.get(ref);
      final data = snap.data()!;
      final field = isHost ? 'hostScore' : 'guestScore';
      final currentScore = data[field] as int? ?? 0;
      tx.update(ref, {field: currentScore + roundScore});
    });
  }
}
