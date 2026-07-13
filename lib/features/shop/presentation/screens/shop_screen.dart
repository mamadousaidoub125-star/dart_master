import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../monetization/domain/entities/shop_product.dart';

/// Écran de boutique : packs de pièces/diamants (achats réels),
/// abonnement Premium sans publicité, et skins cosmétiques achetables
/// en monnaie virtuelle.
class ShopScreen extends StatelessWidget {
  final int userCoins;
  final int userDiamonds;
  final bool isPremium;
  final void Function(ShopProduct product) onBuyRealMoneyProduct;
  final void Function(ShopProduct product) onBuyWithVirtualCurrency;
  final VoidCallback onRestorePurchases;

  const ShopScreen({
    super.key,
    required this.userCoins,
    required this.userDiamonds,
    required this.isPremium,
    required this.onBuyRealMoneyProduct,
    required this.onBuyWithVirtualCurrency,
    required this.onRestorePurchases,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(
        title: const Text('Boutique'),
        actions: [
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
