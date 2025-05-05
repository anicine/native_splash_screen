import 'package:image/image.dart' show Color;

class DesktopSplashConfig {
  final bool withAnimation;
  final int windowWidth;
  final int windowHeight;
  final String windowTitle;
  final String windowClass;
  final Color windowColor;
  final String imagePath;
  final int imageWidth;
  final int imageHeight;
  final double imageBorderRadius;
  final double imageBlurRadius;
  final bool imageScaling;
  final Color backgroundColor;
  final int backgroundWidth;
  final int backgroundHeight;
  final double backgroundBorderRadius;
  DesktopSplashConfig({
    required this.windowWidth,
    required this.windowHeight,
    required this.windowTitle,
    required this.windowClass,
    required this.windowColor,
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageBorderRadius,
    required this.imageScaling,
    required this.backgroundColor,
    required this.backgroundWidth,
    required this.backgroundHeight,
    required this.backgroundBorderRadius,
    required this.withAnimation,
    required this.imageBlurRadius,
  });
}
