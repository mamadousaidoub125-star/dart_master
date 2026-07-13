/// Type de produit vendu dans la boutique de Dart Master.
enum ShopProductType { coinPack, diamondPack, cosmeticSkin, premiumSubscription, limitedOffer }

/// Représente un produit achetable, qu'il s'agisse d'un achat intégré
/// réel (pack de pièces/diamants, abonnement) référencé par [storeProductId]
/// auprès d'Apple/Google, ou d'un objet cosmétique acheté avec la monnaie
/// virtuelle du jeu (auquel cas [storeProductId] est nul).
class ShopProduct {
  final String id;
  final ShopProductType type;
  final String title;
  final String description;
  final String? storeProductId; // ID configuré dans App Store Connect / Play Console.
  final int? coinPrice;         // Prix en pièces virtuelles, si applicable.
  final int? diamondPrice;      // Prix en diamants virtuels, si applicable.
  final int coinsGranted;
  final int diamondsGranted;
  final DateTime? limitedOfferExpiresAt;

  const ShopProduct({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.storeProductId,
    this.coinPrice,
    this.diamondPrice,
    this.coinsGranted = 0,
    this.diamondsGranted = 0,
    this.limitedOfferExpiresAt,
  });

  bool get isRealMoneyPurchase => storeProductId != null;

  bool get isExpired =>
      limitedOfferExpiresAt != null && DateTime.now().isAfter(limitedOfferExpiresAt!);
}

/// Catalogue de référence des produits disponibles.
///
/// En production, ce catalogue est généralement synchronisé avec un
/// document Firestore `shop_catalog` (pour pouvoir ajuster les offres
/// sans redéployer l'app), mais une liste statique de secours est
/// conservée ici pour ne jamais laisser la boutique vide hors-ligne.
class ShopCatalog {
  ShopCatalog._();

  static const List<ShopProduct> coinPacks = [
    ShopProduct(
      id: 'coins_small',
      type: ShopProductType.coinPack,
      title: '1 000 pièces',
      description: 'Petit pack de pièces',
      storeProductId: 'dart_master_coins_1000',
      coinsGranted: 1000,
    ),
    ShopProduct(
      id: 'coins_medium',
      type: ShopProductType.coinPack,
      title: '5 500 pièces',
      description: 'Pack de pièces (+10% bonus)',
      storeProductId: 'dart_master_coins_5500',
      coinsGranted: 5500,
    ),
    ShopProduct(
      id: 'coins_large',
      type: ShopProductType.coinPack,
      title: '12 000 pièces',
      description: 'Pack de pièces (+20% bonus)',
      storeProductId: 'dart_master_coins_12000',
      coinsGranted: 12000,
    ),
  ];

  static const List<ShopProduct> diamondPacks = [
    ShopProduct(
      id: 'diamonds_small',
      type: ShopProductType.diamondPack,
      title: '50 diamants',
      description: 'Petit pack de diamants',
      storeProductId: 'dart_master_diamonds_50',
      diamondsGranted: 50,
    ),
    ShopProduct(
      id: 'diamonds_medium',
      type: ShopProductType.diamondPack,
      title: '300 diamants',
      description: 'Pack de diamants (+15% bonus)',
      storeProductId: 'dart_master_diamonds_300',
      diamondsGranted: 300,
    ),
  ];

  static const ShopProduct premiumSubscription = ShopProduct(
    id: 'premium_monthly',
    type: ShopProductType.premiumSubscription,
    title: 'Dart Master Premium',
    description: 'Sans publicité, coffre quotidien amélioré, badge exclusif',
    storeProductId: 'dart_master_premium_monthly',
  );

  static List<String> get allStoreProductIds => [
        ...coinPacks.map((p) => p.storeProductId!),
        ...diamondPacks.map((p) => p.storeProductId!),
        premiumSubscription.storeProductId!,
      ];
}
