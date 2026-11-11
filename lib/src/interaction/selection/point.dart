import 'package:graphic/src/common/dim.dart';
import 'package:graphic/src/coord/coord.dart';
import 'package:graphic/src/dataflow/tuple.dart';
import 'dart:ui';

import 'package:graphic/src/interaction/gesture.dart';

import 'selection.dart';

/// The selection to select discrete data values.
class PointSelection extends Selection {
  /// Creates a point selection.
  PointSelection({
    this.toggle,
    this.nearest,
    this.testRadius,
    Dim? dim,
    String? variable,
    Set<GestureType>? on,
    Set<GestureType>? clear,
    Set<PointerDeviceKind>? devices,
    int? layer,
  }) : super(
          dim: dim,
          variable: variable,
          on: on,
          clear: clear,
          devices: devices,
          layer: layer,
        );

  /// Whether triggered tuples should be toggled (inserted or removed from) or replace
  /// existing selected tuples.
  ///
  /// If null, a default false is set.
  bool? toggle;

  /// To select the tuple nearest to the pointer in the coordinate, Even if it's
  /// out of [testRadius].
  ///
  /// If null, a default true is set.
  bool? nearest;

  /// Radius of the pointer test.
  ///
  /// If null, a default 10 is set.
  double? testRadius;

  @override
  bool operator ==(Object other) =>
      other is PointSelection &&
      super == other &&
      toggle == other.toggle &&
      nearest == other.nearest &&
      testRadius == other.testRadius;
}

/// The abstract distance in [dim] from [point] to the span of [position] points.
///
/// It is zero if the point is within the span. So an interval is hit anywhere
/// between its start and end, not only near its end.
double _spanDistance(List<Offset> position, Offset point, Dim dim) {
  final value = dim == Dim.x ? point.dx : point.dy;
  var min = double.infinity;
  var max = double.negativeInfinity;
  for (var p in position) {
    final v = dim == Dim.x ? p.dx : p.dy;
    if (v.isFinite) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
  }
  if (min > max) {
    // No finite position value in this dimension.
    return 0;
  }
  if (value < min) {
    return min - value;
  }
  if (value > max) {
    return value - max;
  }
  return 0;
}

/// The point selector.
///
/// The [points] have only one point.
class PointSelector extends Selector {
  PointSelector(
    this.toggle,
    this.nearest,
    this.testRadius,
    Dim? dim,
    String? variable,
    List<Offset> points,
  )   : assert(toggle != true || variable == null),
        super(
          dim,
          variable,
          points,
        );

  final bool toggle;

  final bool nearest;

  final double testRadius;

  @override
  Set<int>? select(
    AttributesGroups groups,
    List<Tuple> tuples,
    Set<int>? preSelects,
    CoordConv coord,
  ) {
    int nearestIndex = -1;
    // nearestDistance is an abstract distance.
    double nearestDistance = double.infinity;
    // Distance in the dimension not tested by dim, to break ties.
    double nearestCrossDistance = double.infinity;
    void Function(Attributes) updateNearest;

    final point = coord.invert(points.single);
    // A 1D coordinate has only the measure dimension, the domain dimension is
    // filled arbitrarily.
    final testDim = coord.dimCount == 1 ? Dim.y : dim;
    if (testDim == null) {
      updateNearest = (attributes) {
        final dx = _spanDistance(attributes.position, point, Dim.x);
        final dy = _spanDistance(attributes.position, point, Dim.y);
        // The neighborhood is an approximate square.
        final distance = (dx + dy) / 2;
        if (distance < nearestDistance) {
          nearestIndex = attributes.index;
          nearestDistance = distance;
        }
      };
    } else {
      final crossDim = testDim == Dim.x ? Dim.y : Dim.x;
      updateNearest = (attributes) {
        final distance = _spanDistance(attributes.position, point, testDim);
        if (distance > nearestDistance) {
          return;
        }
        final crossDistance =
            _spanDistance(attributes.position, point, crossDim);
        if (distance < nearestDistance ||
            crossDistance < nearestCrossDistance) {
          nearestIndex = attributes.index;
          nearestDistance = distance;
          nearestCrossDistance = crossDistance;
        }
      };
    }

    for (var group in groups) {
      for (var attributes in group) {
        updateNearest(attributes);
      }
    }

    if (!nearest) {
      if (nearestDistance > coord.invertDistance(testRadius, testDim)) {
        return null;
      }
    }

    if (variable != null) {
      // Not toggle.

      final rst = <int>{};
      final value = tuples[nearestIndex][variable];
      for (var i = 0; i < tuples.length; i++) {
        if (tuples[i][variable] == value) {
          rst.add(i);
        }
      }
      return rst.isEmpty ? null : rst;
    }

    Set<int> rst;
    if (toggle && preSelects != null) {
      if (preSelects.contains(nearestIndex)) {
        rst = {...preSelects}..remove(nearestIndex);
      } else {
        rst = {...preSelects}..add(nearestIndex);
      }
    } else {
      rst = {nearestIndex};
    }
    return rst.isEmpty ? null : rst;
  }
}
