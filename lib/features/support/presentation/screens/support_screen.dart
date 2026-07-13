import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Écran de support : FAQ dépliable + formulaire de contact.
/// Un lien de support est OBLIGATOIRE pour la publication sur les deux
/// stores (Apple exige une URL de support valide dans App Store Connect).
class SupportScreen extends StatelessWidget {
  final void Function(String subject, String message) onSubmitTicket;

  const SupportScreen({super.key, required this.onSubmitTicket});

  static const _faqItems = [
    ('Comment récupérer mes achats sur un nouvel appareil ?',
        'Connectez-vous avec le même compte, puis utilisez le bouton "Restaurer" dans la boutique.'),
    ('Pourquoi ai-je perdu ma manche alors que mon score était à 0 ?',
        'À 501/301/101, il faut impérativement terminer sur un double. Un lancer amenant à 0 sans double est un "bust" et annule la volée.'),
    ('Comment désactiver les publicités ?',
        "Souscrivez à l'abonnement Dart Master Premium depuis la boutique."),
    ('Le jeu plante ou rame, que faire ?',
        'Vérifiez que votre application est à jour, redémarrez votre appareil, et contactez-nous via le formulaire ci-dessous si le problème persiste.'),
  ];

  @override
  Widget build(BuildContext context) {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Questions fréquentes', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ..._faqItems.map((item) => Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  collapsedIconColor: AppColors.lightGray,
                  iconColor: AppColors.gold,
                  title: Text(item.$1, style: const TextStyle(color: AppColors.white, fontSize: 14)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(item.$2, style: const TextStyle(color: AppColors.lightGray, fontSize: 13)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          const Text('Nous contacter', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: subjectController,
            style: const TextStyle(color: AppColors.white),
            decoration: _decoration('Sujet'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: messageController,
            style: const TextStyle(color: AppColors.white),
            maxLines: 5,
            decoration: _decoration('Décrivez votre problème'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => onSubmitTicket(subjectController.text, messageController.text),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.lightGray),
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}
