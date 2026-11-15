import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';

void main() {
  test('element annotations with other values differ', () {
    final label = Label('a');
    final a =
        TagAnnotation(label: label, variables: ['x', 'y'], values: ['A', 1]);
    final b =
        TagAnnotation(label: label, variables: ['x', 'y'], values: ['B', 1]);
    final c =
        TagAnnotation(label: label, variables: ['x', 'y'], values: ['A', 1]);

    expect(a == b, isFalse);
    expect(a == c, isTrue);
  });
}
