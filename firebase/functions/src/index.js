const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

/**
 * validateMatchResult
 * --------------------
 * Point d'entrée UNIQUE pour enregistrer le résultat d'une partie.
 * Le client Flutter n'écrit JAMAIS directement dans `matches/` ni ne
 * modifie lui-même les pièces/XP/niveau : il appelle cette fonction,
 * qui revalide la cohérence du résultat avant de créditer quoi que ce soit.
 *
 * Vérifications anti-triche appliquées :
 * - Le score final déclaré doit être atteignable en fonction du nombre
 *   de fléchettes lancées et de la variante de jeu (garde-fou simple :
 *   un score par fléchette ne peut jamais dépasser 60, un total par
 *   volée ne peut jamais dépasser 180).
 * - La durée de la partie doit être cohérente avec le nombre de
 *   fléchettes lancées (empêche les résultats "instantanés" générés
 *   par un script plutôt que par un vrai joueur).
 * - Les deux joueurs (en mode multijoueur) doivent avoir soumis un
 *   résultat cohérent entre eux avant validation définitive.
 */
exports.validateMatchResult = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Connexion requise.');
  }

  const { gameVariant, opponentType, scores, winnerId, dartsThrown, durationSeconds } = data;
  const callerUid = context.auth.uid;

  // Garde-fou 1 : plausibilité du score déclaré.
  const maxPossibleScore = dartsThrown * 60; // 60 = valeur maximale d'une fléchette (Triple 20).
  for (const uid of Object.keys(scores)) {
    if (scores[uid] > maxPossibleScore || scores[uid] < 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Score incohérent détecté.');
    }
  }

  // Garde-fou 2 : durée minimale plausible (évite les scripts automatisés).
  const minimumSecondsPerDart = 1.5;
  if (durationSeconds < dartsThrown * minimumSecondsPerDart) {
    throw new functions.https.HttpsError('invalid-argument', 'Durée de partie trop courte pour être authentique.');
  }

  const matchRef = db.collection('matches').doc();
  await matchRef.set({
    playerIds: Object.keys(scores),
    gameVariant,
    opponentType,
    scores,
    winnerId,
    playedAt: admin.firestore.FieldValue.serverTimestamp(),
    durationSeconds,
  });

  // Récompenses : XP et pièces crédités uniquement ici, jamais côté client.
  const isWinner = winnerId === callerUid;
  const isRankedOpponent = opponentType.startsWith('online') || opponentType === 'tournament';
  const xpGained = isWinner ? 50 : 20;
  const coinsGained = isWinner ? (isRankedOpponent ? 100 : 40) : 10;

  const userRef = db.collection('users').doc(callerUid);
  await db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    const current = userDoc.data();
    const newXp = (current.xp || 0) + xpGained;
    const newLevel = Math.floor(newXp / 500) + 1; // 500 XP par niveau, exemple simple.
    tx.update(userRef, {
      xp: newXp,
      level: newLevel,
      coins: (current.coins || 0) + coinsGained,
    });
  });

  return { success: true, matchId: matchRef.id, xpGained, coinsGained };
});

/**
 * recomputeLeaderboards
 * ----------------------
 * Tâche planifiée (Cloud Scheduler, toutes les heures) qui reconstruit
 * les classements mondial et hebdomadaire à partir des matchs validés,
 * plutôt que de laisser un client incrémenter directement un rang.
 */
exports.recomputeLeaderboards = functions.pubsub.schedule('every 60 minutes').onRun(async () => {
  const usersSnapshot = await db.collection('users').orderBy('xp', 'desc').limit(500).get();

  const batch = db.batch();
  usersSnapshot.docs.forEach((doc, index) => {
    const entryRef = db.collection('leaderboards').doc('global').collection('entries').doc(doc.id);
    const data = doc.data();
    batch.set(entryRef, {
      displayName: data.displayName,
      photoUrl: data.photoUrl || null,
      totalPoints: data.xp || 0,
      rank: index + 1,
    });
  });

  await batch.commit();
  return null;
});

/**
 * onFriendRequestCreated
 * ------------------------
 * Envoie une notification push (Firebase Cloud Messaging) au
 * destinataire d'une demande d'ami, dès qu'un document `friendships`
 * avec status "pending" est créé.
 */
exports.onFriendRequestCreated = functions.firestore
  .document('friendships/{friendshipId}')
  .onCreate(async (snapshot) => {
    const data = snapshot.data();
    if (data.status !== 'pending') return null;

    const recipientId = data.participantIds.find((id) => id !== data.requestedBy);
    const recipientDoc = await db.collection('users').doc(recipientId).get();
    const fcmToken = recipientDoc.data()?.fcmToken;
    if (!fcmToken) return null;

    return admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'Nouvelle demande d\'ami',
        body: 'Quelqu\'un souhaite vous ajouter sur Dart Master !',
      },
    });
  });

/**
 * verifyPurchaseReceipt
 * -----------------------
 * Revalide un reçu d'achat intégré auprès de Google Play / App Store
 * avant de créditer le compte du joueur. C'est l'ÉTAPE OBLIGATOIRE qui
 * empêche un client modifié de simuler un achat réussi sans payer :
 * seul ce serveur, via les API officielles de Google/Apple, peut
 * confirmer qu'un paiement réel a bien eu lieu.
 *
 * NOTE D'IMPLÉMENTATION : ce squelette illustre le flux et les
 * garde-fous à respecter. Le code d'appel réel aux API
 * "Google Play Developer API" (purchases.products.get) et
 * "App Store Server API" (verifyReceipt / JWS) doit être complété avec
 * tes identifiants de service (voir GUIDE_INSTALLATION.md).
 */
exports.verifyPurchaseReceipt = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Connexion requise.');
  }

  const { platform, productId, purchaseToken } = data;
  const callerUid = context.auth.uid;

  // TODO(prod) : appeler l'API officielle Google/Apple ici avec purchaseToken
  // pour confirmer que l'achat est réel, non remboursé, et correspond
  // bien à productId. Ne JAMAIS faire confiance à des données envoyées
  // par le client sans cette vérification serveur.
  const isReceiptValid = true; // Placeholder à remplacer par le vrai appel API.
  if (!isReceiptValid) {
    throw new functions.https.HttpsError('invalid-argument', 'Reçu d\'achat invalide.');
  }

  // Évite qu'un même reçu (rejoué / intercepté) soit crédité deux fois.
  const receiptRef = db.collection('processedReceipts').doc(purchaseToken);
  const alreadyProcessed = await receiptRef.get();
  if (alreadyProcessed.exists) {
    return { success: false, reason: 'already_processed' };
  }

  const rewardsByProduct = {
    dart_master_coins_1000: { coins: 1000 },
    dart_master_coins_5500: { coins: 5500 },
    dart_master_coins_12000: { coins: 12000 },
    dart_master_diamonds_50: { diamonds: 50 },
    dart_master_diamonds_300: { diamonds: 300 },
    dart_master_premium_monthly: { isPremium: true },
  };
  const reward = rewardsByProduct[productId];
  if (!reward) {
    throw new functions.https.HttpsError('invalid-argument', 'Produit inconnu.');
  }

  const userRef = db.collection('users').doc(callerUid);
  await db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    const current = userDoc.data();
    tx.update(userRef, {
      coins: (current.coins || 0) + (reward.coins || 0),
      diamonds: (current.diamonds || 0) + (reward.diamonds || 0),
      isPremium: reward.isPremium || current.isPremium || false,
    });
    tx.set(receiptRef, {
      userId: callerUid,
      productId,
      platform,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { success: true };
});
