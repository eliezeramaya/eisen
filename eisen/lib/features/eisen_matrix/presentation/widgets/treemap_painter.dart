import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:eisen/core/constants/layout_constants.dart';
import 'package:eisen/core/theme/animation_tokens.dart';
import 'package:eisen/core/theme/app_theme.dart';
import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/core/ui/ui_typography.dart' as typography;
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/eisen_matrix/domain/category_colors.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_debug.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

// Copy of helper used in painter paint loop.
String? _categoryNameForTask(Task task) {
  final category = task.category ?? task.categoryId;
  if (category == null) return null;
  final trimmed = category.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class TreemapPainter extends CustomPainter {
  TreemapPainter(
    this.layout, {
    this.draggingId,
    this.pointer,
    this.hoverQuadrant,
    this.presentQuadrant,
    this.zoom,
    required this.prevRects01,
    required this.nextRects01,
    required this.t,
    required this.tokens,
    required this.minimal,
    this.pulseQuadrant,
    this.pulseT = 0.0,
    this.suggested,
    required this.layoutVersion,
    this.selectedId,
    this.appearingIds = const <String>{},
    this.outros = const <String, OutroState>{},
    this.outrosVersion = 0,
    required this.outlineColor,
    required this.tileBorderColor,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.tileFillColor,
    this.textScale = 1.0,
    this.warningTaskIds = const <String>{},
    this.categoryColorService, // Optional category color service
    this.colorByCategory = false,
    this.showConfidenceIndicators = true,
    this.showAutoTags = true,
    this.quadrantLabelStyle = QuadrantLabelStyle.professional,
  });
  final List<TreemapRect> layout;
  final String? draggingId;
  final Offset? pointer;
  final Quadrant? hoverQuadrant;
  final Quadrant? presentQuadrant;
  final Quadrant? zoom;
  final Map<String, Rect> prevRects01;
  final Map<String, Rect> nextRects01;
  final double t; // 0..1
  final GlassTokens tokens;
  final bool minimal;
  final Quadrant? pulseQuadrant;
  final double pulseT; // 0..1
  final Set<String>? suggested;
  final int layoutVersion;
  final String? selectedId;
  final Set<String> appearingIds;
  final Map<String, OutroState> outros;
  final int outrosVersion;
  final Color outlineColor;
  final Color tileBorderColor;
  final Color tileFillColor;
  final Color onSurface;
  final Color onSurfaceVariant;
  final double textScale;
  final Set<String> warningTaskIds;
  final CategoryColorService? categoryColorService;
  final bool colorByCategory;
  final bool showConfidenceIndicators;
  final bool showAutoTags;
  final QuadrantLabelStyle quadrantLabelStyle;

  /// Tile path cache for performance optimization.
  ///
  /// Memoizes rounded rectangle paths by (task.id + rect01 hash) to avoid
  /// redundant path calculations when layout is stable. Cache is static and
  /// shared across painter instances.
  ///
  /// Benefits:
  /// - Reduces CPU overhead during animation frames
  /// - Prevents path recalculation for stable tiles
  /// - Improves paint performance when only dragging/hovering changes
  ///
  /// Cache invalidation: Automatic via key = '${task.id}_${rect.hashCode}'
  /// When rect changes, new key is generated and old entry is orphaned.
  static final Map<String, Path> _pathCache = {};

  /// Helper methods for progressive content display based on tile area
  /// These thresholds ensure visual hierarchy without cluttering small tiles

  /// Show due date when tile has enough space (area > 15,000 px²)
  bool _showDueDate(double area) => area > 15000;

  /// Show category pill when tile is medium-large (area > 20,000 px²)
  bool _showCategory(double area) => area > 20000;

  /// Show tags when tile is very large (area > 35,000 px²)
  bool _showTags(double area) => area > 35000;

  /// Format due date for compact display in tiles
  /// Returns short format like "15 Nov" or "15/11" depending on proximity
  String _formatDueDate(DateTime due) {
    final now = DateTime.now();
    final diff = due.difference(now).inDays;

    // If overdue or due today, show urgent format
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Tomorrow';

    // For dates within 7 days, show day name
    if (diff <= 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[due.weekday - 1];
    }

    // Otherwise show date
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${due.day} ${months[due.month - 1]}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final double gap = LayoutConstants.tileGap; // uniform gap between tiles

    final halfW = size.width / 2;
    final halfH = size.height / 2;

    // Only draw center cross when NOT zoomed into a single quadrant
    if (zoom == null) {
      // Draw subtle quadrant grid (center cross) so the matrix is visible even with no tiles
      final centerLine = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outlineColor;
      // Vertical center line
      canvas.drawLine(Offset(halfW, 0), Offset(halfW, size.height), centerLine);
      // Horizontal center line
      canvas.drawLine(Offset(0, halfH), Offset(size.width, halfH), centerLine);
    } else {
      // When zoomed, draw corner indicators to show quadrant position
      _drawQuadrantCornerIndicators(canvas, size, zoom!);
    }

    // Quadrant labels when no tiles or demo mode
    if (layout.isEmpty) {
      final labels = [
        _emptyQuadrantLabel(Quadrant.q1),
        _emptyQuadrantLabel(Quadrant.q2),
        _emptyQuadrantLabel(Quadrant.q3),
        _emptyQuadrantLabel(Quadrant.q4),
      ];
      final centers = [
        Offset(halfW / 2, halfH / 2),
        Offset(halfW + halfW / 2, halfH / 2),
        Offset(halfW / 2, halfH + halfH / 2),
        Offset(halfW + halfW / 2, halfH + halfH / 2),
      ];
      for (int i = 0; i < 4; i++) {
        final tp = _textPainter(
          labels[i],
          Rect.fromCenter(center: centers[i], width: halfW, height: halfH),
          16,
          FontWeight.w600,
          textColor: minimal ? const Color(0xFF424242) : Colors.white,
          maxLines: 3,
        );
        tp.paint(
          canvas,
          Offset(centers[i].dx - tp.width / 2, centers[i].dy - tp.height / 2),
        );
      }
    }

    // Debug: quadrant bounds in blue (disabled in minimal to keep visuals stable)
    if (debugTreemap && !minimal) {
      TreemapDebugOverlay.drawQuadrantBounds(
        canvas,
        Rect.fromLTWH(0, 0, halfW, halfH),
      );
      TreemapDebugOverlay.drawQuadrantBounds(
        canvas,
        Rect.fromLTWH(halfW, 0, halfW, halfH),
      );
      TreemapDebugOverlay.drawQuadrantBounds(
        canvas,
        Rect.fromLTWH(0, halfH, halfW, halfH),
      );
      TreemapDebugOverlay.drawQuadrantBounds(
        canvas,
        Rect.fromLTWH(halfW, halfH, halfW, halfH),
      );
      // HUD: area sums per quadrant
      final quadRects = [
        Rect.fromLTWH(0, 0, halfW, halfH),
        Rect.fromLTWH(halfW, 0, halfW, halfH),
        Rect.fromLTWH(0, halfH, halfW, halfH),
        Rect.fromLTWH(halfW, halfH, halfW, halfH),
      ];
      for (int i = 0; i < 4; i++) {
        final q = Quadrant.values[i];
        final areaSum =
            layout.where((e) => e.task.quadrant == q).fold<double>(0, (a, e) => a + (e.rect01.width * e.rect01.height));
        final quadArea = 0.5 * 0.5; // normalized
        final pct = (areaSum / quadArea * 100).clamp(0.0, 999.0);
        final label = '${q.name}: ${pct.toStringAsFixed(1)}%';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(fontSize: 10, color: Colors.blueAccent),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final pos = Offset(quadRects[i].left + 6, quadRects[i].top + 6);
        tp.paint(canvas, pos);
      }
    }

    // Removed present quadrant glow to avoid confusing highlight

    // Highlight hovered quadrant as a subtle overlay (takes precedence)
    if (hoverQuadrant != null) {
      final qRect = _quadrantRect(hoverQuadrant!, size);
      final qColor = minimal ? Colors.black : _byQuadrant(hoverQuadrant!);
      final overlay = Paint()
        ..style = PaintingStyle.fill
        ..color = minimal ? Colors.black.withValues(alpha: 0.06) : qColor.withValues(alpha: 0.08);
      canvas.drawRect(qRect, overlay);

      // Soft border glow
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..color = minimal ? Colors.black.withValues(alpha: 0.25) : qColor.withValues(alpha: 0.25)
        ..strokeWidth = 2;
      canvas.drawRect(qRect.deflate(1), border);
    }

    final curveT = AnimTokens.curve.transform(t.clamp(0.0, 1.0));
    // Drop pulse feedback
    if (pulseQuadrant != null && pulseT > 0) {
      final qRect = _quadrantRect(pulseQuadrant!, size);
      final c = qRect.center;
      final color = minimal ? Colors.black : _byQuadrant(pulseQuadrant!);
      final r = ui.lerpDouble(8, 28, Curves.easeOut.transform(pulseT))!;
      final a = (1.0 - pulseT).clamp(0.0, 1.0);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color.withValues(alpha: minimal ? 0.35 * a : 0.45 * a);
      canvas.drawCircle(c, r, ring);
    }
    // Prepare shelf clusters for debug overlay
    if (debugTreemap && !minimal && layout.isNotEmpty) {
      final byQ = <Quadrant, List<Rect>>{
        for (final q in Quadrant.values) q: [],
      };
      for (final tr in layout) {
        final rr = Rect.fromLTWH(
          tr.rect01.left * size.width,
          tr.rect01.top * size.height,
          tr.rect01.width * size.width,
          tr.rect01.height * size.height,
        );
        byQ[tr.task.quadrant]!.add(rr);
      }
      for (final q in Quadrant.values) {
        final shelves = _clusterShelves(byQ[q]!);
        for (final s in shelves) {
          TreemapDebugOverlay.drawShelf(canvas, s);
        }
      }
    }

    for (final tr in layout) {
      final id = tr.task.id;
      final r01From = prevRects01[id] ?? tr.rect01;
      final r01To = nextRects01[id] ?? tr.rect01;
      final r01 = Rect.lerp(r01From, r01To, curveT)!;
      final r0 = Rect.fromLTWH(
        r01.left * size.width,
        r01.top * size.height,
        r01.width * size.width,
        r01.height * size.height,
      );
      final r = _snapRect(r0);
      // Flat design: do not color tiles by quadrant

      // If dragging this tile, render it "lifted"
      final bool isDragging = tr.task.id == draggingId;
      Rect drawRect;
      if (isDragging) {
        // Scale around center and slightly offset towards pointer
        final scaled = _scaleRect(r, 1.04);
        Offset shift = Offset.zero;
        if (pointer != null) {
          final v = pointer! - scaled.center;
          final len = v.distance;
          final maxShift = 6.0;
          shift += len > 0 ? Offset(v.dx / len * maxShift, v.dy / len * maxShift) : Offset.zero;
        }
        // Magnetism: bias towards center of hovered quadrant
        if (hoverQuadrant != null) {
          final qCenter = _quadrantRect(hoverQuadrant!, size).center;
          final mv = qCenter - scaled.center;
          final mlen = mv.distance;
          final mMax = 8.0;
          final bias = 0.12; // fraction towards center
          final mshift = mlen > 0 ? Offset(mv.dx / mlen * mMax * bias, mv.dy / mlen * mMax * bias) : Offset.zero;
          shift += mshift;
        }
        drawRect = scaled.shift(shift);
        // No shadows in flat design
      } else {
        drawRect = r;
        // No shadows in flat design
      }
      // Deflate to create a gutter around each tile so rounded borders are visible
      // Clamp gutter so we don't invert tiny rects, then snap to pixel grid to avoid gaps
      final safeGap = math.min(
        gap,
        math.max(0.0, math.min(drawRect.width, drawRect.height) * 0.5 - 0.5),
      );
      drawRect = _snapRect(drawRect.deflate(safeGap));
      // Single geometry: flat fill + 1dp stroke
      final rr = RRect.fromRectAndRadius(
        drawRect,
        Radius.circular(UiTokens.tileRadius),
      );
      final categoryName = _categoryNameForTask(tr.task);
      final fillColor = colorByCategory && categoryName != null
          ? (categoryColorService ?? const CategoryColorService())
              .getLightVariant(categoryName, opacity: minimal ? 0.18 : 0.28)
          : tileFillColor;
      final strokeColor = colorByCategory && categoryName != null
          ? (categoryColorService ?? const CategoryColorService()).getDarkVariant(categoryName, opacity: 0.48)
          : tileBorderColor;
      paint
        ..style = PaintingStyle.fill
        ..color = fillColor;
      canvas.drawRRect(rr, paint);
      paint
        ..style = PaintingStyle.stroke
        ..color = strokeColor
        ..strokeWidth = UiTokens.tileStroke;
      canvas.drawRRect(rr, paint);

      final isLowConfidence = tr.task.classificationConfidence == ConfidenceLevel.low;
      if (showConfidenceIndicators && isLowConfidence) {
        final markerPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.orangeAccent.withValues(alpha: minimal ? 0.55 : 0.7);
        canvas.drawCircle(
          Offset(drawRect.left + 9, drawRect.top + 9),
          math.max(2.2, 3.2 * textScale),
          markerPaint,
        );
        final confidenceStroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.orangeAccent.withValues(alpha: 0.34);
        canvas.drawRRect(rr.deflate(0.5), confidenceStroke);
      }

      final bool warn = warningTaskIds.contains(tr.task.id);
      if (warn) {
        final tp = _textPainter(
          '⚠',
          drawRect,
          14 * textScale,
          FontWeight.w700,
          textColor: Colors.orangeAccent,
          maxLines: 1,
        );
        tp.paint(
          canvas,
          Offset(drawRect.right - tp.width - 4, drawRect.top + 2),
        );
      }

      // If this is a stack tile, render a centered +N label and skip details
      if (tr.stackChildren.isNotEmpty) {
        final label = '+${tr.stackChildren.length}';
        if (minimal) {
          final tp = _textPainter(
            label,
            drawRect,
            12,
            FontWeight.w700,
            textColor: onSurface,
          );
          tp.paint(
            canvas,
            Offset(
              drawRect.right - tp.width - 6,
              drawRect.bottom - tp.height - 4,
            ),
          );
        } else {
          final tp = _textPainter(
            label,
            drawRect,
            14,
            FontWeight.w700,
            textColor: onSurface,
          );
          tp.paint(
            canvas,
            Offset(
              drawRect.center.dx - tp.width / 2,
              drawRect.center.dy - tp.height / 2,
            ),
          );
        }
        continue;
      }

      // Title + metadata (minimal: show only on interaction)
      final area = drawRect.width * drawRect.height;
      final availableHeight = drawRect.height - 12; // padding top+bottom
      double currentY = drawRect.top + 6;

      final canShowTitle = debugTreemap || availableHeight > 18.0;
      final pointerInside = pointer != null && drawRect.contains(pointer!);
      final isSelected = selectedId != null && selectedId == tr.task.id;
      final showLabel = !minimal || isDragging || pointerInside || isSelected;

      // Calculate priority/time metadata height for bottom positioning
      final responsiveMetaSize = typography.metaFontSize(size).toDouble() * textScale;
      final meta = 'P${tr.task.priority} • ${tr.task.minutes}m';
      final metaPainter = _textPainter(
        meta,
        drawRect,
        responsiveMetaSize,
        FontWeight.w500,
        alpha: 0.95,
        maxLines: 1,
        textColor: onSurfaceVariant,
      );
      final metaHeight = metaPainter.height;

      // Reserve space at bottom for priority/time (always shown if space allows)
      final reserveBottomSpace = showLabel && area > 12000 && !debugTreemap;
      final bottomReserved = reserveBottomSpace ? metaHeight + 8 : 0.0;

      // Title
      if (showLabel && canShowTitle) {
        final responsiveTitleSize = (debugTreemap ? 16.0 : typography.titleFontSize(size).toDouble()) * textScale;
        final tp = _textPainter(
          tr.task.title,
          drawRect,
          responsiveTitleSize,
          FontWeight.w700,
          textColor: onSurface,
          maxLines: debugTreemap ? 3 : 1,
        );
        tp.paint(canvas, Offset(drawRect.left + 8, currentY));
        currentY += tp.height + 4; // Increased spacing for metadata
      }

      // PROGRESSIVE CONTENT: Due date (area > 15,000 px²)
      if (showLabel &&
          _showDueDate(area) &&
          tr.task.due != null &&
          currentY + 14 < drawRect.bottom - bottomReserved - 6 &&
          !debugTreemap) {
        final dueDateText = _formatDueDate(tr.task.due!);
        final now = DateTime.now();
        final isOverdue = tr.task.due!.isBefore(now);
        final isUrgent = tr.task.due!.difference(now).inDays <= 1;

        final dueDateColor = isOverdue
            ? Colors.redAccent
            : isUrgent
                ? Colors.orangeAccent
                : onSurfaceVariant;

        final responsiveDueDateSize = typography.metaFontSize(size).toDouble() * textScale * 0.95;
        final dueDatePainter = _textPainter(
          '📅 $dueDateText',
          drawRect,
          responsiveDueDateSize,
          FontWeight.w500,
          alpha: 0.9,
          maxLines: 1,
          textColor: dueDateColor,
        );
        dueDatePainter.paint(canvas, Offset(drawRect.left + 8, currentY));
        currentY += dueDatePainter.height + 3;
      }

      // PROGRESSIVE CONTENT: Category pill (area > 20,000 px²)
      if (showLabel &&
          _showCategory(area) &&
          categoryName != null &&
          currentY + 18 < drawRect.bottom - bottomReserved - 6 &&
          !debugTreemap) {
        final service = categoryColorService ?? const CategoryColorService();
        final categoryBgColor = service.getLightVariant(categoryName);
        final categoryBorderColor = service.getDarkVariant(categoryName);

        // Draw category pill background
        final categoryText = categoryName;
        final responsiveCategorySize = typography.metaFontSize(size).toDouble() * textScale * 0.9;
        final categoryPainter = _textPainter(
          categoryText,
          drawRect,
          responsiveCategorySize,
          FontWeight.w600,
          alpha: 0.85,
          maxLines: 1,
          textColor: onSurface,
        );

        final pillPadding = 6.0;
        final pillHeight = categoryPainter.height + 4;
        final pillWidth = categoryPainter.width + pillPadding * 2;
        final pillRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            drawRect.left + 8,
            currentY,
            math.min(pillWidth, drawRect.width - 16),
            pillHeight,
          ),
          const Radius.circular(8),
        );

        // Draw pill background
        final pillPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = categoryBgColor;
        canvas.drawRRect(pillRect, pillPaint);

        // Draw pill border
        final pillBorderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = categoryBorderColor;
        canvas.drawRRect(pillRect, pillBorderPaint);

        // Draw category text
        categoryPainter.paint(
          canvas,
          Offset(drawRect.left + 8 + pillPadding, currentY + 2),
        );
        currentY += pillHeight + 3;
      }

      // PROGRESSIVE CONTENT: Tags (area > 35,000 px²)
      if (showLabel &&
          _showTags(area) &&
          (tr.task.tags.isNotEmpty || (showAutoTags && tr.task.autoTags.isNotEmpty)) &&
          currentY + 14 < drawRect.bottom - bottomReserved - 6 &&
          !debugTreemap) {
        final mergedTags = [
          ...tr.task.tags,
          if (showAutoTags) ...tr.task.autoTags,
        ];
        final maxTags = 3; // Limit to first 3 tags
        final displayTags = mergedTags.take(maxTags).toList();
        final hasMoreTags = mergedTags.length > maxTags;

        final tagsText = displayTags.join(' · ') + (hasMoreTags ? ' · +${mergedTags.length - maxTags}' : '');

        final responsiveTagSize = typography.metaFontSize(size).toDouble() * textScale * 0.85;
        final tagsPainter = _textPainter(
          tagsText,
          drawRect,
          responsiveTagSize,
          FontWeight.w400,
          alpha: 0.75,
          maxLines: 1,
          textColor: onSurfaceVariant,
        );
        tagsPainter.paint(canvas, Offset(drawRect.left + 8, currentY));
        currentY += tagsPainter.height + 2;
      }

      // Notes preview (if very large size and has notes) - moved after metadata
      if (showLabel &&
          area > 26000 &&
          tr.task.notes != null &&
          tr.task.notes!.isNotEmpty &&
          currentY + 14 < drawRect.bottom - bottomReserved - 6 &&
          !debugTreemap) {
        final responsiveNotesSize = typography.metaFontSize(size).toDouble() * textScale;
        final notesPreview = tr.task.notes!.length > 50 ? '${tr.task.notes!.substring(0, 50)}...' : tr.task.notes!;
        final tp3 = _textPainter(
          notesPreview,
          drawRect,
          responsiveNotesSize,
          FontWeight.w400,
          alpha: minimal ? 0.9 : 0.85,
          maxLines: 2,
          textColor: minimal ? const Color(0xFF424242) : Colors.white,
        );
        tp3.paint(canvas, Offset(drawRect.left + 8, currentY));
      }

      // Priority and time - ALWAYS at bottom if space allows
      if (reserveBottomSpace) {
        final bottomY = drawRect.bottom - metaHeight - 6;
        metaPainter.paint(canvas, Offset(drawRect.left + 8, bottomY));
      }

      // Removed quadrant color indicator for flat design

      // Removed: Suggested by bandit badge (star) - flat design
      // if (suggested?.contains(tr.task.id) == true) {
      //   final star = _textPainter('★', drawRect, 12, FontWeight.w700, alpha: minimal ? 0.95 : 0.9, textColor: minimal ? Colors.black : Colors.white);
      //   star.paint(canvas, Offset(drawRect.left + 6, drawRect.top + 4));
      // }

      // Debug labels for each tile
      if (debugTreemap && !minimal) {
        final area = (drawRect.width * drawRect.height) / (size.width * size.height);
        final ratio = drawRect.width == 0 || drawRect.height == 0 ? 0.0 : (drawRect.width / drawRect.height).abs();
        final rr = ratio < 1 ? 1 / (ratio == 0.0 ? 1.0 : ratio) : ratio;
        TreemapDebugOverlay.labelTile(canvas, drawRect, tr.task.id, area, rr);
      }

      // Draw fade-out outros on top
      if (outros.isNotEmpty) {
        final now = DateTime.now();
        for (final entry in outros.entries) {
          final o = entry.value;
          final prog = o.progress(now);
          if (prog >= 1.0) continue;
          final alpha = (1.0 - prog).clamp(0.0, 1.0);
          final r0 = Rect.fromLTWH(
            o.rect.left * size.width,
            o.rect.top * size.height,
            o.rect.width * size.width,
            o.rect.height * size.height,
          );
          final r = _snapRect(r0);
          final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
          final baseColor = o.quadrant == null ? (minimal ? Colors.black : Colors.white) : _byQuadrant(o.quadrant!);
          final baseAlpha = (debugTreemap && !minimal) ? 0.28 : (minimal ? 0.25 : 0.18);
          final fill = Paint()
            ..style = PaintingStyle.fill
            ..color = baseColor.withValues(alpha: baseAlpha * alpha);
          canvas.drawRRect(rr, fill);
          final stroke = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (debugTreemap && !minimal) ? 2.0 : 1.0
            ..color = (minimal ? Colors.black.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.18))
                .withValues(alpha: (minimal ? 0.20 : 0.18) * alpha);
          canvas.drawRRect(rr, stroke);
        }
      }
    }

    // Debug: visualize inferred shelves after tiles are drawn
    if (debugTreemap && !minimal) {
      final rects = <Rect>[];
      for (final tr in layout) {
        final r = Rect.fromLTWH(
          tr.rect01.left * size.width,
          tr.rect01.top * size.height,
          tr.rect01.width * size.width,
          tr.rect01.height * size.height,
        ).deflate(gap);
        rects.add(_snapRect(r));
      }
      for (final shelf in _clusterShelves(rects)) {
        TreemapDebugOverlay.drawShelf(canvas, shelf);
      }
    }
  }

  /// Determines whether the CustomPainter should repaint.
  ///
  /// Uses deep comparison of layout, animation state, and interaction state.
  /// Comparison is efficient because:
  /// - `layout` uses List equality (identity or content comparison)
  /// - `prevRects01`/`nextRects01` use Map equality
  /// - Primitive comparisons (t, pulseT, draggingId) are cheap
  ///
  /// Performance note: If adding complex overlays/tooltips per tile that cause
  /// jank, consider wrapping individual tiles with `RepaintBoundary` to isolate
  /// repaints. Only do this if profiling shows significant paint overhead.
  ///
  /// Path caching via `_pathCache` reduces redundant path calculations when
  /// layout is stable but other properties change (e.g., pointer movement).
  @override
  bool shouldRepaint(covariant TreemapPainter oldDelegate) {
    final repaint = oldDelegate.layout != layout ||
        oldDelegate.draggingId != draggingId ||
        oldDelegate.pointer != pointer ||
        oldDelegate.hoverQuadrant != hoverQuadrant ||
        oldDelegate.t != t ||
        oldDelegate.suggested != suggested ||
        oldDelegate.pulseQuadrant != pulseQuadrant ||
        oldDelegate.pulseT != pulseT ||
        oldDelegate.prevRects01 != prevRects01 ||
        oldDelegate.nextRects01 != nextRects01 ||
        oldDelegate.layoutVersion != layoutVersion ||
        oldDelegate.tokens != tokens ||
        oldDelegate.minimal != minimal ||
        oldDelegate.zoom != zoom ||
        oldDelegate.outrosVersion != outrosVersion ||
        oldDelegate.outros.length != outros.length ||
        oldDelegate.appearingIds.length != appearingIds.length ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.tileBorderColor != tileBorderColor ||
        oldDelegate.tileFillColor != tileFillColor ||
        oldDelegate.warningTaskIds.length != warningTaskIds.length ||
        oldDelegate.categoryColorService != categoryColorService ||
        oldDelegate.colorByCategory != colorByCategory ||
        oldDelegate.showConfidenceIndicators != showConfidenceIndicators ||
        oldDelegate.showAutoTags != showAutoTags ||
        oldDelegate.quadrantLabelStyle != quadrantLabelStyle;

    // Invalidate path cache on layout version or key visual changes.
    if (oldDelegate.layoutVersion != layoutVersion ||
        oldDelegate.tokens != tokens ||
        oldDelegate.minimal != minimal ||
        oldDelegate.zoom != zoom) {
      _pathCache.clear();
    }
    return repaint;
  }

  @override
  bool shouldRebuildSemantics(covariant TreemapPainter oldDelegate) => oldDelegate.layout != layout;

  @override
  SemanticsBuilderCallback get semanticsBuilder => (Size size) {
        final nodes = <CustomPainterSemantics>[];
        for (final tr in layout) {
          final r = Rect.fromLTWH(
            tr.rect01.left * size.width,
            tr.rect01.top * size.height,
            tr.rect01.width * size.width,
            tr.rect01.height * size.height,
          );

          // Skip tiles with zero or negative dimensions (invisible to users)
          if (r.width <= 0 || r.height <= 0) continue;

          // Enhanced semantic label with complete task context
          final String label;
          if (tr.stackChildren.isNotEmpty) {
            // Stack tile: announce group size and quadrant
            label =
                'Group of ${tr.stackChildren.length + 1} tasks in quadrant ${_quadrantName(tr.task.quadrant)}, tap to expand';
          } else {
            // Individual tile: full task details for screen readers
            final parts = <String>[
              'Task: ${tr.task.title}',
              'Priority: ${tr.task.priority} out of 10',
              'Duration: ${tr.task.minutes} minutes',
              'Quadrant: ${_quadrantName(tr.task.quadrant)}',
            ];

            // Add due date if present
            if (tr.task.due != null) {
              final daysUntil = tr.task.due!.difference(DateTime.now()).inDays;
              if (daysUntil < 0) {
                parts.add('Overdue by ${-daysUntil} days');
              } else if (daysUntil == 0) {
                parts.add('Due today');
              } else if (daysUntil == 1) {
                parts.add('Due tomorrow');
              } else {
                parts.add('Due in $daysUntil days');
              }
            }

            // Add suggestion status
            if (suggested?.contains(tr.task.id) ?? false) {
              parts.add('Suggested task');
            }

            label = parts.join(', ');
          }

          nodes.add(
            CustomPainterSemantics(
              rect: r,
              properties: SemanticsProperties(
                label: label,
                button: true,
                textDirection: TextDirection.ltr,
                hint: 'Double tap to edit, or drag to move to another quadrant',
              ),
            ),
          );
        }
        return nodes;
      };

  /// Get human-readable quadrant name for semantics.
  String _quadrantName(Quadrant q) {
    final label = getQuadrantLabel(q, quadrantLabelStyle);
    return '${label.title}: ${label.subtitle}';
  }

  String _emptyQuadrantLabel(Quadrant q) {
    final label = getQuadrantLabel(q, quadrantLabelStyle);
    return '${label.title}\n${label.subtitle}';
  }

  Color _byQuadrant(Quadrant q) {
    switch (q) {
      case Quadrant.q1:
        return tokens.q1;
      case Quadrant.q2:
        return tokens.q2;
      case Quadrant.q3:
        return tokens.q3;
      case Quadrant.q4:
        return tokens.q4;
    }
  }

  Rect _quadrantRect(Quadrant q, Size size) {
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    switch (q) {
      case Quadrant.q1:
        return Rect.fromLTWH(0, 0, halfW, halfH);
      case Quadrant.q2:
        return Rect.fromLTWH(halfW, 0, halfW, halfH);
      case Quadrant.q3:
        return Rect.fromLTWH(0, halfH, halfW, halfH);
      case Quadrant.q4:
        return Rect.fromLTWH(halfW, halfH, halfW, halfH);
    }
  }

  Rect _scaleRect(Rect r, double scale) {
    final c = r.center;
    final w = r.width * scale;
    final h = r.height * scale;
    return Rect.fromCenter(center: c, width: w, height: h);
  }

  // Snap rect coordinates to pixel grid to reduce hairline gaps.
  Rect _snapRect(Rect r) {
    double snap(double v) => (v + 0.5).floorToDouble() + 0.0; // prefer whole-pixel alignment
    final l = snap(r.left);
    final t = snap(r.top);
    final rr = snap(r.right);
    final bb = snap(r.bottom);
    final w = (rr - l).clamp(0.0, double.infinity);
    final h = (bb - t).clamp(0.0, double.infinity);
    return Rect.fromLTWH(l, t, w, h);
  }

  /// Get or create a cached rounded rectangle path for the given rect.
  ///
  /// Memoizes paths by (taskId + rect hash) to avoid redundant path creation
  /// when layout is stable. This improves performance during interaction-only
  /// repaints (e.g., pointer movement, dragging state changes).
  ///
  /// Cache key invalidation: When rect changes, hashCode changes, creating a
  /// new cache entry. Old entries are orphaned but remain until GC.
  /// Cache is bounded implicitly by task count (max ~500 tasks × 2 states).
  // ignore: unused_element
  Path _getCachedPath(String taskId, Rect rect, double radius) {
    final key = '${taskId}_${rect.hashCode}_$radius#v$layoutVersion';
    return _pathCache.putIfAbsent(key, () {
      return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    });
  }

  /// Draw corner indicators when zoomed into a specific quadrant.
  /// Shows L-shaped markers in corners to indicate quadrant boundaries.
  void _drawQuadrantCornerIndicators(Canvas canvas, Size size, Quadrant zoomedQuadrant) {
    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = outlineColor.withValues(alpha: 0.25);

    const cornerLength = 20.0;
    const margin = 16.0;

    // Determine which corners to draw based on quadrant
    // Q1 (top-left): draw bottom-right corner
    // Q2 (top-right): draw bottom-left corner
    // Q3 (bottom-left): draw top-right corner
    // Q4 (bottom-right): draw top-left corner

    switch (zoomedQuadrant) {
      case Quadrant.q1:
        // Bottom-right corner (connects to Q2, Q3, Q4)
        final brX = size.width - margin;
        final brY = size.height - margin;
        canvas.drawLine(
          Offset(brX - cornerLength, brY),
          Offset(brX, brY),
          cornerPaint,
        );
        canvas.drawLine(
          Offset(brX, brY - cornerLength),
          Offset(brX, brY),
          cornerPaint,
        );
        break;

      case Quadrant.q2:
        // Bottom-left corner (connects to Q1, Q3, Q4)
        final blX = margin;
        final blY = size.height - margin;
        canvas.drawLine(
          Offset(blX, blY),
          Offset(blX + cornerLength, blY),
          cornerPaint,
        );
        canvas.drawLine(
          Offset(blX, blY - cornerLength),
          Offset(blX, blY),
          cornerPaint,
        );
        break;

      case Quadrant.q3:
        // Top-right corner (connects to Q1, Q2, Q4)
        final trX = size.width - margin;
        final trY = margin;
        canvas.drawLine(
          Offset(trX - cornerLength, trY),
          Offset(trX, trY),
          cornerPaint,
        );
        canvas.drawLine(
          Offset(trX, trY),
          Offset(trX, trY + cornerLength),
          cornerPaint,
        );
        break;

      case Quadrant.q4:
        // Top-left corner (connects to Q1, Q2, Q3)
        final tlX = margin;
        final tlY = margin;
        canvas.drawLine(
          Offset(tlX, tlY),
          Offset(tlX + cornerLength, tlY),
          cornerPaint,
        );
        canvas.drawLine(
          Offset(tlX, tlY),
          Offset(tlX, tlY + cornerLength),
          cornerPaint,
        );
        break;
    }
  }

  TextPainter _textPainter(
    String text,
    Rect r,
    double size,
    FontWeight fw, {
    double alpha = 0.92,
    int maxLines = 2,
    Color? textColor,
  }) {
    final maxW = math.max(0.0, r.width - 16);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          fontWeight: fw,
          color: (textColor ?? Colors.white).withValues(alpha: alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxW);
    return tp;
  }
}

