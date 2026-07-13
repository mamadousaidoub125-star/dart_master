import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LeaderboardEntry {
  final int rank;
  final String displayName;
  final String? photoUrl;
  final int points;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.displayName,
    this.photoUrl,
    required this.points,
    this.isCurrentUser = false,
  });
}

/// Écran de classements : bascule entre classement mondial (toutes
/// périodes) et hebdomadaire (réinitialisé chaque lundi), alimentés
/// par la Cloud Function `recomputeLeaderboards`.
class LeaderboardScreen extends StatefulWidget {
  final List<LeaderboardEntry> globalEntries;
  final List<LeaderboardEntry> weeklyEntries;

  const LeaderboardScreen({super.key, required this.globalEntries, required this.weeklyEntries});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _showWeekly = false;

  @override
  Widget build(BuildContext context) {
    final entries = _showWeekly ? widget.weeklyEntries : widget.globalEntries;

    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: const Text('Classements')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Mondial')),
                ButtonSegment(value: true, label: Text('Hebdomadaire')),
              ],
              selected: {_showWeekly},
              onSelectionChanged: (set) => setState(() => _showWeekly = set.first),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Container(
                  color: entry.isCurrentUser ? AppColors.electricBlue.withOpacity(0.15) : null,
                  child: ListTile(
                    leading: _buildRankBadge(entry.rank),
                    title: Text(entry.displayName,
                        style: TextStyle(color: AppColors.white, fontWeight: entry.isCurrentUser ? FontWeight.w800 : FontWeight.w500)),
                    trailing: Text('${entry.points} pts', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    switch (rank) {
      case 1: color = AppColors.gold; break;
      case 2: color = AppColors.lightGray; break;
      case 3: color = const Color(0xFFCD7F32); break;
      default: color = AppColors.darkSurfaceElevated;
    }
    return CircleAvatar(
      backgroundColor: color,
      radius: 16,
      child: Text('$rank', style: const TextStyle(color: AppColors.midnightBlue, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
