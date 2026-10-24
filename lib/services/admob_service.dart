import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'analytics_service.dart';
import 'remote_config_service.dart';

class AdMobService {
  AdMobService._();
  static final AdMobService instance = AdMobService._();

  // Official Google AdMob Test Unit IDs for Android
  static const String _testAppOpenId = 'ca-app-pub-3940256099942544/9257390322';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';

  // --- Dynamic Getters backed by Firebase Remote Config ---

  /// Controls whether ads use Google's official test ad IDs or production IDs.
  /// Sourced directly from Firebase Remote Config (`use_test_ads`).
  static bool get useTestAds => RemoteConfigService.instance.useTestAds;

  /// Master switch to enable/disable ads remotely
  static bool get adsEnabled => RemoteConfigService.instance.adsEnabled;

  /// Dynamic Ad Unit IDs
  static String get appOpenAdUnitId =>
      useTestAds ? _testAppOpenId : RemoteConfigService.instance.adUnitAppOpen;

  static String get interstitialAdUnitId =>
      useTestAds ? _testInterstitialId : RemoteConfigService.instance.adUnitInterstitial;

  static String get rewardedAdUnitId =>
      useTestAds ? _testRewardedId : RemoteConfigService.instance.adUnitRewarded;

  static String get bannerAdUnitId =>
      useTestAds ? _testBannerId : RemoteConfigService.instance.adUnitBanner;

  // --- Internal State ---
  bool _isInitialized = false;

  // Flag to suppress App Open ad when returning from image_picker (gallery / camera)
  bool isPhotoPickerActive = false;

  // Ad references
  AppOpenAd? _appOpenAd;
  bool _isAppOpenLoading = false;
  bool _isShowingAppOpenAd = false;
  DateTime? _lastAppOpenShownTime;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  DateTime? _lastInterstitialShownTime;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  StreamSubscription<void>? _remoteConfigSubscription;

