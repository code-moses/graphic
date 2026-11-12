import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';
import 'package:graphic/src/guide/axis/axis.dart';
import 'package:graphic/src/guide/axis/axis_padding.dart';

List<TickInfo> _ticks(List<String> texts) => [
      for (var i = 0; i < texts.length; i++)
        TickInfo(texts.length == 1 ? 0.5 : i / (texts.length - 1), texts[i])
          ..label = LabelStyle(
              textStyle: const TextStyle(fontSize: 10),
              offset: const Offset(-7.5, 0)),
    ];

void main() {
  const size = Size(300, 200);

  test('leaves room for the widest label of a vertical axis', () {
    final short = measureAxisPadding(size, [
      const AxisLayout(Dim.y, 0, false)
    ], [
      _ticks(['0', '5'])
    ]);
    final wide = measureAxisPadding(size, [
      const AxisLayout(Dim.y, 0, false)
    ], [
      _ticks(['0', '1.000.000'])
    ]);

    expect(wide.left, greaterThan(short.left));
    expect(wide.left, greaterThan(9 * 10.0));
  });

  test('leaves room below a horizontal axis', () {
    final ticks = [
      for (var tick in _ticks(['a', 'b']))
        tick
          ..label = LabelStyle(
              textStyle: const TextStyle(fontSize: 10),
              offset: const Offset(0, 7.5))
    ];
    final padding =
        measureAxisPadding(size, [const AxisLayout(Dim.x, 0, false)], [ticks]);

    expect(padding.bottom, greaterThan(7.5));
  });

  test('keeps the minimum without axes', () {
    expect(measureAxisPadding(size, const [], const []),
        const EdgeInsets.fromLTRB(4, 6, 8, 4));
  });

  test('never takes more than half of the chart', () {
    final padding = measureAxisPadding(const Size(100, 100), [
      const AxisLayout(Dim.y, 0, false)
    ], [
      _ticks(['a very very long label that does not fit'])
    ]);

    expect(padding.left, 50);
  });

  group('thinLabels', () {
    test('keeps all labels that do not overlap', () {
      final labels = [
        for (var i = 0; i < 4; i++) Rect.fromLTWH(i * 20, 0, 10, 10)
      ];

      expect(thinLabels(labels, true), {0, 1, 2, 3});
    });

    test('keeps every n-th label when they overlap', () {
      final labels = [
        for (var i = 0; i < 6; i++) Rect.fromLTWH(i * 10, 0, 15, 10)
      ];

      expect(thinLabels(labels, true), {0, 2, 4});
    });

    test('compares vertical labels by their height', () {
      final labels = [
        for (var i = 0; i < 5; i++) Rect.fromLTWH(0, i * 8, 50, 10)
      ];

      expect(thinLabels(labels, false), {0, 2, 4});
    });
  });
}
