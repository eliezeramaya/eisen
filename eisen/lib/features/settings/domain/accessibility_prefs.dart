class AccessibilityPrefs {
  const AccessibilityPrefs({
    required this.largeText,
    required this.highContrast,
    required this.reduceAnimations,
    required this.hapticsEnabled,
  });

  final bool largeText;
  final bool highContrast;
  final bool reduceAnimations;
  final bool hapticsEnabled;

  AccessibilityPrefs copyWith({
    bool? largeText,
    bool? highContrast,
    bool? reduceAnimations,
    bool? hapticsEnabled,
  }) {
    return AccessibilityPrefs(
      largeText: largeText ?? this.largeText,
      highContrast: highContrast ?? this.highContrast,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  Map<String, Object?> toJson() => {
        'largeText': largeText,
        'highContrast': highContrast,
        'reduceAnimations': reduceAnimations,
        'hapticsEnabled': hapticsEnabled,
      };

  static AccessibilityPrefs fromJson(Map<String, Object?> json) {
    return AccessibilityPrefs(
      largeText: (json['largeText'] as bool?) ?? false,
      highContrast: (json['highContrast'] as bool?) ?? false,
      reduceAnimations: (json['reduceAnimations'] as bool?) ?? false,
      hapticsEnabled: (json['hapticsEnabled'] as bool?) ?? true,
    );
  }
}
