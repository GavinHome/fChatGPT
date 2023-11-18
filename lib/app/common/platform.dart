import 'package:flutter/foundation.dart';

/// [isWeb]
bool isWeb() {
  return kIsWeb;
}

/// [isDesktop]
bool isDesktop() {
  return defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows;
}

/// [isMobile]
bool isMobile() {
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
}