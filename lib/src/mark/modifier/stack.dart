import 'dart:ui';

import 'package:graphic/src/algebra/varset.dart';
import 'package:graphic/src/coord/coord.dart';
import 'package:graphic/src/dataflow/tuple.dart';
import 'package:graphic/src/scale/scale.dart';

import 'modifier.dart';

/// The specification of a stack modifier.
///
/// The stack method cummulates marks in order of the values on a splitter.
/// Each mark item is moved onto the top of the items before it at the same x,
/// so groups may lack some x values: they do not need to be completed with
/// zero items.
///
/// Positive and negative values stack separately, away from zero.
class StackModifier extends Modifier {
  @override
  bool equalTo(Object other) => other is StackModifier;

  @override
  AttributesGroups modify(
      AttributesGroups groups,
      Map<String, ScaleConv<dynamic, num>> scales,
      AlgForm form,
      CoordConv coord,
      Offset origin) {
    final normalZero = origin.dy;

    // The current top of the stack at each x, for each direction.
    final positiveTops = <double, double>{};
    final negativeTops = <double, double>{};

    final AttributesGroups rst = [];
    for (var group in groups) {
      final groupRst = <Attributes>[];
      for (var attributes in group) {
        final position = attributes.position;
        final x = domainOf(position);
        final end = _farthestFromZero(position, normalZero);
        if (x == null || end == null) {
          groupRst.add(attributes);
          continue;
        }

        final tops = end >= normalZero ? positiveTops : negativeTops;
        final shift = (tops[x] ?? normalZero) - normalZero;
        tops[x] = end + shift;
        groupRst.add(attributes.withPosition(position
            .map((point) => Offset(point.dx, point.dy + shift))
            .toList()));
      }
      rst.add(groupRst);
    }

    return rst;
  }

  /// The finite y of [position] farthest from [normalZero], null if there is none.
  static double? _farthestFromZero(List<Offset> position, double normalZero) {
    double? rst;
    for (var point in position) {
      final y = point.dy;
      if (y.isFinite &&
          (rst == null || (y - normalZero).abs() > (rst - normalZero).abs())) {
        rst = y;
      }
    }
    return rst;
  }
}

/// The x of a mark item's [position] that items of other groups at the same
/// place share, null if there is no finite one.
double? domainOf(List<Offset> position) {
  for (var point in position) {
    if (point.dx.isFinite) {
      return point.dx;
    }
  }
  return null;
}
