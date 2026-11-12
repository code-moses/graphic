import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';

void main() {
  final data = [
    {'x': 'a', 'y': 1},
    {'x': 'b', 'y': 2},
  ];

  Future<List<TooltipInfo?>> pumpChart(
      WidgetTester tester, Map<String, Set<int>>? selected) async {
    final infos = <TooltipInfo?>[];
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 200,
          height: 100,
          child: Chart(
            data: data,
            variables: {
              'x': Variable(accessor: (Map map) => map['x'] as String),
              'y': Variable(accessor: (Map map) => map['y'] as num),
            },
            marks: [IntervalMark(selected: selected)],
            selections: {'tap': PointSelection(dim: Dim.x)},
            tooltip: TooltipGuide(
              renderer: (_, __, ___) => const [],
              onChanged: infos.add,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    return infos;
  }

  testWidgets('reports the selected tuples and their anchor', (tester) async {
    final infos = await pumpChart(tester, {
      'tap': {1}
    });

    final info = infos.last!;
    expect(info.selectedTuples.keys, [1]);
    expect(info.selectedTuples[1]!['x'], 'b');
    expect(info.size, const Size(200, 100));
    expect(info.anchor.dx, greaterThan(100));
  });

  testWidgets('reports null without a selection', (tester) async {
    final infos = await pumpChart(tester, null);

    expect(infos, isNotEmpty);
    expect(infos.last, isNull);
  });
}
