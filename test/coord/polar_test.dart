import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';

const _region = Rect.fromLTWH(0, 0, 200, 200);

PolarCoordConv _coord(
  double startAngle,
  double endAngle, {
  bool transposed = false,
  double startRadius = 0,
}) =>
    PolarCoordConv(_region, 2, 0.5, transposed, [0, 1], [0, 1], 100, startAngle, endAngle, startRadius, 100);

void main() {
  group('invert', () {
    final coords = {
      'full': _coord(-pi / 2, 3 * pi / 2),
      'transposed': _coord(-pi / 2, 3 * pi / 2, transposed: true),
      'donut': _coord(-pi / 2, 3 * pi / 2, startRadius: 40),
      'anticlockwise': _coord(3 * pi / 2, -pi / 2),
      'partial': _coord(-2.5, 2.5),
      'partial anticlockwise': _coord(2.5, -2.5),
    };

    coords.forEach((name, coord) {
      test('round trips, $name', () {
        for (var x = 0.05; x < 1; x += 0.1) {
          for (var y = 0.05; y < 1; y += 0.1) {
            final inverted = coord.invert(coord.convert(Offset(x, y)));
            expect(inverted.dx, closeTo(x, 1e-9));
            expect(inverted.dy, closeTo(y, 1e-9));
          }
        }
      });
    });

    test('maps the gap of a partial arc outside of [0, 1]', () {
      final coord = _coord(-2.5, 2.5);
      expect(coord.invert(coord.polarToOffset(-2.6, 50)).dx, lessThan(0));
      expect(coord.invert(coord.polarToOffset(2.6, 50)).dx, greaterThan(1));
    });
  });

  group('invertDistance', () {
    test('is the ratio to arc length and radius range', () {
      final coord = _coord(-pi / 2, 3 * pi / 2, startRadius: 40);
      expect(coord.invertDistance(6, Dim.y), closeTo(6 / 60, 1e-9));
      expect(coord.invertDistance(7, Dim.x), closeTo(7 / (70 * 2 * pi), 1e-9));
    });

    test('follows transposing', () {
      final coord = _coord(-pi / 2, 3 * pi / 2, transposed: true);
      expect(coord.invertDistance(5, Dim.x), closeTo(5 / 100, 1e-9));
      expect(coord.invertDistance(5, Dim.y), closeTo(5 / (50 * 2 * pi), 1e-9));
    });
  });
}
