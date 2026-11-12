import 'package:flutter/painting.dart';
import 'package:graphic/src/coord/rect.dart';
import 'package:graphic/src/graffiti/element/element.dart';
import 'package:graphic/src/graffiti/element/label.dart';
import 'package:graphic/src/graffiti/element/line.dart';
import 'package:graphic/src/graffiti/element/rect.dart';

import 'axis.dart';
import 'axis_padding.dart';

/// Renders horizontal axis.
List<MarkElement>? renderHorizontalAxis(
  List<TickInfo> ticks,
  double position,
  bool flip,
  PaintStyle? line,
  RectCoordConv coord,
) {
  final rst = <MarkElement>[];

  final region = coord.region;
  final flipSign = flip ? -1.0 : 1.0;
  final y = region.bottom - region.height * position;

  if (line != null) {
    rst.add(LineElement(
        start: Offset(region.left, y),
        end: Offset(region.right, y),
        style: line,
        tag: 'line'));
  }

  final labels = <LabelElement>[];
  final labelBackgrounds = <RectElement?>[];
  for (var tick in ticks) {
    final coordLeft = coord.horizontals.first;
    final coordRight = coord.horizontals.last;
    final x = coordLeft + tick.position * (coordRight - coordLeft);
    if (x >= region.left && x <= region.right) {
      if (tick.tickLine != null) {
        rst.add(LineElement(
            start: Offset(x, y),
            end: Offset(x, y + tick.tickLine!.length * flipSign),
            style: tick.tickLine!.style,
            tag: 'tick:${tick.text}'));
      }
      if (tick.haveLabel) {
        final label = LabelElement(
            text: tick.text!,
            anchor: Offset(x, y),
            defaultAlign: flip ? Alignment.topCenter : Alignment.bottomCenter,
            style: tick.label!,
            tag: 'label:${tick.text}');

        labels.add(label);
        labelBackgrounds.add(tick.haveLabelBackground
            ? RectElement(
                rect: label.getBlock(),
                style: tick.labelBackground!,
                tag: 'background:${tick.text}')
            : null);
      }
    }
  }

  // Labels that would overlap are thinned out.
  final kept = thinLabels([for (var label in labels) label.getBlock()], true);
  for (var i = 0; i < labels.length; i++) {
    if (!kept.contains(i)) continue;
    final background = labelBackgrounds[i];
    if (background != null) rst.add(background);
    rst.add(labels[i]);
  }

  return rst.isEmpty ? null : rst;
}

/// Renders horizontal axis grid.
List<MarkElement>? renderHorizontalGrid(
  List<TickInfo> ticks,
  RectCoordConv coord,
) {
  final rst = <MarkElement>[];

  final region = coord.region;
  for (var tick in ticks) {
    if (tick.grid != null) {
      final coordLeft = coord.horizontals.first;
      final coordRight = coord.horizontals.last;
      final x = coordLeft + tick.position * (coordRight - coordLeft);
      if (x >= region.left && x <= region.right) {
        rst.add(LineElement(
            start: Offset(x, region.bottom),
            end: Offset(x, region.top),
            style: tick.grid!,
            tag: 'grid:${tick.text}'));
      }
    }
  }

  return rst.isEmpty ? null : rst;
}
