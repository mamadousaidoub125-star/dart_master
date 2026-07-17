/// Représente une partie multijoueur en ligne stockée dans Firestore
/// (collection `matches`, voir firebase/firestore/SCHEMA.md).
///
/// ⚠️ Cette classe et [OnlineMatchRepository] sont du CODE PRÊT À L'EMPLOI
/// mais NON ACTIF tant que Firebase n'est pas réellement configuré dans
/// ce projet (actuellement l'app utilise un système de connexion factice
/// pour pouvoir tester l'interface sans compte réel). Voir
/// docs/GUIDE_INSTALLATION.md, section Firebase, pour l'activer.
class OnlineMatch {
  final String matchId;
  final String hostId;
  final String? guestId;
  final String status; // "waiting" | "in_progress" | "completed"
  final int hostScore;
  final int guestScore;
  final String currentTurnPlayerId;
  final int currentRound;

  const OnlineMatch({
    required this.matchId,
    required this.hostId,
    this.guestId,
    required this.status,
    this.hostScore = 0,
    this.guestScore = 0,
    required this.currentTurnPlayerId,
    this.currentRound = 1,
  });

  factory OnlineMatch.fromFirestore(String id, Map<String, dynamic> data) {
    return OnlineMatch(
      matchId: id,
      hostId: data['hostId'] as String,
      guestId: data['guestId'] as String?,
      status: data['status'] as String? ?? 'waiting',
      hostScore: data['hostScore'] as int? ?? 0,
      guestScore: data['guestScore'] as int? ?? 0,
      currentTurnPlayerId: data['currentTurnPlayerId'] as String? ?? '',
      currentRound: data['currentRound'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'hostId': hostId,
        'guestId': guestId,
        'status': status,
        'hostScore': hostScore,
        'guestScore': guestScore,
        'currentTurnPlayerId': currentTurnPlayerId,
        'currentRound': currentRound,
      };
}
