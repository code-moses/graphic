import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart';

void main() {
  group('LogScaleConv', () {
    LogScaleConv conv(List<num> values, {LogScale? spec}) => LogScaleConv(
        spec ?? LogScale(),
        [
          for (final v in values) {'v': v}
        ],
        'v');

    test('spans the powers of ten around the data', () {
      final scale = conv([3, 40, 7000]);

      expect(scale.min, 1);
      expect(scale.max, 10000);
      expect(scale.ticks, [1, 10, 100, 1000, 10000]);
    });

    test('places each power of ten an equal step apart', () {
      final scale = conv([1, 1000]);

      expect(scale.convert(1), 0);
      expect(scale.convert(10), closeTo(1 / 3, 1e-9));
      expect(scale.convert(1000), closeTo(1, 1e-9));
      expect(scale.invert(2 / 3), closeTo(100, 1e-6));
    });

    test('puts values that are not positive at the minimum', () {
      final scale = conv([0, -5, 50]);

      expect(scale.convert(0), 0);
      expect(scale.convert(-5), 0);
      expect(scale.zero, scale.min);
    });

    test('adds 2 and 5 multiples within one decade', () {
      expect(conv([2, 8]).ticks, [1, 2, 5, 10]);
    });
  });
}
