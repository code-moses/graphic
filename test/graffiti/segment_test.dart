import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';
import 'package:graphic/src/graffiti/element/segment/segment.dart';

/// A closed area outline over [values]: along the top, back along the bottom.
List<Segment> _area(List<double> values) => [
      MoveSegment(end: const Offset(0, 100)),
      for (var i = 0; i < values.length; i++)
        LineSegment(end: Offset(i * 10.0, 100 - values[i])),
      LineSegment(end: Offset((values.length - 1) * 10.0, 100)),
      CloseSegment(),
    ];

Path _draw(List<Segment> segments) {
  final path = Path();
  for (final s in segments) {
    s.drawPath(path);
  }
  return path;
}

void main() {
  group('nomalizeSegments', () {
    test('morphs closed outlines with different numbers of points', () {
      for (final pair in [
        [
          _area([10, 20, 30]),
          _area([5, 15, 25, 35, 45])
        ],
        [
          _area([5, 15, 25, 35, 45]),
          _area([10, 20, 30])
        ],
      ]) {
        final normalized = nomalizeSegments(pair.first, pair.last);

        expect(normalized.first.length, normalized.last.length);
        expect(normalized.last.last, isA<CloseSegment>(),
            reason: 'the outline stays closed');
        expect(() => lerpSegments(normalized.first, normalized.last, .5),
            returnsNormally);
      }
    });

    test('ends on the target outline', () {
      final to = _area([5, 15, 25, 35, 45]);
      final normalized = nomalizeSegments(_area([10, 20]), to);

      expect(
          _draw(lerpSegments(normalized.first, normalized.last, 1)).getBounds(),
          _draw(to).getBounds());
    });
  });
}
