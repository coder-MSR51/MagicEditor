import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/editor_template_model.dart';
import 'collage_screen.dart';
import 'editor_screen.dart';
import 'private_vault_screen.dart';
import '../services/private_vault_service.dart';
import '../services/admob_service.dart';
import '../widgets/vault_pin_dialog.dart';
import 'background_categories_screen.dart';
import 'effects_studio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  late final PageController _pageController;
  int _currentSlide = 0;
  Timer? _slideTimer;

  // Settings & Preferences
  bool _notificationsEnabled = true;
  bool _isPrivacyAgreed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _slideTimer = Timer.periodic(const Duration(milliseconds: 4000), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentSlide + 1) % 5;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _pickImageAndEdit() async {
    try {
      AdMobService.instance.isPhotoPickerActive = true;
      setState(() => _isLoading = true);
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 3840,
        maxHeight: 3840,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditorScreen(imageBytes: bytes),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open image: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      AdMobService.instance.isPhotoPickerActive = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImageForTemplate(EditorTemplate template) async {
    try {
      AdMobService.instance.isPhotoPickerActive = true;
      setState(() => _isLoading = true);
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 3840,
        maxHeight: 3840,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditorScreen(
                imageBytes: bytes,
                initialTemplate: template,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      AdMobService.instance.isPhotoPickerActive = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  CollageLayout _getOptimalCollageLayout(int imageCount, {CollageLayout? preferredLayout}) {
    if (preferredLayout != null && preferredLayout.photoCount == imageCount) {
      return preferredLayout;
    }
    switch (imageCount) {
      case 1:
        return CollageLayout.vogueMagazine;
      case 2:
        return CollageLayout.twoVertical;
      case 3:
        return CollageLayout.threeHeroTop;
      case 4:
        return CollageLayout.fourGrid;
      case 5:
        return CollageLayout.sixGrid;
      case 6:
        return CollageLayout.sixGrid;
      default:
        if (imageCount >= 7) {
          return CollageLayout.tenGrid;
        }
        return CollageLayout.fourGrid;
    }
  }

  Future<void> _pickCollageImages({CollageLayout? initialLayout, CollageBottomTab? initialTab}) async {
    try {
      AdMobService.instance.isPhotoPickerActive = true;
      setState(() => _isLoading = true);
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 3840,
        maxHeight: 3840,
        imageQuality: 100,
      );

      final List<Uint8List> pickedBytes = [];
      for (final file in pickedFiles) {
        pickedBytes.add(await file.readAsBytes());
      }

      if (mounted) {
        final resolvedLayout = pickedBytes.isNotEmpty
            ? _getOptimalCollageLayout(pickedBytes.length, preferredLayout: initialLayout)
            : (initialLayout ?? CollageLayout.fourGrid);

        final resolvedTab = initialTab ??
            (resolvedLayout.type == CollageType.template || resolvedLayout.type == CollageType.shape
                ? CollageBottomTab.shapes
                : CollageBottomTab.layout);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CollageScreen(
              initialImages: pickedBytes.isNotEmpty ? pickedBytes : null,
              initialLayout: resolvedLayout,
              initialTab: resolvedTab,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Fallback open collage screen with demo photos
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CollageScreen(
              initialLayout: initialLayout ?? CollageLayout.fourGrid,
              initialTab: initialTab ?? CollageBottomTab.layout,
            ),
          ),
        );
      }
    } finally {
      AdMobService.instance.isPhotoPickerActive = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openBackgroundStudio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BackgroundCategoriesScreen(),
      ),
    );
  }


  Future<void> _openEffectsStudio() async {
    try {
      AdMobService.instance.isPhotoPickerActive = true;
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 100,
      );
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EffectsStudioScreen(imageBytes: bytes),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    } finally {
      AdMobService.instance.isPhotoPickerActive = false;
    }
  }


  Future<void> _openPrivateVault() async {
    try {
      await PrivateVaultService.checkAndRequestPermissions();
      final isSet = await PrivateVaultService.isPasswordSet();
      if (!mounted) return;

      if (!isSet) {
        // Create password first as requested by user
        final created = await VaultPinDialog.show(context, mode: VaultPinMode.create);
        if (created == true && mounted) {
          // Password created! Directly open gallery to hide photos, then show vault
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PrivateVaultScreen(autoOpenPickerOnStart: true),
            ),
          );
        }
      } else {
        // Unlock existing PIN
        final unlocked = await VaultPinDialog.show(context, mode: VaultPinMode.unlock);
        if (unlocked == true && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PrivateVaultScreen(autoOpenPickerOnStart: false),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing vault: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildSettingsDrawer(),
      backgroundColor: const Color(0xFF0C0E14), // Dark deep sleek theme matching Screenshot 1
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // 1. App Bar Header Matching Screenshot 1
                  _buildHeaderBar(),

                  const SizedBox(height: 14),

                  // 2. Top Slider / Moving Carousel Window (Templates + Background Filters)
                  _buildTopSliderWindow(),

                  const SizedBox(height: 18),

                  // 3. Two Main Big Action Buttons (Collage & Edit) Matching Screenshot 1
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Left Pink Collage Button
                        Expanded(
                          child: _buildBigCollageButton(),
                        ),
                        const SizedBox(width: 14),
                        // Right Purple Edit Button
                        Expanded(
                          child: _buildBigEditButton(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4. Two Rectangle Boxes: Background & Apply Effects (Left & Right)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Left: Background Studio
                        Expanded(
                          child: _buildBackgroundBox(),
                        ),
                        const SizedBox(width: 14),
                        // Right: Apply Effects Studio
                        Expanded(
                          child: _buildApplyEffectsBox(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 5. Private Photo Vault Banner (Secret encrypted space)
                  _buildPrivateVaultBanner(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// 1. Top Bar Header - Original Vibrant Theme
  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Left side: App Logo & Title
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF00F0FF),
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Magic Editor',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Professional Photo Studio',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white54,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Setting Icon Button on Right Corner (Cyan Glow)
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF131722),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.settings_rounded,
                  color: Color(0xFF00F0FF),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Settings Side Slider Drawer (Opens from left side)
  Widget _buildSettingsDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0F121B),
      width: (MediaQuery.of(context).size.width * 0.86).clamp(320.0, 380.0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F0FF), Color(0xFF9D4EDD)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings & Studio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Magic Editor v2.0.2',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. PRIVATE PHOTO VAULT / LOCK CARD (AT TOP OF SETTINGS AS REQUESTED)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF131F33),
                          Color(0xFF0E1424),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _openPrivateVault();
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00F0FF),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.lock_rounded,
                                    color: Color(0xFF00F0FF),
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        const Flexible(
                                          child: Text(
                                            'Private Vault',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'LOCK',
                                            style: TextStyle(
                                              color: Color(0xFF00F0FF),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'PIN-Protected Safe',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Color(0xFF00F0FF),
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Section Title
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
                    child: Text(
                      'PREFERENCES',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  // 2. CHANGE TEXT STYLE (5 TYPOGRAPHY STYLES)
                  ValueListenableBuilder<String>(
                    valueListenable: AppTheme.fontStyleNotifier,
                    builder: (context, activeFont, _) {
                      return _buildDrawerTile(
                        icon: Icons.text_fields_rounded,
                        accentColor: const Color(0xFF00F0FF),
                        title: 'Change Text Style',
                        subtitle: 'Current: $activeFont',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B2234),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                activeFont,
                                style: AppTheme.getFontStyle(
                                  activeFont,
                                  textStyle: const TextStyle(
                                    color: Color(0xFF00F0FF),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 13),
                          ],
                        ),
                        onTap: _showTextStylePickerSheet,
                      );
                    },
                  ),



                  const SizedBox(height: 10),

                  // 4. NOTIFICATION ON / OFF
                  _buildDrawerTile(
                    icon: _notificationsEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                    accentColor: _notificationsEnabled ? const Color(0xFFFF2A85) : Colors.white38,
                    title: 'Notifications',
                    subtitle: _notificationsEnabled ? 'Creative alerts & tips active' : 'Muted',
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      activeThumbColor: const Color(0xFFFF2A85),
                      activeTrackColor: const Color(0xFFFF2A85).withValues(alpha: 0.4),
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF1E2638),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            content: Row(
                              children: [
                                Icon(
                                  val ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                                  color: val ? const Color(0xFFFF2A85) : Colors.white54,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  val ? 'Notifications enabled' : 'Notifications muted',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Section Title
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
                    child: Text(
                      'STUDIO & LEGAL',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  // 5. ABOUT US
                  _buildDrawerTile(
                    icon: Icons.info_outline_rounded,
                    accentColor: const Color(0xFFFFB800),
                    title: 'About Us',
                    subtitle: 'Magic Editor Studio • Team & Tech',
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 13),
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutUsDialog();
                    },
                  ),

                  const SizedBox(height: 10),

                  // 6. PRIVACY POLICY
                  _buildDrawerTile(
                    icon: _isPrivacyAgreed ? Icons.verified_user_rounded : Icons.privacy_tip_rounded,
                    accentColor: const Color(0xFF10B981),
                    title: 'Privacy Policy',
                    subtitle: _isPrivacyAgreed ? 'Agreed & 100% Protected ✓' : 'Tap to read & agree',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isPrivacyAgreed)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                          ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 13),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showPrivacyPolicyDialog();
                    },
                  ),

                  const SizedBox(height: 10),

                  // 7. SHARE APP
                  _buildDrawerTile(
                    icon: Icons.share_rounded,
                    accentColor: const Color(0xFF00F0FF),
                    title: 'Share With Friends',
                    subtitle: 'Recommend Magic Editor studio',
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 13),
                    onTap: () {
                      Navigator.pop(context);
                      _shareApp();
                    },
                  ),
                ],
              ),
            ),

            // Drawer Footer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Magic Editor Studio • Version 2.0.2\n100% On-Device & Safe',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141824),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTextStylePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141824),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.text_fields_rounded, color: Color(0xFF00F0FF), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Text Style',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Select from 5 typography styles for your app',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: AppTheme.textStyles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final style = AppTheme.textStyles[index];
                      final name = style['name'] ?? '';
                      final isSelected = name == AppTheme.fontStyleNotifier.value;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            AppTheme.setFontStyle(name);
                            setState(() {});
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF161F30),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2),
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF00F0FF), size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Text style changed to $name (Saved permanently)',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00F0FF).withValues(alpha: 0.1)
                                  : const Color(0xFF1B2234),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00F0FF)
                                    : Colors.white12,
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF00F0FF).withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF00F0FF) : Colors.white60,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            name,
                                            style: AppTheme.getFontStyle(
                                              name,
                                              textStyle: TextStyle(
                                                color: isSelected ? const Color(0xFF00F0FF) : Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              style['category'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        style['label'] ?? '',
                                        style: TextStyle(
                                          color: isSelected ? const Color(0xFF00F0FF).withValues(alpha: 0.8) : Colors.white54,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        style['sample'] ?? '',
                                        style: AppTheme.getFontStyle(
                                          name,
                                          textStyle: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF00F0FF),
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }



  void _showAboutUsDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF141824),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F0FF), Color(0xFF9D4EDD)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: Colors.black, size: 32),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Magic Editor Studio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Version 2.0.2 (Latest Release)',
                style: TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Empowering Creators Everywhere ✨\n\n'
              'Magic Editor is an all-in-one creative studio featuring GPU Skia hardware-accelerated photo editing, smart collage creation, AI background cutouts, and a secure PIN-encrypted private photo safe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F131D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '100% On-Device & Zero Cloud Upload. Your photos stay strictly private.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F0FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Tabs: Share, Rate, Privacy with Frosted Glassmorphism Effect
  Widget _buildBottomBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF10131B).withValues(alpha: 0.78),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomBarTab(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  accentColor: const Color(0xFF00F0FF),
                  onTap: _shareApp,
                ),
                _buildBottomBarTab(
                  icon: Icons.star_rounded,
                  label: 'Rate',
                  accentColor: const Color(0xFFFFD700),
                  onTap: _showInAppReviewDialog,
                ),
                _buildBottomBarTab(
                  icon: _isPrivacyAgreed ? Icons.verified_user_rounded : Icons.privacy_tip_rounded,
                  label: _isPrivacyAgreed ? 'Agreed ✓' : 'Privacy',
                  accentColor: const Color(0xFF10B981),
                  onTap: _showPrivacyPolicyDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBarTab({
    required IconData icon,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accentColor, size: 21),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: label.contains('✓') ? accentColor : Colors.white70,
                  fontSize: 11,
                  fontWeight: label.contains('✓') ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareApp() {
    const packageName = 'com.photo.magic.editor.msr';
    const storeUrl = 'https://play.google.com/store/apps/details?id=$packageName';
    const professionalShareText =
'''Transform your photos with Magic Editor ✨

The modern, all-in-one creative studio:
✦ Pro Photo Enhancement & Aesthetic Filters
✦ Creative Collages & Dynamic Layouts
✦ Precision Background Cutout Studio
✦ Secure On-Device Private Photo Vault

Download Magic Editor on Google Play:
$storeUrl''';

    SharePlus.instance.share(
      ShareParams(
        text: professionalShareText,
        subject: 'Magic Editor - Professional Photo Studio & Vault',
      ),
    );
  }

  Future<void> _openGooglePlay() async {
    const packageName = 'com.photo.magic.editor.msr';
    final marketUri = Uri.parse('market://details?id=$packageName');
    final playStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');

    try {
      final launched = await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Could not open Google Play: $e');
      }
    }
  }

  Future<void> _openAppStore() async {
    final appStoreUri = Uri.parse('https://apps.apple.com/app/magic-editor/id6470000000');
    try {
      await launchUrl(appStoreUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open App Store: $e');
    }
  }

  Future<void> _openIndusStore() async {
    const packageName = 'com.photo.magic.editor.msr';
    final indusSchemeUri = Uri.parse('indusappstore://app/$packageName');
    final indusWebUri = Uri.parse('https://www.indusappstore.com/apps/$packageName');

    try {
      final launched = await launchUrl(indusSchemeUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(indusWebUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(indusWebUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Could not open Indus Appstore: $e');
      }
    }
  }

  void _showStoreToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E2638),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoreChooserSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161922),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 26),
                    SizedBox(width: 8),
                    Text(
                      'Rate Magic Editor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose your preferred store to write a review:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Google Play Store Tile
                _buildStoreOptionTile(
                  title: 'Google Play Store',
                  subtitle: 'Official Android App Store',
                  icon: Icons.play_arrow_rounded,
                  badgeText: 'Google Play',
                  accentColor: const Color(0xFF00F0FF),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openGooglePlay();
                    _showStoreToast('Opening Google Play Store... Thank you! 💖');
                  },
                ),
                const SizedBox(height: 10),

                // 2. Indus Appstore Tile
                _buildStoreOptionTile(
                  title: 'Indus Appstore',
                  subtitle: 'India\'s App Store by PhonePe',
                  icon: Icons.storefront_rounded,
                  badgeText: 'Indus Store',
                  accentColor: const Color(0xFFFF9900),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openIndusStore();
                    _showStoreToast('Opening Indus Appstore... Thank you! 💖');
                  },
                ),
                const SizedBox(height: 10),

                // 3. Apple App Store Tile
                _buildStoreOptionTile(
                  title: 'Apple App Store',
                  subtitle: 'iOS / Apple App Store',
                  icon: Icons.apple_rounded,
                  badgeText: 'App Store',
                  accentColor: const Color(0xFF64B5F6),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openAppStore();
                    _showStoreToast('Opening App Store... Thank you! 💖');
                  },
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoreOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1219),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: accentColor, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  void _showInAppReviewDialog() {
    int selectedRating = 5;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String getRatingLabel(int rating) {
              switch (rating) {
                case 1:
                  return 'Needs Work 😞';
                case 2:
                  return 'Fair 😐';
                case 3:
                  return 'Good 🙂';
                case 4:
                  return 'Great! 😊';
                case 5:
                default:
                  return 'Loved It! 🤩💖';
              }
            }

            final isHighRating = selectedRating >= 4;

            return Dialog(
              backgroundColor: const Color(0xFF161922),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD700), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/icons/app_icon.png',
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFFF2A85),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Rate Magic Editor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isHighRating
                          ? 'Thank you for loving Magic Editor! Your review helps us grow.'
                          : 'How was your experience using Magic Editor?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Interactive 5 Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starNumber = index + 1;
                        final isFilled = starNumber <= selectedRating;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedRating = starNumber);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 36,
                              color: isFilled ? const Color(0xFFFFD700) : Colors.white24,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),

                    // Rating description label
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        getRatingLabel(selectedRating),
                        key: ValueKey(selectedRating),
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Feedback text field for suggestions
                    TextField(
                      controller: feedbackController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: isHighRating
                            ? 'What did you like most? (optional)...'
                            : 'Tell us how we can make Magic Editor better...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F1219),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit & Cancel buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isHighRating
                                  ? const Color(0xFFFFB800)
                                  : const Color(0xFF00F0FF),
                              foregroundColor: isHighRating ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                            ),
                            onPressed: () {
                              Navigator.pop(dialogContext);

                              if (isHighRating) {
                                // Show Indus Appstore, Google Play Store and Apple App Store chooser
                                _showStoreChooserSheet();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF1E2638),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    content: const Row(
                                      children: [
                                        Icon(Icons.favorite_rounded, color: Color(0xFFFF2A85), size: 22),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Thank you for your valuable feedback! We will keep improving.',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isHighRating ? Icons.star_rounded : Icons.send_rounded,
                                  size: 16,
                                  color: isHighRating ? Colors.black : Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isHighRating ? 'Rate Us' : 'Submit Feedback',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isHighRating ? Colors.black : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }

  void _showPrivacyPolicyDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131722),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF10B981), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Privacy Policy & Safety',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Your Photos & Data Always Belong To You',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _buildPrivacyItem(
                    icon: Icons.phonelink_lock_rounded,
                    title: '100% On-Device Processing',
                    description: 'All photo edits, filters, and collages are rendered directly on your phone hardware. Your photos are NEVER uploaded to any cloud or external servers.',
                  ),
                  _buildPrivacyItem(
                    icon: Icons.lock_person_rounded,
                    title: 'Encrypted Private Photo Vault',
                    description: 'Photos hidden in Private Vault are stored in a secure offline directory with .nomedia protection, shielded by your personal PIN.',
                  ),
                  _buildPrivacyItem(
                    icon: Icons.no_accounts_rounded,
                    title: 'Zero Tracking & No Account Needed',
                    description: 'We do not collect names, phone numbers, email addresses, or personal identifiers. No login or account is required.',
                  ),
                  _buildPrivacyItem(
                    icon: Icons.photo_library_outlined,
                    title: 'Storage Permissions Transparency',
                    description: 'Device media access is strictly used to load photos you choose to edit and save your finished artwork to your gallery.',
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                      label: Text(
                        _isPrivacyAgreed ? 'You Have Agreed & Protected ✓' : 'Understood & Agree',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      onPressed: () {
                        setState(() => _isPrivacyAgreed = true);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF0F1E17),
                            behavior: SnackBarBehavior.floating,
                            elevation: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                            ),
                            content: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded, color: Colors.black, size: 18),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Privacy Policy Agreed! 🛡️',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Your photos are 100% on-device & protected.',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyItem({required IconData icon, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 3),
                Text(description, style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Top Slider Carousel - Vogue, Harper, Magazine, Spotify Glass, Spatial Audio
  Widget _buildTopSliderWindow() {
    return Column(
      children: [
        SizedBox(
          height: 255,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentSlide = index),
            children: [
              // Slide 1: Y2K Streetwear Magazine Neo-Zine
              _buildMagazineSlide(),

              // Slide 2: Spotify Glass Frosted Music Card (Custom Song)
              _buildSpotifyGlassSlide(),

              // Slide 3: Spatial Audio Dolby Atmos Master
              _buildSpatialAudioSlide(),

              // Slide 4: Vogue Paris Haute Couture (at last)
              _buildVogueParisSlide(),

              // Slide 5: Harper Minimalist Gallery Editorial (at last)
              _buildHarperMinimalistSlide(),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Animated Page Indicator Dots (Vibrant Pink Glow)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final isActive = _currentSlide == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              width: isActive ? 24 : 6,
              height: 4.5,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFFF2A85) : Colors.white24,
                borderRadius: BorderRadius.circular(3),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF2A85).withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Slide 1: Vogue Paris Haute Couture
  Widget _buildVogueParisSlide() {
    return GestureDetector(
      onTap: () => _pickImageForTemplate(EditorTemplate.vogueParis),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C1814), Color(0xFF0E0C09)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -25,
              top: -25,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 11,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                              ),
                              child: const Text(
                                'HAUTE COUTURE',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Flexible(
                              child: Text(
                                'PARIS N° 42',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white54, fontSize: 8.5, fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VOGUE',
                              style: GoogleFonts.cinzel(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                                height: 0.95,
                                color: const Color(0xFFFBF6EE),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'PARIS RUNWAY COVER',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Turn your portrait into an iconic luxury fashion cover.',
                              style: TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.2),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE5B942), Color(0xFFB8860B)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_a_photo_rounded, color: Colors.black, size: 13),
                                SizedBox(width: 5),
                                Text(
                                  'Apply Photo',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10.5,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 11),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    flex: 7,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1A16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.45), width: 1.0),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(2, 3)),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'VOGUE',
                            style: GoogleFonts.cinzel(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                            ),
                            child: const Center(
                              child: Icon(Icons.face_retouching_natural_rounded, color: Color(0xFFD4AF37), size: 28),
                            ),
                          ),
                          Column(
                            children: [
                              const Text('HAUTE COUTURE', style: TextStyle(color: Colors.white70, fontSize: 6.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(10, (i) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 0.8),
                                  width: (i % 3 == 0) ? 2 : 1,
                                  height: 7,
                                  color: Colors.white38,
                                )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Slide 2: Harper Minimalist Gallery Editorial
  Widget _buildHarperMinimalistSlide() {
    return GestureDetector(
      onTap: () => _pickImageForTemplate(EditorTemplate.vogueMinimalist),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E222B), Color(0xFF0F1116)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white24, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: const Text(
                        'EDITORIAL GALLERY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HARPER',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.8,
                            height: 0.95,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'MINIMALIST EXHIBITION',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Museum-grade gallery layout with fine art borders & typography.',
                          style: TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Colors.white24, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_rounded, color: Colors.black, size: 13),
                            SizedBox(width: 5),
                            Text(
                              'Apply Photo',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 11),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 7,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0D11),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24, width: 1.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CONTEMPORARY N° 04',
                        style: TextStyle(color: Colors.white60, fontSize: 6.5, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Center(
                          child: Icon(Icons.museum_rounded, color: Colors.white70, size: 28),
                        ),
                      ),
                      const Text(
                        'EXHIBITION 2026',
                        style: TextStyle(color: Colors.white38, fontSize: 6.5, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Slide 3: Y2K Streetwear Magazine Neo-Zine
  Widget _buildMagazineSlide() {
    return GestureDetector(
      onTap: () => _pickImageForTemplate(EditorTemplate.vogueStreetwear),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B0B13), Color(0xFF140306)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFF2A55).withValues(alpha: 0.55), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2A55).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2A55).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFF2A55), width: 0.8),
                      ),
                      child: const Text(
                        'TOKYO STREETWEAR',
                        style: TextStyle(
                          color: Color(0xFFFF2A55),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAGAZINE',
                          style: GoogleFonts.rubik(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            height: 0.95,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Y2K NEO-ZINE COVER',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Color(0xFFFF7A00),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Distressed Gen-Z typography, barcode stickers & Shibuya editorial.',
                          style: TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF2A55), Color(0xFFFF7A00)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2A55).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 13),
                            SizedBox(width: 5),
                            Text(
                              'Apply Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 11),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 7,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E070B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFF2A55).withValues(alpha: 0.4), width: 1.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ISSUE 2026 // 東京',
                        style: TextStyle(color: Color(0xFFFF7A00), fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF2A55).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFF2A55).withValues(alpha: 0.4)),
                        ),
                        child: const Center(
                          child: Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF2A55), size: 28),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        color: Colors.black,
                        child: const Text('VERIFIED AUTHENTIC', style: TextStyle(color: Colors.white, fontSize: 5.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Slide 4: Spotify Glass Frosted Music Card (Custom Song)
  Widget _buildSpotifyGlassSlide() {
    return GestureDetector(
      onTap: () => _pickImageForTemplate(EditorTemplate.musicSpotify),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF072414), Color(0xFF04120A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.65), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1DB954).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF1DB954), width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.music_note_rounded, color: Color(0xFF1DB954), size: 10),
                          SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              'CUSTOM MUSIC CARD',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF1DB954),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spotify Glass',
                          style: GoogleFonts.inter(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            height: 0.95,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'NOW PLAYING OVERLAY',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Color(0xFF1DB954),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Type your own song & artist name! Frosted glass player with media controls.',
                          style: TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_rounded, color: Colors.black, size: 13),
                            SizedBox(width: 5),
                            Text(
                              'Apply Photo & Song',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 11),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 7,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.4), width: 1.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1DB954),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.music_note, color: Colors.black, size: 13),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Golden Hour', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), maxLines: 1),
                                Text('JVKE', style: TextStyle(color: Colors.white54, fontSize: 6.5), maxLines: 1),
                              ],
                            ),
                          ),
                          const Icon(Icons.favorite_rounded, color: Color(0xFF1DB954), size: 11),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('1:24', style: TextStyle(fontSize: 6, color: Colors.white38)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 20,
                                  decoration: BoxDecoration(color: const Color(0xFF1DB954), borderRadius: BorderRadius.circular(2)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Text('3:45', style: TextStyle(fontSize: 6, color: Colors.white38)),
                        ],
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(Icons.skip_previous_rounded, color: Colors.white54, size: 12),
                          CircleAvatar(radius: 8, backgroundColor: Color(0xFF1DB954), child: Icon(Icons.pause, color: Colors.black, size: 10)),
                          Icon(Icons.skip_next_rounded, color: Colors.white54, size: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Slide 5: Spatial Audio Dolby Atmos Master
  Widget _buildSpatialAudioSlide() {
    return GestureDetector(
      onTap: () => _pickImageForTemplate(EditorTemplate.musicSpatial),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A2E), Color(0xFF0D0417)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.65), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA855F7).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA855F7), width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.graphic_eq_rounded, color: Color(0xFFA855F7), size: 10),
                          SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              'DOLBY ATMOS MASTER',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFFA855F7),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spatial Audio',
                          style: GoogleFonts.inter(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            height: 0.95,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'LOSSLESS DIGITAL MASTER',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Color(0xFFC084FC),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Apple Digital Master loss-free badge with soundwave equalizer bars.',
                          style: TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFA855F7).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 13),
                            SizedBox(width: 5),
                            Text(
                              'Apply Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 11),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 7,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4), width: 1.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3)),
                            child: const Text('LOSSLESS', style: TextStyle(color: Colors.white70, fontSize: 6, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3)),
                            child: const Text('SPATIAL', style: TextStyle(color: Colors.white70, fontSize: 6, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Column(
                        children: [
                          Text('AirPods Max Master', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('32-Bit Lossless', style: TextStyle(color: Colors.white54, fontSize: 6.5)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(12, (i) {
                          final heights = [4.0, 9.0, 14.0, 7.0, 12.0, 16.0, 5.0];
                          final h = heights[i % heights.length];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.0),
                            width: 2.0,
                            height: h,
                            decoration: BoxDecoration(
                              color: const Color(0xFFA855F7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. Vibrant Pink "Collage" Card
  Widget _buildBigCollageButton() {
    return GestureDetector(
      onTap: () => _pickCollageImages(),
      child: Container(
        height: 104,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF2A85),
              Color(0xFFFF5E97),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2A85).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Layout Split Icon on the Right
            Positioned(
              right: 0,
              top: 6,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(7),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Title at bottom left
            const Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Multi-Photo Art',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Vibrant Purple "Edit Photo" Card
  Widget _buildBigEditButton() {
    return GestureDetector(
      onTap: () => _pickImageAndEdit(),
      child: Container(
        height: 104,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF5E5BF7),
              Color(0xFF8655F6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5E5BF7).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Magic Wand with Sparkles Icon on the Right
            Positioned(
              right: 0,
              top: 4,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: -math.pi / 4,
                    child: const Icon(
                      Icons.auto_fix_high_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            // Title at bottom left
            const Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Filters & Darkroom',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4a. Left Rectangle Box: Background Studio
  Widget _buildBackgroundBox() {
    return GestureDetector(
      onTap: _openBackgroundStudio,
      child: Container(
        height: 98,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0D2821),
              Color(0xFF134E48),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Icon at top right
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.wallpaper_rounded,
                  color: Color(0xFF2DD4BF),
                  size: 19,
                ),
              ),
            ),

            // Content at bottom left
            Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Background',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Color(0xFF2DD4BF),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Explore Categories',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4b. Right Rectangle Box: Apply Effects Studio
  Widget _buildApplyEffectsBox() {
    return GestureDetector(
      onTap: _openEffectsStudio,
      child: Container(
        height: 98,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF281335),
              Color(0xFF581C87),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFA855F7).withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA855F7).withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Icon at top right
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFC084FC),
                  size: 19,
                ),
              ),
            ),

            // Content at bottom left
            Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Apply Effects',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          '15 FX',
                          style: TextStyle(
                            color: Color(0xFFE9D5FF),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'HDR, Film, Sci-Fi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// 5. Private Photo Vault Showcase Banner (Original Purple/Pink Theme)
  Widget _buildPrivateVaultBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _openPrivateVault,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF141926),
                Color(0xFF1F1836),
                Color(0xFF28183B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF2A85).withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF2A85).withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF2A85), Color(0xFF9D4EDD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2A85).withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Private Photo Vault',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SECRET',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00F0FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'PIN Protected • 100% On-Device Photo Security',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2A85).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF2A85).withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open',
                      style: TextStyle(
                        color: Color(0xFFFF2A85),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF2A85), size: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
