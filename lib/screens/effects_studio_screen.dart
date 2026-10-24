import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../services/image_export_service.dart';
import '../services/admob_service.dart';
import '../theme/app_theme.dart';
import '../utils/filter_presets.dart';
import 'editor_screen.dart';

class EffectsStudioScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const EffectsStudioScreen({
    super.key,
    required this.imageBytes,
  });

  @override
  State<EffectsStudioScreen> createState() => _EffectsStudioScreenState();
}

class _EffectsStudioScreenState extends State<EffectsStudioScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  late FilterPreset _selectedEffect;
  double _intensity = 1.0;
  bool _isComparing = false;
  bool _isSaving = false;

  final List<FilterPreset> _undoStack = [];
  final List<FilterPreset> _redoStack = [];

  @override
  void initState() {
    super.initState();
    // Default to HDR effect (index 1) as requested
    _selectedEffect = FilterPresets.effects.length > 1
        ? FilterPresets.effects[1]
        : FilterPresets.effects[0];
  }

  void _selectEffect(FilterPreset effect) {
    if (_selectedEffect.id == effect.id) return;
    setState(() {
      _undoStack.add(_selectedEffect);
      _redoStack.clear();
      _selectedEffect = effect;
      _intensity = 1.0;
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _redoStack.add(_selectedEffect);
      _selectedEffect = _undoStack.removeLast();
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _undoStack.add(_selectedEffect);
      _selectedEffect = _redoStack.removeLast();
    });
  }

  Future<void> _exportEffectImage() async {
    try {
      setState(() => _isSaving = true);

      await Future.delayed(const Duration(milliseconds: 120));

      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Canvas not ready');

      final exportedBytes = await ImageExportService.captureWidgetToBytes(boundary, pixelRatio: 3.0);
      if (exportedBytes == null) throw Exception('Failed to render image');

      final savedSuccess = await ImageExportService.saveToGallery(exportedBytes);
      if (!mounted) return;

      if (savedSuccess) {
        AdMobService.instance.showInterstitialAd();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Effect Photo saved to Gallery! ✨',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openInFullEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorScreen(
          imageBytes: widget.imageBytes,
        ),
      ),
    );
  }

  List<double> get _activeMatrix {
    if (_isComparing || _selectedEffect.id == 'original') {
      return FilterPresets.identityMatrix;
    }
    return FilterPresets.getBlendedMatrix(_selectedEffect.matrix, _intensity);
  }

  IconData _getEffectIcon(String id) {
    switch (id) {
      case 'hdr':
        return Icons.hdr_on_rounded;
      case 'cinematic':
        return Icons.movie_filter_rounded;
      case 'film':
        return Icons.camera_roll_rounded;
      case 'poloroid':
        return Icons.photo_camera_back_rounded;
      case 'super_character':
        return Icons.flash_on_rounded;
      case 'warm':
        return Icons.wb_sunny_rounded;
      case 'old1':
        return Icons.history_edu_rounded;
      case 'old2':
        return Icons.camera_alt_outlined;
      case 'future1':
        return Icons.auto_awesome_rounded;
      case 'future2':
        return Icons.hub_rounded;
      case 'galaxy':
        return Icons.blur_circular_rounded;
      case 'sky':
        return Icons.cloud_rounded;
      case 'nature':
        return Icons.eco_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'woody':
        return Icons.forest_rounded;
      default:
        return Icons.filter_vintage_rounded;
    }
  }

  Color _getEffectAccent(String id) {
    switch (id) {
      case 'hdr':
        return const Color(0xFF00E5FF);
      case 'cinematic':
        return const Color(0xFFFF9900);
      case 'film':
        return const Color(0xFFE5B942);
      case 'poloroid':
        return const Color(0xFFFBBF24);
      case 'super_character':
        return const Color(0xFFFF007F);
      case 'warm':
        return const Color(0xFFFFB300);
      case 'old1':
        return const Color(0xFFD4AF37);
      case 'old2':
        return const Color(0xFFA1887F);
      case 'future1':
        return const Color(0xFF00F0FF);
      case 'future2':
        return const Color(0xFF9D4EDD);
      case 'galaxy':
        return const Color(0xFF8B5CF6);
      case 'sky':
        return const Color(0xFF38BDF8);
      case 'nature':
        return const Color(0xFF22C55E);
      case 'water':
        return const Color(0xFF06B6D4);
      case 'woody':
        return const Color(0xFFB45309);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getEffectAccent(_selectedEffect.id);

    return Scaffold(
      backgroundColor: const Color(0xFF0C0E14),
      appBar: _buildTopBar(activeColor),
      body: SafeArea(
        child: Column(
          children: [
            // Center Image Canvas with Live Filter Matrix
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: RepaintBoundary(
                    key: _repaintBoundaryKey,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ColorFiltered(
                            colorFilter: ColorFilter.matrix(_activeMatrix),
                            child: Image.memory(
                              widget.imageBytes,
                              fit: BoxFit.contain,
                            ),
                          ),

                          // Live Comparing Badge
                          if (_isComparing)
                            Positioned(
                              top: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.primary, width: 1.2),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.visibility_rounded, color: AppTheme.primary, size: 14),
                                    SizedBox(width: 6),
                                    Text(
                                      'ORIGINAL (NO EFFECT)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Effects Control Panel
            _buildEffectsPanel(activeColor),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(Color activeColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          const Text(
            'Apply Effects',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            _selectedEffect.name,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: activeColor),
          ),
        ],
      ),
      actions: [
        // Undo
        IconButton(
          icon: Icon(Icons.undo_rounded, size: 20, color: _undoStack.isNotEmpty ? Colors.white : Colors.white24),
          onPressed: _undoStack.isNotEmpty ? _undo : null,
          tooltip: 'Undo',
        ),

        // Redo
        IconButton(
          icon: Icon(Icons.redo_rounded, size: 20, color: _redoStack.isNotEmpty ? Colors.white : Colors.white24),
          onPressed: _redoStack.isNotEmpty ? _redo : null,
          tooltip: 'Redo',
        ),

        // Compare Button
        GestureDetector(
          onTapDown: (_) => setState(() => _isComparing = true),
          onTapUp: (_) => setState(() => _isComparing = false),
          onTapCancel: () => setState(() => _isComparing = false),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isComparing ? activeColor : const Color(0xFF1B2234),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isComparing ? activeColor : Colors.white12,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.compare_rounded,
                  size: 15,
                  color: _isComparing ? Colors.black : Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'COMPARE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: _isComparing ? Colors.black : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Save Button
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: _isSaving
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download_rounded, color: AppTheme.primary, size: 24),
                  tooltip: 'Save Image',
                  onPressed: _exportEffectImage,
                ),
        ),
      ],
    );
  }

  Widget _buildEffectsPanel(Color activeColor) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111520),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF263248), width: 1.0)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Intensity Slider Bar
          if (_selectedEffect.id != 'original')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: activeColor),
                  const SizedBox(width: 10),
                  Text(
                    'Strength: ${(_intensity * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: activeColor,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _intensity,
                      min: 0.0,
                      max: 1.0,
                      activeColor: activeColor,
                      inactiveColor: Colors.white12,
                      onChanged: (val) => setState(() => _intensity = val),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 6),

          // 2. Horizontal Scroll of 15 Effects
          SizedBox(
            height: 106,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: FilterPresets.effects.length,
              itemBuilder: (context, index) {
                final effect = FilterPresets.effects[index];
                final isSelected = effect.id == _selectedEffect.id;
                final effectColor = _getEffectAccent(effect.id);

                return GestureDetector(
                  onTap: () => _selectEffect(effect),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 76,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? effectColor.withValues(alpha: 0.15)
                          : const Color(0xFF181F2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? effectColor : Colors.white12,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: effectColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Effect Circular Icon / Thumbnail
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                effectColor.withValues(alpha: 0.3),
                                effectColor.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _getEffectIcon(effect.id),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            effect.name,
                            style: TextStyle(
                              color: isSelected ? effectColor : Colors.white,
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // 3. Open in Full Studio Editor Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16, color: AppTheme.primary),
                    label: const Text(
                      'Open in Studio Editor (Add Text, Stickers, Crop)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _openInFullEditor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
