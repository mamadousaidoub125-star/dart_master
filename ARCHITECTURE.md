# Documentation technique — Dart Master

## Vue d'ensemble

Dart Master suit une **Clean Architecture allégée**, organisée en
"features" (fonctionnalités), chacune divisée en trois couches :

```
lib/features/<feature>/
├── domain/          # Logique métier pure, AUCUN import Flutter/Firebase
│   ├── entities/    # Objets métier (AppUser, BoardZone, ShopProduct...)
│   ├── repositories/# Interfaces abstraites (contrats)
│   └── services/    # Règles de jeu, physique, IA, calculs
├── data/            # Implémentations concrètes des repositories
│   └── repositories/# Ex: FirebaseAuthRepository implémente AuthRepository
└── presentation/    # Écrans et widgets Flutter
    ├── screens/
    └── widgets/
```

### Pourquoi cette séparation ?

- **domain/** ne dépend jamais de Flutter ni de Firebase : le moteur de
  physique, le calcul de score et les règles de jeu peuvent être
  testés unitairement en quelques millisecondes, sans simulateur, et
  pourraient même être réutilisés côté serveur (Cloud Functions) pour
  l'anti-triche sans dupliquer la logique.
- **data/** peut être remplacée sans toucher au reste : `MockAuthRepository`
  (développement) et `FirebaseAuthRepository` (production) implémentent
  toutes deux `AuthRepository`, donc les écrans de connexion n'ont
  aucune idée de laquelle est utilisée.
- **presentation/** ne contient (idéalement) aucune logique métier :
  les écrans reçoivent des callbacks et des données déjà prêtes.

## Modules principaux

| Module | Rôle |
|---|---|
| `core/theme` | Palette de couleurs officielle, thèmes clair/sombre |
| `features/game/domain/services` | `ScoringService`, `ThrowPhysics`, `AiOpponent`, moteur de règles (`rules/`) |
| `features/game/presentation` | Écran de jeu, rendu de la cible |
| `features/auth` | Authentification (mock + Firebase) |
| `features/home`, `profile`, `settings` | Écrans de navigation principale |
| `features/game_modes` | Sélection règles + type d'adversaire |
| `features/onboarding` | Splash screen, tutoriel |
| `features/monetization` | AdMob, achats intégrés |
| `features/shop`, `inventory`, `rewards` | Économie du jeu |
| `features/social`, `leaderboard`, `tournaments` | Fonctionnalités multijoueur/social |
| `features/history`, `notifications`, `support`, `legal` | Écrans utilitaires |
| `app_shell.dart` | Orchestration de la navigation entre écrans |

## Flux de sécurité anti-triche (résumé)

```
Client Flutter                    Cloud Functions (serveur)          Firestore
─────────────                     ─────────────────────────          ─────────
Joue une partie
  │
  ├─ calcule le score localement
  │  (ScoringService/ThrowPhysics)
  │  → UNIQUEMENT pour l'affichage
  │    immédiat au joueur
  │
  └─► appelle validateMatchResult ──► revalide plausibilité du score ──► écrit matches/{id}
        (scores, dartsThrown,           (durée min., score max.               écrit users/{uid}.xp
         durationSeconds)                atteignable)                        et .coins
```

Le client ne peut jamais écrire directement `matches/`, les champs
sensibles de `users/{uid}` (xp, coins, diamonds, level, isPremium), ni
`leaderboards/` — voir `firebase/firestore/firestore.rules`.

## Ajouter une nouvelle variante de règles de jeu

1. Crée `lib/features/game/domain/services/rules/ma_variante_rules.dart`
   implémentant `GameRules`.
2. Ajoute une valeur à l'enum `GameVariant`
   (`lib/features/game/domain/services/game_rules_factory.dart`).
3. Ajoute le cas correspondant dans `GameRulesFactory.create()` et
   `.description()`.
4. Écris les tests unitaires dans `test/domain/services/rules/`.

Aucune autre partie du code (écrans, moteur de score, IA) n'a besoin
d'être modifiée : c'est l'intérêt de l'abstraction `GameRules`.

## État de complétude par phase

| Phase | Contenu | État |
|---|---|---|
| 1 | Moteur physique, scoring, IA, écran de jeu | ✅ Complet et testé |
| 2 | Écrans principaux (Splash à Tutoriel), moteur de règles (301/501/Cricket/Around the Clock/Count Up) | ✅ Complet et testé |
| 3 | Firebase (Auth, Firestore, règles de sécurité, Cloud Functions) | ✅ Structure complète ; nécessite `flutterfire configure` avec ton propre projet |
| 4 | AdMob, IAP, Boutique, Inventaire, Récompenses/Missions/Succès | ✅ Structure complète ; nécessite tes IDs de production |
| 5 | Amis, Chat, Classements, Tournois, Historique, Notifications, Support, Politique de confidentialité | ✅ Écrans complets ; nécessite le branchement aux repositories Firestore réels |
| 6 | Documentation | ✅ Ce document + guides d'installation/compilation/publication |

## Limitations connues à traiter avant une mise en production réelle

- Les repositories Firestore réels pour l'historique, les amis, le
  chat, les classements et les tournois ne sont pas encore implémentés
  (seuls les *écrans* et les *entités* existent) — à faire en
  connectant chaque écran à des `StreamBuilder`/`FutureBuilder` sur
  les collections décrites dans `firebase/firestore/SCHEMA.md`.
- Aucun asset graphique/audio réel n'est fourni : le rendu actuel de
  la cible est vectoriel (`CustomPainter`), suffisant pour jouer mais
  pas encore au niveau visuel "premium" demandé (illustrations,
  musique, voix). Prévoir un lot de production d'assets séparé.
- `app_shell.dart` utilise une machine à états simple plutôt qu'un
  routeur nommé ; à migrer vers `go_router` si des deep links
  (invitations, notifications cliquées) sont nécessaires.
