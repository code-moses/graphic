import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';

void main() {
  final bar = Attributes(
    index: 0,
    tag: null,
    position: const [Offset(0.5, 0.2), Offset(0.5, 0.8)],
    shape: RectShape(),
    color: const Color(0xff000000),
  );

  test('entering positions start at the origin of the scales', () {
    final deflated = bar.deflate({MarkEntrance.y}, const Offset(0, 0.4));

    expect(deflated.position, const [Offset(0.5, 0.4), Offset(0.5, 0.4)]);
  });

  test('entering positions start at zero without an origin', () {
    expect(bar.deflate({MarkEntrance.y}).position,
        const [Offset(0.5, 0), Offset(0.5, 0)]);
  });
}
