import 'dart:ui' as ui;

import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const ssCardCorner = 18.0;

/// A flat card: the ground colour (or one step up), a hairline border and
/// continuous corners. No shadow, no glass.
class SsCard extends StatelessWidget {
  const SsCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.corner = ssCardCorner,
    this.raised = true,
    this.dashed = false,
    this.borderColor,
    this.fill,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final double corner;
  final bool raised;
  final bool dashed;
  final Color? borderColor;
  final Color? fill;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final shape = AppShape.all(corner);
    final color = fill ?? (raised ? palette.raised : palette.ground);
    final side = borderColor ?? palette.border;
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null || onLongPress != null) {
      content = InkWell(
        customBorder: shape,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        onLongPress: onLongPress,
        child: content,
      );
    }
    final card = Material(
      color: color,
      shape: dashed ? shape : shape.copyWith(side: BorderSide(color: side)),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
    final decorated = dashed
        ? CustomPaint(
            foregroundPainter: _DashedBorderPainter(color: side, shape: shape),
            child: card,
          )
        : card;
    if (semanticLabel == null) {
      return decorated;
    }
    return Semantics(label: semanticLabel, container: true, child: decorated);
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.shape});

  final Color color;
  final ShapeBorder shape;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.getOuterPath(
      (Offset.zero & size).deflate(0.5),
      textDirection: TextDirection.ltr,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.shape != shape;
}

/// Scales its child down a touch while pressed, as physical buttons give.
class SsPressable extends StatefulWidget {
  const SsPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.96,
    this.haptic = true,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;

  @override
  State<SsPressable> createState() => _SsPressableState();
}

class _SsPressableState extends State<SsPressable> {
  var _pressed = false;

  void _set(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) {
                HapticFeedback.lightImpact();
              }
              widget.onTap!();
            }
          : null,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: SsMotion.of(context, SsMotion.fast),
        curve: SsMotion.enter,
        child: widget.child,
      ),
    );
  }
}
