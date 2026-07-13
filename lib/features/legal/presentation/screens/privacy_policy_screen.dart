import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Affiche la politique de confidentialité. Le contenu texte complet
/// est dans `legal/PRIVACY_POLICY.md`, qui doit être hébergé sur une
/// URL publique (obligatoire pour Apple et Google) — voir GUIDE_PUBLICATION.md.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: const Text('Politique de confidentialité')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          _privacyPolicyPreview,
          style: TextStyle(color: AppColors.lightGray, fontSize: 13, height: 1.6),
        ),
      ),
    );
  }
}

const _privacyPolicyPreview = '''
DART MASTER — POLITIQUE DE CONFIDENTIALITÉ (extrait)

Le texte complet et à jour est disponible sur notre site web et doit
être hébergé à une URL publique avant publication sur les stores.
Voir legal/PRIVACY_POLICY.md pour le document de référence complet.

Résumé des données collectées :
• Compte : email, pseudo, photo de profil (via Firebase Authentication)
• Progression de jeu : scores, niveau, XP, historique de parties
• Achats : reçus d'achats intégrés (validés côté serveur)
• Publicité : identifiants publicitaires via Google AdMob
• Technique : journaux de plantage (Firebase Crashlytics)

Vous pouvez demander la suppression de votre compte et de vos données
à tout moment depuis Paramètres > Support.
''';
