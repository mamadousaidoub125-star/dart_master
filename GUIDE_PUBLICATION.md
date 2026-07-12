# Guide de publication — Google Play Store & App Store

## Google Play Store

### 1. Créer la fiche de l'application
Dans [Google Play Console](https://play.google.com/console) :
1. "Créer une application" → renseigne le nom **Dart Master**, la
   langue par défaut, et confirme qu'elle respecte les règles du
   programme des développeurs.
2. Complète la fiche Play Store : description courte (80 caractères),
   description longue, captures d'écran (min. 2, formats téléphone et
   tablette recommandés), icône 512x512, image de présentation
   1024x500.

### 2. Classification du contenu
Remplis le questionnaire IARC. Dart Master contenant des achats
intégrés et un système de tirage aléatoire de récompenses (coffres),
déclare-le honnêtement : certaines juridictions exigent un
avertissement spécifique pour les mécaniques de type "loot box".

### 3. Politique de confidentialité
Renseigne l'URL publique de ta politique de confidentialité (voir
`legal/PRIVACY_POLICY.md`, à héberger sur un site web accessible).
Obligatoire, l'app sera rejetée sans cela.

### 4. Formulaire de sécurité des données (Data Safety)
Déclare précisément les données collectées (voir le tableau dans
`legal/PRIVACY_POLICY.md`) : compte, progression de jeu, publicité,
achats. Une déclaration inexacte peut entraîner une suspension.

### 5. Upload et tests
1. Upload ton fichier `.aab` (voir GUIDE_COMPILATION.md) dans un canal
   de test interne d'abord.
2. Ajoute des testeurs (emails) et vérifie que l'app s'installe et
   fonctionne correctement sur plusieurs appareils.
3. Passe ensuite en test fermé, puis ouvert, avant la production.

### 6. Configuration des produits IAP
Dans Play Console > Monétiser > Produits : crée les mêmes IDs produits
que dans `shop_product.dart` (packs de pièces, diamants, abonnement).

### 7. Soumission
Une fois tous les onglets validés (icône verte), soumets pour examen.
Délai habituel : quelques heures à 7 jours pour une première soumission.

---

## Apple App Store

### 1. Créer l'app dans App Store Connect
Sur [appstoreconnect.apple.com](https://appstoreconnect.apple.com) :
1. "Mes Apps" → "+" → "Nouvelle app"
2. Renseigne le nom, le Bundle ID (doit correspondre à celui configuré
   dans Xcode), le SKU interne.

### 2. Fiche produit
- Captures d'écran obligatoires pour au moins un format iPhone (6.7")
  et un format iPad si l'app supporte les tablettes.
- Description, mots-clés, URL de support (obligatoire), URL de
  politique de confidentialité (obligatoire).

### 3. App Privacy (Nutrition Label)
Apple exige une déclaration détaillée des données collectées et de
leur usage (identique en substance au Data Safety de Google, mais
formulaire distinct). Sois exhaustif : données de compte, identifiants
publicitaires (AdMob), contenu utilisateur (chat).

### 4. Sign in with Apple
Si tu proposes "Se connecter avec Google", Apple **exige** que tu
proposes aussi "Se connecter avec Apple" (déjà inclus dans
`login_screen.dart`). Une app le proposant pas peut être rejetée.

### 5. In-App Purchases
Dans l'onglet "Fonctionnalités" > "Achats intégrés" : crée chaque
produit avec le même identifiant que dans `shop_product.dart`, fournis
une capture d'écran de chaque produit tel qu'affiché dans l'app
(exigé par la revue Apple).

### 6. TestFlight
Avant la soumission finale, distribue une build via TestFlight à des
testeurs internes puis externes pour valider le comportement réel
(paiements en mode sandbox, connexions sociales, etc.)

### 7. Soumission à la revue
Uploade ton `.ipa` (voir GUIDE_COMPILATION.md), remplis les notes pour
l'équipe de revue (identifiants de test si login requis), et soumets.
Délai habituel : 24 à 48h pour une première soumission.

---

## Checklist finale avant soumission (les deux stores)

- [ ] Politique de confidentialité publiée à une URL publique et accessible
- [ ] URL de support fonctionnelle
- [ ] Tous les IDs AdMob/IAP de test remplacés par les IDs de production
- [ ] Firestore Rules déployées en production (`firebase deploy --only firestore:rules`)
- [ ] Cloud Functions déployées et testées (validation de match, achats)
- [ ] App testée sur au moins un appareil milieu de gamme réel (pas seulement un émulateur haut de gamme)
- [ ] Mentions légales relatives aux mécaniques de type "coffre"/loot box, si applicable dans ta juridiction cible
