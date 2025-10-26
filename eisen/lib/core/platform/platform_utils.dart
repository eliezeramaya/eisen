import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// True when running on desktop platforms (macOS, Windows, Linux).
bool get isDesktop => const {
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    }.contains(defaultTargetPlatform);

