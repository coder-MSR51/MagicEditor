import 'dart:async';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

/// Centralized service to manage Firebase Remote Config.
/// Allows remote control of:
/// - Ad activation flags (master ads switch, app open, interstitial, rewarded, banner)
/// - Test mode vs Production mode toggle (`use_test_ads`)
/// - Ad unit IDs for App Open, Interstitial, Rewarded, and Banner
/// - Dynamic cooldowns and frequency capping
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Stream controller to notify listeners (e.g. AdMobService) when configs change live
  final StreamController<void> _configUpdatesController = StreamController<void>.broadcast();
  Stream<void> get onConfigUpdated => _configUpdatesController.stream;

  // Remote Config Parameter Keys
  static const String keyAdsEnabled = 'ads_enabled';
  static const String keyUseTestAds = 'use_test_ads';
  static const String keyAppOpenEnabled = 'app_open_enabled';
  static const String keyInterstitialEnabled = 'interstitial_enabled';
  static const String keyRewardedEnabled = 'rewarded_enabled';
  static const String keyBannerEnabled = 'banner_enabled';

  static const String keyAdUnitAppOpen = 'ad_unit_app_open';
  static const String keyAdUnitInterstitial = 'ad_unit_interstitial';
  static const String keyAdUnitRewarded = 'ad_unit_rewarded';
  static const String keyAdUnitBanner = 'ad_unit_banner';

  static const String keyInterstitialCooldownSec = 'interstitial_cooldown_seconds';
  static const String keyAppOpenCooldownSec = 'app_open_cooldown_seconds';

  // Fallback Production Unit IDs
  static const String defaultProdAppOpenId = 'ca-app-pub-5058759516035385/4609157321';
  static const String defaultProdInterstitialId = 'ca-app-pub-5058759516035385/6935937761';
  static const String defaultProdRewardedId = 'ca-app-pub-5058759516035385/1332257293';
  static const String defaultProdBannerId = 'ca-app-pub-5058759516035385/6300978111';

  /// Initialize Firebase Remote Config with default fallbacks and fetch latest settings
  Future<void> initialize() async {
    try {
      // Set fast fetch timeouts and intervals (avoid stalling on cold start)
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 3),
          // In debug/profile mode fetch quickly; in release fetch at least every 1 hour
          minimumFetchInterval: kDebugMode ? const Duration(seconds: 10) : const Duration(hours: 1),
        ),
      );

      // Define offline & default values
      await _remoteConfig.setDefaults(<String, dynamic>{
        keyAdsEnabled: true,
        keyUseTestAds: false, // Default to production IDs for release
        keyAppOpenEnabled: true,
        keyInterstitialEnabled: true,
        keyRewardedEnabled: true,
        keyBannerEnabled: true,
        keyAdUnitAppOpen: defaultProdAppOpenId,
        keyAdUnitInterstitial: defaultProdInterstitialId,
        keyAdUnitRewarded: defaultProdRewardedId,
        keyAdUnitBanner: defaultProdBannerId,
        keyInterstitialCooldownSec: 180, // 3 minutes
        keyAppOpenCooldownSec: 240, // 4 minutes
      });

      // Fast initial fetch and activate (fail-fast to default config without waiting on poor network)
      try {
        final updated = await _remoteConfig.fetchAndActivate().timeout(const Duration(seconds: 2));
        debugPrint('[RemoteConfigService] Initialized. Activated new config: $updated');
      } catch (e) {
        debugPrint('[RemoteConfigService] Fast timeout or offline, activated default local config: $e');
        await _remoteConfig.activate();
      }

      // Log to analytics
      AnalyticsService.instance.logRemoteConfigUpdated(
        adsEnabled: adsEnabled,
        useTestAds: useTestAds,
      );

      // Listen to real-time config updates (Firebase Remote Config Realtime API)
      _remoteConfig.onConfigUpdated.listen((RemoteConfigUpdate update) async {
        debugPrint('[RemoteConfigService] Realtime update detected: ${update.updatedKeys}');
        await _remoteConfig.activate();
        _configUpdatesController.add(null);

        AnalyticsService.instance.logRemoteConfigUpdated(
          adsEnabled: adsEnabled,
          useTestAds: useTestAds,
        );
      });
    } catch (e) {
      debugPrint('[RemoteConfigService] Error initializing Remote Config: $e');
    }
  }

  // --- Getters for App Logic ---

  /// Master switch to enable or disable all ads remotely
  bool get adsEnabled => _remoteConfig.getBool(keyAdsEnabled);

  /// Toggle between Google official test ads and live production ads
  bool get useTestAds => _remoteConfig.getBool(keyUseTestAds);

  /// Ad format switches
  bool get appOpenEnabled => adsEnabled && _remoteConfig.getBool(keyAppOpenEnabled);
  bool get interstitialEnabled => adsEnabled && _remoteConfig.getBool(keyInterstitialEnabled);
  bool get rewardedEnabled => adsEnabled && _remoteConfig.getBool(keyRewardedEnabled);
  bool get bannerEnabled => adsEnabled && _remoteConfig.getBool(keyBannerEnabled);

  /// Dynamic Ad Unit IDs from Remote Config (or default fallback)
  String get adUnitAppOpen {
    final val = _remoteConfig.getString(keyAdUnitAppOpen);
    return val.trim().isNotEmpty ? val.trim() : defaultProdAppOpenId;
  }

  String get adUnitInterstitial {
    final val = _remoteConfig.getString(keyAdUnitInterstitial);
    return val.trim().isNotEmpty ? val.trim() : defaultProdInterstitialId;
  }

  String get adUnitRewarded {
    final val = _remoteConfig.getString(keyAdUnitRewarded);
    return val.trim().isNotEmpty ? val.trim() : defaultProdRewardedId;
  }

  String get adUnitBanner {
    final val = _remoteConfig.getString(keyAdUnitBanner);
    return val.trim().isNotEmpty ? val.trim() : defaultProdBannerId;
  }

  /// Dynamic cooldowns
  Duration get interstitialCooldown => Duration(
        seconds: _remoteConfig.getInt(keyInterstitialCooldownSec).clamp(30, 3600),
      );

  Duration get appOpenCooldown => Duration(
        seconds: _remoteConfig.getInt(keyAppOpenCooldownSec).clamp(30, 3600),
      );
}
