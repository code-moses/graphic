import 'dart:math';
import 'dart:ui';

import 'package:graphic/src/algebra/varset.dart';
import 'package:graphic/src/coord/coord.dart';
import 'package:graphic/src/dataflow/tuple.dart';
import 'package:graphic/src/scale/scale.dart';

import 'modifier.dart';
import 'stack.dart';

/// The specification of a symmetric modifier.
///
/// The symmetric method redistributes all position points symmetricly around the
/// zero, keeping their relative position unchanged.
///
/// It is mostly used in river chart, and funnel chart.
class SymmetricModifier extends Modifier {
  @override
  bool operator ==(Object other) => other is SymmetricModifier;

  @override
  bool equalTo(Object other) => other is SymmetricModifier && super == other;

  @override
  AttributesGroups modify(
      AttributesGroups groups,
      Map<String, ScaleConv<dynamic, num>> scales,
      AlgForm form,
      CoordConv coord,
      Offset origin) {
    final normalZero = origin.dy;

    // The y range at each x over all groups, which may lack some x values.
    final minYs = <double, double>{};
    final maxYs = <double, double>{};
    for (var group in groups) {
      for (var attributes in group) {
        final x = domainOf(attributes.position);
        if (x == null) continue;
        for (var point in attributes.position) {
          final y = point.dy;
          if (y.isFinite) {
            minYs[x] = min(minYs[x] ?? double.infinity, y);
            maxYs[x] = max(maxYs[x] ?? double.negativeInfinity, y);
          }
        }
      }
    }

    final AttributesGroups rst = [];
    for (var group in groups) {
      final groupRst = <Attributes>[];
      for (var attributes in group) {
        final x = domainOf(attributes.position);
        if (x == null || !minYs.containsKey(x)) {
          groupRst.add(attributes);
          continue;
        }
        final symmetricBias = normalZero - (minYs[x]! + maxYs[x]!) / 2;
        groupRst.add(attributes.withPosition(attributes.position
            .map((point) => Offset(point.dx, point.dy + symmetricBias))
            .toList()));
      }
      rst.add(groupRst);
    }
    return rst;
  }
}
