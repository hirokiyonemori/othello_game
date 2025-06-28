import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class PurchaseManager {
  static const String _removeAdsKey = 'remove_ads_purchased';
  static const String _removeAdsProductId = 'remove_ads_othello';
  
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static bool _isAvailable = false;
  static List<ProductDetails> _products = [];
  static bool _isPurchased = false;

  static bool get isAvailable => _isAvailable;
  static List<ProductDetails> get products => _products;
  static bool get isPurchased => _isPurchased;

  static Future<void> initialize() async {
    if (kIsWeb) {
      // Webでは課金機能を無効化
      _isAvailable = false;
      _isPurchased = false;
      return;
    }
    
    _isAvailable = await _inAppPurchase.isAvailable();
    
    if (_isAvailable) {
      await _loadProducts();
      await _loadPurchaseStatus();
    }
  }

  static Future<void> _loadProducts() async {
    const Set<String> productIds = {_removeAdsProductId};
    
    final ProductDetailsResponse response = 
        await _inAppPurchase.queryProductDetails(productIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }
    
    _products = response.productDetails;
  }

  static Future<void> _loadPurchaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPurchased = prefs.getBool(_removeAdsKey) ?? false;
  }

  static Future<bool> purchaseRemoveAds() async {
    if (kIsWeb) {
      // Webではダミーの成功を返す
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }
    
    if (!_isAvailable || _products.isEmpty) {
      return false;
    }

    final ProductDetails product = _products.first;
    
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    try {
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      
      if (success) {
        // Listen for purchase updates
        _inAppPurchase.purchaseStream.listen(_handlePurchaseUpdates);
      }
      
      return success;
    } catch (e) {
      print('Purchase failed: $e');
      return false;
    }
  }

  static void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchase
        print('Purchase pending');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // Handle successful purchase
        _verifyPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        print('Purchase error: ${purchaseDetails.error}');
      }
      
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  static Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Verify the purchase
    if (purchaseDetails.productID == _removeAdsProductId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_removeAdsKey, true);
      _isPurchased = true;
      print('Remove ads purchased successfully');
    }
  }

  static Future<void> restorePurchases() async {
    if (kIsWeb) {
      return; // Webでは何もしない
    }
    
    await _inAppPurchase.restorePurchases();
  }

  static String getPrice() {
    if (kIsWeb) {
      return '¥250'; // Web用のデフォルト価格
    }
    
    if (_products.isNotEmpty) {
      return _products.first.price;
    }
    return '¥250'; // Default price
  }

  static String getProductId() {
    return _removeAdsProductId;
  }
} 