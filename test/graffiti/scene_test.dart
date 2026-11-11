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

double _paintedHeight(MarkScene scene) =>
    (scene.paintedElements!.single as RectElement).rect.height;

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

  double fillAlpha(MarkElement element) =>
      (element as PrimitiveElement).style.fillColor!.a;

  testWidgets('fades in elements that are new', (tester) async {
    scene = create(const Duration(milliseconds: 400));
    scene
      ..set([_bar(10, tag: 'a')])
      ..update()
      ..set([_bar(20, tag: 'a'), _bar(40, tag: 'b')])
      ..update();

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final painted = scene.paintedElements!;
    expect(painted, hasLength(2));
    expect((painted[0] as dynamic).path.getBounds().height, closeTo(15, 0.5),
        reason: 'a matched element still morphs');
    expect(fillAlpha(painted[1]), closeTo(0.5, 0.05));

    await tester.pump(const Duration(milliseconds: 300));
    expect(scene.paintedElements, hasLength(2));
    expect(fillAlpha(scene.paintedElements![1]), 1);
  });

  testWidgets('fades out elements that are gone and then removes them',
      (tester) async {
    scene = create(const Duration(milliseconds: 400));
    scene
      ..set([_bar(10, tag: 'a'), _bar(40, tag: 'b')])
      ..update()
      ..set([_bar(10, tag: 'a')])
      ..update();

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(scene.paintedElements, hasLength(2));
    expect(fillAlpha(scene.paintedElements![1]), closeTo(0.5, 0.05));

    await tester.pump(const Duration(milliseconds: 300));
    expect(scene.paintedElements, hasLength(1));
  });

  testWidgets('continues from the screen when interrupted during a fade',
      (tester) async {
    scene = create(const Duration(milliseconds: 400));
    scene
      ..set([_bar(10, tag: 'a'), _bar(40, tag: 'b')])
      ..update()
      ..set([_bar(10, tag: 'a')])
      ..update();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    scene
      ..set([_bar(50, tag: 'a')])
      ..update();
    await tester.pump();
    expect(scene.paintedElements, hasLength(1),
        reason: 'the faded element is not taken over');
    await tester.pump(const Duration(milliseconds: 500));
    expect((scene.paintedElements!.single as RectElement).rect.height, 50);
  });
}
