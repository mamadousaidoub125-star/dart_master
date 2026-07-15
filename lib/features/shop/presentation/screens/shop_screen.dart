import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../monetization/domain/entities/shop_product.dart';

/// Écran de boutique : packs de pièces/diamants (achats réels),
/// abonnement Premium, et carrousels d'images pour les haches et les
/// planches (on fait défiler pour voir chaque modèle avant d'acheter).
class ShopScreen extends StatefulWidget {
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
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
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
                  Text('${widget.userCoins}', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  const Icon(Icons.diamond, color: AppColors.electricBlue, size: 18),
                  const SizedBox(width: 4),
                  Text('${widget.userDiamonds}', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onRestorePurchases,
            child: const Text('Restaurer', style: TextStyle(color: AppColors.lightGray)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!widget.isPremium) _buildPremiumBanner(),
          const SizedBox(height: 24),
          const Text('⚔️ Haches — fais défiler pour voir chaque modèle',
              style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          _buildCarousel(
            products: ShopCatalog.axeSkins,
            unlockedIds: widget.unlockedAxeIds,
            buttonBuilder: (p) => _buildAxeButton(p),
          ),
          const SizedBox(height: 28),
          const Text('🎯 Planches — pièces, diamants ou vidéo gratuite',
              style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          _buildCarousel(
            products: ShopCatalog.boardSkins,
            unlockedIds: widget.unlockedBoardIds,
            buttonBuilder: (p) => _buildBoardButton(p),
          ),
          const SizedBox(height: 28),
          const Text('Pièces', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ...ShopCatalog.coinPacks.map((p) => _ProductTile(
                product: p,
                icon: Icons.monetization_on,
                iconColor: AppColors.gold,
                onTap: () => widget.onBuyRealMoneyProduct(p),
              )),
          const SizedBox(height: 24),
          const Text('Diamants', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ...ShopCatalog.diamondPacks.map((p) => _ProductTile(
                product: p,
                icon: Icons.diamond,
                iconColor: AppColors.electricBlue,
                onTap: () => widget.onBuyRealMoneyProduct(p),
              )),
        ],
      ),
    );
  }

  /// Carrousel horizontal swipeable : une carte par modèle, avec son
  /// image, son nom, et le bon bouton d'achat selon son mode de paiement.
  Widget _buildCarousel({
    required List<ShopProduct> products,
    required Set<String> unlockedIds,
    required Widget Function(ShopProduct) buttonBuilder,
  }) {
    return SizedBox(
      height: 230,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.62),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          final isUnlocked = unlockedIds.contains(p.id);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(18),
                border: isUnlocked ? Border.all(color: AppColors.green, width: 2) : null,
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: p.imageAsset != null
                        ? Image.asset(p.imageAsset!, fit: BoxFit.contain)
                        : const Icon(Icons.image_not_supported, color: AppColors.lightGray, size: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  isUnlocked
                      ? const Text('Débloquée ✓', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600))
                      : buttonBuilder(p),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAxeButton(ShopProduct p) {
    final canAfford = widget.userCoins >= (p.coinPrice ?? 0);
    return ElevatedButton(
      onPressed: canAfford ? () => widget.onBuyAxeWithCoins(p) : null,
      child: Text('${p.coinPrice} 🪙'),
    );
  }

  Widget _buildBoardButton(ShopProduct p) {
    if (p.unlockableByWatchingAd) {
      return ElevatedButton.icon(
        onPressed: () => widget.onWatchAdToUnlockBoard(p),
        icon: const Icon(Icons.play_circle, size: 16),
        label: const Text('Vidéo'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
      );
    }
    if (p.diamondPrice != null) {
      final canAfford = widget.userDiamonds >= p.diamondPrice!;
      return ElevatedButton(
        onPressed: canAfford ? () => widget.onBuyBoardWithDiamonds(p) : null,
        child: Text('${p.diamondPrice} 💎'),
      );
    }
    final canAfford = widget.userCoins >= (p.coinPrice ?? 0);
    return ElevatedButton(
      onPressed: canAfford ? () => widget.onBuyBoardWithCoins(p) : null,
      child: Text('${p.coinPrice} 🪙'),
    );
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
            onPressed: () => widget.onBuyRealMoneyProduct(premium),
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
