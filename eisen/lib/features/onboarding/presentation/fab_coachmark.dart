import 'package:flutter/material.dart';

class FabCoachmark extends StatelessWidget {
  const FabCoachmark({super.key, required this.child, required this.show});
  final Widget child;
  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    return Stack(children: [
      child,
      Positioned.fill(
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                right: 24,
                bottom: MediaQuery.paddingOf(context).bottom + 72,
              ),
              child: const _PulseDot(),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_c.value);
        final s = 1.0 + .25 * t;
        final o = (1.0 - t).clamp(.35, .85);
        return Transform.scale(
          scale: s,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: o),
            ),
          ),
        );
      },
    );
  }
}
