import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';
import 'package:graphic/src/guide/axis/axis.dart';
import 'package:graphic/src/guide/axis/horizontal.dart';

final _coord = RectCoordConv(
    const Rect.fromLTWH(40, 0, 200, 100), 2, 0.5, false, [0, 1], [0, 1]);

List<TickInfo> _ticks(List<String> texts) => [
      for (var i = 0; i < texts.length; i++)
        TickInfo(i / (texts.length - 1), texts[i])
          ..label = LabelStyle(textStyle: const TextStyle(fontSize: 10))
          ..grid = PaintStyle(strokeColor: const Color(0xff000000)),
    ];

void main() {
  test('leaves out labels that would overlap', () {
    final texts = [for (var i = 0; i < 20; i++) 'Category $i'];
    final labels = renderHorizontalAxis(_ticks(texts), 0, false, null, _coord)!
        .whereType<LabelElement>()
        .toList();

    expect(labels.length, lessThan(texts.length));
    expect(labels.first.text, 'Category 0');
    for (var i = 1; i < labels.length; i++) {
      expect(
          labels[i - 1].getBlock().right, lessThan(labels[i].getBlock().left));
    }
  });

  test('keeps more labels when they are rotated upright along the axis', () {
    final texts = [for (var i = 0; i < 20; i++) 'Category $i'];
    final upright = renderHorizontalAxis(_ticks(texts), 0, false, null, _coord)!
        .whereType<LabelElement>()
        .length;

    final rotatedTicks = [
      for (var i = 0; i < texts.length; i++)
        TickInfo(i / (texts.length - 1), texts[i])
          ..label = LabelStyle(
            textStyle: const TextStyle(fontSize: 10),
            // Vertical: the label's horizontal footprint is its text height
            rotation: -1.5708,
            align: Alignment.centerLeft,
            offset: const Offset(0, 5),
          ),
    ];
    final rotated = renderHorizontalAxis(rotatedTicks, 0, false, null, _coord)!
        .whereType<LabelElement>()
        .toList();

    expect(rotated.length, greaterThan(upright));
    for (var i = 1; i < rotated.length; i++) {
      expect(rotated[i - 1].getBlock().right,
          lessThanOrEqualTo(rotated[i].getBlock().left + 0.5));
    }
  });
}
