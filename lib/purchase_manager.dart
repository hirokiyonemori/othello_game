import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class PurchaseManager {
  static const String _removeAdsKey = 'remove_ads_purchased';
  static const String _removeAdsProductId = 'remove_ads_othello';
  
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static bool _isAvailable = false;
  static List<ProductDetails> _products = [];
  static bool _isPurchased = false;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

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
    
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      print('In-app purchase available: $_isAvailable');
      
      if (_isAvailable) {
        // 購入ストリームをリッスン
        _subscription = _inAppPurchase.purchaseStream.listen(
          _handlePurchaseUpdates,
          onDone: () => _subscription?.cancel(),
          onError: (error) => print('Purchase stream error: $error'),
        );
        
        await _loadProducts();
        await _loadPurchaseStatus();
      }
    } catch (e) {
      print('Failed to initialize purchase manager: $e');
      _isAvailable = false;
    }
  }

  static Future<void> _loadProducts() async {
    try {
      const Set<String> productIds = {_removeAdsProductId};
      
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
      }
      
      if (response.error != null) {
        print('Product query error: ${response.error}');
      }
      
      _products = response.productDetails;
      print('Loaded ${_products.length} products');
      
      for (var product in _products) {
        print('Product: ${product.id} - ${product.title} - ${product.price}');
      }
    } catch (e) {
      print('Failed to load products: $e');
    }
  }

  static Future<void> _loadPurchaseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPurchased = prefs.getBool(_removeAdsKey) ?? false;
      print('Purchase status loaded: $_isPurchased');
    } catch (e) {
      print('Failed to load purchase status: $e');
      _isPurchased = false;
    }
  }

  static Future<bool> purchaseRemoveAds() async {
    if (kIsWeb) {
      // Webではダミーの成功を返す
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }
    
    if (!_isAvailable) {
      print('In-app purchase not available');
      return false;
    }
    
    if (_products.isEmpty) {
      print('No products available for purchase');
      return false;
    }

    try {
      final ProductDetails product = _products.first;
      print('Attempting to purchase: ${product.id}');
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      
      print('Purchase initiated: $success');
      return success;
    } catch (e) {
      print('Purchase failed: $e');
      return false;
    }
  }

  static void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      print('Purchase status: ${purchaseDetails.status}');
      
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          print('Purchase pending');
          break;
          
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          print('Purchase successful: ${purchaseDetails.productID}');
          _verifyPurchase(purchaseDetails);
          break;
          
        case PurchaseStatus.error:
          print('Purchase error: ${purchaseDetails.error}');
          break;
          
        case PurchaseStatus.canceled:
          print('Purchase canceled');
          break;
      }
      
      if (purchaseDetails.pendingCompletePurchase) {
        print('Completing purchase');
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  static Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // Verify the purchase
      if (purchaseDetails.productID == _removeAdsProductId) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_removeAdsKey, true);
        _isPurchased = true;
        print('Remove ads purchased successfully');
      }
    } catch (e) {
      print('Failed to verify purchase: $e');
    }
  }

  static Future<void> restorePurchases() async {
    if (kIsWeb) {
      return; // Webでは何もしない
    }
    
    try {
      print('Restoring purchases...');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('Failed to restore purchases: $e');
    }
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

  static void dispose() {
    _subscription?.cancel();
  }
} 