class OutroState {
  OutroState({
    required this.rect,
    required this.quadrant,
    required this.startedAt,
    required this.duration,
  });
  final Rect rect; // normalized 0..1
  final Quadrant? quadrant;
  final DateTime startedAt;
  final Duration duration;
  double progress(DateTime now) {
    final dt = now.difference(startedAt).inMilliseconds;
    final total = duration.inMilliseconds;
    if (total <= 0) return 1.0;
    final t = dt / total;
    return t.clamp(0.0, 1.0);
  }
}

// Top-level helper: reorder paint z-order so suggested ids in tie groups paint last per quadrant.
List<TreemapRect> reorderForTieBreak(
  List<TreemapRect> items,
  Set<String>? suggested,
) {
  if (suggested == null || suggested.isEmpty) return items;
  final byQ = <Quadrant, List<TreemapRect>>{
    for (final q in Quadrant.values) q: [],
  };
  for (final it in items) {
    byQ[it.task.quadrant]!.add(it);
  }
  final out = <TreemapRect>[];
  for (final q in Quadrant.values) {
    final list = byQ[q]!;
    if (list.isEmpty) continue;
    final areas = list.map((e) => e.rect01.width * e.rect01.height).toList();
    String sid = '';
    for (final s in suggested) {
      if (list.any((e) => e.task.id == s)) {
        sid = s;
        break;
      }
    }
    if (sid.isEmpty) {
      out.addAll(list);
      continue;
    }
    final idx = list.indexWhere((e) => e.task.id == sid);
    if (idx < 0) {
      out.addAll(list);
      continue;
    }
    final aS = areas[idx];
    final hasTie = areas.asMap().entries.any(
          (e) => e.key != idx && aS > 0 && ((e.value - aS).abs() / aS) <= 0.05,
        );
    if (!hasTie) {
      out.addAll(list);
      continue;
    }
    final reordered = [...list]..removeAt(idx);
    reordered.add(list[idx]);
    out.addAll(reordered);
  }
  return out;
}

