import 'package:flutter/material.dart';

@immutable
class MinimalTokens extends ThemeExtension<MinimalTokens> {
  final bool enabled;
  final double borderAlpha; // 0..1
  final double shadowAlpha; // 0..1
  final double cornerRadius; // dp
  final double focusRingWidth; // dp
  final double motionMs; // ms

  const MinimalTokens({
    this.enabled = false,
    this.borderAlpha = .10,
    this.shadowAlpha = .06,
    this.cornerRadius = 12,
    this.focusRingWidth = 2,
    this.motionMs = 140,
  });

  @override
  MinimalTokens copyWith({
    bool? enabled,
    double? borderAlpha,
    double? shadowAlpha,
    double? cornerRadius,
    double? focusRingWidth,
    double? motionMs,
  }) => MinimalTokens(
        enabled: enabled ?? this.enabled,
        borderAlpha: borderAlpha ?? this.borderAlpha,
        shadowAlpha: shadowAlpha ?? this.shadowAlpha,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        focusRingWidth: focusRingWidth ?? this.focusRingWidth,
        motionMs: motionMs ?? this.motionMs,
      );

  @override
  ThemeExtension<MinimalTokens> lerp(ThemeExtension<MinimalTokens>? other, double t) {
    if (other is! MinimalTokens) return this;
    return MinimalTokens(
      enabled: t < .5 ? enabled : other.enabled,
      borderAlpha: borderAlpha + (other.borderAlpha - borderAlpha) * t,
      shadowAlpha: shadowAlpha + (other.shadowAlpha - shadowAlpha) * t,
      cornerRadius: cornerRadius + (other.cornerRadius - cornerRadius) * t,
      focusRingWidth: focusRingWidth + (other.focusRingWidth - focusRingWidth) * t,
      motionMs: motionMs + (other.motionMs - motionMs) * t,
    );
  }
}

