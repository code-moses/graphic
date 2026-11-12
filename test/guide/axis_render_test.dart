import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';
import 'package:graphic/src/guide/axis/axis.dart';
import 'package:graphic/src/guide/axis/horizontal.dart';
import 'package:graphic/src/guide/axis/vertical.dart';

final _coord = RectCoordConv(
    const Rect.fromLTWH(40, 0, 200, 100), 2, 0.5, false, [0, 1], [0, 1]);

List<TickInfo> _ticks(List<String> texts) => [
      for (var i = 0; i < texts.length; i++)
        TickInfo(i / (texts.length - 1), texts[i])
          ..label = LabelStyle(textStyle: const TextStyle(fontSize: 10))
          ..grid = PaintStyle(strokeColor: const Color(0xff000000)),
    ];

void main() {
  test(
      'tags axis elements by their tick, so they move along when scales change',
      () {
    final elements = renderVerticalAxis(_ticks(['0', '50', '100']), 0, false,
        PaintStyle(strokeColor: const Color(0xff000000)), _coord)!;

    expect(elements.map((e) => e.tag),
        containsAll(['line', 'label:0', 'label:50', 'label:100']));
    expect(renderVerticalGrid(_ticks(['0', '50']), _coord)!.map((e) => e.tag),
        ['grid:0', 'grid:50']);
  });

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
}
