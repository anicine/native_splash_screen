import '../models/desktop.dart';

class Flavor {
  final String name;
  late final DesktopSplashConfig? linux;
  late final DesktopSplashConfig? windows;
  Flavor({required this.name, this.linux, this.windows});

  /// Check if there is a platform for this flavor
  bool get empty => linux == null && windows == null;
  bool get weak => linux == null || windows == null;
}
