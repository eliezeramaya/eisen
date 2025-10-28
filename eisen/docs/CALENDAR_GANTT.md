# Calendar/Gantt

This document explains the architecture of the Calendar/Gantt view, UI tokens, keyboard/mouse shortcuts, and known limits. It also links to a short demo GIF for contributors.

## Architecture

- Painter: `GanttPainter`
  - Renders background, Now line, and bars with gradients and badges.
  - Viewport culling based on horizontal scroll and viewport width.
  - LRU caches for geometry and text to keep frame cost low.
- Header: `GanttHeader`
  - Renders the timeline scale (days/weeks/months) and labels.
  - Can hide weekend labels when Workweek Only is enabled.
- Interaction: `GanttInteractionLayer`
  - Hover tooltip, cursor changes, Ctrl+wheel and pinch zoom.
  - Drag to move; resize from left/right handles.
  - Snaps to scale boundaries (day or week) and enforces min 1-day duration.
  - Accessibility overlay: Semantics per bar and keyboard navigation.
- State & prefs
  - Timeline projector: `TimelineProjector` via `projectorProvider` (Notifier with clamped px/day).
  - UI preferences: `uiPrefsProvider` persists `gantt*` options (scale, badges, compact lanes, workweek, today line).

## Tokens (from `UiTokens`)

- Lane metrics: `laneHeight`, `laneGap`, `barRadius`, `barStroke`.
- Colors: `bgDark`, `now` (Now line), plus palettes via `GanttPalette` for span kinds.
- Zoom clamps: `pxPerDayMin` / `pxPerDayMax`.

## Shortcuts & interactions

- Zoom: Ctrl + Mouse Wheel (desktop) or pinch (touchpad/touch).
- Hover: Tooltip with title and date range.
- Drag/Resize: Move spans or resize from edges. Snaps to day/week. Min duration is 1 day.
- Keyboard:
  - Arrow keys: Navigate between bars (left/right ordering; up/down to nearest in adjacent lane).
  - Enter: Select focused bar.
  - Esc: Clear selection.

## Accessibility

- Each bar exposes Semantics with label (title), value (date range and duration), and hint (keyboard help).
- Bars are marked as buttons and respond to screen reader "tap".
- Focus ring appears when focused or selected.

## Limits & Notes

- Month-scale snapping is not enforced for interactions (day/week supported).
- Goldens are recorded in dark mode to ensure consistent visuals.
- For very large datasets (> 500 spans), consider increasing cache sizes or adding further culling.

## Demo GIF

- File: `docs/images/gantt_flow.gif` (add or replace via a short capture of zoom, hover, drag/resize, and keyboard navigation).

## Development

- Demo data: `lib/features/calendar_gantt/demo/gantt_demo_data.dart` provides an 8-span dataset.
- To validate locally:
  1. Open Workflow plan page and switch to Calendar/Gantt.
  2. Use Settings → Calendar/Gantt to toggle badges, compact lanes, workweek-only, and today line.
  3. Try keyboard navigation (arrows/Enter/Esc).
  4. Zoom with Ctrl+Wheel or pinch.

