import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';
import 'package:graphic/src/coord/polar.dart';
import 'package:graphic/src/graffiti/element/label.dart';
import 'package:graphic/src/graffiti/element/polyline.dart';

void main() {
  // A pie in a 200 x 200 region, radius 100
  final coord = PolarCoordConv(const Rect.fromLTWH(0, 0, 200, 200), 1, 1, true,
      [0, 1], [0, 1], 100, -pi / 2, 3 * pi / 2, 0, 100);

  List<Attributes> sectors(List<double> shares, RectShape shape) {
    var start = 0.0;
    return [
      for (var i = 0; i < shares.length; i++)
        Attributes(
          index: i,
          position: [Offset(0, start), Offset(0, start += shares[i])],
          shape: shape,
          color: const Color(0xff000000),
          label: Label(
              's$i', LabelStyle(textStyle: const TextStyle(fontSize: 10))),
        ),
    ];
  }

  test('puts labels outside with leader lines, apart from each other', () {
    final shape = RectShape(outsideLabels: true);
    final elements = shape.drawGroupLabels(
        sectors([0.02, 0.02, 0.02, 0.94], shape), coord, Offset.zero);

    final labels = elements.whereType<LabelElement>().toList();
    final lines = elements.whereType<PolylineElement>().toList();
    expect(labels, hasLength(4));
    expect(lines, hasLength(4));
    for (final label in labels) {
      expect((label.anchor - const Offset(100, 100)).distance, greaterThan(100),
          reason: 'outside the pie');
    }
    // The three narrow sectors are next to each other on the right
    final right = [
      for (final l in labels)
        if (l.anchor.dx > 100) l.anchor.dy
    ]..sort();
    for (var i = 1; i < right.length; i++) {
      expect(right[i] - right[i - 1], greaterThanOrEqualTo(14 - 1e-9));
    }
  });

  test('leaves out the labels of narrow sectors', () {
    final shape = RectShape(minLabelAngle: 0.2);
    final elements = shape.drawGroupLabels(
        sectors([0.01, 0.49, 0.5], shape), coord, Offset.zero);

    expect(elements.whereType<LabelElement>().map((l) => l.text), ['s1', 's2']);
  });
}
