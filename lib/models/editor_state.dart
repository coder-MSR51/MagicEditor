import '../utils/filter_presets.dart';
import 'background_model.dart';
import 'draw_model.dart';
import 'editor_template_model.dart';
import 'prop_layer_model.dart';
import 'text_layer_model.dart';

class EditorState {
  final FilterPreset filter;
  final double filterIntensity;
  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double tint;
  final double vignette;
  final double grain;
  final int rotationAngle;
  final bool flipHorizontal;
  final bool flipVertical;
  final double? cropAspectRatio;
  final List<DrawPathModel> drawPaths;
  final List<TextLayerModel> textLayers;
  final List<PropLayerModel> propLayers;
  final BackgroundType backgroundType;
  final double backgroundBlur;
  final int backgroundGradientIndex;
  final double framePadding;
  final double frameRadius;
  final String polaroidCaption;
  final EditorTemplate activeTemplate;
  final String songTitle;
  final String artistName;

  const EditorState({
    required this.filter,
    this.filterIntensity = 1.0,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.warmth = 0.0,
    this.tint = 0.0,
    this.vignette = 0.0,
    this.grain = 0.0,
    this.rotationAngle = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.cropAspectRatio,
    this.drawPaths = const [],
    this.textLayers = const [],
    this.propLayers = const [],
    this.backgroundType = BackgroundType.none,
    this.backgroundBlur = 15.0,
    this.backgroundGradientIndex = 0,
    this.framePadding = 20.0,
    this.frameRadius = 16.0,
    this.polaroidCaption = 'PHOTO MAGIC',
    this.activeTemplate = EditorTemplate.none,
    this.songTitle = 'Golden Hour',
    this.artistName = 'JVKE • Memories Edit',
  });

  static EditorState initial() {
    return EditorState(
      filter: FilterPresets.all.first,
      activeTemplate: EditorTemplate.none,
      songTitle: 'Golden Hour',
      artistName: 'JVKE • Memories Edit',
    );
  }

  EditorState copyWith({
    FilterPreset? filter,
    double? filterIntensity,
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? tint,
    double? vignette,
    double? grain,
    int? rotationAngle,
    bool? flipHorizontal,
    bool? flipVertical,
    double? cropAspectRatio,
    bool clearCropAspectRatio = false,
    List<DrawPathModel>? drawPaths,
    List<TextLayerModel>? textLayers,
    List<PropLayerModel>? propLayers,
    BackgroundType? backgroundType,
    double? backgroundBlur,
    int? backgroundGradientIndex,
    double? framePadding,
    double? frameRadius,
    String? polaroidCaption,
    EditorTemplate? activeTemplate,
    String? songTitle,
    String? artistName,
  }) {
    return EditorState(
      filter: filter ?? this.filter,
      filterIntensity: filterIntensity ?? this.filterIntensity,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      warmth: warmth ?? this.warmth,
      tint: tint ?? this.tint,
      vignette: vignette ?? this.vignette,
      grain: grain ?? this.grain,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      cropAspectRatio: clearCropAspectRatio ? null : (cropAspectRatio ?? this.cropAspectRatio),
      drawPaths: drawPaths ?? this.drawPaths,
      textLayers: textLayers ?? this.textLayers,
      propLayers: propLayers ?? this.propLayers,
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundBlur: backgroundBlur ?? this.backgroundBlur,
      backgroundGradientIndex: backgroundGradientIndex ?? this.backgroundGradientIndex,
      framePadding: framePadding ?? this.framePadding,
      frameRadius: frameRadius ?? this.frameRadius,
      polaroidCaption: polaroidCaption ?? this.polaroidCaption,
      activeTemplate: activeTemplate ?? this.activeTemplate,
      songTitle: songTitle ?? this.songTitle,
      artistName: artistName ?? this.artistName,
    );
  }

  bool get hasChanges {
    return filter.id != 'original' ||
        brightness != 0.0 ||
        contrast != 1.0 ||
        saturation != 1.0 ||
        warmth != 0.0 ||
        tint != 0.0 ||
        vignette != 0.0 ||
        grain != 0.0 ||
        rotationAngle != 0 ||
        flipHorizontal ||
        flipVertical ||
        cropAspectRatio != null ||
        drawPaths.isNotEmpty ||
        textLayers.isNotEmpty ||
        propLayers.isNotEmpty ||
        backgroundType != BackgroundType.none ||
        activeTemplate != EditorTemplate.none ||
        songTitle != 'Golden Hour' ||
        artistName != 'JVKE • Memories Edit';
  }
}

