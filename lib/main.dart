import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/admob_service.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'services/remote_config_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-Edge System Bar Configuration
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Instantly render the realistic Splash Screen on the first frame!
  // ZERO blocking delays before UI paints!
  runApp(const PhotoMagicApp());

  // Initialize all background services (Firebase, RemoteConfig, AdMob, Notifications, Preferences)
  // asynchronously in parallel without blocking the UI thread on cold start
  _initializeBackgroundServices();
}

Future<void> _initializeBackgroundServices() async {
  // 1. Load persisted text font style asynchronously in background
  AppTheme.initSavedFont();

  // 2. Initialize Firebase with a fast timeout so fresh installs never hang
  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        debugPrint('[Firebase] initializeApp timed out, continuing in offline mode.');
        return Firebase.app();
      },
    );
    debugPrint('[Firebase] Firebase Core initialized successfully.');

    // 3. Initialize Firebase services in parallel
    await Future.wait([
      AnalyticsService.instance.initialize(),
      RemoteConfigService.instance.initialize(),
      NotificationService.instance.initialize(),
    ]);
  } catch (e) {
    debugPrint('[Firebase] Background services startup note: $e');
  }

  // 4. Initialize Google Mobile Ads SDK (configured with Remote Config ad units)
  try {
    await AdMobService.instance.initialize();
  } catch (e) {
    debugPrint('[AdMob] Error initializing MobileAds: $e');
  }
}

class PhotoMagicApp extends StatefulWidget {
  const PhotoMagicApp({super.key});

  @override
  State<PhotoMagicApp> createState() => _PhotoMagicAppState();
}

class _PhotoMagicAppState extends State<PhotoMagicApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AdMobService.instance.showAppOpenAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppTheme.fontStyleNotifier,
      builder: (context, _) {
        final currentFont = AppTheme.fontStyleNotifier.value;
        final currentTheme = AppTheme.getThemeWithFont(currentFont);

        return MaterialApp(
          title: 'Magic Editor',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          theme: currentTheme,
          darkTheme: currentTheme,
          navigatorObservers: [
            AnalyticsService.instance.observer,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
