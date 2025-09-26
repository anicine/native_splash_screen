import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

import '../models/image.dart';
import '../models/desktop.dart';

import '../common/utils.dart';

import '../src/logger.dart';
import '../src/image.dart';

/// Generates Macos platform-specific code for the native splash screen
///
/// Takes a [config] object containing splash screen configuration,
/// a [flavor] string to support multiple build flavors,
/// and an output [path] to override the default location.
///
/// Returns [true] if generation was successful, [false] otherwise.
Future<bool> generateMacosCode({
  required DesktopSplashConfig config,
  required String flavor,
  required Directory outputDir,
}) async {
  // Validate image file exists
  final imageFile = File(config.imagePath);
  if (!imageFile.existsSync()) {
    logger.e('Image file not found: ${config.imagePath}');
    return false;
  }

  // Load and process the image
  final BGRAImage? imageData = await _loadAndProcessImage(config);
  if (imageData == null) {
    return false;
  }

  // Copy the image to Resources directory and generate the Swift source file
  final imageFileName = await _copyImageToResources(config, imageData, flavor, outputDir.path);
  if (imageFileName == null) {
    return false;
  }

  // Generate the Swift source file
  return _generateSourceFile(
    outputDir: outputDir.path,
    flavor: flavor,
    config: config,
    imageData: imageData,
    imageFileName: imageFileName,
  );
}

/// Saves a BGRAImage as a PNG file
Future<void> _saveBGRAImageAsPNG(BGRAImage imageData, String outputPath) async {
  final img.Image image = img.Image(
    width: imageData.width,
    height: imageData.height,
    numChannels: 4,
  );

  // Convert BGRA data to Image format
  for (int y = 0; y < imageData.height; y++) {
    for (int x = 0; x < imageData.width; x++) {
      final pixelIndex = (y * imageData.width + x) * 4;
      final b = imageData.data[pixelIndex];
      final g = imageData.data[pixelIndex + 1];
      final r = imageData.data[pixelIndex + 2];
      final a = imageData.data[pixelIndex + 3];
      
      image.setPixel(x, y, img.ColorRgba8(r, g, b, a));
    }
  }

  // Encode and save as PNG
  final pngBytes = img.encodePng(image);
  await File(outputPath).writeAsBytes(pngBytes);
}

/// Copies the processed image to the Resources directory and Assets.xcassets
///
/// Returns the filename of the copied image or null if copying failed
Future<String?> _copyImageToResources(
  DesktopSplashConfig config,
  BGRAImage imageData,
  String flavor,
  String outputDir,
) async {
  try {
    // Generate image filename based on flavor
    final imageFileName = 'splash_screen_$flavor.png';
    
    // Copy to Resources directory (backup location)
    final resourcesDir = Directory(path.join(outputDir, 'Resources'));
    if (!resourcesDir.existsSync()) {
      resourcesDir.createSync(recursive: true);
    }
    final resourcesPath = path.join(resourcesDir.path, imageFileName);
    await _saveBGRAImageAsPNG(imageData, resourcesPath);
    logger.i('Copied splash screen image to Resources: $resourcesPath');
    
    // Also copy to Assets.xcassets (preferred location for macOS)
    await _copyImageToAssets(outputDir, imageData, imageFileName, config);
    
    return imageFileName;
  } catch (e) {
    logger.e('Failed to copy image to resources: $e');
    return null;
  }
}

