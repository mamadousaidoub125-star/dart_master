# Guide d'installation — Dart Master

## 1. Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.22 ou supérieur
- [Node.js](https://nodejs.org) 20 (pour les Cloud Functions Firebase)
- Un compte [Firebase](https://console.firebase.google.com)
- Un compte [Google Play Console](https://play.google.com/console) (25$ à vie)
- Un compte [Apple Developer Program](https://developer.apple.com/programs/) (99$/an)
- Un compte [Google AdMob](https://admob.google.com)
- Xcode (pour iOS, nécessite un Mac) et Android Studio

Vérifie ton installation :
```bash
flutter doctor
```
Corrige tout élément marqué d'une croix avant de continuer.

## 2. Installation des dépendances Flutter

```bash
cd dart_master
flutter pub get
```

## 3. Configuration Firebase

1. Crée un projet sur [console.firebase.google.com](https://console.firebase.google.com)
2. Active les services suivants dans la console :
   - Authentication (active Email/Password, Google, Apple)
   - Firestore Database (mode production)
   - Cloud Messaging
   - Crashlytics
   - Storage
3. Installe la CLI FlutterFire :
   ```bash
   dart pub global activate flutterfire_cli
   ```
4. Génère la configuration Firebase pour ton projet :
   ```bash
   flutterfire configure
   ```
   Cette commande crée automatiquement `lib/firebase_options.dart` et
   télécharge `google-services.json` (Android) et
   `GoogleService-Info.plist` (iOS) aux bons emplacements.
5. Dans `lib/main.dart`, initialise Firebase avant `runApp()` :
   ```dart
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```
   (Cette ligne est déjà préparée en commentaire dans le fichier ; il
   suffit de la décommenter une fois `firebase_options.dart` généré.)

## 4. Déploiement des règles et fonctions Firebase

```bash
cd firebase
npm install -g firebase-tools
firebase login
firebase use --add          # Sélectionne ton projet Firebase
firebase deploy --only firestore:rules,firestore:indexes
cd functions && npm install
firebase deploy --only functions
```

## 5. Configuration Google AdMob

1. Crée une application dans la console AdMob (une pour Android, une pour iOS)
2. Crée les unités publicitaires : Bannière, Interstitiel, Vidéo récompensée
3. Remplace les IDs de test dans `lib/features/monetization/data/services/admob_service.dart`
4. Ajoute ton App ID AdMob dans :
   - `android/app/src/main/AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`)
   - `ios/Runner/Info.plist` (`GADApplicationIdentifier`)

## 6. Configuration des achats intégrés (IAP)

1. Crée les produits dans **App Store Connect** et **Google Play Console**
   avec exactement les mêmes identifiants que dans
   `lib/features/monetization/domain/entities/shop_product.dart`
   (ex: `dart_master_coins_1000`).
2. Complète l'appel réel à l'API de vérification de reçu dans
   `firebase/functions/src/index.js` (`verifyPurchaseReceipt`), en
   utilisant tes identifiants de service Google Play Developer API /
   App Store Server API.

## 7. Google Play Games Services & Apple Game Center

1. Active Play Games Services dans Google Play Console, récupère ton
   ID de jeu et configure-le dans `android/app/src/main/AndroidManifest.xml`.
2. Active Game Center dans Xcode (onglet "Signing & Capabilities" > "+ Capability").

## 8. Lancer le projet en développement

```bash
flutter run
```

## 9. Lancer les tests

```bash
flutter test
```

## Dépannage courant

| Symptôme | Solution |
|---|---|
| `FirebaseOptions have not been configured` | Relance `flutterfire configure` |
| Publicités qui ne s'affichent jamais en dev | Normal avec les vrais IDs de prod tant que ton compte AdMob n'est pas validé (peut prendre 24-48h) |
| Achat intégré "produit introuvable" | Vérifie que les IDs produits sont strictement identiques entre le code et les consoles Store, et que l'app a été soumise au moins une fois en test interne |
