import 'package:eisen/core/theme/animation_tokens.dart';
import 'package:flutter/material.dart';

/// Streak bar — visualizes daysActive (0..7) with calm capsules.
class StreakBar extends StatelessWidget {
  // 0..7
  const StreakBar({super.key, required this.daysActive});
  final int daysActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final active = i < daysActive;
        return AnimatedContainer(
          duration: AnimTokens.layout,
          curve: AnimTokens.curve,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 18,
          height: 8,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFF4996E) : const Color(0x339CA3AF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: active
                ? [const BoxShadow(color: Color(0x22F4996E), blurRadius: 8)]
                : null,
          ),
        );
      }),
    );
  }
}
