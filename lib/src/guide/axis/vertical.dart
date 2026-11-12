import 'package:flutter/painting.dart';
import 'package:graphic/src/coord/rect.dart';
import 'package:graphic/src/graffiti/element/element.dart';
import 'package:graphic/src/graffiti/element/label.dart';
import 'package:graphic/src/graffiti/element/line.dart';
import 'package:graphic/src/graffiti/element/rect.dart';

import 'axis.dart';
import 'axis_padding.dart';

/// Renders vertical axis.
List<MarkElement>? renderVerticalAxis(
  List<TickInfo> ticks,
  double position,
  bool flip,
  PaintStyle? line,
  RectCoordConv coord,
) {
  final rst = <MarkElement>[];

  final region = coord.region;
  final flipSign = flip ? -1.0 : 1.0;
  final x = region.left + region.width * position;

  if (line != null) {
    rst.add(LineElement(
        start: Offset(x, region.bottom),
        end: Offset(x, region.top),
        style: line));
  }

  final labels = <LabelElement>[];
  final labelBackgrounds = <RectElement?>[];
  for (var tick in ticks) {
    final coordBottom = coord.verticals.first;
    final coordTop = coord.verticals.last;
    final y = coordBottom - tick.position * (coordBottom - coordTop);
    if (y >= region.top && y <= region.bottom) {
      if (tick.tickLine != null) {
        rst.add(LineElement(
            start: Offset(x, y),
            end: Offset(x - tick.tickLine!.length * flipSign, y),
            style: tick.tickLine!.style));
      }
      if (tick.haveLabel) {
        final label = LabelElement(
            text: tick.text!,
            anchor: Offset(x, y),
            defaultAlign: flip ? Alignment.centerRight : Alignment.centerLeft,
            style: tick.label!);

        labels.add(label);
        labelBackgrounds.add(tick.haveLabelBackground
            ? RectElement(rect: label.getBlock(), style: tick.labelBackground!)
            : null);
      }
    }
  }

  // Labels that would overlap are thinned out.
  final kept = thinLabels([for (var label in labels) label.getBlock()], false);
  for (var i = 0; i < labels.length; i++) {
    if (!kept.contains(i)) continue;
    final background = labelBackgrounds[i];
    if (background != null) rst.add(background);
    rst.add(labels[i]);
  }

  return rst.isEmpty ? null : rst;
}

/// Renders vertical axis grid.
List<MarkElement>? renderVerticalGrid(
  List<TickInfo> ticks,
  RectCoordConv coord,
) {
  final rst = <MarkElement>[];

  final region = coord.region;
  for (var tick in ticks) {
    if (tick.grid != null) {
      final coordBottom = coord.verticals.first;
      final coordTop = coord.verticals.last;
      final y = coordBottom - tick.position * (coordBottom - coordTop);
      if (y >= region.top && y <= region.bottom) {
        rst.add(LineElement(
            start: Offset(region.left, y),
            end: Offset(region.right, y),
            style: tick.grid!));
      }
    }
  }

  return rst.isEmpty ? null : rst;
}
