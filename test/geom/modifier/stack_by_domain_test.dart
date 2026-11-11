import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';
import 'package:graphic/src/coord/rect.dart';
import 'package:graphic/src/dataflow/tuple.dart';

final _coord = RectCoordConv(
    const Rect.fromLTWH(0, 0, 100, 100), 2, 0.5, false, [0, 1], [0, 1]);

/// A bar at [x] from zero (0.5) to [y].
Attributes _bar(int index, double x, double y) => Attributes(
      index: index,
      position: [Offset(x, 0.5), Offset(x, y)],
      shape: RectShape(),
      color: const Color(0xff000000),
    );

AttributesGroups _modify(Modifier modifier, AttributesGroups groups) =>
    modifier.modify(groups, const {}, const [], _coord, const Offset(0, 0.5));

List<List<double>> _ys(AttributesGroups groups) => [
      for (var group in groups)
        for (var a in group) [a.position.first.dy, a.position.last.dy]
    ];

void main() {
  group('StackModifier', () {
    test('stacks items of the same x, even if a group lacks some x', () {
      final groups = [
        [_bar(0, 0.25, 0.6), _bar(1, 0.75, 0.7)],
        // The second series has no value at 0.25
        [_bar(2, 0.75, 0.6)],
        [_bar(3, 0.25, 0.55), _bar(4, 0.75, 0.55)],
      ];

      final ys = _ys(_modify(StackModifier(), groups));
      expect(ys[0], [0.5, 0.6]);
      expect(ys[1], [0.5, 0.7]);
      expect(ys[2][0], closeTo(0.7, 1e-9));
      expect(ys[2][1], closeTo(0.8, 1e-9));
      expect(ys[3][0], closeTo(0.6, 1e-9), reason: 'onto the first series');
      expect(ys[3][1], closeTo(0.65, 1e-9));
      expect(ys[4][0], closeTo(0.8, 1e-9), reason: 'onto both series');
      expect(ys[4][1], closeTo(0.85, 1e-9));
    });

    test('stacks positive and negative values away from zero', () {
      final groups = [
        [_bar(0, 0.5, 0.6)],
        [_bar(1, 0.5, 0.4)],
        [_bar(2, 0.5, 0.7)],
        [_bar(3, 0.5, 0.45)],
      ];

      final ys = _ys(_modify(StackModifier(), groups));
      expect(ys[1], [0.5, 0.4], reason: 'a negative value starts at zero');
      expect(ys[2][0], closeTo(0.6, 1e-9));
      expect(ys[3][0], closeTo(0.4, 1e-9));
      expect(ys[3][1], closeTo(0.35, 1e-9));
    });

    test('keeps items without a finite position', () {
      final empty = Attributes(
        index: 0,
        position: [const Offset(double.nan, double.nan)],
        shape: RectShape(),
        color: const Color(0xff000000),
      );
      final rst = _modify(StackModifier(), [
        [empty],
        [_bar(1, 0.5, 0.6)],
      ]);
      expect(rst.first.single, same(empty));
      expect(rst.last.single.position.last.dy, 0.6);
    });
  });

  group('SymmetricModifier', () {
    test('centers each x on its own, even if a group lacks some x', () {
      final groups = [
        [_bar(0, 0.25, 0.7), _bar(1, 0.75, 0.6)],
        [_bar(2, 0.75, 0.9)],
      ];

      final rst = _modify(SymmetricModifier(), groups);
      // x 0.25 spans 0.5..0.7, centered around 0.5 it moves by -0.1
      expect(rst[0][0].position.last.dy, closeTo(0.6, 1e-9));
      // x 0.75 spans 0.5..0.9, it moves by -0.2
      expect(rst[0][1].position.last.dy, closeTo(0.4, 1e-9));
      expect(rst[1][0].position.last.dy, closeTo(0.7, 1e-9));
    });
  });
}
