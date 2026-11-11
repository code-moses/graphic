// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';
import 'package:graphic/src/coord/rect.dart';
import 'package:graphic/src/dataflow/tuple.dart';
import 'package:graphic/src/interaction/selection/point.dart';
import 'package:graphic/src/interaction/selection/selection.dart';

final _coord = RectCoordConv(
    const Rect.fromLTWH(0, 0, 100, 100), 2, 0.5, false, [0, 1], [0, 1]);

AttributesGroups _bars(int count) => [
      [
        for (var i = 0; i < count; i++)
          Attributes(
            index: i,
            position: [
              Offset((i + 0.5) / count, 0),
              Offset((i + 0.5) / count, 1),
            ],
            shape: RectShape(),
            color: const Color(0xff000000),
          )
      ]
    ];

List<Tuple> _tuples(int count) => [
      for (var i = 0; i < count; i++) {'i': i}
    ];

Map<String, Selector> _tapAt(double x) => {
      'select':
          PointSelector(false, true, 10, Dim.x, null, [Offset(x * 100, 50)]),
    };

void main() {
  late SelectOp op;
  late StreamController<Selected?> stream;
  late List<Selected?> emitted;

  Selected? evaluate({Map<String, Selector>? selectors, int? count}) {
    op.params['selectors'] = selectors ?? op.params['selectors'];
    if (count != null) {
      op.params['groups'] = _bars(count);
      op.params['tuples'] = _tuples(count);
    }
    op.runed = false;
    op.run();
    return op.value;
  }

  setUp(() {
    emitted = [];
    stream = StreamController<Selected?>.broadcast(sync: true)
      ..stream.listen(emitted.add);
    op = SelectOp({
      'selectors': null,
      'groups': _bars(4),
      'tuples': _tuples(4),
      'coord': _coord,
    }, null)
      ..stream = stream;
  });

  tearDown(() => stream.close());

  test('selects and emits on a new gesture', () {
    expect(evaluate(selectors: _tapAt(0.6)), {
      'select': {2}
    });
    expect(emitted, [
      {
        'select': {2}
      }
    ]);
  });

  test('keeps the selection without emitting when data changes', () {
    evaluate(selectors: _tapAt(0.6));
    emitted.clear();

    // With 8 bars, the old pointer would hit index 4.
    expect(evaluate(count: 8), {
      'select': {2}
    });
    expect(emitted, isEmpty);
  });

  test('drops selected indexes of removed tuples without emitting', () {
    evaluate(selectors: _tapAt(0.9));
    emitted.clear();

    expect(evaluate(count: 2), isNull);
    expect(emitted, isEmpty);
  });

  test('keeps an initial selection when data changes', () {
    op = SelectOp({
      'selectors': null,
      'groups': _bars(4),
      'tuples': _tuples(4),
      'coord': _coord,
    }, {
      'select': {1}
    });

    expect(evaluate(count: 5), {
      'select': {1}
    });
  });

  test('selects again on the next gesture after a data change', () {
    evaluate(selectors: _tapAt(0.6));
    evaluate(count: 8);
    emitted.clear();

    expect(evaluate(selectors: _tapAt(0.6)), {
      'select': {4}
    });
    expect(emitted, hasLength(1));
  });
}
