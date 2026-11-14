import 'dart:math' as math;

import 'package:graphic/src/dataflow/tuple.dart';

import 'continuous.dart';

/// The specification of a logarithmic scale.
///
/// It converts positive [num]s to [double]s normalized to `[0, 1]` by their logarithm, so values of different
/// orders of magnitude can be shown together. Values that are not positive are placed at the minimum.
class LogScale extends ContinuousScale<num> {
  /// Creates a logarithmic scale.
  ///
  /// Without [min] and [max], the range spans the powers of [base] around the data.
  LogScale({
    num? min,
    num? max,
    this.base = 10,
    String? title,
    String? Function(num)? formatter,
    List<num>? ticks,
  })  : assert(base > 1),
        assert(min == null || min > 0),
        super(
          min: min,
          max: max,
          title: title,
          formatter: formatter,
          ticks: ticks,
        );

  /// The base of the logarithm, also the step between the default ticks.
  num base;

  @override
  bool operator ==(Object other) =>
      other is LogScale && super == other && base == other.base;
}

/// The logarithmic scale converter.
class LogScaleConv extends ContinuousScaleConv<num> {
  LogScaleConv(
    LogScale spec,
    List<Tuple> tuples,
    String variable,
  ) : base = spec.base {
    num minTmp = double.infinity;
    num maxTmp = double.negativeInfinity;
    for (var tuple in tuples) {
      final value = tuple[variable] as num;
      if (!value.isNaN && value > 0) {
        minTmp = math.min(minTmp, value);
        maxTmp = math.max(maxTmp, value);
      }
    }
    if (minTmp == double.infinity) {
      minTmp = 1;
      maxTmp = base;
    }

    num power(double exponent) => math.pow(base, exponent);
    min = spec.min ?? power((_log(minTmp) + 1e-9).floorToDouble());
    max = spec.max ?? power((_log(maxTmp) - 1e-9).ceilToDouble());
    if (max! <= min!) max = min! * base;

    ticks = spec.ticks ?? _defaultTicks();
    title = spec.title ?? variable;
    formatter = spec.formatter ?? defaultFormatter;
  }

  /// The base of the logarithm.
  final num base;

  double _log(num value) => math.log(value) / math.log(base);

  /// The powers of [base] in the range; with fewer than three, also their 2 and 5 multiples.
  List<num> _defaultTicks() {
    final from = _log(min!).ceil();
    final to = _log(max!).floor();
    final powers = [for (var e = from; e <= to; e++) math.pow(base, e)];
    if (powers.length >= 3) return powers;
    final ticks = <num>[];
    for (var e = from - 1; e <= to; e++) {
      for (final m in const [1, 2, 5]) {
        final value = m * math.pow(base, e);
        if (value >= min! && value <= max!) ticks.add(value);
      }
    }
    return ticks;
  }

  @override
  double convert(num input) {
    if (input.isNaN) return double.nan;
    if (input <= 0) return 0;
    return (_log(input) - _log(min!)) / (_log(max!) - _log(min!));
  }

  @override
  num invert(double output) =>
      math.pow(base, _log(min!) + output * (_log(max!) - _log(min!)));

  /// Bars and areas grow from the minimum, a logarithm has no zero.
  @override
  num get zero => min!;

  @override
  String defaultFormatter(num value) => value.toString();

  @override
  bool operator ==(Object other) =>
      other is LogScaleConv && super == other && base == other.base;
}