  /// Initialize Mobile Ads SDK and preload initial ads
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdMobService] MobileAds initialized successfully. (useTestAds: $useTestAds)');

      // Listen for live Remote Config changes to refresh ads if needed
      _remoteConfigSubscription = RemoteConfigService.instance.onConfigUpdated.listen((_) {
        debugPrint('[AdMobService] Remote Config updated. Refreshing ad instances...');
        _onRemoteConfigUpdated();
      });

      // Preload initial ads if enabled
      if (adsEnabled) {
        if (RemoteConfigService.instance.appOpenEnabled) loadAppOpenAd();
        if (RemoteConfigService.instance.interstitialEnabled) loadInterstitialAd();
        if (RemoteConfigService.instance.rewardedEnabled) loadRewardedAd();
      } else {
        debugPrint('[AdMobService] Ads are currently disabled via Remote Config.');
      }
    } catch (e) {
      debugPrint('[AdMobService] Error initializing MobileAds: $e');
    }
  }

  void _onRemoteConfigUpdated() {
    if (!adsEnabled) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _rewardedAd?.dispose();
      _rewardedAd = null;
      return;
    }

    if (RemoteConfigService.instance.appOpenEnabled && _appOpenAd == null) {
      loadAppOpenAd();
    }
    if (RemoteConfigService.instance.interstitialEnabled && _interstitialAd == null) {
      loadInterstitialAd();
    }
    if (RemoteConfigService.instance.rewardedEnabled && _rewardedAd == null) {
      loadRewardedAd();
    }
  }

  // ==========================================
  // 1. APP OPEN ADS
  // ==========================================

  void loadAppOpenAd() {
    if (!adsEnabled || !RemoteConfigService.instance.appOpenEnabled) return;
    if (_appOpenAd != null || _isAppOpenLoading) return;
    _isAppOpenLoading = true;

    final adUnit = appOpenAdUnitId;
    AppOpenAd.load(
      adUnitId: adUnit,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenLoading = false;
          debugPrint('[AdMobService] App Open ad loaded with ID: $adUnit');
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          _isAppOpenLoading = false;
          debugPrint('[AdMobService] App Open ad failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Show App Open ad on app resume or launch if cooldown and constraints allow
  void showAppOpenAdIfAvailable({VoidCallback? onDismissed}) {
    if (!adsEnabled || !RemoteConfigService.instance.appOpenEnabled) {
      onDismissed?.call();
      return;
    }

    // Suppress if photo picker was active (returning from gallery intent)
    if (isPhotoPickerActive) {
      debugPrint('[AdMobService] App Open ad suppressed: Photo picker is active.');
      onDismissed?.call();
      return;
    }

    if (_isShowingAppOpenAd) {
      onDismissed?.call();
      return;
    }

    // Cooldown check from Remote Config
    final cooldown = RemoteConfigService.instance.appOpenCooldown;
    if (_lastAppOpenShownTime != null) {
      final elapsed = DateTime.now().difference(_lastAppOpenShownTime!);
      if (elapsed < cooldown) {
        debugPrint('[AdMobService] App Open ad cooldown active (${elapsed.inSeconds}s < ${cooldown.inSeconds}s).');
        onDismissed?.call();
        return;
      }
    }

    if (_appOpenAd == null) {
      debugPrint('[AdMobService] App Open ad not ready. Loading for next time...');
      loadAppOpenAd();
      onDismissed?.call();
      return;
    }

    final adUnit = appOpenAdUnitId;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAppOpenAd = true;
        AnalyticsService.instance.logAdImpression(
          adType: 'app_open',
          adUnitId: adUnit,
          isTestAd: useTestAds,
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpenAd = false;
        _lastAppOpenShownTime = DateTime.now();
        AnalyticsService.instance.logAdDismissed(adType: 'app_open');
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
        onDismissed?.call();
      },
    );

    _appOpenAd!.show();
  }

  // ==========================================
  // 2. INTERSTITIAL ADS
  // ==========================================

  void loadInterstitialAd() {
    if (!adsEnabled || !RemoteConfigService.instance.interstitialEnabled) return;
    if (_interstitialAd != null || _isInterstitialLoading) return;
    _isInterstitialLoading = true;

    final adUnit = interstitialAdUnitId;
    InterstitialAd.load(
      adUnitId: adUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('[AdMobService] Interstitial ad loaded with ID: $adUnit');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
          debugPrint('[AdMobService] Interstitial ad failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Show Interstitial ad after save or key actions with frequency capping
  void showInterstitialAd({VoidCallback? onDismissed}) {
    if (!adsEnabled || !RemoteConfigService.instance.interstitialEnabled) {
      onDismissed?.call();
      return;
    }

    // Frequency cap check from Remote Config
    final cooldown = RemoteConfigService.instance.interstitialCooldown;
    if (_lastInterstitialShownTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialShownTime!);
      if (elapsed < cooldown) {
        debugPrint('[AdMobService] Interstitial cooldown active (${elapsed.inSeconds}s < ${cooldown.inSeconds}s).');
        onDismissed?.call();
        return;
      }
    }

    if (_interstitialAd == null) {
      debugPrint('[AdMobService] Interstitial ad not ready. Loading...');
      loadInterstitialAd();
      onDismissed?.call();
      return;
    }

    final adUnit = interstitialAdUnitId;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        AnalyticsService.instance.logAdImpression(
          adType: 'interstitial',
          adUnitId: adUnit,
          isTestAd: useTestAds,
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        _lastInterstitialShownTime = DateTime.now();
        AnalyticsService.instance.logAdDismissed(adType: 'interstitial');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDismissed?.call();
      },
    );

    _interstitialAd!.show();
  }

  // ==========================================
  // 3. REWARDED ADS
  // ==========================================

  void loadRewardedAd() {
    if (!adsEnabled || !RemoteConfigService.instance.rewardedEnabled) return;
    if (_rewardedAd != null || _isRewardedLoading) return;
    _isRewardedLoading = true;

    final adUnit = rewardedAdUnitId;
    RewardedAd.load(
      adUnitId: adUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          debugPrint('[AdMobService] Rewarded ad loaded with ID: $adUnit');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedLoading = false;
          debugPrint('[AdMobService] Rewarded ad failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Show Rewarded ad on voluntary user action (e.g. unlock VIP templates)
  void showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onDismissed,
    VoidCallback? onFailed,
  }) {
    if (!adsEnabled || !RemoteConfigService.instance.rewardedEnabled) {
      debugPrint('[AdMobService] Rewarded ads disabled via Remote Config. Granting access.');
      onUserEarnedReward(RewardItem(1, 'remote_bypass'));
      onDismissed?.call();
      return;
    }

    if (_rewardedAd != null) {
      _presentRewardedAd(
        ad: _rewardedAd!,
        onUserEarnedReward: onUserEarnedReward,
        onDismissed: onDismissed,
        onFailed: onFailed,
      );
      return;
    }

    // If preloaded ad is not ready, attempt immediate load and present
    debugPrint('[AdMobService] Rewarded ad not ready. Attempting immediate on-demand load...');
    _isRewardedLoading = true;
    final adUnit = rewardedAdUnitId;
    RewardedAd.load(
      adUnitId: adUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isRewardedLoading = false;
          debugPrint('[AdMobService] On-demand rewarded ad loaded successfully.');
          _presentRewardedAd(
            ad: ad,
            onUserEarnedReward: onUserEarnedReward,
            onDismissed: onDismissed,
            onFailed: onFailed,
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedLoading = false;
          debugPrint('[AdMobService] Rewarded ad failed to load: ${error.message}');
          onFailed?.call();
        },
      ),
    );
  }

  void _presentRewardedAd({
    required RewardedAd ad,
    required Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onDismissed,
    VoidCallback? onFailed,
  }) {
    final adUnit = rewardedAdUnitId;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (adInstance) {
        AnalyticsService.instance.logAdImpression(
          adType: 'rewarded',
          adUnitId: adUnit,
          isTestAd: useTestAds,
        );
      },
      onAdDismissedFullScreenContent: (adInstance) {
        AnalyticsService.instance.logAdDismissed(adType: 'rewarded');
        adInstance.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Preload next rewarded ad
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (adInstance, error) {
        adInstance.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onFailed?.call();
      },
    );

    ad.show(
      onUserEarnedReward: (adInstance, reward) {
        debugPrint('[AdMobService] User earned reward: ${reward.amount} ${reward.type}');
        AnalyticsService.instance.logAdRewardEarned(
          rewardType: reward.type,
          amount: reward.amount,
        );
        onUserEarnedReward(reward);
      },
    );
  }

  void dispose() {
    _remoteConfigSubscription?.cancel();
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
