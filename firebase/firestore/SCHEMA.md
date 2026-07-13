# Schéma Firestore — Dart Master

## Collections

### `users/{userId}`
Profil du joueur.
```
{
  displayName: string,
  email: string,
  photoUrl: string | null,
  level: number,
  xp: number,
  coins: number,
  diamonds: number,
  isPremium: boolean,
  selectedDartSkin: string,
  selectedBoardSkin: string,
  selectedProfileFrame: string,
  createdAt: timestamp
}
```

### `inventories/{userId}`
Objets cosmétiques débloqués par le joueur.
```
{
  unlockedDartSkins: string[],
  unlockedBoardSkins: string[],
  unlockedBackgrounds: string[],
  unlockedAvatars: string[],
  unlockedProfileFrames: string[],
  unlockedBadges: string[]
}
```

### `matches/{matchId}`
Historique d'une partie terminée. Écrit uniquement par la Cloud Function
`validateMatchResult` après vérification anti-triche.
```
{
  playerIds: string[],
  gameVariant: string,       // "501", "cricket", etc.
  opponentType: string,      // "ai_medium", "online_public", ...
  scores: map<userId, number>,
  winnerId: string,
  playedAt: timestamp,
  durationSeconds: number
}
```

### `leaderboards/{leaderboardId}/entries/{userId}`
Entrées de classement (mondial et hebdomadaire), régénérées par une
Cloud Function planifiée (`recomputeLeaderboards`, Cloud Scheduler).
`leaderboardId` ∈ { `global`, `weekly_<year>_<week>` }.
```
{
  displayName: string,
  photoUrl: string | null,
  totalPoints: number,
  rank: number
}
```

### `friendships/{friendshipId}`
Relation d'amitié ou invitation en attente entre deux joueurs.
```
{
  participantIds: [userIdA, userIdB],
  status: "pending" | "accepted",
  requestedBy: string,
  createdAt: timestamp
}
```

### `chats/{chatId}`
Conversation (1-to-1 ou dans le contexte d'une partie multijoueur).
```
{
  participantIds: string[],
  lastMessageAt: timestamp
}
```
Sous-collection `chats/{chatId}/messages/{messageId}` :
```
{
  senderId: string,
  text: string,
  emoji: string | null,
  sentAt: timestamp
}
```

### `tournaments/{tournamentId}`
```
{
  name: string,
  gameVariant: string,
  status: "registration" | "in_progress" | "completed",
  participantIds: string[],
  bracket: map,           // Structure d'arbre générée par Cloud Function
  startsAt: timestamp,
  prizeCoins: number,
  prizeDiamonds: number
}
```

## Pourquoi les écritures sensibles passent par des Cloud Functions

Toute donnée qui affecte la compétitivité (score, classement, monnaie,
déverrouillage d'objet) est calculée et écrite côté serveur uniquement.
Un client Flutter compromis (device rooté/jailbreaké, requêtes réseau
modifiées) ne peut donc jamais s'auto-attribuer des pièces, gagner des
matchs fictifs ou monter artificiellement au classement : voir
`firebase/functions/src/index.js` et `firestore.rules`.
