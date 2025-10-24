import 'package:eisen/core/services/metrics.dart';
import 'package:flutter/foundation.dart';

/// Web performance measurement integration.
/// 
/// Provides hooks for web platform to report performance metrics like LCP
/// (Largest Contentful Paint) measured via Performance API in JavaScript.
/// 
/// Usage:
/// 1. Web platform measures LCP via PerformanceObserver (see web/index.html)
/// 2. JavaScript calls `window.flutterMetrics.recordLCP(ms)`
/// 3. This class receives and records the metric
/// 
/// Only active on web platform when ?measure_lcp=true URL parameter is set
/// or running on localhost for development monitoring.
class WebPerformance {
  WebPerformance._();
  static final instance = WebPerformance._();
  
  bool _initialized = false;
  
  /// Initialize web performance tracking.
  /// 
  /// Sets up JavaScript interop to receive LCP measurements from the web
  /// platform. Safe to call multiple times (idempotent).
  void init() {
    if (_initialized) return;
    _initialized = true;
    
    if (kIsWeb) {
      _setupWebInterop();
    }
  }
  
  void _setupWebInterop() {
    // On web, expose Flutter method to JavaScript via js interop
    // This requires dart:html or package:web, which we'll add conditionally
    if (kDebugMode || kProfileMode) {
      debugPrint('[WebPerformance] Initialized (web platform)');
      // Note: Actual JS interop would require dart:js or package:js
      // For now, this is a placeholder that documents the intent
      // Real implementation would use:
      // import 'dart:js' as js;
      // js.context['flutterMetrics'] = js.JsObject.jsify({
      //   'recordLCP': (double ms) => recordLCP(ms),
      // });
    }
  }
  
  /// Record LCP measurement from JavaScript.
  /// 
  /// Called by web/index.html script via JavaScript interop when LCP is measured.
  void recordLCP(double ms) {
    if (kDebugMode || kProfileMode) {
      debugPrint('[WebPerformance] LCP: ${ms.toFixed(2)} ms');
    }
    Metrics.instance.recordLCP(ms);
  }
}

extension _DoubleFormat on double {
  String toFixed(int decimals) => toStringAsFixed(decimals);
}
