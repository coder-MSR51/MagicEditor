// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final inputPath = r'C:\Users\manis\.gemini\antigravity-ide\brain\d7acda16-6ac9-4534-a037-9583861eb56c\app_icon_fullbleed_1792701650207.jpg';
  final inputFile = File(inputPath);

  if (!inputFile.existsSync()) {
    print('Error: Input file not found at $inputPath');
    exit(1);
  }

  print('Reading image from: $inputPath');
  final rawBytes = inputFile.readAsBytesSync();
  final original = img.decodeImage(rawBytes);

  if (original == null) {
    print('Error: Failed to decode input image');
    exit(1);
  }

  print('Original image dimensions: ${original.width} x ${original.height}');

  // 1. Root 512x512 icons
  _saveResized(original, 512, 512, 'app_icon_512x512.png');
  _saveResized(original, 512, 512, 'app_icon_magiceditor.png');

  // 2. Android Standard / Legacy Icons (ic_launcher.png & ic_launcher_round.png)
  final androidDensities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in androidDensities.entries) {
    final folder = entry.key;
    final size = entry.value;
    final dir = Directory('android/app/src/main/res/$folder');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    _saveResized(original, size, size, '${dir.path}/ic_launcher.png');
    _saveResized(original, size, size, '${dir.path}/ic_launcher_round.png');
  }

  // 3. Android Adaptive Icon Foregrounds (ic_launcher_foreground.png)
  final adaptiveForegroundSizes = {
    'mipmap-mdpi': 108,
    'mipmap-hdpi': 162,
    'mipmap-xhdpi': 216,
    'mipmap-xxhdpi': 324,
    'mipmap-xxxhdpi': 432,
  };

  for (final entry in adaptiveForegroundSizes.entries) {
    final folder = entry.key;
    final size = entry.value;
    final dir = Directory('android/app/src/main/res/$folder');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    _saveResized(original, size, size, '${dir.path}/ic_launcher_foreground.png');
  }

  // 4. iOS Icons
  final iosDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (iosDir.existsSync()) {
    final iosSizes = {
      'Icon-App-1024x1024@1x.png': 1024,
      'Icon-App-20x20@1x.png': 20,
      'Icon-App-20x20@2x.png': 40,
      'Icon-App-20x20@3x.png': 60,
      'Icon-App-29x29@1x.png': 29,
      'Icon-App-29x29@2x.png': 58,
      'Icon-App-29x29@3x.png': 87,
      'Icon-App-40x40@1x.png': 40,
      'Icon-App-40x40@2x.png': 80,
      'Icon-App-40x40@3x.png': 120,
      'Icon-App-60x60@2x.png': 120,
      'Icon-App-60x60@3x.png': 180,
      'Icon-App-76x76@1x.png': 76,
      'Icon-App-76x76@2x.png': 152,
      'Icon-App-83.5x83.5@2x.png': 167,
    };

    for (final entry in iosSizes.entries) {
      _saveResized(original, entry.value, entry.value, '${iosDir.path}/${entry.key}');
    }
  }

  print('All app icons generated successfully!');
}

void _saveResized(img.Image src, int width, int height, String targetPath) {
  final resized = img.copyResize(
    src,
    width: width,
    height: height,
    interpolation: img.Interpolation.cubic,
  );
  final pngBytes = img.encodePng(resized, level: 6);
  File(targetPath).writeAsBytesSync(pngBytes);
  print('Saved: $targetPath ($width x $height, ${pngBytes.length} bytes)');
}
