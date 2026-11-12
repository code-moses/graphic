import 'package:flutter/painting.dart';
import 'package:graphic/src/common/dim.dart';
import 'package:graphic/src/graffiti/element/label.dart';

import 'axis.dart';

/// Where an axis is drawn, for measuring the space of its labels.
class AxisLayout {
  const AxisLayout(this.canvasDim, this.position, this.flip);

  final Dim canvasDim;
  final double position;
  final bool flip;
}

/// A label rectangle relative to its anchor, and the tick's normalized position.
class AxisLabelBlock {
  const AxisLabelBlock(this.rect, this.tickPosition);

  final Rect rect;
  final double tickPosition;
}

/// The padding of a rectangle region when none is specified.
///
/// It is the space the labels of [axes] need outside the region, at least
/// [minimum].
EdgeInsets measureAxisPadding(
  Size size,
  List<AxisLayout> axes,
  List<List<TickInfo>> ticks, {
  EdgeInsets minimum = const EdgeInsets.fromLTRB(4, 6, 8, 4),
}) {
  var left = minimum.left;
  var top = minimum.top;
  var right = minimum.right;
  var bottom = minimum.bottom;
  const gap = 2.0;

  for (var i = 0; i < axes.length; i++) {
    final axis = axes[i];
    final horizontal = axis.canvasDim == Dim.x;
    // The approximate length of the axis, to tell how far end labels stick out.
    final length = horizontal ? size.width - 50 : size.height - 25;
    for (final block in axisLabelBlocks(axis, ticks[i])) {
      final rect = block.rect;
      if (horizontal) {
        if (axis.position <= 0) bottom = _max(bottom, rect.bottom + gap);
        if (axis.position >= 1) top = _max(top, -rect.top + gap);
        left = _max(left, -rect.left - block.tickPosition * length);
        right = _max(right, rect.right - (1 - block.tickPosition) * length);
      } else {
        if (axis.position <= 0) left = _max(left, -rect.left + gap);
        if (axis.position >= 1) right = _max(right, rect.right + gap);
        // Vertical positions grow upwards.
        top = _max(top, -rect.top - (1 - block.tickPosition) * length);
        bottom = _max(bottom, rect.bottom - block.tickPosition * length);
      }
    }
  }

  // Never more than half of the chart for labels.
  return EdgeInsets.fromLTRB(
    left.clamp(0, size.width / 2),
    top.clamp(0, size.height / 2),
    right.clamp(0, size.width / 2),
    bottom.clamp(0, size.height / 2),
  );
}

double _max(double a, double b) => a > b ? a : b;

/// The label rectangles of [ticks] relative to their anchor on the axis.
Iterable<AxisLabelBlock> axisLabelBlocks(
    AxisLayout axis, List<TickInfo> ticks) sync* {
  final horizontal = axis.canvasDim == Dim.x;
  final align = horizontal
      ? (axis.flip ? Alignment.topCenter : Alignment.bottomCenter)
      : (axis.flip ? Alignment.centerRight : Alignment.centerLeft);
  for (final tick in ticks) {
    if (!tick.haveLabel) continue;
    final label = LabelElement(
      text: tick.text!,
      anchor: Offset.zero,
      defaultAlign: align,
      style: tick.label!,
    );
    yield AxisLabelBlock(label.getBlock(), tick.position);
  }
}

/// Indices of [labels] to draw so that neighbours keep [spacing] apart.
///
/// [labels] are in axis order. Every n-th label is kept, with the smallest n
/// that leaves no overlap.
Set<int> thinLabels(List<Rect> labels, bool horizontal, {double spacing = 4}) {
  bool fits(int step) {
    for (var i = 0; i + step < labels.length; i += step) {
      final a = labels[i];
      final b = labels[i + step];
      final apart = horizontal
          ? (a.right + spacing <= b.left || b.right + spacing <= a.left)
          : (a.bottom + spacing <= b.top || b.bottom + spacing <= a.top);
      if (!apart) return false;
    }
    return true;
  }

  var step = 1;
  while (step < labels.length && !fits(step)) {
    step++;
  }
  return {for (var i = 0; i < labels.length; i += step) i};
}
