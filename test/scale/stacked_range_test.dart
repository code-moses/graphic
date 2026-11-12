import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';
import 'package:graphic/src/scale/linear.dart';

void main() {
  final tuples = [
    {'x': 'a', 'y': 3, 'g': '1'},
    {'x': 'a', 'y': 4, 'g': '2'},
    {'x': 'b', 'y': 5, 'g': '1'},
    {'x': 'b', 'y': -2, 'g': '2'},
    {'x': 'b', 'y': -3, 'g': '3'},
  ];

  test('covers single values when not stacked', () {
    final conv =
        LinearScaleConv(LinearScale(marginMin: 0, marginMax: 0), tuples, 'y');

    expect(conv.min, -3);
    expect(conv.max, 5);
  });

  test('covers positive and negative sums at each x when stacked', () {
    final conv = LinearScaleConv(
        LinearScale(marginMin: 0, marginMax: 0), tuples, 'y',
        stacked: true, stackedBy: 'x');

    expect(conv.max, 7);
    expect(conv.min, -5);
  });

  test('covers the sum of all values when stacked without x', () {
    final conv = LinearScaleConv(LinearScale(min: 0, marginMax: 0), tuples, 'y',
        stacked: true);

    expect(conv.min, 0);
    expect(conv.max, 12);
  });

  test('keeps a given range', () {
    final conv = LinearScaleConv(LinearScale(min: 0, max: 4), tuples, 'y',
        stacked: true, stackedBy: 'x');

    expect(conv.max, 4);
  });
}
