import 'dart:math' as math;

import 'package:graphic/src/dataflow/tuple.dart';
import 'package:graphic/src/scale/util/nice_numbers.dart';
import 'package:graphic/src/scale/util/nice_range.dart';

import 'continuous.dart';

/// The specification of a linear scale.
///
/// It converts [num] to [double]s normalized to `[0, 1]` linearly.
class LinearScale extends ContinuousScale<num> {
  /// Creates a linear scale.
  LinearScale({
    num? min,
    num? max,
    double? marginMin,
    double? marginMax,
    String? title,
    String? Function(num)? formatter,
    List<num>? ticks,
    int? tickCount,
    bool? niceRange,
  }) : super(
          min: min,
          max: max,
          marginMin: marginMin,
          marginMax: marginMax,
          title: title,
          formatter: formatter,
          ticks: ticks,
          tickCount: tickCount,
          niceRange: niceRange,
        );

  @override
  bool operator ==(Object other) => other is LinearScale && super == other;
}

/// The linear scale converter.
class LinearScaleConv extends ContinuousScaleConv<num> {
  /// Creates a linear scale converter.
  ///
  /// If [stacked] is true, the variable is the measure of a stacked mark and
  /// the range also covers the sums of its positive and of its negative values
  /// at each value of [stackedBy], or of all values if [stackedBy] is null.
  LinearScaleConv(
    LinearScale spec,
    List<Tuple> tuples,
    String variable, {
    bool stacked = false,
    String? stackedBy,
  }) {
    if (spec.min != null && spec.max != null) {
      min = spec.min;
      max = spec.max;
    } else {
      // Don't use the first one in case it is NaN.
      num minTmp = double.infinity;
      num maxTmp = double.negativeInfinity;
      for (var tuple in tuples) {
        final value = tuple[variable] as num;
        if (!value.isNaN) {
          minTmp = math.min(minTmp, value);
          maxTmp = math.max(maxTmp, value);
        }
      }

      if (stacked) {
        final positiveSums = <Object?, num>{};
        final negativeSums = <Object?, num>{};
        for (var tuple in tuples) {
          final value = tuple[variable] as num;
          if (!value.isFinite) continue;
          final key = stackedBy == null ? null : tuple[stackedBy];
          final sums = value >= 0 ? positiveSums : negativeSums;
          sums[key] = (sums[key] ?? 0) + value;
        }
        for (var sum in positiveSums.values) {
          maxTmp = math.max(maxTmp, sum);
        }
        for (var sum in negativeSums.values) {
          minTmp = math.min(minTmp, sum);
        }
      }

      // If all data are the same, the range is 10, to get a nice margin 1 and avoid
      // 0 problem.
      final range = maxTmp == minTmp ? 10 : maxTmp - minTmp;
      final marginMin = range * (spec.marginMin ?? 0.1);
      final marginMax = range * (spec.marginMax ?? 0.1);
      min = spec.min ?? minTmp - marginMin;
      max = spec.max ?? maxTmp + marginMax;
    }

    final tickCount = spec.tickCount ?? 5;

    if (spec.niceRange == true) {
      final niceRange = linearNiceRange(min!, max!, tickCount);
      min = niceRange.first;
      max = niceRange.last;
    }

    if (spec.ticks != null) {
      ticks = spec.ticks!;
    } else {
      ticks = linearNiceNumbers(min!, max!, tickCount);
    }

    title = spec.title ?? variable;
    formatter = spec.formatter ?? defaultFormatter;
  }

  @override
  double convert(num input) => (input - min!) / (max! - min!);

  @override
  num invert(double output) => min! + output * (max! - min!);

  @override
  num get zero => 0;

  @override
  String defaultFormatter(num value) => value.toString();

  @override
  bool operator ==(Object other) => other is LinearScaleConv && super == other;
}
