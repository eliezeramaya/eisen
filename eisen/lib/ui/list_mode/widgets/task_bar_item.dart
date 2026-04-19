import 'package:flutter/material.dart';

/// Single task bar with horizontal visual weight representation
class TaskBarItem extends StatefulWidget {
  const TaskBarItem({
    super.key,
    required this.title,
    required this.color,
    required this.weight,
    required this.maxWeight,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final Color color;
  final double weight;
  final double maxWeight;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  State<TaskBarItem> createState() => _TaskBarItemState();
}

class _TaskBarItemState extends State<TaskBarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final widthFactor = (widget.weight / widget.maxWeight).clamp(0.15, 1.0);
    final baseOpacity = 0.3 + (widthFactor * 0.5);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth * widthFactor;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: barWidth,
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    widget.color.withValues(
                      alpha: _isHovered ? baseOpacity + 0.1 : baseOpacity,
                    ),
                    widget.color.withValues(
                      alpha: _isHovered ? 0.25 : 0.15,
                    ),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: _isHovered
                              ? const Color(0xFFF5F5F5)
                              : const Color(0xFFE6E6E6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(
                          color: Color(0xFF7C7C7C),
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Icon(
                      Icons.circle,
                      size: 5,
                      color: widget.color.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
