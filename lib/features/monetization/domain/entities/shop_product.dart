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
  final bool unlockableByWatchingAd; // Déblocable gratuitement via une vidéo récompensée.
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
    this.unlockableByWatchingAd = false,
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

  /// Haches/fléchettes cosmétiques achetables avec les pièces gagnées en
  /// jouant (voir GameScreen.onCoinsEarned), pas avec de l'argent réel.
  static const List<ShopProduct> axeSkins = [
    ShopProduct(
      id: 'axe_bronze',
      type: ShopProductType.cosmeticSkin,
      title: 'Hache de bronze',
      description: 'Le fidèle outil du guerrier débutant',
      coinPrice: 100,
    ),
    ShopProduct(
      id: 'axe_iron',
      type: ShopProductType.cosmeticSkin,
      title: 'Hache de fer runique',
      description: 'Gravée de runes anciennes',
      coinPrice: 350,
    ),
    ShopProduct(
      id: 'axe_flame',
      type: ShopProductType.cosmeticSkin,
      title: 'Hache enflammée',
      description: 'Forgée dans les feux de Muspell',
      coinPrice: 800,
    ),
    ShopProduct(
      id: 'axe_frost',
      type: ShopProductType.cosmeticSkin,
      title: 'Hache de glace éternelle',
      description: "Venue des confins de Niflheim",
      coinPrice: 800,
    ),
    ShopProduct(
      id: 'axe_golden',
      type: ShopProductType.cosmeticSkin,
      title: "Hache dorée d'Odin",
      description: 'Réservée aux plus grands champions',
      coinPrice: 2000,
    ),
  ];

  /// Planches/cibles cosmétiques, achetables de PLUSIEURS façons
  /// différentes selon l'objet : pièces gagnées en jouant, diamants
  /// (monnaie premium), ou gratuitement en regardant une publicité.
  static const List<ShopProduct> boardSkins = [
    ShopProduct(
      id: 'board_oak',
      type: ShopProductType.cosmeticSkin,
      title: 'Planche en chêne',
      description: 'Le bois robuste des maisons longues vikings',
      coinPrice: 150,
    ),
    ShopProduct(
      id: 'board_driftwood',
      type: ShopProductType.cosmeticSkin,
      title: 'Planche en bois flotté',
      description: 'Récupérée sur le rivage — gratuite via une vidéo',
      unlockableByWatchingAd: true,
    ),
    ShopProduct(
      id: 'board_rune_stone',
      type: ShopProductType.cosmeticSkin,
      title: 'Planche de pierre runique',
      description: 'Gravée de symboles anciens, plus résistante',
      coinPrice: 600,
    ),
    ShopProduct(
      id: 'board_ice',
      type: ShopProductType.cosmeticSkin,
      title: 'Planche de glace éternelle',
      description: "Venue des confins de Niflheim",
      diamondPrice: 50,
    ),
    ShopProduct(
      id: 'board_golden_royal',
      type: ShopProductType.cosmeticSkin,
      title: 'Planche dorée royale',
      description: 'Réservée aux champions du classement mondial',
      diamondPrice: 150,
    ),
  ];

  static List<String> get allStoreProductIds => [
        ...coinPacks.map((p) => p.storeProductId!),
        ...diamondPacks.map((p) => p.storeProductId!),
        premiumSubscription.storeProductId!,
      ];
}
