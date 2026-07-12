# Guide de compilation — APK (Android) et IPA (iOS)

## Android (APK / AAB)

### 1. Générer une clé de signature (une seule fois)

```bash
keytool -genkey -v -keystore ~/dart-master-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias dart_master
```
Conserve ce fichier `.jks` et son mot de passe **précieusement** : sans
lui, tu ne pourras plus jamais publier de mise à jour de l'application.

### 2. Configurer la signature

Crée `android/key.properties` (ne JAMAIS commiter ce fichier dans Git) :
```
storePassword=<ton mot de passe keystore>
keyPassword=<ton mot de passe clé>
keyAlias=dart_master
storeFile=<chemin absolu vers dart-master-key.jks>
```

Dans `android/app/build.gradle`, assure-toi que la configuration de
signature de release pointe vers `key.properties` (configuration
standard Flutter, généralement déjà présente dans le template `flutter create`).

### 3. Compiler

Pour un **APK** (test direct sur appareil, ou distribution hors Play Store) :
```bash
flutter build apk --release
```
Fichier généré : `build/app/outputs/flutter-apk/app-release.apk`

Pour un **AAB** (App Bundle, **format requis par le Google Play Store**) :
```bash
flutter build appbundle --release
```
Fichier généré : `build/app/outputs/bundle/release/app-release.aab`

### 4. Vérifier avant envoi

```bash
flutter build apk --analyze-size    # Vérifie la taille finale de l'app
```

## iOS (IPA)

⚠️ La compilation iOS nécessite un **Mac** avec Xcode installé (impossible
depuis Windows/Linux, y compris via ce projet généré à distance).

### 1. Configurer la signature dans Xcode

```bash
open ios/Runner.xcworkspace
```
Dans Xcode :
1. Sélectionne le projet `Runner` > onglet "Signing & Capabilities"
2. Sélectionne ton équipe de développeur Apple
3. Vérifie le Bundle Identifier (doit correspondre à celui créé dans App Store Connect)

### 2. Compiler

```bash
flutter build ipa --release
```
Fichier généré : `build/ios/ipa/dart_master.ipa`

Si tu préfères passer entièrement par Xcode (recommandé pour le premier
envoi, pour repérer plus facilement les erreurs de certificats) :
1. Dans Xcode : Product > Archive
2. Une fois l'archive créée, "Distribute App" > "App Store Connect" > "Upload"

### 3. Erreurs fréquentes

| Erreur | Cause probable |
|---|---|
| `No profiles for 'com.xxx.dartmaster' were found` | Le Bundle ID n'existe pas encore dans App Store Connect, ou le compte développeur n'est pas encore actif |
| `CocoaPods not installed` | `sudo gem install cocoapods` puis `cd ios && pod install` |
| Échec de signature | Vérifie que ton certificat de distribution n'est pas expiré dans le portail développeur Apple |

## Récapitulatif des commandes

```bash
# Android
flutter build appbundle --release   # Pour le Play Store
flutter build apk --release         # Pour test/distribution directe

# iOS (Mac uniquement)
flutter build ipa --release         # Pour l'App Store
```
