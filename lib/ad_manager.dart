import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdManager {
  static String get bannerAdUnitId {
    if (kIsWeb) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Web test ad
    }
    
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ad unit ID
    }
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-8148356110096114/7896973138'; // Android banner
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-8148356110096114/8259370564'; // iOS banner
    }
    
    return 'ca-app-pub-3940256099942544/6300978111'; // Default test ad
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Web test ad
    }
    
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ad unit ID
    }
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-8148356110096114/9551167282'; // Android rewarded
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-8148356110096114/9415721322'; // iOS rewarded
    }
    
    return 'ca-app-pub-3940256099942544/5224354917'; // Default test ad
  }

  static String get appId {
    if (kIsWeb) {
      return 'ca-app-pub-3940256099942544~3347511713'; // Web test app ID
    }
    
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544~3347511713'; // Test app ID
    }
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-8148356110096114~9670038041'; // Android app ID
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-8148356110096114~3800981303'; // iOS app ID
    }
    
    return 'ca-app-pub-3940256099942544~3347511713'; // Default test app ID
  }

  static BannerAd createBannerAd() {
    if (kIsWeb) {
      // Return a dummy ad for web
      return BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            print('Web banner ad loaded (dummy)');
          },
          onAdFailedToLoad: (ad, error) {
            print('Web banner ad failed to load: $error');
            ad.dispose();
          },
        ),
      );
    }
    
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
  }

  static RewardedAd? _rewardedAd;
  static bool _isRewardedAdReady = false;

  static Future<void> loadRewardedAd() async {
    if (kIsWeb) {
      _isRewardedAdReady = true; // Dummy for web
      return;
    }
    
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          print('Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedAdReady = false;
          print('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  static bool get isRewardedAdReady => _isRewardedAdReady;

  static Future<bool> showRewardedAd() async {
    if (kIsWeb) {
      // Dummy reward for web
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }
    
    if (!_isRewardedAdReady || _rewardedAd == null) {
      return false;
    }

    bool rewardEarned = false;
    
    await _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        rewardEarned = true;
        print('User earned reward: ${reward.amount} ${reward.type}');
      },
    );

    _rewardedAd = null;
    _isRewardedAdReady = false;
    
    // Load the next ad
    loadRewardedAd();
    
    return rewardEarned;
  }

  static void dispose() {
    _rewardedAd?.dispose();
  }
} 