/// Copies the image to Assets.xcassets for proper bundle inclusion with Retina support
Future<void> _copyImageToAssets(String outputDir, BGRAImage imageData, String imageFileName, DesktopSplashConfig config) async {
  try {
    // Find Assets.xcassets directory
    final assetsDir = Directory(path.join(outputDir, 'Assets.xcassets'));
    if (!assetsDir.existsSync()) {
      logger.w('Assets.xcassets not found at ${assetsDir.path}, skipping asset copy');
      return;
    }
    
    // Remove extension for imageset name
    final imageSetName = path.basenameWithoutExtension(imageFileName);
    final imageSetDir = Directory(path.join(assetsDir.path, '$imageSetName.imageset'));
    
    // Create imageset directory
    if (!imageSetDir.existsSync()) {
      imageSetDir.createSync(recursive: true);
    }
    
    // Generate images at different scales for Retina support
    final baseFileName = path.basenameWithoutExtension(imageFileName);
    final extension = path.extension(imageFileName);
    
    // Fetch configured logical display size in points
    final configuredWidth = config.imageWidth;
    final configuredHeight = config.imageHeight;

    // IMPORTANT: Generate PNGs directly from the original source image
    // to avoid any BGRA/stride ambiguity. Use the input file as the basis.
    final srcBytes = await File(config.imagePath).readAsBytes();
    final srcImage = img.decodeImage(srcBytes);
    if (srcImage == null) {
      logger.w('Failed to decode source image at ${config.imagePath}');
      return;
    }
    
    // Generate 1x image (logical display size in pixels for 1x)
    final fileName1x = '$baseFileName$extension';
    final assetImagePath1x = path.join(imageSetDir.path, fileName1x);
    final bool sameAs1x =
        srcImage.width == configuredWidth && srcImage.height == configuredHeight;
    if (sameAs1x) {
      await File(assetImagePath1x).writeAsBytes(srcBytes);
    } else {
      final bool downscale1x =
          srcImage.width >= configuredWidth && srcImage.height >= configuredHeight;
      final img.Interpolation interp1x =
          downscale1x ? img.Interpolation.average : img.Interpolation.cubic;
      final img1x = img.copyResize(
        srcImage,
        width: configuredWidth,
        height: configuredHeight,
        interpolation: interp1x,
      );
      await File(assetImagePath1x).writeAsBytes(img.encodePng(img1x));
    }
    
    // Generate 2x image (points * 2 → device pixels)
    final fileName2x = '$baseFileName@2x$extension';
    final assetImagePath2x = path.join(imageSetDir.path, fileName2x);
    final int target2xW = configuredWidth * 2;
    final int target2xH = configuredHeight * 2;
    final bool sameAs2x = srcImage.width == target2xW && srcImage.height == target2xH;
    if (sameAs2x) {
      await File(assetImagePath2x).writeAsBytes(srcBytes);
    } else {
      final bool downscale2x = srcImage.width >= target2xW && srcImage.height >= target2xH;
      final img.Interpolation interp2x =
          downscale2x ? img.Interpolation.average : img.Interpolation.cubic;
      final img2x = img.copyResize(
        srcImage,
        width: target2xW,
        height: target2xH,
        interpolation: interp2x,
      );
      await File(assetImagePath2x).writeAsBytes(img.encodePng(img2x));
    }
    
    // Create Contents.json for the imageset with multiple scales (macOS uses 1x and 2x)
    final contentsJson = '''
{
  "images" : [
    {
      "filename" : "$fileName1x",
      "idiom" : "mac",
      "scale" : "1x"
    },
    {
      "filename" : "$fileName2x",
      "idiom" : "mac",
      "scale" : "2x"
    }
  ],
  "info" : {
    "author" : "native_splash_screen_cli",
    "version" : 1
  }
}''';
    
    final contentsFile = File(path.join(imageSetDir.path, 'Contents.json'));
    await contentsFile.writeAsString(contentsJson);
    
      logger.i('Added Retina images to Assets.xcassets:');
      logger.i('  - 1x (${configuredWidth}x${configuredHeight}): $assetImagePath1x');
      logger.i('  - 2x (${configuredWidth * 2}x${configuredHeight * 2}): $assetImagePath2x');
  } catch (e) {
    logger.w('Failed to copy image to Assets.xcassets: $e');
  }
}

/// Scale the image to exact dimensions
BGRAImage _scaleImageToSize(BGRAImage imageData, int targetWidth, int targetHeight) {
  final sourceImage = img.Image(
    width: imageData.width,
    height: imageData.height,
    numChannels: 4,
  );
  
  // Copy BGRA data to the source image
  for (int y = 0; y < imageData.height; y++) {
    for (int x = 0; x < imageData.width; x++) {
      final pixelIndex = (y * imageData.width + x) * 4;
      final b = imageData.data[pixelIndex];
      final g = imageData.data[pixelIndex + 1];
      final r = imageData.data[pixelIndex + 2];
      final a = imageData.data[pixelIndex + 3];
      
      sourceImage.setPixel(x, y, img.ColorRgba8(r, g, b, a));
    }
  }
  
  // Scale the image using high-quality interpolation
  final scaledImage = img.copyResize(
    sourceImage,
    width: targetWidth,
    height: targetHeight,
    interpolation: img.Interpolation.cubic,
  );
  
  // Convert back to BGRAImage format
  final scaledData = <int>[];
  for (int y = 0; y < targetHeight; y++) {
    for (int x = 0; x < targetWidth; x++) {
      final pixel = scaledImage.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final a = pixel.a.toInt();
      
      // Store as BGRA
      scaledData.addAll([b, g, r, a]);
    }
  }
  
  return BGRAImage(
    data: Uint8List.fromList(scaledData),
    width: targetWidth,
    height: targetHeight,
    original: scaledImage,
  );
}

