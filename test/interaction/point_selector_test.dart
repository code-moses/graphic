import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';
import 'package:graphic/src/interaction/selection/point.dart';

const _region = Rect.fromLTWH(0, 0, 200, 200);

Attributes _interval(int index, Offset start, Offset end) => Attributes(
      index: index,
      position: [start, end],
      shape: RectShape(),
      color: const Color(0xff000000),
    );

List<Tuple> _tuples(int count) => [
      for (var i = 0; i < count; i++) {'i': i}
    ];

int? _select(
  AttributesGroups groups,
  CoordConv coord,
  Offset abstractPoint, {
  Dim? dim,
  bool nearest = true,
}) {
  var count = 0;
  for (var group in groups) {
    count += group.length;
  }
  final selected = PointSelector(
    false,
    nearest,
    10,
    dim,
    null,
    [coord.convert(abstractPoint)],
  ).select(groups, _tuples(count), null, coord);
  return selected?.single;
}

void main() {
  group('pie', () {
    // Stacked sectors of 10%, 40%, 30% and 20%.
    final bounds = [0.0, 0.1, 0.5, 0.8, 1.0];
    final groups = [
      for (var i = 0; i < 4; i++) [_interval(i, Offset(0, bounds[i]), Offset(0, bounds[i + 1]))]
    ];

    PolarCoordConv pie({double start = -pi / 2, double end = 3 * pi / 2}) =>
        PolarCoordConv(_region, 1, 0.5, true, [0, 1], [0, 1], 100, start, end, 0, 100);

    int expected(double angle) => bounds.lastIndexWhere((b) => b <= angle);

    for (final dim in [null, Dim.x, Dim.y]) {
      test('selects the sector under the pointer, dim $dim', () {
        for (var angle = 0.005; angle < 1; angle += 0.01) {
          expect(
            _select(groups, pie(), Offset(0, angle), dim: dim),
            expected(angle),
            reason: 'angle $angle',
          );
        }
      });
    }

    test('selects in a donut', () {
      final coord = PolarCoordConv(_region, 1, 0.5, true, [0, 1], [0, 1], 100, -pi / 2, 3 * pi / 2, 50, 100);
      for (var angle = 0.005; angle < 1; angle += 0.01) {
        expect(_select(groups, coord, Offset(0, angle)), expected(angle));
      }
    });

    test('selects in an anticlockwise pie', () {
      final coord = pie(start: 3 * pi / 2, end: -pi / 2);
      for (var angle = 0.005; angle < 1; angle += 0.01) {
        expect(_select(groups, coord, Offset(0, angle)), expected(angle));
      }
    });

    test('selects the nearer end in the gap of a partial arc', () {
      final coord = pie(start: -2.5, end: 2.5);
      // Canvas points in the gap, just before the start and just after the end.
      final beforeStart = coord.polarToOffset(-2.6, 50);
      final afterEnd = coord.polarToOffset(2.6, 50);
      Set<int>? select(Offset canvas, bool nearest) => PointSelector(false, nearest, 1, null, null, [canvas]).select(groups, _tuples(4), null, coord);

      expect(select(beforeStart, true), {0});
      expect(select(afterEnd, true), {3});
      expect(select(coord.polarToOffset(pi, 50), false), isNull);
    });
  });

  group('rose', () {
    // Sectors with band centers on the angle and values on the radius.
    final groups = [
      [for (var i = 0; i < 4; i++) _interval(i, Offset(0.125 + i * 0.25, 0), Offset(0.125 + i * 0.25, 0.8))]
    ];
    final coord = PolarCoordConv(_region, 2, 0.5, false, [0, 1], [0, 1], 100, -pi / 2, 3 * pi / 2, 0, 100);

    test('selects by angle', () {
      for (var i = 0; i < 4; i++) {
        expect(
          _select(groups, coord, Offset(0.05 + i * 0.25, 0.4), dim: Dim.x),
          i,
        );
        expect(
          _select(groups, coord, Offset(0.2 + i * 0.25, 0.4), dim: Dim.x),
          i,
        );
      }
    });
  });

  group('stacked bars', () {
    // Two bars at x 0.25 and 0.75, each with segments 0-0.3 and 0.3-0.9.
    final groups = [
      [
        _interval(0, const Offset(0.25, 0), const Offset(0.25, 0.3)),
        _interval(1, const Offset(0.75, 0), const Offset(0.75, 0.3)),
      ],
      [
        _interval(2, const Offset(0.25, 0.3), const Offset(0.25, 0.9)),
        _interval(3, const Offset(0.75, 0.3), const Offset(0.75, 0.9)),
      ],
    ];
    final coord = RectCoordConv(_region, 2, 0.5, false, [0, 1], [0, 1]);

    test('dim x selects the segment under the pointer', () {
      expect(_select(groups, coord, const Offset(0.3, 0.1), dim: Dim.x), 0);
      expect(_select(groups, coord, const Offset(0.3, 0.4), dim: Dim.x), 2);
      expect(_select(groups, coord, const Offset(0.7, 0.2), dim: Dim.x), 1);
      expect(_select(groups, coord, const Offset(0.7, 0.85), dim: Dim.x), 3);
    });

    test('no dim selects the segment under the pointer', () {
      expect(_select(groups, coord, const Offset(0.25, 0.25)), 0);
      expect(_select(groups, coord, const Offset(0.25, 0.35)), 2);
      expect(_select(groups, coord, const Offset(0.75, 0.6)), 3);
    });

    test('dim x selects the top segment above the bar', () {
      expect(_select(groups, coord, const Offset(0.25, 0.95), dim: Dim.x), 2);
    });
  });

  group('points', () {
    final groups = [
      [
        for (var i = 0; i < 3; i++)
          Attributes(
            index: i,
            position: [Offset(0.2 + i * 0.3, 0.5)],
            shape: CircleShape(),
            color: const Color(0xff000000),
          )
      ]
    ];
    final coord = RectCoordConv(_region, 2, 0.5, false, [0, 1], [0, 1]);

    test('selects the nearest point', () {
      expect(_select(groups, coord, const Offset(0.3, 0.9), dim: Dim.x), 0);
      expect(_select(groups, coord, const Offset(0.4, 0.1), dim: Dim.x), 1);
      expect(_select(groups, coord, const Offset(0.7, 0.5)), 2);
    });

    test('rejects out of test radius if not nearest', () {
      expect(
        _select(groups, coord, const Offset(0.35, 0.5), dim: Dim.x, nearest: false),
        isNull,
      );
      expect(
        _select(groups, coord, const Offset(0.22, 0.9), dim: Dim.x, nearest: false),
        0,
      );
    });
  });
}
