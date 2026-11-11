import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';
import 'package:graphic/src/graffiti/scene.dart';

RectElement _bar(double height, {String tag = 'a'}) => RectElement(
      rect: Rect.fromLTWH(0, 100 - height, 10, height),
      style: PaintStyle(fillColor: const Color(0xff000000)),
      tag: tag,
    );

double _paintedHeight(MarkScene scene) => (scene.paintedElements!.single as RectElement).rect.height;

void main() {
  late MarkScene scene;

  MarkScene create(Duration duration) => MarkScene(
        layer: 0,
        builtinLayer: 0,
        transition: Transition(duration: duration),
        tickerProvider: const TestVSync(),
        repaint: () {},
      );

  tearDown(() => scene.dispose());

  testWidgets('animates a change with the transition', (tester) async {
    scene = create(const Duration(milliseconds: 400));
    scene
      ..set([_bar(10)])
      ..update()
      ..set([_bar(50)])
      ..update();

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_paintedHeight(scene), closeTo(30, 0.5));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_paintedHeight(scene), 50);
  });

  testWidgets('continues an interrupted animation from what is on screen',
      (tester) async {
    scene = create(const Duration(milliseconds: 400));
    scene
      ..set([_bar(10)])
      ..update()
      ..set([_bar(50)])
      ..update();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_paintedHeight(scene), closeTo(30, 0.5));

    scene
      ..set([_bar(10)])
      ..update();
    await tester.pump();
    expect(_paintedHeight(scene), closeTo(30, 0.5),
        reason: 'no jump to the previous target');
    await tester.pump(const Duration(milliseconds: 200));
    expect(_paintedHeight(scene), closeTo(20, 0.5));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_paintedHeight(scene), 10);
  });

  testWidgets('uses the transition given for a change', (tester) async {
    scene = create(const Duration(seconds: 1));
    scene
      ..set([_bar(10)])
      ..update()
      ..set(
          [_bar(50)],
          null,
          Transition(
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear))
      ..update();

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_paintedHeight(scene), closeTo(30, 0.5));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_paintedHeight(scene), 50);
  });

  testWidgets(
      'sets a change with a zero duration at once, stopping a running animation',
      (tester) async {
    scene = create(const Duration(milliseconds: 400));
    scene
      ..set([_bar(10)])
      ..update()
      ..set([_bar(50)])
      ..update();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    scene
      ..set([_bar(80)], null, Transition(duration: Duration.zero))
      ..update();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_paintedHeight(scene), 80);
  });
}