/// Scales a BGRAImage by the given factor using high-quality interpolation
BGRAImage _scaleImage(BGRAImage original, double scaleFactor) {
  final newWidth = (original.width * scaleFactor).round();
  final newHeight = (original.height * scaleFactor).round();
  
  // Convert BGRAImage to img.Image for scaling
  final sourceImage = img.Image(
    width: original.width,
    height: original.height,
    numChannels: 4,
  );
  
  // Copy pixel data from BGRAImage to img.Image
  for (int y = 0; y < original.height; y++) {
    for (int x = 0; x < original.width; x++) {
      final pixelIndex = (y * original.width + x) * 4;
      final b = original.data[pixelIndex];
      final g = original.data[pixelIndex + 1];
      final r = original.data[pixelIndex + 2];
      final a = original.data[pixelIndex + 3];
      
      sourceImage.setPixel(x, y, img.ColorRgba8(r, g, b, a));
    }
  }
  
  // Scale the image using high-quality interpolation
  // For downscaling (< 1.0), use average to reduce aliasing
  // For upscaling (> 1.0), use cubic
  final interpolation = scaleFactor < 1.0 
      ? img.Interpolation.average 
      : img.Interpolation.cubic;
      
  final scaledImage = img.copyResize(
    sourceImage,
    width: newWidth,
    height: newHeight,
    interpolation: interpolation,
  );
  
  // Convert back to BGRAImage format
  final scaledData = <int>[];
  for (int y = 0; y < newHeight; y++) {
    for (int x = 0; x < newWidth; x++) {
      final pixel = scaledImage.getPixel(x, y);
      scaledData.add(pixel.b.toInt()); // B
      scaledData.add(pixel.g.toInt()); // G
      scaledData.add(pixel.r.toInt()); // R
      scaledData.add(pixel.a.toInt()); // A
    }
  }
  
  return BGRAImage(
    width: newWidth,
    height: newHeight,
    data: Uint8List.fromList(scaledData),
    original: scaledImage,
  );
}

/// Loads and processes the splash screen image according to configuration
///
/// Returns the processed [BGRAImage] or null if processing failed
Future<BGRAImage?> _loadAndProcessImage(DesktopSplashConfig config) async {
  try {
    return await loadImageAsBGRA(
      config.imagePath,
      blurRadius: config.imageBlurRadius,
      resizeToFit: config.imageScaling,
      imageBorderRadius: config.imageBorderRadius,
      targetWidth: config.imageWidth,
      targetHeight: config.imageHeight,
      backgroundBorderRadius: config.backgroundBorderRadius,
      backgroundColor: config.backgroundColor,
      backgroundWidth: config.backgroundWidth,
      backgroundHeight: config.backgroundHeight,
    );
  } catch (e) {
    logger.e('Failed to load or process the image: $e');
    return null;
  }
}

/// Generates the Swift source file with image data and configuration
///
/// Returns [true] if file generation was successful, [false] otherwise
Future<bool> _generateSourceFile({
  required String outputDir,
  required String flavor,
  required DesktopSplashConfig config,
  required BGRAImage imageData,
  required String imageFileName,
}) async {
  final build = flavor.capitalizeFirstLetter();
  final target = 'NativeSplashScreen_$build.swift';

  // Create complete file path using the output directory
  final String outputFilePath = path.join(outputDir, target);

  final outputFile = File(outputFilePath);

  try {
    final buffer = StringBuffer();

    // File header
    buffer.writeln('// Generated file - do not edit');
    buffer.writeln('// Generated by native_splash_screen_cli');
    buffer.writeln('');
    buffer.writeln('import native_splash_screen_macos');
    buffer.writeln('');
    buffer.writeln('');

    // Splash screen configuration
    _writeConfigSection(buffer, config, imageData, build, imageFileName);

    // Write to file
    await outputFile.writeAsString(buffer.toString());
    // logger.success('Generated $target in $outputDir');
    return true;
  } catch (e) {
    logger.e('Failed to generate $target file: $e');
    return false;
  }
}

/// Writes the configuration section of the Swift file
void _writeConfigSection(
  StringBuffer buffer,
  DesktopSplashConfig config,
  BGRAImage imageData,
  String build,
  String imageFileName,
) {
  buffer.writeln(
    'class ${build}NativeSplashScreenConfiguration: NativeSplashScreenConfigurationProvider {',
  );
  buffer.writeln('');
  buffer.writeln('    // MARK: - Splash screen properties');
  buffer.writeln('    let windowWidth: Int = ${config.windowWidth}');
  buffer.writeln('    let windowHeight: Int = ${config.windowHeight}');
  buffer.writeln('');

  buffer.writeln('    // MARK: - Window Title');
  buffer.writeln(
    '    let windowTitle: String = "${escapeString(config.windowTitle)}"',
  );
  buffer.writeln('');

  buffer.writeln('    // MARK: - Animation control');
  buffer.writeln('    let withAnimation: Bool = ${config.withAnimation}');
  buffer.writeln('');

  buffer.writeln('    // MARK: - Image properties');
  buffer.writeln('    let imageFileName: String = "$imageFileName"');
  // Use logical display size from config (not the physical pixels of the source)
  buffer.writeln('    let imageWidth: Int = ${config.imageWidth}');
  buffer.writeln('    let imageHeight: Int = ${config.imageHeight}');
  buffer.writeln('}');
}