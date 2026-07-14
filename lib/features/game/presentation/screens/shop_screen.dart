import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../monetization/domain/entities/shop_product.dart';

/// Écran de boutique : packs de pièces/diamants (achats réels),
/// abonnement Premium sans publicité, skins cosmétiques achetables
/// en monnaie virtuelle, et haches/fléchettes achetables avec les
/// pièces gagnées en jouant.
class ShopScreen extends StatelessWidget {
  final int userCoins;
  final int userDiamonds;
  final bool isPremium;
  final Set<String> unlockedAxeIds;
  final Set<String> unlockedBoardIds;
  final void Function(ShopProduct product) onBuyRealMoneyProduct;
  final void Function(ShopProduct product) onBuyAxeWithCoins;
  final void Function(ShopProduct product) onBuyBoardWithCoins;
  final void Function(ShopProduct product) onBuyBoardWithDiamonds;
  final void Function(ShopProduct product) onWatchAdToUnlockBoard;
  final VoidCallback onRestorePurchases;

  const ShopScreen({
    super.key,
    required this.userCoins,
    required this.userDiamonds,
    required this.isPremium,
    required this.unlockedAxeIds,
    required this.unlockedBoardIds,
    required this.onBuyRealMoneyProduct,
    required this.onBuyAxeWithCoins,
    required this.onBuyBoardWithCoins,
    required this.onBuyBoardWithDiamonds,
    required this.onWatchAdToUnlockBoard,
    required this.onRestorePurchases,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(
        title: const Text('Boutique'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppColors.gold, size: 18),
                  const SizedBox(width: 4),
                  Text('$userCoins', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: onRestorePurchases,
            child: const Text('Restaurer', style: TextStyle(color: AppColors.lightGray)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!isPremium) _buildPremiumBanner(),
          const SizedBox(height: 24),
          const Text('⚔️ Haches (avec les pièces gagnées en jouant)',
              style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ...ShopCatalog.axeSkins.map((p) {
            final isUnlocked = unlockedAxeIds.contains(p.id);
            final canAfford = userCoins >= (p.coinPrice ?? 0);
            return Card(
              color: AppColors.darkSurface,
              child: ListTile(
                leading: const Icon(Icons.hardware, color: AppColors.gold, size: 32),
                title: Text(p.title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(p.description, style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                trailing: isUnlocked
                    ? const Text('Débloquée', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600))
                    : ElevatedButton(
                        onPressed: canAfford ? () => onBuyAxeWithCoins(p) : null,
                        child: Text('${p.coinPrice} 🪙'),
                      ),
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text('🎯 Planches (pièces, diamants ou vidéo gratuite)',
              style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ...ShopCatalog.boardSkins.map((p) {
            final isUnlocked = unlockedBoardIds.contains(p.id);
            return Card(
              color: AppColors.darkSurface,
              child: ListTile(
                leading: const Icon(Icons.gps_fixed, color: AppColors.electricBlue, size: 32),
                title: Text(p.title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(p.description, style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                trailing: isUnlocked
                    ? const Text('Débloquée', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600))
                    : _buildBoardPurchaseButton(p),
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text('Pièces', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ...ShopCatalog.coinPacks.map((p) => _ProductTile(
                product: p,
                icon: Icons.monetization_on,
                iconColor: AppColors.gold,
                onTap: () => onBuyRealMoneyProduct(p),
              )),
          const SizedBox(height: 24),
          const Text('Diamants', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ...ShopCatalog.diamondPacks.map((p) => _ProductTile(
                product: p,
                icon: Icons.diamond,
                iconColor: AppColors.electricBlue,
                onTap: () => onBuyRealMoneyProduct(p),
              )),
        ],
      ),
    );
  }

  /// Choisit le bon bouton d'achat pour une planche selon son mode de
  /// paiement : pièces, diamants, ou vidéo publicitaire gratuite.
  Widget _buildBoardPurchaseButton(ShopProduct p) {
    if (p.unlockableByWatchingAd) {
      return ElevatedButton.icon(
        onPressed: () => onWatchAdToUnlockBoard(p),
        icon: const Icon(Icons.play_circle, size: 18),
        label: const Text('Vidéo'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
      );
    }
    if (p.diamondPrice != null) {
      final canAfford = userDiamonds >= p.diamondPrice!;
      return ElevatedButton(
        onPressed: canAfford ? () => onBuyBoardWithDiamonds(p) : null,
        child: Text('${p.diamondPrice} 💎'),
      );
    }
    if (p.coinPrice != null) {
      final canAfford = userCoins >= p.coinPrice!;
      return ElevatedButton(
        onPressed: canAfford ? () => onBuyBoardWithCoins(p) : null,
        child: Text('${p.coinPrice} 🪙'),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPremiumBanner() {
    final premium = ShopCatalog.premiumSubscription;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: AppColors.midnightBlue, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(premium.title, style: const TextStyle(color: AppColors.midnightBlue, fontWeight: FontWeight.w800)),
                Text(premium.description, style: const TextStyle(color: AppColors.midnightBlue, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.midnightBlue),
            onPressed: () => onBuyRealMoneyProduct(premium),
            child: const Text("S'abonner"),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ShopProduct product;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.icon, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.darkSurface,
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 32),
        title: Text(product.title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(product.description, style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
        trailing: ElevatedButton(onPressed: onTap, child: const Text('Acheter')),
      ),
    );
  }
}
