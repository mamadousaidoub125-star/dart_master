# Dart Master

Jeu de fléchettes mobile premium — Flutter + Flame + Firebase.

## Statut : les 6 phases de développement sont posées

| Phase | Contenu |
|---|---|
| 1 | Moteur physique du lancer, calcul de score officiel, IA à 4 niveaux |
| 2 | Écrans principaux (Splash → Connexion → Accueil → Tutoriel...) + moteur de règles (101/301/501/Cricket/Around the Clock/Count Up) |
| 3 | Backend Firebase (Auth, Firestore, règles de sécurité, Cloud Functions anti-triche) |
| 4 | Monétisation (AdMob, achats intégrés, abonnement Premium) + Boutique/Inventaire/Récompenses |
| 5 | Social (Amis, Chat, Classements, Tournois) + écrans utilitaires (Historique, Notifications, Support, Confidentialité) |
| 6 | Documentation complète (ce dossier `docs/`) |

> ⚠️ Ce code a été écrit intégralement à la main dans un environnement
> sans SDK Flutter/Firebase installé : il n'a **jamais été compilé ni
> exécuté**. Attends-toi à devoir corriger quelques erreurs de syntaxe
> ou de version de package au premier `flutter pub get` / `flutter run`.
> Voir `docs/GUIDE_INSTALLATION.md` pour démarrer, et n'hésite pas à me
> montrer les erreurs de compilation pour que je les corrige.

## Démarrage rapide

```bash
flutter pub get
flutter test      # Lance tous les tests unitaires (scoring, physique, règles)
flutter run       # Lance l'app : Splash -> Connexion -> Tutoriel -> Accueil -> Jeu
```

Au premier lancement, utilise n'importe quel email/mot de passe (le
`MockAuthRepository` accepte tout) pour explorer le flux complet.

## Arborescence

```
dart_master/
├── lib/
│   ├── app_shell.dart        # Orchestration de la navigation entre écrans
│   ├── main.dart
│   ├── core/theme/           # Couleurs officielles, thèmes clair/sombre
│   └── features/
│       ├── game/             # Physique, scoring, IA, règles, écran de jeu
│       ├── auth/              # Connexion/Inscription (mock + Firebase)
│       ├── home/ profile/ settings/
│       ├── onboarding/        # Splash, Tutoriel
│       ├── game_modes/        # Choix du mode de jeu
│       ├── monetization/      # AdMob, IAP
│       ├── shop/ inventory/ rewards/   # Boutique, inventaire, récompenses/missions/succès
│       ├── social/ leaderboard/ tournaments/  # Amis, chat, classements, tournois
│       ├── history/ notifications/ support/ legal/
│
├── test/                     # Tests unitaires (domain layer)
├── firebase/                 # Règles Firestore, index, Cloud Functions
├── legal/PRIVACY_POLICY.md   # Modèle de politique de confidentialité (à faire relire par un juriste)
├── docs/                     # Guides d'installation, de compilation, de publication, architecture technique
└── pubspec.yaml
```

## Documentation

- **`docs/GUIDE_INSTALLATION.md`** — configuration Flutter, Firebase, AdMob, IAP, Play Games/Game Center
- **`docs/GUIDE_COMPILATION.md`** — générer un APK/AAB et un IPA
- **`docs/GUIDE_PUBLICATION.md`** — checklist complète Google Play Store et App Store
- **`docs/ARCHITECTURE.md`** — organisation du code, flux anti-triche, état de complétude détaillé, limitations connues

## Ce qu'il reste à faire pour une mise en production réelle

Voir la section "Limitations connues" de `docs/ARCHITECTURE.md` — en
résumé : brancher les écrans social/classements/historique sur de
vraies requêtes Firestore (actuellement ils reçoivent des données en
paramètre), produire les assets graphiques/audio définitifs, et
remplacer tous les IDs de test (AdMob, IAP) par tes IDs de production.
