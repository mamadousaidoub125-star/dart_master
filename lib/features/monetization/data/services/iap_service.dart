import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../domain/entities/shop_product.dart';

/// Gère le cycle de vie complet des achats intégrés (IAP) : chargement
/// du catalogue depuis les stores, achat, et surtout **validation des
/// reçus côté serveur** avant de créditer quoi que ce soit au joueur.
///
/// ⚠️ Important : ne JAMAIS créditer les pièces/diamants/abonnement
/// directement depuis ce service côté client. Le flux correct est :
/// 1. `buy...()` déclenche l'achat natif (Google Play / App Store)
/// 2. Le store retourne un reçu signé dans `purchaseStream`
/// 3. Ce reçu est envoyé à une Cloud Function (`verifyPurchaseReceipt`)
///    qui le revalide auprès de Google/Apple avant de créditer le
///    compte Firestore de l'utilisateur.
/// Sans cette étape 3, un appareil rooté/jailbreaké pourrait simuler
/// un achat réussi côté client sans jamais payer.
class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Callback fourni par la couche d'appel (généralement un appel à la
  /// Cloud Function `verifyPurchaseReceipt`) pour valider chaque achat.
  final Future<bool> Function(PurchaseDetails purchase) onVerifyPurchase;

  IapService({required this.onVerifyPurchase});

  Future<bool> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return false;

    _subscription = _iap.purchaseStream.listen(_handlePurchaseUpdates, onDone: () => _subscription?.cancel());
    return true;
  }

  Future<Map<String, ProductDetails>> loadCatalog() async {
    final response = await _iap.queryProductDetails(ShopCatalog.allStoreProductIds.toSet());
    if (response.notFoundIDs.isNotEmpty) {
      // Ces IDs doivent être créés dans App Store Connect / Play Console
      // avec exactement les mêmes identifiants que ShopCatalog.
      // ignore: avoid_print
      print('Produits IAP introuvables côté store : ${response.notFoundIDs}');
    }
    return {for (final p in response.productDetails) p.id: p};
  }

  Future<void> buyConsumable(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  Future<void> buySubscription(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;

      if (purchase.status == PurchaseStatus.error) {
        // Achat échoué (annulé, refusé par le moyen de paiement...).
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        final isValid = await onVerifyPurchase(purchase);
        if (isValid && purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  void dispose() => _subscription?.cancel();
}
