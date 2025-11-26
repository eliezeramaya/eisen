import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/features/focus/domain/focus_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FocusWindowCard extends ConsumerWidget {
  const FocusWindowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusDashboardControllerProvider);
    final cs = Theme.of(context).colorScheme;

    return EisenCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Pill(label: 'FOCUS WINDOW'),
          const SizedBox(height: EisenSpacing.lg),
          FocusWindowBar(
            segments: state.windowSegments,
            handlePosition: state.windowHandlePosition,
            onHandleChanged: (value) {
              ref
                  .read(focusDashboardControllerProvider.notifier)
                  .setHandlePosition(value);
            },
          ),
          const SizedBox(height: EisenSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: EisenSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _HourText('7 AM'),
                _HourText('12 PM'),
                _HourText('3 PM'),
                _HourText('11 PM'),
              ],
            ),
          ),
          const SizedBox(height: EisenSpacing.xl),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: Column(
              key: ValueKey(state.period),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ventana óptima de foco',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: EisenSpacing.sm),
                Text(
                  'Trabajar en esta franja suele darte tus mejores sesiones de foco profundo.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.72),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FocusWindowBar extends StatefulWidget {
  const FocusWindowBar({
    super.key,
    required this.segments,
    required this.handlePosition,
    this.onHandleChanged,
  });

  final List<FocusWindowSegment> segments;
  final double handlePosition;
  final ValueChanged<double>? onHandleChanged;

  @override
  State<FocusWindowBar> createState() => _FocusWindowBarState();
}

class _FocusWindowBarState extends State<FocusWindowBar> {
  late double _handle;

  @override
  void initState() {
    super.initState();
    _handle = widget.handlePosition;
  }

  @override
  void didUpdateWidget(covariant FocusWindowBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handlePosition != widget.handlePosition) {
      _handle = widget.handlePosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) {
            final local = details.localPosition.dx.clamp(0.0, width);
            final normalized = (local / width).clamp(0.0, 1.0);
            setState(() => _handle = normalized);
            widget.onHandleChanged?.call(normalized);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Stack(
                children: [
                  for (final segment in widget.segments)
                    Positioned(
                      left: segment.start * width,
                      right: (1 - segment.end) * width,
                      top: 0,
                      bottom: 0,
                      child: Container(color: segment.color),
                    ),
                  Align(
                    alignment: Alignment((_handle * 2) - 1, 0),
                    child: Container(
                      width: 6,
                      height: 22,
                      decoration: BoxDecoration(
                        color: cs.onSurface,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: cs.onSurface.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HourText extends StatelessWidget {
  const _HourText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant.withOpacity(0.8),
          ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EisenSpacing.lg,
        vertical: EisenSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.onSurface.withOpacity(0.04)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 1.5,
              color: cs.onSurface.withOpacity(0.8),
            ),
      ),
    );
  }
}