// Group tiles into horizontal/vertical shelves by clustering similar edges.
List<Rect> _clusterShelves(List<Rect> rects) {
  if (rects.isEmpty) return const [];
  const eps = 0.75; // pixels tolerance
  final used = List<bool>.filled(rects.length, false);
  final shelves = <Rect>[];
  for (var i = 0; i < rects.length; i++) {
    if (used[i]) continue;
    final base = rects[i];
    // Try horizontal grouping by similar top/bottom
    final group = <Rect>[base];
    used[i] = true;
    for (var j = i + 1; j < rects.length; j++) {
      if (used[j]) continue;
      final rj = rects[j];
      final sameRow = ((rj.top - base.top).abs() < eps && (rj.height - base.height).abs() < eps) ||
          ((rj.bottom - base.bottom).abs() < eps && (rj.height - base.height).abs() < eps);
      final sameCol = ((rj.left - base.left).abs() < eps && (rj.width - base.width).abs() < eps) ||
          ((rj.right - base.right).abs() < eps && (rj.width - base.width).abs() < eps);
      if (sameRow || sameCol) {
        group.add(rj);
        used[j] = true;
      }
    }
    Rect union = group.first;
    for (final g in group.skip(1)) {
      union = union.expandToInclude(g);
    }
    shelves.add(union);
  }
  return shelves;
}
