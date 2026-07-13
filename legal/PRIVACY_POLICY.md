# Politique de confidentialité — Dart Master

> ⚠️ **Ce document est un MODÈLE de départ, pas un document juridique
> validé.** Avant publication sur l'App Store ou le Google Play Store,
> fais relire et adapter ce texte par un juriste (obligations RGPD si
> tu as des utilisateurs dans l'UE, CCPA si aux États-Unis, lois
> spécifiques aux mineurs si le jeu peut être utilisé par des enfants,
> etc.). Remplace également [NOM DE L'ÉDITEUR], [EMAIL DE CONTACT] et
> [DATE] par tes informations réelles avant publication.

**Dernière mise à jour : [DATE]**

## 1. Qui sommes-nous

Dart Master est édité par [NOM DE L'ÉDITEUR]. Pour toute question
relative à cette politique, contactez-nous à [EMAIL DE CONTACT].

## 2. Données que nous collectons

| Catégorie | Données | Finalité | Base légale |
|---|---|---|---|
| Compte | Email, pseudo, photo de profil | Authentification, identification en jeu | Exécution du contrat |
| Progression | Score, niveau, XP, historique de parties, classements | Fonctionnement du jeu, classements | Exécution du contrat |
| Achats | Identifiant de transaction, produit acheté | Livraison des achats, support | Exécution du contrat |
| Publicité | Identifiant publicitaire (IDFA/GAID), interactions avec les annonces | Diffusion de publicités via Google AdMob | Consentement (selon juridiction) |
| Technique | Journaux de plantage, informations sur l'appareil | Correction de bugs, amélioration du service | Intérêt légitime |
| Communication | Messages échangés dans le chat entre amis | Fonctionnalité sociale | Exécution du contrat |

Nous ne collectons jamais de mot de passe en clair (géré par Firebase
Authentication) ni d'informations de paiement complètes (gérées
directement par Apple/Google, jamais transmises à nos serveurs).

## 3. Partage des données avec des tiers

- **Firebase (Google)** : hébergement de l'authentification, de la
  base de données et des notifications.
- **Google AdMob** : diffusion de publicités ; peut utiliser
  l'identifiant publicitaire de l'appareil.
- **Google Play Games Services / Apple Game Center** : classements et
  succès natifs, si activés par l'utilisateur.

Nous ne vendons aucune donnée personnelle à des tiers.

## 4. Conservation des données

Les données de compte sont conservées tant que le compte est actif.
En cas de suppression de compte (Paramètres > Support), les données
personnelles sont supprimées sous [X] jours, à l'exception des données
agrégées et anonymisées nécessaires à des fins statistiques.

## 5. Vos droits

Selon votre juridiction, vous pouvez disposer d'un droit d'accès, de
rectification, d'effacement, de portabilité et d'opposition sur vos
données. Contactez [EMAIL DE CONTACT] pour exercer ces droits.

## 6. Public mineur

[À COMPLÉTER selon ta politique réelle] : si le jeu est accessible à
des mineurs, indique ici les mesures prises (consentement parental,
limitation de la collecte de données, absence de chat pour les
comptes identifiés comme mineurs, conformité COPPA si visant les
États-Unis, etc.)

## 7. Sécurité

Les données transitent de manière chiffrée (HTTPS/TLS) et sont
hébergées sur l'infrastructure sécurisée de Google Firebase. L'accès
aux données sensibles côté serveur est restreint par les règles de
sécurité Firestore (voir firebase/firestore/firestore.rules).

## 8. Modifications de cette politique

Nous pouvons mettre à jour cette politique. Toute modification
substantielle sera notifiée dans l'application avant son entrée en
vigueur.
