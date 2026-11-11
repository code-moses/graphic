import 'dart:ui';

import 'element.dart';
import 'group.dart';
import 'label.dart';
import 'path.dart';

/// A transparent copy of [element], for elements to fade in from or out to in
/// transitions.
///
/// Primitive elements become [PathElement]s, as transitions normalize them to
/// anyway. Elements that cannot be made transparent, like images or labels
/// with a text span builder, are returned as they are.
MarkElement transparentCopy(MarkElement element) {
  if (element is GroupElement) {
    return GroupElement(
      elements: element.elements.map(transparentCopy).toList(),
      rotation: element.rotation,
      rotationAxis: element.rotationAxis,
      tag: element.tag,
    );
  }
  if (element is PrimitiveElement) {
    return PathElement(
      segments: element.toSegments(),
      style: _transparentPaint(element.style),
      rotation: element.rotation,
      rotationAxis: element.rotationAxis,
      tag: element.tag,
    );
  }
  if (element is LabelElement) {
    final style = element.style;
    final textStyle = style.textStyle;
    if (textStyle == null) return element;
    return LabelElement(
      text: element.text,
      anchor: element.anchor,
      defaultAlign: element.defaultAlign,
      style: LabelStyle(
        textStyle: textStyle.copyWith(
            color: (textStyle.color ?? const Color(0xff000000)).withAlpha(0)),
        textAlign: style.textAlign,
        textDirection: style.textDirection,
        textScaler: style.textScaler,
        maxLines: style.maxLines,
        ellipsis: style.ellipsis,
        locale: style.locale,
        strutStyle: style.strutStyle,
        textWidthBasis: style.textWidthBasis,
        textHeightBehavior: style.textHeightBehavior,
        minWidth: style.minWidth,
        maxWidth: style.maxWidth,
        offset: style.offset,
        rotation: style.rotation,
        align: style.align,
      ),
      tag: element.tag,
    );
  }
  return element;
}

PaintStyle _transparentPaint(PaintStyle style) => PaintStyle(
      fillColor: style.fillColor?.withAlpha(0),
      fillGradient: style.fillGradient?.scale(0),
      fillShader: style.fillShader,
      strokeColor: style.strokeColor?.withAlpha(0),
      strokeGradient: style.strokeGradient?.scale(0),
      strokeShader: style.strokeShader,
      gradientBounds: style.gradientBounds,
      blendMode: style.blendMode,
      strokeWidth: style.strokeWidth,
      strokeCap: style.strokeCap,
      strokeJoin: style.strokeJoin,
      strokeMiterLimit: style.strokeMiterLimit,
      // A shadow would not fade with the colors
      elevation: null,
      dash: style.dash,
      dashOffset: style.dashOffset,
    );

/// Start and end elements of a transition, paired by index.
class TagPairs {
  TagPairs(this.starts, this.ends, this.exits);

  final List<MarkElement> starts;

  final List<MarkElement> ends;

  /// Number of pairs at the end whose element fades out.
  final int exits;
}

/// Pairs the elements of a transition from [from] to [to] by tag.
///
/// Elements of [to] without a match fade in, elements of [from] without one
/// fade out. Those fading out come last.
TagPairs pairByTag(List<MarkElement> from, List<MarkElement> to) {
  final unused = <String?, List<MarkElement>>{};
  for (var element in from) {
    unused.putIfAbsent(element.tag, () => []).add(element);
  }

  final starts = <MarkElement>[];
  final ends = <MarkElement>[];
  for (var element in to) {
    final candidates = unused[element.tag];
    final match = candidates == null || candidates.isEmpty
        ? null
        : candidates.removeAt(0);
    starts.add(match ?? transparentCopy(element));
    ends.add(element);
  }

  var exits = 0;
  for (var element in from) {
    if (unused[element.tag]?.remove(element) ?? false) {
      starts.add(element);
      ends.add(transparentCopy(element));
      exits++;
    }
  }
  return TagPairs(starts, ends, exits);
}
