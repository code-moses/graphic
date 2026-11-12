import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/src/dataflow/dataflow.dart';
import 'package:graphic/src/dataflow/operator.dart';

class _Source extends Operator<int> {
  _Source() : super(null, 0);

  @override
  bool get runInit => false;

  @override
  int evaluate() => value!;
}

class _Double extends Operator<int> {
  _Double(Map<String, dynamic> params) : super(params);

  int runs = 0;

  int? get result => value;

  @override
  int evaluate() {
    runs++;
    return (params['source'] as int) * 2;
  }
}

class _Flow extends Dataflow {}

void main() {
  test('the first update after initialization reaches its targets', () async {
    final flow = _Flow();
    final source = flow.add(_Source());
    final doubled = flow.add(_Double({'source': source}));
    await flow.run(init: true);
    expect(doubled.result, 0);

    final stream = StreamController<int?>.broadcast();
    flow.bindStream(stream, source);
    stream.add(21);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(doubled.result, 42);
    expect(doubled.runs, 2);
  });
}
