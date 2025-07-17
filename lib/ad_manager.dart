import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';

class AdManager {
  static const String _rewardedAdWatchedDateKey = 'rewarded_ad_watched_date';
  static const String _appLaunchCountKey = 'app_launch_count';
  static const String _lastLaunchDateKey = 'last_launch_date';
  static const String _gameStartCountKey = 'game_start_count';
  static const String _gameStartDateKey = 'game_start_date';
  static bool _isAdFreeToday = false;
  static int _launchCount = 0;
  static int _gameStartCount = 0;

  // その日のリワード広告視聴状態をチェック
  static Future<void> checkAdFreeStatus() async {
    if (kIsWeb) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastWatchedDate = prefs.getString(_rewardedAdWatchedDateKey);
      
      if (lastWatchedDate != null) {
        final lastWatched = DateTime.parse(lastWatchedDate);
        final today = DateTime.now();
        
        // 同じ日かチェック（年、月、日が同じ）
        _isAdFreeToday = lastWatched.year == today.year &&
                        lastWatched.month == today.month &&
                        lastWatched.day == today.day;
      } else {
        _isAdFreeToday = false;
      }
    } catch (e) {
      print('Error checking ad free status: $e');
      _isAdFreeToday = false;
    }
  }

  // アプリ起動カウントを更新
  static Future<void> updateLaunchCount() async {
    if (kIsWeb) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0]; // YYYY-MM-DD形式
      
      final lastLaunchDate = prefs.getString(_lastLaunchDateKey);
      
      // 日付が変わったらカウントをリセット
      if (lastLaunchDate != todayString) {
        _launchCount = 1;
        await prefs.setString(_lastLaunchDateKey, todayString);
      } else {
        _launchCount = prefs.getInt(_appLaunchCountKey) ?? 0;
        _launchCount++;
      }
      
      await prefs.setInt(_appLaunchCountKey, _launchCount);
      print('App launch count: $_launchCount');
    } catch (e) {
      print('Error updating launch count: $e');
      _launchCount = 1;
    }
  }

  // 2回目の起動かどうかをチェック
  static bool get shouldShowInterstitialOnLaunch {
    if (kIsWeb) return false;
    return _launchCount == 2 && shouldShowAds;
  }

  // リワード広告視聴完了時の処理
  static Future<void> markRewardedAdWatched() async {
    if (kIsWeb) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String();
      await prefs.setString(_rewardedAdWatchedDateKey, today);
      _isAdFreeToday = true;
    } catch (e) {
      print('Error marking rewarded ad as watched: $e');
    }
  }

  // その日広告を表示するかどうか
  static bool get shouldShowAds {
    if (kIsWeb) return false;
    return !_isAdFreeToday;
  }

  static String get bannerAdUnitId {
    // 本番用IDのみ返す
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-8148356110096114/7896973138'; // Android banner
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-8148356110096114/8259370564'; // iOS banner
    }
    // その他はデフォルトでiOS本番ID
    return 'ca-app-pub-8148356110096114/8259370564';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Web test ad
    }
    
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ad unit ID
    }
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-8148356110096114/1435931599'; // Android interstitial
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-8148356110096114/3469948435'; // iOS interstitial
    }
    
    return 'ca-app-pub-3940256099942544/1033173712'; // Default test ad
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

  // Interstitial Ad
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  static Future<void> loadInterstitialAd() async {
    if (kIsWeb || !shouldShowAds) {
      _isInterstitialAdReady = true; // Dummy for web or ad-free day
      return;
    }
    
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          print('Interstitial ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialAdReady = false;
          print('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  static bool get isInterstitialAdReady => _isInterstitialAdReady;

  static Future<void> showInterstitialAd() async {
    if (kIsWeb || !shouldShowAds) {
      // Dummy for web or ad-free day
      await Future.delayed(const Duration(seconds: 2));
      return;
    }
    
    if (!_isInterstitialAdReady || _interstitialAd == null) {
      return;
    }

    await _interstitialAd!.show();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
    
    // Load the next ad
    loadInterstitialAd();
  }

  // Rewarded Ad
  static RewardedAd? _rewardedAd;
  static bool _isRewardedAdReady = false;

  // ヒント機能用のリワード広告ユニットID（本番用）
  static const String _rewardedAdUnitId = 'ca-app-pub-8148356110096114/9415721322';

  // リワード広告を読み込み
  static Future<void> loadRewardedAd() async {
    if (kIsWeb) return;

    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
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
    } catch (e) {
      print('Error loading rewarded ad: $e');
    }
  }

  // リワード広告を表示
  static Future<bool> showRewardedAd() async {
    if (kIsWeb || !_isRewardedAdReady || _rewardedAd == null) {
      return false;
    }

    try {
      bool rewardEarned = false;
      
      // 広告を表示（広告が閉じられるまで待機）
      await _rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          rewardEarned = true;
          print('User earned reward: ${reward.amount} ${reward.type}');
        },
      );

      // 広告を破棄して新しい広告を読み込み
      _rewardedAd!.dispose();
      _rewardedAd = null;
      _isRewardedAdReady = false;
      
      // 新しい広告を読み込み
      loadRewardedAd();

      print('Rewarded ad closed, returning reward status: $rewardEarned');
      return rewardEarned;
    } catch (e) {
      print('Error showing rewarded ad: $e');
      return false;
    }
  }

  // リワード広告の準備状況を確認
  static bool get isRewardedAdReady => _isRewardedAdReady;

  // 広告を破棄
  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;
  }

  // ゲーム開始カウントを更新
  static Future<void> updateGameStartCount() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];
      final lastGameStartDate = prefs.getString(_gameStartDateKey);
      if (lastGameStartDate != todayString) {
        _gameStartCount = 1;
        await prefs.setString(_gameStartDateKey, todayString);
      } else {
        _gameStartCount = prefs.getInt(_gameStartCountKey) ?? 0;
        _gameStartCount++;
      }
      await prefs.setInt(_gameStartCountKey, _gameStartCount);
      print('Game start count: $_gameStartCount');
    } catch (e) {
      print('Error updating game start count: $e');
      _gameStartCount = 1;
    }
  }

  static bool get shouldShowInterstitialOnGameStart {
    if (kIsWeb) return false;
    return _gameStartCount >= 5 && shouldShowAds;
  }

  // IDFA関連のメソッド
  static bool get isIDFASupported {
    if (kIsWeb) return false;
    if (Platform.isIOS) {
      // iOS 14.5以降でIDFAがサポートされている
      return true;
    }
    return false;
  }

  static String getIDFAStatusDescription() {
    if (kIsWeb) return 'WebではIDFAはサポートされていません';
    if (!Platform.isIOS) return 'AndroidではIDFAは使用されません';
    return 'iOS 14.5以降でIDFAの許可が必要です';
  }

  // 広告リクエストにIDFA情報を含める
  static AdRequest createAdRequest() {
    if (kIsWeb) {
      return const AdRequest();
    }
    
    // iOSの場合、IDFAの許可状態に応じて広告リクエストを調整
    if (Platform.isIOS) {
      // 実際のアプリでは、IDFAの許可状態をチェックして
      // 適切な広告リクエストを作成する
      return const AdRequest();
    }
    
    return const AdRequest();
  }
} 