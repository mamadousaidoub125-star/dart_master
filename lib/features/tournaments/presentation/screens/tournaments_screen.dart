import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum TournamentStatus { registration, inProgress, completed }

class TournamentEntry {
  final String id;
  final String name;
  final String gameVariant;
  final TournamentStatus status;
  final int participantCount;
  final int maxParticipants;
  final int prizeCoins;
  final int prizeDiamonds;
  final DateTime startsAt;
  final bool isUserRegistered;

  const TournamentEntry({
    required this.id,
    required this.name,
    required this.gameVariant,
    required this.status,
    required this.participantCount,
    required this.maxParticipants,
    required this.prizeCoins,
    required this.prizeDiamonds,
    required this.startsAt,
    this.isUserRegistered = false,
  });
}

/// Écran listant les tournois disponibles (à venir, en cours, terminés)
/// avec inscription en un tap. Le bracket lui-même (arbre d'élimination)
/// est généré côté serveur par Cloud Function pour éviter toute
/// manipulation d'appariement par un client.
class TournamentsScreen extends StatelessWidget {
  final List<TournamentEntry> tournaments;
  final void Function(TournamentEntry tournament) onRegister;
  final void Function(TournamentEntry tournament) onViewBracket;

  const TournamentsScreen({
    super.key,
    required this.tournaments,
    required this.onRegister,
    required this.onViewBracket,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: const Text('Tournois')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: tournaments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final t = tournaments[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(t.name, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    _statusChip(t.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Format ${t.gameVariant} · ${t.participantCount}/${t.maxParticipants} joueurs',
                    style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: AppColors.gold, size: 16),
                    Text(' ${t.prizeCoins}', style: const TextStyle(color: AppColors.white, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.diamond, color: AppColors.electricBlue, size: 16),
                    Text(' ${t.prizeDiamonds}', style: const TextStyle(color: AppColors.white, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                if (t.status == TournamentStatus.registration)
                  ElevatedButton(
                    onPressed: t.isUserRegistered ? null : () => onRegister(t),
                    child: Text(t.isUserRegistered ? 'Déjà inscrit' : "S'inscrire"),
                  )
                else
                  OutlinedButton(
                    onPressed: () => onViewBracket(t),
                    child: const Text('Voir le tableau'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusChip(TournamentStatus status) {
    final (label, color) = switch (status) {
      TournamentStatus.registration => ('Inscriptions', AppColors.green),
      TournamentStatus.inProgress => ('En cours', AppColors.gold),
      TournamentStatus.completed => ('Terminé', AppColors.lightGray),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
