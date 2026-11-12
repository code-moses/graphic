import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';
import 'package:graphic/src/mark/mark.dart';

void main() {
  const region = Rect.fromLTWH(10, 20, 200, 100);
  final clip = RectElement(rect: region, style: PaintStyle());

  RectCoordConv coord({bool transposed = false}) =>
      RectCoordConv(region, 2, 0.5, transposed, [0, 1], [0, 1]);

  test('a revealed mark starts with an empty strip at the start of the domain',
      () {
    expect(entranceClip({MarkEntrance.reveal}, coord(), clip).rect,
        const Rect.fromLTRB(10, 20, 10, 120));
    expect(
        entranceClip({MarkEntrance.reveal}, coord(transposed: true), clip).rect,
        const Rect.fromLTRB(10, 120, 210, 120));
  });

  test('other entrances keep the clip', () {
    expect(entranceClip({MarkEntrance.y}, coord(), clip), same(clip));
  });
}
