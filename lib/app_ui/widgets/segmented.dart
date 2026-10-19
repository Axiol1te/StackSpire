import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class SsSegment<T> {
  const SsSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Pill segments with an indicator that slides to the chosen one.
class SsSegmented<T> extends StatelessWidget {
  const SsSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.color,
  });

  final List<SsSegment<T>> segments;
  final T value;
  final ValueChanged<T>? onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final accent = color ?? palette.accent;
    final index = segments.indexWhere((s) => s.value == value);
    final duration = SsMotion.of(context, SsMotion.medium);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: palette.raised,
        shape: AppShape.full.copyWith(side: BorderSide(color: palette.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / segments.length;
          final showIcons =
              width >= MediaQuery.textScalerOf(context).scale(118);
          return Stack(
            children: [
              if (index >= 0)
                AnimatedPositionedDirectional(
                  duration: duration,
                  curve: SsMotion.emphasized,
                  start: width * index,
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: palette.tint(accent, palette.isDark ? 0.2 : 0.16),
                      shape: AppShape.full.copyWith(
                        side: BorderSide(color: accent.withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final (i, segment) in segments.indexed)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == index,
                        label: segment.label,
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onChanged == null || i == index
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  onChanged!(segment.value);
                                },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 40),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (segment.icon != null && showIcons) ...[
                                    Icon(
                                      segment.icon,
                                      size: 15,
                                      color: i == index
                                          ? palette.text
                                          : palette.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: AnimatedDefaultTextStyle(
                                        duration: duration,
                                        style: SsType.label.color(
                                          i == index
                                              ? palette.text
                                              : palette.textMuted,
                                        ),
                                        child: Text(segment.label, maxLines: 1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
