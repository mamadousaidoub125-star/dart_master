import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FriendEntry {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final bool isOnline;
  final bool isPendingRequest;

  const FriendEntry({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.isOnline = false,
    this.isPendingRequest = false,
  });
}

/// Écran de gestion des amis : liste, demandes en attente, invitation
/// à une partie, et recherche de nouveaux joueurs par pseudo.
class FriendsScreen extends StatelessWidget {
  final List<FriendEntry> friends;
  final List<FriendEntry> pendingRequests;
  final void Function(String query) onSearch;
  final void Function(FriendEntry friend) onInviteToMatch;
  final void Function(FriendEntry friend) onAcceptRequest;
  final void Function(FriendEntry friend) onOpenChat;

  const FriendsScreen({
    super.key,
    required this.friends,
    required this.pendingRequests,
    required this.onSearch,
    required this.onInviteToMatch,
    required this.onAcceptRequest,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: const Text('Amis')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: AppColors.white),
              onSubmitted: onSearch,
              decoration: InputDecoration(
                hintText: 'Rechercher un joueur par pseudo',
                hintStyle: const TextStyle(color: AppColors.lightGray),
                prefixIcon: const Icon(Icons.search, color: AppColors.lightGray),
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (pendingRequests.isNotEmpty) ...[
                  _sectionTitle('Demandes en attente'),
                  ...pendingRequests.map((f) => ListTile(
                        leading: _avatar(f),
                        title: Text(f.displayName, style: const TextStyle(color: AppColors.white)),
                        trailing: ElevatedButton(
                          onPressed: () => onAcceptRequest(f),
                          child: const Text('Accepter'),
                        ),
                      )),
                ],
                _sectionTitle('Mes amis (${friends.length})'),
                ...friends.map((f) => ListTile(
                      leading: _avatar(f),
                      title: Text(f.displayName, style: const TextStyle(color: AppColors.white)),
                      subtitle: Text(f.isOnline ? 'En ligne' : 'Hors ligne',
                          style: TextStyle(color: f.isOnline ? AppColors.green : AppColors.lightGray, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.chat_bubble_outline, color: AppColors.lightGray), onPressed: () => onOpenChat(f)),
                          IconButton(icon: const Icon(Icons.sports_esports, color: AppColors.electricBlue), onPressed: () => onInviteToMatch(f)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(FriendEntry f) => Stack(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.darkSurfaceElevated,
            backgroundImage: f.photoUrl != null ? NetworkImage(f.photoUrl!) : null,
            child: f.photoUrl == null ? const Icon(Icons.person, color: AppColors.white, size: 18) : null,
          ),
          if (f.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle, border: Border.all(color: AppColors.midnightBlue, width: 2)),
              ),
            ),
        ],
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text(title, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
      );
}
