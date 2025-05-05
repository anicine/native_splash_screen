class Platforms {
  final Platform? linux;
  final Platform? windows;

  Platforms({this.linux, this.windows});

  bool get hasLinux =>
      linux != null && linux!.enabled != null ? linux!.enabled! : false;
  bool get hasWindows =>
      windows != null && windows!.enabled != null ? windows!.enabled! : false;

  bool get hasAnyPlatform => hasLinux || hasWindows; //.. etc.

  bool canFallback() {
    bool f = false;
    if (!f && hasLinux) {
      f = linux!.canFall;
    }
    if (!f && hasWindows) {
      f = windows!.canFall;
    }

    return f;
  }

  /// Helper to get a list of enabled platforms for logging
  String all() {
    final enabledPlatforms = <String>[];
    if (hasLinux) enabledPlatforms.add('Linux');
    if (hasWindows) enabledPlatforms.add('Windows');

    return enabledPlatforms.join(", ");
  }
}

class Platform {
  final bool? enabled;
  final String path;
  final bool? fallback;

  Platform({this.enabled = false, required this.path, this.fallback = false});

  bool get canFall {
    return fallback ?? false;
  }
}
