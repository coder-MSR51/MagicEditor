import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// Safe NavigatorObserver proxy that forwards route transitions to FirebaseAnalyticsObserver
/// once Firebase has initialized asynchronously, preventing cold-start crashes.
class SafeAnalyticsObserver extends NavigatorObserver {
  FirebaseAnalyticsObserver? _delegate;

  void attachObserver(FirebaseAnalytics analytics) {
    _delegate = FirebaseAnalyticsObserver(analytics: analytics);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    try {
      _delegate?.didPush(route, previousRoute);
    } catch (_) {}
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    try {
      _delegate?.didPop(route, previousRoute);
    } catch (_) {}
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    try {
      _delegate?.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    } catch (_) {}
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    try {
      _delegate?.didRemove(route, previousRoute);
    } catch (_) {}
  }
}

/// Centralized Firebase Analytics Service for tracking user engagement,
/// ad impressions/clicks, photo editing workflows, and feature usage.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final SafeAnalyticsObserver _safeObserver = SafeAnalyticsObserver();
  FirebaseAnalytics? _analyticsInstance;
  bool _isInitialized = false;

  FirebaseAnalytics? get analytics => _analyticsInstance;
  FirebaseAnalytics? get _analytics => _analyticsInstance;

  /// Route observer to safely track screen transitions in MaterialApp even before Firebase finishes initializing
  SafeAnalyticsObserver get observer => _safeObserver;

  /// Initialize and log initial app open
  Future<void> initialize() async {
    try {
      _analyticsInstance = FirebaseAnalytics.instance;
      _safeObserver.attachObserver(_analyticsInstance!);
      await _analyticsInstance!.setAnalyticsCollectionEnabled(true);
      await _analyticsInstance!.logAppOpen();
      _isInitialized = true;
      debugPrint('[AnalyticsService] Firebase Analytics initialized.');
    } catch (e) {
      debugPrint('[AnalyticsService] Error initializing analytics: $e');
    }
  }

  /// Log generic custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_isInitialized || _analyticsInstance == null) return;
    try {
      await _analyticsInstance!.logEvent(
        name: name,
        parameters: parameters,
      );
      debugPrint('[AnalyticsService] Logged event: $name $parameters');
    } catch (e) {
      debugPrint('[AnalyticsService] Failed to log event $name: $e');
    }
  }

  /// Screen navigation tracking
  Future<void> logScreenView({required String screenName}) async {
    if (!_isInitialized || _analyticsInstance == null) return;
    try {
      await _analyticsInstance!.logScreenView(screenName: screenName);
      debugPrint('[AnalyticsService] Screen view: $screenName');
    } catch (e) {
      debugPrint('[AnalyticsService] Failed to log screen view: $e');
    }
  }

  /// Photo Editing Actions
  Future<void> logPhotoEdited({required String toolName}) async {
    await logEvent(
      name: 'photo_edited',
      parameters: {'tool': toolName},
    );
  }

  Future<void> logFilterApplied({required String filterName}) async {
    await logEvent(
      name: 'filter_applied',
      parameters: {'filter': filterName},
    );
  }

  Future<void> logCollageCreated({
    required int photoCount,
    required String layoutType,
  }) async {
    await logEvent(
      name: 'collage_created',
      parameters: {
        'photo_count': photoCount,
        'layout': layoutType,
      },
    );
  }

  Future<void> logPhotoSaved() async {
    await logEvent(name: 'photo_saved');
  }

  Future<void> logPhotoShared() async {
    await logEvent(name: 'photo_shared');
  }

  /// Ad Lifecycle & Performance tracking
  Future<void> logAdImpression({
    required String adType,
    required String adUnitId,
    required bool isTestAd,
  }) async {
    await logEvent(
      name: 'ad_impression_custom',
      parameters: {
        'ad_type': adType,
        'ad_unit_id': adUnitId,
        'is_test_ad': isTestAd ? 1 : 0,
      },
    );
  }

  Future<void> logAdDismissed({required String adType}) async {
    await logEvent(
      name: 'ad_dismissed_custom',
      parameters: {'ad_type': adType},
    );
  }

  Future<void> logAdRewardEarned({
    required String rewardType,
    required num amount,
  }) async {
    await logEvent(
      name: 'ad_reward_earned',
      parameters: {
        'reward_type': rewardType,
        'reward_amount': amount,
      },
    );
  }

  Future<void> logVipUnlocked({required String feature}) async {
    await logEvent(
      name: 'vip_unlocked',
      parameters: {'feature': feature},
    );
  }

  /// Remote Config sync event
  Future<void> logRemoteConfigUpdated({
    required bool adsEnabled,
    required bool useTestAds,
  }) async {
    await logEvent(
      name: 'remote_config_updated',
      parameters: {
        'ads_enabled': adsEnabled ? 1 : 0,
        'use_test_ads': useTestAds ? 1 : 0,
      },
    );
  }
}
